#!/usr/bin/perl

use v5.14;
use Test::More;
use Reconcile::Accounts::Vin;

eval 'use Test::More';
plan(skip_all => 'Test::More required') if $@;

plan tests => 11;

my $obj = Reconcile::Accounts::Vin->new(length => 17, remove => {I => 1, O => 0, Q => 0},);

ok($obj->get_length == 17, 'length attribute provided in contructor');

is($obj->get_length(), 17, 'get_length works');

unlike($obj->run_checks('xx83q5lkengq09ug'),qr/[a-z]/, 'run_checks converts to lower case');

ok(length ($obj->run_checks('xxx888vvv')) > 16, 'lpad pads input to minimum 17 characters');

like($obj->run_checks('xx83q5lk'),qr/^0/, 'lpad first letter 0');

unlike($obj->run_checks('xx83q5lkengq09ug'),qr/\W/, 'run_checks all word characters');

unlike($obj->run_checks('xx83q5lken**q09ug'),qr/\*/, 'run_checks char * removed');

unlike($obj->run_checks('xx8?q5+@kenq09ug'),qr/(\*|\?|\@)/, 'run_checks char ?+@ removed');

unlike($obj->run_checks('xx8oq5Okenq09ug'),qr/(o|O)/, 'run_checks char o and O removed');

unlike($obj->run_checks('xx8Iq5ikenq09ug'),qr/(o|O)/, 'run_checks char i and I removed');

unlike($obj->run_checks('xx8Iq5ikQnq09ug'),qr/(o|O)/, 'run_checks char q and Q removed');
