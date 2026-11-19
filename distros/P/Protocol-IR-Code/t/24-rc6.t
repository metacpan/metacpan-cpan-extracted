#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();
my $code = $converter->get_protocol('RC6')->decode_params(address => 5, command => 10);
my $pronto = $converter->export_code($code, 'Pronto');
my $back = $converter->import_format('Pronto', $pronto);
is($back->protocol, 'RC6', 'RC6 round-trips protocol');
is($back->address, 5, 'RC6 round-trips address');
is($back->command, 10, 'RC6 round-trips command');
done_testing;
