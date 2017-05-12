use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::AttributeShortcuts;

    has foo  => (is => 'rw', clearer => 1, predicate => -1);
    has _foo => (is => 'rw', clearer => 1, predicate => -1);

    has bar  => (is => 'rw', predicate => 1, clearer => -1);
    has _bar => (is => 'rw', predicate => 1, clearer => -1);
}

use Test::More;
use Test::Moose;
use Test::Moose::More 0.043;

validate_class TestClass => (
    methods => [qw{
        foo     clear_foo      _has_foo
        _foo    _clear_foo     has_foo
        bar     has_bar        _clear_bar
        _bar    _has_bar       clear_bar
    }],

    attributes => [
        foo  => { accessor => 'foo',  clearer   => 'clear_foo',  predicate => '_has_foo'   },
        _foo => { accessor => '_foo', clearer   => '_clear_foo', predicate => 'has_foo'    },
        bar  => { accessor => 'bar',  predicate => 'has_bar',    clearer   => '_clear_bar' },
        _bar => { accessor => '_bar', predicate => '_has_bar',   clearer   => 'clear_bar'  },
    ],
);

done_testing;
