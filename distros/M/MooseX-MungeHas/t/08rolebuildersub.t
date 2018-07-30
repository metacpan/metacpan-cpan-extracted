=pod

=encoding utf-8

=head1 PURPOSE

Test C<< has attr => (builder => sub {}) >> works in a role.

=head1 DEPENDENCIES

Test requires Moo or is skipped.

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Aaron Crane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Requires 'Moo';
use Test::More;

{
	package Local::Role1;
	use Moo::Role;
	use MooseX::MungeHas;
	has attr => (is => 'lazy', builder => sub { 'from role' });
}

{
	package Local::Class1;
	use Moo;
	with 'Local::Role1';
	sub _build_attr { 'from class' }
}

{
	package Local::Class2;
	use Moo;
	with 'Local::Role1';
	around _build_attr => sub { 'from class' };
}

is(Local::Class1->new->attr, 'from class');
is(Local::Class2->new->attr, 'from class');
done_testing;

