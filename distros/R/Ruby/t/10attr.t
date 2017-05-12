#!perl

use warnings;
use strict;
use Test::More tests => 9;

BEGIN{ use_ok('Ruby') }

use Ruby -class => 'GC', -eval => <<'EOT';

class MyObject
	attr_accessor :foo;
	def initialize()
		@foo = 1;
	end
end

EOT

my $o = MyObject->new;

is($o->{foo}, 1, "fetch form attr method");
is($o->{foo}, 1, "fetch from ivtable");

$o->{foo} = 0xFF;

is($o->{foo}, 0xFF, "store");

$o->{foo} = 'foo';

is($o->{foo}, "foo");

$o->{foo} = 1;

$o->{foo}++;

is($o->{foo}, 2, "incr");

$o->{foo} *= 2;

is($o->{foo}, 4, "mul with assig");

for(1 .. 100){
	GC->start;
	$o->{foo}++;
}

is($o->{foo}, 104, "incr with GC->start");

$o->{foo} = true;

is_deeply($o->{foo}, true, "store Ruby object");
