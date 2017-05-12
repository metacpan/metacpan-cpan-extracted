=head1 PURPOSE

Tests that the one-argument form of C<does> works with lexical C<< $_ >>,
using a Perl 5.10 C<given> block.

In Perl 5.17.x and above, C<given> no longer uses lexical C<< $_ >> but this
test should continue to work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires "v5.10.1";

BEGIN {
	plan skip_all => "skipping given/when test in Perl >= 5.17" if $] >= 5.017;
};

use feature qw(switch);
use Scalar::Does -constants;

plan tests => 2;

my $array = [];

ok does $array, ARRAY;

given ($array) {
	when ( does(HASH)  ) { fail() }
	when ( does(ARRAY) ) { pass() }
}

