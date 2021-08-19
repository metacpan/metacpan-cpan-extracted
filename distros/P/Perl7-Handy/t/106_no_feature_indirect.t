use 5.00503;
use strict;

BEGIN {
    $| = 1;
    print "1..1\n";
    if ($] < 5.031009) {
        print "ok 1 - SKIP no feature qw(indirect)\n";
        exit;
    }
    close(STDERR);
    $SIG{__WARN__} = sub { print "ok 1 - no feature qw(indirect)\n"; undef $SIG{__WARN__}; };
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl7::Handy;

my $horse = new Horse;
print "not ok 1 - no feature qw(indirect)\n";

package Horse;
sub new { bless {}, $_[0] }

__END__
