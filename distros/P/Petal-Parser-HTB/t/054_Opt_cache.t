#!/usr/bin/perl
##############################################################################
# Tests the 'disk_cache' and 'memory_cache' options to Petal->new.
#

use Test::More tests => 8;

use warnings;
use lib 'lib';

use Petal;
use Petal::Parser::HTB;
$Petal::INPUT = 'HTML';
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


