#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 12;

use Pinwheel::View::Wrap::Scalar;

my $o = bless({}, 'Pinwheel::View::Wrap::Scalar');


{
    is($o->strip('  abc  '), 'abc');
    is($o->strip(''), '');
}

{
    is($o->upcase('Hello World'), 'HELLO WORLD');
    is($o->upcase(''), '');

    is($o->downcase('Hello World'), 'hello world');
    is($o->downcase(''), '');
}

{
    is($o->length('abc'), 3);
    is($o->length(''), 0);

    is($o->size('abc'), 3);
    is($o->size(''), 0);
}

{
    eval { $o->blah };
    like($@, qr/bad scalar method/i);
    eval { $o->BLAH };
    ok(!$@);
}
