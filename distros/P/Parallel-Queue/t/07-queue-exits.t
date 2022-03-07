
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

use File::Spec::Functions
qw
(
    catdir
);

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

    use_ok $madness
    or skip "'$madness' is unusable", 1;

    can_ok $madness, $method
    or skip "Your $madness lacks any '$method'";

    my $run = __PACKAGE__->can( $method )
    or BAIL_OUT "This package cannot '$method'";

    my $dir     = tempdir DIR => $temp_d, CLEANUP => 1;

    for( @argz )
    {
        my ( $arg, $jobs ) = @$_;

        note "$arg => $method->( $jobs, ... )";

        $madness->configure( verbose => $arg );

        my $output  = "$dir/$arg-$jobs.out";

        my @queue   
        = map
        {
            my $i   = $_;

            sub { say "($arg $jobs) $i: $$"; return }
        }
        ( 1 .. 10 );

        if( open my $fh, '>', $output )
        {
            local *STDOUT   = $fh;
            local *STDERR   = $fh;

            my @unused = $run->( $jobs, @queue );

            ok ! @unused, "Queue completed ($arg => $jobs)"
            or diag "Remaining queue:\n", explain \@unused;

            say "\nQueue complete: $$";

            close $fh
            or diag "Failed close: '$output', $!";

            ok -s $output, 'Output has content.'
            or diag "Empty output: '$output'";
        }
        else
        {
            skip "Failed open: > '$output', $!", 1
        }

        # should only end up with one copy
        # of 'Queue complete.' in the file.

        my @linz
        = do
        {
            open my $fh, '<', $output
            or skip "Failed open: < '$output', $!", 1;

            grep /^Queue complete/, readline $fh
        };

        chomp @linz;

        ok 1 == @linz, 'One summary line.'
        or diag "Line copies:\n", explain \@linz;
    }
}

done_testing;
__END__
