package Protocol::Database::PostgreSQL::Backend::AuthenticationRequest;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION

use parent qw(Protocol::Database::PostgreSQL::Backend);

=head1 NAME

Protocol::Database::PostgreSQL::Backend::AuthenticationRequest - an authentication request message

=head1 DESCRIPTION

=cut

use Log::Any qw($log);

sub type { 'authentication_request' }

sub auth_type { shift->{auth_type} }
sub password_type { shift->{password_type} }
sub password_salt { shift->{password_salt} }

sub new_from_message {
    my ($class, $msg) = @_;

    my (undef, undef, $auth_code, $data) = unpack('C1N1N1a*', $msg);
    my $auth_type = $Protocol::Database::PostgreSQL::AUTH_TYPE{$auth_code} or die "Invalid auth code $auth_code received";
    $log->tracef("Auth message [%s]", $auth_type);
    my %info = (
        auth_type => $auth_type,
    );
    if($auth_type eq 'AuthenticationMD5Password') {
        my ($salt) = unpack('a4', $data);
        $info{password_type} = 'md5';
        $info{password_salt} = $salt;
    } elsif($auth_type eq 'AuthenticationCleartextPassword') {
        $info{password_type} = 'plain';
    } elsif($auth_type eq 'AuthenticationOk') {
        # No action required
    } else {
        die 'unknown auth thing here';
    }
    return $class->new(
        %info,
    );
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

