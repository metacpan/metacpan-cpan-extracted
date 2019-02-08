#!perl

use Test::Most;

use PerlX::Let;

let $x = 3;

is $x => 3, 'global';

let $x = 1 {

    is $x => 1, 'scope';

    dies_ok { $x++ } 'read-only';

    let $x = 2 {
        is $x => 2, 'inner scope';
    };

};

done_testing;
