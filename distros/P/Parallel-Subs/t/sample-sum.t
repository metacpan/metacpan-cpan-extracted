use strict;
use warnings;

use Test::More;

use_ok 'Parallel::Subs';

use Parallel::Subs;

my $sum;

sub work_to_do {
    my ( $a, $b ) = @_;
    return sub {
    	note "Running in parallel from process $$";
        # need some time to execute...
        # return 42;
        # return { value => 42 };
        # return [ 1..9 ];
        return $a * $b;
        }
}

sub read_result {
    my $result = shift;

    $sum += $result;
}

my $p = Parallel::Subs->new();
$p->add(
    sub {
        my $time = int( rand(2) );
        sleep($time);
        return { number => 1, time => $time };
    },
    sub {
        # run from the main process once the kid process has finished its work
        #   to access return values from previous sub
        my $result = shift;
        $sum += $result->{number};

        return;
    }
    )->add( work_to_do( 1, 2 ), \&read_result )
    ->add( work_to_do( 3, 4 ),  \&read_result )
    ->add( work_to_do( 5, 6 ),  \&read_result )
    ->add( work_to_do( 7, 8 ),  \&read_result )
    ->add( work_to_do( 9, 10 ), \&read_result );

$p->wait_for_all();

is $sum, 191;

done_testing;
