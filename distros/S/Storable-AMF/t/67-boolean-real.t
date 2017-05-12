#===============================================================================
# vim: ts=8 et sw=4 sts=4
#
#         FILE:  66-boolean-3.t
#         COMMENT code taken from boolean-patch 
#===============================================================================


use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(parse_option freeze thaw new_amfdate);
use Storable::AMF  qw(thaw0 freeze0 thaw3 freeze3);

eval {
	require boolean;
	boolean->import(":all"); # imports true false isTrue isFalse
};
if ( $@ ){
	eval "use Test::More qw(skip_all) => 'boolean hasn\\'t installed'";
	exit;
}


my $total = 14;
eval "use Test::More tests=>$total;";
warn($@) && exit if $@;
my $nop = parse_option('prefer_number, json_boolean');
our $var;
#goto ABC;

# constants
ok( !is_amf_boolean ( 1 ),    'perl bool context not converted()');
ok( !is_amf_boolean ( 0 ),    'perl bool context not converted()');
ok( !is_amf_boolean ( '' ),    'perl bool context not converted()');
ok( !is_amf_boolean ( ! !1 ),    'perl bool context not converted(t)');
ok( !is_amf_boolean ( ! !0 ),    'perl bool context not converted(f)');
ok( is_amf_boolean ( true() ),   '"boolean" true');
ok( is_amf_boolean ( false() ),   '"boolean" false');

# Vars
ok( !is_amf_boolean ( $a = 4 ),      'int var');
ok( !is_amf_boolean ( $a = 4.0 ), 'double var');
ok( !is_amf_boolean ( $a = "4" ),     'str var');
ok( is_amf_boolean(  $a = true() ),  'boolean var');
ok( is_amf_boolean(  $a = false() ),  'boolean var');
ok( is_amf_boolean(  $a = true(), 1), "true" );
ok( is_amf_boolean(  $a = false(), 0), "false" );

sub is_amf_boolean{
	is_amf0_boolean( @_  ) && is_amf3_boolean( @_  );
}
sub is_amf0_boolean{
	return '' unless ord( my $s = freeze0( $_[0], )) == 1;
	return 1 unless defined $_[1];
	my $byte1 = ord( substr($s,1));
	return 1 if $_[1]  && $byte1 == 1;
	return 1 if !$_[1] && $byte1 == 0;
	return '';
}
sub is_amf3_boolean{
	my $header = ord( freeze3( $_[0] ));
	return $header == 2 || $header == 3 unless defined $_[1];
	return $header == 2 if !$_[1];
	return $header == 3 if $_[1]
}
