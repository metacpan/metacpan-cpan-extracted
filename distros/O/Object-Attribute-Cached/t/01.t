use strict;

package Twibble::Number;

use Object::Attribute::Cached
	squared => sub { shift->{num} ** 2 },
	uptosquare => sub { 1 .. shift->squared },
	squaredsquared => sub { map $_ ** 2, shift->uptosquare },
	gotsquares => sub { +{ map { $_ => 1 } shift->squaredsquared} };

sub new { bless { num => +pop }, +shift }

package main;

use Test::More tests => 17;

{
	my $obj = Twibble::Number->new(8);
	isa_ok $obj => "Twibble::Number";
	can_ok $obj => "squared";
	can_ok $obj => "uptosquare";
	can_ok $obj => "squaredsquared";
}

{
	my $ten = Twibble::Number->new(10);
	my $one = Twibble::Number->new(1);

	is $one->squared, 1, "Can get 1 squared";
	is $ten->squared, 100, "Can get 100 squared";

	my @o_upto = $one->uptosquare;
	is @o_upto, 1, "1 upto square";
	is $o_upto[-1], 1, "Just 1";

	my @t_upto = $ten->uptosquare;
	is @t_upto, 100, "100 upto square";
	is $t_upto[-1], 100, "1 - 100";

	my @o_sqsq = $one->squaredsquared;
	is @o_sqsq, 1, "1 nums in SqSq";
	is $o_sqsq[-1], 1, "Just 1 again";

	my @t_sqsq = $ten->squaredsquared;
	is @t_sqsq, 100, "100 nums in SqSq";
	is $t_sqsq[-1], 10000, " - up to 10000";

	my $got = $ten->gotsquares;
	ok $got->{9}, "Got 9";
	ok !$got->{10}, "But not 10";

	local $ten->{num} = 20;
	is $ten->squared, 100, "Value is cached";
}




