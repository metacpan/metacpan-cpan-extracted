########################################################################
# test large list using next_job with a lightweight class.
########################################################################

use v5.24;
use strict;

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

my $madness = 'Parallel::Queue';
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

# avoid having to explicitly close the xterms.
$DB::inhibit_exit = 0;

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

    my $run = __PACKAGE__->can( $method )
    or BAIL_OUT "This package cannot '$method'";

    for( @argz )
    {
        my ( $arg, $jobs ) = @$_;
        note "$arg => $method->( $jobs, ... )";

        $madness->configure( $arg );

        my $dir = tempdir DIR => $temp_d, CLEANUP => 1;
        my @pathz   
        = sort
        map
        {
            ( tempfile $tmpl8, DIR => $dir )[1]
            or
            skip "Failed creating tempfile: '$dir' ($_)"
        }
        ( 1 .. 32 );

        my $handler
        = do
        {
            package Frobnicate;
            use Test::More;

            state $stub = sub{};

            sub next_job
            {
                my $queue   = shift;
                my $path    = shift @$queue
                or return;

                if( -e $path )
                {
                    sub
                    {
                        use autodie;
                        unlink $path;
                        return
                    }
                }
                else
                {
                    $stub
                }
            }

            bless \@pathz, __PACKAGE__
        };

        eval
        {
            $run->( $jobs, $handler );

            pass "$method completed ($arg, $jobs)."
        }
        // fail "Exception: $method w/ $arg => $jobs, $@";

        ok ! @$handler, "Queue empty ($arg, $jobs)."
        or diag "Remaining jobs:\n", explain $handler;

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
