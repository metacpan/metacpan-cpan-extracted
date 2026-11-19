#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();
my $code = $converter->get_protocol('MITSUBISHI')->decode_params(address => 119, command => 192);
my $pronto = $converter->export_code($code, 'Pronto');
my $back = $converter->import_format('Pronto', $pronto);
is($back->protocol, 'Mitsubishi', 'Mitsubishi round-trips protocol');
is($back->address, 119, 'Mitsubishi round-trips address');
is($back->command, 192, 'Mitsubishi round-trips command');
done_testing;
