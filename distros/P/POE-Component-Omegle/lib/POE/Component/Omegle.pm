package POE::Component::Omegle;

use 5.006000;
use strict;
use warnings;

use POE;

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my @args = @_;

    my $self = {
        session => POE::Session->create(
            package_states => [
                                  OMSession => [qw/_start _stop start_chat say disconnect set_callback
                                                on_event_handled poke/],
                              ],
            args => \@args,
        ),
    };

    bless $self, $class;
    return $self;
}

sub AUTOLOAD {
    my $self = shift;

    use vars qw($AUTOLOAD);
    my $state = $AUTOLOAD;
    $state =~ s/.*:://;
    $poe_kernel->post( $self->{session} => $state => @_ );
}


#####

package OMSession;

use strict;
use warnings;

use POE;
use WWW::Omegle;


sub _start {
    my ($kernel, $sender, $heap, $session, %args) = @_[KERNEL, SENDER, HEAP, SESSION, ARG0..$#_];

    my $om = $heap->{om} = new WWW::Omegle();
    $kernel->yield(set_callback => 'event_handled', $session->postback('on_event_handled'));
}

sub set_callback {
    my ($sender, $heap, $callback, $state, @extra) = @_[SENDER, HEAP, ARG0, ARG1, ARG2..$#_];
    $heap->{om}->set_callback($callback => $sender->postback($state), @extra); 
}

sub _stop {}

# initiate a convo
sub start_chat {
    my ($kernel, $sender, $heap, $pb) = @_[KERNEL, SENDER, HEAP, ARG0];
    
    $heap->{om}->start;
}

sub poke {
    my ($kernel, $sender, $heap) = @_[KERNEL, SENDER, HEAP];
    $heap->{om}->poke;
}

sub on_event_handled {
    my ($sender, $heap, $success) = @_[SENDER, HEAP, ARG0];
}
    
sub say {
    my ($sender, $heap, $msg) = @_[SENDER, HEAP, ARG0];
    $heap->{om}->say($msg);
}

sub disconnect {
    my ($sender, $heap) = @_[SENDER, HEAP];
    $heap->{om}->disconnect;
}

1;
__END__

=head1 NAME

POE::Component::Omegle - Simple POE wrapper around WWW::Omegle

=head1 SYNOPSIS

	use POE;

	POE::Session->create(
	                     package_states => [
	                                        OMPoeBot => [qw/
	                                                     _start om_connect om_chat om_disconnect poke
	                                                     /],
	                                        ],
	                     );

	$poe_kernel->run;

	package OMPoeBot;
	use POE qw/Component::Omegle/;

	sub _start {
	    my ($heap) = $_[HEAP];

	    my $om = POE::Component::Omegle->new;

	    $om->set_callback(connect    => 'om_connect');
	    $om->set_callback(chat       => 'om_chat');
	    $om->set_callback(disconnect => 'om_disconnect');

	    $heap->{om} = $om;
    
	    $om->start_chat;
	    $poe_kernel->delay_add(poke => 0.1, $om);
	}

	sub poke {
	    my ($kernel, $heap, $om) = @_[KERNEL, HEAP, ARG0];

	    $om->poke;
	    $poe_kernel->delay_add(poke => 0.1, $om);
	}

	sub om_connect {
	    my $om = $_[HEAP]->{om};

	    print "Stranger connected\n";
	    $om->say("Yo homie! Where you at?");
	}

	sub om_chat {
	    my ($cb_args) = $_[ARG1];
	    my ($om, $chat) = @$cb_args;

	    print ">> $chat\n";
	}

	sub om_disconnect { print "Stranger disconnected\n"; }



=head1 DESCRIPTION

This module makes it easy to run multiple Omegle bots using
asynchronous HTTP calls.

=head2 EXPORT

None by default.

=head1 METHODS

POE::Component::Omegle is just a thin wrapper around the methods in
L<WWW::Omegle>. See that module for the other available commands

=over 4

=item poke

This method will poll for outstanding requests to process, it's good
to call frequently.

=back

=head1 SEE ALSO

L<WWW::Omegle>, L<POE>

=head1 AUTHOR

Mischa Spiegelmock, E<lt>revmischa@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mischa Spiegelmock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
