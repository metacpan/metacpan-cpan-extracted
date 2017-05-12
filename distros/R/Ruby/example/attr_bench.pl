#!perl
use strict;
use warnings;
use Ruby ':DEFAULT', -eval => <<'EOR';

class MyObject
	def initialize
		@foo = 42;
	end
	def foo
		@foo
	end
	def foo=(x)
		@foo = x;
	end
end

EOR

use Benchmark qw(cmpthese timethese);

my $o = MyObject->new;

cmpthese timethese -1, {
	'$obj->foo' => sub{
		my $x = $o->foo;
	},
	'$obj->{foo}' => sub{
		my $x = $o->{'foo'};
	},
};
