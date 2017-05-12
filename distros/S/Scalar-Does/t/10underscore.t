=head1 PURPOSE

Tests that the one-argument forms of C<does> and C<overloads> work with lexical
C<< $_ >>, using C<< my $_ >>.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=80434>.

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
use Test::Requires "v5.10.0";

BEGIN {
	plan skip_all => "skipping lexical \$_ test in Perl >= 5.17" if $] >= 5.017;
};

use Scalar::Does -constants, 'overloads';

$_ = [];
ok does ARRAY;
ok not does HASH;

{
	my $_ = {};
	ok does HASH;
	ok not does ARRAY;
}

{
	my $_ = do {
		package Local::Overloader;
		use overload '%{}' => sub { +{} };
		bless [];
	};

	ok does ARRAY;
	ok does HASH;
	ok not overloads '@{}';
	ok overloads '%{}';
}

done_testing;

