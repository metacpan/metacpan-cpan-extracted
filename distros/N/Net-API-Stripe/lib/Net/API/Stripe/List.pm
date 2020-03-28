##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/List.pm
## Version 0.2
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/02/16
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::List;
## To be inherited
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
	# use B;
	# use B::Deparse;
    our( $VERSION ) = '0.2';
};

sub object { CORE::shift->_set_get_scalar( 'object', @_ ); }

sub count { return( CORE::shift->_set_get_scalar( 'total_count', @_ ) ); }

sub data { return( shift->_data( @_ ) ); }

sub has_more { CORE::shift->_set_get_boolean( 'has_more', @_ ); }

sub url { CORE::shift->_set_get_uri( 'url', @_ ); }

## sub total_count { CORE::shift->_set_get_scalar( 'total_count', @_ ); }
sub total_count
{
	my $self = shift( @_ );
	if( @_ )
	{
		$self->_set_get_scalar( 'total_count', @_ );
	}
	my $total = $self->_set_get_scalar( 'total_count' );
	# my( $p, $f, $l ) = caller;
	# my $sub = ( caller( 1 ) )[3];
	# $self->message( 3, "Called from package $p in file $f at line $l from sub $sub." );
	if( !CORE::length( $total ) )
	{
		# my $code_ref = $self->can( 'data' );
		# my $meta = B::svref_2object( $code_ref );
		# my $deparse = B::Deparse->new( '-p', '-sC' );
		# my $meth_body = $deparse->coderef2text( $code_ref );
		# $self->message( 3, "Log handler code routine name is " . $meta->GV->NAME . " called in file " . $meta->GV->FILE . " at line " . $meta->GV->LINE, " with code: ", $meth_body );
		# $self->message( 3, "Data is '", $self->data(), "' and data value is '", $self->{data}, "'." );
		return( $self->_data->size );
	}
	else
	{
		return( $total );
	}
}

## Additional methods for navigation to be used like $list->next or $list->prev
sub get
{
	my $self = CORE::shift( @_ );
	my $pos  = @_ ? int( CORE::shift( @_ ) ) : ( $self->{ '_pos' } || 0 );
	my $data = $self->_data;
	return( $data->[ $pos ] );
}

sub length
{
	my $self = CORE::shift( @_ );
	my $data = $self->_data;
	return( scalar( @$data ) );
}

sub next
{
	my $self = CORE::shift( @_ );
	$self->{ '_pos' } = -1 if( !exists( $self->{ '_pos' } ) );
	my $data = $self->_data;
	$self->message( 3, "Is there more data? ", $self->has_more ? 'yes' : 'no' );
	if( $self->{ '_pos' } + 1 < scalar( @$data ) )
	{
		return( $data->[ ++$self->{ '_pos' } ] );
	}
	elsif( $self->has_more && scalar( @$data ) && $self->_is_object( $data->[-1] ) )
	{
		my $last_id = $data->[-1]->id;
		$self->{_limit} = scalar( @$data ) if( !$self->{_limit} );
		$self->messagef( 3, "Fetching more starting from last id $last_id with _limit value %d", $self->{_limit} );
		my $opts =
		{
		starting_after => $last_id,
		limit => ( $self->{_limit} || 10 ),
		};
		my $hash = $self->parent->get( $self->url, $opts ) || return;
# 		return( $self->error( "Cannot find the data property in the hash returned from the follow-on query to Stripe." ) ) if( !CORE::exists( $hash->{data} ) );
# 		return( $self->error( "Data property is not an array reference." ) ) if( ref( $hash->{data} ) ne 'ARRAY' );
# 		return( '' ) if( !scalar( @{$hash->{data}} ) );
# 		return( $self->error( "I was expecting an array of hash reference, but instead I got: ", sub{ $self->dumper( $hahs->{data} ) } ) ) if( ref( $hash->{data}->[0] ) ne 'HASH' );
		return( $self->error( "Cannot find property 'object' in this hash reference: ", sub{ $self->dumper( $hash ) } ) ) if( !CORE::exists( $hash->{object} ) );
		my $class = $self->_object_type_to_class( $hash->{object} ) || return;
		my $list = $self->parent->_response_to_object( $class, $hash ) || return;
		$data = $list->_data;
		## $self->{data} = $data;
		$self->_data( $data );
		$self->{_pos} = 0;
		return( '' ) if( !scalar( @$data ) );
		return( $data->[ $self->{_pos} ] );
	}
	else
	{
		## We do not return undef(), which we use to signal errors
		return( '' );
	}
}

sub prev
{
	my $self = CORE::shift( @_ );
	$self->{ '_pos' } = -1 if( !exists( $self->{ '_pos' } ) );
	my $data = $self->_data;
	my $ret = $data->[ $pos ];
	if( $self->{ '_pos' } - 1 >= 0 )
	{
		return( $data->[ --$self->{ '_pos' } ] );
	}
	elsif( scalar( @$data ) && $self->_is_object( $data->[0] ) )
	{
		my $first_id = $data->[0]->id;
		$self->{_limit} = scalar( @$data ) if( !$self->{_limit} );
		$self->messagef( 3, "Fetching previous set of data starting from first id $first_id with _limit value %d", $self->{_limit} );
		my $opts =
		{
		ending_before => $first_id,
		limit => ( $self->{_limit} || 10 ),
		};
		my $hash = $self->parent->get( $self->url, $opts ) || return;
		return( $self->error( "Cannot find property 'object' in this hash reference: ", sub{ $self->dumper( $hash ) } ) ) if( !CORE::exists( $hash->{object} ) );
		my $class = $self->_object_type_to_class( $hash->{object} ) || return;
		my $list = $self->parent->_response_to_object( $class, $hash ) || return;
		$data = $list->_data;
		## $self->{data} = $data;
		$self->_data( $data );
		$self->{_pos} = $#$data;
		return( '' ) if( !scalar( @$data ) );
		return( $data->[ $self->{_pos} ] );
	}
	else
	{
		## We do not return undef(), which we use to signal errors
		return( '' );
	}
}

sub pop
{
	my $self = CORE::shift( @_ );
	return( $self->_data->pop );
}

sub push
{
	my $self = CORE::shift( @_ );
	my $this = CORE::shift( @_ ) || return( $self->error( "Nothing was provided to add to the list of object." ) );
	$self->_check( $this ) || return;
	$self->_data->push( $this );
	return( $self );
}

sub shift
{
	my $self = CORE::shift( @_ );
	return( $self->_data->shift );
}

sub unshift
{
	my $self = CORE::shift( @_ );
	my $this = CORE::shift( @_ ) || return( $self->error( "Nothing was provided to add to the list of object." ) );
	$self->_check( $this ) || return;
	$self->_data->unshift( $this );
	return( $self );
}

sub _check
{
	my $self = CORE::shift( @_ );
	my $this = CORE::shift( @_ ) || return( $self->error( "No data was provided to check." ) );
	return( $self->error( "Data provided is not an object." ) ) if( !$self->_is_object( $this ) );
	## Check if there is any data and if there is find out what kind of object we are holding so we can maintain consistency
	my $data = $self->_data;
	my $obj_name;
	if( scalar( @$data ) && $self->_is_object( $data->[0] ) )
	{
		$obj_name = $data->[0]->object if( $data->[0]->can( 'object' ) );
	}
	if( $this->can( 'object' ) )
	{
		return( $self->error( "Object provided ($this) has an object type (", $this->object, ") different from the ones currently in our stack ($obj_name)." ) ) if( $this->object ne $obj_name );
	}
	return( $this );
}

sub _data
{
	my $self = CORE::shift( @_ );
	# my $field = shift( @_ );
	# my( $pack, $file, $line ) = caller;
	# require Devel::StackTrace;
	# my $trace = Devel::StackTrace->new;
	# $self->message( 3, "data called from package $pack in file $file at line $line with arguments: '", join( "', '", @_ ), "'." );
	## $self->message( 3, "data called with arguments: '", join( "', '", @_ ), "'. Stack trace: ", $trace->as_string );
	my $field = 'data';
	if( @_ )
	{
		my $ref = CORE::shift( @_ );
		# $self->message( 3, "Received '$ref' (", ref( $ref ), ")." );
    	return( $self->error( "I was expecting an array ref, but instead got '$ref'" ) ) if( !$self->_is_array( $ref ) );
    	my $arr = [];
    	# $self->messagef( 3, "Array of %d items provided.", scalar( @$ref ) );
    	if( scalar( @$ref ) )
    	{
    		return( $self->error( "I was expecting an array of hash reference, but instead of hash I found $ref->[0]" ) ) if( ref( $ref->[0] ) ne 'HASH' );
    		return( $self->error( "Found an hash reference in this array, but it is empty: ", sub{ $self->dumper( $ref ) } ) ) if( !scalar( keys( %{$ref->[0]} ) ) );
			my $type = $ref->[0]->{object} || return( $self->error( "I was expecting a string in property 'object', but found nothing: ", sub{ $self->dumper( $ref ) } ) );
			my $class = $self->_object_type_to_class( $type ) || return( $self->error( "Could not find corresponding class for ojbect type \"$type\"." ) );
			$arr = $self->_set_get_object_array_object( $field, $class, $ref );
			# $self->messagef( 3, "_set_get_object_array returned %d items ($arr).", scalar( @$arr ) );
			## Store this value used by next() and prev() to replicate the query with the right limit
			## If initial query made by the user was 10 this array would be 10 or less if there is no more data
    	}
    	#else
    	#{
    	#	$self->message( 3, "Array $ref is empty." );
    	#}
    	$self->{ $field } = $arr;
	}
	if( !$self->{ $field } || !$self->_is_object( $self->{ $field } ) )
	{
		# $self->message( 3, "Currently value for field '$field' is \"", $self->{ $field }, "\", which is either empty or not an object." );
        my $o = Module::Generic::Array->new( $self->{ $field } );
		$self->{ $field } = $o;
		# $self->message( 3, "Value for field \"$field\" is now: \"", $self->{ $field }, "\"." );
	}
	# my( $p, $f, $l ) = caller;
	# my $sub = ( caller( 1 ) )[3];
	# $self->message( 3, "Called from package $p in file $f at line $l from sub $sub and returning ", $self->{ $field } );
	return( $self->{ $field } );
}

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::List - Stripe List Object

=head1 SYNOPSIS

=head1 VERSION

    0.2

=head1 DESCRIPTION

This is a package with a set of useful methods to be inherited by various Stripe package, such as bellow packages. It can also be used directly in a generic way and this will find out which list of objects this is. This is the case for example when getting the list of customer tax ids in B<Net::API::Stripe::tax_id_list>().

=over 4

=item C<Net::API::Stripe::Billing::Invoice::Lines>

=item C<Net::API::Stripe::Billing::Subscription::Items>

=item C<Net::API::Stripe::Charge::Refunds>

=item C<Net::API::Stripe::Connect::Account::ExternalAccounts>

=item C<Net::API::Stripe::Connect::ApplicationFee::Refunds>

=item C<Net::API::Stripe::Connect::Transfer::Reversals>

=item C<Net::API::Stripe::Customer::Sources>

=item C<Net::API::Stripe::Customer::Subscription>

=item C<Net::API::Stripe::Customer::TaxIds>

=item C<Net::API::Stripe::File::Links>

=item C<Net::API::Stripe::Order::Return>

=item C<Net::API::Stripe::Payment::Intent::Charges>

=item C<Net::API::Stripe::Sigma::ScheduledQueryRun::File::Links>

=back

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

=item B<object> string

This is the string identifier of the type of data. Usually it is "list"

=item B<data> array

This is an array of data, usually objects, but it could vary, which is why this method should be overriden by package inheriting from this one.

=item B<has_more> boolean

This is a boolean value to indicate whether the data is buffered

=item B<url> URI

This is uri to be used to access the next or previous set of data

=item B<total_count> integer

Total size of the array i.e. number of elements

=item B<get> offset

Retrieves the data at the offset specified

=item B<length> integer

The size of the array

=item B<next>

Moves to the next entry in the array

=item B<prev>

Moves to the previous entry in the array

=back

=head1 API SAMPLE

	{
	  "object": "list",
	  "url": "/v1/refunds",
	  "has_more": false,
	  "data": [
		{
		  "id": "re_1DQFAzCeyNCl6fY2Ntw9eath",
		  "object": "refund",
		  "amount": 30200,
		  "balance_transaction": "txn_1DQFAzCeyNCl6fY2VBP8MxtZ",
		  "charge": "ch_1DQFAHCeyNCl6fY2ugNKel6w",
		  "created": 1540736617,
		  "currency": "jpy",
		  "metadata": {},
		  "reason": null,
		  "receipt_number": null,
		  "source_transfer_reversal": null,
		  "status": "succeeded",
		  "transfer_reversal": null
		},
		{...},
		{...}
	  ]
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
