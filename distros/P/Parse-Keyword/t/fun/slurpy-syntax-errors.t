use strict;
use warnings;
use Test::More;
use lib 't/fun/lib';

BEGIN {
    if (!eval { require Sub::Name }) {
        plan skip_all => "This test requires Sub::Name";
    }
}

use Fun;

{
    eval 'fun ( $foo, @bar, $baz ) { return [] }';
    ok $@, '... got an error';
}

{
    eval 'fun ( $foo, %bar, $baz ) { return {} }';
    ok $@, '... got an error';
}

{
    eval 'fun ( $foo, @bar, %baz ) { return [] }';
    ok $@, '... got an error';
}

{
    eval 'fun ( $foo, %bar, @baz ) { return {} }';
    ok $@, '... got an error';
}

done_testing;
