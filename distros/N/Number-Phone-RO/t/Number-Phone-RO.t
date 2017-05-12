#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More tests => 22;
BEGIN { use_ok('Number::Phone::RO') };

my $nr;

sub num {
	my ($num) = @_;
	note "Now working with the number $num";
	$nr = Number::Phone::RO->new($num);
}

num '0';
ok !defined $nr, 'Constructor returns undef';

num '0350123456';
ok $nr->is_geographic, 'is_geographic';
ok $nr->is_fixed_line, 'is_fixed_line';
ok !$nr->is_mobile, '!is_mobile';
ok !$nr->is_tollfree, 'is_tollfree';
ok !$nr->is_specialrate, 'is_specialrate';
is $nr->areacode, '350', 'areacode';
is $nr->areaname, 'Vâlcea', 'areaname';
is $nr->subscriber, '123456', 'subscriber';
is $nr->format, '+40 350 123 456', 'format';

num '0211234567';
is $nr->areacode, '21', 'areacode';
is $nr->subscriber, '1234567', 'subscriber';
is $nr->format, '+40 21 123 4567', 'format';

num '0800123123';
is $nr->intra_country_dial_to, '0800123123', 'intra_country_dial_to';
ok $nr->is_tollfree, 'is_tollfree';
is $nr->country_code, 40, 'country_code';
like $nr->regulator, qr/ANCOM/, 'regulator';
ok !defined $nr->areaname, 'areaname is undef';

num '0906123456';
ok $nr->is_adult, 'is_adult';

num '0731123456';
ok $nr->is_mobile, 'is_mobile';
ok !$nr->is_fixed_line, 'is_fixed_line';
