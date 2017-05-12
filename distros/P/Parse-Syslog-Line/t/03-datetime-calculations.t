#!perl

use Test::More;
use Test::Deep;
use Test::MockTime;

use List::AllUtils qw/mesh/; #TODO: removeme

use Data::Dumper;
use DateTime;
use DateTime::TimeZone;
use Time::Moment;

use Parse::Syslog::Line qw/:with_timezones/;

subtest 'If logdate is "in the future" it is actually "in the past"' => sub {

    # default settings
    Test::MockTime::set_fixed_time("2016-05-29T05:00:00Z");
    my $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2016-03-27 01:59:59',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'date is "in the past" - intuitive behaviour');

    Test::MockTime::set_fixed_time("2016-02-29T05:41:00Z"); #
    $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2015-03-27 01:59:59',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'date is "in the future" - HTTP::Date assumes it is in the past and finds a date match from previous year');

    done_testing();
};

subtest 'setting named timezone for syslog file' => sub {
    $msg = parse_syslog_line(q|2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}|);
    cmp_deeply($msg, superhashof({
        datetime_str => '2015-09-30 06:26:06',
        datetime_raw => '2015-09-30T06:26:06.779373-05:00',
    }), 'By default we will discard datetime present in message.');

    is($msg->{datetime_obj}->iso8601(), '2015-09-30T06:26:06', "Also dt_object doesn't have it...");

    $Parse::Syslog::Line::NormalizeToUTC = 0;
    $Parse::Syslog::Line::DateTimeCreate = 0;
    set_syslog_timezone('Europe/Warsaw');

    is($Parse::Syslog::Line::NormalizeToUTC, 1, "\t Normalize was set by set_syslog_timezone");
    is($Parse::Syslog::Line::DateTimeCreate, 1, "\t DateTimeCreate was set by set_syslog_timezone");

    Test::MockTime::set_fixed_time("2016-09-01T05:00:00Z"); #TZ +02:00

    $msg = parse_syslog_line(q|2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}|);
    cmp_deeply($msg,
    superhashof({
        datetime_str => '2015-09-30T06:26:06.779373-05:00',
        datetime_raw => '2015-09-30T06:26:06.779373-05:00',
    }), '...however with NormalizeToUTC we preserve it');

    is($msg->{datetime_obj}->strftime("%Y-%m-%dT%H:%M:%S%6N%z"), '2015-09-30T06:26:06779373-0500', 'but we remember them in dt object');

    $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2016-03-27T01:59:59+01:00',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'msg date is +01:00 despite local timezone being +02:00');

    $msg = parse_syslog_line(q|<11>Mar  27 03:00:01 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2016-03-27T03:00:01+02:00',
        datetime_raw => 'Mar  27 03:00:01',
    }), 'msg date is +02:00 same as local timezone because of DST (27 March 01:00 UTC - summer time start)');

    Test::MockTime::set_fixed_time("2016-02-29T05:41:00Z"); #TZ +01:00
    $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2015-03-27T01:59:59+01:00',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'msg date is +01:00 same as local timezone');

    $msg = parse_syslog_line(q|<11>Mar  27 03:00:01 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2015-03-27T03:00:01+01:00',
        datetime_raw => 'Mar  27 03:00:01',
    }), 'msg date is +02:00 but since it is in the future, it jumped back to 2015 where DST change ocurred 2015-03-29');

    Test::MockTime::restore_time();
    done_testing();
};

subtest 'setting offset timezone for syslog file' => sub {
    plan tests => 4;

    # with NormalizeToUTC and timezone set
    set_syslog_timezone('+0100');

    Test::MockTime::set_fixed_time("2016-09-01T05:00:00Z"); #TZ +02:00
    $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2016-03-27T01:59:59+01:00',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'msg date is +01:00 irregardless of DST');

    $msg = parse_syslog_line(q|<11>Mar  27 03:00:01 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2016-03-27T03:00:01+01:00',
        datetime_raw => 'Mar  27 03:00:01',
    }), 'msg date is +01:00 irregardless of DST');

    Test::MockTime::set_fixed_time("2016-02-29T05:41:00Z"); #TZ +01:00
    $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2015-03-27T01:59:59+01:00',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'msg date is +01:00 irregardless of DST');

    $msg = parse_syslog_line(q|<11>Mar  27 03:00:01 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2015-03-27T03:00:01+01:00',
        datetime_raw => 'Mar  27 03:00:01',
    }), 'msg date is +01:00 but since the date is in the future, it jumped back to 2015, with correct timezone');

    Test::MockTime::restore_time();
};

Test::MockTime::set_fixed_time("2016-01-01T00:00:01Z");

my %utc_syslogs = (
    'Cisco NX-OS'               => q|2015-01-01T11:09:36+02:00 hostname.company.tld : $year Jan  1 11:09:36.290 CET: %ETHPORT-5-IF_DOWN_CFG_CHANGE: Interface Ethernet121/1/1 is down(Config change)|,
    'ISO8601 with micro'        => q|2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}|,
    'ISO8601 with micro - zulu' => q|2015-09-30T06:26:06.779373Z my-host my-script.pl: {"lunchTime":1443612366.442}|,
);

    my %expects = (
        'Cisco NX-OS'               => {
            date => '2015-01-01', 'time' => '11:09:36', offset => '+02:00',
            datetime_str => "2015-01-01T11:09:36+02:00",
            datetime_utc => '2015-01-01T09:09:36Z',
            epoch        => Time::Moment->from_string("2015-01-01T11:09:36+02:00")->strftime("%s"),
        },
        'ISO8601 with micro'        => {
            date => '2015-09-30', 'time' => '06:26:06.779373', offset => '-05:00',
            datetime_str => "2015-09-30T06:26:06.779373-05:00",
            datetime_utc => '2015-09-30T11:26:06.779373Z',
            epoch        => Time::Moment->from_string("2015-09-30T06:26:06.779373-05:00")->epoch,
        },
        'ISO8601 with micro - zulu' => {
            date => '2015-09-30', 'time' => '06:26:06.779373', offset => 'Z',
            datetime_str => "2015-09-30T06:26:06.779373Z",
            datetime_utc => '2015-09-30T06:26:06.779373Z',
            epoch        => Time::Moment->from_string("2015-09-30T06:26:06.779373Z")->epoch,
        },
    );


my @test_configs = (
    { 'Pure UTC log parsing'        => { 'DateTimeCreate' => 0, 'EpochCreate' => 0, 'IgnoreTimezones' => 0, 'NormalizeToUTC' => 1,  }, },
    { 'Datetime with normalize'     => { 'DateTimeCreate' => 1, 'EpochCreate' => 0, 'IgnoreTimezones' => 0, 'NormalizeToUTC' => 1, }, },
);

foreach my $set (@test_configs) {

    my ($set_name, $config) = each %{$set};

    subtest $set_name => sub {

        local ( # localized to subtest scope
            $Parse::Syslog::Line::DateTimeCreate,
            $Parse::Syslog::Line::EpochCreate,
            $Parse::Syslog::Line::IgnoreTimeZones,
            $Parse::Syslog::Line::NormalizeToUTC,
        );

        _set_test_config( $config );

        while (my ($case_name, $msg) = each %utc_syslogs) {
            cmp_deeply(
                parse_syslog_line($msg),
                superhashof($expects{$case_name}),
                $case_name,
            );
        }
        done_testing();
    };
}

subtest 'config switching' => sub {
    set_syslog_timezone('local');
    local $Parse::Syslog::Line::DateTimeCreate=0;
    local $Parse::Syslog::Line::EpochCreate=0;
    local $Parse::Syslog::Line::IgnoreTimeZones=0;
    local $Parse::Syslog::Line::NormalizeToUTC=0;

    use_utc_syslog();

    is($Parse::Syslog::Line::DateTimeCreate, 0, 'config variable OK');
    is($Parse::Syslog::Line::EpochCreate, 0, 'config variable OK');
    is($Parse::Syslog::Line::IgnoreTimeZones, 0, 'config variable OK');
    is($Parse::Syslog::Line::NormalizeToUTC, 1, 'config variable OK');
    is(get_syslog_timezone, 'UTC');

    while (my ($case_name, $msg) = each %utc_syslogs) {
        cmp_deeply(
            parse_syslog_line($msg),
            superhashof($expects{$case_name}),
            $case_name,
        );
    }
    done_testing();
};

done_testing;

sub _set_test_config{
    my ( $config ) = @_;

    # set config values
    while (my ($name, $value) = each %{$config}) {
        ${"Parse::Syslog::Line::$name"} = $value;
    };

    return;
};

__END__
