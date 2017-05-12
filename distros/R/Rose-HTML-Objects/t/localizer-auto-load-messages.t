#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);

use Test::More tests => 7;

$ENV{'RHTMLO_LOCALES'} = 'fr,en';
$ENV{'RHTMLO_PRIME_CACHES'} = 1;
use_ok('Rose::HTML::Form::Field');

my $msgs = Rose::HTML::Form::Field->localizer->localized_messages_hash;

#use Data::Dumper;
#print Dumper($msgs);

ok(exists $msgs->{'FIELD_REQUIRED_GENERIC'}{'en'}, 'locales: en,fr 1');
ok(exists $msgs->{'FIELD_REQUIRED_GENERIC'}{'fr'}, 'locales: en,fr 2');
ok(!exists $msgs->{'FIELD_REQUIRED_GENERIC'}{'de'}, 'locales: en,fr 3');

Rose::HTML::Form::Field->localizer->localized_messages_hash({});

Rose::HTML::Form::Field->localizer->auto_load_locales('en');
Rose::HTML::Form::Field->localizer->load_all_messages('Rose::HTML::Form::Field');

$msgs = Rose::HTML::Form::Field->localizer->localized_messages_hash;

ok(exists $msgs->{'FIELD_REQUIRED_GENERIC'}{'en'}, 'locales: en 4');
ok(!exists $msgs->{'FIELD_REQUIRED_GENERIC'}{'fr'}, 'locales: en 5');
ok(!exists $msgs->{'FIELD_REQUIRED_GENERIC'}{'de'}, 'locales: en 6');
