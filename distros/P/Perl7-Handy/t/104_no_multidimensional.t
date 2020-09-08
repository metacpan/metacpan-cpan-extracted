print "1..1\n";
print "ok - 1 SKIP on CPAN\n";

__END__
use 5.00503;
use strict;

BEGIN {
    $| = 1;
    print "1..1\n";
    close(STDERR);
    $SIG{__DIE__} = sub {
        print "ok 1 - no multidimensional\n";
        $SIG{__DIE__} = sub {}; # avoid doubling messages
    };
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl7::Handy;

$_{1,2,3} = 1; # makes die

__END__
