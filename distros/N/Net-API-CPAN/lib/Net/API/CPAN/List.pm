##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/List.pm
## Version v0.1.1
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/08/02
## Modified 2023/09/26
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::CPAN::List;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::CPAN::Generic );
    use vars qw( $VERSION );
    use Clone ();
    use HTTP::Promise;
    use Wanted;
    use constant {
        # Elastic Search default value.
        # See <https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-from-size.html>
        DEFAULT_PAGE_SIZE => 10,
    };
    our $VERSION = 'v0.1.1';
};

use strict;
use warnings;

sub init
{
    my $self = CORE::shift( @_ );
    $self->{api}            = undef unless( CORE::exists( $self->{api} ) );
    # The name of the JSON property containing the array reference of data
    # This is used for data in format other than search results such as hits->hits
    $self->{container}      = undef unless( CORE::exists( $self->{container} ) );
    # The full URI to the endpoint used for loading data
    # $self->{endpoint}       = undef unless( CORE::exists( $self->{endpoint} ) );
    $self->{filter}         = undef unless( CORE::exists( $self->{filter} ) );
    # Is this list a list that can load more data or is this set of data the only one available?
    $self->{pageable}       = 1 unless( CORE::exists( $self->{pageable} ) );
    $self->{page}           = 1 unless( CORE::exists( $self->{page} ) );
    # Either 'from' or 'page' is used to navigate through pages of data
    $self->{page_type}      = 'from' unless( CORE::exists( $self->{page_type} ) );
    $self->{postprocess}    = sub{$_[0]} unless( CORE::exists( $self->{postprocess} ) );
    # $self->{preprocess}     = sub{$_[0]} unless( CORE::exists( $self->{preprocess} ) );
    $self->{preprocess}     = undef unless( CORE::exists( $self->{preprocess} ) );
    $self->{request}        = undef unless( CORE::exists( $self->{request} ) );
    # We use this if we are not using filters
    $self->{size}           = undef unless( CORE::exists( $self->{size} ) );
    # Usually this is 'size', but sometimes it is 'page_size'
    $self->{size_prop}      = 'size' unless( CORE::exists( $self->{size_prop} ) );
    $self->{timed_out}      = 0 unless( CORE::exists( $self->{timed_out} ) );
    $self->{took}           = undef unless( CORE::exists( $self->{took} ) );
    $self->{total}          = undef unless( CORE::exists( $self->{total} ) );
    $self->{type}           = undef unless( CORE::exists( $self->{type} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_init_params_order} = [qw( debug type api container preprocess postprocess total data )];
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    unless( CORE::exists( $self->{api} ) && $self->_is_a( $self->{api} => 'Net::API::CPAN' ) )
    {
        $self->_load_class( 'Net::API::CPAN' ) || return( $self->pass_error );
        $self->{api} = Net::API::CPAN->new( debug => $self->debug ) || 
            return( $self->pass_error( Net::API::CPAN->error ) );
    }
    # Simple initialisation
    $self->{_raw_items} = $self->new_array;
    return( $self );
}

sub api { return( CORE::shift->_set_get_object( 'api', 'Net::API::CPAN', @_ ) ); }

sub container { return( CORE::shift->_set_get_scalar( 'container', @_ ) ); }

sub data
{
    my $self = CORE::shift( @_ );
    if( @_ )
    {
        $self->load_data( @_ ) || return( $self->pass_error );
    }
    return( $self->items );
}

# sub endpoint { return( CORE::shift->_set_get_uri( 'endpoint', @_ ) ); }

sub filter { return( CORE::shift->_set_get_object_without_init( 'filter', 'Net::API::CPAN::Filter', @_ ) ); }

sub get
{
    my $self = CORE::shift( @_ );
    my $pos  = @_ ? int( CORE::shift( @_ ) ) : ( $self->{_pos} || 0 );
    my $data = $self->items;
    my $what = lc( Wanted::wantref );
    if( !defined( $data->[ $pos ] ) )
    {
        if( $what eq 'object' || $what eq 'hash' )
        {
            return( $self->new_null( type => $what ) );
        }
        return;
    }
    return( $data->[ $pos ] );
}

sub has_more
{
    my $self = CORE::shift( @_ );
    my $total = $self->total // 0;
    my( $filter, $size );
    if( $filter = $self->filter )
    {
        $size = $filter->size;
    }
    # This is the default Elastic Search value
    $size //= $self->size // DEFAULT_PAGE_SIZE;
    my $offset = $self->offset // 0;
    $self->message( 4, "\$total = $total, \$offset = $offset, \$size = $size" );
    $self->message( 4, "Returning true. There is more." ) if( $total && $total > $size && ( $total - ( $offset + 1 ) > 0 ) );
    # Do we have data and is it bigger than the page size and we are not on the last page
    return(1) if( $total && $total > $size && ( $total - ( $offset + 1 ) > 0 ) );
    $self->message( 4, "Returning false. There is no more data to fetch." );
    return(0);
}

sub items
{
    my $self = CORE::shift( @_ );
    @_ = () if( @_ == 1 && !defined( $_[0] ) );
    if( @_ )
    {
        my $ref = CORE::shift( @_ );
        my $opts = $self->_get_args_as_hash( @_ );
        return( $self->error( "I was expecting an array reference, but instead got '", overload::StrVal( $ref ), "'." ) ) if( !$self->_is_array( $ref ) );
        my $cache = {};
        my $api = $self->api;
        my $arr = $self->new_array;
        my $def_type = $self->type->scalar;
        $self->message( 4, "Processing ", scalar( @$ref ), " elements with type '$def_type'" );
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            return( $self->error( "I was expecting an array of hash reference, but instead of an hash I found '", overload::StrVal( $ref->[$i] ), "'" ) ) if( ref( $ref->[$i] ) ne 'HASH' );
            my $hash = $ref->[$i];
            my $type = $opts->{type} || $hash->{_type} || $def_type ||
                return( $self->error( "No object type was specified nor any could be found in the hash reference at offset $i" ) );
            my $class;
            unless( $class = $cache->{ $type } )
            {
                $class = $self->_object_type_to_class( $type ) || return( $self->error( "Could not find corresponding class for ojbect type \"$type\"." ) );
                $self->message( 4, "Loading class $class (", overload::StrVal( $class ), ") for object type $type" );
                $self->_load_class( $class ) || return( $self->pass_error );
                $cache->{ $type } = $class;
                # XXX
#                 if( $class eq 'Net::API::CPAN::List::Web::Element' )
#                 {
#                     my @symbols = $self->_list_symbols( 'Net::API::CPAN::List::Web::Element' );
#                     $self->message( 4, "Symbols found for class Net::API::CPAN::List::Web::Element are -> ", sub{ $self->Module::Generic::dump( \@symbols ) } );
#                 }
            }
            $hash = $hash->{_source} if( exists( $hash->{_source} ) && ref( $hash->{_source} ) eq 'HASH' );
            # $self->message( 4, "Instantiating a $class object at offset $i for object type $type with data: ", sub{ $self->Module::Generic::dump( $hash ) } );
            $hash->{debug} = $self->debug;
            my $o = $class->new( %$hash, api => $api ) || return( $self->pass_error( $class->error ) );
            $self->message( 4, "Adding new $class object $o (", overload::StrVal( $o ), ") to the stack." );
            $arr->push( $o );
        }
        $self->{items} = $arr;
    }
    if( !$self->{items} || !$self->_is_a( $self->{items} => 'Module::Generic::Array' ) )
    {
        $self->{items} = $self->new_array( defined( $self->{items} ) ? $self->{items} : [] );
    }
    return( $self->{items} );
}

sub length { return( CORE::shift->items->length ); }

sub load
{
    my $self = CORE::shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $req = $opts->{request} ||
        return( $self->error( "No HTTP request was provided to load data." ) );
    my $api = $self->api ||
        return( $self->error( "No Net::API::CPAN obejct is currently set. This should not happen." ) );
    my $type = $self->type ||
        return( $self->error( "No object type set for this list." ) );
    my $filter = $self->filter;
    if( $filter )
    {
        return( $self->error( "No search query set." ) ) if( !$filter->query );
        my $json = $filter->as_json ||
            return( $self->pass_error( $filter->error ) );
        $req->method( 'POST' );
    }
    else
    {
        $req->method( 'GET' );
    }
    $req->headers->header( Accept => 'application/json' );
    my $data = $api->fetch( $type => {
        request => $req,
        # We simply want the raw data back
        class => sub{ $_[0] },
    }) || return( $self->pass_error( $api->error ) );
    
    $self->load_data( $data ) || return( $self->pass_error );    
    return( $self );
}

sub load_data
{
    my $self = CORE::shift( @_ );
    my $data = CORE::shift( @_ ) ||
        return( $self->error( "No data was provided to load." ) );
    return( $self->error( "Data provided is not an hash reference." ) ) if( ref( $data ) ne 'HASH' );
    $self->message( 4, "Loading data received with ", scalar( keys( %$data ) ), " properties: ", join( ', ', sort( keys( %$data ) ) ) );
    my $filter = $self->filter;
    my $container = $self->container;
    $self->message( 4, "Container to use is '", ( $container // 'undef', ), "'" );

    if( my $code = $self->preprocess )
    {
        $self->message( 4, "Executing preprocess." );
        # try-catch
        local $@;
        $data = eval
        {
            $code->( $data );
        };
        if( $@ )
        {
            return( $self->error( $@ ) );
        }
        # $self->message( 5, "After preprocess, data now is: ", sub{ $self->Module::Generic::dump( $data ) } );
    }

    # $ref is the variable containing the array reference of data
    my( $ref, $total );
    if( ( $container && 
          $container eq 'hits' && 
          exists( $data->{ $container } ) && 
          ref( $data->{ $container } ) eq 'HASH' && 
          exists( $data->{ $container }->{hits} ) && 
          ref( $data->{ $container }->{hits} ) eq 'ARRAY'
        ) ||
        ( !defined( $container ) && 
          exists( $data->{hits} ) && 
          ref( $data->{hits} ) eq 'HASH' && 
          exists( $data->{hits}->{hits} ) && 
          ref( $data->{hits}->{hits} ) eq 'ARRAY'
        ) )
    {
        $self->message( 4, "Guessed container to be 'hits->hits'" );
        unless( defined( $container ) )
        {
            $self->container( $container = 'hits' );
        }
        if( !exists( $data->{hits} ) ||
            !defined( $data->{hits} ) ||
            ref( $data->{hits} ) ne 'HASH' )
        {
            # return( $self->error( "Malformed data received. I was expecting a top property 'hits' to be an hash reference." ) );
            # Actually not necessarily an error, but simply no more data
            $self->items->reset;
        }
        elsif( !exists( $data->{hits}->{hits} ) ||
            !defined( $data->{hits}->{hits} ) ||
            ref( $data->{hits}->{hits} ) ne 'ARRAY' )
        {
            # return( $self->error( "Malformed data received. I was expecting the property 'hits' within the top property 'hits' to be an array reference." ) );
            # Actually not necessarily an error, but simply no more data
            $self->items->reset;
        }
        else
        {
            $ref = $data->{hits}->{hits};
            # The overall number of hits
            if( exists( $data->{hits}->{total} ) &&
                defined( $data->{hits}->{total} ) &&
                CORE::length( $data->{hits}->{total} ) )
            {
                $self->message( 4, "Setting total value using hits->total (", $data->{hits}->{total}, ")" );
                # $self->total( $data->{hits}->{total} );
                $total = $data->{hits}->{total};
            }
            # If the information is not available somehow, use the size of the array
            else
            {
                $self->message( 4, "Setting total value using items->length (", $self->items->length, ")" );
                # $self->total( $self->items->length );
                $total = $self->items->length;
            }
        }
    }
    else
    {
        $self->message( 4, "Container is not hits->hits, trying to find the first property with an array." );
        unless( $container = $self->container )
        {
            foreach my $prop ( keys( %$data ) )
            {
                if( defined( $data->{ $prop } ) &&
                    ref( $data->{ $prop } ) eq 'ARRAY' )
                {
                    $container = $prop;
                    $self->message( 4, "Found the container being the property '$prop'" );
                    # Save it for next time
                    $self->container( $container );
                    last;
                }
            }
        }
        
        if( !defined( $container ) )
        {
            return( $self->error( "No data container name was specified and none could be found in the data provided." ) );
        }
        elsif( !exists( $data->{ $container } ) )
        {
            return( $self->error( "Data container specified '$container' does not exist in the data provided." ) );
        }
        # There is simply no data. Admittedly it would be better if it was defined and an empty array
        elsif( !defined( $data->{ $container } ) )
        {
            $ref = [];
        }
        elsif( ref( $data->{ $container } ) ne 'ARRAY' )
        {
            return( $self->error( "Data container specified '$container' does not point to an array reference, but to a '", ( ref( $data->{ $container } ) // 'string' ), "'." ) );
        }
        else
        {
            $ref = $data->{ $container };
        }
        
        # Like for some release data, such as /all_by_author
        $total = $data->{total} if( exists( $data->{total} ) && CORE::length( $data->{total} // '' ) );
    }

    if( defined( $ref ) )
    {
        $self->message( 4, "Container contains ", scalar( @$ref ), " ", $self->type, " elements." );
        # We take steps to ensure the data we received is not the same as the data we already have
        my $new_items = $self->new_array( $ref );
        my $old_items = $self->{_raw_items} // $self->new_array;
        $self->message( 5, "Old items are -> ", sub{ $self->Module::Generic::dump( $old_items ) } );
        # Set the size of the number of elements per page, so we can rely on it, even if the array is modified afterwards
#         unless( defined( $filter->size ) )
#         {
#             $filter->size( $new_items->length );
#         }
        # Set the value for 'type' for our object if it was not set already by the user.
        # It should already have been set if there was an API call, but not necessarily if the data were simply and directly loaded here.
        if( !$self->type && 
            scalar( @$new_items ) && 
            ref( $new_items->[0] ) eq 'HASH' &&
            exists( $new_items->[0]->{_type} ) &&
            CORE::length( $new_items->[0]->{_type} // '' ) )
        {
            $self->type( $new_items->[0]->{_type} );
        }
        
        if( !$new_items->is_empty && 
            !$old_items->is_empty &&
            ref( $new_items->first ) eq 'HASH' &&
            ref( $old_items->first ) eq 'HASH' )
        {
            my $json = $self->new_json->canonical;
            my $new_first = $new_items->first;
            my $old_first = $old_items->first;
            my( $new_serial, $old_serial );
            local $@;
            # try-catch
            eval
            {
                $new_serial = $json->encode( $new_first );
                $old_serial = $json->encode( $old_first );
            };
            if( $@ )
            {
                return( $self->error( "Error serialising hash reference into JSON data: $@" ) );
            }

            # old and new data are the same. We cannot have that, 
            # so we set an empty data pool
            if( defined( $new_serial ) &&
                defined( $old_serial ) && 
                $new_serial eq $old_serial )
            {
                $self->items->reset;
            }
            else
            {
                $self->items( $ref );
                $self->{_raw_items} = $self->new_array( Clone::clone( $ref ) );
            }
        }
        # Ok, old and new data are not the same
        else
        {
            $self->items( $ref );
            $self->{_raw_items} = $self->new_array( Clone::clone( $ref ) );
        }
        
        # If the information is not available somehow, use the size of the array
        $self->total( $total // $self->items->length );
        # If it was already set the first time, we do not overwrite it.
        # This is used so we can compute next page offset
        unless( $self->page_size )
        {
            $self->page_size( $self->items->length );
        }
    }
    else
    {
        return( $self->error( "No data found for container '$container'" ) );
    }
    
    if( exists( $data->{timed_out} ) &&
        defined( $data->{timed_out} ) &&
        CORE::length( $data->{timed_out} ) )
    {
        $self->timed_out( $data->{timed_out} );
    }
    else
    {
        $self->timed_out(0);
    }
    
    if( exists( $data->{took} ) &&
        defined( $data->{took} ) &&
        CORE::length( $data->{took} ) )
    {
        $self->took( $data->{took} );
    }
    else
    {
        $self->took(undef);
    }
    # Reset the array position
    delete( $self->{_pos} );
    
    if( my $code = $self->postprocess )
    {
        $self->message( 4, "Executing postprocess." );
        # try-catch
        local $@;
        eval
        {
            $code->( $data );
        };
        if( $@ )
        {
            return( $self->error( $@ ) );
        }
    }
    return( $self );
}

sub next
{
    my $self = CORE::shift( @_ );
    $self->{_pos} = -1 if( !exists( $self->{_pos} ) );
    my $data = $self->items;
    my $what = lc( Wanted::wantref );
    my $val;
#     if( $self->{_pos} + 1 < $data->length )
#     {
        $val = $data->[ ++$self->{_pos} ];
#     }
    
    if( !defined( $val ) )
    {
        # Our offset exceeds the size of our data pool and we have more data, so let's fetch some more
        if( $self->{_pos} > $data->size && $self->has_more )
        {
            my $req = $self->request ||
                return( $self->error( "No initial HTTP request was provided to load data." ) );
            $req = $req->clone;
            my $filter = $self->filter;
            # Starting from 1
            my $page = $self->page // 1;
            my $size;
            if( $filter )
            {
                return( $self->error( "No search query set." ) ) if( !$filter->query );
                # 10 is Elastic Search default size
                $size = $filter->size;
                if( defined( $size ) && !$size )
                {
                    $size = $self->size // DEFAULT_PAGE_SIZE;
                    $filter->size( $size );
                }
                $filter->from( int( ( $page - 1 ) * $size ) );
            }
            else
            {
                $self->message( 5, "Original query URL is ", $req->uri );
                my $query = $req->uri->query_form_hash;
                if( !scalar( keys( %$query ) ) || 
                    ( !exists( $query->{page} ) && !exists( $query->{from} ) && !exists( $query->{size} ) ) )
                {
                    # return( $self->error( "No search query set." ) );
                }
                $size = $self->size;
                # If size option is set, otherwise we leave it out
                if( defined( $size ) )
                {
                    $size //= DEFAULT_PAGE_SIZE;
                    my $size_prop = $self->size_prop // 'size';
                    $query->{ $size_prop } = $size;
                }
                my $page_type = $self->page_type || 'from';
                $self->message( 4, "Page is '", ( $page // 'undef' ), "' size is '", ( $size // 'undef' ), "', page_type is '", ( $page_type // 'undef' ), "'" );
                if( $page_type eq 'from' )
                {
                    my $page_size = $size // $self->page_size;
                    # 0..9 or 10..19
                    my $offset = int( ( $page - 1 ) * $page_size );
                    $self->message( 4, "Offset is '$offset'" );
                    $query->{from} = $offset;
                }
                elsif( $page_type eq 'page' )
                {
                    $query->{page} = ( $page + 1 );
                }
                else
                {
                    return( $self->error( "Unknown page type '$page_type'" ) );
                }
                $self->message( 4, "Setting new query with hash -> ", sub{ $self->dump( $query ) } );
                $req->uri->query_form( $query );
                $self->message( 4, "Using URI for next load of data -> ", $req->uri );
            }
            
            # User will need to check if there is an error if the user gets an undefined value in return,
            # to distinguish between no more value vs a returned error
            $self->load( request => $req ) || return( $self->pass_error );
            # We set our current page to +1 if indeed we have data.
            $self->page( $page + 1 ) if( !$self->items->is_empty );
            return( $self->next );
        }
        
        if( $what eq 'object' || $what eq 'hash' )
        {
            return( $self->new_null( type => $what ) );
        }
        return;
    }
    return( $val );
}

sub offset
{
    my $self = CORE::shift( @_ );
    my $page = $self->page // 1;
    my( $size, $filter );
    if( $filter = $self->filter )
    {
        $size = $filter->size;
    }
    # $size //= $self->page_size // DEFAULT_PAGE_SIZE;
    $size ||= $self->page_size || DEFAULT_PAGE_SIZE;
    my $pos = $self->pos // 0;
    $self->message( 4, "Calculating offset using page '$page', size '$size' and pos '$pos' -> ", ( $pos + ( $size * ( $page - 1 ) ) ) );
    return( $self->new_number( $pos + ( $size * ( $page - 1 ) ) ) );
}

sub page { return( CORE::shift->_set_get_number( 'page', @_ ) ); }

sub pageable { return( CORE::shift->_set_get_number( 'pageable', @_ ) ); }

sub page_size { return( CORE::shift->_set_get_number( 'page_size', @_ ) ); }

sub page_type { return( shift->_set_get_scalar_as_object( 'page_type', @_ ) ); }

sub pop
{
    my $self = CORE::shift( @_ );
    my $data = $self->items;
    my $what = lc( Wanted::wantref );
    my $val  = $self->items->pop;

    if( !defined( $val ) )
    {
        if( $what eq 'object' || $what eq 'hash' )
        {
            return( $self->new_null( type => $what ) );
        }
        return;
    }
    return( $val );
}

sub pos { return( CORE::shift->{_pos} ); }

sub preprocess { return( CORE::shift->_set_get_code( 'preprocess', @_ ) ); }

sub postprocess { return( CORE::shift->_set_get_code( 'postprocess', @_ ) ); }

sub prev
{
    my $self = CORE::shift( @_ );
    $self->{_pos} = -1 if( !exists( $self->{_pos} ) );
    my $data = $self->items;
    my $what = lc( Wanted::wantref );
    my $val;
    if( $self->{_pos} - 1 >= 0 )
    {
        $val = $data->[ --$self->{_pos} ];
    }

    if( !defined( $val ) )
    {
        # Starting from 1
        my $page = $self->page // 1;
        if( $self->{_pos} <= 0 && $page > 1 )
        {
            my $req = $self->request ||
                return( $self->error( "No initial HTTP request was provided to load data." ) );
            $req = $req->clone;
            my $filter = $self->filter;
            # Next page
            $page--;
            my $size;
            if( $filter )
            {
                return( $self->error( "No search query set." ) ) if( !$filter->query );
                # 10 is Elastic Search default size
                $size = $filter->size;
                if( defined( $size ) && !$size )
                {
                    $size = $self->size // DEFAULT_PAGE_SIZE;
                    $filter->size( $size );
                }
                $filter->from( int( ( $page - 1 ) * $size ) );
            }
            else
            {
                my $query = $req->uri->query_form_hash;
                return( $self->error( "No search query set." ) ) if( !scalar( keys( %$query ) ) || !CORE::length( $query->{'q'} // '' ) );
                $size = $self->size;
                # If size option is set, otherwise we leave it out
                if( defined( $size ) )
                {
                    $size //= DEFAULT_PAGE_SIZE;
                    my $size_prop = $self->size_prop // 'size';
                    $query->{ $size_prop } = $size;
                }
                my $page_type = $self->page_type || 'from';
                if( $page_type eq 'from' )
                {
                    # 0..9 or 10..19
                    my $offset = int( ( $page - 1 ) * $size );
                    $query->{from} = $offset;
                }
                elsif( $page_type eq 'page' )
                {
                    $query->{page} = ( $page + 1 );
                }
                else
                {
                    return( $self->error( "Unknown page type '$page_type'" ) );
                }
                $req->uri->query_form_hash( $query );
            }
            
            # User will need to check if there is an error if the user gets an undefined value in return,
            # to distinguish between no more value vs a returned error
            $self->load( request => $req ) || return( $self->pass_error );
            # We set our current page to +1 if indeed we have data.
            $self->page( $page ) if( !$self->items->is_empty );
        }
        
        if( $what eq 'object' || $what eq 'hash' )
        {
            return( $self->new_null( type => $what ) );
        }
        return;
    }
    return( $val );
}

sub push
{
    my $self = CORE::shift( @_ );
    my $this = CORE::shift( @_ ) || return( $self->error( "Nothing was provided to add to the list of object." ) );
    $self->_check( $this ) || return( $self->pass_error );
    $self->items->push( $this );
    return( $self );
}

sub request { CORE::return( shift->_set_get_object_without_init( 'request', 'HTTP::Promise::Request', @_ ) ); }

sub shift
{
    my $self = CORE::shift( @_ );
    my $data = $self->items;
    my $what = lc( Wanted::wantref );
    my $val  = $self->items->shift;


    if( !defined( $val ) )
    {
        if( $what eq 'object' || $what eq 'hash' )
        {
            return( $self->new_null( type => $what ) );
        }
        return;
    }
    return( $val );
}

sub size { return( CORE::shift->_set_get_number( 'size', @_ ) ); }

sub size_prop { return( CORE::shift->_set_get_scalar_as_object( 'size_prop', @_ ) ); }

# NOTE: timed_out is returned by MetaCPAN API (Elastic Search)
sub timed_out { return( CORE::shift->_set_get_boolean( 'timed_out', @_ ) ); }

# NOTE: took is returned by MetaCPAN API (Elastic Search)
sub took { return( CORE::shift->_set_get_number( { field => 'took', undef_ok => 1 }, @_ ) ); }

# NOTE: total returns the number returned by MetaCPAN API, which represents the overal total number of hits across all pages
sub total { return( CORE::shift->_set_get_number( 'total', @_ ) ); }

sub type { return( CORE::shift->_set_get_scalar_as_object( 'type', @_ ) ); }

sub unshift
{
    my $self = CORE::shift( @_ );
    my $this = CORE::shift( @_ ) || return( $self->error( "Nothing was provided to add to the list of object." ) );
    $self->_check( $this ) || return( $self->pass_error );
    $self->items->unshift( $this );
    return( $self );
}

sub _check
{
    my $self = CORE::shift( @_ );
    my $this = CORE::shift( @_ ) || return( $self->error( "No data was provided to check." ) );
    return( $self->error( "Data provided is not an object." ) ) if( !$self->_is_object( $this ) );
    # Check if there is any data and if there is find out what kind of object we are holding so we can maintain consistency
    my $data = $self->items;
    my $obj_name;
    if( !$data->is_empty && $self->_is_object( $data->[0] ) )
    {
        $obj_name = $data->[0]->object if( $data->[0]->can( 'object' ) );
    }
    if( $this->can( 'object' ) )
    {
        my $this_object = $this->object;
        $this_object = '' if( !defined( $this_object ) || !$this_object->defined );
        $obj_name = '' if( !defined( $obj_name ) || !$obj_name->defined );
        return( $self->error( "Object provided (", overload::StrVal( $this ), ") has an object type (${this_object}) different from the ones currently in our stack (${obj_name})." ) ) if( $this_object ne $obj_name );
    }
    return( $this );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::List - Meta CPAN API List

=head1 SYNOPSIS

    use Net::API::CPAN::List;
    my $list = Net::API::CPAN::List->new(
        items => $array_ref,
    ) || die( Net::API::CPAN::List->error, "\n" );
    # or
    my $list = Net::API::CPAN::List->new;
    $list->load_data( $hash_ref ) || die( $list->error );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This class is used to retrieve and manipulate list of data such as the ones resulting from a search query.

It inherits from L<Net::API::CPAN::Generic>

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or an hash reference of parameters and this will instantiate a new list object.

The valid parmeters that can be used are as below and can also be accessed with their corresponding method:

=over 4

=item * C<api>

An L<Net::API::CPAN> object.

=item * C<items>

An array reference of data.

=back

=head1 METHODS

=head2 api_uri

Sets or gets the MetaCPAN API base URI, which defaults to L<https://fastapi.metacpan.org>

This returns an L<URI> object.

=head2 api_version

Sets or gets the MetaCPAN API version, which defaults to C<1>. This is used to form the base of the endpoints, such as C</v1/author/search>

It returns a L<scalar object|Module::Generic::Scalar>

=head2 container

Sets or gets a string representing the property containing the array of all the data.

If this is not set, then L</load_data> will try to guess it.

=head2 data

    $list->data( $hash_ref ) || die( $list->error );
    my $array_ref = $list->data;

This is a convenient shortcut that calls L<load_data|/load_data> when data is provided, and returns the call to L<items|/items> either way.

=head2 filter

Sets or gets the L<filter object|Net::API::CPAN::Filter>. It returns C<undef> in scalar context if none is set, but it instantiates automatically a new instance in object context.

    my $filter = $list->filter; # undef
    my $from = $list->filter->from; # ok, it works, but still undef

=head2 get

    # implicit
    my $obj = $list->get;
    # explicit
    my $obj = $list->get(0);
    # or
    my $obj = $list->get(2);

This returns the data object at the current offset, or at the provided offset if one was provided.

If no data object exists at the offset, this will return C<undef> in scalar context, or an empty list in list context, and it will return a L<null object|Module::Generic::Null> in object context to prevent a perl error of some methods called with an undefined value. The null object virtual method call will return C<undef> eventually.

For example, let's assume a list of only 1 element. Calling C<get> with offset C<3> exceeds the size of the data pool, and would return an C<undef> value, but since it is called in object context, it returns a L<null object|Module::Generic::Null> instead.

    my $undef = $list->get(3)->author;

=head2 has_more

Read-only. This will return true if there are more data to be fetched from the MetaCPAN API, or false otherwise.

=head2 http_request

Sets or gets an L<HTTP::Promise::Request> object.

=head2 http_response

Sets or gets an L<HTTP::Promise::Response> object.

=head2 items

Provided with an array reference and an hash or hash reference of options and this sets the provided array as the active pool of data.

The data contained can be either an array reference of hash reference, or an array reference of objects. If the data provided are an array reference of hash reference, they will be turned into their corresponding object, based on the value of each hash C<_type> property, such as C<< _type => "author" >>

It always return an L<array object|Module::Generic::Array>, whether any data were provided or not.

=head2 load

Using the L<filter object|Net::API::CPAN::Filter> accessible with L</filter>, this will issue a new HTTP C<POST> query to the MetaCPAN API endpoint to retrieve the C<JSON> data.

It will then populate the data, notably to C<items>, C<timed_out>, C<total>, C<took> and return the current object for chaining.

It also sets the HTTP request object and the HTTP response object that can be retrieved with L</http_request> and L</http_response> respectively.

If an error occurred, it will set an L<error object|Net::API::CPAN::Exception>, and return C<undef> in scalar context or an empty list in list context.

There is no need to access C<load> directly. This would be called automatically when more data is requested and if there is indeed more data.

=head2 load_data

Provided with an hash reference of data, and this will load it into the current object, and return the current object for chaining. Upon error, this will set an L<error object|Net::API::CPAN::Exception> and return C<undef> in scalar context, or an empty list in list context.

=head2 length

Read-only. This returns the size of the data pool as a L<number object|Module::Generic::Number>.

A 10-elements data pool would return 10. The value returned is directly related to the sie of the arra reference data pool, so if you use the methods L</pop>, L</unshift>, L</shift>, L</unshift>, it will affect the value returned here.

See also L</total>

=head2 next

    my $obj = $list->next;

This returns the next data object in the data pool, or if none exists, C<undef> in scalar context and an empty list in list context, and it will return a L<null object|Module::Generic::Null> in object context to prevent a perl error of some methods called with an undefined value. The null object virtual method call will return C<undef> eventually.

For example, let's assume the list is empty. Calling C<next> would return an C<undef> value, but since it is called in object context, it returns a L<null object|Module::Generic::Null> instead.

    my $undef = $list->next->author;

The size of the data pool returned from the MetaCPAN REST API is based upon the value of L<size|/size>, which usually defaults to C<10>. Once C<next> has reached the last element in the data pool, it will attempt to load more data, if there are more to load at all. To know that, it calls L</has_more>. Thus, when C<undef> is returned, it really means, there is no more data to retrieve.

=head2 offset

Read-only. Returns the offset position of the current item across the entire data set.

For example, if you are currently checking the 3rd element of the 2 data page, the offset value would be C<12>, because offset starts at C<0>

This returns a L<number object|Module::Generic::Number>

See also L</pos>

=head2 page

Integer. Sets or gets an integer representing the current page of data being used.

Returns a L<number object|Module::Generic::Number>

=head2 page_type

Sets or gets a L<scalar object|Module::Generic::Scalar> representing the type of paging used to access next and previous pages. Possible values are C<from> and C<page>, and this defaults to C<from>

When it is set to C<from>, L<load|/load> will use a data offset starting from C<0>. For example, on a data set broken into pages of 20 elements each, moving to the 2 pages would set the C<from> value to C<20>.

If C<page_type> is set to C<page>, the L<page|/page> number starting from C<1> will be used.

=head2 pageable

Boolean. Sets or gets a boolean value representing whether more data can be loaded beyond the current set, or if the current set the only set of available data.

Returns a L<boolean object|Module::Generic::Boolean>

For example, L<autocomplete|Net::API::CPAN/autocomplete> returns a set of 10 elements, but is not pageable.

=head2 page_size

Integer. This indicates the size of each result page. Contrary to L<size|/size>, which is a preference that can be set to indicate how many result per page one wants, C<page_size> is set upon loading data with L<load_data|/load_data> and reflects the actul page size.

If the page contains only a small amount of results, such as 3, then C<page_size> will be 3, but if the overall total exceeds that of the page size, C<page_size> will show how many result per page is provided.

This information is then used for new requests to load more data by L<next|/next> and L<prev|/prev>

Thus it is more an internal method.

=head2 pop

    my $obj = $list->pop;

This removes the last entry from the data pool, thus altering it, and returns it.

If the value to be returned is undefined, it will return C<undef> in scalar context and an empty list in list context, and it will return a L<null object|Module::Generic::Null> in object context to prevent a perl error of some methods called with an undefined value. The null object virtual method call will return C<undef> eventually.

For example, let's assume the list is empty. Calling C<pop> would return an C<undef> value, but since it is called in object context, it returns a L<null object|Module::Generic::Null> instead.

    my $undef = $list->pop->author;

You might want to use C<< $list->get(-1) >> instead to avoid modifying the array reference of data.

=head2 pos

Read-ony. Returns the current position in the array reference of data pool. This would be a positive integer, or C<undef> if no data was accessed yet.

See also L</offset>

=head2 postprocess

Sets or gets the caller (anonymous subroutine) that is is called by L</load_data> with the hash reference of data received from the MetaCPAN API, for possible post processing.

This method, not the callback, returns the current object for chaining, or upon error, sets an L<error|Net::API::CPAN::Exception> and returns C<undef> in scalar context or an empty list in list context.

=head2 preprocess

Sets or gets the caller (anonymous subroutine) that is is called by L</load_data> with the hash reference of data received from the MetaCPAN API, for possible pre processing.

This method, not the callback, returns the current object for chaining, or upon error, sets an L<error|Net::API::CPAN::Exception> and returns C<undef> in scalar context or an empty list in list context.

=head2 prev

    my $obj = $list->next;

This returns the previous data object in the data pool, or if none exists, C<undef> in scalar context and an empty list in list context, and it will return a L<null object|Module::Generic::Null> in object context to prevent a perl error of some methods called with an undefined value. The null object virtual method call will return C<undef> eventually.

For example, let's assume the list is empty. Calling C<prev> would return an C<undef> value, but since it is called in object context, it returns a L<null object|Module::Generic::Null> instead.

    my $undef = $list->prev->author;

=head2 push

    $list->push( $object );

Provided with a proper object value, and this will add it to the end of the data pool and returns the current list object for chaining purposes.

A valid value must be an object of the same type as the ones used in this data pool.

Upon error, this will set an L<error object|Net::API::CPAN::Exception> and returns C<undef> in scalar context and an empty list in list context.

=head2 request

Sets or gets the original L<HTTP request object|HTTP::Promise::Request> that was used for this list object.

=head2 shift

    my $obj = $list->shift;

This removes the first entry from the data pool, thus altering it, and returns it.

If the value to be returned is undefined, it will return C<undef> in scalar context and an empty list in list context, and it will return a L<null object|Module::Generic::Null> in object context to prevent a perl error of some methods called with an undefined value. The null object virtual method call will return C<undef> eventually.

For example, let's assume the list is empty. Calling C<shift> would return an C<undef> value, but since it is called in object context, it returns a L<null object|Module::Generic::Null> instead.

    my $undef = $list->shift->author;

=head2 size

Sets or gets the size of each page. Normally, this is figured out automatically by L<load_data|/load_data>, but sometimes, when large chunk of data are returning at once, and you want to break it down, setting the C<size> makes it possible.

This returns a L<number object|Module::Generic::Number>

=head2 size_prop

Sets or gets the property name in the data containing the size of the data set. Typically this is C<size> and this is the default value.

This returns a L<scalar object|Module::Generic::Scalar>

=head2 timed_out

Sets or gets the boolean value returned from the last API call to MetaCPAN and representing whether the query has timed out.

=head2 took

Sets or gets a number returned from the last API call to MetaCPAN. If set, this will return a L<number object|Module::Generic::Number>, otherwise C<undef>

=head2 total

Sets or gets the overall size of the data available from MetaCPAN API, possibly across multiple API calls.

For example, a query might result in data of 120 elements found, and each page with 10 elements. C<total> would then be 120.

It returns a L<number object|Module::Generic::Number>.

See also L</length>, which returns the current size of the data at hands stored in C<items>

=head2 type

Sets or gets the underlying object type of the data pool. This can be C<author>, C<changes>, C<cover>, C<distribution>, C<favorite>, C<file>, C<mirror>, C<module>, C<package>, C<permission>, C<rating>, C<release>, but is not enforced, so whatever value you set is your responsibility.

=head2 unshift

    $list->unshift( $object );

Provided with a proper object value, and this will add it at the beginning of the data pool and returns the current list object for chaining purposes.

A valid value must be an object of the same type as the ones used in this data pool.

Upon error, this will set an L<error object|Net::API::CPAN::Exception> and returns C<undef> in scalar context and an empty list in list context.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::CPAN>, L<Net::API::CPAN::Scroll>, L<Net::API::CPAN::Filter>, L<Net::API::CPAN::Exception>, L<HTTP::Promise>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
