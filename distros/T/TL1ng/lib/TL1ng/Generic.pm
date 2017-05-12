package TL1ng::Generic;

use strict;
use warnings;

our $VERSION = '0.07';

#our @ISA = qw(TL1ng::Base);
use base 'TL1ng::Base';

# Example of a derived class.
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_) or return; # Get the setup from the base-class.
    bless $self, $class;
    $self->{sessions} = [] unless $self->{sessions};
    #use Data::Dumper; print Dumper $self; exit;
    return $self;
}

# Logs into the specifid target node using the spuulied credentials.
# Returns true on success, false on failure.
# You should also check the TL1 object for error specifics.
sub login {
	my ( $self, $sid, $user, $pass ) = @_;

    # no need to continue if we're already logged in!
    return $self if grep { $_->{SID} eq $sid } $self->sessions();

	my $status 
        = $self->send_cmd( "ACT-USER:$sid:$user:" . $self->rand_ctag() . "::$pass;" );

    return unless $status;

	my $msg = $self->get_resp( $self->last_ctag() ) || return;

    # Save the message on the queue, since we're not returning it.
    push @{ $self->{response_queue} }, $msg;
	
	if ( $msg->{response_code} eq 'COMPLD' ) {

        my $session = {
            SID  => $sid,
            USER => $user,
            PASS => $pass,
        };
        push @{ $self->{sessions} }, $session;
        return $self;
    }

	return;
}


sub sessions {
    my $self = shift;
    $self->{sessions} = [] unless $self->{sessions};
    return @{ $self->{sessions} };
}


sub logout {
	my ( $self, $sid ) = @_;
    
    # Find the SID in the session list...
    my ($session) = grep { $_->{SID} eq $sid } $self->sessions();
    
    # no need to continue if we're NOT already logged in!
    return 1 unless $session;

    my $user = $session->{USER};
    my $pass = $session->{PASS};

    $self->send_cmd( "CANC-USER:$sid:$user:" . $self->rand_ctag() . ";" )
        || return;

    my $msg = $self->get_resp( $self->last_ctag() ) || return;

    # Save the message on the queue, since we're not returning it.
    push @{ $self->{response_queue} }, $msg;
    
	if ( defined $msg->{response_code} && $msg->{response_code} eq 'COMPLD' ) {
        # If sucessful, remove this SID from the sessions array!
        my @sessions = grep { $_->{SID} ne $sid } $self->sessions();
        $self->{sessions} = \@sessions;
        return 1;
    }
	return;
}

1;

__END__

=head1 NAME 

TL1ng::Generic - Provides generic TL1 commands and functionality

=head1 METHODS

This class extends L<TL1ng::Base> to provide basic TL1 session management
capabilities like login and logout of nodes available via the connected
NE/GNE's TL1 agent.

Since this class inherits from L<TL1ng::Base>, look there for the rest of the
methods this module supports.

=head2 new

Provides nothing over and above the constructor for L<TL1ng::Base>, except
for the initalization of some extra internal data this class needs.

=head2 login

Given a TID/SID, a username, and a password, this method attempts to establish 
a login session with an NE available through the currently connected NE/GNE.

=head2 logout

Given the name of an NE (it's TID or SID) it terminates the current login
session.

=head2 sessions

Returns a hashref with information on all currently logged-in sessions.

=cut