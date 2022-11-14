#Performance Probability test.
use strict;
use warnings;

use Test::Most;
use Test::FailWarnings;

use Performance::Probability qw(get_performance_probability);

my $file = 't/test_contracts_0.csv';
open my $info, $file or die "Could not open $file: $!";

my $data;
my $cnt = 0;

my @buy;
my @payout;
my @start;
my @sell;
my @underlying;
my @type;
my @exit_tick_epoch;
my @barriers;
my $pnl = 0;

while (my $line = <$info>) {

    if ($cnt == 0) {
        $cnt++;
        next;
    }

    $data = $line;

    #tokenize contract data.
    my @tokens = split(/,/, $data);

    my $bet_type          = $tokens[2];
    my $buy_price         = $tokens[3];
    my $payout_price      = $tokens[4];
    my $start_time        = $tokens[6];
    my $underlying_symbol = $tokens[7];
    my $sell_time         = $tokens[8];
    my $exit_tick_epoch   = $tokens[9];
    my $barrier           = $tokens[10];

    push @type,            $bet_type;
    push @buy,             $buy_price;
    push @payout,          $payout_price;
    push @start,           $start_time;
    push @sell,            $sell_time;
    push @underlying,      $underlying_symbol;
    push @exit_tick_epoch, $exit_tick_epoch;
    push @barriers,        $barrier;

    $pnl = $pnl + ($payout_price - $buy_price);
}

close $info;

subtest 'performance_probability' => sub {

    #add test case inside here

    my $performance_probability = Performance::Probability::get_performance_probability({
        payout          => \@payout,
        bought_price    => \@buy,
        pnl             => $pnl,
        types           => \@type,
        underlying      => \@underlying,
        start_time      => \@start,
        sell_time       => \@sell,
        exit_tick_epoch => \@exit_tick_epoch,
        barriers        => \@barriers,
    });

    ok $performance_probability, "Performance probability calculation.";

};

done_testing;
