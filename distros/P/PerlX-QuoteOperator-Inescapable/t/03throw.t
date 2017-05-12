=head1 PURPOSE

Check various syntax that should throw errors.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.010001;
use strict;
use warnings;
use utf8;
use Test::More;

use PerlX::QuoteOperator::Inescapable;

sub throws_ok ($$;$)
{
	my ($code, $regexp, $desc) = @_;
	$desc //= "CODE THROWS: $code";
	local $@;
	no warnings; eval $code; use warnings;
	defined($@) ? like($@, $regexp, $desc) : fail("No exception! $desc");
}

throws_ok
	q{ Q(Hello },
	qr{^Unterminated inescapable quoted string found},
	qq{Unterminated quote throws.};

throws_ok
	q{ Q(Hello (Earth) World) },
	qr{^syntax error}i,
	qq{Attempt at nesting quotes fails.};

throws_ok
	q{ Q#Hello# },
	qr{},
	qq{Hash quote delimiter throws.};

done_testing;
