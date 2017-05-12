=pod

=encoding utf-8

=head1 PURPOSE

Test that Refinements works.

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

BEGIN {
	package AAAA;
	sub xxxx { 9999 };
	sub yyyy { 6666 };
};

BEGIN {
	package BBBB;
	BEGIN { our @ISA = 'AAAA' };
	sub yyyy { shift->SUPER::yyyy() / 2 };
};

BEGIN {
	package CCCC;
	use Refinements;
	refine 'AAAA::yyyy' => sub {
		my $orig = shift;
		shift->$orig() / 3
	};
};

isa_ok('CCCC', 'Refinements::Package');
can_ok('CCCC', qw/ add_refinement has_refinement get_refinement get_refinement_names /);

ok(CCCC->has_refinement('AAAA::yyyy'), 'has_requirement positive');
ok(!CCCC->has_refinement('AAAA::xxxx'), 'has_requirement negative');
ok(!CCCC->has_refinement('yyyy'), 'has_requirement fails if not fully-qualified');

is(ref CCCC->get_refinement('AAAA::yyyy'), ref(sub {}), 'get_requirement');
is(CCCC->get_refinement('AAAA::xxxx'), undef, 'get_requirement when not has_requirement');

is(AAAA->xxxx, 9999, 'AAAA->xxxx without CCCC');
is(AAAA->yyyy, 6666, 'AAAA->yyyy without CCCC');
is(BBBB->xxxx, 9999, 'BBBB->xxxx without CCCC');
is(BBBB->yyyy, 3333, 'BBBB->yyyy without CCCC');

{
	use CCCC;
	is(AAAA->xxxx, 9999, 'AAAA->xxxx with CCCC');
	is(AAAA->yyyy, 2222, 'AAAA->yyyy with CCCC');
	is(BBBB->xxxx, 9999, 'BBBB->xxxx with CCCC');
	is(BBBB->yyyy, 3333, 'BBBB->yyyy with CCCC');
}

is(AAAA->xxxx, 9999, 'AAAA->xxxx without CCCC');
is(AAAA->yyyy, 6666, 'AAAA->yyyy without CCCC');
is(BBBB->xxxx, 9999, 'BBBB->xxxx without CCCC');
is(BBBB->yyyy, 3333, 'BBBB->yyyy without CCCC');

done_testing;
