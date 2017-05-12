# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..257\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNS::ToolKit qw(parse_char);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2-257	check all characters
foreach(0x0..0xFF) {
  my($b,$h,$d,$a) = &parse_char($_);
# print "$b   $h   $d   $a\n";
# next line only works in 5.6 and up
  if ( $] > 5.006 && eval("0b${b}") != $_ ) {
    print "binary conversion failure $b\nnot ";
    last;
  } elsif ( eval($h) != $_ ) {
    print "hex conversion failure $h\nnot ";
    last;
  } elsif ( $d != $_ ) {
    print "decimal conversion failure $d\nnot ";
    last;
  } elsif ( $a && $a ne pack("C",$_) ) {
    print "ascii conversion failure $a, ",pack("C",$_),"\nnot ";
    last;
  }
  &ok;
}
