package RPC::ExtDirect::Test::Foo;

use strict;
use warnings;
no  warnings 'uninitialized';

use RPC::ExtDirect;

# Return scalar result
sub foo_foo : ExtDirect(1, before => \&foo_before) {
    return "foo! '${_[1]}'"
}

# Return arrayref result
sub foo_bar
    : ExtDirect(2, instead => \&foo_instead)
{
    return [ 'foo! bar!', @_[1, 2], ];
}

# Return hashref result
sub foo_baz : ExtDirect( params  => [foo, bar, baz], before  => \&foo_before, after   => \&foo_after) {
    my $class = shift;
    my %param = @_;

    my $ret = { msg => 'foo! bar! baz!', foo => $param{foo},
                bar => $param{bar},      baz => $param{baz},
              };

    delete @param{ qw(foo bar baz _env) };
    @$ret{ keys %param } = values %param;

    return $ret;
}

# Testing zero parameters
sub foo_zero : ExtDirect(0) {
    my ($class) = @_;

    my $ret = [ @_ ];

    return $ret;
}

# Testing blessed object return
sub foo_blessed : ExtDirect {
    return bless {}, 'foo';
}

# Testing hooks
sub foo_before {
    return 1;
}

sub foo_instead {
    my ($class, %params) = @_;

    return $params{orig}->();
}

sub foo_after {
}

1;
