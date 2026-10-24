#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use utf8;

use JSON::MaybeXS ();
use Path::Tiny qw( path );
use FindBin;

use Skilletor::JSON qw( js_parse js_stringify js_ordered js_sort_keys );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

# t/data/json-oracle.json is Node's answer (maint/oracle-json.mjs): for each text what
# JSON.stringify(JSON.parse(text), null, 2) and JSON.stringify(JSON.parse(text)) give, and
# for each malformed text the message of JSON.parse's SyntaxError.
my $oracle = js_parse( path( $FindBin::Bin, 'data', 'json-oracle.json' )->slurp_utf8 );

subtest 'stringify matches JSON.stringify for every oracle text' => sub {
  for my $case ( @{ $oracle->{stringify} } ) {
    my $value = js_parse( $case->{text} );
    is( js_stringify( $value, 2 ), $case->{pretty}, 'pretty: '.$case->{text} );
    is( js_stringify($value), $case->{compact}, 'compact: '.$case->{text} );
  }
};

subtest 'parse errors carry JSON.parse messages' => sub {
  for my $case ( @{ $oracle->{errors} } ) {
    my $err = do { local $@; eval { js_parse( $case->{text} ); 1 } ? undef : $@ };
    ok( ref $err && $err->isa('Skilletor::Error::JSON'), 'error object for '.$case->{text} )
      or next;
    is( $err->message, $case->{message}, 'message for '.$case->{text} );
  }
};

subtest 'parsed objects keep JavaScript property order' => sub {
  my $v = js_parse('{"b":1,"a":2,"10":3,"2":4,"x":{"z":1,"y":2}}');
  is_deeply( [ keys %$v ], [qw( 2 10 b a x )], 'index keys first, then insertion order' );
  is_deeply( [ keys %{ $v->{x} } ], [qw( z y )], 'nested object too' );
  $v->{c} = 5;
  delete $v->{b};
  $v->{b} = 6;
  is( js_stringify($v), '{"2":4,"10":3,"a":2,"x":{"z":1,"y":2},"c":5,"b":6}', 'stored keys append, a re-stored key moves to the end' );
};

subtest 'plain Perl hashes are written with sorted keys, as Object.keys().sort() orders them' => sub {
  is( js_stringify( { b => 1, a => 2, 10 => 3, 9 => 4 } ), '{"9":4,"10":3,"a":2,"b":1}', 'index keys first' );
  # UTF-16 code units: U+1F600 is D83D DE00 and sorts before U+FF61 (Node: ["😀","｡"]).
  is_deeply( [ js_sort_keys( "\x{FF61}", "\x{1F600}", 'a' ) ], [ 'a', "\x{1F600}", "\x{FF61}" ], 'js_sort_keys' );
  is( js_stringify( { "\x{FF61}" => 1, "\x{1F600}" => 2 } ), qq({"\x{1F600}":2,"\x{FF61}":1}), 'astral before high BMP' );
  is( js_stringify( js_ordered( z => 1, a => 2 ) ), '{"z":1,"a":2}', 'js_ordered keeps the given order' );
};

subtest 'Perl scalars: numbers, strings, booleans, undef' => sub {
  is( js_stringify(10), '10', 'integer' );
  is( js_stringify(1.5), '1.5', 'float' );
  is( js_stringify( 0.1 + 0.2 ), '0.30000000000000004', 'shortest round trip' );
  is( js_stringify(1e21), '1e+21', 'exponent form from 1e21' );
  is( js_stringify(1e-7), '1e-7', 'exponent form below 1e-6' );
  is( js_stringify(-0.0), '0', 'negative zero' );
  is( js_stringify( 9**9**9 ), 'null', 'Infinity is null' );
  is( js_stringify( -sin( 9**9**9 ) ), 'null', 'NaN is null' );
  is( js_stringify(9007199254740993), '9007199254740992', 'an integer beyond 2**53 is a double' );
  is( js_stringify('10'), '"10"', 'a string stays a string' );
  is( js_stringify( 0 + '5' ), '5', 'a string turned number is a number' );
  is( js_stringify( [ JSON::MaybeXS::true(), JSON::MaybeXS::false(), undef ] ), '[true,false,null]', 'booleans, undef' );
  is( js_stringify( "a/b\x{e9}\x{2028}\x{1F600}" ), qq("a/b\x{e9}\x{2028}\x{1F600}"), 'no escape for / or non-ASCII' );
  is( js_stringify( "\x{D800}" ), '"\ud800"', 'a lone surrogate is escaped' );
  is( js_stringify( { a => [] }, 2 ), qq({\n  "a": []\n}), 'empty array, indented' );
};

subtest 'parse values' => sub {
  my $v = js_parse('[1, 1.5, -0, 1e400, "x", true, false, null, "😀", "é"]');
  is( $v->[0], 1, 'integer' );
  is( $v->[1], 1.5, 'float' );
  ok( $v->[3] == 9**9**9, '1e400 is Infinity, as in JavaScript' );
  ok( JSON::MaybeXS::is_bool( $v->[5] ) && $v->[5], 'true' );
  ok( JSON::MaybeXS::is_bool( $v->[6] ) && !$v->[6], 'false' );
  ok( !defined $v->[7], 'null is undef' );
  is( $v->[8], "\x{1F600}", 'surrogate pair joins' );
  is( $v->[9], "\x{e9}", 'unicode escape' );
  is( js_stringify( js_parse('18446744073709551615') ), '18446744073709552000', 'a big integer is a double' );
};

done_testing;
