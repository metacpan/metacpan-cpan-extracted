#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Cwd 'abs_path';

use FindBin qw($Bin);

BEGIN {
	use_ok ( 'Sys::Path::Example1::SPc' ) or exit;
}

exit main();

sub main {
	my %paths_to_check = (
		'prefix'        => [],
		'localstatedir' => [],
		'sysconfdir'    => [ 'etc' ],
		'datadir'       => [ 'share' ],
		'docdir'        => [ 'doc' ],
		'cache'         => [ 'cache' ],
		'log'           => [ 'log' ],
		'spool'         => [ 'spool' ],
		'run'           => [ 'run' ],
		'lock'          => [ 'lock' ],
		'state'         => [ 'state' ],
	);
	while (my ($type, $path) = each(%paths_to_check)) {
		is(
			Sys::Path::Example1::SPc->$type,
			File::Spec->catdir(
				abs_path(File::Spec->catfile($Bin, '..',)),
				@{$path},
			),
			$type,
		);
	}
	
	return 0;
}

