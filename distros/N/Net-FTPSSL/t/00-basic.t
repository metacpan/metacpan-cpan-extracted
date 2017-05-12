#!/usr/bin/perl -w

use Test::More tests => 4;
# plan tests => 3;

BEGIN {
   use_ok('Net::SSLeay');   # Added for the Smoke Tester's benifit.
   use_ok('Net::FTPSSL');
}

ok(1, 'Net::FTPSSL loaded.');

my $res = test_caller ();
ok ($res, "Verifying caller func available for use in FTPSSL");

# if ($res) {
#    diag( "\nNet::FTPSSL loaded properly." );
# } else {
#    diag("\nNet::FTPSSL loaded properly, but will have issues with caller().");
# }


# Tells us early on if the current version of perl doesn't support this.
# Means that the caller logic in FTPSSL won't work if this test fails!
# Done since I'm developing & testing with perl v5.8.8 only.
sub test_caller {
   my $func = __PACKAGE__ . "::test_caller";

   my $c = (caller(1))[3];   # Should always be undef here!
   $c = ""  unless (defined $c);

   return ( (caller(0))[3] eq $func && $c eq "" &&
            test2 ( (caller(0))[3] ) &&
            Zapper123::ztest1 ( (caller(0))[3] ) );
}

sub test2 {
   my $func = __PACKAGE__ . "::test2";

   return ( (caller(1))[3] eq $_[0] && (caller(0))[3] eq $func );
}


package Zapper123;

sub ztest1 {
   my $func = __PACKAGE__ . "::ztest1";

   return ( (caller(1))[3] eq $_[0] &&
            (caller(0))[3] eq $func &&
            main::test2 ( (caller(0))[3] ) );
}

# vim:ft=perl:
