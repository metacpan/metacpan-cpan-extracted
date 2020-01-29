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

with 'OpenTracing::Role::Span';



package main;

interface_ok('MyTestClass', 'OpenTracing::Interface::Span');

done_testing();
