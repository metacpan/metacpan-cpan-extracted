use strict;
use warnings;

use Test::More tests => 4;
use Test::Warn;
use Test::Exception;
use Test::NoWarnings;

use Date::Utility;
use Quant::Framework::Spot::Tick;
use Quant::Framework::Spot::OHLC;

subtest 'ticks' => sub {
    my $tick = Quant::Framework::Spot::Tick->new(
        bid   => 5,
        ask   => 10,
        quote => 7,
        epoch => 1
    );
    $tick->invert_values();

    is $tick->bid,   1 / 5,  'Bid Ok';
    is $tick->ask,   1 / 10, 'Ask Ok';
    is $tick->quote, 1 / 7,  'Quote Ok';
};

subtest 'ohlc' => sub {
    my $tick = Quant::Framework::Spot::OHLC->new(
        open  => 7,
        high  => 10,
        low   => 5,
        close => 8,
        epoch => 1
    );
    $tick->invert_values();

    is $tick->open,  1 / 7,  'Open Ok';
    is $tick->close, 1 / 8,  'Close Ok';
    is $tick->high,  1 / 5,  'High Ok';
    is $tick->low,   1 / 10, 'Low Ok';
};

subtest 'realtime tick' => sub {
    my $tick = Quant::Framework::Spot::Tick->new(
        quote => 8,
        epoch => 1
    );
    $tick->invert_values();

    is $tick->quote, 1 / 8, 'Close Ok';
};
