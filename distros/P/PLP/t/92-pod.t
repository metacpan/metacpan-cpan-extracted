use strict;
use warnings;

use Test::More;
use ExtUtils::Manifest qw(maniread);
eval 'use Test::Pod 1.00';
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my $manifest = maniread();
my @pod = grep /\.(?:pm|pod)$/, keys %$manifest;
plan tests => scalar @pod;
pod_file_ok($_ => $_) for @pod;

