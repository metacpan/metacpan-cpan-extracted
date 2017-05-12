use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';

throws_ok {

    package Foo;

    use Moo;

    use BarWithRequires;

    BarWithRequires->apply(
        { attr => 'baz', method => 'run', requires => 'xoxo' } );
}
qr/Can't apply BarWithRequires to Foo - missing xoxo/, 'should die';

done_testing;
