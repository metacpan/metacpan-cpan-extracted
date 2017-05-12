
# The usage information prints the 'documentation' value for all Getopt
# attributes, except the order is not deterministic (rather, it uses the order
# in which the attributes are stored in the metaclass 'attributes' hash).
# Let's sort them by insertion order, which should lead to nicer output:
# If MooseX::Getopt is applied early, the help options will be on top
# the help options will always be on top (assuming this role is applied
# early), followed by options added by parent classes and roles, and then
# options added by this class.

use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    package MyClass;
    use strict; use warnings;
    use Moose;
    with 'MooseX::Getopt';

    has $_ => (
        is => 'ro', isa => 'Str',
        traits => ['Getopt'],
        documentation => 'Documentation for "' . $_ . '"',
    ) foreach qw(foo bar baz);
}

my $obj = MyClass->new_with_options();

like(
    $obj->usage->text,
    qr/\A\Qusage: 110_sort_usage_by_attr_order.t [-?h] [long options...]\E
\t-h -\? --usage --help\s+Prints this usage information.
\t--foo (STR)?\s+Documentation for "foo"
\t--bar (STR)?\s+Documentation for "bar"
\t--baz (STR)?\s+Documentation for "baz"\Z/,
    'Usage text has nicely sorted options',
);

done_testing;
