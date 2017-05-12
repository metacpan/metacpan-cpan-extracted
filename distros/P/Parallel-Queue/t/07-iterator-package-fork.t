########################################################################
# test using runqueue as a class method -- also tests large job
# lists.
########################################################################

package PQ::Iterator;

use v5.10;
use strict;

use Test::More;

use Parallel::Queue qw( fork );

use Symbol  qw( qualify qualify_to_ref );

########################################################################
# create and drop a list of files. if any jobs are being dropped
# out of the queue then it'll show up here.

my $dir     = './tmp';
my $ext     = 'z';

-d $dir || mkdir $dir, 0777
or die "Unable to mkdir '$dir': $!";

unlink glob "$dir/$$.*";

my @queue
= map
{
    my $count = 8;

    my $pkg = qualify $_;

    *{ qualify_to_ref 'next_job', $pkg }
    = sub
    {
        --$count 
        or return;

        my $path    = "$dir/$$." . ++$ext;

        open my $fh, '>', $path
        or die "Botched open: '$path', $!";

        sub
        {
            unlink $path || die "Botched unlink: '$path', $!";

            ok ! -e $path, "Removed: '$path'";

            return
        }
    };

    $pkg
}
( 'a' .. 'c' );

my $cleanup
= sub
{
    eval { unlink glob "./tmp/$$*"; };
    eval { rmdir "./tmp" };

    ok ! -d './tmp', "Cleaned up './tmp'";

    return
};

my @unused  = eval { runqueue 0, @queue, $cleanup };

$@
? fail "Error in queue: $@"
: pass "Queue complete"
;

ok ! @unused, 'Queue completed';

done_testing;

__END__
