# vim: ts=8 sw=4 sts=4 expandtab
# vim: ts=8 et sw=4 sts=4
#===============================================================================
#
#         FILE:  66-boolean-3.t
#         COMMENT code taken from boolean-patch 
#===============================================================================


use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(parse_option freeze thaw new_amfdate);
use Storable::AMF  qw(thaw0 freeze0 thaw3 freeze3);

sub boolean{
    return bless \(my $s = $_[0]), 'boolean';
}
sub true(){
    return boolean(1); 
}
sub false(){
    return boolean('');
}

BEGIN{
if (!exists &JSON::XS::true){
    eval <<'CODE';
    sub JSON::XS::true{
	    return bless \(my $o = 1), "JSON::PP::Boolean" ;
    }
    sub JSON::XS::false{
	    return bless \(my $o = 0), "JSON::PP::Boolean";
    }
CODE
    warn $@ if $@;
}}

my $total = 17 + 8 + 8 + 2 + 11;
eval "use Test::More tests=>$total;";
warn $@ if $@;
my $nop = parse_option('prefer_number, json_boolean');
my $json_true = JSON::XS::true;
my $json_false = JSON::XS::false;
my $boolean_true = true;
my $boolean_false = false;

# goto ABC;
# ABC:

# constants
ok( !is_amf_boolean ( ! !1 ),    'perl bool context not converted(t)');
ok( !is_amf_boolean ( ! !0 ),    'perl bool context not converted(f)');
ok( is_amf_boolean ( true ),   '"boolean" true');
ok( is_amf_boolean ( false ),   '"boolean" false');
ok( is_amf_boolean ( boolean(undef) ),   '"boolean(undef)"');
ok( is_amf_boolean ( boolean(0) ),	 '"boolean(0)"');
ok( is_amf_boolean ( boolean('') ),       "boolean('')");
ok( is_amf_boolean ( boolean(1) ),       '"boolean(1)"');
ok( is_amf_boolean ( JSON::XS::true() ),   'JSON::XS::true');
ok( is_amf_boolean ( JSON::XS::false() ),   'JSON::XS::false');

# Vars
ok( !is_amf_boolean ( $a = 4 ),      'int var');
ok( !is_amf_boolean ( $a = 4.0 ), 'double var');
ok( !is_amf_boolean ( $a = "4" ),     'str var');
ok( is_amf_boolean (  $a = JSON::XS::true ),  'JSON::XS bool var');
ok( is_amf_boolean (  $a = true ),  'boolean var');
ok( is_amf_boolean (  $a = JSON::XS::false ),  'JSON::XS bool var');
ok( is_amf_boolean (  $a = false ),  'boolean var');

my $object1 = {
    a => {a => 1},
    jxb1 => $json_true,
    jxb2 => $json_true,
    c => {a => 1, jxb3 => $json_true },
};
my $object2 = {
    a => {a => 1},
    jxb1 => $json_false,
    jxb2 => $json_false,
    c => {a => 1, jxb3 => $json_false },
};
# AMF0 half-trip (false, true)
is_deeply( freeze0($json_false), chr(1).chr(0), "halftrip false (r-A0)" );
is_deeply( freeze0($json_true) , chr(1).chr(1), "halftrip true  (r-A0)" );

is_deeply( thaw0(chr(1).chr(0), $nop), $json_false, "halftrip false (A0)" );
is_deeply( thaw0(chr(1).chr(1), $nop), $json_true,  "halftrip true  (A0)" );
is_deeply( thaw0(chr(1).chr(2), $nop), $json_true,  "halftrip true2 (A0)" );
is_deeply( thaw0(chr(1).chr(254), $nop), $json_true,  "halftrip true254 (A0)" );
is_deeply( thaw0(chr(1).chr(255), $nop), $json_true,  "halftrip true255 (A0)" );

# AMF3 half-trip (false, true)

is_deeply( thaw3(chr(2), $nop), $json_false, "halftrip false (A3)" );
is_deeply( thaw3(chr(3), $nop), $json_true,  "halftrip true  (A3)" );

is( freeze3( $json_false), chr(2),  "halftrip false (r-A3)" );
is( freeze3( $json_true ), chr(3),  "halftrip true  (r-A3)" );

# AMF0 roundtrip
is_deeply( amf0_roundtrip($object1), $object1, "roundtrip_1 multi-bool (A0)" );
is_deeply( amf0_roundtrip($object2), $object2, "roundtrip_2 multi-bool (A0)" );
is_deeply( amf0_roundtrip( true  ),  $json_true,  '"boolean" comes back as JSON::XS (A0)' );
is_deeply( amf0_roundtrip( false ), $json_false, '"boolean" comes back as JSON::XS (A0)' );
# AMF3 roundtrip
is_deeply( amf3_roundtrip($object1), $object1, "roundtrip_1 multi-bool (A3)" );
is_deeply( amf3_roundtrip($object2), $object2, "roundtrip_2 multi-bool (A3)" );
is_deeply( amf3_roundtrip( true ),  $json_true, '"boolean" comes back as JSON::XS (A3)' );
is_deeply( amf3_roundtrip( false ), $json_false, '"boolean" comes back as JSON::XS (A3)' );

# AMF0 Added more accurate tests 
isa_ok( amf0_roundtrip( true ) , ref $json_true );
isa_ok( amf0_roundtrip( $json_true ) , ref $json_true);
isa_ok( amf0_roundtrip( false ) , ref $json_false);
isa_ok( amf0_roundtrip( $json_false ) , ref $json_false);

# AMF3 Added more accurate tests 
isa_ok( amf3_roundtrip( true ), ref $json_true);
isa_ok( amf3_roundtrip( $json_true ), ref $json_true);
isa_ok( amf3_roundtrip( false ) , ref $json_false);
isa_ok( amf3_roundtrip( $json_false ) , ref $json_false);

ok( is_amf_boolean(  $a = JSON::XS::true(), 1), "true" );
ok( is_amf_boolean(  $a = JSON::XS::false(), 0), "false" );

sub is_amf_boolean{
    is_amf0_boolean( @_  ) && is_amf3_boolean( @_  );
}
sub is_amf0_boolean{
    my $s = freeze0( $_[0], );
    return '' if !defined $s;
    return '' unless ord( $s ) == 1;
    return 1 unless defined $_[1];
    my $byte1 = ord( substr($s,1));
    return 1 if $_[1]  && $byte1 == 1;
    return 1 if !$_[1] && $byte1 == 0;
    return '';
}
sub is_amf3_boolean{
    my $s = freeze3( $_[0] );
    return '' if !defined $s;
    my $header = ord( freeze3( $_[0] ));
    return $header == 2 || $header == 3 unless defined $_[1];
    return $header == 2 if !$_[1];
    return $header == 3 if $_[1]
}
sub amf0_roundtrip {
    my $src = shift;
    my $amf = freeze0( $src );
    my $struct = thaw0($amf, $nop);
    return $struct;
}
sub amf3_roundtrip {
    my $src = shift;
    my $amf = freeze3( $src );
    my $struct = thaw3($amf, $nop);
    return $struct;
}
