use strict;
use warnings;
use Test::More;

=head1 Testing Parallel Loops

A simple test here. We run a foreach loop and in it, we send the results back.
We test the result structure and make sure it is what we expect. Then we do the same for a while loop

=cut

BEGIN { use_ok( 'Parallel::Loops' ); }

my $maxProcs = 2;
my $pl = new_ok( 'Parallel::Loops', [$maxProcs] );

# unit tests
{
    my @blessedArray;
    bless \@blessedArray, 'His::Highness';
    eval {
        $pl->share( \@blessedArray );
    };
    my $err = $@;
    $err
        or die "Expected exception when trying to share a blessed object";
    like(
        $err,
        qr/^Only unblessed hash and array refs are supported by share/,
        "trying to share a blessed array fails",
    );
}

{
    my %blessedHash;
    bless \%blessedHash, 'His::Highness';
    eval {
        $pl->share( \%blessedHash );
    };
    my $err = $@;
    $err
        or die "Expected exception when trying to share a blessed object";
    like(
        $err,
        qr/^Only unblessed hash and array refs are supported by share/,
        "trying to share a blessed hash fails",
    );
}

# integration tests
my @iterations = ( 0 .. 4 );

my %output;
$pl->share( \%output );

my @pids;
$pl->share( \@pids );

sub checkResults {
    my @seenPids;
    my $expectedStruct = {
        foo => 'FOO',
        bar => 'BAR'
    };
    foreach (@iterations) {
        my $out = $output{$_};
        if (defined $out->{pid} && $out->{pid} != $$) {
            pass("pid from child defined and good");
        } else {
            fail("pid from child has error");
        }
        push @seenPids, $out->{pid};
        is_deeply($out->{struct}, $expectedStruct, "Testing data transfer");
    }
    @seenPids = sort @seenPids;
    @pids = sort @pids;
    is_deeply(\@seenPids, \@pids, "Pids registered");
}

$pl->foreach(
    \@iterations,
    sub {
        $output{$_} = {
            pid => $$,
            struct => {
                foo => 'FOO',
                bar => 'BAR'
            }
        };
        push @pids, $$;
    }
);

checkResults();

%output = (); @pids = ();

my $i = -1;
$pl->while (
    sub { ++$i < scalar(@iterations) },
    sub {
        $output{$i} = {
            pid => $$,
            struct => {
                foo => 'FOO',
                bar => 'BAR'
            }
        };
        push @pids, $$;
    }
);
checkResults();

if ($$pl{workingSelect}) {
    $$pl{workingSelect} = 0;
    %output = (); @pids = ();

    my $i = -1;
    $pl->while (
        sub { ++$i < scalar(@iterations) },
        sub {
            $output{$i} = {
                pid => $$,
                struct => {
                    foo => 'FOO',
                    bar => 'BAR'
                }
            };
            push @pids, $$;
        }
    );
    checkResults();
    $$pl{workingSelect} = 1;
}

done_testing;
