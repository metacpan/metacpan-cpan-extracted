use strict;
use warnings;

no warnings qw(redefine);

package RT::User;

=head2 LoadOrCreateByPagerPhone NUMBER

Attempts to find a user who has the provided pager phone number. If that fails,
creates an unprivileged user with the provided pager phone number and loads them.

Returns a tuple of the user's id and a status message.
0 will be returned in place of the user's id in case of failure.

=cut

sub LoadOrCreateByPagerPhone {
    my $self  = shift;
    my $pager = shift;

    # find the user with the phone number sending the sms
    my $users
        = RT::Users->new( $HTML::Mason::Commands::session{CurrentUser} );
    $users->Limit(
        FIELD    => 'PagerPhone',
        VALUE    => $pager,
        OPERATOR => '=',
    );
    # XXX - should we check if there is more than one user with same pager?
    if ( $users->Count > 0 ) {
        $self->Load( $users->First->Id );
    }

    return wantarray ? ( $self->Id, $self->loc("User loaded") ) : $self->Id
        if $self->Id;

    # strip off country code and format pager into account name
    ( my $name = $pager ) =~ s/\+\d*?(\d{3})(\d{3})(\d{4})$/SMS-$1-$2-$3/;

    my ( $val, $message ) = $self->Create(
        Name       => $name,
        PagerPhone => $pager,
        Privileged => 0,
        Comments   => 'Autocreated when creating ticket from SMS',
    );
    return wantarray ? ( $self->Id, $self->loc("User loaded") ) : $self->Id
        if $self->Id;

    # Deal with the race condition of two account creations at once
    $self->LoadByPagerPhone($pager);
    unless ( $self->Id ) {
        sleep 5;
        $self->LoadByPagerPhone($pager);
    }

    if ( $self->Id ) {
        $RT::Logger->error(
            "Recovered from creation failure due to race condition");
        return
            wantarray ? ( $self->Id, $self->loc("User loaded") ) : $self->Id;
    } else {
        $RT::Logger->crit("Failed to create user SMS-$pager: $message");
        return wantarray ? ( 0, $message ) : 0 unless $self->id;
    }
}

=head2 LoadByPagerPhone

Tries to load this user object from the database by the user's pager phone number.

=cut

sub LoadByPagerPhone {
    my $self  = shift;
    my $pager = shift;

    # Never load an empty pager.
    unless ($pager) {
        return (undef);
    }

    return $self->LoadByCol( "PagerPhone", $pager );
}

1;
