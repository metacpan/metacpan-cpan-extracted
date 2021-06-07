use 5.00503;
use strict;

BEGIN {
    $| = 1;
    print "1..1\n";
    if ($] < 5.020) {
        print "ok 1 - SKIP use feature qw(signatures)\n";
        exit;
    }
    close(STDERR);
    $SIG{__WARN__} = sub { print "not ok 1 - use feature qw(signatures)\n" };
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl7::Handy;

sub division ( $m, $n ) {
    eval { $m / $n }
}

print "ok 1 - use feature qw(signatures)\n";

__END__
