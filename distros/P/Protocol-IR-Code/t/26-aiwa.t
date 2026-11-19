#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();
my $code = $converter->get_protocol('AIWA')->decode_params(address => 127, command => 15);
my $pronto = $converter->export_code($code, 'Pronto');
my $back = $converter->import_format('Pronto', $pronto);
is($back->protocol, 'Aiwa', 'Aiwa round-trips protocol');
is($back->address, 127, 'Aiwa round-trips address');
is($back->command, 15, 'Aiwa round-trips command');
done_testing;
