#!/usr/bin/perl
##############################################################################
# Tests the 'taint' option to Petal->new.
#

use Test::More tests => 4;

use warnings;
use lib 'lib';

use Petal;
use File::Spec;

my $data_dir = File::Spec->catdir('t', 'data');
my $file     = 'if.html';

# Confirm taint mode defaults to off

my $template = new Petal (file => $file, base_dir => $data_dir);

ok(!$template->taint, "taint mode defaults to off");


# Confirm option can enable it

$template = new Petal (file => $file, base_dir => $data_dir, taint => 1);

ok($template->taint, "taint option turns it on");


# Confirm global can enable it

$Petal::TAINT = 1;
$template = new Petal (file => $file, base_dir => $data_dir);

ok($template->taint, "\$Petal::TAINT turns it on");


# Confirm option can disable it

$template = new Petal (file => $file, base_dir => $data_dir, taint => 0);

ok(!$template->taint, "taint option turns it off again");


