package OpenTracing::Implementation::Interface::Bootstrap;

use Role::Declare::Should;
use Types::Standard qw/Any ConsumerOf/;



class_method bootstrap_tracer(
    Any @implementation_args,
) :Return ( ConsumerOf['OpenTracing::Interface::Tracer'] ) { }



1;