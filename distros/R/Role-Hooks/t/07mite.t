use strict;
use warnings;
use Test::More;

use Test::Requires '5.010001';
use Test::Requires 'FindBin';
use Role::Hooks;

use FindBin qw($Bin);
use lib "@{[keys%{+{$Bin=>1}}]}/mite/lib"; # untaint :/

use Local::Class1;

is_deeply(\%Local::xxx, {
	'Local::Role1' => [
		[
			'before_apply',
			'Local::Role1',
			'Local::Role2'
		],
		[
			'after_apply',
			'Local::Role1',
			'Local::Role2'
		],
		[
			'before_apply',
			'Local::Role2',
			'Local::Class1'
		],
		[
			'after_apply',
			'Local::Role2',
			'Local::Class1'
		]
	],
	'Local::Role2' => [
		[
			'before_apply',
			'Local::Role2',
			'Local::Class1'
		],
		[
			'after_apply',
			'Local::Role2',
			'Local::Class1'
		]
	]
}) or diag explain(\%Local::xxx);

done_testing;
