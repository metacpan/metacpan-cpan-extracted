# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use constant CKSUM => 3763067826;
use constant SIZE => 333;

my ($x, $y, $X, $Y);
my (@lines, $lines);

use Test::More tests => 10;
use File::Temp qw(tempfile);
BEGIN { use_ok('String::CRC::Cksum' ) }

my $handle = tempfile();

# gather ye rosebuds while ye may
while(<DATA>) {
    s/\s+$//;      # avoid binmode problems on dossy platforms
    push @lines, $_;
    $lines .= $_;
    print $handle $_;
}
## cksum of the poem is CKSUM SIZE - let's prove it

my $cksum = String::CRC::Cksum->new;
($x, $y) = $cksum->result;
ok($x == 4294967295 && $y == 0, 'result operation after new');

$cksum->add($_) foreach @lines;

$x = $cksum->peek;
ok($x == CKSUM, 'peek operation, scalar');

($x, $y) = $cksum->peek;
ok($x == CKSUM && $y == SIZE, 'peek operation, list');

($x, $y) = $cksum->result;
ok($x == CKSUM && $y == SIZE, 'result operation, list');

($x, $y) = $cksum->result;
ok($x == 4294967295 && $y == 0, 'result operation after reset');

$x = String::CRC::Cksum::cksum $lines;
ok($x == CKSUM, 'basic algorithm in scalar context');

($x, $y) = String::CRC::Cksum::cksum $lines;
ok($x == CKSUM && $y == SIZE, 'basic algorithm in list context');

SKIP: {
    local *PFD;

    skip "Cannot read /etc/profile (probably not UNIX?)\n", 1
          unless open PFD, "< /etc/profile";

    ($x, $y) = String::CRC::Cksum::cksum(\*PFD);
    close PFD;

    # The following hard-coded path is probably tooooo harsh
    # However, the main thing is for me to check the algorithm
    # against the Real Thing if I ever muck around with it.
    #
    skip "Cannot execute /usr/bin/cksum (probably not UNIX?)\n", 1
          unless -x '/usr/bin/cksum';

    ($X, $Y) = split /\s+/, `/usr/bin/cksum < /etc/profile`;

    ok($x == $X && $y == $Y, 'reading filehandle');
};

seek $handle, 0, 0;
($x, $y) = String::CRC::Cksum::cksum($handle);
ok($x == CKSUM && $y == SIZE, 'reading handle');

__DATA__
*** Homer's Musical Scale ***
D'Oh! Oh dear! I spilt my beer!
Ray, a guy that buys me beer!
Me, the guy, who drinks the beer,
Far! A long long way for beer!
So, I think I'll have a beer!
La - ger, another name for beer!
Tea? No thanks I'll have a beer!
which will bring us back to...
D'Oh! D'Oh! D'Oh-D'Oh!
*** Homer's Musical Scale ***
__END__
