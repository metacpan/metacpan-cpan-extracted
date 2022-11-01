#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Perl::Critic::Utils qw(all_perl_files);
use Test::Perl::Critic;

subtest "critic" => sub {
    critic_ok($_) for all_perl_files(qw(lib t));
};

done_testing;

