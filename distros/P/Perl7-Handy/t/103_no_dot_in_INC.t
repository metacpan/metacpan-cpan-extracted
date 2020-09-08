use 5.00503;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl7::Handy;

$| = 1;
print "1..1\n";
if (grep {$_ eq '.'} @INC) {
    print qq{not ok 1 - ".(dot)" in \@INC\n};
}
else {
    print qq{ok 1 - ".(dot)" in \@INC\n};
}

__END__
