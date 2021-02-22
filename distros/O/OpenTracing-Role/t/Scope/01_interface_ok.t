use Test::Most;
use Test::Interface;

=head1 DESCRIPTION

Test that a class that consumes the role, it complies with OpenTracing Interface

=cut

use strict;
use warnings;


BEGIN {
    $ENV{EXTENDED_TESTING} = 1 unless exists $ENV{EXTENDED_TESTING};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!



package MyTestClass;

use Moo;

with 'OpenTracing::Role::Scope';

# add required subs
#
sub close { ... }
sub get_span { ... }



package main;

interface_ok('MyTestClass', 'OpenTracing::Interface::Scope');

done_testing();
