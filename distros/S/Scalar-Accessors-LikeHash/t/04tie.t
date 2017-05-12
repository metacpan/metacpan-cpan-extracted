=head1 PURPOSE

Test the L<Tie::Hash::SerializedString> interface.

=head1 CAVEATS

Test is skipped if L<JSON> module unavailable.

Test cases are not very thorough.

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
use Test::Requires {
	JSON   => 2.00,
};

use Tie::Hash::SerializedString;

my $str  = '{}';
tie my %hash, 'Tie::Hash::SerializedString', \$str;

$hash{foo} = "bar";
is($str, '{"foo":"bar"}', 'tie mechanism seems to work');

my $str2 = %hash;
is($str2, '{"foo":"bar"}', '%hash in scalar context works');

$hash{baz} = "quux";

is_deeply(
	[keys %hash],
	[qw/ baz foo /],
	'keys %hash',
);

is_deeply(
	[values %hash],
	[qw/ quux bar /],
	'values %hash',
);

done_testing;
