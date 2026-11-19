#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();
my $code = $converter->get_protocol('DISH_NETWORK')->decode_params(command => 5);
my $pronto = $converter->export_code($code, 'Pronto');
my $back = $converter->import_format('Pronto', $pronto);
is($back->protocol, 'Dish_Network', 'Dish_Network round-trips protocol');
is($back->command, 5, 'Dish_Network round-trips command');
done_testing;
