##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Filter.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/08/03
## Modified 2023/08/03
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::CPAN::Filter;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{aggs}       = undef unless( CORE::exists( $self->{aggs} ) );
    $self->{es}         = undef unless( CORE::exists( $self->{es} ) );
    $self->{fields}     = undef unless( CORE::exists( $self->{fields} ) );
    $self->{filter}     = undef unless( CORE::exists( $self->{filter} ) );
    $self->{from}       = undef unless( CORE::exists( $self->{from} ) );
    $self->{match_all}  = 0 unless( CORE::exists( $self->{match_all} ) );
    $self->{name}       = undef unless( CORE::exists( $self->{name} ) );
    $self->{query}      = undef unless( CORE::exists( $self->{query} ) );
    $self->{size}       = undef unless( CORE::exists( $self->{size} ) );
    $self->{sort}       = undef unless( CORE::exists( $self->{sort} ) );
    $self->{source}     = undef unless( CORE::exists( $self->{source} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_data} = {};
    return( $self );
}

sub aggregations { return( shift->aggs( @_ ) ); }

sub aggs { return( shift->reset(@_)->_set_get_hash_as_mix_object( 'aggs', @_ ) ); }

sub apply
{
    my $self = shift( @_ );
    my $hash = $self->_get_args_as_hash( @_ );
    return( $self ) if( !scalar( keys( %$hash ) ) );
    
    foreach my $k ( keys( %$hash ) )
    {
        my $code;
        # if( !CORE::exists( $dict->{ $k } ) )
        if( !( $code = $self->can( $k ) ) )
        {
            warn( "No method \"$k\" found in class ", ( ref( $self ) || $self ), " when applying data to this object. Skipping it." ) if( $self->_is_warnings_enabled );
            next;
        }
        $code->( $self, $hash->{ $_ } );
    }
    return( $self );
}

sub as_hash
{
    my $self = shift( @_ );
    return( $self->{_data_cache} ) if( $self->{_data_cache} && !CORE::length( $self->{_reset} ) );
    my $data = {};
    my $es = $self->es;
    if( defined( $es ) && $es->length )
    {
        $data = $es->as_hash;
    }
    else
    {
        $data->{query} = $self->query;
        if( my $aggs = $self->aggs )
        {
            $data->{aggs} = $aggs;
        }
        if( my $fields = $self->fields )
        {
            $data->{fields} = [@$fields] if( !$fields->is_empty );
        }
        if( my $filter = $self->filter )
        {
            $data->{filter} = $filter;
        }
        if( my $sort = $self->sort )
        {
            $data->{sort} = [@$sort] if( !$sort->is_empty );
        }
        if( my $source = $self->source )
        {
            $data->{_source} = $source;
        }
        if( my $name = $self->name )
        {
            if( exists( $data->{filter} ) &&
                exists( $data->{filter}->{terms} ) &&
                ref( $data->{filter}->{terms} ) eq 'HASH' )
            {
                $data->{filter}->{terms}->{_name} = $name;
            }
        }
        if( defined( my $from = $self->from ) )
        {
            $data->{from} = $from;
        }
        if( defined( my $size = $self->size ) )
        {
            $data->{size} = $size;
        }
    }
    $self->{_data_cache} = $data;
    CORE::delete( $self->{_reset} );
    return( $data );
}

sub as_json
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $data = $self->as_hash;
    my $j = $self->new_json;
    $j = $j->pretty if( $opts->{pretty} );
    $j = $j->canonical if( $opts->{sort} );
    my $json;
    local $@;
    # try-catch
    eval
    {
        if( exists( $opts->{encoding} ) && 
            defined( $opts->{encoding} ) &&
            ( lc( $opts->{encoding} ) eq 'utf-8' || lc( $opts->{encoding} ) eq 'utf8' ) )
        {
            $json = $j->utf8->encode( $data );
        }
        else
        {
            $json = $j->encode( $data );
        }
    };
    if( $@ )
    {
        return( $self->error( "Error encoding to JSON: $@" ) );
    }
    return( $json );
}

sub es { return( shift->reset(@_)->_set_get_hash_as_mix_object( 'es', @_ ) ); }

sub fields { return( shift->reset(@_)->_set_get_array_as_object( 'fields', @_ ) ); }

sub filter { return( shift->reset(@_)->_set_get_hash_as_mix_object( 'filter', @_ ) ); }

sub from { return( shift->reset(@_)->_set_get_number( 'from', @_ ) ); }

sub match_all { return( shift->reset(@_)->_set_get_number( 'match_all', @_ ) ); }

sub name { return( shift->reset(@_)->_set_get_scalar_as_object( 'name', @_ ) ); }

sub query
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $query;
        my $this = shift( @_ );
        my $opts = $self->_get_args_as_hash( @_ );
        return( $self->error( "Argument to query must be an hash reference." ) ) if( ref( $this ) ne 'HASH' );
        $self->message( 5, "Query provided is -> ", sub{ $self->Module::Generic::dump( $this ) } );
        $self->reset(1);
        my @es_ops = qw( bool should );
        my $es_ops = {};
        @$es_ops{ @es_ops } = (1) x scalar( @es_ops );
        my @operators = ( 'all', 'bool', 'either', 'not', 'must', 'shall', 'shall not', 'should' );
        my $op_re = join( '|', @operators );
        my $equi =
        {
        all => 'must',
        either => 'should',
        not => 'must_not',
        };
        my $build;
        $build = sub
        {
            my $ref = shift( @_ );
            $self->message( 5, "Top properties are: ", sub{ join( ', ', sort( keys( %$ref ) ) ) } );
            my $q = {};
            if( scalar( grep( /^($op_re)$/, keys( %$ref ) ) ) )
            {
                foreach my $op ( @operators )
                {
                    next unless( exists( $ref->{ $op } ) );
                    my $def = delete( $ref->{ $op } );
                    # No need for transformation
                    if( exists( $es_ops->{ $op } ) )
                    {
                        $q->{ $op } = $def;
                        next;
                    }
                    $def = [$def] if( ref( $def ) eq 'HASH' );
                    if( !$self->_is_array( $def ) )
                    {
                        return( $self->error( "Invalid parameter \"$op\" value provided (", overload::StrVal( $def ), "). I was expecting an hash or an array reference." ) );
                    }
                    
                    my $sub_q = [];
                    foreach my $sub_def ( @$def )
                    {
                        my $this_q = $build->( $sub_def ) || return( $self->pass_error );
                        push( @$sub_q, $this_q );
                    }
                    
                    $q->{bool} = {};
                    $q->{bool}->{ $equi->{ $op } // $op } = $sub_q;
                }
            }
            else
            {
                $self->message( 5, "Top properties do not contain either of ", sub{ join( ', ', @operators ) } );
                my $n = scalar( keys( %$ref ) );
                return( $self->error( "Wrong number of keys (${n}). Query element should have only 1 key. Insted I got: ", sub{ $self->Module::Generic::dump( $ref ) } ) ) if( $n > 1 );
                my $key = [keys( %$ref )]->[0];
                my $val = $ref->{ $key };
                # Example:
                # $ref = 
                # {
                #     status => 
                #     {
                #         value => "latest",
                #         boost => 2.0
                #     }
                # }
                if( ref( $val ) eq 'HASH' )
                {
                    $q->{term} = $ref;
                }
                # or, just:
                # $ref = { status => "latest" }
                # or, maybe:
                # $ref = { name => "Some*" }
                elsif( ( !ref( $val ) || $self->_can_overload( $val => '""' ) ) && "$val" =~ /[\w\*]/ )
                {
                    my $type = ( "$val" =~ /[*?]/ ? 'wildcard' : 'term' );
                    $q->{ $type } = $ref;
                }
                else
                {
                    return( $self->error( "Wrong value for \"$key\". I do not know what to do with '", overload::StrVal( $val ), "'" ) );
                }
            }
            return( $q );
        };
        $query = $build->( $this ) || return( $self->pass_error );
        $self->{query} = $query;
    }
    
    unless( $self->{query} )
    {
        my $match_all = $self->match_all;
        if( $match_all )
        {
            if( $match_all == 1 )
            {
                $self->{query} = { match_all => {} };
            }
            else
            {
                $self->{query} = { match_all => { boost => $match_all } };
            }
        }
    }
    return( $self->{query} );
}

sub reset
{
    my $self = shift( @_ );
    if( (
            !exists( $self->{_reset} ) ||
            !defined( $self->{_reset} ) ||
            !CORE::length( $self->{_reset} ) 
        ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
    }
    return( $self );
}

sub size { return( shift->reset(@_)->_set_get_number( 'size', @_ ) ); }

sub sort { return( shift->reset(@_)->_set_get_array_as_object( 'sort', @_ ) ); }

sub source
{
    my $self = shift( @_ );
    if( @_ )
    {
        if( !defined( $_[0] ) )
        {
            $self->{source} = undef;
            $self->reset(1);
        }
        elsif( $self->_is_array( $_[0] ) ||
               !ref( $_[0] ) ||
               ( ref( $_[0] ) && $self->_can_overload( $_[0] => '""' ) ) )
        {
            $self->{source} = shift( @_ );
            $self->reset(1);
        }
        else
        {
            return( $self->error( "A source can only be either a string or an array reference." ) );
        }
    }
    return( $self->{source} );
}

sub TO_JSON { return( shift->as_hash ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Filter - Meta CPAN API

=head1 SYNOPSIS

    use Net::API::CPAN::Filter;
    my $this = Net::API::CPAN::Filter->new(
        query => {
            regexp => { name => 'HTTP.*' },
        },
    ) || die( Net::API::CPAN::Filter->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class is designed to facilitate the forming of an Elastic Search query and store its various components as an object of this class, so it can possibly be re-used or shared.

You can pass arguments to the methods L</aggs>, L</fields>, L</filter>, L</from>, L</match_all>, L</query>, L</size>, L</sort>, L</source> to affect the production of the query.

Alternatively, you can pass an hash reference of a fully formed Elastic Search query directly to L</es> to take precedence over all the other methods.

Calling L</as_hash> will collate all the components and cache the result. If any information is changed using any of the methods in this class, it will remove the cached hash produced by L</as_hash>

You can get a resulting C<JSON> by calling L</as_json>, which in turn, calls L</as_hash>

As far as it is documented in the API documentation, Meta CPAN uses version C<2.4> of Elastic Search, and the methods documentation herein reflect that.

=head1 METHODS

=head2 aggregations

This is an alias for L</aggs>

=head2 aggs

Sets or gets an hash reference of query L<aggregations (post filter)|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-post-filter.html>. It returns an L<hash object|Module::Generic::Hash>, or C<undef>, if nothing was set.

Example from L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-post-filter.html>

    {
        aggs => {
            models => {
                terms => { field => "model" },
            },
        },
        query => {
            bool => {
                filter => [
                    {
                        term => { color => "red" },
                    },
                    {
                        term => { brand => "gucci" },
                    },
                ],
            },
        },
    }

See also L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-post-filter.html>, and L<here|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-aggregations-bucket-terms-aggregation.html>

=head2 apply

Provided with an hash or hash reference of parameters and this will apply each of the value to the method matching its corresponding key if that method exists.

It returns the current object for chaining.

=head2 as_hash

Read-only. Returns the various components of the query as an hash reference.

The resulting hash of data is cached so you can call it multiple time without additional overhead. Any change passed to any methods here will reset that cache.

=head2 as_json

    my $json = $filter->as_json;
    my $json_in_utf8 = $filter->as_json( encoding => 'utf-8' );

Read-only. Returns the various components of the query as C<JSON> data encoded in L<Perl internal utf-8 encoding|perlunicode>.

If an hash or hash reference of options is provided with a property encoding set to C<utf-8> or C<utf8>, then the JSON data returned will be encoded in C<utf-8>

=head2 es

This takes an hash reference of L<Elastic Search query parameters|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-filter-context.html>.

See L</"ELASTIC SEARCH QUERY"> for a brief overview of valid parameters.

Otherwise you are encouraged to call L</query> which will format the Elastic Search query for you.

Returns an L<hash object|Module::Generic::Hash>

=head2 fields

Sets or gets an array of fields onto which the query will be applied.

It returns an L<array object|Module::Generic::Array>

    {
        query => {
            terms => { name => "Japan Folklore" }
        },
        fields => [qw( name abstract distribution )],
    }

Field names can also contain wildcard:

    {
        query => {
            terms => { name => "Japan Folklore" }
        },
        fields => [qw( name abstract dist* )],
    }

Importance of some fields can also be boosted using the caret notation C<^>

    {
        query => {
            terms => { name => "Japan Folklore" }
        },
        fields => [qw( name^3 abstract dist* )],
    }

Here, the field C<name> is treated as 3 times important as the others.

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-fields.html> for more information.

=head2 filter

Sets or gets an hash of filter to affect the Elastic Search query result.

    {
        query => {
            bool => {
                must => [
                    { match => { name     => "Folklore-Japan-v1.2.3"       }},
                    { match => { abstract => "Japan Folklore Object Class" }}
                ],
                filter => [
                    { term =>  { status => "latest" }}, 
                    { range => { date => { gte => "2023-07-01" }}} 
                ]
            }
        }
    }

It returns an L<hash object|Module::Generic::Hash>

=head2 from

Sets or gets a positive integer to return the desired results page. It returns the current value, if any, as a L<number object|Module::Generic::Number>, or C<undef> if there is no value set.

    {
        from => 0,
        query => {
            term => { user => "kimchy" },
        },
        size => 10,
    }

As per the Elastic Search documentation, "[p]agination of results can be done by using the C<from> and C<size> parameters. The C<from> parameter defines the offset from the first result you want to fetch. The C<size> parameter allows you to configure the maximum amount of hits to be returned".

For example, on a size of C<10> elements per page, the first page would start at offset a.k.a C<from> C<0> and end at offset C<9> and page 2 at C<from> C<10> till C<19>, thus to get the second page you would set the value for C<from> to C<10>

See also the more efficient L<scroll approach|Net::API::CPAN::Scroll> to pagination of query results.

Keep in mind this is different from the C<from> option supported in some endpoints of the MetaCPAN API, which would typically starts at 1 instead of 0.

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-from-size.html> for more information.

=head2 match_all

    # Enabled
    $filter->match_all(1);
    # Disabled (default)
    $filter->match_all(0);
    # or
    $filter->match_all(undef);
    # or with explicit score
    $filter->match_all(1.12);

Boolean. If true, this will match all documents by Elastic Search with an identical score of C<1.0>

If the value provided is a number other than C<1> or C<0>, then it will be interpreted as an explicit score to use instead of the default C<1.0>

For example:

    $filter->match_all(1.12)

would produce:

    { match_all => { boost => 1.2 }}

See L<Elastic Search|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-match-all-query.html> for more information.

=head2 name

Sets or gets the L<optional query name|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-named-queries-and-filters.html>. It always returns a L<scalar object|Module::Generic::Scalar>

If set, it will be added to the C<filter>

    {
        bool => {
            filter => {
                terms => { _name => "test", "name.last" => [qw( banon kimchy )] },
            },
            should => [
                {
                    match => { "name.first" => { _name => "first", query => "shay" } },
                },
                {
                    match => { "name.last" => { _name => "last", query => "banon" } },
                },
            ],
        },
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-named-queries-and-filters.html> for more information.

=head2 query

This takes an hash reference of parameters and format the query in compliance with Elastic Search. You can provide directly the Elastic Search structure by calling L</es> and providing it the proper hash reference of parameters.

Queries can be straightforward such as:

    { name => 'Taro Momo' }

or

    { pauseid => 'MOMOTARO' }

or using simple regular expression:

    { name => 'Taro *' }

This would find all the people whose name start with C<Taro>

To produce more complex search queries, you can use some special keywords: C<all>, C<either> and C<not>, which correspond respectively to Elastic Search C<must>, C<should>, and C<must_not> and you can use the Elastic Search keywords interchangeably if you prefer. Thus:

    {
        either => [
            { name => 'John *'  },
            { name => 'Peter *' },
        ]
    }

is the same as:

    {
        should => [
            { name => 'John *'  },
            { name => 'Peter *' },
        ]
    }

and

    {
        all => [
            { name  => 'John *'     },
            { email => '*gmail.com' },
        ]
    }

is the same as:

    {
        must => [
            { name  => 'John *'     },
            { email => '*gmail.com' },
        ]
    }

Likewise

    {
        either => [
            { name => 'John *'  },
            { name => 'Peter *' },
        ],
        not => [
            { email => '*gmail.com' },
        ],
    }

can also be expressed as:

    {
        should => [
            { name => 'John *'  },
            { name => 'Peter *' },
        ],
        must_not => [
            { email => '*gmail.com' },
        ],
    }

=head2 reset

When called with some arguments, no matter their value, this will reset the cached hash reference computed by L</as_hash>

It returns the current object for chaining.

=head2 size

Sets or gets a positive integer to set the maximum number of hits of query results. It returns the current value, if any, as a L<number object|Module::Generic::Number>, or C<undef> if there is no value set.

See L</from> for more information.

    {
        from => 0,
        query => {
            term => { user => "kimchy" },
        },
        size => 10,
    }

See also the L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-from-size.html>

=head2 sort

Sets or gets an array reference of C<sort> parameter to affect the order of the query results.

It always returns an L<array object|Module::Generic::Array>, which might be empty if nothing was specified.

    {
        query => {
            term => { user => "kimchy" },
        },
        sort => [
            {
                post_date => { order => "asc" },
            },
            "user",
            { name => "desc" },
            { age => "desc" },
            "_score",
        ],
    }

The order option can have the following values:

=over 4

=item * C<asc>

Sort in ascending order

=item * C<desc>

Sort in descending order 

=back

Elastic Search supports sorting by array or multi-valued fields. The mode option controls what array value is picked for sorting the document it belongs to. The mode option can have the following values:

    {
        query => {
            term => { user => "kimchy" },
        },
        sort => [
            {
                price => {
                    order => "asc",
                    mode => "avg"
                }
            }
        ]
    }

=over 4

=item * C<min>

Pick the lowest value.

=item * C<max>

Pick the highest value.

=item * C<sum>

Use the sum of all values as sort value. Only applicable for number based array fields.

=item * C<avg>

Use the average of all values as sort value. Only applicable for number based array fields.

=item * C<median>

Use the median of all values as sort value. Only applicable for number based array fields. 

=back

You can also allow to sort by geo distance with C<_geo_distance>, such as:

    {
        query => {
            term => { user => "kimchy" },
        },
        sort => [
            {
                _geo_distance => {
                    distance_type => "sloppy_arc",
                    mode => "min",
                    order => "asc",
                    "pin.location" => [-70, 40],
                    # or, as lat/long
                    # "pin.location" => {
                    #     lat => 40,
                    #     lon => -70
                    # },
                    # or, as string
                    # "pin.location" => "40,-70",
                    # or, as GeoHash
                    # "pin.location" => "drm3btev3e86",
                    unit => "km",
                },
            },
        ],
    }

See also L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-sort.html>

=head2 source

This sets or gets a string or an array reference of query L<source filtering|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-source-filtering.html>.

It returns the current value, which may be C<undef> if nothing was specified.

By default Elastic Search returns the contents of the C<_source> field unless you have used the L<fields|/fields> parameter or if the C<_source> field is disabled.

You can set it to false to disable it. A false value can be C<0>, or an empty string C<"">, but not C<undef>, which will disable this option entirely.

    $filter->query({
        user => 'kimchy'
    });
    $filter->source(0);

would produce the following hash returned by L</as_hash>:

    {
        _source => \0,
        query => {
            term => { user => "kimchy" },
        },
    }

For complete control, you can specify both C<include> and C<exclude> patterns:

    $filter->query({
        user => 'kimchy'
    });
    $filter->source({
        exclude => ["*.description"],
        include => ["obj1.*", "obj2.*"],
    });

would produce the following hash returned by L</as_hash>:

    {
        _source => { exclude => ["*.description"], include => ["obj1.*", "obj2.*"] },
        query => {
            term => { user => "kimchy" },
        },
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-request-source-filtering.html> for more information.

=head1 ELASTIC SEARCH QUERY

=head2 Query and Filter

Example:

The following will instruct Meta CPAN Elastic Search to find module release where all the following conditions are met:

=over 4

=item * The C<name> field contains the word C<Folklore-Japan-v1.2.3>.

=item * The C<abstract> field contains C<Japan Folklore Object Class>.

=item * The C<status> field contains the exact word C<latest>.

=item * The C<date> field contains a date from 1 July 2023 onwards.

=back

    {
        query => {
            bool => {
                must => [
                    { match => { name     => "Folklore-Japan-v1.2.3"       }},
                    { match => { abstract => "Japan Folklore Object Class" }}
                ],
                filter => [
                    { term =>  { status => "latest" }}, 
                    { range => { date => { gte => "2023-07-01" }}} 
                ]
            }
        }
    }

=head2 Match all

    { match_all => {} }

or with an explicit score of C<1.12>

    { match_all => { boost => 1.12 } }

=head2 Match Query

    {
        match => { name => "Folklore-Japan-v1.2.3" }
    }

or

    {
        match => {
            name => {
                query => "Folklore-Japan-v1.2.3",
                # Defaults to 'or'
                operator => 'and',
                # The minimum number of optional 'should' clauses to match
                minimum_should_match => 1,
                # Set to true (\1 is translated as 'true' in JSON) to ignore exceptions caused by data-type mismatches
                lenient => \1,
                # Set the fuzziness value: 0, 1, 2 or AUTO
                fuzziness => 'AUTO',
                # True by default
                fuzzy_transpositions => 1,
                # 'none' or 'all'; defaults to 'none'
                zero_terms_query => 'all',
                cutoff_frequency => 0.001,
            }
        }
    }

=over 4

=item * C<minimum_should_match>

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-minimum-should-match.html> for valid value for C<minimum_should_match>

=item * C<fuzziness>

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/common-options.html#fuzziness> for valid values

=item * C<zero_terms_query>

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-match-query.html#query-dsl-match-query-zero> for valid values

=item * C<cutoff_frequency>

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-match-query.html#query-dsl-match-query-cutoff> for valid values

=back

See also the L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-match-query.html> on C<match> query for more information on its valid parameters.

=head2 Match Phrase

    {
        match_phrase => {
            abstract => "Japan Folklore Object Class",
        }
    }

which is the same as:

    {
        match => {
            abstract => {
                query => "Japan Folklore Object Class",
                type => 'phrase',
            }
        }
    }

=head2 Match Phrase Prefix

As per L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-match-query.html#query-dsl-match-query-phrase-prefix>, this is a poor-man’s autocomplete.

    {
        match_phrase_prefix => {
            abstract => "Japan Folklore O"
        }
    }

It is designed to allow expansion on the last term of the query. The maximum number of expansion is controlled with the parameter C<max_expansions>

    {
        match_phrase_prefix => {
            abstract => {
                query => "Japan Folklore O",
                max_expansions => 10,
            }
        }
    }

The L<documentation recommends|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-suggesters-completion.html> the use of the completion suggester instead.

=head2 Multi Match Query

This performs a query on multiple fields:

    {
        multi_match => {
            query => 'Japan Folklore',
            fields => [qw( name abstract distribution )],
        }
    }

Field names can contain wildcard:

    {
        multi_match => {
            query => 'Japan Folklore',
            fields => [qw( name abstract dist* )],
        }
    }

Importance of some fields can also be boosted using the caret notation C<^>

    {
        multi_match => {
            query => 'Japan Folklore',
            fields => [qw( name^3 abstract dist* )],
        }
    }

Here, the field C<name> is treated as 3 times important as the others.

To affect the way the multiple match query is performed, you can set the C<type> value to C<best_fields>, C<most_fields>, C<cross_fields>, C<phrase> or C<phrase_prefix>

    {
        multi_match => {
            query => 'Japan Folklore',
            fields => [qw( name^3 abstract dist* )],
            type => 'best_fields',
        }
    }

It accepts the other same parameters as in the L<match query/"Query and Filter">

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-multi-match-query.html#multi-match-types> for more details.

=head2 Common Terms Query

As per L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-common-terms-query.html#query-dsl-common-terms-query>, the "C<common> terms query is a modern alternative to stopwords which improves the precision and recall of search results (by taking stopwords into account), without sacrificing performance."

    {
        common => {
            abstract => {
                query => 'Japan Folklore',
                cutoff_frequency => 0.001,
            }
        }
    }

The number of terms which should match can be controlled with the C<minimum_should_match>

See the L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-common-terms-query.html> for more information.

=head2 Query String Query

This leverages the parser in order to parse the content of the query.

    {
        query_string => {
            default_field => "abstract",
            query => "this AND that OR thus",
            fields => [qw( abstract name )],
            # Default is 'OR'
            default_operator => 'AND',
            # \1 (true) or \0 (false)
            allow_leading_wildcard => \1,
            # Default to true
            lowercase_expanded_terms => \1,
            # Default to true
            enable_position_increments => \1,
            # Defaults to 50
            fuzzy_max_expansions => 10,
            # Defaults to 'AUTO'
            fuzziness => 'AUTO',
            # Defaults to 0
            fuzzy_prefix_length => 0,
            # Defaults to 0
            phrase_slop => 0,
            # Defaults to 1.0
            boost => 0,
            # Defaults to true
            analyze_wildcard => \1,
            # Defaults to false
            auto_generate_phrase_queries => \0,
            # Defaults to 10000
            max_determinized_states => 10000,
            minimum_should_match => 2,
            # Defaults to true,
            lenient => \1,
            locale => 'ROOT',
            time_zone => 'Asia/Tokyo',
        }
    }

L<Wildcard searches|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-query-string-query.html#_wildcards> can be run on individual terms, using C<?> to replace a single character, and C<*> to replace zero or more characters:

    qu?ck bro*

L<Regular expression|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-regexp-query.html#regexp-syntax> can also be used:

As per the L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-query-string-query.html#_regular_expressions>, "regular expression patterns can be embedded in the query string by wrapping them in forward-slashes ("/")":

    name:/joh?n(ath[oa]n)/

Fuzziness, i.e., terms that are similar to, but not exactly like our search terms, can be expressed with the fuzziness operator:

    quikc~ brwn~ foks~

An edit distance can be specified:

    quikc~1
    "fox quick"~5

A range can be specified for date, numeric or string fields. Inclusive ranges are specified with square brackets C<[min TO max]> and exclusive ranges with curly brackets C<{min TO max}>.

All days in 2023:

    date:[2023-01-01 TO 2023-12-31]

Numbers 1..5

    count:[1 TO 5]

Tags between C<alpha> and C<omega>, excluding C<alpha> and C<omega>:

    tag:{alpha TO omega}

Numbers from 10 upwards

    count:[10 TO *]

Dates before 2023

    date:{* TO 2023-01-01}

Numbers from 1 up to but not including 5

    count:[1 TO 5}

Ranges with one side unbounded can use the following syntax:

    age:>10
    age:>=10
    age:<10
    age:<=10

    age:(>=10 AND <20)
    age:(+>=10 +<20)

But better to use a L<range query|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html>:

    {
        range => {
            age => {
                gte => 10,
                lte => 20,
                boost => 2.0
            }
        }
    }

L<Boolean operators|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-query-string-query.html#_boolean_operators>:

    quick brown +fox -news

=over

=item * fox must be present

=item * news must not be present

=item * quick and brown are optional — their presence increases the relevance

=back

L<Grouping|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-query-string-query.html#_grouping>

    (quick OR brown) AND fox

    status:(active OR pending) title:(full text search)^2

See the L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-query-string-query.html#query-dsl-query-string-query> and the L<query string syntax|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-query-string-query.html#query-string-syntax> for more information.

L<Multi field|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-query-string-query.html#_multi_field>

    {
        query_string => {
            fields => [qw( abstract name )],
            query => "this AND that"
        }
    }

is equivalent to:

{
    query_string => {
      query => "(abstract:this OR name:this) AND (abstract:that OR name:that)"
    }
}

"Simple wildcard can also be used to search "within" specific inner elements of the document":

    {
        query_string => {
            fields => ["metadata.*"],
            # or, even, to give 5 times more importance of sub elements of metadata
            fields => [qw( abstract metadata.*^5 )],
            query => "this AND that OR thus",
            use_dis_max => \1,
        }
    }

=head2 Field names

Field names can contain query syntax, such as:

where the C<status> field contains C<latest>

    status:latest

where the C<abstract> field contains quick or brown. If you omit the OR operator the default operator will be used

    abstract:(quick OR brown)
    abstract:(quick brown)

where the C<author> field contains the exact phrase C<john smith>

    author:"John Smith"

where any of the fields C<metadata.abstract>, C<metadata.name> or C<metadata.date> contains C<quick> or C<brown> (note how we need to escape the C<*> with a backslash):

    metadata.\*:(quick brown)

where the field C<resources.bugtracker> has no value (or is missing):

    _missing_:resources.bugtracker

where the field C<resources.repository> has any non-null value:

    _exists_:resources.repository

=head2 Simple Query String Query

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-simple-query-string-query.html#query-dsl-simple-query-string-query> for more information.

Those queries will never throw an exception and discard invalid parts.

    {
        simple_query_string => {
            query => "\"fried eggs\" +(eggplant | potato) -frittata",
            analyzer => "snowball",
            fields => [qw( body^5 _all )],
            default_operator => "and",
        }
    }

Supported special characters:

=over 4

=item * C<+> signifies AND operation

=item * C<|> signifies OR operation

=item * C<-> negates a single token

=item * C<"> wraps a number of tokens to signify a phrase for searching

=item * C<*> at the end of a term signifies a prefix query

=item * C<(> and C<)> signify precedence

=item * C<~N> after a word signifies edit distance (fuzziness)

=item * C<~N> after a phrase signifies slop amount

=back

L<Flags|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-simple-query-string-query.html#_flags> can be specified to indicate which features to enable when parsing:

    {
        simple_query_string => {
            query => "foo | bar + baz*",
            flags => "OR|AND|PREFIX",
        }
    }

The available flags are: C<ALL>, C<NONE>, C<AND>, C<OR>, C<NOT>, C<PREFIX>, C<PHRASE>, C<PRECEDENCE>, C<ESCAPE>, C<WHITESPACE>, C<FUZZY>, C<NEAR>, and C<SLOP>

=head2 Term Queries

    {
        term => { author => "John Doe" }
    }

A C<boost> parameter can also be used to give a term more importance:

    {
        query => {
            bool => {
                should => [
                {
                    term => {
                        status => {
                            value => "latest",
                            boost => 2.0 
                        }
                    }
                },
                {
                    term => {
                        status => "deprecated"
                    }
                }]
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-term-query.html#query-dsl-term-query> for more information.

=head2 Terms Query

    {
        constant_score => {
            filter => {
                terms => { pauseid => [qw( momotaro kintaro )]}
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-terms-query.html#query-dsl-terms-query> for more information.

=head2 Range Query

    {
        range => {
            age => {
                gte => 10,
                lte => 20,
                boost => 2.0,
            }
        }
    }

The C<range> query accepts the following parameters:

=over 4

=item * C<gte>

Greater-than or equal to

=item * C<gt>

Greater-than

=item * C<lte>

Less-than or equal to

=item * C<lt>

Less-than

=item * C<boost>

Sets the boost value of the query, defaults to C<1.0>

=back

When using range on a date, ranges can be specified using L<Date Math|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/common-options.html#date-math>:

=over 4

=item * C<+1h>

Add one hour

=item * C<-1d>

Subtract one day

=item * C</d>

Round down to the nearest day

=back

Supported time units are: C<y> (year), C<M> (month), C<w> (week), C<d> (day), C<h> (hour), C<m> (minute), and C<s> (second).

For example:

=over 4

=item * C<now+1h>

The current time plus one hour, with ms resolution.

=item * C<now+1h+1m>

The current time plus one hour plus one minute, with ms resolution.

=item * C<now+1h/d>

The current time plus one hour, rounded down to the nearest day.

=item * C<2023-01-01||+1M/d>

C<2023-01-01> plus one month, rounded down to the nearest day. 

=back

L<Date formats|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries> in range queries can be specified with the C<format> argument:

    {
        range => {
            born => {
                gte => "01/01/2022",
                lte => "2023",
                format => "dd/MM/yyyy||yyyy"
                # With a time zone
                # alternatively: Asia/Tokyo
                time_zone => "+09:00",
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#query-dsl-range-query> for more information.

=head2 Exists Query

Search for values that are non-null.

    {
        exists => { field => "author" }
    }

You can change the definition of what is C<null> with the L<null_value parameter|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-exists-query.html#null-value-mapping>

Equivalent to the L<missing query|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-exists-query.html#missing-query>:

    bool => {
        must_not => {
            exists => {
                field => "author"
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-exists-query.html#query-dsl-exists-query> for more information.

=head2 Prefix Query

Search for documents that have fields containing terms with a specified C<prefix>.

For example, the C<author> field that contains a term starting with C<ta>:

    {
        prefix => { author => "ta" }
    }

or, using the C<boost> parameter:

    {
        prefix => {
            author => {
                value => "ta",
                boost => 2.0,
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-prefix-query.html#query-dsl-prefix-query> for more information.

=head2 Wildcard Query

    {
        wildcard => { pauseid => "momo*o" }
    }

or

    {
        wildcard => {
            pauseid => {
                value => "momo*o",
                boost => 2.0,
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-wildcard-query.html#query-dsl-wildcard-query> for more information.

=head2 Regexp Query

This enables the use of L<regular expressions syntax|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-regexp-query.html#regexp-syntax>

    {
        regexp => {
            metadata.author => "Ta.*o"
        }
    }

or

    {
        regexp => {
            metadata.author => {
                value => "Ta.*o",
                boost => 1.2,
                flags => "INTERSECTION|COMPLEMENT|EMPTY",
            }
        }
    }

Possible flags values are: ALL (default), ANYSTRING, COMPLEMENT, EMPTY, INTERSECTION, INTERVAL, or NONE

Check the L<regular expression syntax|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-regexp-query.html#regexp-syntax>

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-regexp-query.html#query-dsl-regexp-query> for more information.

=head2 Fuzzy Query

    {
        fuzzy => { pauseid => "momo" }
    }

With more advanced parameters:

    {
        fuzzy => {
            user => {
                value => "momo",
                boost => 1.0,
                fuzziness => 2,
                prefix_length => 0,
                max_expansions => 100
            }
        }
    }

With number fields:

    {
        fuzzy => {
            price => {
                value => 12,
                fuzziness => 2,
            }
        }
    }

With date fields:

    {
        fuzzy => {
            created => {
                value => "2023-07-29T12:05:07",
                fuzziness => "1d"
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-fuzzy-query.html#query-dsl-fuzzy-query> for more information.

=head2 Constant Score Query

As per the Elastic Search documentation, this is a "query that wraps another query and simply returns a constant score equal to the query boost for every document in the filter".

    {
        constant_score => {
            filter => {
                term => { pauseid => "momotaro"}
            },
            boost => 1.2,
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-constant-score-query.html#query-dsl-constant-score-query> for more information.

=head2 Bool Query

As per the Elastic Search documentation, this is a "query that matches documents matching boolean combinations of other queries."

The occurrence types are:

=over 4

=item * C<must>

The clause (query) must appear in matching documents and will contribute to the score.

=item * C<filter>

The clause (query) must appear in matching documents. However unlike must the score of the query will be ignored.

=item * C<should>

The clause (query) should appear in the matching document. In a boolean query with no must or filter clauses, one or more should clauses must match a document. The minimum number of should clauses to match can be set using the L<minimum_should_match|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-minimum-should-match.html> parameter.

=item * C<must_not>

The clause (query) must not appear in the matching documents.

=back

    {
        bool => {
            must => {
                term => { author => "momotaro" }
            },
            filter => {
                term => { tag => "tech" }
            },
            must_not => {
                range => {
                    age => { from => 10, to => 20 }
                }
            },
            should => [
                {
                    term => { tag => "wow" }
                },
                {
                    term => { tag => "elasticsearch" }
                }
            ],
            minimum_should_match => 1,
            boost => 1.0,
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-bool-query.html#query-dsl-bool-query> for more information.

=head2 Dis Max Query

As per the Elastic Search documentation, this is a "query that generates the union of documents produced by its subqueries".

    {
        dis_max => {
            tie_breaker => 0.7,
            boost => 1.2,
            queries => [
                {
                    term => { "age" : 34 }
                },
                {
                    term => { "age" : 35 }
                }
            ]
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-dis-max-query.html#query-dsl-dis-max-query> for more information.

=head2 Function Score Query

As per the Elastic Search documentation, the "C<function_score> allows you to modify the score of documents that are retrieved by a query. This can be useful if, for example, a score function is computationally expensive and it is sufficient to compute the score on a filtered set of documents.

To use C<function_score>, the user has to define a query and one or more functions, that compute a new score for each document returned by the query."

    function_score => {
        query => {},
        boost => "boost for the whole query",
        FUNCTION => {},
        boost_mode => "(multiply|replace|...)"
    }

Multiple functions can also be provided:

    function_score => {
        query => {},
        boost => "boost for the whole query",
        functions => [
            {
                filter => {},
                FUNCTION => {},
                weight => $number,
            },
            {
                FUNCTION => {},
            },
            {
                filter => {},
                weight => $number,
            }
        ],
        max_boost => $number,
        score_mode => "(multiply|max|...)",
        boost_mode => "(multiply|replace|...)",
        min_score => $number
    }

C<score_mode> can have the following values:

=over 4

=item * C<multiply>

Scores are multiplied (default)

=item * C<sum>

Scores are summed

=item * C<avg>

Scores are averaged

=item * C<first>

The first function that has a matching filter is applied

=item * C<max>

Maximum score is used

=item * C<min>

Minimum score is used 

=back

C<boost_mode> can have the following values:

=over 4

=item * C<multiply>

Query score and function score is multiplied (default)

=item * C<replace>

Only function score is used, the query score is ignored

=item * C<sum>

Query score and function score are added

=item * C<avg>

Average

=item * C<max>

Max of query score and function score

=item * C<min>

Min of query score and function score 

=back

To exclude documents that do not meet a certain score threshold the C<min_score> parameter can be set to the desired score threshold.

See the L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-function-score-query.html> for the list of functions that can be used.

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-function-score-query.html#query-dsl-function-score-query> for more information.

=head2 Boosting Query

As per the Elastic Search documentation, the "C<boosting> query can be used to effectively demote results that match a given query. Unlike the "NOT" clause in C<bool> query, this still selects documents that contain undesirable terms, but reduces their overall score".

    {
        boosting => {
            positive => {
                term => {
                    field1 => "value1",
                },
            },
            negative => {
                term => {
                    field2 => "value2",
                },
            },
            negative_boost => 0.2,
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-boosting-query.html#query-dsl-boosting-query> for more information.

=head2 Indices Query

    {
        indices => {
            indices => [qw( index1 index2 )],
            query => {
                term => { tag => "wow" }
            },
            no_match_query => {
                term => { tag => "kow" }
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-indices-query.html#query-dsl-indices-query> for more information.

=head2 Joining Queries

Elastic Search provides 2 types of joins that are "designed to scale horizontally": C<nested> and L<has_child|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-has-child-query.html#query-dsl-has-child-query> / L<has_parent|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-has-parent-query.html#query-dsl-has-parent-query>

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/joining-queries.html#joining-queries> for more information.

=head2 Nested Query

As per the Elastic Search documentation, the "C<nested> query allows to query nested objects / docs".

    {
        nested => {
            path => "obj1",
            score_mode => "avg",
            query => {
                bool => {
                    must => [
                        {
                            match => { "obj1.name" => "blue" }
                        },
                        {
                            range => { "obj1.count" => { gt => 5 } }
                        },
                    ]
                }
            }
        }
    }

The C<score_mode> allows to set how inner children matching affects scoring of parent. It defaults to C<avg>, but can be C<sum>, C<min>, C<max> and C<none>.

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-nested-query.html#query-dsl-nested-query> for more information.

=head2 Geo Queries

Elastic Search supports two types of geo data: C<geo_point> and L<geo_shape|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-geo-shape-query.html>

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/geo-queries.html#geo-queries> for more information.

=head2 Geo Bounding Box Query

A query allowing to filter hits based on a point location using a bounding box.

    {
        bool => {
            must => {
                match_all => {},
            },
            filter => {
                geo_bounding_box => {
                    "author.location" => {
                        top_left => {
                            lat => 40.73,
                            lon => -74.1,
                        },
                        # or, using an array reference [long, lat]
                        # top_left => [qw( -74.1 40.73 )],
                        # or, using a string "lat, long"
                        # top_left => "40.73, -74.1"
                        # or, using GeoHash:
                        # top_left => "dr5r9ydj2y73",
                        bottom_right => {
                            lat => 40.01,
                            lon => -71.12,
                        },
                        # or, using an array reference [long, lat]
                        # bottom_right => [qw( -71.12 40.01 )],
                        # or, using a string "lat, long"
                        # bottom_right => "40.01, -71.12",
                        # or, using GeoHash:
                        # bottom_right => "drj7teegpus6",
                    },
                    # Set to true to accept invalid latitude or longitude (default to false)
                    ignore_malformed => \1,
                }
            }
        }
    }

or, using L<vertices|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-geo-bounding-box-query.html#_vertices>

    {
        bool => {
            must => {
                match_all => {},
            },
            filter => {
                geo_bounding_box => {
                    "author.location" => {
                        top => -74.1,
                        left => 40.73,
                        bottom => -71.12,
                        right => 40.01,
                    },
                    # Set to true to accept invalid latitude or longitude (default to false)
                    ignore_malformed => \1,
                }
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-geo-bounding-box-query.html> for more information.

=head2 Geo Distance Query

As per the Elastic Search documentation, this "filters documents that include only hits that exists within a specific distance from a geo point."

    {
        bool => {
            must => {
                match_all => {},
            },
            filter => {
                geo_distance => {
                    distance => "200km",
                    "author.location" => {
                        lat => 40,
                        lon => -70,
                    }
                    # or, using an array reference [long, lat]
                    # "author.location" => [qw( -70 40 )],
                    # or, using a string "lat, long"
                    # "author.location" => "40, -70",
                    # or, using GeoHash
                    # "author.location" => "drm3btev3e86",
                }
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-geo-distance-query.html#query-dsl-geo-distance-query> for more information.

=head2 Geo Distance Range Query

As per the Elastic Search documentation, this "filters documents that exists within a range from a specific point".

    {
        bool => {
            must => {
                match_all => {}
            },
            filter => {
                geo_distance_range => {
                    from => "200km",
                    to => "400km",
                    2pin.location" : {
                        lat => 40,
                        lon => -70,
                    }
                }
            }
        }
    }

This supports the same geo point options as L</"Geo Distance Query">

It also "support the common parameters for range (C<lt>, C<lte>, C<gt>, C<gte>, C<from>, C<to>, C<include_upper> and C<include_lower>)."

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-geo-distance-range-query.html#query-dsl-geo-distance-range-query> for more information.

=head2 Geo Polygon Query

This allows "to include hits that only fall within a polygon of points".

    {
        bool => {
            query => {
                match_all => {}
            },
            filter => {
                geo_polygon => {
                    "person.location" => {
                        points => [
                            { lat => 40, lon => -70 },
                            { lat => 30, lon => -80 },
                            { lat => 20, lon => -90 }
                            # or, as an array [long, lat]
                            # [-70, 40],
                            # [-80, 30],
                            # [-90, 20],
                            # or, as a string "lat, long"
                            # "40, -70",
                            # "30, -80",
                            # "20, -90"
                            # or, as GeoHash
                            # "drn5x1g8cu2y",
                            # "30, -80",
                            # "20, -90"
                        ]
                    },
                    # Set to true to ignore invalid geo points (defaults to false)
                    ignore_malformed => \1,
                }
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-geo-polygon-query.html#query-dsl-geo-polygon-query> for more information.

=head2 GeoHash Cell Query

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-geohash-cell-query.html#query-dsl-geohash-cell-query> for more information.

=head2 More Like This Query

As per the Elastic Search documentation, the "More Like This Query (MLT Query) finds documents that are "like" a given set of documents".

"The simplest use case consists of asking for documents that are similar to a provided piece of text".

For example, querying for all module releases that have some text similar to "Application Programming Interface" in their "abstract" and in their "description" fields, limiting the number of selected terms to 12.

    {
        more_like_this => {
            fields => [qw( abstract description )],
            like => "Application Programming Interface",
            min_term_freq => 1,
            max_query_terms => 12,
            # optional
            # unlike => "Python",
            # Defaults to 30%
            # minimum_should_match => 2,
            # boost_terms => 1,
            # Defaults to false
            # include => \1,
            # Defaults to 1.0
            # boost => 1.12
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-mlt-query.html#query-dsl-mlt-query> for more information.

=head2 Template Query

As per the Elastic Search documentation, this "accepts a query template and a map of key/value pairs to fill in template parameters".

    {
        query => {
            template => {
                inline => { match => { text => "{{query_string}}" }},
                params => {
                    query_string => "all about search",
                }
            }
        }
    }

would be translated to:

    {
        query => {
            match => {
                text => "all about search",
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-template-query.html#query-dsl-template-query> for more information.

=head2 Script Query

As per the Elastic Search documentation, this is used "to define scripts as queries. They are typically used in a filter context". for example:

    bool => {
        must => {
            # query details goes here
            # ...
        },
        filter => {
            script => {
                script => "doc['num1'].value > 1"
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-script-query.html#query-dsl-script-query> for more information.

=head2 Span Term Query

As per the Elastic Search documentation, this matches "spans containing a term".

    {
        span_term => { pauseid => "momotaro" }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-span-term-query.html#query-dsl-span-term-query> for more information.

=head2 Span Multi Terms Query

The C<span_multi> query allows you to wrap a multi term query (one of C<wildcard>, C<fuzzy>, C<prefix>, C<term>, C<range> or C<regexp> query) as a C<span> query, so it can be nested.

    {
        span_multi => {
            match => {
                prefix => { pauseid => { value => "momo" } }
            }
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-span-multi-term-query.html#query-dsl-span-multi-term-query> for more information.

=head2 Span First Query

As per the Elastic Search documentation, this matches "spans near the beginning of a field".

    {
        span_first => {
            match => {
                span_term => { pauseid => "momotaro" }
            },
            end => 3,
        }
    }

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-span-first-query.html#query-dsl-span-first-query> for more information.

=head2 Span Near Query

As per the Elastic Search documentation, this matches "spans which are near one another. One can specify slop, the maximum number of intervening unmatched positions, as well as whether matches are required to be in-order".

    {
        span_near => {
            clauses => [
                { span_term => { field => "value1" } },
                { span_term => { field => "value2" } },
                { span_term => { field => "value3" } },
            ],
            collect_payloads => \0,
            in_order => \0,
            slop => 12,
        },
    }

The C<clauses> element is a list of one or more other span type queries and the C<slop> controls the maximum number of intervening unmatched positions permitted.

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-span-near-query.html#query-dsl-span-near-query> for more information.

=head2 Span Or Query

As per the Elastic Search documentation, this matches "the union of its span clauses".

    {
        span_or => {
            clauses => [
                { span_term => { field => "value1" } },
                { span_term => { field => "value2" } },
                { span_term => { field => "value3" } },
            ],
        },
    }

The C<clauses> element is a list of one or more other span type queries

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-span-or-query.html#query-dsl-span-or-query> for more information.

=head2 Span Not Query

As per the Elastic Search documentation, this removes "matches which overlap with another span query".

    {
        span_not => {
            exclude => {
                span_near => {
                    clauses => [
                        { span_term => { field1 => "la" } },
                        { span_term => { field1 => "hoya" } },
                    ],
                    in_order => \1,
                    slop => 0,
                },
            },
            include => { span_term => { field1 => "hoya" } },
        },
    }

The C<include> and C<exclude> clauses can be any span type query.

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-span-not-query.html#query-dsl-span-not-query> for more information.

=head2 Span Containing Query

As per the Elastic Search documentation, this returns "matches which enclose another span query".

    {
        span_containing => {
            big => {
                span_near => {
                    clauses => [
                        { span_term => { field1 => "bar" } },
                        { span_term => { field1 => "baz" } },
                    ],
                    in_order => \1,
                    slop => 5,
                },
            },
            little => { span_term => { field1 => "foo" } },
        },
    }

The C<big> and C<little> clauses can be any C<span> type query. Matching spans from C<big> that contain matches from C<little> are returned.

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-span-containing-query.html#query-dsl-span-containing-query> for more information.

=head2 Span Within a Query

As per the Elastic Search documentation, this returns "matches which are enclosed inside another span query".

    {
        span_within => {
            big => {
                span_near => {
                    clauses => [
                        { span_term => { field1 => "bar" } },
                        { span_term => { field1 => "baz" } },
                    ],
                    in_order => \1,
                    slop => 5,
                },
            },
            little => { span_term => { field1 => "foo" } },
        },
    }

The C<big> and C<little> clauses can be any C<span> type query. Matching spans from C<little> that are enclosed within C<big> are returned.

See L<Elastic Search documentation|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-span-within-query.html#query-dsl-span-within-query> for more information.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::CPAN::Scroll>, L<Net::API::CPAN::List>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
