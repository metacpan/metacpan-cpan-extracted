#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MockTime;

use Data::Dumper;
use DateTime;
use DateTime::TimeZone;
use Time::Moment;
use Storable qw(dclone);

use Parse::Syslog::Line qw/:with_timezones/;


subtest 'If logdate is "in the future" it is actually "in the past"' => sub {

    # default settings
    Test::MockTime::set_fixed_time("2016-05-29T05:00:00Z");
    my $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2016-03-27T01:59:59',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'date is "in the past" - intuitive behaviour');

    Test::MockTime::set_fixed_time("2016-02-29T05:41:00Z"); #
    $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);

    cmp_deeply($msg, superhashof({
        datetime_str => '2015-03-27T01:59:59',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'date is "in the future" - HTTP::Date assumes it is in the past and finds a date match from previous year');

    done_testing();
};


subtest 'setting named timezone for syslog file' => sub {
    Test::MockTime::set_fixed_time("2016-05-29T05:00:00Z");

    set_syslog_timezone('EST');
    local $Parse::Syslog::Line::DateTimeCreate = 1;
    my $msg = parse_syslog_line(q|2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}|);
    cmp_deeply($msg, superhashof({
        datetime_str => '2015-09-30T06:26:06.779373-0500',
        datetime_raw => '2015-09-30T06:26:06.779373-05:00',
    }), 'By default we will discard timezone present in message.');
    is($msg->{datetime_obj}->iso8601(), '2015-09-30T06:26:06', "Also dt_object doesn't have it...");

    set_syslog_timezone('Europe/Warsaw');
    Test::MockTime::set_fixed_time("2016-09-01T05:00:00Z"); #TZ +02:00
    $msg = parse_syslog_line(q|2015-09-30T06:26:06.779373-05:00 my-host my-script.pl: {"lunchTime":1443612366.442}|);
    cmp_deeply($msg,
    superhashof({
        datetime_str => '2015-09-30T13:26:06.779373+0200',
        datetime_raw => '2015-09-30T06:26:06.779373-05:00',
    }), '...however with NormalizeToUTC we preserve it');
    is($msg->{datetime_obj}->strftime("%Y-%m-%dT%H:%M:%S%6N%z"), '2015-09-30T13:26:06779373+0200', 'but we remember them in dt object');

    $msg = parse_syslog_line(q|<11>Mar  27 01:59:59 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);
    cmp_deeply($msg, superhashof({
        datetime_str => '2016-03-27T01:59:59+0100',
        datetime_raw => 'Mar  27 01:59:59',
    }), 'msg date is +01:00 despite local timezone being +02:00');

    $msg = parse_syslog_line(q|<11>Mar  27 03:00:01 11.22.33.44 dhcpd: DHCPINFORM from 172.16.2.137 via vlan3|);
    cmp_deeply($msg, superhashof({
        datetime_str => '2016-03-27T03:00:01+0200',
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

    Test::MockTime::restore_time();
    done_testing();
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
        date => '2015-01-01', 'time' => '11:09:36', offset => '+0200',
        datetime_str => "2015-01-01T11:09:36+0200",
        datetime_utc => '2015-01-01T09:09:36Z',
        epoch        => Time::Moment->from_string("2015-01-01T11:09:36+02:00")->strftime("%s"),
    },
    'ISO8601 with micro'        => {
        _set_tz => 'EST',
        date => '2015-09-30', 'time' => '06:26:06.779373', offset => '-0500',
        datetime_str => "2015-09-30T06:26:06.779373-0500",
        datetime_utc => '2015-09-30T11:26:06.779373Z',
        epoch        => Time::Moment->from_string("2015-09-30T06:26:06.779373-05:00")->epoch . '.77937',
    },
    'ISO8601 with micro - zulu' => {
        date => '2015-09-30', 'time' => '06:26:06.779373', offset => 'Z',
        datetime_str => "2015-09-30T06:26:06.779373Z",
        datetime_utc => '2015-09-30T06:26:06.779373Z',
        epoch        => Time::Moment->from_string("2015-09-30T06:26:06.779373Z")->epoch . '.77937',
    },
);

subtest 'Millisecond resolution' => sub {
    while (my ($case_name, $msg) = each %utc_syslogs) {
        my $exp = dclone($expects{$case_name});
        my $tz  = exists $exp->{_set_tz} ? delete $exp->{_set_tz} : 'UTC';
        delete $exp->{datetime_utc};
        set_syslog_timezone($tz);
        cmp_deeply(
            parse_syslog_line($msg),
            superhashof($exp),
            $case_name,
        );
    }
    done_testing();
};

subtest 'config switching' => sub {
    use_utc_syslog();
    is($Parse::Syslog::Line::NormalizeToUTC, 1, 'config variable OK');
    is(get_syslog_timezone, 'UTC');

    while (my ($case_name, $msg) = each %utc_syslogs) {
        my $exp = dclone($expects{$case_name});
        # Adjust expected to the UTC values
        delete $exp->{_set_tz};
        $exp->{datetime_str} = delete $exp->{datetime_utc};
        $exp->{time}    = ($exp->{datetime_str} =~ /[ T](\d{2}(?::\d{2}){2}(?:\.\d+)?)/)[0];
        $exp->{offset}  = 'Z';
        use YAML;
        cmp_deeply(
            parse_syslog_line($msg),
            superhashof($exp),
            $case_name,
        ) || Dump parse_syslog_line($msg);
    }
    done_testing();
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
