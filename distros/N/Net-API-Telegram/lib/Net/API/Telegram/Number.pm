# -*- perl -*-
##----------------------------------------------------------------------------
## Telegram API - ~/lib/Net/API/Telegram/Number.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/06/02
## Modified 2019/06/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::Number;
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
		return( $self->{ '_number' } );
	},
	'-' => sub
	{
		my( $self, $other, $swap ) = @_;
		my $result = $self->{ '_number' } - $other;
		$result = -$result if( $swap );
		return( $result );
	},
	'+' => sub
	{
		my( $self, $other, $swap ) = @_;
		my $result = $self->{ '_number' } + $other;
		return( $result );
	},
	'*' => sub
	{
		my( $self, $other, $swap ) = @_;
		my $result = $self->{ '_number' } * $other;
		return( $result );
	},
	'/' => sub
	{
		my( $self, $other, $swap ) = @_;
		if( $swap )
		{
			return( $other / $self->{ '_number' } );
		}
		else
		{
			return( $self->{ '_number' } / $other );
		}
	},
	'<' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $swap ? $other < $self->{ '_number' } : $self->{ '_number' } < $other );
	},
	'<=' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $swap ? $other <= $self->{ '_number' } : $self->{ '_number' } <= $other );
	},
	'>' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $swap ? $other > $self->{ '_number' } : $self->{ '_number' } > $other );
	},
	'>=' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $swap ? $other >= $self->{ '_number' } : $self->{ '_number' } >= $other );
	},
	'<=>' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $swap ? $other <=> $self->{ '_number' } : $self->{ '_number' } <=> $other );
	},
	'==' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $self->{ '_number' } == $other );
	},
	'!=' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $self->{ '_number' } == $other );
	},
	'eq' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $self->{ '_number' } eq $other );
	},
	'ne' => sub
	{
		my( $self, $other, $swap ) = @_;
		return( $self->{ '_number' } ne $other );
	}
);

sub init
{
	my $self = shift( @_ );
	my $num  = shift( @_ );
	$self->SUPER::init;
	$self->{ '_fmt' } = Number::Format->new(
		-thousands_sep => ',',
		-decimal_point => '.',
		-int_curr_symbol => '¥',
	);
	$self->{ '_number' } = $num;
	return( $self );
}

sub as_string { return( shift->{ '_number' } ) }

sub format
{
	my $self = shift( @_ );
	no overloading;
	my $num  = $self->{ '_number' };
	## If value provided was undefined, we leave it undefined, otherwise we would be at risk of returning 0, and 0 is very different from undefined
	return( $num ) if( !defined( $num ) );
	my $fmt  = $self->{ '_fmt' };
	return( $fmt->format_number( $num, @_ ) );
}

sub format_money
{
	my $self = shift( @_ );
	no overloading;
	my $num  = $self->{ '_number' };
	## See comment in format() method
	return( $num ) if( !defined( $num ) );
	my $fmt  = $self->{ '_fmt' };
	return( $fmt->format_price( $num, @_ ) );
}

1;

__END__

