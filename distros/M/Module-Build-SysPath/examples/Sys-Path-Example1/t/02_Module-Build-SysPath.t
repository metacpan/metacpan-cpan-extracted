#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Differences;

use FindBin qw($Bin);
use lib File::Spec->catdir($Bin, 'lib');
use lib File::Spec->catdir($Bin, '..', 'lib');

BEGIN {
	use_ok ( 'Module::Build::SysPath' ) or exit;
}

exit main();

sub main {
	my $builder = Module::Build::SysPath->new(
		module_name  => 'Sys::Path::Example1',
    	license      => 'perl',
	);

	eq_or_diff(
		$builder->{'properties'}->{'install_path'},
		{
			'sysconfdir' => '/etc',
			'datadir'    => '/usr/share',
		},
		'install_path check'
	);
	eq_or_diff(
		$builder->{'properties'}->{'sysconfdir_files'},
		{
			'etc/project/blah2.txt' => 'sysconfdir/project/blah2.txt',
			'etc/project/blah' => 'sysconfdir/project/blah',
			'etc/etc-test.txt' => 'sysconfdir/etc-test.txt'
		},
		'sysconfdir_files check'
	);
	eq_or_diff(
		$builder->{'properties'}->{'datadir_files'},
		{
			'share/sys-path-example1/README' => 'datadir/sys-path-example1/README',
		},
		'datadir_files check'
	);	
	
	return 0;
}

