##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Connect/Account/ExternalAccounts.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Connect::Account::ExternalAccounts;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::List );
    our( $VERSION ) = '0.1';
};

# Inhertied
# sub object { shift->_set_get_scalar( 'object', @_ ); }

## The list contains all external accounts that have been attached to the Stripe account. These may be bank accounts or cards.
## sub data { shift->_set_get_array( 'data', @_ ); }
sub data
{
	my $self = shift( @_ );
	if( @_ )
	{
		local $process = sub
		{
			my $ref = shift( @_ );
			my $type = $ref->{object} || return( $self->error( "No object type could be found in hash: ", sub{ $self->_dumper( $ref ) } ) );
			my $class = $self->_object_type_to_class( $type );
			$self->_message( 3, "Object type $type has class $class" );
			my $o = $self->_instantiate_object( 'data', $class, $ref );
			$self->{data} = $o;
			## return( $class->new( %$ref ) );
			## return( $self->_set_get_object( 'object', $class, $ref ) );
		};
		
		if( ref( $_[0] ) eq 'HASH' )
		{
			my $o = $process->( @_ ) 
		}
		## An array of objects hash
		elsif( ref( $_[0] ) eq 'ARRAY' )
		{
			my $arr = shift( @_ );
			my $res = [];
			foreach my $data ( @$arr )
			{
				my $o = $process->( $data ) || return( $self->error( "Unable to create object: ", $self->error ) );
				push( @$res, $o );
			}
			$self->{data} = $res;
		}
	}
	return( $self->{data} );
}

# Inhertied
# sub has_more { shift->_set_get_scalar( 'has_more', @_ ); }

# Inhertied
# sub total_count { shift->_set_get_scalar( 'total_count', @_ ); }

# Inhertied
# sub url { shift->_set_get_uri( 'url', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Connect::Account::ExternalAccounts - A Stripe External Accounts List Object

=head1 VERSION

    0.1

=head1 DESCRIPTION

This module inherits everything from L<Net::API::Stripe::List> module and overrides only the B<data> method

This is instantiated from method B<external_accounts> in module L<Net::API::Stripe::Connect::Account>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
