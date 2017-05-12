package MooseX::Types::Locale::Currency;
use 5.008;
use strict;
use warnings;

our $VERSION = '0.001005'; # VERSION

use MooseX::Types -declare => [ qw( CurrencyCode ) ];
use MooseX::Types::Moose qw( Str Int );
use Module::Runtime 'use_module';

enum CurrencyCode, [
	use_module('Locale::Currency', 3 )
	&& Locale::Currency::all_currency_codes()
];

coerce CurrencyCode,
	from Int,
	via {
		use_module('Locale::Currency', 3 );
		Locale::Currency::currency_code2code( $_, 'num', 'alpha' );
	}
	;

1;

# ABSTRACT: Moose Types related to Locale Currency

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::Locale::Currency - Moose Types related to Locale Currency

=head1 VERSION

version 0.001005

=head1 SYNOPSIS

	{
		package My::Object;
		use Moose;
		use MooseX::Types::Locale::Currency qw( CurrencyCode );

		has currency_code => (
			is => 'ro',
			isa => CurrencyCode,
		);
		__PACKAGE__->meta->make_immutable;
	}

	my $obj = My::Object->new({
		currency_code => 'usd'
	});

=head1 DESCRIPTION

This module provides the C<CurrencyCode> type.

=head1 TYPES

=over

=item * C<CurrencyCode>

Base Type: C<enum>

will validate the the 3 character string passed to it is in the list of
C<all_currency_codes>

Enabling coercion will allow you to input the ISO 4217 Numeric currency code
and will convert it into the 3 Alpha character currency code.

=back

=head1 SEE ALSO

=over

=item * L<Locale::Currency>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/moosex-types-locale-currency/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
