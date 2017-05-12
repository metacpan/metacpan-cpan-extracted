#!/usr/bin/env perl

use Test::More;

my $CLASS = "MojoX::Renderer::IncludeLater";
use_ok $CLASS;
new_ok $CLASS;
can_ok $CLASS, 'register';

done_testing;
