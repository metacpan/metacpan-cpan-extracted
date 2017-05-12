=pod

=encoding utf-8

=head1 PURPOSE

Test that PerlX::Window works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use PerlX::Window;

subtest "simple example with string" => sub
{
	my $str = "Foobar";
	my @r;
	while (window $str, 3) {
		push @r, $window;
		push @r, window_pos;
	}
	
	is($str, 'Foobar', 'string not modified');
	is_deeply(
		\@r,
		[ qw/ Foo 0 oob 1 oba 2 bar 3 / ],
		'sliding window was correct',
	) or diag explain(\@r);
};

subtest "simple example with array" => sub
{
	my @arr = qw"F o o b a r";
	my @r;
	while (window @arr, 3) {
		push @r, [ @window ];
	}
	
	is_deeply(\@arr, [qw"F o o b a r"], 'array not modified');
	is_deeply(
		\@r,
		[
			[ qw"F o o" ],
			[ qw"o o b" ],
			[ qw"o b a" ],
			[ qw"b a r" ],
		],
		'sliding window was correct',
	) or diag explain(\@r);
};

subtest "read-write example with string" => sub
{
	my $str = "Foobar";
	my @r;
	while (window $str, 3) {
		$window = 'eeb' if $window eq 'oob';
		push @r, $window;
	}
	
	is($str, 'Feebar', 'string modified correctly');
	is_deeply(
		\@r,
		[ qw/ Foo eeb eba bar / ],
		'sliding window was correct',
	) or diag explain(\@r);
};

subtest "read-write example with array" => sub
{
	my @arr = qw"F o o b a r";
	my @r;
	while (window @arr, 3) {
		if ("@window" eq 'o o b')
		{
			$window[0] = 'e';
			$window[1] = 'e';
		}
		push @r, [ @window ];
	}
	
	is_deeply(\@arr, [qw"F e e b a r"], 'array modified correctly');
	is_deeply(
		\@r,
		[
			[ qw"F o o" ],
			[ qw"e e b" ],
			[ qw"e b a" ],
			[ qw"b a r" ],
		],
		'sliding window was correct',
	) or diag explain(\@r);
};

done_testing;

