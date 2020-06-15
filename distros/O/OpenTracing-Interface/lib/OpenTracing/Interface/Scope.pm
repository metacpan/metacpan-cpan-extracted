package OpenTracing::Interface::Scope;


use strict;
use warnings;


our $VERSION = 'v0.202.2';


use Role::Declare;

use OpenTracing::Types qw/Span/;

use namespace::clean;


instance_method close(
) :ReturnSelf {}



instance_method get_span(
) :Return(Span) {}


1;
