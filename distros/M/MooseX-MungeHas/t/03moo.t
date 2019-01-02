=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::MungeHas features work with Moo.

=head1 DEPENDENCIES

Test requires Moo 1.000000 and Types::Standard 0.006 or is skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Requires { "Moo" => "1.000000" };
use Test::Requires { "Types::Standard" => "0.006" };
use Test::More;
use Test::Fatal;

use Types::Standard -types;

my $Even = Int->create_child_type(
	name       => "Even",
	constraint => sub { $_ % 2 == 0 },
)->plus_coercions(Int, '2 * $_');

{
	package Local::Class1;
	use Moo;
	use MooseX::MungeHas qw( is_ro simple_isa always_coerce );
	has attr1 => $Even;
	has attr2 => (isa => $Even, coerce => 0); # this should be simplified to Int
	has attr3 => (isa => $Even, is => "rwp");
	has attr4 => (isa => $Even, is => "lazy", default => sub { 42 });
	has attr5 => sub { 999 };
}

is(
	Local::Class1->new("attr$_" => 333)->${\"attr$_"}, 666,
	qq[Local::Class1 attribute attr$_ coerces],
) for 1, 3, 4;

is(
	Local::Class1->new("attr2" => 333)->attr2, 333,
	q[attr2 accepts an odd Int because its type check has been simplified],
);

can_ok("Local::Class1", "_set_attr3");

my $o = Local::Class1->new;
ok(
	!exists $o->{attr4},
	'$o->attr4 is not initialized',
);
is(
	$o->attr4,
	42,
	'default worked',
);
ok(
	exists $o->{attr4},
	'$o->attr4 is now initialized',
);

ok(
	!exists $o->{attr5},
	'$o->attr5 is not initialized',
);
is(
	$o->attr5,
	999,
	'default worked',
);
ok(
	exists $o->{attr5},
	'$o->attr5 is now initialized',
);

{
	package Local::Class2;
	use Moo;
	use MooseX::MungeHas qw( is_ro always_required );
	has attr1 => $Even;
	has attr2 => (isa => $Even, required => 0);
	has attr3 => (isa => $Even, default => sub { 42 });
}

use Test::Fatal;

my $e1 = exception { Local::Class2->new(attr1 => 2) };
is($e1, undef, "attr2 and attr3 shouldn't be required");

my $e2 = exception { Local::Class2->new(attr2 => 2) };
like($e2, qr/required/i, "attr1 should be required");

done_testing;
