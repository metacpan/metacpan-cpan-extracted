#!/usr/bin/env perl
# Test the date modifiers

use warnings;
use strict;
use utf8;

use Test::More;

use String::Print;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

# Date routines easily break on local system differences, so run most
# tests only on my private development system.
my $devel = $ENV{MARKOV_DEVEL} || 0;

my $now = 1498224823;

is $f->sprinti("{t YEAR}", t => '2017'),       '2017', 'year';
is $f->sprinti("{t YEAR}", t => '2017-06-23'), '2017', 'year';
is $f->sprinti("{t YEAR}", t => $now),         '2017', 'year';

is $f->sprinti("{t DATE}", t => '2017-06-23'), '2017-06-23', 'date';
is $f->sprinti("{t DATE}", t => '2017-06-23 15:50'), '2017-06-23', 'date';
is $f->sprinti("{t DATE}", t => '2017/06/23'), '2017-06-23', 'date';
is $f->sprinti("{t DATE}", t => '2017.06.23'), '2017-06-23', 'date';
is $f->sprinti("{t DATE}", t => '20170623'),   '2017-06-23', 'date';
is $f->sprinti("{t DATE}", t => '2017-6-23'),  '2017-06-23', 'date';
if($devel)
{  # timezone may influence date
   is $f->sprinti("{t DATE}", t => $now), '2017-06-23', 'date';
}

is $f->sprinti("{t TIME}", t => '13:33:43')  , '13:33:43', 'time';
is $f->sprinti("{t TIME}", t => '  13:33')   , '13:33:00', 'time';
is $f->sprinti("{t TIME}", t => '2017-06-23 13:33:43'), '13:33:43', 'time';
is $f->sprinti("{t TIME}", t => '2017-06-23 13:33'), '13:33:00', 'time';
if($devel)
{  # timezone does always influence time
   is $f->sprinti("{t TIME}", t => $now), '15:33:43', 'time';
}

### DT

# str2time ignores timezone if none given
is $f->sprinti("{t DT}", t => '2017-06-23 13:33:43'),'2017-06-23 13:33:43','dt';

if($devel)
{   is $f->sprinti("{t DT}", t => $now),     '2017-06-23 15:33:43', 'dt default';
    is $f->sprinti("{t DT(FT)}", t => $now), '2017-06-23 15:33:43', 'dt FT';
    is $f->sprinti("{t DT}", t => '2017-06-23 13:33:43+2'), '2017-06-23 13:33:43', 'dt';
    is $f->sprinti("{t DT}", t => '2017-06-23 13:33:43-25:15'), '2017-06-24 16:48:43', 'dt';
    is $f->sprinti("{t DT(ASC)}", t => '2017-06-23 13:33:43+2'), 'Fri Jun 23 13:33:43 2017', 'dt asc';
    is $f->sprinti("{t DT(ISO)}", t => '2017-06-23 13:33:43+2'), '2017-06-23T13:33:43+0200', 'dt iso';
    is $f->sprinti("{t DT(RFC2822)}", t => '2017-06-23 13:33:43+2'), 'Fri, 23 Jun 2017 13:33:43 +0200', 'dt rfc2822';
    is $f->sprinti("{t DT(RFC822)}", t => '2017-06-23 13:33:43+2'), 'Fri, 23 Jun 17 13:33:43 +0200', 'dt rfc822';

	$f->setDefaults(DT => { standard => 'ISO' });
	is $f->sprinti("{t DT}", t => $now), '2017-06-23T15:33:43+0200', 'dt setDefault';
}

### DateTime object

if($devel)
{	require DateTime;
	my $dt = DateTime->from_epoch(epoch => $now);
	is $f->sprinti("{t YEAR}", t => $dt),       '2017', 'DateTime year';
	is $f->sprinti("{t DATE}", t => $dt), '2017-06-23', 'DateTime date';
	is $f->sprinti("{t TIME}", t => $dt),   '13:33:43', 'DateTime time';
	is $f->sprinti("{t DT(FT)}", t => $now), '2017-06-23 15:33:43', 'DateTime dt';
}

done_testing;
