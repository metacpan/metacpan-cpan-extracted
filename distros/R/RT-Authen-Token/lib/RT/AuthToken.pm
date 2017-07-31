use strict;
use warnings;
use 5.10.1;

package RT::AuthToken;
use base 'RT::Record';

require RT::User;
require RT::Util;
use Digest::SHA 'sha512_hex';

=head1 NAME

RT::AuthToken - Represents an authentication token for a user

=cut

=head1 METHODS

=head2 Create PARAMHASH

Create takes a hash of values and creates a row in the database.  Available
keys are:

=over 4

=item Owner

The user ID for whom this token will authenticate. If it's not the AuthToken
object's CurrentUser, then the AdminUsers permission is required.

=item Description

A human-readable description of what this token will be used for.

=back

Returns a tuple of (status, msg) on failure and (id, msg, authstring) on
success. Note that this is the only time the authstring will be directly
readable (as it is stored in the database hashed like a password, so use
this opportunity to capture it.

=cut

sub Create {
    my $self = shift;
    my %args = (
        Owner       => undef,
        Description => '',
        @_,
    );

    return (0, $self->loc("Permission Denied"))
        unless $self->CurrentUserHasRight('ManageAuthTokens');

    return (0, $self->loc("Owner required"))
        unless $args{Owner};

    return (0, $self->loc("Permission Denied"))
        unless $args{Owner} == $self->CurrentUser->Id
            || $self->CurrentUserHasRight('AdminUsers');

    my $token = $self->_GenerateToken;

    my ( $id, $msg ) = $self->SUPER::Create(
        Token => $self->_CryptToken($token),
        map { $_ => $args{$_} } grep {exists $args{$_}}
            qw(Owner Description),
    );
    unless ($id) {
        return (0, $self->loc("Authentication token create failed: [_1]", $msg));
    }

    my $authstring = $self->_BuildAuthString($self->Owner, $token);

    return ($id, $self->loc('Authentication token created'), $authstring);
}

=head2 CurrentUserCanSee

Returns true if the current user can see the AuthToken

=cut

sub CurrentUserCanSee {
    my $self = shift;

    return 0 unless $self->CurrentUserHasRight('ManageAuthTokens');

    return 0 unless $self->__Value('Owner') == $self->CurrentUser->Id
                 ||  $self->CurrentUserHasRight('AdminUsers');

    return 1;
}

=head2 SetOwner

Not permitted

=cut

sub SetOwner {
    my $self = shift;
    return (0, $self->loc("Permission Denied"));
}

=head2 SetToken

Not permitted

=cut

sub SetToken {
    my $self = shift;
    return (0, $self->loc("Permission Denied"));
}

=head2 Delete

Checks ACL

=cut

sub Delete {
    my $self = shift;
    return (0, $self->loc("Permission Denied")) unless $self->CurrentUserCanSee;
    my ($ok, $msg) = $self->SUPER::Delete(@_);
    return ($ok, $self->loc("Authentication token revoked.")) if $ok;
    return ($ok, $msg);
}

=head2 UpdateLastUsed

Sets the "last used" time, without touching "last updated"

=cut

sub UpdateLastUsed {
    my $self = shift;

    my $now = RT::Date->new( $self->CurrentUser );
    $now->SetToNow;

    return $self->__Set(
        Field => 'LastUsed',
        Value => $now->ISO,
    );
}

=head2 ParseAuthString AUTHSTRING

Class method that takes as input an authstring and provides a tuple
of (user id, token) on success, or the empty list on failure.

=cut

sub ParseAuthString {
    my $class = shift;
    my $input = shift;

    my ($version) = $input =~ s/^([0-9]+)-//
        or return;

    if ($version == 1) {
        my ($user_id, $token) = $input =~ /^([0-9]+)-([0-9a-f]{32})$/i
            or return;
        return ($user_id, $token);
    }

    return;
}

=head2 IsToken

Analogous to L<RT::User/IsPassword>, without all of the legacy password
forms.

=cut

sub IsToken {
    my $self = shift;
    my $value = shift;

    my $stored = $self->__Value('Token');

    # If it's a new-style (>= RT 4.0) password, it starts with a '!'
    my (undef, $method, @rest) = split /!/, $stored;
    if ($method eq "bcrypt") {
        if (RT::Util->can('constant_time_eq')) {
            return 0 unless RT::Util::constant_time_eq(
                $self->_CryptToken_bcrypt($value, @rest),
                $stored,
            );
        } else {
            return 0 unless $self->_CryptToken_bcrypt($value, @rest) eq $stored;
        }
        # Upgrade to a larger number of rounds if necessary
        return 1 unless $rest[0] < RT->Config->Get('BcryptCost');
    }
    else {
        $RT::Logger->warn("Unknown hash method $method");
        return 0;
    }

    # We got here by validating successfully, but with a legacy
    # password form.  Update to the most recent form.
    $self->_Set(Field => 'Token', Value => $self->_CryptToken($value));
    return 1;
}

=head2 LastUsedObj

L</LastUsed> as an L<RT::Date> object.

=cut

sub LastUsedObj {
    my $self = shift;
    my $date = RT::Date->new($self->CurrentUser);
    $date->Set(Format => 'sql', Value => $self->LastUsed);
    return $date;
}

=head1 PRIVATE METHODS

Documented for internal use only, do not call these from outside
RT::AuthToken itself.

=head2 _Set

Checks if the current user can I<ManageAuthTokens> before calling
C<SUPER::_Set>.

=cut

sub _Set {
    my $self = shift;
    my %args = (
        Field => undef,
        Value => undef,
        @_
    );

    return (0, $self->loc("Permission Denied"))
        unless $self->CurrentUserCanSee;

    return $self->SUPER::_Set(@_);
}

=head2 _Value

Checks L</CurrentUserCanSee> before calling C<SUPER::_Value>.

=cut

sub _Value {
    my $self = shift;
    return unless $self->CurrentUserCanSee;
    return $self->SUPER::_Value(@_);
}

=head2 _GenerateToken

Generates an unpredictable auth token

=cut

sub _GenerateToken {
    my $class = shift;
    require Time::HiRes;

    my $input = join '',
                    Time::HiRes::time(), # subsecond-precision time
                    {},                  # unpredictable memory address
                    rand();              # RNG

    my $digest = sha512_hex($input);

    return substr($digest, 0, 32);
}

=head2 _BuildAuthString

Takes a user id and token and provides an authstring for use in place of
a (username, password) combo.

=cut

sub _BuildAuthString {
    my $self    = shift;
    my $version = 1;
    my $userid  = shift;
    my $token   = shift;

    return $version . '-' . $userid . '-' . $token;
}

sub _CryptToken_bcrypt {
    my $self = shift;
    return $self->CurrentUser->UserObj->_GeneratePassword_bcrypt(@_);
}

sub _CryptToken {
    my $self = shift;
    return $self->_CryptToken_bcrypt(@_);
}

sub Table { "RTxAuthTokens" }

sub _CoreAccessible {
    {
        id            => { read => 1, type => 'int(11)',        default => '' },
        Owner         => { read => 1, type => 'int(11)',        default => '0' },
        Token         => { read => 1, sql_type => 12, length => 256, is_blob => 0, is_numeric => 0, type => 'varchar(256)', default => ''},
        Description   => { read => 1, type => 'varchar(255)',   default => '',  write => 1 },
        LastUsed      => { read => 1, type => 'datetime',       default => '',  write => 1 },
        Creator       => { read => 1, type => 'int(11)',        default => '0', auto => 1 },
        Created       => { read => 1, type => 'datetime',       default => '',  auto => 1 },
        LastUpdatedBy => { read => 1, type => 'int(11)',        default => '0', auto => 1 },
        LastUpdated   => { read => 1, type => 'datetime',       default => '',  auto => 1 },
    }
}

1;
