use Test::Most;
use Test::OpenTracing::Interface::Tracer qw/can_all_ok/;

use strict;
use warnings;

can_all_ok('MyStub::Tracer');

done_testing();


package MyStub::Tracer;
use Moo;

sub build_span                           { ... }
sub build_context                        { ... }
sub inject_context_into_array_reference  { ... }
sub extract_context_from_array_reference { ... }
sub inject_context_into_hash_reference   { ... }
sub extract_context_from_hash_reference  { ... }
sub inject_context_into_http_headers     { ... }
sub extract_context_from_http_headers    { ... }

BEGIN { with 'OpenTracing::Role::Tracer'; }
