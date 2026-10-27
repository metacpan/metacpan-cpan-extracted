use strict;
use warnings;
use Test::More;
use JSON::PP ();

use PrivatusAnalytics qw(page_props_json);

is(
    page_props_json( [ plan => 'pro', role => 'admin' ] ),
    '{"plan":"pro","role":"admin"}',
    'props become a JSON object'
);
is( page_props_json( { role => 'admin', plan => 'pro' } ), '{"plan":"pro","role":"admin"}', 'hash keys are sorted' );

is( page_props_json( {} ),                undef, 'empty props give undef' );
is( page_props_json(undef),               undef, 'undef props give undef' );
is( page_props_json( [ gone => undef ] ), undef, 'only undef values give undef' );

is(
    page_props_json(
        [ seats => 5, ratio => 1.5, beta => \1, old => \0, flags => [ 'a', undef, 'b', 3 ], text => '5' ]
    ),
    '{"seats":5,"ratio":1.5,"beta":true,"old":false,"flags":["a","b",3],"text":"5"}',
    'numbers, booleans and lists keep their JSON types'
);
is( page_props_json( [ yes => JSON::PP::true(), no => JSON::PP::false() ] ),
    '{"yes":true,"no":false}', 'JSON::PP booleans' );

is( page_props_json( [ bad => 9**9**9, nan => -sin( 9**9**9 ), ok => 1 ] ),
    '{"ok":1}', 'infinity and NaN are left out' );

is( page_props_json( [ 'App Version' => '2.1' ] ), '{"app_version":"2.1"}', 'keys are cleaned like event props' );

my $json = JSON::PP->new;
my @many = map { ( "p$_" => $_ ) } 1 .. 40;
is( scalar keys %{ $json->decode( page_props_json( \@many ) ) }, 30, 'at most 30 props' );
is( scalar @{ $json->decode( page_props_json( [ list => [ map { "$_" } 1 .. 50 ] ] ) )->{list} },
    30, 'at most 30 list items' );
is( length $json->decode( page_props_json( [ long => 'x' x 900 ] ) )->{long}, 500, 'values are cut to 500 characters' );

my $safe = page_props_json( [ note => "</script><b>&\x{2028}\x{2029}" ] );
is(
    $safe,
    '{"note":"\\u003c/script\\u003e\\u003cb\\u003e\\u0026\\u2028\\u2029"}',
    'the JSON is safe inside a script tag'
);
unlike( $safe, qr/[<>&\x{2028}\x{2029}]/, 'no unsafe characters left' );

done_testing;
