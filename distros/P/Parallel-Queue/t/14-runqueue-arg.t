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
  , [   fork => 4 ]
);

########################################################################
# run in debug mode without forking/threading off
# the individual jobs.

SKIP:
{
    for( $temp_d )
    {
        use autodie;

        # may need to stat it with -d and -r if it
        # has to be created. 

        -d      || mkdir $temp_d, 02770;
        -r      || skip "Non-readable: '$_'";
        -w _    || skip "Non-writeable: '$_'";
    }

    use_ok $madness 
    or skip "'$madness' is unusable", 1;

    my $handler
    = sub
    {
        $DB::inhibit_exit = '';

        use autodie;
        unlink @_;
        return
    };

    for( @argz )
    {
        my ( $fork, $jobs ) = @$_;
        note "$fork => $method->( $jobs, ... )";

        my $dir = tempdir DIR => $temp_d, CLEANUP => 1;
        my @pathz   
        = sort
        map
        {
            ( tempfile $tmpl8, DIR => $dir )[1]
            or
            skip "Failed creating tempfile: '$dir' ($_)"
        }
        ( 1 .. $jobs + 4 );

        my $qmgr
        = eval
        {
            my $qm
            = $madness
            ->new( $handler )
            ->configure( $fork )
            ;

            $qm->queue  = \@pathz;
            $qm->runqueue( $jobs )
        }
        // fail "Exception: $method w/ $fork => $jobs, $@";

        my $queue   = $qmgr->queue;

        ok ! @$queue, "Queue completed ($fork, $jobs)"
        or diag "Remaining queue:\n", explain $queue;

        if( my @cruft = grep { -e } @pathz )
        {
            fail 'Skipped files.';
            diag explain \@cruft;
        }
        else
        {
            pass 'Queue executed.'
        }
    }
}

done_testing;
__END__
