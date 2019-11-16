#!perl

BEGIN {
        $ENV{EXTENDED_TESTING} =
        $ENV{RELEASE_TESTING} =
        $ENV{AUTHOR_TESTING} =
        $ENV{PERL_STRICT} = 0;
};

use Test::Most;

use lib 't/lib';
use MooTest::Strict;

ok my $o = MooTest::Strict->new;

lives_ok {
    ++$o->bar->[0];
} 'not disallowed change of array element (not strict)';

isnt $o->bar->[0] => 1, 'element was changed';

lives_ok {

    $o->bop->{y};

} 'can access a non-existent key attribute (not strict)';

lives_ok {

    $o->bo( { a => 1, b => 2 } );

} 'set a write-once attribute';

lives_ok {

    ++$o->bo->{a};

} 'can write again to a write-once attribute (not strict)';

done_testing;
