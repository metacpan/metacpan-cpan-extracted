=pod

=encoding utf-8

=head1 PURPOSE

Test C<< $_type >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern -requires => { 'Moose' => '2.0600' };

use MooseX::Types::MoreUtils;

BEGIN { package Local::RoleA; use Moose::Role };
BEGIN { package Local::ClassA; use Moose; with 'Local::RoleA' };
BEGIN { package Local::ClassB; use Moose; sub xyz { 42 } };

my $MMTC = 'Moose::Meta::TypeConstraint';

object_ok(
	(sub { $_ == 42 })->$_type,
	q($from_coderef),
	isa    => [ $MMTC ],
	more   => sub {
		ok     $_[0]->check(42);
		ok not $_[0]->check(43);
	},
);

object_ok(
	{ role => 'Local::RoleA' }->$_type,
	q($roletype),
	isa    => [ $MMTC, "$MMTC\::Role" ],
	more   => sub {
		is     $_[0]->role, 'Local::RoleA';
		ok     $_[0]->check( Local::ClassA->new );
		ok not $_[0]->check( Local::ClassB->new );
	},
);

object_ok(
	{ class => 'Local::ClassA' }->$_type,
	q($classtype),
	isa    => [ $MMTC, "$MMTC\::Class" ],
	more   => sub {
		is     $_[0]->class, 'Local::ClassA';
		ok     $_[0]->check( Local::ClassA->new );
		ok not $_[0]->check( Local::ClassB->new );
	},
);

object_ok(
	{ duck => [qw/xyz/] }->$_type,
	q($ducktype),
	isa    => [ $MMTC, "$MMTC\::DuckType" ],
	more   => sub {
		is_deeply $_[0]->methods, [qw/xyz/];
		ok not $_[0]->check( Local::ClassA->new );
		ok     $_[0]->check( Local::ClassB->new );
	},
);

object_ok(
	{ enum => [qw/ abc xyz /] }->$_type,
	q($enumeration),
	isa    => [ $MMTC, "$MMTC\::Enum" ],
	more   => sub {
		is_deeply [sort @{$_[0]->values}], [qw/abc xyz/];
		ok     $_[0]->check('abc');
		ok not $_[0]->check('def');
		ok     $_[0]->check('xyz');
	},
);

object_ok(
	{ union => [ { enum => [qw/ abc xyz /] }, sub { $_ eq 42 } ] }->$_type,
	q($union),
	isa    => [ $MMTC, "$MMTC\::Union" ],
	more   => sub {
		ok     $_[0]->check('abc');
		ok not $_[0]->check('def');
		ok     $_[0]->check('xyz');
		ok     $_[0]->check('42');
	},
);

done_testing;

