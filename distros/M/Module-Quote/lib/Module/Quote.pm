package Module::Quote;

use 5.008;
use strict;
use warnings;

BEGIN {
	$Module::Quote::AUTHORITY = 'cpan:TOBYINK';
	$Module::Quote::VERSION   = '0.002';
}

sub import
{
	my $me = shift;
	@_ = qw(qm) unless @_;
	
	require Module::Hash;
	require PerlX::QuoteOperator;
	
	while (@_)
	{
		my $name = shift;
		my %args = %{ ref $_[0] ? shift : {} };
		
		my $emulate = delete $args{emulate} || 'qq';
		my $mh      = "Module::Hash"->new(%args);
		
		"PerlX::QuoteOperator"->new->import($name, {
			-emulate => $emulate,
			-parser  => 1,
			-with    => sub ($) { $mh->use(@_) },
		}, scalar caller);
	}
}

1
__END__

=head1 NAME

Module::Quote - a quote-like operator that requires modules for you

=head1 SYNOPSIS

	use Test::More tests => 1;
	use Module::Quote;
	
	my $number = qm( Math::BigInt 1.00 )->new(42);
	
	isa_ok $number, "Math::BigInt";

=head1 DESCRIPTION

The C<< qm() >> quote-like operator will load a module and return its name.
So the following should just work, even if you haven't C<< use >>d
Math::BigInt in advance.

	qm( Math::BigInt 1.00 )->new(42)

The more usual invocation:

	Math::BigInt->new(42)

won't automatically load Math::BigInt, won't check a version number, and
crucially is ambiguous! (See what happens when you define a sub called
C<BigInt> in the C<Math> package.)

The C<qm> operator interpolates variables, so this works too:

	my $x = "BigInt 1.00";
	qm( Math::$x )->new(42);

You may export C<qm> with an alternative name:

	use Module::Quote 'qmod';

You may provide a hashref of options for the quote-like operator:

	use Module::Quote qm => { emulate => 'q' };

You can export the operator multiple times with different options:

	use Module::Quote
		qm  => { emulate => 'q' },
		qqm => { emulate => 'qq' },
	;

The C<< optimistic >> and C<< prefix >> options from L<Module::Hash> are
supported. As is C<< emulate >> which can be set to C<< "qq" >> (the default)
or C<< "q" >> (to disable interpolation).

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Module-Quote>.

=head1 SEE ALSO

L<Module::Hash> - similar idea, but less magic.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

