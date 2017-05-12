#
# WARNING WARNING WARNING
#
# DO NOT CHANGE ANYTHING IN THIS MODULE. OTHERWISE, A LOT OF API 
# AND OTHER TESTS MAY BREAK.
#
# This module is here to test certain behaviors. If you need
# to test something else, add another test module.
# It's that simple.
#

# This does not need to be indexed by PAUSE
package
    RPC::ExtDirect::Test::Pkg::Hooks;

use strict;
use warnings;
no  warnings 'uninitialized';

use RPC::ExtDirect before => \&nonexistent_before_hook;

our ($foo_foo_called, $foo_bar_called, $foo_baz_called);

sub foo_foo : ExtDirect(1) {
    $foo_foo_called = 1;
}

sub foo_bar : ExtDirect(2, before => 'NONE') {
    $foo_bar_called = 1;
}

# This hook will simply raise a flag and die
sub foo_baz_after {
    $foo_baz_called = 1;

    die;
}

# Return hashref result
sub foo_baz : ExtDirect( params  => [foo, bar, baz], before  => 'NONE', after   => \&foo_baz_after)
{
    my $class = shift;
    my %param = @_;

    my $ret = { msg => 'foo! bar! baz!', foo => $param{foo},
                bar => $param{bar},      baz => $param{baz},
              };

    delete @param{ qw(foo bar baz) };
    @$ret{ keys %param } = values %param;

    return $ret;
}

# Testing hook changing parameters
sub foo_hook : ExtDirect(1) {
    my ($class, $foo) = @_;

    my $ret = [ @_ ];

    return $ret;
}

1;

