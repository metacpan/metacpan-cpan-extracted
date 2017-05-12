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

    plan skip_all => "This isn't really going to work yet, probably";
}

use Symbol;

my $anon = {};
my $stash = Package::Stash->new($anon);
# no way to bless something into a hashref yet
# my $obj = $anon->bless({});

{
    my $code = sub { 'FOO' };
    $stash->add_symbol('&foo' => $code);
    is($stash->get_symbol('&foo'), $code);
    # is($obj->foo, 'FOO');
}

{
    local $TODO = "can't inflate weird stash entries";
    $anon->{bar} = \123;

    is(
        exception {
            my $code = $stash->get_symbol('&bar');
            is(ref($code), 'CODE');
            is($code->(), 123);

            # is($obj->bar, 123);
        },
        undef
    );
}

{
    local $TODO = "can't inflate weird stash entries";
    $anon->{baz} = -1;

    is(
        exception {
            my $code = $stash->get_symbol('&baz');
            is(ref($code), 'CODE');
            like(
                exception { $code->() },
                qr/Undefined subroutine \&__ANON__::baz called/
            );
        },
        undef
    );
}

done_testing;
