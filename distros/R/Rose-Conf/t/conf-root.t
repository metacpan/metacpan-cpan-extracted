#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

use File::Spec;
require Rose::Conf::Root;

use FindBin '$Bin';

my $dir = File::Spec->tmpdir;

Rose::Conf::Root->import($dir);

is($ENV{'ROSE_CONF_FILE_ROOT'}, $dir, 'import()');
is(Rose::Conf::Root->conf_root, $dir, 'conf_root() 1');

Rose::Conf::Root->conf_root($Bin);

is($ENV{'ROSE_CONF_FILE_ROOT'}, $Bin, 'conf_root() 2');
is(Rose::Conf::Root->conf_root, $Bin, 'conf_root() 3');
