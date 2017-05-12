=pod

=encoding utf-8

=head1 PURPOSE

Check that closing over variables works OK.

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

my @out;
my $i = 0;
for my $letter ("a".."e")
{
	push @out, switch ($letter) mode ($a eq $b) do {
		case "a": 1 + ++$i;
		case "b": 2 + ++$i;
		case "c": 3 + ++$i;
		case "d": 4 + ++$i;
		case "e": 5 + ++$i;
		default:  0;
	};
}

is_deeply(
	\@out,
	[2, 4, 6, 8, 10],
);

done_testing;
