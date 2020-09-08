use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

$| = 1;
eval q{ use Test::Pod 1.48 tests => 1; };
if ($@) {
    print "1..1\n";
    print "ok 1 - SKIP\n";
}
else {
    pod_file_ok('lib/Perl7/Handy.pm');
}

__END__
