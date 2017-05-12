package Net::Semantics3::Products;

use Moose;
use methods;
use JSON::XS;
use Data::Dumper;
use Net::Semantics3::Error;

extends 'Net::Semantics3';

use constant MAX_LIMIT => 10;

=head1 NAME

Net::Semantics3::Products - API Client for Semantics3 Products API

=head1 SYNOPSIS

    use Net::Semantics3::Products;
    use Data::Dumper;

    my $sem3 = Net::Semantics3::Products->new (
        api_key => 'YOUR_API_KEY',
        api_secret => 'YOUR_API_SECRET',
    );

    $sem3->add("products","cat_id",4992);
    $sem3->add("products","brand","Toshiba");
    $sem3->add("products","weight","gte",1000000);
    $sem3->add("products","weight","lt",1500000);

    my $products = $sem3->get_products();
    print STDERR Dumper($products);

=head1 DESCRIPTION

This module is a wrapper around the Semantics3 Products API. Methods are 
generally named after the HTTP method and the object name.

=head1 METHODS

=head2 API Object

=head3 new PARAMHASH

This creates a new Semantics3 API object.  The following parameters are accepted:

=over

=item api_key

This is required. You get this from your Semantics3 Dashboard.

=item api_secret

This is required. You get this from your Semantics3 Dashboard.

=back
 
=cut


has 'data_query' => (isa => 'HashRef', is => 'rw', default => sub { my %hash; return \%hash; } );
has 'query_result' => (isa => 'HashRef', is => 'rw', default => sub { my %hash; return \%hash; } );
#has 'sem3_endpoint' => (isa => 'Str', is => 'ro', writer => 'private_set_endpoint', default => "products");

=head2 Offers 

Methods for querying the 'offers' endpoint.

See https://semantics3.com/docs for full details.

=head3 offers_field( params1, params2, ... )

Query the offers endpoint by building up the query parameters.

    $sem3->offers_field( 'currency', 'USD' );
    $sem3->offers_field( 'currency', 'price', 'gte', 30 );

=head3 get_offers( )

Returns the output of the query on the 'offers' endpoint. Note: The output of this method would overwrite the output of any previous query stored in the results buffer.
 
    my $offersResultRef = $sem3->get_offers();
    print STDERR Dumper( $offersResultRef );

=cut

Offers: {

    method offers_field {
        $self->add( 'offers', @_ );
    }

    method get_offers {
        return $self->run_query( 'offers' );
    }

}

=head2 Categories 

Methods for querying the 'categories' endpoint.

See https://semantics3.com/docs for full details.

=head3 categories_field( params1, params2, ... )

Query the categories endpoint by building up the query parameters.

    $sem3->categories_field( 'parent_cat_id', 1 );

=head3 get_categories( )

Returns the output of the query on the 'categories' endpoint. Note: The output of this method would overwrite the output of any previous query stored in the results buffer.

    my $categoriesResultRef = $sem3->get_categories();
    print STDERR Dumper( $categoriesResultRef );

=cut

Categories: {

    method categories_field {
        $self->add( 'categories', @_ );
    }

    method get_categories {
        return $self->run_query( 'categories' );
    }

}

=head2 Products 

Methods for querying the 'products' endpoint.

See https://semantics3.com/docs for full details.

=head3 products_field( params1, params2, ... )

Query the products endpoint by building up the query parameters.

    $sem3->products_field( 'cat_id', 4992 );
    $sem3->products_field( 'brand', 'Toshiba' );
    $sem3->products_field( 'weight', 'gte', 1000000 );
    $sem3->products_field( 'weight', 'lt', 1500000 );

=head3 get_products( )

Returns the output of the query on the 'products' endpoint. Note: The output of this method would overwrite the output of any previous query stored in the results buffer.

    my $productsResultRef = $sem3->get_products();
    print STDERR Dumper( $productsResultRef );

=head3 all_products( )

Converts and returns the results of the query output of the 'products' endpoint as an array reference.
get_products() or run_query("products") must have been called before and should have returned a valid
result set.

    $sem3->get_products();
    my @productsArray = $sem3->all_products;
    foreach(@productsArray) {
        print STDERR Dumper($_);
    }

=head3 iterate_products( )

Returns the output of the query by auto incrementing the offset based on the limit defined.
If limit is not defined, it defaults to default value of 10.

    #-- get_products() or run_query("products") must have been called before and query
    #-- should have returned a valid result set in order to use iterate_products() methdo
    $sem3->get_products();

    while(my $nextProductsRef = $sem3->iterate_products()) {
        print STDERR Dumper( $nextProductsRef );
    }

=cut

Products: {

    method products_field {
        $self->add( 'products', @_ );
    }

    method get_products {
        return $self->run_query( 'products' );
    }

    method all_products {
        if( !defined( $self->query_result->{ 'results' } ) ) {
            Net::Semantics3::Error->new(
                type => "Undefined Query",
                message => "Query result is undefined. You need to run a query first. " . Dumper( $self->query_result->{ 'results' } ),
            );  
        }
        my $arrRef = $self->query_result->{ 'results' };
        return @{ $arrRef };
    }
    
    method iterate_products {
        my $limit=MAX_LIMIT;

        if(!defined($self->query_result->{ 'total_results_count' }) ||
            $self->query_result->{ 'offset' } >= $self->query_result->{ 'total_results_count' }) {
            return undef;
        }

        $limit = $self->data_query->{ 'products' }->{ 'limit' } if defined $self->data_query->{ 'products' }->{ 'limit' };
        $self->data_query->{ 'products' }->{ 'offset' } = $self->data_query->{ 'products' }->{ 'offset' } + $limit;

        return $self->get_products();
    }

}

=head2 Common 

Common methods for use to querying the various endpoints of the Semantics3 Products API.

See https://semantics3.com/docs for full details.

=head3 add( ENDPOINT, params1, params2, ... )

Query any endpoint by building up the query parameters.

    $sem3->add( 'products', 'cat_id', 4992 );
    $sem3->add( 'products', 'brand', 'Toshiba' );
    $sem3->add( 'products', 'weight', 'gte', 1000000 );
    $sem3->add( 'products', 'weight', 'lt', 1500000 );

=head3 remove( ENDPOINT, params1, params2, ... )

Removes any specific parameters in the constructured query parameter set for any endpoint.

    #-- Removes the 'gte' attribute and it's associated weight
    $sem3->remove( 'products', 'weight', 'gte' );
    #-- Removes the entire 'brand' field from the query
    $sem3->remove( 'products', 'brand' );

=head3 get_query( ENDPOINT )

Returns the hash reference of the constructed query for the specified endpoint.

    my $productsQuery = get_query( 'products' );

=head3 get_query_json( ENDPOINT )

Returns the JSON string of the constructed query for the specified endpoint.

    my $productsJSON = get_query_json( 'products' );

=head3 get_results( )

Returns the hash reference of the results from any previously executed query.

    my $resultsRef = get_results( );

=head3 get_results_json( )

Returns the JSON string of the results from any previously executed query.

    my $resultsJSONString = get_results_json( );

=head3 clear( )

Clears previously constructed parameters for each of the endpoints and also the results buffer.

    $sem3->clear();

=head3 run_query( ENDPOINT, data )

Execute query of any endpoint based on the previously constructed query parameters or alternatively
execute query of any endpoint based on the hash reference or JSON string of the query you wish to 
supply. Returns a hash reference of the executed query.

    #-- Just query based on constructed query using methods add() or endpoint-specific methods like products_field(), etc..
    my $resultsRef = run_query( 'products' );
    #-- Pass in a hash reference
    my $resultsRef = run_query( 'products', { 'cat_id'=>4992, 'brand'=>'Toshiba' } );
    #-- Pass in a JSON string
    my $resultsRef = run_query( 'products', '{"cat_id":4992,"brand":"Toshiba","weight":{"gte":1000000,"lt":1500000}}' );

=cut

Common: {

    method add {
        my $endpoint = $_[0];
        my @fields = @_[1..$#_];

        if(!defined($endpoint) || $endpoint eq "") {
            Net::Semantics3::Error->new(
                type => "Undefined Endpoint",
                message => "Query Endpoint was not defined. You need to provide one. Eg: products " . Dumper( $self->data_query ),
                param => "endpoint",
            );  
        }

        if( !defined( $self->data_query->{ $endpoint } ) ) {
            $self->data_query->{ $endpoint } = {};
        }

        my $prodRef = $self->data_query->{ $endpoint };

        for( my $i=1; $i<=$#fields; $i++ ) {
            if( !defined( $prodRef->{ $fields[$i-1] } ) ) {
                $prodRef->{ $fields[$i-1] } = {};
            }
            if($i != $#fields) {
                $prodRef = $prodRef->{ $fields[$i-1] };
            }
            else {
                $prodRef->{ $fields[$i-1] } = $fields[$i];
            }
        }
    }

    method remove {
        my $endpoint = $_[0];
        my @fields = @_[1..$#_];

        if(!defined($endpoint) || $endpoint eq "") {
            Net::Semantics3::Error->new(
                type => "Undefined Endpoint",
                message => "Query Endpoint was not defined. You need to provide one. Eg: products " . Dumper( $self->data_query ),
                param => "endpoint",
            );  
        }
        my $valid = 0;
        my $prodRef;
        my $arrayCt = 0;

        if( defined( $self->data_query->{ $endpoint } ) ) {
            $prodRef = $self->data_query->{ $endpoint };
            $arrayCt = $#fields;
            $valid = 1;

            for( my $i=0; $i<=$arrayCt-1; $i++ ) {
                if( defined( $prodRef->{ $fields[$i] } ) ) {
                    $prodRef = $prodRef->{ $fields[$i] };
                    $prodRef->{ $fields[$i-1] } = {};
                }
                else {
                    $valid = 0;
                }
            }
        }

        if( $valid ) {
            delete $prodRef->{ $fields[ $arrayCt ] };
        }
        else {
            Net::Semantics3::Error->new(
                type => "Attempted Invalid Deletion",
                message => "Attempted to detele something which didn't exist. " . Dumper( $self->data_query->{ $endpoint } ),
            );  
        }
    }

    method get_query {
        my( $endpoint ) = @_;

        if(!defined( $endpoint ) || $endpoint eq "") {
            Net::Semantics3::Error->new(
                type => "Undefined Endpoint",
                message => "Query Endpoint was not defined. You need to provide one. Eg: products " . Dumper( $self->data_query ),
                param => "endpoint",
            );  
        }

        return $self->data_query->{ $endpoint };
    }

    method get_query_json {
        my( $endpoint ) = @_;

        if(!defined( $endpoint ) || $endpoint eq "") {
            Net::Semantics3::Error->new(
                type => "Undefined Endpoint",
                message => "Query Endpoint was not defined. You need to provide one. Eg: products " . Dumper( $self->data_query ),
                param => "endpoint",
            );  
        }

        return encode_json( $self->data_query->{ $endpoint } );
    }

    method get_results {
        return $self->query_result();
    }

    method get_results_json {
        return encode_json( $self->query_result() );
    }

    method clear {
        $self->data_query({});
        $self->query_result({});
    }

    #-- TODO:
    #-- get_query -> wraps run_query with hardcoded method
    #-- post_query
    #-- put_query
    #-- del_query
    #-- run_query(endpoint,data,method)
    method run_query {
        my( $endpoint, $data, $method ) = @_;

        if(!defined( $method ) || $method eq "") {
            $method = "GET";
        }

        if(!defined( $endpoint ) || $endpoint eq "") {
            Net::Semantics3::Error->new(
                type => "Undefined Endpoint",
                message => "Query Endpoint was not defined. You need to provide one. Eg: products " . Dumper( $self->data_query ),
                param => "endpoint",
            );  
        }

        if( !defined( $data ) ) {
            my $dataQueryEndpoint = "{}";
            if(defined($self->data_query->{ $endpoint })) {
                $dataQueryEndpoint = encode_json( $self->data_query->{ $endpoint } );
            }

            $self->query_result( $self->_request( $endpoint, $dataQueryEndpoint, $method ) );
        }
        else {
            #-- Data is nether hash nor string
            if(ref( $data ) ne "HASH" && ref( $data ) ne "" ) {
                Net::Semantics3::Error->new(
                    type => "Invalid Data",
                    message => "Invaid data was sent. Reference Type: - " . ref( $data ),
                    param => "data",
                );  
            }
            else {
                #-- Data is Hash ref. Great just send it.
                if(ref( $data ) eq "HASH") {
                    $self->query_result( $self->_request( $endpoint, encode_json( $data ), $method ) );
                }
                #-- Data is string
                elsif(ref ($data) eq "") {
                    #-- Check if it's JSON
                    eval{ my $testRef = decode_json( $data ); };
                    #-- Nope. Throw error
                    if($@) {
                        Net::Semantics3::Error->new(
                            type => "Invalid JSON: $@",
                            message => "Invaid JSON was sent.",
                            param => "data",
                        );  
                    }
                    #-- Yup it's valid JSON. Just send it.
                    else {
                        $self->query_result( $self->_request( $endpoint, $data, $method ) );
                    }
                }

            }
        }

        return $self->query_result();
    }

}

=head1 NAME

Net::Semantics3::Products - API Client for Semantics3 Products Data API

=head1 SEE ALSO

L<https://semantics3.com>, L<https://semantics3.com/docs>

=head1 AUTHOR

Sivamani Varun, varun@semantics3.com

=head1 COPYRIGHT AND LICENSE

Net-Semantics3 is Copyright (C) 2013 Semantics3 Inc.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut

__PACKAGE__->meta->make_immutable;
1;
