########################################################################
# test large list using next_job with a lightweight class.
########################################################################
use v5.24;

use Test::More;

use File::Basename  qw( basename dirname    );
use File::Temp      qw( tempdir tempfile    );
use FindBin         qw( $Bin                );
use Symbol          qw( qualify_to_ref      );

########################################################################
# package variables & sanity checks
########################################################################

my $base0   = basename $0 => qw( .t );
my $tmpl8   = "$base0.XXXX";

my $madness = 'Parallel::Queue::Manager';
my $method  = 'runqueue';

my $work_d  = dirname dirname $0;
my $temp_d  = "$work_d/tmp";

my @argz =
(
    # first two have same result: non-forking queue
    [ nofork => 0 ]
  , [   fork => 0 ]

    # job count has no effect w/ nofork
  , [ nofork => 1 ]
  , [ nofork => 2 ]


    # finally, we begin forking
  , [   fork => 1 ]
  , [   fork => 2 ]
);

my @fixed
= qw
(
    verbose 
    finish
);

my @queue
= qw
(
    0
    0
    1
    0
    0
);

########################################################################
# run in debug mode without forking/threading off
# the individual jobs.

SKIP:
{
    use_ok $madness 
    or skip "'$madness' is unusable", 1;

    my $handler
    = sub
    {
        $DB::inhibit_exit = '';

        # just reutrn the first arg

        shift
    };

    for( @argz )
    {
        my ( $fork, $jobs ) = @$_;
        note "$fork => $method->( $jobs, ... )";

        my $qmgr
        = eval
        {
            $madness
            ->new( $handler, @queue )
            ->configure( $fork => @fixed )
            ->runqueue( $jobs )
        }
        // fail "Exception: $method w/ $fork => $jobs, $@";

        # this time we expect something left on the queue.
        # no guarantee what order the job returned failure,
        # but the queue is large enough to have at least
        # one item left over.

        my $queue   = $qmgr->queue;

        ok ! @$queue, "Queue completed ($fork, $jobs)";
    }
}

done_testing;
__END__
