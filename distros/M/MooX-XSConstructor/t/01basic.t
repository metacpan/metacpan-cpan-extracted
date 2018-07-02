=pod

=encoding utf-8

=head1 PURPOSE

Test that MooX::XSConstructor compiles and works.

=head1 AUTHO
Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Warnings;

# stolen from MooseX::XSAccessor
sub is_xs  {
	require Scalar::Util;
	my $sub = shift;
	if (Scalar::Util::blessed($sub) and $sub->isa("Class::MOP::Method")) {
	$sub = $sub->body;
	}
	elsif (not ref $sub) {
		no strict "refs";
		$sub = \&{$sub};
	}
	require B;
	!! B::svref_2object($sub)->XSUB;
}


{
	package Foo;
	use Moo; has xyz => (is => "ro", required => 1);
}

{
	package Bar;
	use Moo;
	use MooX::XSConstructor;
	extends "Foo";
	has abc => (is => "lazy", builder => sub { 123 });
}

ok !is_xs('Foo::new') => 'Foo::new not redefined';
ok is_xs('Bar::new') => 'Bar::new redefined';

is_deeply(Bar->new(xyz => 123), bless({ xyz => 123 } => "Bar"), "is deeply");

my $e = exception { Bar->new };
like($e, qr/required/, 'required stuff works');

done_testing;
