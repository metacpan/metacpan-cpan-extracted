#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use_ok ('Panotools::Script::Line::Variable');

my $variable = new Panotools::Script::Line::Variable;

is (%{$variable}, 0, 'image variables are undef');

$variable->Parse ("v v0 r0 p0 r1 p1 y1 e1 e2 b7 Eev7\n\n");

ok (exists $variable->{2}->{e}, 'e parameter of image 2 will be optimised');
is ($variable->{0}->{e}, undef, 'e parameter of image 0 will not be optimised');
ok (exists $variable->{7}->{Eev}, 'Eev parameter of image 7 will be optimised');
is ($variable->{0}->{Eev}, undef, 'Eev parameter of image 0 will not be optimised');


#use Data::Dumper; die Dumper $variable->Assemble;

like ($variable->Assemble, '/ e1/', 'optimise image-1 e-parameter written as e1');
like ($variable->Assemble, '/ e2/', 'optimise image-2 e-parameter written as e2');
unlike ($variable->Assemble, '/ e0/', 'no optimise image-0 e-parameter not written');

ok ($variable->Report (0));
