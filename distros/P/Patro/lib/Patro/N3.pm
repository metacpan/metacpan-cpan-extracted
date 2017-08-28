package Patro::N3;
use Devel::GlobalDestruction;
use strict;
use warnings;

# we must keep this namespace very clean
use Carp ();
use Socket ();
use Data::Dumper ();

use overload
    '&{}' => sub { ${$_[0]}->{sub} },
    'nomethod' => \&Patro::LeumJelly::overload_handler,
    ;

sub DESTROY {
    my $self = shift;
    return if in_global_destruction();
    if ($$self->{_DESTROY}++) {
	return;
    }
    my $socket = $$self->{socket};
    if ($socket) {

	# XXX - shouldn't disconnect on every object destruction,
	# only when all of the wrapped objects associated with a
	# client have been destroyed, or during global
	# destruction

	my $response = Patro::LeumJelly::proxy_request(
	    $$self,
	    { id => $$self->{id},
	      topic => 'META',
	      #command => 'disconnect' } );
	      command => 'destroy' } );
	if ($response->{disconnect_ok}) {
	    close $socket;
	    delete $$self->{socket};
	}
    }
}

############################################################

1;
