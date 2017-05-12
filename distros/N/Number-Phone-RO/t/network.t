#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
BEGIN { plan skip_all => '$ENV{RELEASE_TESTING} is false' unless $ENV{RELEASE_TESTING} }
BEGIN { plan tests => 4 }

use Number::Phone::RO;

my $nr = Number::Phone::RO->new("0767254626");

like $nr->operator, qr/COSMOTE/, 'operator (ported number)';
like $nr->operator_ported, qr/ROMTELECOM/, 'operator_ported (ported number)';

$nr = Number::Phone::RO->new("0773928513");

is $nr->operator, $nr->operator_ported, 'operator eq operator_ported (unported number)';

$nr = Number::Phone::RO->new("0111111111");

ok !$nr->operator, "operator (invalid number)";
