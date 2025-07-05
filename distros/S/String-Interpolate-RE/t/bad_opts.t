#! perl

use v5.10;
use Test2::V0;

use String::Interpolate::RE 'strinterp';

subtest 'unrecognized option' => sub {
    like( dies { String::Interpolate::RE->import( strinterp => { opts => { Foo => 'bar' } } ) },
        qr/unrecognized option/, 'import', );

    like( dies { strinterp( q{}, {}, { Foo => 'bar' } ) }, qr/unrecognized option/, 'runtime' );
};

subtest 'bad fallback option' => sub {

    like( dies { String::Interpolate::RE->import( strinterp => { opts => { fallback => 1 } } ) },
        qr/must be a coderef/, 'import', );

    like( dies { strinterp( q{}, {}, { fallback => 1 } ) }, qr/must be a coderef/, 'runtime' );

};

done_testing;
