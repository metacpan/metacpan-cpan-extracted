# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 11 };
use Net::FTP;
use Net::FTP::blat;
ok('duh'); # If we made it this far, we're ok.

#########################

# We need access to a ftp server we can write to to test
# writing ability --- sorry but I don't want to honor any FTP server
# in particular with getting hit by CPAN testing.
#
# Okay, I have created username "blat" passwr "test0" on ftp.tipjar.com
# for the purposes of testing this module.  Anyone found abusing this
# account will be referred to the Perl Mongers disciplinary committee
# for tattooing.

#test 2
ok(my $f = (
           Net::FTP->new('ftp.tipjar.com')
    or     exit(0)  #### looks like my FTP server is down
  ));

$f->binary();

#test 3
ok($f->login(blat => 'test0'));

my $filename = rand(10000);
my $data = rand(10000);

#test 4
ok($data, $f->blat($data, $filename));

# and again, with leading spaces, because I like leading spaces
my $data2 = 2.3 * $data;


#test 5
ok($data2, $f->blat($data2, " $filename"));

my $copy2;
#test 6
ok($data2, $f->slurp(" $filename", $copy2));

#test 7
ok($data2, $copy2);

# original should still be in spaceless version

#test 8
ok($data, $f->slurp($filename));

# and two leading spaces should be undefined.
#test 9
ok( !defined($f->slurp("  $filename")));

print "cleanup\n";
ok($f->delete($filename));
ok($f->delete(" $filename"));

