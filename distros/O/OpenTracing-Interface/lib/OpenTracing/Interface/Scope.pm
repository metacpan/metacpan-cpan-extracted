package OpenTracing::Interface::Scope;


use strict;
use warnings;


our $VERSION = 'v0.206.1';


use Role::Declare::Should;

use OpenTracing::Types qw/Span/;

use namespace::clean;


instance_method close(
) :ReturnSelf {}



instance_method get_span(
) :Return(Span) {}


1;
