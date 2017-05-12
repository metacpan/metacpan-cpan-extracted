#!/usr/bin/perl

use Test::MockTime qw( :all );
use Quant::Framework::Utils::Test qw( :init );

use Test::Most;
use Test::MockModule;
use File::Spec;
use Test::FailWarnings;
use Test::MockObject::Extends;
use Test::MockModule;
use JSON qw(decode_json);
use Time::Local ();
use YAML::XS qw(LoadFile);
use Quant::Framework::TradingCalendar;
use Quant::Framework::InterestRate;
use Quant::Framework::Utils::Test;

use Readonly;
Readonly::Scalar my $HKSE_TRADE_DURATION_DAY => ((2 * 3600 + 29 * 60) + (2 * 3600 + 40 * 60));
Readonly::Scalar my $HKSE_TRADE_DURATION_MORNING => 2 * 3600 + 29 * 60;
Readonly::Scalar my $HKSE_TRADE_DURATION_EVENING => 2 * 3600 + 40 * 60;
my ($chronicle_r, $chronicle_w) = Data::Chronicle::Mock::get_mocked_chronicle();
my $date = Date::Utility->new('2013-12-01');    # first of December 2014
Quant::Framework::Utils::Test::create_doc(
    'holiday',
    {
        recorded_date => $date,
        calendar      => {
            "6-May-2013" => {
                "Early May Bank Holiday" => [qw(LSE)],
            },
            "25-Dec-2013" => {
                "Christmas Day" => [qw(LSE FOREX METAL)],
            },
            "1-Jan-2014" => {
                "New Year's Day" => [qw(LSE FOREX METAL)],
            },
            "1-Apr-2013" => {
                "Easter Monday" => [qw(LSE)],
            },
        },
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });

Quant::Framework::Utils::Test::create_doc(
    'partial_trading',
    {
        recorded_date => $date,
        type          => 'early_closes',
        calendar      => {
            '24-Dec-2009' => {
                '4h30m' => ['HKSE'],
            },
            '24-Dec-2010' => {'12h30m' => ['LSE']},
            '24-Dec-2013' => {
                '12h30m' => ['LSE'],
            },
            '22-Dec-2016' => {
                '18h' => ['FOREX', 'METAL'],
            },
        },
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });
Quant::Framework::Utils::Test::create_doc(
    'partial_trading',
    {
        recorded_date => $date,
        type          => 'late_opens',
        calendar      => {
            '24-Dec-2010' => {
                '2h30m' => ['HKSE'],
            },
        },
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    });

Quant::Framework::Utils::Test::create_doc(
    'currency',
    {
        symbol           => $_,
        chronicle_reader => $chronicle_r,
        chronicle_writer => $chronicle_w,
    }) for qw(AUD GBP EUR USD HKD);

my $LSE = Quant::Framework::TradingCalendar->new({
    symbol           => 'LSE',
    chronicle_reader => $chronicle_r,
    for_date         => $date
});
my $FSE = Quant::Framework::TradingCalendar->new({
    symbol           => 'FSE',
    chronicle_reader => $chronicle_r
});    # think GDAXI
my $FOREX = Quant::Framework::TradingCalendar->new({
    symbol           => 'FOREX',
    chronicle_reader => $chronicle_r
});
my $RANDOM = Quant::Framework::TradingCalendar->new({
    symbol           => 'RANDOM',
    chronicle_reader => $chronicle_r
});
my $RANDOM_NOCTURNE = Quant::Framework::TradingCalendar->new({
    symbol           => 'RANDOM_NOCTURNE',
    chronicle_reader => $chronicle_r
});
my $ASX = Quant::Framework::TradingCalendar->new({
    symbol           => 'ASX',
    chronicle_reader => $chronicle_r
});
my $NYSE = Quant::Framework::TradingCalendar->new({
    symbol           => 'NYSE',
    chronicle_reader => $chronicle_r
});
my $HKSE = Quant::Framework::TradingCalendar->new({
    symbol           => 'HKSE',
    chronicle_reader => $chronicle_r
});
my $ISE = Quant::Framework::TradingCalendar->new({
    symbol           => 'ISE',
    chronicle_reader => $chronicle_r
});
my $METAL = Quant::Framework::TradingCalendar->new({
    symbol           => 'METAL',
    chronicle_reader => $chronicle_r
});

subtest 'holidays check' => sub {
    is $LSE->for_date->epoch, $date->epoch, 'for_date properly set in Exchange';
    my %expected_holidays = (
        15831 => 'Early May Bank Holiday',
        16064 => 'Christmas Day',
        16071 => 'New Year\'s Day',
        15796 => 'Easter Monday',
    );
    lives_ok {
        my $holidays = $LSE->holidays;
        is scalar(keys %$holidays), scalar(keys %expected_holidays), 'holidays retrieved is as expected';
        for (keys %expected_holidays) {
            is $holidays->{Date::Utility->new($_)->epoch}, $expected_holidays{$_}, 'matches holiday';
        }
    }
    'check holiday accuracy';

    is($LSE->holiday_days_between(Date::Utility->new('24-Dec-13'), Date::Utility->new('3-Jan-14')), 2, "two holidays over the year end on LSE.");

    ok($LSE->has_holiday_on(Date::Utility->new('6-May-13')),    'LSE has holiday on 6-May-13.');
    ok(!$FOREX->has_holiday_on(Date::Utility->new('6-May-13')), 'FOREX is open on LSE holiday 6-May-13.');
    ok(!$LSE->has_holiday_on(Date::Utility->new('7-May-13')),   'LSE is open on 7-May-13.');
    ok(!$METAL->has_holiday_on(Date::Utility->new('6-May-13')), 'METAL is open on LSE holiday 6-May-13.');

    ok(!$LSE->trades_on(Date::Utility->new('1-Jan-14')),   'LSE doesn\'t trade on 1-Jan-14 because it is on holiday.');
    ok(!$LSE->trades_on(Date::Utility->new('12-May-13')),  'LSE doesn\'t trade on weekend (12-May-13).');
    ok($LSE->trades_on(Date::Utility->new('3-May-13')),    'LSE trades on normal day 4-May-13.');
    ok(!$LSE->trades_on(Date::Utility->new('5-May-13')),   'LSE doesn\'t trade on 5-May-13 as it is a weekend.');
    ok($RANDOM->trades_on(Date::Utility->new('5-May-13')), 'RANDOM trades on 5-May-13 as it is open on weekends.');

    my @real_holidays = grep { $LSE->has_holiday_on(Date::Utility->new($_ * 86400)) } keys(%{$LSE->holidays});
    is(scalar @real_holidays, 4, '4 real LSE holidays');
    ok(!$LSE->has_holiday_on(Date::Utility->new('26-Dec-13')), '26-Dec-13 is not a real holiday');
};

subtest "Holiday/Weekend weights" => sub {
    my $trade_start = Date::Utility->new('30-Mar-13');
    my $sunday      = Date::Utility->new('7-Apr-13');
    my $trade_end   = Date::Utility->new('8-Apr-13');
    my $trade_end2  = Date::Utility->new('9-Apr-13');    # Just to avoid memoization on weighted_days_in_period
    ok $sunday->is_a_weekend, "This is a weekend";
    ok(!$LSE->has_holiday_on($sunday), 'No holiday on that sunday.');

    # mock
    Test::MockObject::Extends->new($LSE);
    my $orig_holidays = $LSE->holidays;
    $LSE->mock(
        'holidays',
        sub {
            return {%$orig_holidays, 14703 => 'Test Sunday Holiday!'};
        });
    # test
    is($LSE->simple_weight_on($sunday), 0.0, "holiday on sunday.");

    # unmock
    $LSE->unmock('holidays');
    ok(!$LSE->has_holiday_on($sunday), 'Unmocked');
};

subtest 'Whole bunch of stuff.' => sub {
    plan tests => 107;

    is($LSE->simple_weight_on(Date::Utility->new('2-Apr-13')), 1.0, 'open weight');
    is($LSE->simple_weight_on(Date::Utility->new('1-Apr-13')), 0.0, 'holiday weight');
    is($LSE->simple_weight_on(Date::Utility->new('1-Apr-13')), 0.0, 'weekend weight');

    is($FOREX->trade_date_after(Date::Utility->new('20-Dec-13'))->date, '2013-12-23', '23-Dec-13 is next trading day on FOREX after 20-Dec-13');
    is($FOREX->calendar_days_to_trade_date_after(Date::Utility->new('20-Dec-13')),
        3, '3 calendar days until next trading day on FOREX after 20-Dec-13');
    is($FOREX->calendar_days_to_trade_date_after(Date::Utility->new('27-Dec-13')),
        3, '3 calendar days until next trading day on FOREX after 27-Dec-13');
    is($FOREX->calendar_days_to_trade_date_after(Date::Utility->new('7-Mar-13')), 1, '1 calendar day until next trading day on FOREX after 7-Mar-13');
    is($FOREX->calendar_days_to_trade_date_after(Date::Utility->new('8-Mar-13')), 3,
        '3 calendar days until next trading day on FOREX after 8-Mar-13');
    is($FOREX->calendar_days_to_trade_date_after(Date::Utility->new('9-Mar-13')), 2,
        '2 calendar days until next trading day on FOREX after 9-Mar-13');
    is($FOREX->calendar_days_to_trade_date_after(Date::Utility->new('10-Mar-13')),
        1, '1 calendar day until next trading day on FOREX after 10-Mar-13');

    is($FSE->calendar_days_to_trade_date_after(Date::Utility->new('20-Dec-13')), 3, '3 calendar days until next trading day on FSE after 20-Dec-13');
    is($FSE->calendar_days_to_trade_date_after(Date::Utility->new('27-Dec-13')), 3, '3 calendar days until next trading day on FSE after 27-Dec-13');
    
    is($METAL->trade_date_after(Date::Utility->new('20-Dec-13'))->date, '2013-12-23', '23-Dec-13 is next trading day on METAL after 20-Dec-13');
    is($METAL->calendar_days_to_trade_date_after(Date::Utility->new('20-Dec-13')),
        3, '3 calendar days until next trading day on METAL after 20-Dec-13');
    is($METAL->calendar_days_to_trade_date_after(Date::Utility->new('27-Dec-13')),
        3, '3 calendar days until next trading day on METAL after 27-Dec-13');
    is($METAL->calendar_days_to_trade_date_after(Date::Utility->new('7-Mar-13')), 1, '1 calendar day until next trading day on METAL after 7-Mar-13');
    is($METAL->calendar_days_to_trade_date_after(Date::Utility->new('8-Mar-13')), 3,
        '3 calendar days until next trading day on METAL after 8-Mar-13');
    is($METAL->calendar_days_to_trade_date_after(Date::Utility->new('9-Mar-13')), 2,
        '2 calendar days until next trading day on METAL after 9-Mar-13');
    is($METAL->calendar_days_to_trade_date_after(Date::Utility->new('10-Mar-13')),
        1, '1 calendar day until next trading day on METAL after 10-Mar-13');
 



    # testing the "use current time" methods for one date/time only.
    # Rest of tests will use the "_at" methods ("current time" ones
    # use them anyway).
    Test::MockTime::set_fixed_time('2013-05-03T09:00:00Z');
    is($LSE->is_open,   1,     'LSE is open at 9am on a trading day');
    is($LSE->will_open, undef, 'LSE will not open "later" (is it already open)');
    Test::MockTime::restore_time();

    # before opening time on an LSE trading day:
    my $six_am       = Date::Utility->new('3-May-13 06:00:00');
    my $six_am_epoch = $six_am->epoch;
    is($LSE->is_open_at($six_am),                   undef, 'LSE not open at 6am');
    is($LSE->is_open_at($six_am_epoch),             undef, 'LSE not open at 6am');
    is($LSE->will_open_after($six_am),              1,     'LSE will open on this day after 6am');
    is($LSE->will_open_after($six_am_epoch),        1,     'LSE will open on this day after 6am');
    is($LSE->seconds_since_open_at($six_am),        undef, 'at 6am, LSE not open yet');
    is($LSE->seconds_since_open_at($six_am_epoch),  undef, 'at 6am, LSE not open yet');
    is($LSE->seconds_since_close_at($six_am),       undef, 'at 6am, LSE hasn\'t closed yet');
    is($LSE->seconds_since_close_at($six_am_epoch), undef, 'at 6am, LSE hasn\'t closed yet');

    # after closing time on an LSE trading day:
    my $six_pm       = Date::Utility->new('3-May-13 18:00:00');
    my $six_pm_epoch = $six_pm->epoch;
    is($LSE->is_open_at($six_pm),                   undef,         'LSE not open at 6pm.');
    is($LSE->is_open_at($six_pm_epoch),             undef,         'LSE not open at 6pm.');
    is($LSE->will_open_after($six_pm),              undef,         'LSE will not open on this day after 6pm.');
    is($LSE->will_open_after($six_pm_epoch),        undef,         'LSE will not open on this day after 6pm.');
    is($LSE->seconds_since_open_at($six_pm),        11 * 60 * 60,  'at 6pm, LSE opening was 11 hours ago.');
    is($LSE->seconds_since_open_at($six_pm_epoch),  11 * 60 * 60,  'at 6pm, LSE opening was 11 hours ago.');
    is($LSE->seconds_since_close_at($six_pm),       2.5 * 60 * 60, 'at 6pm, LSE has been closed for 2.5 hours.');
    is($LSE->seconds_since_close_at($six_pm_epoch), 2.5 * 60 * 60, 'at 6pm, LSE has been closed for 2.5 hours.');

    # LSE holiday:
    my $lse_holiday_epoch = Date::Utility->new('6-May-13 12:00:00')->epoch;
    is($LSE->is_open_at($lse_holiday_epoch),             undef, 'is_open_at LSE not open today at all.');
    is($LSE->will_open_after($lse_holiday_epoch),        undef, 'will_open_after LSE not open today at all.');
    is($LSE->seconds_since_open_at($lse_holiday_epoch),  undef, 'seconds_since_open_at LSE not open today at all.');
    is($LSE->seconds_since_close_at($lse_holiday_epoch), undef, 'seconds_since_close_at LSE not open today at all.');

    # Two session trading stuff:
    my $HKSE = Quant::Framework::TradingCalendar->new({
        symbol           => 'HKSE',
        chronicle_reader => $chronicle_r
    });

    my $lunchbreak_epoch = Date::Utility->new('3-May-13 04:30:00')->epoch;
    is($HKSE->is_open_at($lunchbreak_epoch),            undef, 'HKSE closed for lunch!');
    is($HKSE->will_open_after($lunchbreak_epoch),       1,     'HKSE will open for the afternoon session.');
    is($HKSE->seconds_since_open_at($lunchbreak_epoch), undef, 'seconds since open is undef if market is closed (which includes closed for lunch).');
    is($HKSE->seconds_since_close_at($lunchbreak_epoch), 31 * 60, '1 hour into lunch, HKSE closed 31 minutes ago.');

    my $HKSE_close_epoch = Date::Utility->new('3-May-13 07:40:00')->epoch;
    is($HKSE->seconds_since_close_at($HKSE_close_epoch), 0, 'HKSE: seconds since close at close should be zero (as opposed to undef).');

    # DST stuff
    # Europe: last Sunday of March.
    is($LSE->is_open_at(Date::Utility->new('29-Mar-13 07:30:00')->epoch), undef, 'LSE not open at 7:30am GMT during winter.');
    is($LSE->is_open_at(Date::Utility->new('3-Apr-13 07:30:00')->epoch),  1,     'LSE open at 7:30am GMT during summer.');

    # Australia: first Sunday of April.
    # BE CAREFUL: Au "summer" is Northern Hemisphere "winter"!
    my $ASX = Quant::Framework::TradingCalendar->new({
        symbol           => 'ASX',
        chronicle_reader => $chronicle_r
    });
    my $late_apr_3 = Date::Utility->new('3-Apr-13 23:30:00');
    is($ASX->is_open_at($late_apr_3),                                    1,            'ASX open at 23:30 GMT a day earlier during Aussie "summer"');
    is($ASX->trading_date_for($late_apr_3)->date,                        '2013-04-04', '... and it is trading on the "next" day.');
    is($ASX->is_open_at(Date::Utility->new('5-Apr-13 05:30:00')->epoch), undef,        'ASX not open at 5:30am GMT during Aussie "summer".');
    is($ASX->is_open_at(Date::Utility->new('8-Apr-13 23:30:00')->epoch), undef, 'ASX not open at 23:30 GMT a day earlier during Aussie "winter".');
    is($ASX->is_open_at(Date::Utility->new('8-Apr-13 05:30:00')->epoch), 1,     'ASX open at 5:30am GMT during Aussie "winter".');

    # USA: second Sunday of March.
    my $NYSE = Quant::Framework::TradingCalendar->new({
        symbol           => 'NYSE',
        chronicle_reader => $chronicle_r
    });
    is($NYSE->is_open_at(Date::Utility->new('8-Mar-13 14:00:00')->epoch),  undef, 'NYSE not open at 2pm GMT during winter.');
    is($NYSE->is_open_at(Date::Utility->new('11-Mar-13 14:00:00')->epoch), 1,     'NYSE open at 2pm GMT during summer.');

    is(
        $LSE->opening_on(Date::Utility->new('3-May-13'))->epoch,
        Date::Utility->new('3-May-13 07:00')->epoch,
        'Opening time of LSE on 3-May-13 is 07:00.'
    );
    is(
        $LSE->closing_on(Date::Utility->new('3-May-13'))->epoch,
        Date::Utility->new('3-May-13 15:30')->epoch,
        'Closing time of LSE on 3-May-13 is 14:30.'
    );
    is(
        $LSE->opening_on(Date::Utility->new('8-Feb-13'))->epoch,
        Date::Utility->new('8-Feb-13 08:00')->epoch,
        'Opening time of LSE on 8-Feb-13 is 08:00 (winter time).'
    );
    is(
        $LSE->closing_on(Date::Utility->new('8-Feb-13'))->epoch,
        Date::Utility->new('8-Feb-13 16:30')->epoch,
        'Closing time of LSE on 8-Feb-13 is 16:30 (winter time).'
    );
    is($LSE->opening_on(Date::Utility->new('12-May-13')), undef, 'LSE doesn\'t open on weekend (12-May-13).');

    is(
        $HKSE->opening_on(Date::Utility->new('3-May-13'))->epoch,
        Date::Utility->new('3-May-13 01:30')->epoch,
        '[epoch test] Opening time of HKSE on 3-May-13 is 01:30.'
    );
    ok($HKSE->trading_breaks(Date::Utility->new('3-May-13')), 'HKSE has trading breaks');
    is $HKSE->trading_breaks(Date::Utility->new('3-May-13'))->[0]->[0]->epoch, Date::Utility->new('3-May-13 03:59')->epoch,
        'correct interval open time';
    is $HKSE->trading_breaks(Date::Utility->new('3-May-13'))->[0]->[1]->epoch, Date::Utility->new('3-May-13 05:00')->epoch,
        'correct interval close time';
    is(
        $HKSE->closing_on(Date::Utility->new('3-May-13'))->epoch,
        Date::Utility->new('3-May-13 07:40')->epoch,
        '[epoch test] Closing time of HKSE on 3:-May-13 is 07:40.'
    );

    ok(!$LSE->closes_early_on(Date::Utility->new('23-Dec-13')),   'LSE doesn\'t close early on 23-Dec-10');
    ok($LSE->closes_early_on(Date::Utility->new('24-Dec-13')),    'LSE closes early on 24-Dec-10');
    ok(!$FOREX->closes_early_on(Date::Utility->new('23-Dec-13')), 'FOREX doesn\'t close early on 23-Dec-13');
    ok(!$METAL->closes_early_on(Date::Utility->new('23-Dec-13')), 'METAL doesn\'t close early on 23-Dec-13');

    is(
        $LSE->closing_on(Date::Utility->new('24-Dec-13'))->epoch,
        Date::Utility->new('24-Dec-13 12:30')->epoch,
        '(Early) closing time of LSE on 24-Dec-13 is 12:30.'
    );

    ok(!$HKSE->opens_late_on(Date::Utility->new('23-Dec-13')), 'HKSE doesn\'t open late on 23-Dec-10');
    ok($HKSE->opens_late_on(Date::Utility->new('24-Dec-10')),  'HKSE opens late on 24-Dec-10');
    is(
        $HKSE->opening_on(Date::Utility->new('24-Dec-10'))->epoch,
        Date::Utility->new('24-Dec-10 02:30')->epoch,
        '(Late) opening time of HKSE on 24-Dec-10 is 02:30.'
    );

    is($HKSE->closing_on(Date::Utility->new('23-Dec-13'))->time_hhmm, '07:40', 'Closing time of HKSE on 23-Dec-10 is 07:40.');

    throws_ok { $LSE->closes_early_on('JUNK') } qr/forgot to load "JUNK"/, 'closes_early_on dies when given a bad date';

    is($LSE->trade_date_before(Date::Utility->new('3-May-13'))->date, '2013-05-02', '2nd May is 1 trading day before 3rd May on FTSE');
    is($LSE->trade_date_before(Date::Utility->new('3-May-13'), {lookback => 2})->date,
        '2013-05-01', '1st May is 2 trading days before 3rd May on FTSE');
    is($LSE->trade_date_before(Date::Utility->new('12-May-13'))->date,
        '2013-05-10', '10th May is 1 trading day before 12th May on FTSE (looking back over weekend)');
    is($LSE->trade_date_before(Date::Utility->new('6-May-13'))->date,
        '2013-05-03', '3rd May is 1 trading day before 6th May on FTSE (4th and 5th are the weekend)');
    is($LSE->trade_date_before(Date::Utility->new('6-May-13'), {lookback => 3})->date,
        '2013-05-01', '1st May is 3 trading days before 6th May on FTSE (4th and 5th are the weekend)');

    is($LSE->holiday_days_between(Date::Utility->new('3-May-13'), Date::Utility->new('7-May-13')), 1, 'See? 6th is a holiday');

    is($LSE->trading_days_between(Date::Utility->new('29-Mar-13'), Date::Utility->new('1-Apr-13')),
        0, 'No trading days between 29th Mar and 1st Apr on LSE');
    is($LSE->trading_days_between(Date::Utility->new('11-May-13'), Date::Utility->new('12-May-13')),
        0, 'No trading days between 11th and 12th May on LSE (over weekend)');
    is($LSE->trading_days_between(Date::Utility->new('4-May-13'), Date::Utility->new('6-May-13')),
        0, 'No trading days between 4th May and 6th May on LSE (over weekend, then holiday on Monday)');
    is($LSE->trading_days_between(Date::Utility->new('10-May-13'), Date::Utility->new('14-May-13')),
        1, '1 trading day between 10th and 14th May on LSE (over weekend, Monday open)');

    # seconds_of_trading_between:

    # HSI Opens 02:00 hours, closes 04:30 for lunch, reopens at 06:30 after lunch, and closes for the day at 08:00.
    # Thus, opens for 2.5 hours first session, and 1.5 hours the second session for a total of 4 hours per day.
    my @test_data = (
        # Tuesday 10 March 2009 00:00, up to end of the day
        {
            start        => Date::Utility->new(1236643200),
            end          => Date::Utility->new(1236643200 + 86400),
            trading_time => $HKSE_TRADE_DURATION_DAY,
            desc         => 'Trade time : Full Day'
        },
        # Tuesday 10 March 2009 00:00, up to start of lunch break
        {
            start        => Date::Utility->new(1236643200),
            end          => Date::Utility->new(1236643200 + (3 * 3600 + 59 * 60)),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time : Lunch Break',
        },
        # Tuesday 10 March 2009 00:00, up to end of lunch break
        {
            start        => Date::Utility->new(1236643200),
            end          => Date::Utility->new(1236643200 + 5 * 3600),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade Time : End of lunch Break',
        },
        # Tuesday 10 March 2009 02:30, up to end of lunch break
        {
            start        => Date::Utility->new(1236643200 + 1.5 * 3600),
            end          => Date::Utility->new(1236643200 + 5 * 3600),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time : Start of trade day to End lunch Break',
        },
        # Tuesday 10 March 2009 00:00, up to 07:00
        {
            start        => Date::Utility->new(1236643200),
            end          => Date::Utility->new(1236643200 + 7 * 3600),
            trading_time => $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 00:00 GMT to 07:00 GMT'
        },
        # Tuesday 10 March 2009 00:00, up to Weds 07:00
        {
            start        => Date::Utility->new(1236643200),
            end          => Date::Utility->new(1236643200 + 86400 + 7 * 3600),
            trading_time => $HKSE_TRADE_DURATION_DAY + $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 00:00 GMT to next day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:30, up to Weds 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 03:00 GMT to next day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:30, up to Thursday 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 2 * 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + $HKSE_TRADE_DURATION_DAY + $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 03:00 GMT to alternate day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:30, up to Friday 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 3 * 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + (2 * $HKSE_TRADE_DURATION_DAY) + $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 03:00 GMT to third day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:00, up to Saturday 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 4 * 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + (3 * $HKSE_TRADE_DURATION_DAY),
            desc         => 'Trade time : From 03:00 GMT to weekend day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:00, up to Sunday 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 5 * 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + (3 * $HKSE_TRADE_DURATION_DAY),
            desc         => 'Trade time : From 03:00 GMT to weekend(sunday) day 07:00 GMT'
        },
        # Tuesday 10 March 2009 03:30, up to next Monday 07:00
        {
            start        => Date::Utility->new(1236643200 + 3 * 3600),
            end          => Date::Utility->new(1236643200 + 6 * 86400 + 7 * 3600),
            trading_time => (59 * 60) + $HKSE_TRADE_DURATION_EVENING + (3 * $HKSE_TRADE_DURATION_DAY) + $HKSE_TRADE_DURATION_MORNING + (2 * 3600),
            desc         => 'Trade time : From 03:00 GMT to sixth(monday) day 07:00 GMT'
        },
        # EARLY CLOSE TESTS
        # Thursday 24 December 2009. Market closes early at 04:30.
        {
            start        => Date::Utility->new('24-Dec-09 01:00:00'),
            end          => Date::Utility->new('24-Dec-09 03:00:00'),
            trading_time => (1 * 3600) + (30 * 60),
            desc         => 'Trade time Early Close : Before close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 01:00:00'),
            end          => Date::Utility->new('24-Dec-09 09:00:00'),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time Early Close : After Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 01:30:00'),
            end          => Date::Utility->new('24-Dec-09 08:00:00'),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time Early Close : Start of trade day to After Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 01:30:00'),
            end          => Date::Utility->new('24-Dec-09 05:00:00'),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time Early Close : Start of trade day to After Close 2',
        },
        {
            start        => Date::Utility->new('24-Dec-09 01:30:00'),
            end          => Date::Utility->new('24-Dec-09 04:30:00'),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time Early Close : Start of trade day to At Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 01:30:00'),
            end          => Date::Utility->new('24-Dec-09 04:00:00'),
            trading_time => $HKSE_TRADE_DURATION_MORNING,
            desc         => 'Trade time Early Close : Start of trade day to Before Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 04:30:00'),
            end          => Date::Utility->new('24-Dec-09 08:00:00'),
            trading_time => (0) * 3600,
            desc         => 'Trade time Early Close : Close of trade day to After Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 05:00:00'),
            end          => Date::Utility->new('24-Dec-09 08:00:00'),
            trading_time => (0) * 3600,
            desc         => 'Trade time Early Close : After Close of trade day to After Close',
        },
        {
            start        => Date::Utility->new('24-Dec-09 06:00:00'),
            end          => Date::Utility->new('24-Dec-09 08:00:00'),
            trading_time => (0) * 3600,
            desc         => 'Trade time Early Close : After Close of trade day to After Close 2',
        },
        {
            start        => Date::Utility->new('24-Dec-09 07:00:00'),
            end          => Date::Utility->new('24-Dec-09 08:00:00'),
            trading_time => (0) * 3600,
            desc         => 'Trade time Early Close : After Close of trade day to After Close 3',
        },
    );
    TEST:
    foreach my $data (@test_data) {
        my $dt                    = $data->{'start'};
        my $dt_end                = $data->{'end'};
        my $expected_trading_time = $data->{'trading_time'};
        my $desc                  = $data->{'desc'};
        is(
            $HKSE->seconds_of_trading_between_epochs($dt->epoch, $dt_end->epoch),
            $expected_trading_time,
            'testing "seconds_of_trading_between_epochs(' . $dt->epoch . ', ' . $dt_end->epoch . ')" on HKSE : [' . $desc . ']',
        );
    }
};

subtest 'regularly_adjusts_trading_hours_on' => sub {
    plan tests => 10;
    my $monday = Date::Utility->new('2013-08-26');
    my $friday = $monday->plus_time_interval('4d');

    note 'It is expected that this long-standing close in forex will not change, so we can use it to verify the implementation.';

    ok(!$FOREX->regularly_adjusts_trading_hours_on($monday), 'FOREX does not regularly adjust trading hours on ' . $monday->day_as_string);
    ok(!$METAL->regularly_adjusts_trading_hours_on($monday), 'METAL does not regularly adjust trading hours on ' . $monday->day_as_string);

    my $friday_changes = $FOREX->regularly_adjusts_trading_hours_on($friday);
    ok($friday_changes,                       'FOREX regularly adjusts trading hours on ' . $friday->day_as_string);
    ok(exists $friday_changes->{daily_close}, ' changing daily_close');
    is($friday_changes->{daily_close}->{to},   '21h',     '  to 21h after midnight');
    is($friday_changes->{daily_close}->{rule}, 'Fridays', '  by rule "Friday"');

    my $metal_friday = $METAL->regularly_adjusts_trading_hours_on($friday);
    ok($metal_friday,  'METAL regularly adjusts trading hours on ' . $friday->day_as_string);
    ok(exists $metal_friday->{daily_close}, ' changing daily_close');
    is($metal_friday->{daily_close}->{to},   '21h',     '  to 21h after midnight');
    is($metal_friday->{daily_close}->{rule}, 'Fridays', '  by rule "Friday"');



};

subtest 'trading_date_for' => sub {

    plan tests => 8;

    note
        'This assumes that the RANDOM and RANDOM NOCTURNE remain open every day and offset by 12 hours, so we can use them to verify the implementation.';
    my $RANDOM_NOCTURNE = Quant::Framework::TradingCalendar->new({
        symbol           => 'RANDOM_NOCTURNE',
        chronicle_reader => $chronicle_r
    });
    my $today = Date::Utility->today;

    ok(
        $RANDOM->trading_date_for($today)->is_same_as($RANDOM_NOCTURNE->trading_date_for($today)),
        "Random and Random Nocturne are on the same trading date at midnight today"
    );

    my $yo_am = $today->plus_time_interval('11h');
    ok($RANDOM->trading_date_for($yo_am)->is_same_as($RANDOM_NOCTURNE->trading_date_for($yo_am)), ".. and at 11am this morning");

    my $almost_closed_am = $yo_am->plus_time_interval('59m59s');
    ok($RANDOM->trading_date_for($almost_closed_am)->is_same_as($RANDOM_NOCTURNE->trading_date_for($almost_closed_am)),
        ".. and at a second before noon.");
    my $noon = $today->plus_time_interval('12h');
    ok(!$RANDOM->trading_date_for($noon)->is_same_as($RANDOM_NOCTURNE->trading_date_for($noon)), "At noon, they diverge");
    is($RANDOM->trading_date_for($noon)->days_between($RANDOM_NOCTURNE->trading_date_for($noon)), -1, ".. with Random a day behind Random Nocturne");

    my $yo_pm = $noon->plus_time_interval('11h');
    is($RANDOM->trading_date_for($yo_pm)->days_between($RANDOM_NOCTURNE->trading_date_for($yo_pm)), -1, ".. where it remains at 11pm this evening");

    my $almost_closed_pm = $yo_pm->plus_time_interval('59m59s');
    is($RANDOM->trading_date_for($almost_closed_pm)->days_between($RANDOM_NOCTURNE->trading_date_for($almost_closed_pm)),
        -1, ".. and at a second before midnight.");

    my $tomorrow = $today->plus_time_interval('24h');
    ok(
        $RANDOM->trading_date_for($tomorrow)->is_same_as($RANDOM_NOCTURNE->trading_date_for($tomorrow)),
        "Then Random and Random Nocturne are on back the same trading date at midnight tomorrow"
    );
};

subtest 'trading_date_can_differ' => sub {

    my $never_differs = Quant::Framework::TradingCalendar->new({
        symbol           => 'NYSE',
        chronicle_reader => $chronicle_r
    });
    ok(!$never_differs->trading_date_can_differ, $never_differs->symbol . ' never trades on a different day than the UTC calendar day.');
    my $always_differs = Quant::Framework::TradingCalendar->new({
        symbol           => 'RANDOM_NOCTURNE',
        chronicle_reader => $chronicle_r
    });
    ok($always_differs->trading_date_can_differ, $always_differs->symbol . ' always trades on a different day than the UTC calendar day.');
    my $sometimes_differs = Quant::Framework::TradingCalendar->new({
        symbol           => 'ASX',
        chronicle_reader => $chronicle_r
    });
    ok($sometimes_differs->trading_date_can_differ, $sometimes_differs->symbol . ' sometimes trades on a different day than the UTC calendar day.');

};

subtest 'regular_trading_day_after' => sub {
    my $exchange = Quant::Framework::TradingCalendar->new({
        symbol           => 'FOREX',
        chronicle_reader => $chronicle_r
    });
    lives_ok {
        my $weekend     = Date::Utility->new('2014-03-29');
        my $regular_day = $exchange->regular_trading_day_after($weekend);
        is($regular_day->date_yyyymmdd, '2014-03-31', 'correct regular trading day after weekend');
        my $new_year = Date::Utility->new('2014-01-01');
        $regular_day = $exchange->regular_trading_day_after($new_year);
        is($regular_day->date_yyyymmdd, '2014-01-02', 'correct regular trading day after New Year');
    }
    'test regular trading day on weekend and exchange holiday';
};

subtest 'get exchange settlement time' => sub {
    my $testing_date = Date::Utility->new(1426564197);
    lives_ok {
        is($LSE->settlement_on($testing_date)->epoch,             '1426620600', 'correct settlement time for LSE');
        is($FSE->settlement_on($testing_date)->epoch,             '1426620600', 'correct settlement time for FSE');
        is($FOREX->settlement_on($testing_date)->epoch,           '1426636799', 'correct settlement time for FOREX');
        is($METAL->settlement_on($testing_date)->epoch,           '1426636799', 'correct settlement time for METAL');
        is($RANDOM->settlement_on($testing_date)->epoch,          '1426636799', 'correct settlement time for RANDOM');
        is($RANDOM_NOCTURNE->settlement_on($testing_date)->epoch, '1426593599', 'correct settlement time for RANDOM NOCTURNE');
        is($ASX->settlement_on($testing_date)->epoch,             '1426579200', 'correct settlement time for ASX');
        is($NYSE->settlement_on($testing_date)->epoch,            '1426633199', 'correct settlement time for NYSE');
        is($HKSE->settlement_on($testing_date)->epoch,            '1426588800', 'correct settlement time for HKSE');
        is($ISE->settlement_on($testing_date)->epoch,             '1426631400', 'correct settlement time for ISE');

    }
    'test regular settlement time ';
};

subtest 'trading period' => sub {
    my $ex = Quant::Framework::TradingCalendar->new({
        symbol           => 'HKSE',
        chronicle_reader => $chronicle_r
    });
    my $trading_date = Date::Utility->new('15-Jul-2015');
    lives_ok {
        my $p = $ex->trading_period($trading_date);
        # daily_open       => '1h30m',
        # trading_breaks   => [['3h59m', '5h00m']],
        # daily_close      => '7h40m',
        my $expected = [{
                open  => Time::Local::timegm(0, 30, 1, 15, 6, 115),
                close => Time::Local::timegm(0, 59, 3, 15, 6, 115)
            },
            {
                open  => Time::Local::timegm(0, 0,  5, 15, 6, 115),
                close => Time::Local::timegm(0, 40, 7, 15, 6, 115)
            },
        ];
        is_deeply $p, $expected, 'two periods';
    }
    'trading period for HKSE';
    $ex = Quant::Framework::TradingCalendar->new({
        symbol           => 'FOREX',
        chronicle_reader => $chronicle_r
    });
    lives_ok {
        my $p = $ex->trading_period($trading_date);
        # daily_open: 0s
        # daily_close: 23h59m59s
        my $expected = [{
                open  => Time::Local::timegm(0,  0,  0,  15, 6, 115),
                close => Time::Local::timegm(59, 59, 23, 15, 6, 115)
            },
        ];
        is_deeply $p, $expected, 'one period';
    }
    'trading period for FOREX';

    $ex = Quant::Framework::TradingCalendar->new({
        symbol  =>'METAL',
        chronicle_reader => $chronicle_r
});
    lives_ok {
        my $p = $ex->trading_period($trading_date);
        # daily_open: 0s
        # daily_close: 23h59m59s
        my $expected = [{
                open  => Time::Local::timegm(0,  0,  0,  15, 6, 115),
                close => Time::Local::timegm(59, 59, 23, 15, 6, 115)
            },
        ];
        is_deeply $p, $expected, 'one period';
    }
    'trading period for METAL';

};

subtest "seconds between trading" => sub {

    is $HKSE->seconds_of_trading_between_epochs(1291161600, 1293753600), 404280, "Seconds between 1st and 31 of December 2010 (HKSE/late opening)";

    is $FOREX->seconds_of_trading_between_epochs(1385856000, 1388448000),
        1684784, "Seconds between 1st and 31 of December 2013 (Forex/Christmas holiday)";

    is $METAL->seconds_of_trading_between_epochs(1385856000, 1388448000),
        1684784, "Seconds between 1st and 31 of December 2013 (METAL/Christmas holiday)";

    is $LSE->seconds_of_trading_between_epochs(1385856000, 1388448000), 597600, "Seconds between 1st and 31 of December 2013 (LSE/early closes)";

    is $RANDOM->seconds_of_trading_between_epochs(1385856000, 1388448000),
        (1388448000 - 1385856000) - 30, "Seconds between 1st and 31 of December 2013 (Random)";

};

subtest 'standard_closing_on' => sub {
    note("DST ends on 3 April 2016");
    my $in_dst  = Date::Utility->new('2016-03-01');
    my $non_dst = Date::Utility->new('2016-03-04');
    my $asx     = Quant::Framework::TradingCalendar->new({
        symbol           => 'ASX',
        chronicle_reader => $chronicle_r
    });
    is $asx->standard_closing_on($in_dst)->epoch, $in_dst->plus_time_interval('6h')->epoch,
        'standard_closing_on return non DST closing on 1 April 2016';
    is $asx->standard_closing_on($non_dst)->epoch, $non_dst->plus_time_interval('6h')->epoch,
        'standard_closing_on return non DST closing on 4 April 2016';
};

subtest 'standard_closing_on early close' => sub {
    my $hkse = Quant::Framework::TradingCalendar->new({
        symbol           => 'HKSE',
        chronicle_reader => $chronicle_r
    });
    my $early_close = Date::Utility->new('2009-12-24');
    is $hkse->standard_closing_on($early_close)->epoch, $early_close->plus_time_interval('7h40m')->epoch, 'no early close for indices';

    my $friday               = Date::Utility->new('2016-03-25');
    my $normal_thursday      = Date::Utility->new('2016-03-24');
    my $early_close_thursday = Date::Utility->new('2016-12-24');
    my $fx                   = Quant::Framework::TradingCalendar->new({
        symbol           => 'FOREX',
        chronicle_reader => $chronicle_r
    });
    is $fx->standard_closing_on($friday)->epoch, $friday->plus_time_interval('21h')->epoch, 'standard close for friday is 21:00 GMT';
    is $fx->standard_closing_on($normal_thursday)->epoch, $normal_thursday->plus_time_interval('23h59m59s')->epoch,
        'normal standard closing is 23:59:59 GMT';
    is $fx->standard_closing_on($early_close_thursday)->epoch, $early_close_thursday->plus_time_interval('23h59m59s')->epoch,
        'normal standard closing is 23:59:59 GMT';

    my $metal                = Quant::Framework::TradingCalendar->new({
        symbol            =>'METAL',
        chronicle_reader => $chronicle_r});
    is $metal->standard_closing_on($friday)->epoch, $friday->plus_time_interval('21h')->epoch, 'standard close for friday is 21:00 GMT';
    is $metal->standard_closing_on($normal_thursday)->epoch, $normal_thursday->plus_time_interval('23h59m59s')->epoch,
        'normal standard closing is 23:59:59 GMT';
    is $metal->standard_closing_on($early_close_thursday)->epoch, $early_close_thursday->plus_time_interval('23h59m59s')->epoch,
        'normal standard closing is 23:59:59 GMT';
};

my $builder = Quant::Framework::Utils::Builder->new({
        chronicle_reader  => $chronicle_r,
        chronicle_writer  => $chronicle_w,
        underlying_config => Quant::Framework::Utils::Test::create_underlying_config('FTSE')});

my $trade_start = Date::Utility->new('30-Mar-13');
my $trade_end   = Date::Utility->new('8-Apr-13');
my $trade_end2  = Date::Utility->new('9-Apr-13');    # Just to avoid memoization on weighted_days_in_period
is $builder->build_trading_calendar->closed_weight, 0.55, 'Sanity check so that our weighted math matches :-)';
is $builder->build_trading_calendar->weighted_days_in_period($trade_start, $trade_end), 7.2,
    'Weighted period calculated correctly: 5 trading days, plus 4 weekends/holidays';
is $builder->build_trading_calendar->weighted_days_in_period($trade_start, $trade_end2), 8.2,
    'Weighted period calculated correctly: 6 trading days, plus 4 weekends/holidays';

done_testing;

1;
