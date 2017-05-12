#!/usr/bin/perl

##
## Tests for Petal::Utils :date modifiers
##

use blib;
use strict;
#use warnings;

use Test::More qw( no_plan );

use Carp;
use t::LoadPetal;

use Petal::Utils qw( :date );

my $hash = {
	date  => 1,
	date1 => '2003-09-05',
	date2 => '2003/09/05',
	date3 => '20030905',
};
my $template = Petal->new('date.html');
my $out      = $template->process( $hash );

# Dates:
like($out, qr|date = \w+\s+\d+ \d+ (?:\d+\:?)+|, 'date');
like($out, qr|date1 = 09/05/2003|, 'us_date');
like($out, qr|date2 = 09/05/2003|, 'us_date');
like($out, qr|date3 = 09/05/2003|, 'us_date');

TODO: {
    local $TODO = 'dynamically set date separator';
    like($out, qr|date4 = 09-05-2003|, 'us_date');
}

