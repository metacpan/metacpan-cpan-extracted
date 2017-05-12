#!/usr/bin/perl

=pod

=encoding utf-8

=head1 PURPOSE

Test C<< make_builder($coderef, %args) >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings;

use t::lib::TestUtils;

my $r;
{
	package My::Organization;
	use Moo;
	extends qw(Organization);
	with qw(MooseX::ConstructInstance);
	after construct_instance => sub
	{
		shift;
		$r = [ @_ ];
	};
}

my $org = 'My::Organization'->new(
	name       => 'Catholic Church',
	boss_name  => 'Francis',
	boss_title => 'Pope',
	hq_name    => 'Rome',
);

isa_ok($org, 'Organization', '$org');
isa_ok($org->boss, 'Person', '$org->boss');

is_deeply(
	$r,
	[
		'Person',
		{ name => 'Francis', title => 'Pope' },
	],
	'construct_instance was passed expected data',
);

done_testing;
