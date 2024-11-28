#!perl

use strict;
use warnings;
use bignum;

use Test::More;
use Test::Deep;
use Test::MockTime;

use Data::Dumper;
use DateTime;
use DateTime::TimeZone;
use Time::Moment;
use Storable qw(dclone);
use YAML  ();

use Parse::Syslog::Line qw/:with_timezones/;

set_syslog_timezone('UTC');

subtest 'If logdate is "in the future" it is actually "in the past"' => sub {

    # default settings
    Test::MockTime::set_fixed_time("2016-05-29T05:00:00Z");
    my $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2016-03-27T01:59:59Z',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'date is "in the past" - intuitive behaviour');

    Test::MockTime::set_fixed_time("2016-02-29T05:41:00Z"); #
    $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2015-03-27T01:59:59Z',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'date is "in the future" - HTTP::Date assumes it is in the past and finds a date match from previous year');
};


subtest 'setting named timezone for syslog file' => sub {
    Test::MockTime::set_fixed_time("2016-05-29T05:00:00Z");

    set_syslog_timezone('EST');
    my $msg = parse_syslog_line(q|2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}|);
    cmp_deeply($msg, superhashof({
        datetime_str => '2015-09-30T06:26:06.779373-0500',
        datetime_raw => '2015-09-30T06:26:06.779373-05:00',
    }), 'By default we will discard timezone present in message.');

    set_syslog_timezone('Europe/Warsaw');
    $msg = parse_syslog_line(q|2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}|);
    cmp_deeply($msg, superhashof({
        datetime_utc => '2015-09-30T11:26:06.779373Z',
        datetime_raw => '2015-09-30T06:26:06.779373-05:00',
    }), '...however with NormalizeToUTC we preserve it');

    $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);
    cmp_deeply($msg, superhashof({
        datetime_str => '2016-03-27T01:59:59+0100',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'msg date is +01:00 despite local timezone being +02:00');

    $msg = parse_syslog_line(q|<11>Mar  27 03:00:01 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);
    cmp_deeply($msg, superhashof({
        datetime_utc => '2016-03-27T02:00:01Z',
        datetime_raw => 'Mar  27 03:00:01',
    }), 'msg date is +02:00 same as local timezone because of DST (27 March 01:00 UTC - summer time start)');


    Test::MockTime::set_fixed_time("2016-02-29T05:41:00Z"); #TZ +01:00
    $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);
    cmp_deeply($msg, superhashof({
        datetime_str => '2015-03-27T01:59:59+0100',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'msg date is +01:00 same as local timezone');

    $msg = parse_syslog_line(q|<11>Mar  27 03:00:01 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);
    cmp_deeply($msg, superhashof({
        datetime_str => '2015-03-27T03:00:01+0100',
        datetime_raw => 'Mar  27 03:00:01',
    }), 'msg date is +02:00 but since it is in the future, it jumped back to 2015 where DST change ocurred 2015-03-29');
};

Test::MockTime::set_fixed_time("2016-01-01T00:00:01Z");
my %utc_syslogs = (
    'Cisco NX-OS'               => q|2015-01-01T11:09:36+02:00 hostname.company.tld : $year Jan  1 11:09:36.290 CET: %ETHPORT-5-IF_DOWN_CFG_CHANGE: Interface Ethernet121/1/1 is down(Config change)|,
    'ISO8601 with micro'        => q|2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}|,
    'ISO8601 with micro - zulu' => q|2015-09-30T06:26:06.779373Z my-host my-script.pl: {"lunchTime":1443612366.442}|,
);
my %expects = (
    'Cisco NX-OS'               => {
        _set_tz => 'EET',
        date => '2015-01-01', 'time' => '11:09:36', tz => '+0200',
        datetime_str => "2015-01-01T11:09:36+0200",
        datetime_utc => '2015-01-01T09:09:36Z',
        epoch        => Time::Moment->from_string("2015-01-01T11:09:36+02:00")->strftime("%s"),
    },
    'ISO8601 with micro'        => {
        _set_tz => 'EST',
        date => '2015-09-30', 'time' => '06:26:06.779373', tz => '-0500',
        datetime_str => "2015-09-30T06:26:06.779373-0500",
        datetime_utc => '2015-09-30T11:26:06.779373Z',
        epoch        => Time::Moment->from_string("2015-09-30T06:26:06.779373-05:00")->epoch . '.779373',
    },
    'ISO8601 with micro - zulu' => {
        date => '2015-09-30', 'time' => '06:26:06.779373', tz => 'Z',
        datetime_utc => '2015-09-30T06:26:06.779373Z',
        epoch        => Time::Moment->from_string("2015-09-30T06:26:06.779373Z")->epoch . '.779373',
    },
);

subtest 'Millisecond resolution' => sub {
    while (my ($case_name, $msg) = each %utc_syslogs) {
        my $exp = dclone($expects{$case_name});
        my $tz  = exists $exp->{_set_tz} ? delete $exp->{_set_tz} : 'UTC';
        set_syslog_timezone($tz);
        my $got = parse_syslog_line($msg);
        cmp_deeply(
            $got,
            superhashof($exp),
            $case_name,
        ) || diag YAML::Dump $got;
    }
};

done_testing;

sub _set_test_config{
    my ( $config ) = @_;

    # set config values
    while (my ($name, $value) = each %{$config}) {
        no strict 'refs';
        ${"Parse::Syslog::Line::$name"} = $value;
    };

    return;
};

__END__
