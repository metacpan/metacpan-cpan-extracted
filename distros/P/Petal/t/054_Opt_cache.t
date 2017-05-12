#!/usr/bin/perl
##############################################################################
# Tests the 'disk_cache' and 'memory_cache' options to Petal->new.
#

use Test::More tests => 12;

use warnings;
use lib 'lib';

use Petal;
use File::Spec;

my $data_dir = File::Spec->catdir('t', 'data');
my $file     = 'if.html';

# Confirm disk cache defaults to on

my $template = new Petal (file => $file, base_dir => $data_dir);

ok($template->disk_cache, "disk_cache defaults to on");


# Confirm option can disable it

$template = new Petal (file => $file, base_dir => $data_dir, disk_cache => 0);

ok(!$template->disk_cache, "disk_cache option turns it off");


# Confirm global can disable it

$Petal::DISK_CACHE = 0;
$template = new Petal (file => $file, base_dir => $data_dir);

ok(!$template->disk_cache, "\$Petal::DISK_CACHE turns it off");


# Confirm option can enable it

$template = new Petal (file => $file, base_dir => $data_dir, disk_cache => 1);

ok($template->disk_cache, "disk_cache option turns it on again");



# Confirm memory cache defaults to on

$template = new Petal (file => $file, base_dir => $data_dir);

ok($template->memory_cache, "memory_cache defaults to on");


# Confirm option can disable it

$template = new Petal (file => $file, base_dir => $data_dir, memory_cache => 0);

ok(!$template->memory_cache, "memory_cache option turns it off");


# Confirm global can disable it

$Petal::MEMORY_CACHE = 0;
$template = new Petal (file => $file, base_dir => $data_dir);

ok(!$template->memory_cache, "\$Petal::MEMORY_CACHE turns it off");


# Confirm option can enable it

$template = new Petal (file => $file, base_dir => $data_dir, memory_cache => 1);

ok($template->memory_cache, "memory_cache option turns it on again");



# Confirm cache_only defaults to off

$template = new Petal (file => $file, base_dir => $data_dir);

ok(!$template->cache_only, "cache_only defaults to off");


# Confirm option can enable it

$template = new Petal (file => $file, base_dir => $data_dir, cache_only => 1);

ok($template->cache_only, "cache_only option turns it on");


# Confirm global can enable it

$Petal::CACHE_ONLY = 1;
$template = new Petal (file => $file, base_dir => $data_dir);

ok($template->cache_only, "\$Petal::CACHE_ONLY turns it on");


# Confirm option can disable it

$template = new Petal (file => $file, base_dir => $data_dir, cache_only => 0);

ok(!$template->cache_only, "cache_only option turns it off again");


