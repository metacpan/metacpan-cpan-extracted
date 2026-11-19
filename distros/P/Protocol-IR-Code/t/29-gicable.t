#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();
my $code = $converter->get_protocol('G.I.CABLE')->decode_params(command => 5);
my $pronto = $converter->export_code($code, 'Pronto');
my $back = $converter->import_format('Pronto', $pronto);
is($back->protocol, 'G.I.Cable', 'G.I.Cable round-trips protocol');
is($back->command, 5, 'G.I.Cable round-trips command');
done_testing;
