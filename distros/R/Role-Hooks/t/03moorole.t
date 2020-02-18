use strict;
use warnings;
use Test::More;

{ package Local::Dummy1; use Test::Requires 'Moo';  };
{ package Local::Dummy2; use Test::Requires 'Moo::Role'; };

use Role::Hooks;

my %xxx;

{
	package Local::Role1;
	use Moo::Role;
	
	Role::Hooks->before_apply(__PACKAGE__, sub {
		push @{ $xxx{+__PACKAGE__}||=[] }, [before_apply => @_];
	});
	
	Role::Hooks->after_apply(__PACKAGE__, sub {
		push @{ $xxx{+__PACKAGE__}||=[] }, [after_apply => @_];
	});
}

{
	package Local::Role2;
	use Moo::Role;
	with 'Local::Role1';
	
	Role::Hooks->before_apply(__PACKAGE__, sub {
		push @{ $xxx{+__PACKAGE__}||=[] }, [before_apply => @_];
	});
	
	Role::Hooks->after_apply(__PACKAGE__, sub {
		push @{ $xxx{+__PACKAGE__}||=[] }, [after_apply => @_];
	});
}

{
	package Local::Class1;
	use Moo;
	with 'Local::Role2';
}

is_deeply(\%xxx, {
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
}) or diag explain(\%xxx);

done_testing;
