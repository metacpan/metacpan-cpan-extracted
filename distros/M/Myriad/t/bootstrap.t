use strict;
use warnings;

# We deliberately *avoid* Test::More here, because it pulls in
# an ever-changing kitchen sync full of awesomely-useful modules
# that will mess up our clean-namespace requirement

use Myriad::Bootstrap;

# We cannot call ->autoflush directly, since that'll pull in 10+ extra modules
{
    my $oldfh = select(STDOUT);
    $| = 1;
    select($oldfh);
}

eval {
    Myriad::Bootstrap->boot(sub {
        # Must *not* happen at compiletime, hence the require/import
        require Test::More;
        Test::More->import;
        pass('bootstrap success');
        done_testing();
    });
    1;
} or do {
    if ($@ =~ q{Can't locate Linux/Inotify2.pm}) {
        print "1..0 # SKIP Linux::Inotify2 not installed\n";
    } else {
        print "not ok - exception on ->boot, $@\n";
        print "1..1\n";
    }
};
