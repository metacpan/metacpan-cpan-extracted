#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.07";
plan skip_all => "Test::Pod::Coverage 1.07 required for testing POD coverage" if $@;
eval "use Pod::Coverage::Moose";
plan skip_all => "Pod::Coverage::Moose is required for testing POD coverage" if $@;

my @modules = grep { $_ !~ /Type/ } all_modules('lib');

plan tests => scalar(@modules);

my %mod_private = (
    'Parse::StackTrace' => ['trim', qr/_class$/],
);

foreach my $module (@modules) {
    my @also_private = (qr/^has_/, qr/^clear_/, qr/^BUILD$/, qr/^[A-Z_]+$/);
    push(@also_private, @{ $mod_private{$module} }) if $mod_private{$module};
    pod_coverage_ok($module, { coverage_class => 'Pod::Coverage::Moose',
                               also_private =>  \@also_private });
}
