# -*- perl -*-

# t/05.scalar.t - check scalar manipulation object

use Test::More qw( no_plan );
use strict;
use warnings;
use utf8;

BEGIN { use_ok( 'Module::Generic' ) || BAIL_OUT( "Unable to load Module::Generic" ); }

my $str = "Hello world";
my $s = Module::Generic::Scalar->new( $str ) || BAIL_OUT( "Unable to instantiate an object." );
isa_ok( $s, 'Module::Generic::Scalar', 'Scalar object' );
is( "$s", $str, 'Stringification' );

my $s2 = $s->clone;
isa_ok( $s2, 'Module::Generic::Scalar', 'Scalar object' );
is( "$s2", $str, 'Cloning' );

$s .= "\n";
isa_ok( $s, 'Module::Generic::Scalar', 'Object after concatenation' );
is( $s, "$str\n", 'Checking updated string object' );
my $a1 = $s->clone( "Prefix; " );
$a1 .= $s;
# diag( "\$a1 is $a1" );
my $s3 = Module::Generic::Scalar->new( 'A' );
my $res = $s3 x 12;
# diag( "$s3 x 12 = $res (" . ref( $res ) . ")" );
is( $res, 'AAAAAAAAAAAA', 'Multiplying string' );
isa_ok( $res, 'Module::Generic::Scalar', 'Multiplied string class object' );
# $res =~ s/A{2}$//;
$res->replace( qr/A{2}$/, '' );
# diag( "$s3 now is = $res (" . ref( $res ) . ")" );

isa_ok( Module::Generic::Scalar->new( 'true' )->as_boolean, 'Module::Generic::Boolean', 'Scalar to boolean' );

my $bool_1 = Module::Generic::Scalar->new( 'true' )->as_boolean;
# diag( "\$bool_1 is '$bool_1'" );
ok( $bool_1 == 1, 'Scalar value to true boolean' );
ok( !Module::Generic::Scalar->new( 0 )->as_boolean, 'Scalar value to false boolean' );

# diag( "\$s = '$s'" );
$s->chomp;
is( $s, 'Hello world', 'chomp' );
$s->chop;
is( $s, 'Hello worl', 'chop' );
is( $s->crypt( 'key' ), 'keqUNAuo7.kCQ', 'crypt' );
is( $s->fc( 'Hello worl' ), 1, 'fc' );
is( Module::Generic::Scalar->new( '0xAf' )->hex, 175, 'hex' );
isa_ok( Module::Generic::Scalar->new( '0xAf' )->hex, 'Module::Generic::Number' );
is( $s->index( 'wo' ), 6, 'index' );
is( $s->index( 'world' ), -1, 'index not found' );
ok( !$s->is_alpha, 'Is alpha' );
ok( Module::Generic::Scalar->new( 'Hello' )->is_alpha, 'Is alpha ok' );
ok( Module::Generic::Scalar->new( 'Front242' )->is_alpha_numeric, 'Is alpha numeric' );
ok( !$s->is_empty, 'Is empty' );
my $empty = Module::Generic::Scalar->new( 'Hello' )->undef;
isa_ok( $empty, 'Module::Generic::Scalar' );
ok( !$empty->defined, 'Is undefined' );
ok( !$s->is_lower, 'Is lower (false)' );
ok( lc( $s ), 'Is lower (true)' );
ok( !Module::Generic::Scalar->new( 'Front242' )->is_numeric, 'Looks like a number' );
ok( Module::Generic::Scalar->new( 'Hello' )->uc->is_upper, 'Is all caps' );
is( Module::Generic::Scalar->new( 'Hello' )->lc, 'hello', 'Small caps' );
is( Module::Generic::Scalar->new( 'HELLO' )->lcfirst, 'hELLO', 'lcfirst' );
is( Module::Generic::Scalar->new( 'Hello' )->left( 2 ), 'He', 'left' );
is( $s->length, 10, 'length' );
is( Module::Generic::Scalar->new( '     Hello  ' )->trim, 'Hello', 'trim' );
is( Module::Generic::Scalar->new( '     Hello  ' )->ltrim, 'Hello  ', 'ltrim' );
ok( $s->match( qr/[[:blank:]]+worl/ ), 'Regexp match' );
is( Module::Generic::Scalar->new( 'J' )->ord, 74, 'ord' );
$s->trim;
is( $s->pad( 3, 'x' ), 'xxxHello worl', 'pad at start' );
is( $s->pad( -3, 'z' ), 'xxxHello worlzzz', 'pad at end' );
$s->replace( 'xxx', '' );
is( $s, 'Hello worlzzz', 'Replace' );
$s->replace( qr/z{3}/, '' );
is( $s, 'Hello worl', 'Replace2' );
is( $s->quotemeta, 'Hello\ worl', 'quotemeta' );
is( $s->reset->length, 0, 'reset' );
$s .= 'I disapprove of what you say, but I will defend to the death your right to say it';
isa_ok( $s, 'Module::Generic::Scalar', 'Scalar assignment' );
is( $s->clone->capitalise, 'I Disapprove of What You Say, but I Will Defend to the Death Your Right to Say It', 'Capitalise' );
is( Module::Generic::Scalar->new( 'Hello' )->reverse, 'olleH', 'reverse' );
is( $s->rindex( 'I' ), 34, 'rindex' );
is( $s->rindex( 'I', 40 ), 34, 'rindex with position' );
is( Module::Generic::Scalar->new( 'Hello world%%%%' )->rtrim( '%' ), 'Hello world', 'rtrim' );
is( $s->clone->set( 'Bonjour' ), 'Bonjour', 'set' );
isa_ok( $s->split( qr/[[:blank:]]+/ ), 'Module::Generic::Array', 'split -> array' );
is( Module::Generic::Scalar->new( 'Hello Ms %s.' )->sprintf( 'Jones' ), 'Hello Ms Jones.', 'sprintf' );
is( $s->substr( 2, 13 ), 'disapprove of', 'substr' );
is( $s->substr( 2, 13, 'really do not approve' ), 'disapprove of', 'substr substituted part' );
is( $s, 'I really do not approve what you say, but I will defend to the death your right to say it', 'substr -> substitution' );

