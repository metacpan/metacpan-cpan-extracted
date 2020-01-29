use Test::Most;
use Test::Interface;

=head1 DESCRIPTION

Test that a class that consumes the role, it complies with OpenTracing Interface

=cut

use strict;
use warnings;


$ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
#
# This breaks if it would be set to 0 externally, so, don't do that!!!



package MyTestClass;

use Moo;

with 'OpenTracing::Role::Tracer';

# add required subs
#
sub _build_scope_manager { ... }
sub build_span { ... }
sub extract_context { ... }
sub inject_context { ... }



package main;

interface_ok('MyTestClass', 'OpenTracing::Interface::Tracer');

done_testing();
