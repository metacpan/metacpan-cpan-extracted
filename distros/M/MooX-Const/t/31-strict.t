#!perl

BEGIN {
        $ENV{EXTENDED_TESTING} =
        $ENV{RELEASE_TESTING} =
        $ENV{AUTHOR_TESTING} =
        $ENV{PERL_STRICT} = 1;
};

use Test::Most;

use lib 't/lib';
use MooTest::Strict;

ok my $o = MooTest::Strict->new;

lives_ok {
    ++$o->foo->[0];
} 'allowed change of array element';

is $o->foo->[0] => 2, 'element was changed';

dies_ok {
    ++$o->bar->[0];
} 'disallowed change of array element';

is $o->bar->[0] => 1, 'element was not changed';

dies_ok {

    $o->bop->{y};

} 'cannot access a non-existent key attribute (read-only)';

lives_ok {

    $o->bo( { a => 1, b => 2 } );

} 'set a write-once attribute';

dies_ok {

    ++$o->bo->{a};

} 'cannot write again to a write-once attribute';

dies_ok {

    $o->bo->{c};

} 'cannot access a non-existent key attribute (write once)';

done_testing;
