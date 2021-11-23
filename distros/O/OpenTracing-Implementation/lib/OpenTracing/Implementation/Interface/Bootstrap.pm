package OpenTracing::Implementation::Interface::Bootstrap;

use Role::Declare::Should;
use Types::Standard qw/ConsumerOf/;



class_method bootstrap_tracer(
) :Return ( ConsumerOf['OpenTracing::Interface::Tracer'] ) { }



1;