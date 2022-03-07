########################################################################
# test whether the debug-mode dispatcher works properly (via jobcount
# of zero).
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

my $madness = 'Parallel::Queue';
my $method  = 'runqueue';

my $work_d  = dirname dirname $0;
my $temp_d  = "$work_d/tmp";

my @argz =
(
    [ nofork => 0 ]
  , [ nofork => 1 ]
  , [ nofork => 2 ]
  , [   fork => 0 ]
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

    my $handler 
    = sub
    {
        my $path    = shift;

        unlink $path
        or die "Unlink: $path: $!";

        0
    };

    use_ok $madness
    or skip "'$madness' is unusable", 1;

    can_ok $madness, $method
    or skip "Your $madness lacks any '$method'";

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
            BAIL_OUT "Failed creating tempfile: '$dir' ($_)"
        }
        ( 1 .. 10 );

        my @queue   
        = map
        {
            my $path    = $_;
            sub
            {
                $DB::inhibit_exit = '';
                $path->$handler
            }
        }
        @pathz;

        my @unused  = $run->( $jobs, @queue );

        ok ! @unused, "Queue completed ($arg => $jobs)"
        or diag "Remaining queue:\n", explain \@unused;

        if( my @cruft = grep { -e } @pathz )
        {
            fail 'Skipped files.';
            diag explain \@cruft;
        }
    }
}

done_testing;
__END__
