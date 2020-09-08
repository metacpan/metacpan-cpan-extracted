print "1..1\n";
print "ok - 1 SKIP on CPAN\n";

__END__
use 5.00503;
### use strict; ### This script must do test "strict feature by Perl7::Handy"

BEGIN {
    $| = 1;
    print "1..1\n";
    close(STDERR);
    $SIG{__DIE__} = sub {
        print "ok 1 - use strict\n";
        $SIG{__DIE__} = sub {}; # avoid doubling messages
    };
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl7::Handy;

$var = 1; # makes die

__END__
