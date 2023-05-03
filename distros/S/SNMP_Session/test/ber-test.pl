#!/usr/local/bin/perl -w
######################################################################
### Name:	  ber-test.pl
### Date Created: Sat Feb  1 16:09:46 1997
### Author:	  Simon Leinen  <simon@switch.ch>
### RCS $Id: ber-test.pl,v 1.9 2004-02-17 21:38:56 leinen Exp $
######################################################################
### Regression Tests for BER encoding/decoding
######################################################################

use BER;
use Carp;
use integer;

use strict;

## Prototypes
sub regression_test ();
sub encode_int_test ($$);
sub decode_intlike_test ($$);
sub eq_test ($$);
sub equal_test ($$);
sub string_hex ($ );
sub encode_int_regression_test ();

my $exitcode = 0;
regression_test;
exit ($exitcode);

#### Regression Tests

sub regression_test ()
{
    eq_test ('encode_string ("public")', "\x04\x06\x70\x75\x62\x6C\x69\x63");
    eq_test ('encode_ip_address ("\x82\x3b\x04\x02")', "\x40\x04\x82\x3b\x04\x02");
    eq_test ('encode_ip_address ("130.59.4.2")', "\x40\x04\x82\x3b\x04\x02");
    encode_int_test (0x4aec3116, "\x02\x04\x4A\xEC\x31\x16");
    encode_int_test (0xec3116, "\x02\x04\x00\xEC\x31\x16");
    encode_int_test (0x3c3116, "\x02\x03\x3C\x31\x16");
    encode_int_test (-1234, "\x02\x02\xfb\x2e");
    decode_intlike_test ('"\x02\x01\x01"', 1);
    decode_intlike_test ('"\x02\x01\xff"', -1);
    decode_intlike_test ('"\x02\x02\x01\x02"', 258);
    decode_intlike_test ('"\x02\x02\xff\xff"', -1);
    decode_intlike_test ('"\x02\x03\x00\xff\xfe"', 65534);
    decode_intlike_test ('"\x02\x03\xff\xff\xfd"', -3);
    decode_intlike_test ('"\x02\x04\x00\xff\xff\xfd"', 16777213);
    decode_intlike_test ('"\x02\x04\xff\xff\xff\xfc"', -4);
    decode_intlike_test ('"\x02\x05\x00\xff\xff\xff\xfc"', 4294967292);

    ## Tests for integers > 2^32
    ##
    ## For really big integers (those that don't have an exact double
    ## representation, I guess), we have to write the comparands as
    ## strings, because otherwise they will be converted to NaN by
    ## Perl.  The comparisons still work right thanks to Math::BigInt,
    ## which is used by BER.pm for large integers.
    ##
    decode_intlike_test ('"\x02\x06\x00\x01\x00\x00\x00\x00"', 4294967296);
    decode_intlike_test ('"\x02\x09\x00\xff\xff\xff\xff\xff\xff\xff\xff"',
			 "18446744073709551615");
    use Math::BigInt lib => 'GMP';
    {
	## We have to disable warnings because of Math::BigInt
	##
	local $^W = 0;
	eq_test ('encode_int (new Math::BigInt ("18446744073709551615"))',
		 "\x02\x09\x00\xff\xff\xff\xff\xff\xff\xff\xff");
    }

    eq_test ('(BER::decode_string ("\x04\x06public"))[0]', "public");
    eq_test ('(BER::decode_oid ("\x06\x04\x01\x03\x06\x01"))[0]', 
	     "\x06\x04\x01\x03\x06\x01");
    die unless encode_int_regression_test ();
}

sub encode_int_test ($$) {
    my ($int, $encoded) = @_;
    eq_test ("encode_int ($int)", $encoded);
}


sub decode_intlike_test ($$) {
    my ($pdu, $wanted) = @_;
    equal_test ("(BER::decode_intlike ($pdu))[0]", $wanted);
}

sub eq_test ($$) {
    my ($expr, $wanted) = @_;
    my $result;
    undef $@;
    $result = eval $expr;
    croak "$@" if $@;
    (warn $expr." => ".string_hex ($result)." != ".string_hex ($wanted)), ++$exitcode
	unless $result eq $wanted;
}

sub equal_test ($$) {
    my ($expr, $wanted) = @_;
    my $result;
    undef $@;
    $result = eval $expr;
    croak "$@" if $@;
    (warn $expr." => ".$result." != ".$wanted), ++$exitcode
	unless $result == $wanted;
}

sub string_hex ($ ) {
    my $result = '';
    my ($string) = @_;
    my ($i);
    for ($i = 0; $i < length $string; ++$i) {
	$result .= sprintf "%02x", ord (substr ($string, $i, 1));
    }
    $result;
}

### Test cases and harness kindly contributed by
### Mike Mitchell <mcm@unx.sas.com>
###
sub encode_int_regression_test () {
  my $try;
  my @tries = (
	       0, 1, 126, 127, 128, 129, 254, 255, 256, 257, 32766, 32767,
	       32768, 32769, 65534, 65535, 65536, 65537, 8388606, 8388607,
	       8388608, 8388609, 16777214, 16777215, 16777216, 16777217, 
	       -1, -126, -127, -128, -129, -254, -255, -256, -257, -32766, -32767,
	       -32768, -32769, -65534, -65535, -65536, -65537, -8388606, -8388607,
	       -8388608, -8388609, -16777214, -16777215, -16777216, -16777217,
	       5921370, -5921370, 2147483646, 2147483647, -2147483647, -2147483648
	      ); 
my $expected = <<EOM;
0: 02 01 00 
1: 02 01 01 
126: 02 01 7e 
127: 02 01 7f 
128: 02 02 00 80 
129: 02 02 00 81 
254: 02 02 00 fe 
255: 02 02 00 ff 
256: 02 02 01 00 
257: 02 02 01 01 
32766: 02 02 7f fe 
32767: 02 02 7f ff 
32768: 02 03 00 80 00 
32769: 02 03 00 80 01 
65534: 02 03 00 ff fe 
65535: 02 03 00 ff ff 
65536: 02 03 01 00 00 
65537: 02 03 01 00 01 
8388606: 02 03 7f ff fe 
8388607: 02 03 7f ff ff 
8388608: 02 04 00 80 00 00 
8388609: 02 04 00 80 00 01 
16777214: 02 04 00 ff ff fe 
16777215: 02 04 00 ff ff ff 
16777216: 02 04 01 00 00 00 
16777217: 02 04 01 00 00 01 
-1: 02 01 ff 
-126: 02 01 82 
-127: 02 01 81 
-128: 02 01 80 
-129: 02 02 ff 7f 
-254: 02 02 ff 02 
-255: 02 02 ff 01 
-256: 02 02 ff 00 
-257: 02 02 fe ff 
-32766: 02 02 80 02 
-32767: 02 02 80 01 
-32768: 02 02 80 00 
-32769: 02 03 ff 7f ff 
-65534: 02 03 ff 00 02 
-65535: 02 03 ff 00 01 
-65536: 02 03 ff 00 00 
-65537: 02 03 fe ff ff 
-8388606: 02 03 80 00 02 
-8388607: 02 03 80 00 01 
-8388608: 02 03 80 00 00 
-8388609: 02 04 ff 7f ff ff 
-16777214: 02 04 ff 00 00 02 
-16777215: 02 04 ff 00 00 01 
-16777216: 02 04 ff 00 00 00 
-16777217: 02 04 fe ff ff ff 
5921370: 02 03 5a 5a 5a 
-5921370: 02 03 a5 a5 a6 
2147483646: 02 04 7f ff ff fe 
2147483647: 02 04 7f ff ff ff 
-2147483647: 02 04 80 00 00 01 
-2147483648: 02 04 80 00 00 00 
EOM

  my @wanted = split ("\n", $expected);

  foreach $try (@tries) {
    my ($r, $jnk, $val, @vals, $output, $wanted);
    undef @vals;
    
    $r = BER::encode_int($try);
    
    $output = "$try: ";
    @vals = unpack("C*", $r);
    foreach $val (@vals)
      {
	$output .= sprintf ("%02x ", $val);
      }
    ($r, $jnk) = BER::decode_intlike_s($r, 1);
    $output .= "Decode to $r didn't match!" if ($r != $try);
    $wanted = shift @wanted;
    die "Mismatch in encode_int_regression_test:\n"
      ."< $wanted\n> $output" unless $output eq $wanted;
  }
  1;
}
