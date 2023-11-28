##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN.pm
## Version v0.1.4
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/07/25
## Modified 2023/11/24
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::CPAN;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $UA_OPTS $TYPE2CLASS $MODULE_RE );
    use HTTP::Promise;
    use HTTP::Promise::Headers;
    use JSON;
    use constant 
    {
        API_URI => 'https://fastapi.metacpan.org',
        METACPAN_CLIENTINFO_URI => 'https://clientinfo.metacpan.org',
    };
    our $MODULE_RE = qr/[a-zA-Z_][a-zA-Z0-9_]+(?:\:{2}[a-zA-Z0-9_]+)*/;
    our $VERSION = 'v0.1.4';
};

use strict;
use warnings;

our $UA_OPTS =
{
    agent => "MetaCPAN API Client/$VERSION",
    auto_switch_https => 1,
    default_headers => HTTP::Promise::Headers->new(
        Accept => 'application/json,text/html,application/xhtml+xml;q=0.9,*/*;q=0.8',
    ),
    ext_vary => 1,
    max_body_in_memory_size => 102400,
    timeout => 15,
    use_promise => 0,
};

our $TYPE2CLASS =
{
    activity => 'Net::API::CPAN::Activity',
    author => 'Net::API::CPAN::Author',
    changes => 'Net::API::CPAN::Changes',
    changes_release => 'Net::API::CPAN::Changes::Release',
    contributor => 'Net::API::CPAN::Contributor',
    cover => 'Net::API::CPAN::Cover',
    diff => 'Net::API::CPAN::Diff',
    distribution => 'Net::API::CPAN::Distribution',
    download_url => 'Net::API::CPAN::DownloadUrl',
    favorite => 'Net::API::CPAN::Favorite',
    file => 'Net::API::CPAN::File',
    list_web => 'Net::API::CPAN::List::Web',
    list => 'Net::API::CPAN::List',
    mirror => 'Net::API::CPAN::Mirror',
    mirrors => 'Net::API::CPAN::Mirrors',
    module => 'Net::API::CPAN::Module',
    package => 'Net::API::CPAN::Package',
    permission => 'Net::API::CPAN::Permission',
    # pod => 'Net::API::CPAN::Pod',
    rating => 'Net::API::CPAN::Rating',
    release => 'Net::API::CPAN::Release',
    release_recent => 'Net::API::CPAN::Release::Recent',
    release_suggest => 'Net::API::CPAN::Release::Suggest',
};

sub init
{
    my $self = shift( @_ );
    $self->{api_version}    = 1 unless( CORE::exists( $self->{api_version} ) );
    $self->{cache_file}     = undef unless( CORE::exists( $self->{cache_file} ) );
    $self->{ua}             = undef unless( CORE::exists( $self->{ua} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'Net::API::CPAN::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    unless( CORE::exists( $self->{ua} ) && $self->_is_a( $self->{ua} => 'HTTP::Promise' ) )
    {
        $self->{ua} = HTTP::Promise->new( %$UA_OPTS, debug => $self->debug ) || 
            return( $self->pass_error( HTTP::Promise->error ) );
        
    }
    $self->{api_version} = 1 unless( $self->{api_version} =~ /^\d+$/ );
    unless( $self->{api_uri} )
    {
        $self->api_uri( API_URI . '/v' . $self->{api_version} );
    }
    return( $self );
}

sub activity
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( exists( $opts->{author} ) && length( $opts->{author} // '' ) )
    {
        return( $self->fetch( 'activity' => {
            endpoint => "/activity",
            class => $self->_object_type_to_class( 'activity' ),
            query => {
                author => uc( $opts->{author} ),
                ( exists( $opts->{interval} ) ? ( res => $opts->{interval} ) : () ),
                ( exists( $opts->{new} ) ? ( new_dists => 'n' ) : () ),
            },
        }) );
    }
    if( exists( $opts->{distribution} ) && length( $opts->{distribution} // '' ) )
    {
        return( $self->fetch( 'activity' => {
            endpoint => "/activity",
            class => $self->_object_type_to_class( 'activity' ),
            query => {
                distribution => $opts->{distribution},
                ( exists( $opts->{interval} ) ? ( res => $opts->{interval} ) : () ),
            },
        }) );
    }
    elsif( exists( $opts->{module} ) && length( $opts->{module} // '' ) )
    {
        return( $self->fetch( 'activity' => {
            endpoint => "/activity",
            class => $self->_object_type_to_class( 'activity' ),
            query => {
                module => $opts->{module},
                ( exists( $opts->{interval} ) ? ( res => $opts->{interval} ) : () ),
                ( exists( $opts->{new} ) ? ( new_dists => 'n' ) : () ),
            },
        }) );
    }
    elsif( exists( $opts->{new} ) )
    {
        return( $self->fetch( 'activity' => {
            endpoint => "/activity",
            class => $self->_object_type_to_class( 'activity' ),
            query => {
                new_dists => 'n',
                ( exists( $opts->{interval} ) ? ( res => $opts->{interval} ) : () ),
            },
        }) );
    }
    else
    {
        return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
    }
}

sub api_uri { return( shift->_set_get_uri( 'api_uri', @_ ) ); }

sub api_version { return( shift->_set_get_scalar_as_object( 'api_version', @_ ) ); }

sub author
{
    my $self = shift( @_ );
    my( $author, $authors, $filter, $opts );
    if( @_ )
    {
        if( scalar( @_ ) == 1 &&
            $self->_is_array( $_[0] ) )
        {
            $authors = shift( @_ );
            return( $self->fetch( author => {
                endpoint => "/author/by_ids",
                class => $self->_object_type_to_class( 'list' ),
                query => { id => [@$authors] },
            }) );
        }
        elsif( scalar( @_ ) == 1 &&
            $self->_is_a( $_[0] => 'Net::API::CPAN::Filter' ) )
        {
            $filter = shift( @_ );
            my $payload = $filter->as_json( encoding => 'utf8' ) ||
                return( $self->pass_error( $filter->error ) );
            return( $self->fetch( author => {
                endpoint => "/author",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    filter => $filter,
                },
                method => 'post',
                payload => $payload,
            }) );
        }
        elsif( scalar( @_ ) == 1 &&
            ( !ref( $_[0] ) || ( ref( $_[0] ) && overload::Method( $_[0] => '""' ) ) ) )
        {
            $author = uc( shift( @_ ) );
            return( $self->fetch( author => {
                endpoint => "/author/${author}",
                class => $self->_object_type_to_class( 'author' ),
            }) );
        }
        else
        {
            $opts = $self->_get_args_as_hash( @_ );
            if( exists( $opts->{query} ) )
            {
                return( $self->fetch( author => {
                    endpoint => "/author",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        'q' => $opts->{query},
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    }
                }) );
            }
            elsif( exists( $opts->{prefix} ) )
            {
                return( $self->fetch( author => {
                    endpoint => "/author/by_prefix/" . $opts->{prefix},
                    class => $self->_object_type_to_class( 'list' ),
                }) );
            }
            elsif( exists( $opts->{user} ) )
            {
                my $users = $self->_is_array( $opts->{user} ) ? $opts->{user} : [$opts->{user}];
                if( scalar( @$users ) > 1 )
                {
                    return( $self->fetch( author => {
                        endpoint => "/author/by_user",
                        class => $self->_object_type_to_class( 'list' ),
                        query => {
                            user => [@$users],
                        },
                    }) );
                }
                elsif( scalar( @$users ) )
                {
                    return( $self->fetch( author => {
                        endpoint => "/author/by_user/" . $users->[0],
                        class => $self->_object_type_to_class( 'list' ),
                    }) );
                }
                else
                {
                    return( $self->error( "No user ID was provided." ) );
                }
            }
            else
            {
                return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
            }
        }
    }
    else
    {
        return( $self->fetch( 'author' => {
            endpoint => "/author",
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
}

sub autocomplete
{
    my $self = shift( @_ );
    my $term = shift( @_ );
    return( $self->error( "No search term was provided." ) ) if( $self->_is_empty( $term ) );
    return( $self->fetch( 'file' => {
        endpoint => "/search/autocomplete",
        class => $self->_object_type_to_class( 'list' ),
        query => {
            'q' => $term,
        },
        # The data returned by the API, although containing module information, are not formatted like we expect it to be, so we set this callback to correct that, so that Net::API::CPAN::List->load_data() is happy
        list_preprocess => sub
        {
            my $ref = shift( @_ ) || 
                die( "No autcomplete data was provided to preprocess.\n" );
            if( defined( $ref ) && 
                ref( $ref ) eq 'HASH' &&
                exists( $ref->{hits} ) &&
                ref( $ref->{hits} ) eq 'HASH' &&
                exists( $ref->{hits}->{hits} ) &&
                ref( $ref->{hits}->{hits} ) eq 'ARRAY' )
            {
                # For each entry, there is one element called 'fields' containing the properties distribution, documentation, release and author. We rename that element 'fields' to '_source' to standardise.
                for( my $i = 0; $i < scalar( @{$ref->{hits}->{hits}} ); $i++ )
                {
                    my $this = $ref->{hits}->{hits}->[$i];
                    # $self->message( 5, "Processing data at offset $i -> ", sub{ $self->Module::Generic::dump( $this ) } );
                    if( ref( $this ) eq 'HASH' &&
                        exists( $this->{fields} ) &&
                        ref( $this->{fields} ) eq 'HASH' )
                    {
                        $this->{_source} = delete( $this->{fields} );
                        $ref->{hits}->{hits}->[$i] = $this;
                    }
                    else
                    {
                        warn( "Warning only: I was expecting the property 'fields' to be present for this autocomplete data at offset $i, but could not find it, or it is not an HASH reference: ", $self->Module::Generic::dump( $this ) ) if( $self->_is_warnings_enabled );
                    }
                }
            }
            else
            {
                warn( "Warning only: autocomplete data provided for preprocessing is not an hash reference or does not contains the property path hits->hits as an array: ", $self->Module::Generic::dump( $ref ) ) if( $self->_is_warnings_enabled );
            }
            return( $ref );
        },
    }) );
}

sub cache_file { return( shift->_set_get_file( 'cache_file', @_ ) ); }

sub changes
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( exists( $opts->{distribution} ) )
    {
        return( $self->error( "Distribution provided is empty." ) ) if( $self->_is_empty( $opts->{distribution} ) );
        return( $self->fetch( changes => {
            endpoint => "/changes/" . $opts->{distribution},
            class => $self->_object_type_to_class( 'changes' ),
        }) );
    }
    elsif( exists( $opts->{author} ) && exists( $opts->{release} ) )
    {
        if( $self->_is_array( $opts->{author} ) &&
            $self->_is_array( $opts->{release} ) )
        {
            if( scalar( @{$opts->{author}} ) != scalar( @{$opts->{release} } ) )
            {
                return( $self->error( "The size of the array for author (", scalar( @{$opts->{author}} ), ") is not the same as the size of the array for release (", scalar( @{$opts->{release}} ), ")." ) );
            }
            my $n = -1;
            return( $self->fetch( changes_release => {
                endpoint => "/changes/by_releases",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    pageable => 0,
                },
                query => {
                    release => [map( join( '/', $opts->{author}->[++$n],$opts->{release}->[$n] ), @{$opts->{author}} )],
                }
            }) );
        }
        else
        {
            if( $self->_is_empty( $opts->{author} ) )
            {
                return( $self->error( "Author provided is empty." ) );
            }
            elsif( $self->_is_empty( $opts->{release} ) )
            {
                return( $self->error( "Release provided is empty." ) );
            }
            return( $self->fetch( changes => {
                endpoint => "/changes/" . $opts->{author} . '/' . $opts->{release},
                class => $self->_object_type_to_class( 'changes' ),
            }) );
        }
    }
    # Example: OALDERS/HTTP-Message-6.36
    # or
    # [qw( OALDERS/HTTP-Message-6.36 NEILB/Data-HexDump-0.04 )]
    elsif( exists( $opts->{release} ) &&
        defined( $opts->{release} ) )
    {
        if( $self->_is_array( $opts->{release} ) )
        {
            return( $self->fetch( changes_release => {
                endpoint => "/changes/by_releases",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    pageable => 0,
                },
                query => {
                    release => [@{$opts->{release}}],
                }
            }) );
        }
        else
        {
            return( $self->fetch( changes => {
                endpoint => "/changes/" . $opts->{release},
                class => $self->_object_type_to_class( 'changes' ),
            }) );
        }
    }
    else
    {
        return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
    }
}

# HTTP request returns something like this:
# {
# 	"production": {
# 		"version": "v1",
#       "domain": "https://fastapi.metacpan.org/",
# 		"url": "https://fastapi.metacpan.org/v1/"
# 	},
# 	"future": {
# 		"version": "v1",
#       "domain": "https://fastapi.metacpan.org/",
# 		"url": "https://fastapi.metacpan.org/v1/"
# 	},
# 	"testing": {
# 		"version": "v1",
#       "domain": "https://fastapi.metacpan.org/",
# 		"url": "https://fastapi.metacpan.org/v1/"
# 	}
# }
sub clientinfo
{
    my $self = shift( @_ );
    return( $self->{_cached_clientinfo} ) if( exists( $self->{_cached_clientinfo} ) && defined( $self->{_cached_clientinfo} ) );
    my $resp = $self->ua->get( METACPAN_CLIENTINFO_URI );
    my $info = {};
    if( $resp->is_success )
    {
        my $payload = $resp->decoded_content_utf8;
        my $j = $self->new_json;
        local $@;
        # try-catch
        eval
        {
            $info = $j->decode( $payload );
        };
        if( $@ )
        {
            warn( "Warning only: error decoding the JSON payload returned by the MetaCPAN API: $@" ) if( $self->_is_warnings_enabled );
        }
    }
    
    unless( scalar( keys( %$info ) ) )
    {
        $info = 
        {
            production =>
            {
            domain => API_URI,
            url => API_URI,
            }
        };
    }
    
    foreach my $stage ( keys( %$info ) )
    {
        foreach my $prop ( keys( %{$info->{ $stage }} ) )
        {
            if( defined( $info->{ $stage }->{ $prop } ) && 
                length( $info->{ $stage }->{ $prop } ) && 
                lc( substr( $info->{ $stage }->{ $prop }, 0, 4 ) ) eq 'http' )
            {
                $info->{ $stage }->{ $prop } = URI->new( $info->{ $stage }->{ $prop } );
            }
        }
    }
    $self->{_cached_clientinfo} = $info;
    return( $info );
}

sub contributor
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( exists( $opts->{author} ) &&
        exists( $opts->{release} ) )
    {
        if( $self->_is_empty( $opts->{author} ) )
        {
            return( $self->error( "Author provided is empty." ) );
        }
        elsif( $self->_is_empty( $opts->{release} ) )
        {
            return( $self->error( "Release provided is empty." ) );
        }
        return( $self->fetch( contributor => {
            endpoint => "/contributor/" . $opts->{author} . '/' . $opts->{release},
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
    elsif( exists( $opts->{author} ) )
    {
        if( $self->_is_empty( $opts->{author} ) )
        {
            return( $self->error( "Author provided is empty." ) );
        }
        return( $self->fetch( contributor => {
            endpoint => "/contributor/by_pauseid/" . $opts->{author},
            class => $self->_object_type_to_class( 'list' ),
            args => {
                pageable => 0,
            },
        }) );
    }
    else
    {
        return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
    }
}

sub cover
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( exists( $opts->{release} ) )
    {
        if( $self->_is_empty( $opts->{release} ) )
        {
            return( $self->error( "Release provided is empty." ) );
        }
        return( $self->fetch( cover => {
            endpoint => "/cover/" . $opts->{release},
            class => $self->_object_type_to_class( 'cover' ),
        }) );
    }
    else
    {
        return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
    }
}

sub diff
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $type = ( exists( $opts->{accept} ) ? $opts->{accept} : 'application/json' );
    if( exists( $opts->{file1} ) &&
        exists( $opts->{file2} ) )
    {
        if( $self->_is_empty( $opts->{file1} ) )
        {
            return( $self->error( "File1 provided is empty." ) );
        }
        elsif( $self->_is_empty( $opts->{file2} ) )
        {
            return( $self->error( "File2 provided is empty." ) );
        }
        return( $self->fetch( diff => {
            endpoint => "/diff/file/" . join( '/', @$opts{qw( file1 file2 )} ),
            class => ( $type eq 'text/plain' ? sub{$_[0]} : $self->_object_type_to_class( 'diff' ) ),
            headers => [Accept => $type],
            # The MetaCPAN REST API recognise the Accept header only with the POST method,
            # not the GET method, amazingly enough
            # See <https://github.com/metacpan/metacpan-api/blob/master/lib/MetaCPAN/Server/Controller/Diff.pm> 
            # and Catalyst::TraitFor::Request::REST for more details on this.
            method => 'post',
        }) );
    }
    elsif( exists( $opts->{author1} ) &&
        exists( $opts->{release1} ) &&
        exists( $opts->{release2} ) )
    {
        $opts->{author2} //= $opts->{author1};
        foreach my $t ( qw( author1 author2 release1 release2 ) )
        {
            return( $self->error( "$t option provided is empty" ) ) if( $self->_is_empty( $opts->{ $t } ) );
        }
        return( $self->fetch( diff => {
            endpoint => "/diff/release/" . join( '/', @$opts{qw( author1 release1 author2 release2 )} ),
            class => ( $type eq 'text/plain' ? sub{$_[0]} : $self->_object_type_to_class( 'diff' ) ),
            headers => [Accept => $type],
            # The MetaCPAN REST API recognise the Accept header only with the POST method,
            # not the GET method, amazingly enough
            # See <https://github.com/metacpan/metacpan-api/blob/master/lib/MetaCPAN/Server/Controller/Diff.pm> 
            # and Catalyst::TraitFor::Request::REST for more details on this.
            method => 'post',
        }) );
    }
    elsif( exists( $opts->{distribution} ) )
    {
        return( $self->error( "Distribution provided is empty." ) ) if( $self->_is_empty( $opts->{distribution} ) );
        return( $self->fetch( diff => {
            endpoint => "/diff/release/" . $opts->{distribution},
            class => ( $type eq 'text/plain' ? sub{$_[0]} : $self->_object_type_to_class( 'diff' ) ),
            headers => [Accept => $type],
            # The MetaCPAN REST API recognise the Accept header only with the POST method,
            # not the GET method, amazingly enough
            # See <https://github.com/metacpan/metacpan-api/blob/master/lib/MetaCPAN/Server/Controller/Diff.pm> 
            # and Catalyst::TraitFor::Request::REST for more details on this.
            method => 'post',
        }) );
    }
    else
    {
        return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
    }
}

sub distribution
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $dist, $filter, $opts );
        if( scalar( @_ ) == 1 &&
            ( !ref( $_[0] ) || ( ref( $_[0] ) && overload::Method( $_[0] => '""' ) ) ) )
        {
            $dist = shift( @_ );
            return( $self->fetch( distribution => {
                endpoint => "/distribution/${dist}",
                class => $self->_object_type_to_class( 'distribution' ),
            }) );
        }
        elsif( scalar( @_ ) == 1 &&
            $self->_is_a( $_[0] => 'Net::API::CPAN::Filter' ) )
        {
            $filter = shift( @_ );
            my $payload = $filter->as_json( encoding => 'utf8' ) ||
                return( $self->pass_error( $filter->error ) );
            return( $self->fetch( distribution => {
                endpoint => "/distribution",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    filter => $filter,
                },
                method => 'post',
                payload => $payload,
            }) );
        }
        else
        {
            $opts = $self->_get_args_as_hash( @_ );
            if( exists( $opts->{query} ) )
            {
                return( $self->fetch( distribution => {
                    endpoint => "/distribution",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        'q' => $opts->{query},
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    }
                }) );
            }
            else
            {
                return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
            }
        }
    }
    else
    {
        return( $self->fetch( distribution => {
            endpoint => "/distribution",
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
}

sub download_url
{
    my $self = shift( @_ );
    my $mod = shift( @_ ) ||
        return( $self->error( "No module provided to retrieve its download URL." ) );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->fetch( download_url => {
        endpoint => "/download_url/" . $mod,
        class => $self->_object_type_to_class( 'download_url' ),
        query => {
            ( $opts->{dev} ? ( dev => 1 ) : () ),
            ( $opts->{version} ? ( version => $opts->{version} ) : () ),
        },
    }) );
}

sub favorite
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $filter, $opts );
        if( scalar( @_ ) == 1 &&
            $self->_is_a( $_[0] => 'Net::API::CPAN::Filter' ) )
        {
            $filter = shift( @_ );
            my $payload = $filter->as_json( encoding => 'utf8' ) ||
                return( $self->pass_error( $filter->error ) );
            return( $self->fetch( favorite => {
                endpoint => "/favorite",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    filter => $filter,
                },
                method => 'post',
                payload => $payload,
            }) );
        }
        else
        {
            $opts = $self->_get_args_as_hash( @_ );
            if( exists( $opts->{query} ) )
            {
                return( $self->fetch( favorite => {
                    endpoint => "/favorite",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        'q' => $opts->{query},
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    }
                }) );
            }
            elsif( exists( $opts->{aggregate} ) ||
                exists( $opts->{agg} ) )
            {
                # $agg could be a distribution or an array reference of distributions
                my $agg = $opts->{aggregate} // $opts->{agg};
                return( $self->error( "Aggregate value provided is empty." ) ) if( $self->_is_empty( $agg ) );
                return( $self->fetch( favorite => {
                    endpoint => "/favorite/agg_by_distributions",
                    # class => $self->_object_type_to_class( 'list' ),
                    class => sub
                    {
                        my $ref = shift( @_ );
                        if( ref( $ref ) eq 'HASH' &&
                            exists( $ref->{favorites} ) &&
                            ref( $ref->{favorites} ) eq 'HASH' )
                        {
                            return( $ref->{favorites} );
                        }
                        # Return an empty hash for uniformity
                        return( {} );
                    },
                    query => { distribution => [@$agg] },
                }) );
            }
            elsif( exists( $opts->{distribution} ) )
            {
                return( $self->error( "Distribution value provided is empty." ) ) if( $self->_is_empty( $opts->{distribution} ) );
                return( $self->fetch( favorite => {
                    endpoint => "/favorite/users_by_distribution/" . $opts->{distribution},
                    # class => $self->_object_type_to_class( 'list' ),
                    class => sub
                    {
                        my $ref = shift( @_ );
                        if( ref( $ref ) eq 'HASH' &&
                            exists( $ref->{users} ) &&
                            ref( $ref->{users} ) eq 'ARRAY' )
                        {
                            return( $ref->{users} );
                        }
                        return( [] );
                    },
                }) );
            }
            elsif( exists( $opts->{user} ) )
            {
                return( $self->error( "User value provided is empty." ) ) if( $self->_is_empty( $opts->{user} ) );
                return( $self->fetch( favorite => {
                    endpoint => "/favorite/by_user/" . $opts->{user},
                    class => $self->_object_type_to_class( 'list' ),
                }) );
            }
            elsif( exists( $opts->{leaderboard} ) )
            {
                return( $self->fetch( favorite => {
                    endpoint => "/favorite/leaderboard",
                    # class => $self->_object_type_to_class( 'list' ),
                    class => sub
                    {
                        my $ref = shift( @_ );
                        my $data = [];
                        if( ref( $ref ) eq 'HASH' &&
                            exists( $ref->{leaderboard} ) &&
                            ref( $ref->{leaderboard} ) eq 'ARRAY' )
                        {
                            return( $ref->{leaderboard} );
                        }
                        # Return an empty array for uniformity
                        return( [] );
                    },
                }) );
            }
            elsif( exists( $opts->{recent} ) )
            {
                return( $self->fetch( favorite => {
                    endpoint => "/favorite/recent",
                    class => $self->_object_type_to_class( 'list' ),
                    args => {
                        page_type => 'page',
                    },
                }) );
            }
            else
            {
                return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
            }
        }
    }
    else
    {
        return( $self->fetch( 'favorite' => {
            endpoint => "/favorite",
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
}

sub fetch
{
    my $self = shift( @_ );
    my $type = shift( @_ ) || return( $self->error( "No object type was provided." ) );
    return( $self->error( "Object type contains illegal characters." ) ) if( $type !~ /^\w+$/ );
    my $opts = $self->_get_args_as_hash( @_ );
    # $self->message( 4, "Options received are: ", sub{ $self->dump( $opts ) } );
    my $class = $opts->{class} || $self->_object_type_to_class( $type ) ||
        return( $self->pass_error );
    my( $ep, $meth, $uri, $req );
    if( exists( $opts->{request} ) )
    {
        if( !$self->_is_a( $opts->{request} => 'HTTP::Promise::Request' ) )
        {
            return( $self->error( "Request provided is not an HTTP::Promise::Request object." ) );
        }
        $req = $opts->{request};
        $uri = $req->uri || return( $self->error( "No URI set in request object provided." ) );
        $meth = $req->method || return( $self->error( "No HTTP method set in request object provided." ) );
    }
    else
    {
        $ep = $opts->{endpoint} ||
            return( $self->error( "No endpoint was provided." ) );
        $meth = $opts->{method} // 'get';
        $uri = $self->api_uri->clone;
        $uri->path( $uri->path . ( substr( $ep, 0, 1 ) eq '/' ? '' : '/' ) . $ep );
    }
    my $ua = $self->ua || return( $self->error( "The User Agent object is gone!" ) );
    my $postprocess;
    if( $self->_is_code( $opts->{postprocess} ) )
    {
        $postprocess = $opts->{postprocess};
    }
    my( $headers, $payload, $query );
    if( exists( $opts->{headers} ) )
    {
        return( $self->error( "Headers option provided is not an array reference." ) ) if( !$self->_is_array( $opts->{headers} ) );
        $headers = $opts->{headers};
    }
    if( exists( $opts->{payload} ) )
    {
        $payload = $opts->{payload};
        if( ref( $payload ) eq 'HASH' )
        {
            local $@;
            # try-catch
            eval
            {
                $payload = $self->new_json->utf8->encode( $payload );
            };
            if( $@ )
            {
                return( $self->error( "Error encoding payload provided into JSON data: $@" ) );
            }
        }
        if( exists( $opts->{method} ) &&
            lc( $opts->{method} ) ne 'post' &&
            lc( $opts->{method} ) ne 'put' )
        {
            return( $self->error( "The HTTP method specified is '", $opts->{method}, "', but you specified also a payload, which requires either POST or PUT." ) );
        }
    }
    if( exists( $opts->{query} ) )
    {
        $query = $opts->{query};
    }

    my $resp;
    # If we are using a cache file for debugging purpose
    if( my $cache_file = $self->cache_file )
    {
        my $data = $cache_file->load( binmode => ':raw' ) ||
            return( $self->pass_error( $cache_file->error ) );
        $resp = HTTP::Promise::Response->new( 200, 'OK', [
            Connection => 'close',
            Server => 'local_cache',
            Content_Type => 'application/json; charset=utf-8',
            Cache_Control => 'private',
            Accept_Ranges => 'bytes',
            Date => HTTP::Promise->httpize_datetime( $cache_file->last_modified->clone ),
            # <https://developer.fastly.com/learning/concepts/shielding/#debugging>
            X_Cache => 'MISS, MISS',
            X_Cache_Hits => '0, 0',
        ], $data ) || return( $self->pass_error( HTTP::Promise::Response->error ) );
    }
    elsif( defined( $req ) )
    {
        if( defined( $headers ) )
        {
            # $req->headers->header( @$headers );
            for( my $i = 0; $i < scalar( @$headers ); $i += 2 )
            {
                $req->headers->replace( $headers->[$i] => $headers->[$i + 1] );
            }
        }
        
        if( defined( $query ) )
        {
            if( ref( $query ) eq 'HASH' || $self->_is_array( $query ) )
            {
                local $@;
                # try-catch
                eval
                {
                    $req->uri->query_form( $query );
                };
                if( $@ )
                {
                    return( $self->error( "Error while setting query form key-value pairs: $@" ) );
                };
            }
            elsif( !ref( $query ) || ( ref( $query ) && overload::Method( $query => '""' ) ) )
            {
                $req->uri->query( "$query" );
            }
        }
        
        if( defined( $payload ) )
        {
            $req->content( $payload ) ||
                return( $self->pass_error( $req->error ) );
            unless( $req->headers->exists( 'Content-Type' ) )
            {
                $req->headers->header( Content_Type => 'application/json' );
            }
        }
        $resp = $ua->request( $req ) ||
            return( $self->pass_error( $ua->error ) );
    }
    elsif( lc( $meth ) eq 'get' )
    {
        $resp = $ua->get( $uri, 
            # Headers
            ( defined( $headers ) ? @$headers : () ),
            ( defined( $query ) ? ( Query => $query ) : () ),
        )  || return( $self->pass_error( $ua->error ) );
    }
    elsif( lc( $meth ) eq 'post' )
    {
        if( defined( $payload ) &&
            defined( $headers ) && 
            !scalar( grep( /^Content[_-]Type$/i, @$headers ) ) )
        {
            push( @$headers, 'Content_Type', 'application/json' );
        }
        $resp = $ua->post( $uri,
            # Headers
            ( defined( $headers ) ? @$headers : () ),
            # Payload
            ( defined( $payload ) ? ( Content => $payload ) : () ),
        ) || return( $self->pass_error( $ua->error ) );
    }
    else
    {
        return( $self->error( "Invalid method provided. The API only supports GET or POST." ) );
    }

    if( $self->_is_a( $resp => 'HTTP::Promise::Exception' ) )
    {
        return( $self->pass_error( $resp ) );
    }
    $self->{http_request} = $resp->request;
    $self->{http_response} = $resp;
    
    my $data;
    if( $resp->is_success || $resp->is_redirect )
    {
        $self->message( 4, "Reponse headers are:\n", $resp->headers->as_string );
        $self->message( 4, "Getting decoded content." );
        my $content = $resp->decoded_content;
        if( $resp->headers->content_is_json )
        {
            $self->message( 3, "Request successful, decoding its JSON content '", $content, "'" );
            # decoded_content returns a scalar object, which we force into regular string, otherwise JSON complains it cannot parse it.
            local $@;
            # try-catch
            $data = eval
            {
                $self->new_json->utf8->decode( "${content}" );
            };
            if( $@ )
            {
                return( $self->error({
                    code => 500,
                    message => "An error occurred trying to decode MetaCPAN API response payload: $@",
                    cause => { payload => $content },
                }) );
            }
        }
        else
        {
            $self->message( 4, "Content returned is not JSON -> ", $resp->headers->type );
            $data = $content;
        }
        
        if( defined( $postprocess ) )
        {
            # try-catch
            local $@;
            $data = eval
            {
                $postprocess->( $data );
            };
            if( $@ )
            {
                return( $self->error( $@ ) );
            }
        }

        my $result;        
        if( ref( $class ) eq 'CODE' )
        {
            $self->message( 4, "Class is actually a code callback, executing it with ", ( length( $data ) // 0 ), " bytes of data -> ", substr( $data, 0, 255 ) );
            local $@;
            # try-catch
            $result = eval
            {
                $class->( $data );
            };
            $self->message( 5, "Value returned from callback is: ", substr( ( $result // 'undef' ), 0, 255 ) . ( length( $result ) > 255 ? '...' : '' ) );
            if( $@ )
            {
                return( $self->error({
                    code => 500,
                    message => "An error occurred calling the callback to process data received from the MetaCPAN REST API for object $type: $@",
                }) );
            }
            elsif( !defined( $result ) )
            {
                return( $self->pass_error );
            }
        }
        else
        {
            $self->message( 4, "Loading class '$class'" );
            $self->_load_class( $class ) || return( $self->error );
            $self->message( 4, "Instantiating new object for class '$class'" );
            # $self->message( 5, "Option 'list_preprocess' provided? -> ", ( exists( $opts->{list_preprocess} ) ? 'yes' : 'no' ) );
            $result = $class->new(
                debug => $self->debug,
                (
                    $class->isa( 'Net::API::CPAN::List' ) ? (
                        api => $self,
                        data => $data,
                        request => $resp->request,
                        type => $type,
                        # Used by autocomplete
                        ( ( exists( $opts->{list_preprocess} ) && ref( $opts->{list_preprocess} ) eq 'CODE' ) ? ( preprocess => $opts->{list_preprocess} ) : () ),
                        ( ( exists( $opts->{list_postprocess} ) && ref( $opts->{list_postprocess} ) eq 'CODE' ) ? ( postprocess => $opts->{list_postprocess} ) : () ),
                    ) : (),
                ),
                (
                    ( exists( $opts->{args} ) && ref( $opts->{args} ) eq 'HASH' ) ? ( %{$opts->{args}} ) : (),
                ),
            );
            unless( $class->isa( 'Net::API::CPAN::List' ) )
            {
                $self->message( 4, "Applying API data to new object '", overload::StrVal( $result ), "'" );
                $result->apply( $data ) || return( $self->pass_error( $result->error ) );
            }
        }
        return( $result );
    }
    else 
    {
        $self->messagef( 3, "Request failed with error %s", $resp->status );
        if( $resp->header( 'Content-Type' ) =~ m{text/html} ) 
        {
            return( $self->error({
                code    => $resp->code->scalar,
                type    => $resp->status->scalar,
                message => $resp->status->scalar
            }) );
        }
        elsif( $resp->headers->type =~ /json/i )
        {
            local $@;
            my $content = $resp->decoded_content;
            # try-catch
            eval
            {
                $data = $self->json->utf8->decode( "${content}" );
            };
            if( $@ )
            {
                return( $self->error({
                    code => 500,
                    message => "An error occurred trying to decode MetaCPAN API response payload: $@",
                    cause => { payload => $content },
                }) );
            }
            
            my $ref = {};
            if( exists( $data->{error} ) &&
                defined( $data->{error} ) )
            {
                if( ref( $data->{error} ) eq 'HASH' &&
                    exists( $data->{error}->{message} ) )
                {
                    $ref->{message} = $data->{error}->{message};
                    $ref->{code} = exists( $data->{error}->{code} )
                        ? $data->{error}->{code}
                        : $resp->code;
                }
                elsif( !ref( $data->{error} ) )
                {
                    $ref->{message} = $data->{error};
                    $ref->{code} = $resp->code;
                }
            }
            else
            {
                $ref = $data;
            }
            $ref->{cause} = { response => $resp, request => $resp->request };
            return( $self->error( $ref ) );
        }
        else
        {
            return( $self->error({
                code => $resp->code,
                message => $resp->status,
            }) );
        }
    }
}

sub file
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $filter, $opts );
        if( scalar( @_ ) == 1 &&
            $self->_is_a( $_[0] => 'Net::API::CPAN::Filter' ) )
        {
            $filter = shift( @_ );
            my $payload = $filter->as_json( encoding => 'utf8' ) ||
                return( $self->pass_error( $filter->error ) );
            return( $self->fetch( file => {
                endpoint => "/file",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    filter => $filter,
                },
                method => 'post',
                payload => $payload,
            }) );
        }
        else
        {
            $opts = $self->_get_args_as_hash( @_ );
            if( exists( $opts->{query} ) )
            {
                return( $self->fetch( favorite => {
                    endpoint => "/file",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        'q' => $opts->{query},
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    }
                }) );
            }
            elsif( exists( $opts->{author} ) &&
                exists( $opts->{release} ) &&
                exists( $opts->{dir} ) )
            {
                foreach my $t ( qw( author release dir ) )
                {
                    if( $self->_is_empty( $opts->{ $t } ) )
                    {
                        return( $self->error( "The $t value provided is empty." ) );
                    }
                }
                return( $self->fetch( file => {
                    endpoint => "/file/dir/" . join( '/', @$opts{qw( author release dir )} ),
                    class => $self->_object_type_to_class( 'list' ),
                    # We change the properties stat.mime and stat.size to an hash reference 
                    # stat { mime => 12345, size => 12345 }
                    postprocess => sub
                    {
                        my $ref = shift( @_ );
                        if( ref( $ref ) eq 'HASH' &&
                            exists( $ref->{dir} ) &&
                            ref( $ref->{dir} ) eq 'ARRAY' )
                        {
                            for( my $i = 0; $i < scalar( @{$ref->{dir}} ); $i++ )
                            {
                                my $this = $ref->{dir}->[$i];
                                if( defined( $this ) &&
                                    ref( $this ) eq 'HASH' )
                                {
                                    my @keys = grep( /^stat\.\w+$/, keys( %$this ) );
                                    if( scalar( @keys ) )
                                    {
                                        $this->{stat} = {};
                                        foreach my $f ( @keys )
                                        {
                                            my( $stat, $field ) = split( /\./, $f, 2 );
                                            $this->{stat}->{ $field } = CORE::delete( $this->{ $f } );
                                        }
                                    }
                                }
                                $ref->{dir}->[$i] = $this;
                            }
                        }
                        return( $ref );
                    },
                }) );
            }
            elsif( exists( $opts->{author} ) &&
                exists( $opts->{release} ) &&
                exists( $opts->{path} ) )
            {
                foreach my $t ( qw( author release path ) )
                {
                    if( $self->_is_empty( $opts->{ $t } ) )
                    {
                        return( $self->error( "The $t value provided is empty." ) );
                    }
                }
                return( $self->fetch( file => {
                    endpoint => "/file/" . join( '/', @$opts{qw( author release path )} ),
                    class => $self->_object_type_to_class( 'file' ),
                }) );
            }
            else
            {
                return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
            }
        }
    }
    else
    {
        return( $self->fetch( 'file' => {
            endpoint => "/file",
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
}

sub first
{
    my $self = shift( @_ );
    my $term = shift( @_ );
    return( $self->error( "No search term was provided." ) ) if( $self->_is_empty( $term ) );
    return( $self->fetch( 'search' => {
        endpoint => "/search/first",
        class => $self->_object_type_to_class( 'module' ),
        query => {
            'q' => $term,
        },
        postprocess => sub
        {
            my $ref = shift( @_ );
            if( exists( $ref->{ 'abstract.analyzed' } ) )
            {
                $ref->{abstract} = CORE::delete( $ref->{ 'abstract.analyzed' } );
            }
            return( $ref );
        },
    }) );
}

sub http_request { CORE::return( shift->_set_get_object_without_init( 'http_request', 'HTTP::Promise::Request', @_ ) ); }

sub http_response { CORE::return( shift->_set_get_object_without_init( 'http_response', 'HTTP::Promise::Response', @_ ) ); }

sub history
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $type = $opts->{type} || return( $self->error( "No history type was provided." ) );
    my $path = $opts->{path} || return( $self->error( "No path was provided." ) );
    if( $type !~ /^(?:module|file|documentation)$/ )
    {
        return( $self->error( "Invalid type provided ($type). This can only be either 'module', 'file' or 'documentation'." ) );
    }
    if( $type eq 'module' && exists( $opts->{module} ) )
    {
        return( $self->fetch( 'module' => {
            endpoint => "/search/history/module/" . join( '/', @$opts{qw( module path )} ),
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
    elsif( $type eq 'file' && exists( $opts->{distribution} ) )
    {
        return( $self->fetch( 'file' => {
            endpoint => "/search/history/file/" . join( '/', @$opts{qw( distribution path )} ),
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
    elsif( $type eq 'documentation' && exists( $opts->{module} ) )
    {
        return( $self->fetch( 'file' => {
            endpoint => "/search/history/documentation/" . join( '/', @$opts{qw( module path )} ),
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
    else
    {
        return( $self->error( "Unknonw options provided -> ", sub{ $self->Module::Generic::dump( $opts ) } ) );
    }
}

sub json
{
    my $self = shift( @_ );
    return( $self->{json} ) if( $self->{json} );
    $self->{json} = JSON->new->allow_nonref->allow_blessed->convert_blessed->relaxed;
    return( $self->{json} );
}

sub mirror
{
    my $self = shift( @_ );
    return( $self->fetch( 'mirror' => {
        endpoint => "/mirror",
        class => $self->_object_type_to_class( 'list' ),
    }) );
}

sub module
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $filter, $mod, $opts );
        if( scalar( @_ ) == 1 &&
            $self->_is_a( $_[0] => 'Net::API::CPAN::Filter' ) )
        {
            $filter = shift( @_ );
            my $payload = $filter->as_json( encoding => 'utf8' ) ||
                return( $self->pass_error( $filter->error ) );
            return( $self->fetch( module => {
                endpoint => "/module",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    filter => $filter,
                },
                method => 'post',
                payload => $payload,
            }) );
        }
        else
        {
            $opts = $self->_get_args_as_hash( @_ );
            if( exists( $opts->{query} ) )
            {
                return( $self->fetch( module => {
                    endpoint => "/module",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        'q' => $opts->{query},
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    }
                }) );
            }
            elsif( exists( $opts->{module} ) && 
                length( $opts->{module} // '' ) )
            {
                my $mod = $opts->{module};
                my $join;
                if( exists( $opts->{join} ) )
                {
                    $join = $self->_is_array( $opts->{join} )
                        ? [@{$opts->{join}}]
                        : length( $opts->{join} // '' )
                            ? [$opts->{join}]
                            : [];
                }
                return( $self->fetch( module => {
                    endpoint => "/module/${mod}",
                    class => $self->_object_type_to_class( 'module' ),
                    ( $join ? ( query => { join => $join } ) : () ),
                    postprocess => sub
                    {
                        my $ref = shift( @_ );
                        return( $ref ) if( !defined( $join ) );
                        return( $ref ) if( !defined( $ref ) || ref( $ref ) ne 'HASH' );
                        foreach my $t ( qw( author release ) )
                        {
                            if( exists( $ref->{ $t } ) &&
                                ref( $ref->{ $t } ) eq 'HASH' &&
                                exists( $ref->{ $t }->{_source} ) &&
                                ref( $ref->{ $t }->{_source} ) eq 'HASH' )
                            {
                                $ref->{ $t } = $ref->{ $t }->{_source};
                            }
                        }
                        return( $ref );
                    },
                }) );
            }
            else
            {
                return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
            }
        }
    }
    else
    {
        return( $self->fetch( 'module' => {
            endpoint => "/module",
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
}

sub new_filter
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $self->_load_class( 'Net::API::CPAN::Filter' ) || return( $self->pass_error );
    my $filter = Net::API::CPAN::Filter->new( %$opts, debug => $self->debug ) ||
        return( $self->pass_error( Net::API::CPAN::Filter->error ) );
    return( $filter );
}

sub package
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $filter, $mod, $opts );
        # Issue No 1136: some dataset contains the property version with string value of 'undef' in JSON instead of null
        # we check it and convert it here until this is fixed.
        # <https://github.com/metacpan/metacpan-api/issues/1136>
        my $postprocess = sub
        {
            my $ref = shift( @_ );
            if( ref( $ref ) eq 'HASH' &&
                exists( $ref->{hits} ) &&
                ref( $ref->{hits} ) eq 'HASH' &&
                exists( $ref->{hits}->{hits} ) &&
                ref( $ref->{hits}->{hits} ) eq 'ARRAY' )
            {
                for( my $i = 0; $i < scalar( @{$ref->{hits}->{hits}} ); $i++ )
                {
                    my $this = $ref->{hits}->{hits}->[$i];
                    if( defined( $this ) &&
                        ref( $this ) eq 'HASH' &&
                        exists( $this->{_source} ) &&
                        ref( $this->{_source} ) eq 'HASH' &&
                        exists( $this->{_source}->{version} ) &&
                        defined( $this->{_source}->{version} ) &&
                        $this->{_source}->{version} eq 'undef' )
                    {
                        $this->{_source}->{version} = undef;
                        $ref->{hits}->{hits}->[$i] = $this;
                    }
                }
            }
            return( $ref );
        };
        if( scalar( @_ ) == 1 &&
            $self->_is_a( $_[0] => 'Net::API::CPAN::Filter' ) )
        {
            $filter = shift( @_ );
            my $payload = $filter->as_json( encoding => 'utf8' ) ||
                return( $self->pass_error( $filter->error ) );
            return( $self->fetch( package => {
                endpoint => "/package",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    filter => $filter,
                },
                method => 'post',
                payload => $payload,
                postprocess => $postprocess,
            }) );
        }
        elsif( scalar( @_ ) == 1 &&
            ( !ref( $_[0] ) || ( ref( $_[0] ) && overload::Method( $_[0] => '""' ) ) ) )
        {
            $mod = shift( @_ );
            return( $self->fetch( package => {
                endpoint => "/package/${mod}",
                class => $self->_object_type_to_class( 'package' ),
            }) );
        }
        else
        {
            $opts = $self->_get_args_as_hash( @_ );
            if( exists( $opts->{query} ) )
            {
                return( $self->fetch( package => {
                    endpoint => "/package",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        'q' => $opts->{query},
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    },
                    postprocess => $postprocess,
                }) );
            }
            elsif( exists( $opts->{distribution} ) )
            {
                return( $self->error( "Value provided for distribution is empty." ) ) if( $self->_is_empty( $opts->{distribution} ) );
                return( $self->fetch( package => {
                    endpoint => "/package/modules/" . $opts->{distribution},
                    class => sub
                    {
                        my $ref = shift( @_ );
                        if( ref( $ref ) ne 'HASH' ||
                            ( ref( $ref ) eq 'HASH' && !exists( $ref->{modules} ) ) )
                        {
                            return( $self->error( "No \"modules\" property found in data returned by MetaCPAN REST API." ) );
                        }
                        elsif( ref( $ref->{modules} ) ne 'ARRAY' )
                        {
                            return( $self->error( "The \"modules\" property returned by the MetaCPAN REST API is not an array reference." ) );
                        }
                        return( $self->new_array( $ref->{modules} ) );
                    },
                }) );
            }
            else
            {
                return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
            }
        }
    }
    else
    {
        return( $self->fetch( 'package' => {
            endpoint => "/package",
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
}

sub permission
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $filter, $opts );
        if( scalar( @_ ) == 1 &&
            $self->_is_a( $_[0] => 'Net::API::CPAN::Filter' ) )
        {
            $filter = shift( @_ );
            my $payload = $filter->as_json( encoding => 'utf8' ) ||
                return( $self->pass_error( $filter->error ) );
            return( $self->fetch( permission => {
                endpoint => "/permission",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    filter => $filter,
                },
                method => 'post',
                payload => $payload,
            }) );
        }
        else
        {
            $opts = $self->_get_args_as_hash( @_ );
            if( exists( $opts->{query} ) )
            {
                return( $self->fetch( permission => {
                    endpoint => "/permission",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        'q' => $opts->{query},
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    }
                }) );
            }
            elsif( exists( $opts->{author} ) )
            {
                return( $self->error( "Value provided for author is empty." ) ) if( $self->_is_empty( $opts->{author} ) );
                return( $self->fetch( permission => {
                    endpoint => "/permission/by_author/" . $opts->{author},
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    }
                }) );
            }
            elsif( exists( $opts->{module} ) )
            {
                # This endpoint /permission/by_module can take a query string as used below, 
                # but can also take a module in its path, such as:
                # /permission/by_module/HTTP::Message
                # which returns the same data structure
                # Since it is identical to using q query string for 1 or more module, we do not use it.
                if( $self->_is_array( $opts->{module} ) )
                {
                    return( $self->fetch( 'permission' => {
                        endpoint => "/permission/by_module",
                        class => $self->_object_type_to_class( 'list' ),
                        query => {
                            module => [@{$opts->{module}}],
                        }
                    }) );
                }
                else
                {
                    return( $self->error( "Value provided for module is empty." ) ) if( $self->_is_empty( $opts->{module} ) );
                    return( $self->fetch( 'permission' => {
                        endpoint => "/permission/" . $opts->{module},
                        class => $self->_object_type_to_class( 'permission' ),
                    }) );
                }
            }
            else
            {
                return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
            }
        }
    }
    else
    {
        return( $self->fetch( 'permission' => {
            endpoint => "/permission",
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
}

sub pod
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !scalar( keys( %$opts ) ) )
    {
        return( $self->error( "No option was specified for pod." ) );
    }
    if( exists( $opts->{author} ) &&
        exists( $opts->{release} ) &&
        exists( $opts->{path} ) )
    {
        foreach my $t ( qw( author release path ) )
        {
            if( $self->_is_empty( $opts->{ $t } ) )
            {
                return( $self->error( "The $t value provided is empty." ) );
            }
        }
        $opts->{author} = uc( $opts->{author} );
        return( $self->fetch( 'pod' => {
            endpoint => "/pod/" . join( '/', @$opts{qw( author release path )} ),
            class => sub{$_[0]},
            (
                exists( $opts->{accept} ) ? ( headers => [Accept => $opts->{accept}] ) : ()
            ),
            # Because MetaCPAN API does not recognise the Accept header, even though it is coded that way, 
            # we must use this query string to be more explicit
            (
                exists( $opts->{accept} ) ? ( query => { content_type => $opts->{accept} } ) : ()
            ),
        }) );
    }
    elsif( exists( $opts->{module} ) )
    {
        if( $self->_is_empty( $opts->{module} ) )
        {
            return( $self->error( "Value provided for module is empty." ) );
        }
        elsif( !$self->_is_module( $opts->{module} ) )
        {
            return( $self->error( "Value provided for module ($opts->{module}) does not look like a module." ) );
        }
        return( $self->fetch( 'pod' => {
            endpoint => "/pod/" . $opts->{module},
            class => sub{$_[0]},
            (
                exists( $opts->{accept} ) ? ( headers => [Accept => $opts->{accept}] ) : ()
            ),
            # Because MetaCPAN API does not recognise the Accept header, even though it is coded that way, 
            # we must use this query string to be more explicit
            (
                exists( $opts->{accept} ) ? ( query => { content_type => $opts->{accept} } ) : ()
            ),
        }) );
    }
    elsif( exists( $opts->{render} ) )
    {
        if( $self->_is_empty( $opts->{render} ) )
        {
            return( $self->error( "Value provided for render is empty." ) );
        }
        return( $self->fetch( 'pod' => {
            endpoint => "/pod_render",
            class => sub{$_[0]},
            query => {
                pod => $opts->{render},
            },
        }) );
    }
    else
    {
        return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
    }
}

sub rating
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $filter, $opts );
        if( scalar( @_ ) == 1 &&
            $self->_is_a( $_[0] => 'Net::API::CPAN::Filter' ) )
        {
            $filter = shift( @_ );
            my $payload = $filter->as_json( encoding => 'utf8' ) ||
                return( $self->pass_error( $filter->error ) );
            return( $self->fetch( rating => {
                endpoint => "/rating",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    filter => $filter,
                },
                method => 'post',
                payload => $payload,
            }) );
        }
        else
        {
            $opts = $self->_get_args_as_hash( @_ );
            if( exists( $opts->{query} ) )
            {
                return( $self->fetch( rating => {
                    endpoint => "/rating",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        'q' => $opts->{query},
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    }
                }) );
            }
            elsif( exists( $opts->{distribution} ) )
            {
                return( $self->error( "Value provided for author is empty." ) ) if( $self->_is_empty( $opts->{author} ) );
                return( $self->fetch( rating => {
                    endpoint => "/rating/by_author",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        'q' => $opts->{author},
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    }
                }) );
            }
            elsif( exists( $opts->{distribution} ) )
            {
                my $dist = $self->_is_array( $opts->{distribution} ) ? [@{$opts->{distribution}}] : [$opts->{distribution}];
                return( $self->fetch( 'rating' => {
                    endpoint => "/rating/by_distributions",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        module => $dist,
                    }
                }) );
            }
            else
            {
                return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
            }
        }
    }
    else
    {
        return( $self->fetch( 'rating' => {
            endpoint => "/rating",
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
}

sub release
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $filter, $opts );
        if( scalar( @_ ) == 1 &&
            $self->_is_a( $_[0] => 'Net::API::CPAN::Filter' ) )
        {
            $filter = shift( @_ );
            my $payload = $filter->as_json( encoding => 'utf8' ) ||
                return( $self->pass_error( $filter->error ) );
            return( $self->fetch( release => {
                endpoint => "/release",
                class => $self->_object_type_to_class( 'list' ),
                args => {
                    filter => $filter,
                },
                method => 'post',
                payload => $payload,
            }) );
        }
        else
        {
            $opts = $self->_get_args_as_hash( @_ );
            # NOTE: release -> query
            if( exists( $opts->{query} ) )
            {
                return( $self->fetch( release => {
                    endpoint => "/release",
                    class => $self->_object_type_to_class( 'list' ),
                    query => {
                        'q' => $opts->{query},
                        ( exists( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    }
                }) );
            }
            # NOTE: release -> all AUTHOR
            elsif( exists( $opts->{all} ) )
            {
                return( $self->error( "Value provided for all is empty." ) ) if( $self->_is_empty( $opts->{all} ) );
                $opts->{all} = uc( $opts->{all} );
                return( $self->fetch( release => {
                    endpoint => "/release/all_by_author/" . $opts->{all},
                    class => $self->_object_type_to_class( 'list' ),
                    args => { page_type => 'page' },
                    # Bug No 1126, the parameters page and size are inverted. It was fixed, but the fix was reverted on 2023-09-08
                    # <https://github.com/metacpan/metacpan-api/issues/1126>
                    # <https://github.com/metacpan/metacpan-api/actions/runs/6115139953>
                    # Until this is finally fixed, we need to invert the parameters, weirdly enough
                    query => {
                        ( exists( $opts->{page} ) ? ( page => $opts->{page} ) : () ),
                        ( exists( $opts->{size} ) ? ( page_size => $opts->{size} ) : () ),
                    }
                }) );
            }
            # NOTE: release -> author, release, contributors
            elsif( exists( $opts->{author} ) &&
                exists( $opts->{release} ) &&
                exists( $opts->{contributors} ) )
            {
                return( $self->error( "Value provided for author is empty." ) ) if( $self->_is_empty( $opts->{author} ) );
                return( $self->error( "Value provided for release is empty." ) ) if( $self->_is_empty( $opts->{release} ) );
                $opts->{author} = uc( $opts->{author} );
                return( $self->fetch( 'author' => {
                    endpoint => "/release/contributors/" . join( '/', @$opts{qw( author release )} ),
                    class => $self->_object_type_to_class( 'list' ),
                }) );
            }
            # NOTE: release -> author, release, files
            elsif( exists( $opts->{author} ) &&
                exists( $opts->{release} ) &&
                exists( $opts->{files} ) )
            {
                return( $self->error( "Value provided for author is empty." ) ) if( $self->_is_empty( $opts->{author} ) );
                return( $self->error( "Value provided for release is empty." ) ) if( $self->_is_empty( $opts->{release} ) );
                $opts->{author} = uc( $opts->{author} );
                return( $self->fetch( 'release' => {
                    endpoint => "/release/files_by_category/" . join( '/', @$opts{qw( author release )} ),
                    class => sub{ $_[0] },
                }) );
            }
            # NOTE: release -> author, release, modules
            elsif( exists( $opts->{author} ) &&
                exists( $opts->{release} ) &&
                exists( $opts->{modules} ) )
            {
                return( $self->error( "Value provided for author is empty." ) ) if( $self->_is_empty( $opts->{author} ) );
                return( $self->error( "Value provided for release is empty." ) ) if( $self->_is_empty( $opts->{release} ) );
                $opts->{author} = uc( $opts->{author} );
                return( $self->fetch( 'file' => {
                    endpoint => "/release/modules/" . join( '/', @$opts{qw( author release )} ),
                    class => $self->_object_type_to_class( 'list' ),
                }) );
            }
            # NOTE: release -> author, release, interesting_files
            elsif( exists( $opts->{author} ) &&
                exists( $opts->{release} ) &&
                ( exists( $opts->{interesting_files} ) || exists( $opts->{interesting} ) ) )
            {
                return( $self->error( "Value provided for author is empty." ) ) if( $self->_is_empty( $opts->{author} ) );
                return( $self->error( "Value provided for release is empty." ) ) if( $self->_is_empty( $opts->{release} ) );
                $opts->{author} = uc( $opts->{author} );
                return( $self->fetch( 'file' => {
                    endpoint => "/release/interesting_files/" . join( '/', @$opts{qw( author release )} ),
                    class => $self->_object_type_to_class( 'list' ),
                }) );
            }
            # NOTE: release -> author, release
            elsif( exists( $opts->{author} ) &&
                exists( $opts->{release} ) )
            {
                return( $self->error( "Value provided for author is empty." ) ) if( $self->_is_empty( $opts->{author} ) );
                return( $self->error( "Value provided for release is empty." ) ) if( $self->_is_empty( $opts->{release} ) );
                $opts->{author} = uc( $opts->{author} );
                return( $self->fetch( 'release' => {
                    endpoint => "/release/" . join( '/', @$opts{qw( author release )} ),
                    class => $self->_object_type_to_class( 'release' ),
                    postprocess => sub
                    {
                        my $ref = shift( @_ );
                        if( exists( $ref->{release} ) &&
                            defined( $ref->{release} ) &&
                            ref( $ref->{release} ) eq 'HASH' )
                        {
                            return( $ref->{release} );
                        }
                        return( $ref );
                    },
                }) );
            }
            # NOTE: release -> author, latest
            elsif( exists( $opts->{author} ) &&
                exists( $opts->{latest} ) )
            {
                return( $self->error( "Value provided for author is empty." ) ) if( $self->_is_empty( $opts->{author} ) );
                $opts->{author} = uc( $opts->{author} );
                return( $self->fetch( 'release' => {
                    endpoint => "/release/latest_by_author/" . $opts->{author},
                    class => $self->_object_type_to_class( 'list' ),
                }) );
            }
            # NOTE: release -> distribution, latest
            elsif( exists( $opts->{distribution} ) &&
                exists( $opts->{latest} ) )
            {
                return( $self->error( "Value provided for distribution is empty." ) ) if( $self->_is_empty( $opts->{distribution} ) );
                return( $self->fetch( 'release' => {
                    endpoint => "/release/latest_by_distribution/" . $opts->{distribution},
                    class => $self->_object_type_to_class( 'release' ),
                    postprocess => sub
                    {
                        my $ref = shift( @_ );
                        if( exists( $ref->{release} ) &&
                            defined( $ref->{release} ) &&
                            ref( $ref->{release} ) eq 'HASH' )
                        {
                            return( $ref->{release} );
                        }
                        return( $ref );
                    },
                }) );
            }
            # NOTE: release -> distribution, versions
            elsif( exists( $opts->{distribution} ) &&
                exists( $opts->{versions} ) )
            {
                # return( $self->error( "Value provided for versions is empty." ) ) if( $self->_is_empty( $opts->{versions} ) );
                my $query;
                if( exists( $opts->{plain} ) &&
                    !$self->_is_empty( $opts->{plain} ) )
                {
                    $query = { plain => $opts->{plain} };
                }
                
                if( ( $self->_is_array( $opts->{versions} ) && scalar( @{$opts->{versions}} ) ) ||
                    ( defined( $opts->{versions} ) && length( "$opts->{versions}" ) ) )
                {
                    if( $self->_is_array( $opts->{versions} ) )
                    {
                        $query //= {};
                        $query->{versions} = join( ',', @{$opts->{versions}} );
                    }
                    else
                    {
                        $query //= {};
                        $query->{versions} = $opts->{versions};
                    }
                }
                
                return( $self->fetch( 'release' => {
                    endpoint => "/release/versions/" . $opts->{distribution},
                    (
                        defined( $query ) ? ( query => $query ) : (),
                    ),
                    # If the user wants the plain text data, we return it as-is, otherwise, we return a list object.
                    class => $opts->{plain} ? sub{$_[0]} : $self->_object_type_to_class( 'list' ),
                }) );
            }
            # NOTE: release -> author
            elsif( exists( $opts->{author} ) )
            {
                return( $self->error( "Value provided for author is empty." ) ) if( $self->_is_empty( $opts->{author} ) );
                $opts->{author} = uc( $opts->{author} );
                return( $self->fetch( release => {
                    endpoint => "/release/by_author/" . $opts->{author},
                    class => $self->_object_type_to_class( 'list' ),
                    args => { page_type => 'page' },
                    query => {
                        ( exists( $opts->{page} ) ? ( page => $opts->{page} ) : () ),
                        ( exists( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
                    },
                    postprocess => sub
                    {
                        my $ref = shift( @_ );
                        if( defined( $ref ) &&
                            ref( $ref ) eq 'HASH' &&
                            exists( $ref->{releases} ) &&
                            defined( $ref->{releases} ) &&
                            ref( $ref->{releases} ) eq 'ARRAY' )
                        {
                            for( my $i = 0; $i < scalar( @{$ref->{releases}} ); $i++ )
                            {
                                my $this = $ref->{releases}->[$i];
                                if( exists( $this->{metadata} ) )
                                {
                                    $this->{version} = $this->{metadata}->{version};
                                }
                            }
                        }
                        return( $ref );
                    },
                }) );
            }
            # NOTE: release -> distribution
            elsif( exists( $opts->{distribution} ) )
            {
                return( $self->error( "Value provided for distribution is empty." ) ) if( $self->_is_empty( $opts->{distribution} ) );
                $opts->{author} = uc( $opts->{author} );
                return( $self->fetch( 'release' => {
                    endpoint => "/release/" . $opts->{distribution},
                    class => $self->_object_type_to_class( 'release' ),
                }) );
            }
            # NOTE: release -> recent
            elsif( exists( $opts->{recent} ) )
            {
                return( $self->fetch( 'release' => {
                    endpoint => "/release/recent",
                    class => $self->_object_type_to_class( 'list' ),
                    args => { page_type => 'page' },
                    query => {
                        ( exists( $opts->{page} ) ? ( page => $opts->{page} ) : () ),
                        ( exists( $opts->{size} ) ? ( page_size => $opts->{size} ) : () ),
                    }
                }) );
            }
            else
            {
                return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
            }
        }
    }
    else
    {
        return( $self->fetch( 'release' => {
            endpoint => "/release",
            class => $self->_object_type_to_class( 'list' ),
        }) );
    }
}

sub reverse
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( exists( $opts->{distribution} ) && length( $opts->{distribution} // '' ) )
    {
        return( $self->fetch( 'release' => {
            endpoint => "/reverse_dependencies/dist/" . $opts->{distribution},
            class => $self->_object_type_to_class( 'list' ),
            query => {
                ( exists( $opts->{page} ) ? ( page => $opts->{page} ) : () ),
                # How many elements returned per page
                ( exists( $opts->{size} ) ? ( page_size => $opts->{size} ) : () ),
                ( exists( $opts->{sort} ) ? ( sort => $opts->{sort} ) : () ),
            },
        }) );
    }
    elsif( exists( $opts->{module} ) && length( $opts->{module} // '' ) )
    {
        return( $self->fetch( 'release' => {
            endpoint => "/reverse_dependencies/module/" . $opts->{module},
            class => $self->_object_type_to_class( 'list' ),
            query => {
                ( exists( $opts->{page} ) ? ( page => $opts->{page} ) : () ),
                # How many elements returned per page
                ( exists( $opts->{size} ) ? ( page_size => $opts->{size} ) : () ),
                ( exists( $opts->{sort} ) ? ( sort => $opts->{sort} ) : () ),
            },
        }) );
    }
    else
    {
        return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
    }
}

{
    no warnings 'once';
    *reverse_dependencies = \&reverse;
}

sub search
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $type = delete( $opts->{type} ) ||
        return( $self->error( "No API endpoint search type was provided." ) );
    return( $self->error( "API endpoint type \"${type}\" contains illegal characters. Only alphanumerical characters are supported." ) ) if( $type !~ /^[a-zA-Z]\w+$/ );
#     my $query = delete( $opts->{query} ) ||
#         return( $self->error( "No search query was provided." ) );
    my $filter = $self->new_filter( $opts ) || 
        return( $self->pass_error );
#     $filter->apply( $opts );
    return( $self->fetch( $type => {
        endpoint => "/${type}/_search",
        class => $self->_object_type_to_class( 'list' ),
        payload => $filter->as_json( encoding => 'utf-8' ),
        method => 'post',
        headers => [
            Content_Type => 'application/json',
            ( exists( $opts->{accept} ) ? ( Accept => $opts->{accept} ) : () ),
        ],
    }) );
}

sub source
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( exists( $opts->{author} ) && 
        length( $opts->{author} // '' ) && 
        exists( $opts->{release} ) && 
        length( $opts->{release} // '' ) && 
        exists( $opts->{path} ) && 
        length( $opts->{path} // '' ) )
    {
        # Returns a string
        return( $self->fetch( 'source' => {
            endpoint => "/source/" . join( '/', @$opts{qw( author release path )} ),
            # Returns data as-is
            class => sub{$_[0]},
        }) );
    }
    elsif( exists( $opts->{module} ) && 
        length( $opts->{module} // '' ) )
    {
        # Returns a string
        return( $self->fetch( 'source' => {
            endpoint => "/source/" . $opts->{module},
            # Returns data as-is
            class => sub{$_[0]},
        }) );
    }
    else
    {
        return( $self->error( "Unknown option properties provided: ", join( ', ', sort( keys( %$opts ) ) ) ) );
    }
}

sub suggest
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "No search term was provided." ) ) if( $self->_is_empty( $opts->{query} ) );
    return( $self->fetch( 'release_suggest' => {
        endpoint => "/search/autocomplete/suggest",
        class => $self->_object_type_to_class( 'list' ),
        query => {
            'q' => $opts->{query},
        },
    }) );
}

sub top_uploaders
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    # Possible values are 'all', 'weekly', 'monthly' or 'yearly'
    my $query;
    if( exists( $opts->{range} ) &&
        !$self->_is_empty( $opts->{range} ) &&
        $opts->{range} =~ /^\w+$/ )
    {
        $query = { range => $opts->{range} };
    }
    if( exists( $opts->{size} ) &&
        !$self->_is_empty( $opts->{size} ) &&
        $opts->{size} =~ /^\d+$/ )
    {
        $query //= {};
        $query->{size} = $opts->{size};
    }
    return( $self->fetch( 'release' => {
        endpoint => "/release/top_uploaders",
        (
            defined( $query ) ? ( query => $query ) : (),
        ),
        class => sub
        {
            my $ref = shift( @_ );
            if( exists( $ref->{counts} ) &&
                defined( $ref->{counts} ) &&
                ref( $ref->{counts} ) eq 'HASH' )
            {
                return( $self->new_hash( $ref->{counts} ) );
            }
            return( $ref );
        },
    }) );
}

sub ua { return( shift->_set_get_object_without_init( 'ua', 'HTTP::Promise', @_ ) ); }

sub web
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "No search term was provided." ) ) if( $self->_is_empty( $opts->{query} ) );
    return( $self->fetch( 'list_web' => {
        endpoint => "/search/web",
        # The data structure looks like a regular list, but is non-standard.
        # We use the special class list_web (Net::API::CPAN::List::Web)
        class => $self->_object_type_to_class( 'list' ),
        query => {
            'q' => $opts->{query},
            ( $opts->{collapsed} ? ( collapsed => $opts->{collapsed} ) : () ),
            ( length( $opts->{from} ) ? ( from => $opts->{from} ) : () ),
            ( length( $opts->{size} ) ? ( size => $opts->{size} ) : () ),
        },
    }) );
}

sub _is_module { return( $_[1] =~ /^$MODULE_RE$/ ); }

sub _object_type_to_class
{
    my $self = shift( @_ );
    my $type = shift( @_ ) ||
        return( $self->error( "No object type was provided to derive its module name" ) );
    my $class = '';
    if( exists( $TYPE2CLASS->{ $type } ) )
    {
        return( $TYPE2CLASS->{ $type } );
        $class = 'Net::API::CPAN::' . join( '', map( ucfirst( lc( $_ ) ), split( /_/, $type ) ) );
    }
    elsif( $type =~ /^$MODULE_RE$/ )
    {
        # $type provided is actually already a package name
        $class = $type;
    }
    # returns either the class, or if nothing found an empty, but defined, string.
    return( $class );
}

sub _query_fields
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !exists( $opts->{fields} ) || !length( $opts->{fields} // '' ) )
    {
        return( '' );
    }
    my $fields = $opts->{fields};
    my $clean = $self->new_array;
    if( $self->_is_array( $fields ) )
    {
        for( @$fields )
        {
            if( !ref( $_ ) || ( ref( $_ ) && $self->_is_scalar( $_ ) && $self->_can_overload( $_ => '""' ) ) )
            {
                $clean->push( "$_" );
            }
        }
    }
    elsif( !ref( $fields ) || ( ref( $fields ) && $self->_is_scalar( $fields ) && $self->_can_overload( $fields => '""' ) ) )
    {
        $clean->push( "$fields" );
    }
    return( '' ) if( $clean->is_empty );
    # We return an hash that URI will use to properly encode and add as a query string
    return( { fields => $clean->join( ',' )->scalar } );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN - Meta CPAN API

=head1 SYNOPSIS

    use Net::API::CPAN;
    my $cpan = Net::API::CPAN->new(
        api_version => 1,
        ua => HTTP::Promise->new( %options ),
        debug => 4,
    ) || die( Net::API::CPAN->error, "\n" );
    $cpan->api_uri( 'https://api.example.org' );
    my $uri = $cpan->api_uri;
    $cpan->api_version(1);
    my $version = $cpan->api_version;

=head1 VERSION

    v0.1.4

=head1 DESCRIPTION

C<Net::API::CPAN> is a client to issue queries to the MetaCPAN REST API.

Make sure to check out the L</"TERMINOLOGY"> section for the exact meaning of key words used in this documentation.

=head1 CONSTRUCTOR

=head2 new

This instantiates a new L<Net::API::CPAN> object. This accepts the following options, which can later also be set using their associated method.

=over 4

=item * C<api_version>

Integer. This is the C<CPAN> API version, and defaults to C<1>.

=item * C<debug>

Integer. This sets the debugging level. Defaults to 0. The higher and the more verbose will be the debugging output on STDERR.

=item * C<ua>

An optional L<HTTP::Promise> object. If not provided, one will be instantiated automatically.

=back

=head1 METHODS

=head2 api_uri

Sets or gets the C<CPAN> API C<URI> to use. This defaults to the C<Net::API::CPAN> constant C<API_URI> followed by the API version, such as:

    https://fastapi.metacpan.org/v1

This returns an L<URI> object.

=head2 api_version

Sets or gets the C<CPAN> API version. As of 2023-09-01, this can only C<1>

This returns a L<scalar object|Module::Generic::Scalar>

=head2 cache_file

Sets or gets a cache file path to use instead of issuing the C<HTTP> request. This affects how L</fetch> works since it does not issue an actual C<HTTP> request, but does not change the rest of the workflow.

Returns a L<file object|Module::Generic::File> or C<undef> if nothing was set.

=head2 fetch

This takes an object type, such as C<author>, C<release>, C<file>, etc, and the following options and performs an C<HttP> request to the remote MetaCPAN REST API and return the appropriate data or object.

If an error occurs, this set an L<error object|Net::API::CPAN::Error> and return C<undef> in scalar context, and an empty list in list context.

=over 4

=item * C<class>

One of C<Net::API::CPAN> classes, such as L<Net::API::CPAN::Author>

=item * C<endpoint>

The endpoint to access, such as C</author>

=item * C<headers>

An array reference of headers with their corresponding values.

=item * C<method>

The C<HTTP> method to use. This defaults to C<GET>. This is case insensitive.

=item * C<payload>

The C<POST> payload to send to the remote MetaCPAN API. It must be already encoded in C<UTF-8>.

=item * C<postprocess>

A subroutine reference or an anonymous subroutine that will be called back, taking the data received as the sole argument and returning the modified data.

=item * C<query>

An hash reference of key-value pairs representing the query string elements. This will be passed to L<URI/query_form>, so make sure to check what data structure is acceptable by L<URI>

=item * C<request>

An L<HTTP::Promise::Request> object.

=back

=head2 http_request

The latest L<HTTP::Promise::Request> issued to the remote MetaCPAN API server.

=head2 http_response

The latest L<HTTP::Promise::Response> received from the remote MetaCPAN API server.

=head2 json

Returns a new L<JSON> object.

=head2 new_filter

This instantiates a new L<Net::API::CPAN::Filter>, passing whatever arguments were received, and setting the debugging mode too.

=head1 API METHODS

=head2 activity

    # Get all the release activity for author OALDERS in the last 24 months
    my $activity_obj = $cpan->activity(
        author => 'OALDERS',
        # distribution => 'HTTP-Message',
        # module => 'HTTP::Message',
        interval => '1M',
    ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

    # Get all the release activity that depend on HTTP::Message in the last 24 months
    my $activity_obj = $cpan->activity(
        # author => 'OALDERS',
        # distribution => 'HTTP-Message',
        module => 'HTTP::Message',
        interval => '1M',
    ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

This method is used to query the CPAN REST API for the release activity for all, or for a given C<author>, or a given C<distribution>, or a given C<module> dependency. An optional aggregation interval can be stipulated with C<res> and it defaults to C<1w> (set by the API).

=over 4

=item * C<author> -> C</activity>

If a string is provided representing a specific C<author>, this will issue a query to the API endpoint C</activity> to retrieve the release activity for that C<author> for the past 24 months for the specified author, such as:

    /activity?author=OALDERS

For example:

    my $activity_obj = $cpan->activity(
        author => 'OALDERS',
        interval => '1M',
    ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

This would return, upon success, a L<Net::API::CPAN::Activity> object containing release activity for the C<author> C<OALDERS> for the past 24 months.

Note that the value of the C<author> is case insensitive and will automatically be transformed in upper case, so you could also do:

Possible options are:

=over 8

=item * C<interval>

Specifies an interval for the aggregate value. Defaults to C<1w>, which is 1 week. See L<ElasticSearch document|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries> for the proper value to use as interval.

=item * C<new>

Limit the result to newly issued distributions.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Factivity%3Fauthor%3DOALDERS> to see the data returned by the CPAN REST API.

=item * C<distribution> -> C</activity>

If a string is provided representing a specific C<distribution>, this will issue a query to the API endpoint C</activity> to retrieve the release activity for that C<distribution> for the past 24 months for the specified C<distribution>, such as:

    /activity?distribution=HTTP-Message

For example:

    my $activity_obj = $cpan->activity(
        distribution => 'HTTP-Message',
        interval => '1M',
    ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

This would return, upon success, a L<Net::API::CPAN::Activity> object containing release activity for the C<distribution> C<HTTP-Message> for the past 24 months.

Possible options are:

=over 8

=item * C<interval>

Specifies an interval for the aggregate value. Defaults to C<1w>, which is 1 week. See L<ElasticSearch document|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries> for the proper value to use as interval.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Factivity%3Fdistribution%3DHTTP-Message> to see the data returned by the CPAN REST API.

=item * C<module> -> C</activity>

If a string is provided representing a specific C<module>, this will issue a query to the API endpoint C</activity> to retrieve the release activity that have a dependency on that C<module> for the past 24 months, such as:

    /activity?res=1M&module=HTTP::Message

For example:

    my $activity_obj = $cpan->activity(
        module => 'HTTP::Message',
        interval => '1M',
    ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

This would return, upon success, a L<Net::API::CPAN::Activity> object containing release activity for all the distributions depending on the C<module> C<HTTP::Message> for the past 24 months.

Possible options are:

=over 8

=item * C<interval>

Specifies an interval for the aggregate value. Defaults to C<1w>, which is 1 week. See L<ElasticSearch document|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries> for the proper value to use as interval.

=item * C<new>

Limit the result to newly issued distributions.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Factivity%3Fres%3D1M%26module%3DHTTP%3A%3AMessage> to see the data returned by the CPAN REST API.

=item * C<new> -> C</activity>

If C<new> is provided with any value (true or not does not matter), this will issue a query to the API endpoint C</activity> to retrieve the new release activity in the past 24 months, such as:

    /activity?res=1M&new_dists=n

For example:

    my $activity_obj = $cpan->activity(
        new => 1,
        interval => '1M',
    ) || die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

This would return, upon success, a L<Net::API::CPAN::Activity> object containing all new distributions release activity for the past 24 months.

Possible options are:

=over 8

=item * C<interval>

Specifies an interval for the aggregate value. Defaults to C<1w>, which is 1 week. See L<ElasticSearch document|https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html#_date_format_in_range_queries> for the proper value to use as interval.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Factivity%3Fres%3D1M%26new_dists%3Dn> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 author

    # Retrieves the information details for the specified author
    my $author_obj = $cpan->author( 'OALDERS' ) ||
        die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

    # Retrieves author information details for the specified pause IDs
    my $list_obj = $cpan->author( [qw( OALDERS NEILB )] ) ||
        die( "Error with code: ", $cpan->error->code, " and message: ", $cpan->error->message );

    # Queries authors information details
    my $list_obj = $cpan->author(
        query => 'Olaf',
        from => 10,
        size => 20,
    ) || die( $cpan->error );

    # Queries authors information details using ElasticSearch format
    my $list_obj = $cpan->author( $filter_object ) ||
        die( $cpan->error );

    # Queries authors information using a prefix
    my $list_obj = $cpan->author( prefix => 'O' ) || 
        die( $cpan->error );

    # Retrieves authors information using their specified IDs
    my $list_obj = $cpan->author( user => [qw( FepgBJBZQ8u92eG_TcyIGQ 6ZuVfdMpQzy75_Mazx2_nw )] ) || 
        die( $cpan->error );

This method is used to query the CPAN REST API for a specific C<author>, a list of C<authors>, or search an C<author> using a query.
It takes a string, an array reference, an hash or alternatively an hash reference as possible parameters.

=over 4

=item * C<author> -> C</author/{author}>

If a string is provided representing a specific C<author>, this will issue a query to the API endpoint C</author/{author}> to retrieve the information details for the specified author, such as:

    /author/OALDERS

For example:

    my $author_obj = $cpan->author( 'OALDERS' ) ||
        die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::Author> object.

Note that the value of the C<author> is case insensitive and will automatically be transformed in upper case, so you could also do:

    my $author_obj = $cpan->author( 'OAlders' ) ||
        die( $cpan->error );

The following options are also supported:

=over 8

=item * C<from>

An integer representing the offset starting from 0 within the total data.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fauthor%2FOALDERS> to see the data returned by the CPAN REST API.

=item * [C<author>] -> C</author/by_ids>

And providing an array reference of C<authors> will trigger a query to the API endpoint C</author/by_ids>, such as:

    /author/by_ids?id=OALDERS&id=NEILB

For example:

    my $list_obj = $cpan->author( [qw( OALDERS NEILB )] ) || 
        die( $cpan->error );

This would, upon success, return a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Author> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fauthor%2Fby_ids%3Fid%3DOALDERS%26id%3DNEILB> to see the data returned by the CPAN REST API.

=item * C<query> -> C</author>

If the property C<query> is provided, this will trigger a simple search query to the endpoint C</author>, such as:

    /author?q=Tokyo

For example:

    my $list_obj = $cpan->author(
        query => 'Tokyo',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

will find all C<authors> related to Tokyo.

This would, upon success, return a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Author> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fauthor%3Fq%3DTokyo> to see the data returned by the CPAN REST API.

=item * C<prefix> -> C</author/by_prefix/{prefix}>

However, if the property C<prefix> is provided, this will issue a query to the endpoint C</author/by_prefix/{prefix}>, such as:

    /author/by_prefix/O

which will find all C<authors> whose Pause ID starts with the specified prefix; in this example, the letter C<O>

For example:

    my $list_obj = $cpan->author( prefix => 'O' ) || 
        die( $cpan->error );

This would, upon success, return a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Author> objects.

The following options are also supported:

=over 8

=item * C<from>

An integer representing the offset starting from 0 within the total data.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fauthor%2Fby_prefix%2FO> to see the data returned by the CPAN REST API.

=item * C<user> -> C</author/by_user>

And if the property C<user> is provided, this will issue a query to the endpoint C</author/by_user>, such as:

    /author/by_user?user=FepgBJBZQ8u92eG_TcyIGQ&user=6ZuVfdMpQzy75_Mazx2_nw

which will fetch the information for the authors whose user ID are C<FepgBJBZQ8u92eG_TcyIGQ> and C<6ZuVfdMpQzy75_Mazx2_nw> (here respectively corresponding to the C<authors> C<OALDERS> and C<HAARG>)

For example:

    my $list_obj = $cpan->author( user => [qw( FepgBJBZQ8u92eG_TcyIGQ 6ZuVfdMpQzy75_Mazx2_nw )] ) || 
        die( $cpan->error );

This would, upon success, return a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Author> objects.

However, note that not all C<CPAN> account have a user ID, surprisingly enough.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fauthor%2Fby_user%3Fuser%3DFepgBJBZQ8u92eG_TcyIGQ%26user%3D6ZuVfdMpQzy75_Mazx2_nw> to see the data returned by the CPAN REST API.

=item * L<search filter|Net::API::CPAN::Filter> -> C</author/_search>

And if a L<search filter|Net::API::CPAN::Filter> is passed, this will trigger a more advanced ElasticSearch query to the endpoint C</author/_search> using the C<HTTP> C<POST> method. See the L<Net::API::CPAN::Filter> module on more details on what granular queries you can execute.

This would, upon success, return a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Author> objects.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 autocomplete

This takes a string and will issue a query to the endpoint C</search/autocomplete> to retrieve the result set based on the autocomplete search query specified, such as:

    /search/autocomplete?q=HTTP

For example:

    my $list_obj = $cpan->autocomplete( 'HTTP' ) || die( $cpan->error );

This would, upon success, return a L<Net::API::CPAN::List> object of L<Net::API::CPAN::File> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fsearch%2Fautocomplete%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 changes

    # Retrieves the specified distribution Changes file content
    my $change_obj = $cpan->changes( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Retrieves one or more distribution Changes file details using author and release information
    my $change_obj = $cpan->changes(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36'
    ) || die( $cpan->error );

    # Same:
    my $change_obj = $cpan->changes( release => 'OALDERS/HTTP-Message-6.36' ) ||
        die( $cpan->error );

    # With multiple author and releases
    my $list_obj = $cpan->changes(
        author => [qw( OALDERS NEILB )],
        release => [qw( HTTP-Message-6.36 Data-HexDump-0.04 )]
    ) || die( $cpan->error );

    # Same:
    my $list_obj = $cpan->changes( release => [qw( OALDERS/HTTP-Message-6.36 NEILB/Data-HexDump-0.04 )] ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API for one or more particular C<release>'s C<Changes> (or C<CHANGES> depending on the release) file content.

=over 4

=item * C<distribution> -> C</changes/{distribution}>

If the property C<distribution> is provided, this will issue a query to the endpoint C</changes/{distribution}> to retrieve a distribution Changes file details, such as:

    /changes/HTTP-Message

For example:

    my $change_obj = $cpan->changes( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

which will retrieve the C<Changes> file information for the B<latest> C<release> of the specified C<distribution>, and return a L<Net::API::CPAN::Changes> object upon success.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fchanges%2FHTTP-Message> to see the data returned by the CPAN REST API.

=item * C<release> -> C</changes/>

=item * C<author> and C<release> -> C</changes/{author}/{release}>

If the properties C<author> and C<release> have been provided or that the value of the property C<release> has the form C<author>/C<release>, this will issue a query to the endpoint C</changes/{author}/{release}> to retrieve an author distribution Changes file details:

    /changes/OALDERS/HTTP-Message-6.36

For example:

    my $change_obj = $cpan->changes(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36'
    ) || die( $cpan->error );
    # or
    my $change_obj = $cpan->changes( release => 'OALDERS/HTTP-Message-6.36' ) ||
        die( $cpan->error );

which will retrieve the C<Changes> file information for the specified C<release>, and return, upon success, a L<Net::API::CPAN::Changes> object.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fchanges%2FOALDERS%2FHTTP-Message-6.36> to see the data returned by the CPAN REST API.

=item * [C<author>] and [C<release>] -> C</author/by_releases>

And, if both properties C<author> and C<release> have been provided and are both an array reference of equal size, this will issue a query to the endpoint C</author/by_releases> to retrieve one or more distribution Changes file details using the specified author and release information, such as:

    /changes/by_releases?release=OALDERS%2FHTTP-Message-6.37&release=NEILB%2FData-HexDump-0.04

For example:

    my $list_obj = $cpan->changes(
        author => [qw( OALDERS NEILB )],
        release => [qw( HTTP-Message-6.36 Data-HexDump-0.04 )]
    ) || die( $cpan->error );

Alternatively, you can provide the property C<release> having, as value, an array reference of C<author>/C<release>, such as:

    my $list_obj = $cpan->changes(
        release => [qw(
            OALDERS/HTTP-Message-6.36
            NEILB/Data-HexDump-0.04
        )]
    ) || die( $cpan->error );

which will retrieve the C<Changes> file information for the specified C<releases>, and return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Changes> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fchanges%2Fby_releases%3Frelease%3DOALDERS%252FHTTP-Message-6.37%26release%3DNEILB%252FData-HexDump-0.04> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 clientinfo

This issue a query to the endpoint C<https://clientinfo.metacpan.org> and retrieves the information of the various base URL.

It returns an hash reference with the following structure:

    {
        future => {
            domain => "https://fastapi.metacpan.org/",
            url => "https://fastapi.metacpan.org/v1/",
            version => "v1",
        },
        production => {
            domain => "https://fastapi.metacpan.org/",
            url => "https://fastapi.metacpan.org/v1/",
            version => "v1",
        },
        testing => {
            domain => "https://fastapi.metacpan.org/",
            url => "https://fastapi.metacpan.org/v1/",
            version => "v1",
        },
    }

Each of the URL is an L<URL> object.

=head2 contributor

    # Retrieves a list of module contributed to by the specified PauseID
    my $list_obj = $cpan->contributor( author => 'OALDERS' ) ||
        die( $cpan->error );

    # Retrieves a list of module contributors details
    my $list_obj = $cpan->contributor(
        author => 'OALDERS'
        release => 'HTTP-Message-6.37'
    ) || die( $cpan->error );

This method is used to query the CPAN REST API for either the list of C<releases> a CPAN account has contributed to, or to get the list of C<contributors> for a specified C<release>.

=over 4

=item * C<author> -> C</contributor/by_pauseid/{author}>

If the property C<author> is provided, this will issue a query to the endpoint C</contributor/by_pauseid/{author}> to retrieve a list of module contributed to by the specified PauseID, such as:

    /contributor/by_pauseid/OALDERS

For example:

    my $list_obj = $cpan->contributor( author => 'OALDERS' ) ||
        die( $cpan->error );

This will, upon success, return a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Contributor> objects containing the details of the release to which the specified C<author> has contributed.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fcontributor%2Fby_pauseid%2FOALDERS> to see the data returned by the CPAN REST API.

=item * C<author> and C<release> -> C</contributor/{author}/{release}>

And if the properties C<author> and C<release> are provided, this will issue a query to the endpoint C</contributor/{author}/{release}> to retrieve a list of release contributors details, such as:

    /contributor/OALDERS/HTTP-Message-6.36

For example:

    my $list_obj = $cpan->contributor(
        author => 'OALDERS'
        release => 'HTTP-Message-6.37'
    ) || die( $cpan->error );

This will, upon success, return a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Contributor> objects containing the specified C<release> information and the C<pauseid> of all the C<authors> who have contributed to the specified C<release>.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fcontributor%2FOALDERS%2FHTTP-Message-6.36> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 cover

This method is used to query the CPAN REST API to the endpoint C</v1/cover/{release}> to get the C<cover> information including C<distribution> name, C<release> name, C<version> and download C<URL>, such as:

    /cover/HTTP-Message-6.37

For example:

    my $cover_obj = $cpan->cover(
        release => 'HTTP-Message-6.37',
    ) || die( $cpan->error );

It returns, upon success, a L<Net::API::CPAN::Cover> object.

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 diff

    # Retrieves a diff of two files with output as JSON
    my $diff_obj = $cpan->diff(
        file1 => 'AcREzFgg3ExIrFTURa0QJfn8nto',
        file2 => 'Ies7Ysw0GjCxUU6Wj_WzI9s8ysU',
        # Default
        accept => 'application/json',
    ) || die( $cpan->error );

    # Retrieves a diff of two files with output as plain text
    my $diff_text = $cpan->diff(
        file1 => 'AcREzFgg3ExIrFTURa0QJfn8nto',
        file2 => 'Ies7Ysw0GjCxUU6Wj_WzI9s8ysU',
        # Default
        accept => 'text/plain',
    ) || die( $cpan->error );

    # Retrieves a diff of two releases with output as JSON
    my $diff_obj = $cpan->diff(
        author1 => 'OALDERS',
        # This is optional if it is the same
        author2 => 'OALDERS',
        release1 => 'HTTP-Message-6.35'
        release2 => 'HTTP-Message-6.36'
        # Default
        accept => 'application/json',
    ) || die( $cpan->error );

    # Retrieves a diff of two releases with output as plain text
    my $diff_text = $cpan->diff(
        author1 => 'OALDERS',
        # This is optional if it is the same
        author2 => 'OALDERS',
        release1 => 'HTTP-Message-6.35'
        release2 => 'HTTP-Message-6.36'
        # Default
        accept => 'text/plain',
    ) || die( $cpan->error );

    # Retrieves a diff of the latest release and its previous version with output as JSON
    my $diff_obj = $cpan->diff(
        distribution => 'HTTP-Message',
        # Default
        accept => 'application/json',
    ) || die( $cpan->error );

    # Retrieves a diff of the latest release and its previous version with output as plain text
    my $diff_text = $cpan->diff(
        distribution => 'HTTP-Message',
        # Default
        accept => 'text/plain',
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to get the C<diff> output between 2 files, or 2 releases.

=over 4

=item * C<file1> and C<file2> -> C</diff/file/{file1}/{file2}>

If the properties C<file1> and C<file2> are provided, this will issue a query to the endpoint C</diff/file/{file1}/{file2}>, such as:

    /diff/file/AcREzFgg3ExIrFTURa0QJfn8nto/Ies7Ysw0GjCxUU6Wj_WzI9s8ysU

The result returned will depend on the optional C<accept> property, which is, by default C<application/json>, but can also be set to C<text/plain>.

When set to C<application/json>, this will retrieve the result as C<JSON> data and return a L<Net::API::CPAN::Diff> object. If this is set to C<text/plain>, then this will return a raw C<diff> output as a string encoded in L<Perl internal utf-8 encoding|perlunicode>.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fdiff%2Ffile%2FAcREzFgg3ExIrFTURa0QJfn8nto%2FIes7Ysw0GjCxUU6Wj_WzI9s8ysU> to see the data returned by the CPAN REST API.

=item * C<author1>, C<author2>, C<release1>, and C<release2> -> C</diff/release/{author1}/{release1}/{author2}/{release2}>

If the properties C<author1>, C<author2>, C<release1>, and C<release2> are provided, this will issue a query to the endpoint C</diff/release/{author1}/{release1}/{author2}/{release2}>, such as:

    /diff/release/OALDERS/HTTP-Message-6.35/OALDERS/HTTP-Message-6.36

For example:

    my $diff_obj = $cpan->diff(
        author1 => 'OALDERS',
        # This is optional if it is the same
        author2 => 'OALDERS',
        release1 => 'HTTP-Message-6.35'
        release2 => 'HTTP-Message-6.36'
        # Default
        accept => 'application/json',
    ) || die( $cpan->error );

Note that, if C<author1> and C<author2> are the same, C<author2> is optional.

It is important, however, that the C<release> specified with C<release1> belongs to C<author1> and the C<release> specified with C<release2> belongs to C<author2>

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fdiff%2Frelease%2FOALDERS%2FHTTP-Message-6.35%2FOALDERS%2FHTTP-Message-6.36> to see the data returned by the CPAN REST API.

=item * C<distribution> -> C</diff/release/{distribution}>

You can also specify the property C<distribution>, and this will issue a query to the endpoint C</diff/release/{distribution}>, such as:

    /diff/release/HTTP-Message

For example:

    my $diff_obj = $cpan->diff(
        distribution => 'HTTP-Message',
        # Default
        accept => 'application/json',
    ) || die( $cpan->error );

If C<accept> is set to C<application/json>, which is the default value, this will return a L<Net::API::CPAN::Diff> object representing the difference between the previous version and current version for the C<release> of the C<distribution> specified. If, however, C<accept> is set to C<text/plain>, a string of the diff output will be returned encoded in L<Perl internal utf-8 encoding|perlunicode>.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fdiff%2Frelease%2FHTTP-Message> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 distribution

    # Retrieves a distribution information details
    my $dist_obj = $cpan->distribution( 'HTTP-Message' ) ||
        die( $cpan->error );

    # Queries distribution information details using simple search
    my $list_obj = $cpan->distribution(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );
    
    # Queries distribution information details using advanced search with ElasticSearch
    my $list_obj = $cpan->distribution( $filter_object ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve C<distribution> information.

=over 4

=item * C<distribution> -> C</distribution/{distribution}>

If a string representing a C<distribution> is provided, it will issue a query to the endpoint C</distribution/{distribution}> to retrieve a distribution information details, such as:

    /distribution/HTTP-Message

For example:

    my $dist_obj = $cpan->distribution( 'HTTP-Message' ) ||
        die( $cpan->error );

This will return, upon success, a L<Net::API::CPAN::Distribution> object.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fdistribution%2FHTTP-Message> to see the data returned by the CPAN REST API.

=item * C<query> -> C</distribution>

If the property C<query> is provided, this will trigger a simple search query to the endpoint C</distribution>, such as:

    /distribution?q=HTTP

For example:

    my $list_obj = $cpan->distribution(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Distribution> objects.

The following options are also supported:

=over 8

=item * C<from>

An integer representing the offset starting from 0 within the total data.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fdistribution%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

=item * L<search filter|Net::API::CPAN::Filter> -> C</distribution>

And if a L<search filter|Net::API::CPAN::Filter> is passed, this will trigger a more advanced ElasticSearch query to the endpoint C</distribution> using the C<HTTP> C<POST> method. See the L<Net::API::CPAN::Filter> module on more details on what granular queries you can execute.

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Distribution> objects.

=back

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 download_url

    # Retrieve the latest release download URL information details
    my $dl_obj = $cpan->download_url( 'HTTP::Message' ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve the specified C<module> latest C<release> C<download_url> information.

=over 4

=item * C<module> -> C</download_url/{module}>

If a string representing a C<module> is provided, it will issue a query to the endpoint C</download_url/{module}> to retrieve the download URL information details of the specified module, such as:

    /download_url/HTTP::Message

This will return, upon success, a L<Net::API::CPAN::DownloadUrl> object.

The following options are also supported:

=over 8

=item * C<dev>

    # Retrieves a development release
    my $dl_obj = $cpan->download_url( 'HTTP::Message',
    {
        dev => 1,
        version => '>1.01',
    }) || die( $cpan->error );

Specifies if the C<release> is a development version.

=item * C<version>

    # Retrieve the download URL of a specific release version
    my $dl_obj = $cpan->download_url( 'HTTP::Message',
    {
        version => '1.01',
    }) || die( $cpan->error );

    # or, using a range
    my $dl_obj = $cpan->download_url( 'HTTP::Message',
    {
        version => '<=1.01',
    }) || die( $cpan->error );
    my $dl_obj = $cpan->download_url( 'HTTP::Message',
    {
        version => '>1.01,<=2.00',
    }) || die( $cpan->error );

Specifies the version requirement or version range requirement.

Supported range operators are C<==> C<!=> C<< <= >> C<< >= >> C<< < >> C<< > >> C<!>

Separate the ranges with a comma when specifying multiple ranges.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fdownload_url%2FHTTP%3A%3AMessage> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 favorite

    # Queries favorites using a simple search
    my $list_obj = $cpan->favorite(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries favorites using a advanced search with ElasticSearch format
    my $list_obj = $cpan->favorite( $filter_object ) ||
        die( $cpan->error );

    # Retrieves favorites agregate by distributions as an hash reference
    # e.g.: HTTP-Message => 63
    my $hash_ref = $cpan->favorite( aggregate => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Same
    my $hash_ref = $cpan->favorite( agg => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Same with multiple distributions
    my $hash_ref = $cpan->favorite( aggregate => [qw( HTTP-Message Data-HexDump)] ) ||
        die( $cpan->error );

    # Same
    my $hash_ref = $cpan->favorite( agg => [qw( HTTP-Message Data-HexDump)] ) ||
        die( $cpan->error );

    # Retrieves list of users who favorited a distribution as an array reference
    # e.g. [ '9nGbVdZ4QhO4Ia5ZhNpjtg', 'c4QLX0YORN6-quL15MGwqg', ... ]
    my $array_ref = $cpan->favorite( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Retrieves user favorites information details
    my $list_obj = $cpan->favorite( user => 'q_15sjOkRminDY93g9DuZQ' ) ||
        die( $cpan->error );

    # Retrieves top favorite distributions a.k.a. leaderboard as an array reference
    my $array_ref = $cpan->favorite( leaderboard => 1 ) ||
        die( $cpan->error );

    # Retrieves list of recent favorite distribution
    my $list_obj = $cpan->favorite( recent => 1 ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve C<favorite> information.

=over 4

=item * C<query> -> C</favorite>

If the property C<query> is provided, this will trigger a simple search query to the endpoint C</favorite>, such as:

    /favorite?q=HTTP

For example:

    my $list_obj = $cpan->favorite( query => 'HTTP' ) || 
        die( $cpan->error );

which will find all C<favorite> related to the query term C<HTTP>.

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Favorite> objects.

The following options are also supported:

=over 8

=item * C<from>

An integer representing the offset starting from 0 within the total data.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Ffavorite%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

=item * L<search filter|Net::API::CPAN::Filter> -> C</favorite>

And if a L<search filter|Net::API::CPAN::Filter> is passed, this will trigger a more advanced ElasticSearch query to the endpoint C</favorite> using the C<HTTP> C<POST> method. See the L<Net::API::CPAN::Filter> module on more details on what granular queries you can execute.

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Favorite> objects.

=item * C<aggregate> or C<agg> -> C</favorite/agg_by_distributions>

If the property C<aggregate> or C<agg>, for short, is provided, this will issue a query to the endpoint C</favorite/agg_by_distributions> to retrieve favorites agregate by distributions, such as:

    /favorite/agg_by_distributions?distribution=HTTP-Message&distribution=Data-HexDump

For example:

    my $hash_ref = $cpan->favorite( aggregate => 'HTTP-Message' ) ||
        die( $cpan->error );
    my $hash_ref = $cpan->favorite( aggregate => [qw( HTTP-Message Data-HexDump)] ) ||
        die( $cpan->error );

The C<aggregate> value can be either a string representing a C<distribution>, or an array reference of C<distributions>

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Favorite> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Ffavorite%2Fagg_by_distributions%3Fdistribution%3DHTTP-Message%26distribution%3DData-HexDump> to see the data returned by the CPAN REST API.

=item * C<distribution> -> C</favorite/users_by_distribution/{distribution}>

If the property C<distribution> is provided, will issue a query to the endpoint C</favorite/users_by_distribution/{distribution}> to retrieves the list of users who favorited the specified distribution, such as:

    /favorite/users_by_distribution/HTTP-Message

For example:

    my $array_ref = $cpan->favorite( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Favorite> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Ffavorite%2Fusers_by_distribution%2FHTTP-Message> to see the data returned by the CPAN REST API.

=item * C<user> -> C</favorite/by_user/{user}>

If the property C<user> is provided, this will issue a query to the endpoint C</favorite/by_user/{user}> to retrieve the specified user favorites information details, such as:

    /favorite/by_user/q_15sjOkRminDY93g9DuZQ

For example:

    my $list_obj = $cpan->favorite( user => 'q_15sjOkRminDY93g9DuZQ' ) ||
        die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Favorite> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Ffavorite%2Fby_user%2Fq_15sjOkRminDY93g9DuZQ> to see the data returned by the CPAN REST API.

=item * C<leaderboard> -> C</favorite/leaderboard>

If the property C<leaderboard> is provided with any value true or false does not matter, this will issue a query to the endpoint C</favorite/leaderboard> to retrieve the top favorite distributions a.k.a. leaderboard, such as:

    /favorite/leaderboard

For example:

    my $array_ref = $cpan->favorite( leaderboard => 1 ) ||
        die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Favorite> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Ffavorite%2Fleaderboard> to see the data returned by the CPAN REST API.

=item * C<recent> -> C</favorite/recent>

Finally, if the property C<recent> is provided with any value true or false does not matter, this will issue a query to the endpoint C</favorite/recent> to retrieve the list of recent favorite distributions, such as:

    /favorite/recent

For example:

    my $list_obj = $cpan->favorite( recent => 1 ) ||
        die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Favorite> objects.

The following options are also supported:

=over 8

=item * C<page>

An integer representing the page offset starting from 1.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back


You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Ffavorite%2Frecent> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 file

    # Queries files using simple search
    my $list_obj = $cpan->file(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries files with advanced search using ElasticSearch
    my $list_obj = $cpan->file( $filter_object ) ||
        die( $cpan->error );

    # Retrieves a directory content
    my $list_obj = $cpan->file(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        dir => 'lib/HTTP',
    ) || die( $cpan->error );

    # Retrieves a file information details
    my $file_obj = $cpan->file(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve C<file> information.

=over 4

=item * C<query> -> C</file>

If the property C<query> is provided, this will trigger a simple search query to the endpoint C</file>, such as:

    /file?q=HTTP

For example:

    my $list_obj = $cpan->file(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

will find all C<files> related to C<HTTP>.

This would return a L<Net::API::CPAN::List> object upon success.

The following options are also supported:

=over 8

=item * C<from>

An integer representing the offset starting from 0 within the total data.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Ffile%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

=item * L<search filter|Net::API::CPAN::Filter> -> C</file>

And if a L<search filter|Net::API::CPAN::Filter> is passed, this will trigger a more advanced ElasticSearch query to the endpoint C</file> using the C<HTTP> C<POST> method. See the L<Net::API::CPAN::Filter> module on more details on what granular queries you can execute.

    my $list_obj = $cpan->file( $filter_object ) ||
        die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::File> objects.

=item * C<author>, C<release> and C<dir> -> C</file/dir/{author}/{release}/{dir}>

If the properties, C<author>, C<release> and C<dir> are provided, this will issue a query to the endpoint C</file/dir/{author}/{release}/{dir}> to retrieve the specified directory content, such as:

    /file/dir/OALDERS/HTTP-Message-6.36/lib/HTTP

For example:

    my $list_obj = $cpan->file(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        dir => 'lib/HTTP',
    ) || die( $cpan->error );

For this to yield correct results, the C<dir> specified must be a directory.

This would return, upon success, a L<Net::API::CPAN::List> object of all the files and directories contained within the specified directory.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Ffile%2Fdir%2FOALDERS%2FHTTP-Message-6.36%2Flib%2FHTTP> to see the data returned by the CPAN REST API.

=item * C<author>, C<release> and C<path> -> C</file/{author}/{release}/{path}>

If the properties, C<author>, C<release> and C<path> are provided, this will issue a query to the endpoint C</file/{author}/{release}/{path}> to retrieve the specified file (or directory) information details, such as:

    /file/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm

For example:

    my $file_obj = $cpan->file(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::File> object of the information retrieved.

Note that the path can point to either a file or a directory within the given release.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Ffile%2FOALDERS%2FHTTP-Message-6.36%2Flib%2FHTTP%2FMessage.pm> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 first

This takes a string and will issue a query to the endpoint C</search/first> to retrieve the first result found based on the search query specified, such as:

    /search/first?q=HTTP

For example:

    my $list_obj = $cpan->first( 'HTTP' ) || die( $cpan->error );

This would, upon success, return a L<Net::API::CPAN::Module> object.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fsearch%2Fautocomplete%2Fsuggest%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

=head2 history

    # Retrieves the history of a given module
    my $list_obj = $cpan->history(
        type => 'module',
        module => 'HTTP::Message',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

    # Retrieves the history of a given distribution file
    my $list_obj = $cpan->history(
        type => 'file',
        distribution => 'HTTP-Message',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

    # Retrieves the history of a given module documentation
    my $list_obj = $cpan->history(
        type => 'documentation',
        module => 'HTTP::Message',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve C<file> history information.

=over 4

=item * C<module> -> C</search/history/module>

If the property C<module> is provided, this will trigger a query to the endpoint C</search/history/module> to retrieve the history of a given module, such as:

    /search/history/module/HTTP::Message/lib/HTTP/Message.pm

For example:

    my $list_obj = $cpan->history(
        type => 'module',
        module => 'HTTP::Message',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

will find all C<module> history related to the module C<HTTP::Message>.

This would return a L<Net::API::CPAN::List> object upon success.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fsearch%2Fhistory%2Fmodule%2FHTTP%3A%3AMessage%2Flib%2FHTTP%2FMessage.pm> to see the data returned by the CPAN REST API.

=item * C<file> -> C</search/history/file>

If the property C<file> is provided, this will trigger a query to the endpoint C</search/history/file> to retrieve the history of a given distribution file, such as:

    /search/history/file/HTTP-Message/lib/HTTP/Message.pm

For example:

    my $list_obj = $cpan->history(
        type => 'file',
        distribution => 'HTTP-Message',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

will find all C<files> history related to the distribution C<HTTP-Message>.

This would return a L<Net::API::CPAN::List> object upon success.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fsearch%2Fhistory%2Ffile%2FHTTP-Message%2Flib%2FHTTP%2FMessage.pm> to see the data returned by the CPAN REST API.

=item * C<documentation> -> C</search/history/documentation>

If the property C<documentation> is provided, this will trigger a query to the endpoint C</search/history/documentation> to retrieve the history of a given module documentation, such as:

    /search/history/documentation/HTTP::Message/lib/HTTP/Message.pm

For example:

    my $list_obj = $cpan->history(
        type => 'documentation',
        module => 'HTTP::Message',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

will find all C<documentation> history related to the module C<HTTP::Message>.

This would return a L<Net::API::CPAN::List> object upon success.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fsearch%2Fhistory%2Fdocumentation%2FHTTP%3A%3AMessage%2Flib%2FHTTP%2FMessage.pm> to see the data returned by the CPAN REST API.

=back

=head2 mirror

    my $list_obj = $cpan->mirror;

This would return, upon success, a L<Net::API::CPAN::List> object.

Actually there is no mirroring anymore, because for some time now CPAN runs on a CDN (Content Distributed Network) which performs the same result, but transparently.

See more on this L<here|https://www.cpan.org/SITES.html>

This endpoint also has search capability, but given there is now only one entry, it is completely useless.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fmirror> to see the data returned by the CPAN REST API.

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 module

    # Queries modules with a simple search
    my $list_obj = $cpan->module(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries modules with an advanced search using ElasticSearch
    my $list_obj = $cpan->module( $filter_object ) ||
        die( $cpan->error );

    # Retrieves the specified module information details
    my $module_obj = $cpan->module(
        module => 'HTTP::Message',
    ) || die( $cpan->error );

    # And if you want to join with other object types
    my $module_obj = $cpan->module(
        module => 'HTTP::Message',
        join => [qw( release author )],
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve C<module> information.

=over

=item * C<query> -> C</module>

If the property C<query> is provided, this will trigger a simple search query to the endpoint C</module>, such as:

    /module?q=HTTP

For example:

    my $list_obj = $cpan->module( query => 'HTTP' ) || 
        die( $cpan->error );

will find all C<modules> related to C<HTTP>.

This would return a L<Net::API::CPAN::List> object upon success.

The following options are also supported:

=over 8

=item * C<from>

An integer representing the offset starting from 0 within the total data.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fmodule%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

=item * L<search filter|Net::API::CPAN::Filter> -> C</module>

And if a L<search filter|Net::API::CPAN::Filter> is passed, this will trigger a more advanced ElasticSearch query to the endpoint C</module> using the C<HTTP> C<POST> method. See the L<Net::API::CPAN::Filter> module on more details on what granular queries you can execute.

This would return a L<Net::API::CPAN::List> object upon success.

=item * C<$module> -> C</module/{module}>

If a string representing a C<module> is provided, this will be used to issue a query to the endpoint C</module/{module}> to retrieve the specified module information details, such as:

    /module/HTTP::Message

For example:

    my $module_obj = $cpan->module(
        module => 'HTTP::Message',
        join => [qw( release author )],
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::Module> object.

The following options are also supported:

=over 8

=item * C<join>

You can join a.k.a. merge other objects data by setting C<join> to that object type, such as C<release> or C<author>. C<join> value can be either a string or an array of object types.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fmodule%2FHTTP%3A%3AMessage> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 package

    # Queries packages with a simple search
    my $list_obj = $cpan->package(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries packages with an advanced search using ElasticSearch
    my $list_obj = $cpan->package( $filter_object ) ||
        die( $cpan->error );

    # Retrieves the list of a distribution packages
    my $list_obj = $cpan->package( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Retrieves the latest release and package information for the specified module
    my $package_obj = $cpan->package( 'HTTP::Message' ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve C<package> information.

=over 4

=item * C<query> -> C</package>

If the property C<query> is provided, this will trigger a simple search query to the endpoint C</package>, such as:

    /package?q=HTTP

For example:

    my $list_obj = $cpan->package( query => 'HTTP' ) || 
        die( $cpan->error );

will find all C<packages> related to C<HTTP>.

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Package>

The following options are also supported:

=over 8

=item * C<from>

An integer representing the offset starting from 0 within the total data.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fpackage%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

=item * L<search filter|Net::API::CPAN::Filter> -> C</package>

And if a L<search filter|Net::API::CPAN::Filter> is passed, this will trigger a more advanced ElasticSearch query to the endpoint C</package> using the C<HTTP> C<POST> method. See the L<Net::API::CPAN::Filter> module on more details on what granular queries you can execute.

=item * C<distribution> -> C</package/modules/{distribution}>

If the property C<distribution> is provided, this will issue a query to the endpoint C</package/modules/{distribution}> to retrieve the list of a distribution packages, such as:

    /package/modules/HTTP-Message

For example:

    my $list_obj = $cpan->package( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

This would return, upon success, an L<array object|Module::Generic::Array> containing all the modules name provided within the specified C<distribution>.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fpackage%2Fmodules%2FHTTP-Message> to see the data returned by the CPAN REST API.

=item * C<$package> -> C</package/{module}>

If a string representing a package name is directly passed, this will issue a query to the endpoint C</package/{module}> to retrieve the latest release and package information for the specified module, such as:

    /package/HTTP::Message

For example:

    my $package_obj = $cpan->package( 'HTTP::Message' ) ||
        die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::Package> object.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fpackage%2FHTTP%3A%3AMessage> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 permission

    # Queries permissions with a simple search
    my $list_obj = $cpan->permission(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries permissions with an advanced search using ElasticSearch
    my $list_obj = $cpan->permission( $filter_object ) ||
        die( $cpan->error );

    # Retrieves permission information details for the specified author
    my $list_obj = $cpan->permission(
        author => 'OALDERS',
        from => 40,
        size => 20,
    ) || die( $cpan->error );

    # Retrieves permission information details for the specified module
    my $list_obj = $cpan->permission(
        module => 'HTTP::Message',
    ) || die( $cpan->error );

    # Retrieves permission information details for the specified modules
    my $list_obj = $cpan->permission(
        module => [qw( HTTP::Message Data::HexDump )],
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve C<package> information.

=over 4

=item * C<query> -> C</permission>

If the property C<query> is provided, this will trigger a simple search query to the endpoint C</permission>, such as:

    /permission?q=HTTP

For example:

    my $list_obj = $cpan->permission(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

will find all C<permissions> related to C<HTTP>.

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Permission> objects.

The following options are also supported:

=over 8

=item * C<from>

An integer representing the offset starting from 0 within the total data.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fpermission%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

=item * L<search filter|Net::API::CPAN::Filter> -> C</permission>

And if a L<search filter|Net::API::CPAN::Filter> is passed, this will trigger a more advanced ElasticSearch query to the endpoint C</permission> using the C<HTTP> C<POST> method. See the L<Net::API::CPAN::Filter> module on more details on what granular queries you can execute.

=item * C<author> -> C</permission/by_author/{author}>

If the property C<author> is provided, this will trigger a simple search query to the endpoint C</permission/by_author/{author}> to retrieve the permission information details for the specified author, such as:

    /permission/by_author/OALDERS?from=40&q=HTTP&size=20

For example:

    my $list_obj = $cpan->permission(
        author => 'OALDERS',
        from => 40,
        size => 20,
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Permission> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fpermission%2Fby_author%2FOALDERS%3Ffrom%3D40%26q%3DHTTP%26size%3D20> to see the data returned by the CPAN REST API.

=item * C<module> -> C</permission/{module}>

If the property C<module> is provided, and its value is a string, this will issue a query to the endpoint C</permission/{module}> to retrieve permission information details for the specified module, such as:

    /permission/HTTP::Message

For example:

    my $list_obj = $cpan->permission(
        module => 'HTTP::Message',
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::Permission> object.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fpermission%2FHTTP%3A%3AMessage> to see the data returned by the CPAN REST API.

=item * [C<module>] -> C</permission/by_module>

If the property C<module> is provided, and its value is an array reference, this will issue a query to the endpoint C</permission/by_module> to retrieve permission information details for the specified modules, such as:

    /permission/by_module?module=HTTP%3A%3AMessage&module=Data%3A%3AHexDump

For example:

    my $list_obj = $cpan->permission(
        module => [qw( HTTP::Message Data::HexDump )],
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Permission> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fpermission%2Fby_module%3Fmodule%3DHTTP%253A%253AMessage%26module%3DData%253A%253AHexDump> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 pod

    # Returns the POD of the given module in the 
    # specified release in markdown format
    my $string = $cpan->pod(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        path => 'lib/HTTP/Message.pm',
        accept => 'text/x-markdown',
    ) || die( $cpan->error );

    # Returns the POD of the given module in 
    # markdown format
    my $string = $cpan->pod(
        module => 'HTTP::Message',
        accept => 'text/x-markdown',
    ) || die( $cpan->error );

    # Renders the specified POD code into HTML
    my $html = $cpan->pod(
        render => qq{=encoding utf-8\n\n=head1 Hello World\n\nSomething here\n\n=oops\n\n=cut\n}
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve C<pod> documentation from specified modules and to render pod into C<HTML> data.

=over 4

=item * C<author>, C<release> and C<path> -> C</pod/{author}/{release}/{path}>

If the properties C<author>, C<release> and C<path> are provided, this will issue a query to the endpoint C</pod/{author}/{release}/{path}> to retrieve the POD of the given module in the specified release, such as:

    /pod/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm

For example:

    my $string = $cpan->pod(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        path => 'lib/HTTP/Message.pm',
        accept => 'text/x-markdown',
    ) || die( $cpan->error );

This would return a string of data in the specified format, which can be one of C<text/html>, C<text/plain>, C<text/x-markdown> or C<text/x-pod>. By default this is C<text/html>. The preferred data type is specified with the property C<accept>

The following options are also supported:

=over 8

=item * C<accept>

This value instructs the MetaCPAN API to return the pod data in the desired format.

Supported formats are: C<text/html>, C<text/plain>, C<text/x-markdown>, C<text/x-pod>

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fpod%2FOALDERS%2FHTTP-Message-6.36%2Flib%2FHTTP%2FMessage.pm> to see the data returned by the CPAN REST API.

=item * C<module> -> C</v1/pod/{module}>

If the property C<module> is provided, this will issue a query to the endpoint C</v1/pod/{module}> to retrieve the POD of the specified module, such as:

    /pod/HTTP::Message

For example:

    my $string = $cpan->pod(
        module => 'HTTP::Message',
        accept => 'text/x-markdown',
    ) || die( $cpan->error );

Just like the previous one, this would return a string of data in the specified format (in the above example markdown), which can be one of C<text/html>, C<text/plain>, C<text/x-markdown> or C<text/x-pod>. By default this is C<text/html>. The preferred data type is specified with the property C<accept>.

The following options are also supported:

=over 8

=item * C<accept>

This value instructs the MetaCPAN API to return the pod data in the desired format.

Supported formats are: C<text/html>, C<text/plain>, C<text/x-markdown>, C<text/x-pod>

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fpod%2FHTTP%3A%3AMessage> to see the data returned by the CPAN REST API.

=item * C<render> -> C</pod_render>

If the property C<render> is provided with a string of C<POD> data, this will issue a query to the endpoint C</pod_render>, such as:

    /pod_render?pod=%3Dencoding+utf-8%0A%0A%3Dhead1+Hello+World%0A%0ASomething+here%0A%0A%3Doops%0A%0A%3Dcut%0A

For example:

    my $html = $cpan->pod(
        render => qq{=encoding utf-8\n\n=head1 Hello World\n\nSomething here\n\n=oops\n\n=cut\n}
    ) || die( $cpan->error );

This would return a string of C<HTML> formatted data.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fpod_render%3Fpod%3D%253Dencoding%2Butf-8%250A%250A%253Dhead1%2BHello%2BWorld%250A%250ASomething%2Bhere%250A%250A%253Doops%250A%250A%253Dcut%250A> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 rating

    # Queries permissions with a simple search
    my $list_obj = $cpan->rating(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Queries permissions with an advanced search using ElasticSearch format
    my $list_obj = $cpan->rating( $filter_object ) ||
        die( $cpan->error );

    # Retrieves rating information details of the specified distribution
    my $list_obj = $cpan->rating(
        distribution => 'HTTP-Tiny',
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve C<rating> historical data for the specified search query or C<distribution>.

It is worth mentioning that although this endpoint still works, CPAN Ratings has been decommissioned some time ago, and thus its usefulness is questionable.

=over 4

=item * C<query> -> C</rating>

If the property C<query> is provided, this will trigger a simple search query to the endpoint C</rating>, such as:

    /rating?q=HTTP

For example:

    my $list_obj = $cpan->rating(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

will find all C<ratings> related to C<HTTP>.

This would return a L<Net::API::CPAN::List> object upon success.

The following options are also supported:

=over 8

=item * C<from>

An integer representing the offset starting from 0 within the total data.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frating%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

=item * L<search filter|Net::API::CPAN::Filter> -> C</rating>

And if a L<search filter|Net::API::CPAN::Filter> is passed, this will trigger a more advanced ElasticSearch query to the endpoint C</rating> using the C<HTTP> C<POST> method. See the L<Net::API::CPAN::Filter> module on more details on what granular queries you can execute.

=item * C<distribution> -> C</rating/by_distributions>

If a property C<distribution> is provided, this will issue a query to the endpoint C</rating/by_distributions> to retrieve rating information details of the specified distribution, such as:

    /rating/by_distributions?distribution=HTTP-Tiny

For example:

    my $list_obj = $cpan->rating(
        distribution => 'HTTP-Tiny',
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Rating> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frating%2Fby_distributions%3Fdistribution%3DHTTP-Tiny> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 release

    # Perform a simple query
    my $list_obj = $cpan->release(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

    # Perform an advanced query using ElasticSearch format
    my $list_obj = $cpan->release( $filter_object ) ||
        die( $cpan->error );

    # Retrieves a list of all releases for a given author
    my $list_obj = $cpan->release(
        all => 'OALDERS',
        page => 2,
        size => 100,
    ) || die( $cpan->error );

    # Retrieves a shorter list of all releases for a given author
    my $list_obj = $cpan->release( author => 'OALDERS' ) ||
        die( $cpan->error );

    # Retrieve a release information details
    my $release_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
    ) || die( $cpan->error );

    # Retrieves the latest distribution release information details
    my $release_obj = $cpan->release(
        distribution => 'HTTP-Message',
    ) || die( $cpan->error );

    # Retrieves the list of contributors for the specified distributions
    my $list_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        contributors => 1,
    ) || die( $cpan->error );

    # Retrieves the list of release key files by category
    my $hash_ref = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        files => 1,
    ) || die( $cpan->error );

    # Retrieves the list of interesting files for the given release
    my $list_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        # You can also use just 'interesting'
        interesting_files => 1,
    ) || die( $cpan->error );

    # Get latest releases by the specified author
    my $list_obj = $cpan->release(
        author => 'OALDERS',
        latest => 1,
    ) || die( $cpan->error );

    # Get the latest releases for the specified distribution
    my $release_obj = $cpan->release(
        distribution => 'HTTP-Message',
        latest => 1,
    ) || die( $cpan->error );

    # Retrieves the list of modules in the specified release
    my $list_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        modules => 1,
    ) || die( $cpan->error );

    # Get the list of recent releases
    my $list_obj = $cpan->release(
        recent => 1,
    ) || die( $cpan->error );

    # get all releases by versions for the specified distribution
    my $list_obj = $cpan->release(
        versions => 'HTTP-Message',
    ) || die( $cpan->error );

This method is used to query the CPAN REST API to retrieve C<release> information.

=over 4

=item * C<query> -> C</release>

If the property C<query> is provided, this will trigger a simple search query to the endpoint C</release>, such as:

    /release?q=HTTP

For example:

    my $list_obj = $cpan->release(
        query => 'HTTP',
        from => 10,
        size => 10,
    ) || die( $cpan->error );

will find all C<releases> related to C<HTTP>.

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Release> objects.

The following options are also supported:

=over 8

=item * C<from>

An integer representing the offset starting from 0 within the total data.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

=item * L<search filter|Net::API::CPAN::Filter> -> C</release>

And if a L<search filter|Net::API::CPAN::Filter> is passed, this will trigger a more advanced ElasticSearch query to the endpoint C</release> using the C<HTTP> C<POST> method. See the L<Net::API::CPAN::Filter> module on more details on what granular queries you can execute.

=item * C<all> -> C</release/all_by_author/{author}>

If the property C<all> is provided, this will issue a query to the endpoint C</release/all_by_author/{author}> to get all releases by the specified author, such as:

    /release/all_by_author/OALDERS?page=2&page_size=100

For example:

    my $list_obj = $cpan->release(
        all => 'OALDERS',
        page => 2,
        size => 100,
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Release> objects.

The following options are also supported:

=over 8

=item * C<page>

An integer representing the page offset starting from 1.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Fall_by_author%2FOALDERS%3Fpage%3D1%26page_size%3D100> to see the data returned by the CPAN REST API.

=item * C<author> -> C</release/by_author/{author}>

If the property C<author> alone is provided, this will issue a query to the endpoint C</release/by_author/{author}> to get releases by author, such as:

    /release/by_author/OALDERS

For example:

    my $list_obj = $cpan->release( author => 'OALDERS' ) ||
        die( $cpan->error );

This would return a L<Net::API::CPAN::List> object upon success.

Note that this is similar to C<all>, but returns a subset of all the author's data.

The following options are also supported:

=over 8

=item * C<page>

An integer representing the page offset starting from 1.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Fby_author%2FOALDERS> to see the data returned by the CPAN REST API.

=item * C<author> and C<release> -> C</v1/release/{author}/{release}>

If the property C<author> and C<release> are provided, this will issue a query to the endpoint C</v1/release/{author}/{release}> tp retrieve a distribution release information, such as:

    /release/OALDERS/HTTP-Message-6.36

For example:

    my $release_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
    ) || die( $cpan->error );

This would return a L<Net::API::CPAN::Release> object upon success.

The following options are also supported:

=over 8

=item * C<join>

You can join a.k.a. merge other objects data by setting C<join> to that object type, such as C<module> or C<author>. C<join> value can be either a string or an array of object types.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2FOALDERS%2FHTTP-Message-6.36> to see the data returned by the CPAN REST API.

=item * C<distribution> -> C</release/{distribution}>

If the property C<distribution> alone is provided, this will issue a query to the endpoint C</release/{distribution}> to retrieve a release information details., such as:

    /release/HTTP-Message

For example:

    my $release_obj = $cpan->release(
        distribution => 'HTTP-Message',
    ) || die( $cpan->error );

This would return a L<Net::API::CPAN::Release> object upon success.

The following options are also supported:

=over 8

=item * C<join>

You can join a.k.a. merge other objects data by setting C<join> to that object type, such as C<module> or C<author>. C<join> value can be either a string or an array of object types.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2FHTTP-Message> to see the data returned by the CPAN REST API.

=item * C<contributors>, C<author> and C<release> -> C</release/contributors/{author}/{release}>

If the property C<contributors>, C<author> and C<release> are provided, this will issue a query to the endpoint C</release/contributors/{author}/{release}> to retrieve the list of contributors for the specified release, such as:

    /release/contributors/OALDERS/HTTP-Message-6.36

For example:

    my $list_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        contributors => 1,
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Release> objects.
:List> object upon success.

The following options are also supported:

=over 8

=item * C<join>

You can join a.k.a. merge other objects data by setting C<join> to that object type, such as C<module> or C<author>. C<join> value can be either a string or an array of object types.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Fcontributors%2FOALDERS%2FHTTP-Message-6.36> to see the data returned by the CPAN REST API.

=item * C<files>, C<author> and C<release> -> C</release/files_by_category/{author}/{release}>

If the property C<files>, C<author> and C<release> are provided, this will issue a query to the endpoint C</release/files_by_category/{author}/{release}> to retrieve the list of key files by category for the specified release, such as:

    /release/files_by_category/OALDERS/HTTP-Message-6.36

For example:

    my $hash_ref = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        files => 1,
    ) || die( $cpan->error );

This would return an L<hash object|Module::Generic::Hash> of the following category names, each having, as their value, an array of the specified C<release> files.

The categories are:

=over 8

=item * C<changelog>

This is typically the C<Changes> or C<CHANGES> file.

=item * C<contributing>

This is typically the C<CONTRIBUTING.md> file.

=item * C<dist>

This is typically other files that are part of the C<release>, such as C<cpanfile>, C<Makefile.PL>, C<dist.ini>, C<META.json>, C<META.yml>, C<MANIFEST>.

=item * C<install>

This is typically the C<INSTALL> file.

=item * C<license>

This is typically the C<LICENSE> file.

=item * C<other>

This is typically the C<README.md> file.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Ffiles_by_category%2FOALDERS%2FHTTP-Message-6.36> to see the data returned by the CPAN REST API.

=item * C<interesting_files>, C<author> and C<release> -> C</release/interesting_files/{author}/{release}>

If the property C<interesting_files> (or also just C<interesting>), C<author> and C<release> are provided, this will issue a query to the endpoint C</release/interesting_files/{author}/{release}> to retrieve the list of release interesting files for the specified release, such as:

    /release/interesting_files/OALDERS/HTTP-Message-6.36

For example:

    my $list_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        interesting_files => 1,
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Release> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Finteresting_files%2FOALDERS%2FHTTP-Message-6.36> to see the data returned by the CPAN REST API.

=item * C<latest>, and C<author> -> C</release/latest_by_author/{author}>

If the property C<latest>, and C<author> are provided, this will issue a query to the endpoint C</release/latest_by_author/{author}> to retrieve the latest releases by the specified author, such as:

    /release/latest_by_author/OALDERS

For example:

    my $list_obj = $cpan->release(
        author => 'OALDERS',
        latest => 1,
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Release> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Flatest_by_author%2FOALDERS> to see the data returned by the CPAN REST API.

=item * C<latest>, and C<distribution> -> C</release/latest_by_distribution/{distribution}>

If the property C<latest>, and C<distribution> are provided, this will issue a query to the endpoint C</release/latest_by_distribution/{distribution}> to retrieve the latest releases of the specified distribution, such as:

    /release/latest_by_distribution/HTTP-Message

For example:

    my $release_obj = $cpan->release(
        distribution => 'HTTP-Message',
        latest => 1,
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::Release> object representing the latest C<release> for the specified C<distribution>.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Flatest_by_distribution%2FHTTP-Message> to see the data returned by the CPAN REST API.

=item * C<modules>, C<author>, and C<release> -> C</release/modules/{author}/{release}>

If the property C<modules>, C<author>, and C<release> are provided, this will issue a query to the endpoint C</release/modules/{author}/{release}> to retrieve the list of modules in the specified distribution, such as:

    /release/modules/OALDERS/HTTP-Message-6.36

For example:

    my $list_obj = $cpan->release(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        modules => 1,
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Release> objects.

The following options are also supported:

=over 8

=item * C<join>

You can join a.k.a. merge other objects data by setting C<join> to that object type, such as C<module> or C<author>. C<join> value can be either a string or an array of object types.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Fmodules%2FOALDERS%2FHTTP-Message-6.36> to see the data returned by the CPAN REST API.

=item * C<recent> -> C</release/recent>

If the property C<recent>, alone is provided, this will issue a query to the endpoint C</release/recent> to retrieve the list of recent releases, such as:

    /release/recent

For example:

    my $list_obj = $cpan->release(
        recent => 1,
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Release> objects.

The following options are also supported:

=over 8

=item * C<page>

An integer specifying the page offset starting from 1.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Frecent> to see the data returned by the CPAN REST API.

=item * C<versions> -> C<distribution>

If the property C<versions> is provided having a value representing a C<distribution>, this will issue a query to the endpoint C</release/versions/{distribution}> to retrieve all releases by versions for the specified distribution, such as:

    /release/versions/HTTP-Message

For example:

    my $list_obj = $cpan->release(
        distribution => 'HTTP-Message',
        # or, alternatively: version => '6.35,6.36,6.34',
        versions => [qw( 6.35 6.36 6.34 )],
        # Set this to true to get a raw list of version -> download URL instead of a list object
        # plain => 1,
    ) || die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of all the C<distribution> versions released.

The following options are also supported:

=over 8

=item * C<versions>

An array reference of versions to return, or a string specifying the version(s) to return as a comma-sepated value

=item * C<plain>

A boolean value specifying whether the result should be returned in plain mode.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Fversions%2FHTTP-Message> to see the data returned by the CPAN REST API and L<here for the result in plain text mode|https://explorer.metacpan.org/?url=%2Frelease%2Fversions%2FHTTP-Message%3Fplain%3D1>.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 reverse

    # Returns a list of all the modules who depend on the specified distribution
    my $list_obj = $cpan->reverse( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

    # Returns a list of all the modules who depend on the specified module
    my $list_obj = $cpan->reverse( module => 'HTTP::Message' ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve reverse dependencies, i.e. releases on C<CPAN> that depend on the specified C<distribution> or C<module>.

=over 4

=item * C<distribution> -> C</reverse_dependencies/dist/{distribution}>

If the property C<distribution> representing a distribution is provided, this will issue a query to the endpoint C</reverse_dependencies/dist/{distribution}> to retrieve a list of all the modules who depend on the specified distribution, such as:

    /reverse_dependencies/dist/HTTP-Message

For example:

    my $list_obj = $cpan->reverse( distribution => 'HTTP-Message' ) ||
        die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Release> objects.

The following options are also supported:

=over 8

=item * C<page>

An integer representing the page offset starting from 1.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=item * C<sort>

A string representing a field specifying how the result is sorted.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Freverse_dependencies%2Fdist%2FHTTP-Message> to see the data returned by the CPAN REST API.

=item * C<module> -> C</reverse_dependencies/module/{module}>

If the property C<module> representing a module is provided, this will issue a query to the endpoint C</reverse_dependencies/module/{module}> to retrieve a list of all the modules who depend on the specified module, such as:

    /reverse_dependencies/module/HTTP::Message

For example:

    my $list_obj = $cpan->reverse( module => 'HTTP::Message' ) ||
        die( $cpan->error );

This would return, upon success, a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Release> objects.

The following options are also supported:

=over 8

=item * C<page>

An integer representing the page offset starting from 1.

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=item * C<sort>

A string representing a field specifying how the result is sorted.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Freverse_dependencies%2Fmodule%2FHTTP%3A%3AMessage> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 reverse_dependencies

This is an alias for L</reverse>

=head2 search

Provided with an hash or hash reference of options and this performs a search query and returns a L<Net::API::CPAN::List> object, or an L<Net::API::CPAN::Scroll> depending on the type of search query requested.

There are 3 types of search query:

=over 4

=item 1. Using L<HTTP GET method|https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#get-searches>

=item 2. Using L<HTTP POST method|https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#post-searches> with L<Elastic Search query|Net::API::CPAN::Filter>

=item 3. Using L<HTTP POST method|https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md#post-searches> with Elastic Search query using L<scroll|Net::API::CPAN::Scroll>

=back

=head2 source

    # Retrieves the source code of the given module path within the specified release
    my $string = $cpan->source(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

    # Retrieves the full source of the latest, authorized version of the specified module
    my $string = $cpan->source( module => 'HTTP::Message' ) ||
        die( $cpan->error );

This method is used to query the CPAN REST API to retrieve the source code or data of the specified C<release> element or C<module>.

=over 4

=item * C<author>, C<release> and C<path> -> C</source/{author}/{release}/{path}>

If the properties C<author>, C<release> and C<path> are provided, this will issue a query to the endpoint C</source/{author}/{release}/{path}> to retrieve the source code of the given module path within the specified release, such as:

    /source/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm

For example:

    my $string = $cpan->source(
        author => 'OALDERS',
        release => 'HTTP-Message-6.36',
        path => 'lib/HTTP/Message.pm',
    ) || die( $cpan->error );

This will return a string representing the source data of the file located at the specified C<path> and C<release>.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fsource%2FOALDERS%2FHTTP-Message-6.36%2Flib%2FHTTP%2FMessage.pm> to see the data returned by the CPAN REST API.

=item * C<module> -> C</source/{module}>

If the properties C<module> is provided, this will issue a query to the endpoint C</source/{module}> to retrieve the full source of the latest, authorized version of the specified module, such as:

    /source/HTTP::Message

For example:

    my $string = $cpan->source( module => 'HTTP::Message' ) ||
        die( $cpan->error );

This will return a string representing the source data of the specified C<module>.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fsource%2FHTTP%3A%3AMessage> to see the data returned by the CPAN REST API.

=back

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 suggest

This takes a string and will issue a query to the endpoint C</search/autocomplete/suggest> to retrieve the suggested result set based on the autocomplete search query, such as:

    /search/autocomplete/suggest?q=HTTP

For example:

    my $list_obj = $cpan->suggest( query => 'HTTP' ) || die( $cpan->error );

This would, upon success, return a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Release::Suggest> objects.

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fsearch%2Fautocomplete%2Fsuggest%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

=head2 top_uploaders

This will issue a query to the endpoint C</release/top_uploaders> to retrieve an L<hash object|Module::Generic::Hash> of the top uploading C<authors> with the total as the key's value, such as:

    /release/top_uploaders

For example:

    my $hash_ref = $cpan->top_uploaders || die( $cpan->error );

This would return, upon success, an L<hash object|Module::Generic::Hash> of C<author> and their recent total number of C<release> upload on C<CPAN>

For example:

    {
        OALDERS => 12,
        NEILB => 7,
    }

The following options are also supported:

=over 8

=item * C<range>

A string specifying the result range. Valid values are C<all>, C<weekly>, C<monthly> or C<yearly>. It defaults to C<weekly>

=item * C<size>

An integer representing the size of each page, i.e. how many results are returned per page. This usually defaults to 10.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Frelease%2Ftop_uploaders> to see the data returned by the CPAN REST API.

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head2 web

This takes a string and will issue a query to the endpoint C</search/web> to retrieve the result set based on the search query specified similar to the one on the MetaCPAN website, such as:

    /search/web?q=HTTP

For example:

    my $list_obj = $cpan->web(
        query => 'HTTP',
        from => 0,
        size => 10,
    ) || die( $cpan->error );

This would, upon success, return a L<Net::API::CPAN::List> object of L<Net::API::CPAN::Module> objects.

Search terms can be:

=over 8

=item * can be unqualified string, such as C<paging>

=item * can be author, such as C<author:OALDERS>

=item * can be module, such as C<module:HTTP::Message>

=item * can be distribution, such as C<dist:HTTP-Message>

=back

The following options are also supported:

=over 8

=item * C<collapsed>

Boolean. When used, this forces a collapsed even when searching for a particular distribution or module name.

=item * C<from>

An integer that represents offset to use in the result set.

=item * C<size>

An integer that represents the number of results per page.

=back

You can try it out on L<CPAN Explorer|https://explorer.metacpan.org/?url=%2Fsearch%2Fweb%3Fq%3DHTTP> to see the data returned by the CPAN REST API.

Upon failure, an L<error|Net::API::CPAN::Exception> will be set and C<undef> will be returned in scalar context, or an empty list in list context.

=head1 TERMINOLOGY

The MetaCPAN REST API has quite a few endpoints returning sets of data containing properties. Below are the meanings of some of those keywords:

=over 4

=item * C<author>

For example C<JOHNDOE>

This is a C<CPAN> id, and C<distribution> author. It is also referred as C<cpanid>

=item * C<cpanid>

For example C<JOHNDOE>

See C<author>

=item * C<contributor>

For example: C<JOHNDOE>

A C<contributor> is a C<CPAN> author who is contributing code to an C<author>'s C<distribution>.

=item * C<distribution>

For example: C<HTTP-Message>

This is a bundle of modules distributed over C<CPAN> and available for download. A C<distribution> goes through a series of C<releases> over the course of its lifetime.

=item * C<favorite>

C<favorite> relates to the appreciation a C<distribution> received by having registered and non-registered user marking it as one of their favorite distributions.

=item * C<file>

A C<file> is an element of a C<distribution>

=item * C<module>

For example C<HTTP::Message>

This has the same meaning as in Perl. See L<perlmod> for more information on Perl modules.

=item * C<package>

For example C<HTTP::Message>

This is similar to C<module>, but a C<package> is a C<class> and a C<module> is a file.

=item * C<permission>

A C<permission> defines the role a user has over a C<distribution> and is one of C<owner> or C<co_maintainer>

=item * C<release>

For example: C<HTTP-Message-6.36>

A C<release> is a C<distribution> being released with a unique version number.

=item * C<reverse_dependencies>

This relates to the C<distributions> depending on any given C<distribution>

=back

=head1 ERRORS

This module does not die or croak, but instead set an L<error object|Net::API::CPAN::Exception> using L<Module::Generic/error> and returns C<undef> in scalar context, or an empty list in list context.

You can retrieve the latest error object set by calling L<error|Module::Generic/error> inherited from L<Module::Generic>

Errors issued by this distributions are all instances of class L<Net::API::CPAN::Exception>

=head1 METACPAN OPENAPI SPECIFICATIONS

From the information I could gather, L<I have produced the specifications|https://gitlab.com/jackdeguest/Net-API-CPAN/-/blob/master/build/cpan-openapi-spec-3.0.0.pl> for L<Open API|https://spec.openapis.org/oas/v3.0.0> v3.0.0 for your reference. You can also find it L<here|https://gitlab.com/jackdeguest/Net-API-CPAN/-/blob/master/build/cpan-openapi-spec-3.0.0.json> in C<JSON> format.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Meta CPAN API documentation|https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md>

L<https://metacpan.org/>, L<https://www.cpan.org/>

L<Net::API::CPAN::Activity>, L<Net::API::CPAN::Author>, L<Net::API::CPAN::Changes>, L<Net::API::CPAN::Changes::Release>, L<Net::API::CPAN::Contributor>, L<Net::API::CPAN::Cover>, L<Net::API::CPAN::Diff>, L<Net::API::CPAN::Distribution>, L<Net::API::CPAN::DownloadUrl>, L<Net::API::CPAN::Favorite>, L<Net::API::CPAN::File>, L<Net::API::CPAN::Module>, L<Net::API::CPAN::Package>, L<Net::API::CPAN::Permission>, L<Net::API::CPAN::Rating>, L<Net::API::CPAN::Release>

L<Net::API::CPAN::Filter>, L<Net::API::CPAN::List>, L<Net::API::CPAN::Scroll>

L<Net::API::CPAN::Mock>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
