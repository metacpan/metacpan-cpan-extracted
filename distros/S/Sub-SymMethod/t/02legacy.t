=pod

=encoding utf-8

=head1 PURPOSE

Test old Sub::SymMethod API.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

my @R;

{
	package Local::Parent;
	use Sub::SymMethod;
	symmethod foo => sub { push @R, __PACKAGE__ };
}

{
	package Local::Role1;
	use Role::Tiny;
	use Sub::SymMethod;
	symmethod foo => sub { push @R, __PACKAGE__ };
}

{
	package Local::Role1B;
	use Role::Tiny;
	with 'Local::Role1';
}

{
	package Local::Role2;
	use Role::Tiny;
	use Sub::SymMethod;
	use Types::Standard -types;
	symmethod foo => sub { push @R, __PACKAGE__. '//a' };
	with 'Local::Role1B';
	symmethod foo => (
		signature => [ n => Int ],
		named     => 1,
		code      => sub {
			my ($self, $arg) = @_;
			push @R, __PACKAGE__ . '//b//' . $arg->n;
		},
	);
}

{
	package Local::Child;
	use parent -norequire, 'Local::Parent';
	use Sub::SymMethod;
	use Role::Tiny::With;
	symmethod foo => ( order => -10 ) => sub { push @R, __PACKAGE__ . '//a' };
	with 'Local::Role2';
	symmethod foo => sub { push @R, __PACKAGE__ . '//b' };
}

{
	package Local::Grandchild;
	use parent -norequire, 'Local::Child';
	use Sub::SymMethod;
	symmethod foo => sub { push @R, __PACKAGE__ };
}

is 'Local::Grandchild'->foo( n => 42 ), 7;

is_deeply(
	\@R,
	[qw{
		Local::Child//a
		Local::Parent
		Local::Role2//a
		Local::Role2//b//42
		Local::Role1
		Local::Child//b
		Local::Grandchild
	}]
) or diag explain \@R;

@R = ();

is 'Local::Grandchild'->foo( n => [] ), 6;

is_deeply(
	\@R,
	[qw{
		Local::Child//a
		Local::Parent
		Local::Role2//a
		Local::Role1
		Local::Child//b
		Local::Grandchild
	}]
) or diag explain \@R;

@R = ();

is 'Sub::SymMethod'->dispatch('Local::Grandchild' => foo => ( n => 42 )), 7;

is_deeply(
	\@R,
	[qw{
		Local::Child//a
		Local::Parent
		Local::Role2//a
		Local::Role2//b//42
		Local::Role1
		Local::Child//b
		Local::Grandchild
	}]
) or diag explain \@R;

@R = ();

done_testing;
