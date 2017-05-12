#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 14;

use POE::Filter::Syslog;
use POSIX qw(strftime  setlocale LC_ALL LC_CTYPE);

my $filter = POE::Filter::Syslog->new();

my $loc = eval { setlocale( LC_ALL, 'C' ) };

#
# Syslog uses an ambiguous datetime format.  No year and no timezone.
#

#
# correct this test for timezone issues
#
my $now = time();
my $ts = strftime("%b %d %H:%M:%S", localtime($now));

my $complex = "<1>$ts /USR/SBIN/CRON[16273]: (root) CMD (test -x /usr/lib/sysstat/sa1 && /usr/lib/sysstat/sa1)";
my $simple = "<1>$ts sungo: pie";
my $nodate = '<78>CROND[19679]: (root) CMD (/usr/bin/mrtg /etc/mrtg/mrtg.cfg)';
my $newline = "<1>$ts /USR/SBIN/CRON[16273]: (root) CMD (test -x /usr/lib/sysstat/sa1 \n&& /usr/lib/sysstat/sa1)";


my $records;

#
# simple
#
eval { $records = $filter->get([ $simple ]); };

ok(!$@, 'get() does not throw an exception');
ok(defined $records && @$records, "get() returns data when fed valid string");

is_deeply($records->[0], {
    'msg' => 'sungo: pie',
    'time' => $now,
    'pri' => '1',
    'facility' => 0,
    'severity' => 1,
    },
    'get() returns proper data when fed valid simple string'
);

#
# Complex
#
$records = undef;
eval { $records = $filter->get([ $complex ]); };
ok(!$@, 'get() does not throw an exception');
ok(defined $records && @$records, "get() returns data when fed valid string");

is_deeply($records->[0], {
    'msg' => '/USR/SBIN/CRON[16273]: (root) CMD (test -x /usr/lib/sysstat/sa1 && /usr/lib/sysstat/sa1)',
    'time' => $now,
    'pri' => '1',
    'facility' => 0,
    'severity' => 1,
    },
    'get() returns proper data when fed valid complex string');

#
# nodate
#
$records = undef;
eval { $records = $filter->get([ $nodate ]); };
ok(!$@, 'get() does not throw an exception');
ok(defined $records && @$records, "get() returns data when fed valid string");

is_deeply($records->[0], {
    'msg' => 'CROND[19679]: (root) CMD (/usr/bin/mrtg /etc/mrtg/mrtg.cfg)',
    'time' => time(),
    'pri' => '78', 
    'facility' => 9,
    'severity' => 6,
    },
    '_parse_syslog_message() returns proper data when given string with no date');

#
# bogus data
#
$records = undef;
eval { $records = $filter->get([ "I am not a syslog message" ]); };
ok(!$@, 'get() does not throw an exception');
ok(defined $records && !@$records, "get() returns no data when fed invalid string");

#
# data with a \n in it 
# apparently syslog-ng sends this
# 
$records = undef;
eval { $records = $filter->get([ $newline ]); };
ok(!$@, 'get() does not throw an exception');
ok(defined $records && @$records, "get() returns data when fed valid string");

is_deeply($records->[0], {
    'msg' => "/USR/SBIN/CRON[16273]: (root) CMD (test -x /usr/lib/sysstat/sa1 \n&& /usr/lib/sysstat/sa1)",
    'time' => $now,
    'pri' => '1',
    'facility' => 0,
    'severity' => 1,
    },
    'get() returns proper data when fed valid string containing newlines');


