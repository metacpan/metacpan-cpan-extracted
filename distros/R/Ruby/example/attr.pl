#!perl
use strict;
use warnings;
use Ruby -all;
use Ruby -eval => <<'RUBY';

class Foo
	attr_accessor :foo, :bar, :baz;
end

RUBY

my $o = Foo->new;
$o->{foo} = 42;
$o->{bar} = "str";
$o->{baz} = { k => 'v' };

p {%$o};
