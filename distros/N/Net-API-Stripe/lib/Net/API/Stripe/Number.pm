##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Number.pm
## Version 0.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Number;
BEGIN
{
    use strict;
    use parent qw( Module::Generic );
    use Number::Format;
    our( $VERSION ) = '0.1';
};

use overload (
	'""' => sub 
	{
		my $self = shift( @_ );
		return( $self->{_number} );
	},
	'-' => sub
	{
		my( $self, $other, $swap ) = @_;
		my $result = $self->{_number} - $other;
		$result = -$result if( $swap );
		return( $result );
	},
	'+' => sub
	{
		my( $self, $other, $swap ) = @_;
		my $result = $self->{_number} + $other;
		return( $result );
	},
	'*' => sub
	{
		my( $self, $other, $swap ) = @_;
		my $result = $self->{_number} * $other;
		return( $result );
	},
	'/' => sub
	{
		my( $self, $other, $swap ) = @_;
		if( $swap )
		{
			return( $other / $self->{_number} );
		}
		else
		{
			return( $self->{_number} / $other );
		}
	},
	'<' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $swap ? $other < $self->{_number} : $self->{_number} < $other );
	},
	'<=' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $swap ? $other <= $self->{_number} : $self->{_number} <= $other );
	},
	'>' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $swap ? $other > $self->{_number} : $self->{_number} > $other );
	},
	'>=' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $swap ? $other >= $self->{_number} : $self->{_number} >= $other );
	},
	'<=>' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $swap ? $other <=> $self->{_number} : $self->{_number} <=> $other );
	},
	'==' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $self->{_number} == $other );
	},
	'!=' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $self->{_number} == $other );
	},
	'eq' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $self->{_number} eq $other );
	},
	'ne' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $self->{_number} ne $other );
	}
);

sub init
{
	my $self = shift( @_ );
	my $num  = shift( @_ );
	$self->SUPER::init( @_ );
	$self->{_fmt} = Number::Format->new(
		-thousands_sep => ',',
		-decimal_point => '.',
		-int_curr_symbol => '¥',
	);
	$self->{_number} = $num;
	return( $self );
}

sub as_string { return( shift->{_number} ) }

sub format
{
	my $self = shift( @_ );
	no overloading;
	my $num  = $self->{_number};
	## If value provided was undefined, we leave it undefined, otherwise we would be at risk of returning 0, and 0 is very different from undefined
	return( $num ) if( !defined( $num ) );
	my $fmt  = $self->{_fmt};
	return( $fmt->format_number( $num, @_ ) );
}

sub format_money
{
	my $self = shift( @_ );
	no overloading;
	my $num  = $self->{_number};
	## See comment in format() method
	return( $num ) if( !defined( $num ) );
	my $fmt  = $self->{_fmt};
	return( $fmt->format_price( $num, @_ ) );
}

AUTOLOAD
{
	my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
	my $self = shift( @_ ) || return;
	my $fmt_obj = $self->{_fmt} || return;
	my $code = $fmt_obj->can( $method );
	return( $code->( $fmt_obj, @_ ) ) if( $code );
	return;
};

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Number - A Number Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

This is a convenient wrapper around C<Number::Format> object. It does not inherit, but still you can use all of the C<Number::Format> method directly from here thanks to AUTOLOAD.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new C<Net::API::Stripe> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<verbose>

Toggles verbose mode on/off

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item B<as_string>

This returns the original number

=item B<format>

This calls C<Number::Format::format_number> method passing it the original number and any extra arguments.

For details of what arguments to provide, check the C<Number::Format> documentation.

=item B<format_money>

This calls C<Number::Format::format_price> method passing it the original number and any extra arguments.

For details of what arguments to provide, check the C<Number::Format> documentation.

=back

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

C<Number::Format>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
