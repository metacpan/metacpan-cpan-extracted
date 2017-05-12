use strict;
use warnings;
use Test::More tests => 4;
use Test::Fatal;

use MooseX::Method::Signatures;

my $o = bless {} => 'Foo';

my $meth = method ($, $, $foo, $, $bar, $) {
    return $foo . $bar;
};
isa_ok($meth, 'Moose::Meta::Method');

ok(exception {
    $meth->($o, 1, 2, 3, 4, 5);
});

is(exception {
    is($meth->($o, 1, 2, 3, 4, 5, 6), 35);
}, undef);

1;
