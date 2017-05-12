#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'Prompt::ReadKey';

our ( @read_ret, $print_ret );
our ( @read_called, @print_called );

{
	package MockPrompter; # Test::MockObject::Extends breaks for some reason with the default option handling
	use Moose;

	extends qw(Prompt::ReadKey);

	sub read_key {
		push @read_called, [@_];
		shift @read_ret;
	}

	sub print {
		push @print_called, [@_];
		$print_ret;
	}
}

my @options = (
	{ name => "one", default => 1 },
	{ name => "two" },
);

my $t = MockPrompter->new(
	prompt => "foo",
	options => \@options,
);

$print_ret = 1;

{
	local @read_ret = ( 'o' );
	local @read_called;
	local @print_called;

	is( $t->prompt, "one", "option one" );

	is( @read_called, 1, "read once" );

	is( @print_called, 1, "printed once" );
	is_deeply( \@print_called, [ [ $t, "foo [Ot] " ] ], "print arguments" );
}

{
	local @read_ret = ( 't' );
	local @read_called;
	local @print_called;

	is( $t->prompt, "two", "option two" );

	is( @read_called, 1, "read once" );
	is( @print_called, 1, "printed once" );
}

{
	local @read_ret = ( 'o' );
	local @read_called;
	local @print_called;

	is( $t->prompt( case_insensitive => 0 ), "one", "option one" );

	is( @read_called, 1, "read once" );

	is( @print_called, 1, "printed once" );
	is_deeply( \@print_called, [ [ $t, "foo [ot] " ] ], "print arguments" );
}

{
	local @read_ret = ( "\n" );
	local @read_called;
	local @print_called;

	is( $t->prompt, "one", "option one (the default)" );

	is( @read_called, 1, "read once" );

	is( @print_called, 1, "printed once" );
	is_deeply( \@print_called, [ [ $t, "foo [Ot] " ] ], "print arguments" );
}

{
	local @read_ret = ( 'x', 'o' );
	local @read_called;
	local @print_called;

	is( $t->prompt, "one", "option one" );

	is( @read_called, 2, "read twice" );

	is( @print_called, 3, "printed three times" );
	is_deeply(
		\@print_called,
		[
			[ $t, "foo [Ot] " ],
			[ $t, "'x' is not a valid choice, please select one of the options. Enter 'h' for help.\n" ],
			[ $t, "foo [Ot] " ],
		],
		"print arguments",
	);
}

{
	local @read_ret = ( 'h', 'o' );
	local @read_called;
	local @print_called;

	is( $t->prompt, "one", "option one" );

	is( @read_called, 2, "read twice" );

	is( @print_called, 3, "printed three times" );

	my $help = $print_called[1][1];
	$print_called[1][1] = \"help";
	is_deeply(
		\@print_called,
		[
			[ $t, "foo [Ot] " ],
			[ $t, \"help" ],
			[ $t, "foo [Ot] " ],
		],
		"print arguments",
	);

	like( $help, qr/one/, "mentions 'one'" );
	like( $help, qr/two/, "mentions 'two'" );
	like( $help, qr/help/, "mentions 'help'" );
}

{
	local @read_ret = ( 't' );
	local @read_called;
	local @print_called;

	is( $t->prompt( return_option => 1 ), $options[1], "option two" );

	is( @read_called, 1, "read once" );
	is( @print_called, 1, "printed once" );
}

done_testing;

