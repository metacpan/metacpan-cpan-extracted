use 5.00503;
use strict;
BEGIN { $|=1; print "1..2\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Modern::Open;
use Fcntl;

my $rc = 0;

$rc = sysopen(FILE,$0,O_RDONLY);
ok($rc, q{sysopen(FILE,$0,O_RDONLY)});
if ($rc) {
    local $_ = fileno(FILE);
    close(FILE);
}

$rc = sysopen(my $fh,$0,O_RDONLY);
ok($rc, q{sysopen(my $fh,$0,O_RDONLY)});
if ($rc) {
    close($fh);
}

__END__
