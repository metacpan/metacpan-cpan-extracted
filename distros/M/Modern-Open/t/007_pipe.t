use 5.00503;
use strict;
BEGIN { $|=1; print "1..2\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Modern::Open;

my $rc = 0;

$rc = pipe(README,WRITEME);
ok($rc, q{pipe(README,WRITEME)});
if ($rc) {
    local $_ = fileno(README);
    close(README);
    local $_ = fileno(WRITEME);
    close(WRITEME);
}

$rc = pipe(my $readme,my $writeme);
ok($rc, q{pipe(my $readme,my $writeme)});
if ($rc) {
    close($readme);
    close($writeme);
}

__END__
