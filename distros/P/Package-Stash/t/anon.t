#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use lib 't/lib';

use Package::Stash;

BEGIN {
    plan skip_all => "Anonymous stashes in PP need at least perl 5.14"
        if $] < 5.014
        && $Package::Stash::IMPLEMENTATION eq 'PP';
}

use Test::Requires 'Package::Anon';
use Symbol;

my $anon = Package::Anon->new;
my $stash = Package::Stash->new($anon);
my $obj = $anon->bless({});

{
    my $code = sub { 'FOO' };
    $stash->add_symbol('&foo' => $code);
    is($stash->get_symbol('&foo'), $code);
    is($obj->foo, 'FOO');
}

{
    $anon->{bar} = \123;

    my $code = $stash->get_symbol('&bar');
    is(ref($code), 'CODE');
    is($code->(), 123);

    is($obj->bar, 123);
}

{
    $anon->{baz} = -1;

    my $code = $stash->get_symbol('&baz');
    is(ref($code), 'CODE');
    like(
        exception { $code->() },
        qr/Undefined subroutine \&__ANON__::baz called/
    );
}

done_testing;
