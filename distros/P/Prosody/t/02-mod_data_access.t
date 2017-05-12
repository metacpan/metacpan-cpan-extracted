#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use Prosody::Mod::Data::Access;

my $data = Prosody::Mod::Data::Access->new(
	jid => 'testone@test.domain',
	password => 'testpass',
);

isa_ok($data,'Prosody::Mod::Data::Access');

done_testing;
