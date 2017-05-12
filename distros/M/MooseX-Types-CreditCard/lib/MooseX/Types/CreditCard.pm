package MooseX::Types::CreditCard;
use 5.008;
use strict;
use warnings;

our $VERSION = '0.002003'; # VERSION

use MooseX::Types -declare => [ qw(
	CreditCard
	CardNumber
	CardSecurityCode
	CardExpiration
) ];

use Module::Runtime                        qw( use_module      );
use MooseX::Types::Moose                   qw( Str Int HashRef );
use MooseX::Types::Common::String 0.001005 qw( NumericCode     );
use MooseX::Types::DateTime ();


subtype CardNumber,
	as NumericCode,
	where {
		length($_) <= 20
		&& length $_ >= 12
		&& use_module('Business::CreditCard')
		&& Business::CreditCard::validate($_)
	},
	message {'"'. $_ . '" is not a valid credit card number' };


subtype CardSecurityCode,
	as NumericCode,
	where {
		length $_ >= 3
		&& length $_ <= 4
		&& $_ =~ /^[0-9]+$/xms
	},
	message { '"'
		. $_
		. '" is not a valid credit card security code. Must be 3 or 4 digits'
	};

subtype CardExpiration,
	as MooseX::Types::DateTime::DateTime,
	where {
		my ( $month, $year ) = ( $_->month, $_->year );

		my $comparitor
			= use_module('DateTime')
			->last_day_of_month( month => $month, year => $year )
			;

		return 0 unless DateTime->compare( $_, $comparitor ) == 0;
		return 1;
	},
	message {
		'DateTime object is not the last day of month';
	};

subtype CreditCard,
	as CardNumber,
	where {
		our @CARP_NOT = qw( Moose::Meta::TypeConstraint );
		use_module('Carp');
		Carp::carp 'DEPRECATED: use CardNumber instead of CreditCard Type';
		1;
	}, # just for backcompat
	message {'"'. $_ . '" is not a valid credit card number' };

coerce CardNumber, from Str,
	via {
		my $int = $_;
		$int =~ tr/0-9//cd;
		return $int;
	};
	message {'"'. $_ . '" is not a valid credit card number' };

coerce CreditCard, from Str,
	via {
		my $int = $_;
		$int =~ tr/0-9//cd;
		return $int;
	};
	message {'"'. $_ . '" is not a valid credit card number' };

coerce CardExpiration, from HashRef,
	via {
		return use_module('DateTime')->last_day_of_month( %{ $_ } );
	};

1;

# ABSTRACT: Moose Types related to Credit Cards

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::CreditCard - Moose Types related to Credit Cards

=head1 VERSION

version 0.002003

=head1 SYNOPSIS

	{
		package My::CreditCard;
		use Moose;
		use MooseX::Types::CreditCard qw(
			CardNumber
			CardSecurityCode
			CardExpiration
		);

		has credit_card => (
			isa    => CardNumber,
			is     => 'ro',
			coerce => 1,
		);

		has cvv2 => (
			isa => CardSecurityCode,
			is  => 'ro',
		);

		has expiration => (
			isa    => CardExpiration,
			is     => 'ro',
			coerce => 1,
		);

		__PACKAGE__->meta->make_immutable;
	}

	my $obj = My::CreditCard->new({
		credit_card => '4111111111111111',
		cvv2        => '123',
		expiration  => { month => 10, year => 2013 },
	});

=head1 DESCRIPTION

This module provides types related to Credit Cards for weak validation.

=head1 TYPES

=head2 CardNumber

B<Base Type:> C<Str>

It will validate that the number passed to it appears to be a
valid credit card number. Please note that this does not mean that the
Credit Card is actually valid, only that it appears to be by algorithms
defined in L<Business::CreditCard>.

Enabling coerce will strip out any non C<0-9> characters from a string
allowing for numbers like "4111-1111-1111-1111" to be passed.

=head2 CardSecurityCode

B<Base Type:> C<Str>

A Credit L<Card Security Code|http://wikipedia.org/wiki/Card_security_code> is
a 3 or 4 digit number. This is also called CSC, CVV, CVC, and CID, depending
on the issuing vendor.

=head2 head2 CardExpiration

B<Base Type:> C<DateTime>

A Credit Card Expiration Date. It's a L<DateTime> Object and checks to see if
the object is equal to the last day of the month, using the month and year
stored in the object.

Coerce allows you to create the L<DateTime> object from a C<HashRef> by passing
the keys C<month> and C<year>.

=head1 ACKNOWLEDGEMENTS

=over

=item * L<hostgator.com>

For funding initial development

=back

=head1 SEE ALSO

=over

=item * L<Business::CreditCard>

=item * L<DateTime>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/moosex-types-creditcard/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
