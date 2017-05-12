=pod

=encoding utf-8

=head1 PURPOSE

Tests based on the examples in pod.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Switcheroo;

sub example1
{
	my $day = shift;
	my $day_type;
	switch ($day) {
		case 0, 6:  $day_type = "weekend";
		default:    $day_type = "weekday";
	}
	return $day_type;
}

subtest "SYNOPSIS" => sub {
	is(example1(0), 'weekend');
	is(example1($_), 'weekday') for 1..5;
	is(example1(6), 'weekend');
	is(example1('monkey'), 'weekday');
	done_testing;
};

sub example2
{
	local $_ = shift;
	my $day_type;
	switch {
		case 0, 6:  $day_type = "weekend";
		default:    $day_type = "weekday";
	}
	return $day_type;
}

subtest "Implicit test" => sub {
	is(example2(0), 'weekend');
	is(example2($_), 'weekday') for 1..5;
	is(example2(6), 'weekend');
	is(example2('monkey'), 'weekday');
	done_testing;
};

sub example3
{
	my $number = shift;
	switch ($number) {
		case 0:           "zero";
		case { $_ % 2 }:  "an odd number";
		default:          "an even number";
	}
}

subtest "Expression blocks" => sub {
	is(example3(0), 'zero');
	is(example3(1), 'an odd number');
	is(example3(2), 'an even number');
	is(example3(3), 'an odd number');
	is(example3(4), 'an even number');
	done_testing;
};

sub example7
{
	my $foo = shift;
	switch ($foo) {
		case /foo/:        "foo";
		case 1, /bar/, 2:  "bar";
		default:           "baz";
	}
}

subtest "Regexp Expressions" => sub {
	is(example7("foo"), 'foo');
	is(example7("bar"), 'bar');
	is(example7("baz"), 'baz');
	is(example7("1"),   'bar');
	is(example7("2"),   'bar');
	is(example7(undef), 'baz');
	done_testing;
};

sub example4
{
	my $number = shift;
	switch ($number) {
		case 0:          { "zero"           }
		case { $_ % 2 }: { "an odd number"  }
		default:         { "an even number" }
	}
}

subtest "Statement blocks" => sub {
	is(example4(0), 'zero');
	is(example4(1), 'an odd number');
	is(example4(2), 'an even number');
	is(example4(3), 'an odd number');
	is(example4(4), 'an even number');
	done_testing;
};

sub example5
{
	no warnings 'once';
	
	my $number = shift;
	switch ($number) mode ($a > $b) {
		case 1000:   "greater than 1000";
		case 100:    "greater than 100";
		case 10:     "greater than 10";
		case 1:      "greater than 1";
	}
}

subtest "Comparison expression" => sub {
	is(example5(0), undef);
	is(example5(1), undef);
	is(example5(7), 'greater than 1');
	is(example5(77), 'greater than 10');
	is(example5(77777), 'greater than 1000');
	done_testing;
};

sub example6
{
	my $day = shift;
	my $day_type = switch ($day) do {
		case 0, 6:  "weekend";
		default:    "weekday";
	};
	return $day_type;
}

subtest "Switch expressions" => sub {
	is(example6(0), 'weekend');
	is(example6($_), 'weekday') for 1..5;
	is(example6(6), 'weekend');
	is(example6('monkey'), 'weekday');
	done_testing;
};

done_testing;

