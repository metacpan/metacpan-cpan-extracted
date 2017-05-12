use strict;
use warnings;

use Test::Exception;
use Test::More tests => 2;
use Test::NoWarnings;

use Date::Utility;
use Format::Util::Numbers qw( roundnear );
use Quant::Framework::CorrelationMatrix;
use Quant::Framework::Utils::Test;
use Quant::Framework::TradingCalendar;
use Quant::Framework::Currency;
use Quant::Framework::ExpiryConventions;

subtest general => sub {
    plan tests => 3;

    my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();
    my $date = Date::Utility->new('2015-05-26');

    Quant::Framework::Utils::Test::create_doc(
        'correlation_matrix',
        {
            recorded_date    => $date,
            chronicle_reader => $chronicle_r,
            chronicle_writer => $chronicle_w,
        });

    my $rho = Quant::Framework::CorrelationMatrix->new(
        symbol           => 'indices',
        for_date         => $date,
        chronicle_reader => $chronicle_r
    );

    my $index           = 'FCHI';
    my $payout_currency = 'USD';
    my $calendar        = Quant::Framework::TradingCalendar->new({
        symbol           => 'EURONEXT',
        chronicle_reader => $chronicle_r,
        for_date         => $date
    });

    my $qcurrency = Quant::Framework::Currency->new({
        symbol           => 'USD',
        for_date         => $date,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });

    my $expiry_conventions = Quant::Framework::ExpiryConventions->new(
        chronicle_reader => $chronicle_r,
        for_date         => $date,
        symbol           => $index,
        quoted_currency  => $qcurrency,
        calendar         => $calendar,
    );

    my $tiy = 366 / 365;
    my $mycorr = $rho->correlation_for($index, $payout_currency, $tiy, $expiry_conventions);
    is($mycorr, 0.516, "Correlation value for a little more than 1 year.");

    $tiy = 7 / 365;
    $mycorr = $rho->correlation_for($index, $payout_currency, $tiy, $expiry_conventions);
    is($mycorr, 0.568782608695652, "Correlation value for 7 days.");

    $tiy = 175 / 365;
    $mycorr = $rho->correlation_for($index, $payout_currency, $tiy, $expiry_conventions);
    is(roundnear(0.01, $mycorr), 0.54, "Correlation value for 175 days.");
};

