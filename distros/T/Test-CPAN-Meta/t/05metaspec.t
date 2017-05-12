#!/usr/bin/perl -w
use strict;

use Test::More  tests => 3;
use Test::CPAN::Meta;

my $vers = '1.3';
my $test = 't/samples/00-META.yml';

my $meta = meta_spec_ok($test,$vers);

#use Data::Dumper;
#diag(Dumper($meta));

is($meta->{license}, 'perl', 'hash value for license matches');
