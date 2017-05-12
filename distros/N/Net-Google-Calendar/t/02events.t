#!perl -w

use strict;
use Net::Google::Calendar;
use Net::Google::Calendar::Entry;
use lib qw(t/lib);
use GCalTest;
use Test::More;

our $cal = eval { GCalTest::get_calendar('login') };
if ($@) {
	plan skip_all => "because $@";
} else {
	plan tests => 16;
}

do('t/02events_base');
