#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();
my $code = $converter->get_protocol('PIONEER')->decode_params(address => 162, command => 13);
my $pronto = $converter->export_code($code, 'Pronto');
my $back = $converter->import_format('Pronto', $pronto);
is($back->protocol, 'Pioneer', 'Pioneer round-trips protocol');
is($back->address, 162, 'Pioneer round-trips address');
is($back->command, 13, 'Pioneer round-trips command');
done_testing;
