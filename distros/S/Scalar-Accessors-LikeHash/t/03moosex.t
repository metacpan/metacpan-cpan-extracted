=head1 PURPOSE

Test L<Acme::MooseX::JSON> module.

=head1 CAVEATS

Test is skipped if L<JSON> and L<Moose> modules are unavailable.

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
	Moose  => 2.00,
};

{
	package Local::Class;
	use Acme::MooseX::JSON;
	has aaa => (
		is    => 'rw',
		isa   => 'ArrayRef',
	);
}

sub checker
{
	plan tests => 3;
	my $o1 = Local::Class->new(aaa => [1,2,3]);
	is($$o1, '{"aaa":[1,2,3]}', 'Object is internally JSON');
	is_deeply($o1->aaa, [1,2,3]);
	$o1->aaa([4,5,6]);
	is_deeply($o1->aaa, [4,5,6]);
}

subtest "Mutable class" => \&checker;

Local::Class->meta->make_immutable;
subtest "Immutable class" => \&checker;

done_testing;
