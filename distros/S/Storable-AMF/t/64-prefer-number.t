use strict;
# vim: ts=8 et sw=4 sts=4
use ExtUtils::testlib;
use Storable::AMF0 qw(parse_option freeze thaw);

my $total = 44 ;
#*CORE::GLOBAL::caller = sub { CORE::caller($_[0] + $Carp::CarpLevel + 1) }; 
use warnings;
eval "use Test::More tests=>$total;";
warn $@ if $@;
my $nop = parse_option('prefer_number');
our $var;


# constants
ok( !is_amf_string ( 4 ),      'int constant');
ok( !is_amf_string ( 4.0 ), 'double constant');
ok( is_amf_string ( "4" ),     'str constant');

ok( !is_amf_string ( 4  , $nop ),      'int constant not changed');
ok( !is_amf_string ( 4.0 ,$nop ), 'double constant not changed');
ok( is_amf_string ( "4",  $nop ),     'str constant not changed');

# Vars
ok( !is_amf_string ( $a = 4 ),      'int var');
ok( !is_amf_string ( $a = 4.0 ), 'double var');
ok( is_amf_string (  $a = "4" ),     'str var');

ok( !is_amf_string ( $a = 4   , $nop ),     'int var not changed');
ok( !is_amf_string ( $a = 4.0 , $nop ),  'double var not changed');
ok( is_amf_string (  $a ="4"  , $nop ),     'str var not changed');

# IntVar
$a = 1;
$b = "$a";
$var = 'Int';
ok(    is_amf_string($a)			 , "$var converted  is   a string"  );
ok( !  is_amf_string(0+$a)		 , "$var 0+converted     is double" );
ok( !  is_amf_string(0.0+$a,$nop), "$var 0.0+converted   is double" );
ok( !  is_amf_string($a, $nop)   , "$var converted again is double" );


# IntVar *
$a = 1;
$b = "".$a;
$var = "Int++";
ok(    is_amf_string($a)			 , "$var converted  is   a string"  );
ok( !  is_amf_string(0+$a)		 , "$var 0+converted     is double" );
ok( !  is_amf_string(0.0+$a,$nop), "$var 0.0+converted   is double" );
ok( !  is_amf_string($a, $nop)   , "$var converted again is double" );

# DoubleVar
$a = 1.0;
$b = "$a";
$var = "Double";

my %string_number=(0=>1,2=>1);
ok(    $string_number{ byte_amf_string($a)} , "$var converted  is   a string"  );
ok( !  is_amf_string(0+$a)		 , "$var 0+converted     is double" );
ok( !  is_amf_string(0.0+$a,$nop), "$var 0.0+converted   is double" );
ok( !  is_amf_string($a, $nop)   , "$var converted again is double" );


# DoubleVar *
$a = 1.0;
$b = "".$a;
$var = "Double++";
ok(    $string_number{ byte_amf_string($a)}, "$var converted  is   a string"  );
ok( !  is_amf_string(0+$a)		 , "$var 0+converted     is double" );
ok( !  is_amf_string(0.0+$a,$nop), "$var 0.0+converted   is double" );
ok( !  is_amf_string($a, $nop)   , "$var converted again is double" );

#############################################
#             String
#############################################

$a = "1";
$var = "Str 1";

ok(    is_amf_string($a)		 , "$var converted  is    a string"  );
ok(    is_amf_string($a, $nop)	 , "$var converted agn is a string"  );
ok( !  is_amf_string(0+$a)		 , "$var 0+converted     is double" );
ok( !  is_amf_string(0.0+$a,$nop), "$var 0.0+converted   is double" );
ok(    is_amf_string($a,     )   , "$var converted       is double" );
ok( !  is_amf_string($a, $nop)   , "$var converted again is double" );
ok(    is_amf_string(''.$a, $nop), "$var ''.converted again is str" );
ok(    is_amf_string(''.$a, )   ,  "$var ''.converted       is str" );


$a = "1.0";
$var = "Str 1.0";

ok(    is_amf_string($a)		 , "$var converted  is   a string"  );
ok(    is_amf_string($a, $nop)	 , "$var converted again is a string"  );
ok( !  is_amf_string(0+$a)		 , "$var 0+converted     is double" );
ok( !  is_amf_string(0.0+$a,$nop), "$var 0.0+converted   is double" );
ok(    is_amf_string($a,)        , "$var converted       is double" );
ok( !  is_amf_string($a, $nop)   , "$var converted again is double" );
ok(    is_amf_string(''.$a, $nop), "$var ''.converted again is str" );
ok(    is_amf_string(''.$a, )   ,  "$var ''.converted       is str" );



sub is_amf_string{
	ord( freeze( $_[0], $_[1]||0 )) == 2;
}
sub byte_amf_string{
	ord( freeze( $_[0], $_[1]||0 ));
}
