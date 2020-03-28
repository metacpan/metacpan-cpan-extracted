##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Hash.pm
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
## Generic package to contain discretionary hash data
package Net::API::Stripe::Hash;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub init
{
	my $self = shift( @_ );
	my $init = shift( @_ );
	$self->SUPER::init( $init );
	my $ref = shift( @_ );
	foreach my $k ( keys( %$ref ) )
	{
		$self->message( 3, "Set field $k with value '", $ref->{ $k }, "'" );
		$self->{ $k } = $ref->{ $k };
	}
	return( $self );
}

## No other method defined because available methods depends on the hash keys

1;

__END__
