=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::SymMethod works.

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

use MooX::Press (
	factory_package => 'Local',
	prefix => 'Local',
	class => [
		'Parent' => [
			symmethod => [
				'foo' => sub { push @R, 'Local::Parent' },
			],
		],
		'Child' => [
			extends   => 'Parent',
			with      => 'Role2',
			symmethod => [
				'foo' => {
					code  => sub { push @R, 'Local::Child//a' },
					order => -10,
				},
				'foo' => sub { push @R, 'Local::Child//b' },
			],
		],
		'Grandchild' => [
			extends   => 'Child',
			symmethod => [
				'foo' => sub { push @R, 'Local::Grandchild' },
			],
		],
	],
	role => [
		'Role1' => [
			symmethod => [
				'foo' => sub { push @R, 'Local::Role1' },
			],
		],
		'Role1B' => [
			with      => 'Role1'
		],
		'Role2' => [
			with      => [ 'Role1B' ],
			symmethod => [
				'foo' => sub { push @R, 'Local::Role2//a' },
				'foo' => {
					signature => [ 'n' => 'Int' ],
					named     => 1,
					code      => sub {
						my ($self, $arg) = @_;
						push @R, 'Local::Role2//b//' . $arg->n;
					},
				},
			],
		],
	],
);

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
