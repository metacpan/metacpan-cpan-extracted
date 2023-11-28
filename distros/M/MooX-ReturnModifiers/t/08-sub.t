use Test::More;

{
	package Test::One::Thing;
	use MooX::ReturnModifiers qw/return_modifiers return_sub/;
	use Moo;

	sub import {
        	my %modifiers = return_modifiers($_[0]);
		$modifiers{sub}->('test', sub { return 10; });
		my $sub = return_sub($_[0]);
		$sub->('testing', sub { return 100; });
	}

	1;	
}

package main;

use Test::One::Thing;

my $obj = Test::One::Thing->new();

is($obj->test, 10);

is($obj->testing, 100);

done_testing();

1;



