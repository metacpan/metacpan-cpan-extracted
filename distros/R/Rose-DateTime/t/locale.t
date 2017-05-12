#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;

BEGIN 
{
  use_ok('Rose::DateTime::Util');
  use_ok('DateTime');
}

Rose::DateTime::Util->import('parse_date');

Rose::DateTime::Util->european_dates(undef); # re-init

my $d = parse_date('03-05-2003');
is($d->month, 3, 'locale 1');

DateTime->DefaultLocale('de');

$d = parse_date('03-05-2003');
is($d->month, 3, 'locale 2');

Rose::DateTime::Util->european_dates(undef); # re-init

$d = parse_date('03-05-2003');
is($d->month, 5, 'locale 3');

is(Rose::DateTime::Util->european_dates, 1, 'european_dates check');

DateTime->DefaultLocale('en_US');
Rose::DateTime::Util->european_dates(undef); # re-init

$d = parse_date('03-05-2003');
is($d->month, 3, 'locale 4');
