use 5.00503;
use strict;

BEGIN {
    $| = 1;
    print "1..1\n";
    if ($] < 5.031009) {
        print "ok 1 - SKIP no feature qw(indirect)\n";
        exit(0);
    }
    close(STDERR);
    $SIG{__WARN__} =
    $SIG{__DIE__}  = sub {
        print "ok 1 - no feature qw(indirect)\n";
        $SIG{__WARN__} = sub {}; # avoid doubling messages
        $SIG{__DIE__}  = sub {}; # avoid doubling messages
        exit(0);
    };
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl7::Handy;

my $horse = new Horse;

package Horse;
sub new { bless {}, $_[0] }

__END__
