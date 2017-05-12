

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

require SF::SF_form_secure;
$loaded = 1;
print "ok 1\n";

{
                $SF_form_secure::code = 'The_key';
                $SF_form_secure::exp = '';
                $SF_form_secure::ip_ct = '';

                 my $extra_code = 'Name:Password';

 my $stuff = SF_form_secure::x_secure(4, $extra_code, '');
 if ($stuff) {
      print "ok 2\n";
 }
 else {
      print "not ok 2\n";
 }
 $stuff = SF_form_secure::x_secure(5, $extra_code, $stuff);
 if ($stuff eq 1) {
      print "ok 3\n";
 }
 else {
      print "not ok 3\n";
 }
}

