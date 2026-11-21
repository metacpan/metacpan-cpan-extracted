#!/usr/bin/env perl
# The reference's toml.ts: stringifyToml and tomlKey, byte for byte.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of );

use JSON::MaybeXS ();
use Path::Tiny qw( path );
use Scalar::Util qw( blessed reftype );
use Skilletor::JSON qw( js_stringify js_ordered js_type );
use Skilletor::TOML qw( stringify_toml toml_key toml_float is_toml_float );

# t/data/toml-oracle.json is the reference's answer (maint/oracle-toml.mjs). It is read with
# JSON::MaybeXS: js_parse needs some 20 s for its 200 KB, and the format carries a table's
# key order itself.
my $oracle = JSON::MaybeXS->new( utf8 => 1 )->decode( path( $FindBin::Bin, 'data', 'toml-oracle.json' )->slurp_raw );

my $INF = 9**9**9;
my %NON_FINITE = ( Infinity => $INF, '-Infinity' => -$INF, NaN => $INF - $INF );

# The oracle's value encoding: {"$float": x} a TomlFloat, {"$number": "NaN"} a non-finite
# number, {"$table": [[key, value], ...]} a table.
sub decode_value {
  my ( $v ) = @_;
  return [ map { decode_value($_) } @$v ] if ref $v && reftype $v eq 'ARRAY';
  return $v unless ref $v && reftype $v eq 'HASH' && !JSON::MaybeXS::is_bool($v);
  if ( exists $v->{'$float'} ) {
    # A string: a non-finite float, or an integer too long for Cpanel::JSON::XS to read as a number.
    my $x = $v->{'$float'};
    return toml_float( js_type($x) ne 'string' ? $x : $NON_FINITE{$x} // 0 + $x );
  }
  return $NON_FINITE{ $v->{'$number'} } if exists $v->{'$number'};
  my $t = js_ordered();
  $t->{ $_->[0] } = decode_value( $_->[1] ) for @{ $v->{'$table'} };
  return $t;
}

# A test name in ASCII: the inputs hold every control character and non-characters.
sub label {
  ( my $s = js_stringify( $_[0] ) ) =~ s/([^\x{20}-\x{7E}])/sprintf '\\x{%X}', ord $1/ge;
  return $s;
}

subtest 'tomlKey' => sub {
  is( toml_key( $_->{key} ), $_->{out}, 'key '.label( $_->{key} ) ) for @{ $oracle->{keys} };
};

subtest "stringifyToml: the reference's text, or its error" => sub {
  for my $case ( @{ $oracle->{cases} } ) {
    my $name = label( $case->{table} ).( $case->{multiline} ? ' multiline '.label( $case->{multiline} ) : '' );
    my @opts = $case->{multiline} ? ( { multiline => $case->{multiline} } ) : ();
    my $table = decode_value( $case->{table} );
    my $out;
    my $ok  = eval { $out = stringify_toml( $table, @opts ); 1 };
    my $err = $@;
    if ( $case->{error} ) {
      ok( !$ok && blessed $err && $err->isa('Skilletor::Error::TOML'), "$name: a Skilletor::Error::TOML" );
      is( $ok ? undef : blessed $err ? $err->message : "$err", $case->{error}{message}, "$name: message" );
    }
    else {
      is( $out, $case->{out}, $name ) or diag( 'died: '.$err );
    }
  }
};

subtest 'Perl values' => sub {
  is( stringify_toml( js_ordered( n => 3, s => '3', f => toml_float(3) ) ), qq(n = 3\ns = "3"\nf = 3.0\n),
    'a number, a string of digits, a float' );
  my $n = 5;
  is( stringify_toml( js_ordered( n => $n ) ), "n = 5\n", 'a number' );
  is( stringify_toml( js_ordered( t => JSON::MaybeXS::true(), f => JSON::MaybeXS::false(), y => !!1, x => !!0 ) ),
    "t = true\nf = false\ny = true\nx = false\n", 'JSON and core booleans' );
  is( stringify_toml( { b => 'x', a => { z => 1, y => 2 }, 1 => 'one' } ), qq(1 = "one"\nb = "x"\n\n[a]\ny = 2\nz = 1\n),
    'a plain hash: keys in the order JSON.stringify would sort them' );
  is( stringify_toml( js_ordered( k => "\x{e9}" ) ), qq(k = "\x{e9}"\n), 'characters, not bytes' );
  ok( is_toml_float( toml_float(1) ), 'is_toml_float' );
  ok( !is_toml_float(1), 'a number is no TomlFloat' );
  is( toml_float(2.5)->value, 2.5, 'value' );
  like( error_of( sub { stringify_toml( js_ordered( k => sub {1} ) ) } ), qr/\Ak: unsupported value undefined\z/,
    'a code ref is what JSON.stringify cannot write' );
};

done_testing;
