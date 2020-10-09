#!perl
use Mojo::Base -strict;
use Test::More;

use Mojo::Log::Role::Color -func;
use Mojo::Log::Role::Color -func => 'x::DEBUG';

isa_ok +l(),        'Mojo::Log';
isa_ok +x::DEBUG(), 'Mojo::Log';

open my $FH, '>', \my $logged;
x::DEBUG()->level('debug')->handle($FH);
l error => 'Boom %s', 123;
like $logged, qr{Boom 123}, 'logged boom';

done_testing;
