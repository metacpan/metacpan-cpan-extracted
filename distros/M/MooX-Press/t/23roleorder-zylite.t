use strict;
use warnings;
use Test::More;

use Zydeco::Lite;

app 'MyApp' => sub {
	
	class 'Class' => sub {
		with 'Role1', 'Role4';
	};
	
	role 'Role1' => sub {
		with 'Role2';
	};
	
	role 'Role2' => sub {
		with 'Role3', 'Role4';
	};
	
	role 'Role3' => sub {
		method 'foo' => sub { 666 };
	};
	
	role 'Role4' => sub {
		method 'bar' => sub { 999 };
	};
};

my $obj = 'MyApp'->new_class;

is($obj->foo, 666);
is($obj->bar, 999);

done_testing;
