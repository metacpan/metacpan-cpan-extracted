use strict;
use warnings;
use Test::More;

my %xxx;

use MooX::Press (
	prefix => 'Local',
	factory_package => 'Local',
	role => [
		'Role1' => {
			before_apply => sub {
				push @{ $xxx{'Role1'}||=[] }, [before_apply => @_];
			},
			after_apply => sub {
				push @{ $xxx{'Role1'}||=[] }, [after_apply => @_];
			},
		},
		'Role2' => {
			with => 'Role1',
			before_apply => sub {
				push @{ $xxx{'Role2'}||=[] }, [before_apply => @_];
			},
			after_apply => sub {
				push @{ $xxx{'Role2'}||=[] }, [after_apply => @_];
			},
		},
	],
	class => [
		'Class1' => { with => 'Role2' },
	],
);

is_deeply(\%xxx, {
	'Role1' => [
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
	'Role2' => [
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
}) or diag explain(\%xxx);

done_testing;
