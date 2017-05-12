#!/usr/bin/env perl

use Test::More;

my $CLASS = "MojoX::Moose::Controller";

use_ok $CLASS;
new_ok $CLASS;
isa_ok $CLASS, 'Mojolicious::Controller';
isa_ok $CLASS, 'Moose::Object';

done_testing(4);
