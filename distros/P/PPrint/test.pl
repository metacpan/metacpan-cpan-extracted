use strict;
use warnings;
use lib '.';

use PPrint;

# this piece of black magic is to make sure PPrint at least compiles
BEGIN { $| = 1; print "1..9\n"; }
my $loaded = 1;
END { print "not ok 1\n" unless $loaded}
print "ok 1\n";

my @tests = ();

# YAHGTS: Yet Another HomeGrown Testing System

sub install_test {
    my ($code,$desc) = @_;
    my $number = 1 + scalar @tests;
    push @tests, sub {
        print "$desc:\n";
        unless ($code->()) {
            print "not ";
        }
        print "ok $number\n";
    }
}

sub eq_test (&$$){
    my ($code, $expected, $desc) = @_;
    my $number = 1 + scalar @tests;
    push @tests, sub {
        print "$desc:\n";
        my $ret = $code->();
        if ($ret eq $expected) {
            print "ok $number\n";
        } else {
            print "not ok $number\n";
            print "expected: $expected\n";
            print "but got : $ret\n";
        }
    }
}

eq_test { pprint("~~"); } "~", "~ directive #1";

eq_test { pprint("~4~"); } "~~~~", "~ directive #2";

eq_test { pprint("~'v~", 2); } "~~", "~ directive #3 (with 'v param)";

eq_test { pprint("~n"); } "\n", "n directive #1";

eq_test { pprint("~4n"); } chr(0x0A) x 4, "n directive #2";

eq_test { pprint("~2,'dn"); } (chr(0x0D) . chr(0x0A)) x 2, "n directive #3";

eq_test { pprint("~r", -3); } "-3", "r directive #1";

eq_test { pprint("~2,8,'0,'-,2:;r",10) } "00+10-10", "r directive #2";

eq_test { pprint("~,8r", 0xff) } "     255", "r directive #3";

eq_test { pprint("~2r", 0xff) } "11111111", "r directive #4";

eq_test { pprint("~j", [ 1, 2, 3] ); } "1 2 3", "j directive #1";

eq_test { pprint("~',j", [ 1, 2, 3 ] ); } "1,2,3", "j directive #2";

eq_test { pprint("~',,'[,']j", [1,2,3] );} "[1,2,3]", "j directive #3";

# now we run the test

$_->() for @tests;
