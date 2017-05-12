#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

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

my $t = MockPrompter->new(
    prompt => "foo",
    options => [
        { name => 'hit' },
    ],
);

like(exception { $t->prompt }, qr/duplicate value for 'keys'/);

$t = MockPrompter->new(
    prompt    => "foo",
    auto_help => 0,
    options   => [
        { name => 'hit' },
    ],
);

is(exception {
    local @read_ret = ('h');
    $t->prompt;
}, undef);

done_testing;

