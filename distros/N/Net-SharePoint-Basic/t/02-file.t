#!perl

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;

use File::Basename;

use Net::SharePoint::Basic;

my $test_file = "t/filetests/aa";
my $test_dir  = dirname $test_file;
eval { Net::SharePoint::Basic::read_file($test_file) };
ok($@, 'read non-existant file failed expectedly');
like($@, qr/read file $test_file/, 'error set');
my $file = Net::SharePoint::Basic::write_file('aa', $test_file);
is($file, $test_file, 'file written');
ok(-f $file, 'file exists');
is(-s $file, length('aa'), 'file correct size');
my $contents = Net::SharePoint::Basic::read_file($test_file);
is($contents, 'aa', 'contents read ok');
END {
	unlink $test_file;
	rmdir $test_dir;
}
