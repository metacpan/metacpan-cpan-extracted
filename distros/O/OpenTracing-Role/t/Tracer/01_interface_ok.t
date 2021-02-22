use Test::Most;
use Test::Interface;

=head1 DESCRIPTION

Test that a class that consumes the role, it complies with OpenTracing Interface

=cut

use strict;
use warnings;


$ENV{EXTENDED_TESTING} = 1 unless exists $ENV{EXTENDED_TESTING};
#
# This breaks if it would be set to 0 externally, so, don't do that!!!



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

with 'OpenTracing::Role::Tracer';



package main;

interface_ok('MyStub::Tracer', 'OpenTracing::Interface::Tracer');

done_testing();



1;
