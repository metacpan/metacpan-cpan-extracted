use 5.00503;
use strict;

BEGIN {
    $| = 1;
    print "1..1\n";
    if ($] < 5.006) {
        print "ok 1 - SKIP use warnings\n";
        exit;
    }
    close(STDERR);
    $SIG{__WARN__} = sub { print "ok 1 - use warnings\n" };
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl7::Handy;

$_ = '1:' + 2; # makes warnings

__END__
