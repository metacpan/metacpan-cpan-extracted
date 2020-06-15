use Test::Most;
use Test::OpenTracing::Interface::Tracer qw/can_all_ok/;

use strict;
use warnings;

can_all_ok('MyStub::Tracer');

done_testing();


package MyStub::Tracer;
use Moo;

sub build_span          { ... }
sub build_context       { ... }
sub extract_context     { ... }
sub inject_context      { ... }

BEGIN { with 'OpenTracing::Role::Tracer'; }
