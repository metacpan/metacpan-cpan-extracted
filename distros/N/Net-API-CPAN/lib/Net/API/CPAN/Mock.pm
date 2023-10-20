##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Mock.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/08/12
## Modified 2023/08/12
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::CPAN::Mock;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $DATA $TEST_DATA @STANDARD_HEADERS $DIFF_RAW_TEMPLATE $DIFF_JSON_TEMPLATE );
    use curry;
    use Changes::Version;
    use DateTime;
    use DateTime::Format::Strptime;
    use Encode ();
    use HTTP::Promise::Parser;
    use HTTP::Promise::Response;
    use HTTP::Promise::Status;
    use IO::Handle;
    use Socket;
    use URI;
    use constant DEFAULT_LANG => 'en_GB';
    our $VERSION = 'v0.1.0';
    our @STANDARD_HEADERS = (
        Server => "CPAN-Mock/$VERSION",
    );
};

use strict;
use warnings;
use utf8;

sub init
{
    my $self = shift( @_ );
    # OpenAPI specifications file checksum for caching
    $self->{checksum}   = undef unless( exists( $self->{checksum} ) );
    # OpenAPI resulting endpoints we derived from the specs
    $self->{endpoints}  = undef unless( exists( $self->{endpoints} ) );
    $self->{host}       = undef unless( exists( $self->{host} ) );
    # OpenAPI specifications file
    $self->{openapi}    = undef unless( exists( $self->{openapi} ) );
    $self->{port}       = undef unless( exists( $self->{port} ) );
    $self->{pretty}     = 0 unless( exists( $self->{pretty} ) );
    # OpenAPI JSON specifications as perl data
    $self->{specs}      = undef unless( exists( $self->{specs} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    if( $self->{specs} )
    {
        $self->load_specs( $self->{specs} ) || return( $self->pass_error );
    }
    $self->{json} = $self->new_json;
    $self->{json}->pretty(1)->canonical(1) if( $self->pretty );
    unless( $TEST_DATA )
    {
        $DATA = Encode::decode_utf8( $DATA ) if( !Encode::is_utf8( $DATA ) );
        $TEST_DATA = eval( $DATA );
        if( $@ )
        {
            die( $@ );
        }
    }
    return( $self );
}

# See perlipc/"Sockets: Client/Server Communication"
sub bind
{
    my $self = shift( @_ );
    my $socket;
    unless( $socket = $self->socket )
    {
        my $proto = getprotobyname('tcp') ||
            return( $self->error( "Unable to get TCP proto: $!" ) );
        my $s;
        socket( $s, PF_INET, SOCK_STREAM, $proto ) ||
          return( $self->error( "Unable to get socket: $!" ) );
        my $host = $self->{host} || '127.0.0.1';
        my $bin = Socket::inet_aton( $host ) ||
            return( $self->error( "Unable to resolve $host: $!" ) );
        my $port;
        while(1)
        {
            $port = $self->{port} || int( rand( 5000 ) ) + 10000;
            # To prevent next cycle to use it again
            $self->{port} = undef;
            my $addr = Socket::pack_sockaddr_in( $port, $bin );
            bind( $s, $addr ) || next;
            listen( $s, 10 ) || return( $self->error( "Unable to listen on host $host with port $port: $!" ) );
            last;
        }
        $self->host( $host );
        $self->port( $port );
        $self->socket( $s );
    }
    return( $self );
}

sub checksum { return( shift->_set_get_scalar( 'checksum', @_ ) ); }

sub data { return( $TEST_DATA ); }

sub endpoints { return( shift->_set_get_hash_as_mix_object( 'endpoints', @_ ) ); }

sub host
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{host} = shift( @_ );
    }
    else
    {
        $self->bind || return( $self->pass_error );
    }
    return( $self->{host} );
}

sub json { return( shift->_set_get_object( 'json', 'JSON', @_ ) ); }

sub load_specs
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No openapi specifications file was provided." ) );
    $file = $self->new_file( $file );
    if( !$file->exists )
    {
        return( $self->error( "OpenAPI specifications file provided $file does not exist." ) );
    }
    elsif( !$file->is_file )
    {
        return( $self->error( "OpenAPI specifications file provided $file is not a regular file." ) );
    }
    elsif( $file->is_empty )
    {
        return( $self->error( "OpenAPI specifications file provided $file is empty." ) );
    }
    my $checksum = $file->checksum_md5;
    if( $self->{checksum} &&
        $self->{checksum} eq $checksum &&
        $self->{specs} &&
        ref( $self->{specs} ) eq 'HASH' &&
        scalar( keys( %{$self->{specs}} ) ) )
    {
        warn( "Called to reprocess the OpenAPI specification, but we already have a cache, so re-using the cache instead.\n" ) if( $self->_is_warnings_enabled );
        return( $self );
    }
    my $specs = $file->load_json( boolean_values => [0,1] ) || return( $self->pass_error( $file->error ) );
    my $paths = $specs->{paths} || return( $self->error( "No 'paths' property found in the openapi specifications provided." ) );
    return( $self->error( "The 'paths' property found is not an hash reference." ) ) if( !defined( $paths ) || ref( $paths ) ne 'HASH' );
    $self->{specs} = $specs;
    $self->{checksum} = $file->checksum_md5;
    my $def = {};
    
    my $seen = {};
    my $processed = {};

    # NOTE: resolve_ref()
    my $resolve_ref = sub
    {
        my $schema = shift( @_ );
        my $opts = $self->_get_args_as_hash( @_ );
        my $ctx = $opts->{context};
        # Already processed previously
        if( ref( $schema ) eq 'HASH' &&
            exists( $processed->{ $self->_refaddr( $schema ) } ) )
        {
            return( $schema );
        }
    
        return( $self->error( "Found a schema reference (\$ref) for path $ctx->{path} and method $ctx->{method}, but its value is not a plain string (", overload::StrVal( $schema ), ")" ) ) if( ref( $schema ) );
        # This is valid, but unsupported by us.
        # <https://spec.openapis.org/oas/v3.0.0#reference-object>
        # <https://spec.openapis.org/oas/v3.0.0#example-object-example>
        if( lc( substr( $schema, 0, 4 ) // '' ) eq 'http' )
        {
            return( $self->error( "External http schema reference is not supported by this tool for path $ctx->{path} and method $ctx->{method}" ) );
        }
        return( $self->error( "Schema reference set for path $ctx->{path} and method $ctx->{method} should start with '#/', but it does not ($schema)." ) ) unless( substr( $schema, 0, 2 ) eq '#/' );
        # Prevent infinite recursion
        if( exists( $seen->{ $schema } ) )
        {
            return( $seen->{ $schema } );
        }
        $schema = substr( $schema, 2 );
        my $frags = [split( /\//, $schema )];
        scalar( @$frags ) || 
            return( $self->error( "The schema reference for path $ctx->{path} and method $ctx->{method} does not have any schema value." ) );
        $self->message( 4, "Checking the path fragments '", join( "', '", @$frags ), "'" );
        my $tmp = $specs;
        my $breadcrumbs = ['/'];
        for( my $i = 0; $i < scalar( @$frags ); $i++ )
        {
            $self->message( 4, "Checking path fragment '", $frags->[$i], "'" );
            if( exists( $tmp->{ $frags->[$i] } ) )
            {
                $tmp = $tmp->{ $frags->[$i] };
                push( @$breadcrumbs, $frags->[$i] );
            }
            else
            {
                return( $self->error( "Unable to find path fragment '", $frags->[$i], "' in OpenAPI specifications in ", join( '/', @$breadcrumbs ), " for path $ctx->{path} and method $ctx->{method}" ) );
            }
        }
        $seen->{ $schema } = $tmp;
        $processed->{ $self->_refaddr( $tmp ) } = $tmp;
        return( $tmp );
    };

    # NOTE: been_there()
    my $crawl;
    my $been_there = {};
    $crawl = sub
    {
        my $ref = shift( @_ );
        my $opts = $self->_get_args_as_hash( @_ );
        my $ctx = $opts->{context};
        my $type = lc( ref( $ref ) // '' );
        if( $type eq 'hash' )
        {
            foreach my $prop ( keys( %$ref ) )
            {
                if( $prop eq '$ref' )
                {
                    my $schema = $ref->{ $prop };
                    my $tmp = $resolve_ref->( $schema, context => $ctx ) || return( $self->pass_error );
                    $ref->{ $prop } = $tmp;
                }
                elsif( ref( $ref->{ $prop } ) )
                {
                    if( ++$been_there->{ $self->_refaddr( $ref->{ $prop } ) } > 1 )
                    {
                        next;
                    }
                    $crawl->( $ref->{ $prop }, context => $ctx ) || return( $self->pass_error );
                }
            }
        }
        elsif( $type eq 'array' )
        {
            for( my $i = 0; $i < scalar( @$ref ); $i++ )
            {
                if( ref( $ref->[$i] ) )
                {
                    if( ++$been_there->{ $self->_refaddr( $ref->[$i] ) } > 1 )
                    {
                        next;
                    }
                    $crawl->( $ref->[$i], context => $ctx ) || return( $self->pass_error );
                }
            }
        }
        return(1);
    };

    # NOTE: load_properties()
    my $circular_props = {};
    my $load_properties;
    $load_properties = sub
    {
        my $hash = shift( @_ ) || return( $self->error( "No schema specification hash reference was provided." ) );
        return( $self->error( "Data provided to parse is not an hash reference." ) ) if( ref( $hash ) ne 'HASH' );
        my $opts = $self->_get_args_as_hash( @_ );
        my $ctx = $opts->{context};
        $opts->{prefix} = [] if( !exists( $opts->{prefix} ) );
        my $prefix = join( '', @{$opts->{prefix}} );
    
        my $props;
        if( exists( $hash->{ '$ref' } ) )
        {
            $self->message( 4, "${prefix} Found schema reference \$ref -> '", $hash->{ '$ref' }, "'." );
            my $schema_def = $resolve_ref->( $hash->{ '$ref' }, context => $ctx ) || return( $self->pass_error );
            $self->message( 4, "${prefix} \$ref '", $hash->{ '$ref' }, "' resolved to ${schema_def} with keys -> '", sub{ join( "', '", sort( keys( %$schema_def ) ) ) }, "'" );
            
            # e.g.: <https://gist.github.com/xygon/82cd827dd8979167bc6287bafc9eaf84>
            if( exists( $schema_def->{allOf} ) )
            {
                $self->message( 4, "${prefix} Found allOf." );
                if( ref( $schema_def->{allOf} ) ne 'ARRAY' )
                {
                    return( $self->error( "Found property 'allOf' in this schema for path $ctx->{path} and method $ctx->{method}, but this is not an array reference." ) );
                }
                my $tmp = {};
                foreach my $elem ( @{$schema_def->{allOf}} )
                {
                    $self->message( 4, "${prefix}[allOf] Processing $elem" );
                    if( ref( $elem ) ne 'HASH' )
                    {
                        return( $self->error( "I was expecting an hash reference, but instead I got '$elem' for ${prefix}" ) );
                    }
                    
                    if( ++$circular_props->{ $self->_refaddr( $elem ) } > 1 )
                    {
                        next;
                    }
                    my $tmp_props = $load_properties->( $elem, 
                        context => $ctx,
                        prefix => [@{$opts->{prefix}}, '[allOf]'],
                    ) || return( $self->pass_error );
                    $self->message( 4, "${prefix}[allOf] Found properties with keys '", sub{ join( "', '", sort( keys( %$tmp_props ) ) ) }, "'" );
                    my @tmp_keys = keys( %$tmp_props );
                    @$tmp{ @tmp_keys } = @$tmp_props{ @tmp_keys };
                }
                $props = $tmp;
                $self->message( 4, "${prefix} \$props is '", ( $props // 'undef' ), "'" );
            }
            elsif( !exists( $schema_def->{properties} ) )
            {
                $self->message( 4, "${prefix} \$ref error: no 'properties' found." );
                return( $self->error( "Unable to find the property 'properties' in this schema definition for path $ctx->{path} and method $ctx->{method}" ) );
            }
            else
            {
                $props = $schema_def->{properties};
            }
        }
        elsif( exists( $hash->{properties} ) )
        {
            $self->message( 4, "${prefix} Found schema properties with keys '", sub{ join( "', '", sort( keys( %{$hash->{properties}} ) ) ) }, "'" );
            if( !exists( $hash->{type} ) ||
                $hash->{type} ne 'object' )
            {
                warn( "Warning only: no 'type' property set to 'object' could be found with the property 'properties' for path $ctx->{path} and method $ctx->{method}.\n" ) if( $self->_is_warnings_enabled );
            }
            $props = $hash->{properties};
        }
        # <https://spec.openapis.org/oas/v3.0.0#path-item-object-example>
        # <https://spec.openapis.org/oas/v3.0.0#paths-object-example>
        # <https://stackoverflow.com/questions/47656791/openapi-multiple-types-inside-an-array>
        # "schema": {
        #   "type": "array",
        #   "items": {
        #     "$ref": "#/components/schemas/Pet"
        #   }
        # }
        # or:
        # "schema": {
        #   "type": "array",
        #   "items": {
        #     "type": "string"
        #   }
        # }
        # or:
        # "schema": {
        #   "type": "array",
        #   "items": {
        #     "anyOf": [
        #       { "$ref": "#/components/schemas/Pet" },
        #       { "$ref": "#/components/schemas/Cat" },
        #       { "$ref": "#/components/schemas/Dog" }
        #     ]
        #   }
        # }
        # or:
        # "schema": {
        #   "type": "array",
        #   "items": {
        #     "type": "object",
        #     "properties": {
        #       "name": {
        #         "type": "string"
        #       },
        #       "status": {
        #         "type": "boolean"
        #       }
        #     }
        #   }
        # }
        elsif( exists( $hash->{type} ) &&
            defined( $hash->{type} ) &&
            $hash->{type} eq 'array' )
        {
            $self->message( 4, "${prefix} Found array." );
            if( !exists( $hash->{items} ) ||
                !defined( $hash->{items} ) ||
                ref( $hash->{items} ) ne 'HASH' )
            {
                return( $self->error( "Found an array for schema in path $ctx->{path} and method $ctx->{method}, but either there is no 'items' property, or it is not an hash reference." ) );
            }
            my $items = $hash->{items};
            my $subprops;
            # allOf, anyOf, oneOf
            if( exists( $items->{allOf} ) ||
                exists( $items->{anyOf} ) ||
                exists( $items->{oneOf} ) )
            {
                foreach my $t ( qw( allOf anyOf oneOf ) )
                {
                    next unless( exists( $items->{ $t } ) );
                    $subprops = $load_properties->( $items->{ $t },
                        context => $ctx,
                        prefix => [@{$opts->{prefix}}, '{items}', $t],
                    ) || return( $self->pass_error );
                    my @keys = scalar( keys( %$subprops ) );
                    @{$items->{ $t }}{ @keys } = @$subprops{ @keys };
                    last;
                }
            }
            else
            {
                $subprops = $load_properties->( $items,
                    context => $ctx,
                    prefix => [@{$opts->{prefix}}, '{items}']
                ) || return( $self->pass_error );
                my @keys = scalar( keys( %$subprops ) );
                @$items{ @keys } = @$subprops{ @keys };
            }
            $props = $items;
        }
        elsif( exists( $hash->{type} ) )
        {
            $self->message( 4, "${prefix} Found simple type definition -> '",$hash->{type}, "' ." );
            $props = $hash;
        }
        else
        {
            $self->message( 4, "${prefix} Error. Clueless as to what to do." );
            return( $self->error( "I was expecting either the property '\$ref' or 'properties' or some 'type', but could not find either in this schema definition for path $ctx->{path} and method $ctx->{method}" ) );
        }
        
        $self->message( 4, "${prefix} Returning \$props -> '", ( $props // 'undef' ), "'" );

        if( !defined( $props ) ||
            ref( $props ) ne 'HASH' )
        {
            return( $self->error( "The property 'properties' found for schema definition for path $ctx->{path} and method $ctx->{method} is not an hash reference!" ) );
        }
    
        # Make sure to resolve all references
        $crawl->( $props, context => $ctx ) || return( $self->pass_error );
        return( $props );
    };
    
    # Path and method by ID
    my $ids = {};
    # NOTE: Processing each path
    foreach my $path ( keys( %$paths ) )
    {
        my $p = { path => $path };
        return( $self->error( "Path definition for $path is not an hash reference." ) ) if( ref( $paths->{ $path } ) ne 'HASH' );
        # my $path_re = $path;
        # This does not work when the last variable is a path such as lib/Some/Module.pm
        # $path_re =~ s/\{([^\}]+)\}/\(\?<$1>\[^\\\/\\\?\]+\)/gs;
        my @parts = split( /\{([^\}]+)\}/, $path );
        my @elems = ();
        for( my $i = 0; $i < scalar( @parts ); $i++ )
        {
            # Odd entries are the endpoint variables
            if( $i % 2 )
            {
                if( $i == $#parts )
                {
                    push( @elems, '(?<' . $parts[$i] . '>.*?)$' );
                }
                else
                {
                    push( @elems, '(?<' . $parts[$i] . '>[^\/\?]+)' );
                }
            }
            else
            {
                push( @elems, $parts[$i] );
            }
        }
        my $path_re = join( '', @elems );
        foreach my $meth ( qw( delete get post put ) )
        {
            next unless( exists( $paths->{ $path }->{ $meth } ) );
            $def->{ $path } = {} if( !exists( $def->{ $path } ) );
            $def->{ $path }->{ $meth } = { path => $path, method => $meth };
            my $this = $paths->{ $path }->{ $meth };
            return( $self->error( "Method definition for path $path and method $meth is not an hash reference." ) ) if( ref( $this ) ne 'HASH' );
            $def->{ $path }->{ $meth }->{id} = $this->{operationId};
            if( exists( $ids->{ $this->{operationId} } ) )
            {
                return( $self->error( "Found the operation ID '$this->{operationId}' for method $meth in path $path, but there is already this ID for path ", $ids->{ $this->{operationId} }->{path}, " and method ", $ids->{ $this->{operationId} }->{method} ) );
            }
            $ids->{ $this->{operationId} } = $def->{ $path }->{ $meth };
            my $params = $this->{parameters};
            my $ep_params = [];
            my $query = {};
            foreach my $elem ( @$params )
            {
                next unless( defined( $elem ) && ref( $elem ) eq 'HASH' );
                if( $elem->{in} eq 'query' )
                {
                    $query->{ $elem->{name} } = exists( $elem->{schema} ) ? $elem->{schema}->{type} : 'string';
                }
                elsif( $elem->{in} eq 'path' )
                {
                    push( @$ep_params, { name => $elem->{name}, type => $elem->{type} } );
                }
            }
            $def->{ $path }->{ $meth }->{params} = $ep_params;
            $def->{ $path }->{ $meth }->{query} = $query;
            $def->{ $path }->{ $meth }->{endpoint_re} = qr/$path_re/;
            my $ok_content_types = [];
            unless( $meth eq 'get' || $meth eq 'delete' )
            {
                if( !exists( $this->{requestBody} ) )
                {
                    return( $self->error( "The path $path with method $meth is missing the 'requestBody' property'." ) );
                }
                elsif( !defined( $this->{requestBody} ) || ref( $this->{requestBody} ) ne 'HASH' )
                {
                    return( $self->error( "Property 'requestBody' in path $path for method $meth is not an hash reference." ) );
                }
                elsif( !exists( $this->{requestBody}->{content} ) ||
                       !defined( $this->{requestBody}->{content} ) ||
                       ref( $this->{requestBody}->{content} ) ne 'HASH' )
                {
                    return( $self->error( "Missing property 'content' or not an hash reference for path $path and method $meth" ) );
                }
                my $cts = $this->{requestBody}->{content};
                if( !scalar( keys( %$cts ) ) )
                {
                    push( @$ok_content_types, 'application/x-www-form-urlencoded' );
                }
                else
                {
                    push( @$ok_content_types, sort( keys( %$cts ) ) );
                }
                # TODO: Need to add the possible request parameters for later validation
            }
            $def->{ $path }->{ $meth }->{content_types} = $ok_content_types;
            # Response
            if( !exists( $this->{responses} ) )
            {
                return( $self->error( "The path $path with method $meth is missing the 'responses' property'." ) );
            }
            elsif( !defined( $this->{responses} ) ||
                   ref( $this->{responses} ) ne 'HASH' )
            {
                return( $self->error( "The path $path with method $meth has a property 'responses' that is not an hash reference." ) );
            }
            elsif( !scalar( keys( %{$this->{responses}} ) ) )
            {
                return( $self->error( "There is no possible responses set for the path $path and method $meth!" ) );
            }
            my $resps = {};
            foreach my $code ( keys( %{$this->{responses}} ) )
            {
                $resps->{ $code } = {};
                if( !defined( $this->{responses}->{ $code } ) ||
                    ref( $this->{responses}->{ $code } ) ne 'HASH' )
                {
                    return( $self->error( "The response code $code for path $path and method $meth is either not defined or not an hash reference." ) );
                }
                elsif( !exists( $this->{responses}->{ $code }->{content} ) )
                {
                    return( $self->error( "There is no 'content' property for response code $code for path $path and method $meth" ) );
                }
                elsif( !defined( $this->{responses}->{ $code }->{content} ) ||
                       ref( $this->{responses}->{ $code }->{content} ) ne 'HASH' )
                {
                    return( $self->error( "The 'content' property for the response code $code in path $path and method $meth is not an hash reference." ) );
                }
                # $ct could also be '*/*'
                # <https://spec.openapis.org/oas/v3.0.0#path-item-object-example>
                foreach my $ct ( sort( keys( %{$this->{responses}->{ $code }->{content}} ) ) )
                {
                    if( !exists( $this->{responses}->{ $code }->{content}->{ $ct }->{schema} ) )
                    {
                        return( $self->error( "Missing property 'schema' in this response for content-type $ct for the response code $code in path $path and method $meth" ) );
                    }
                    elsif( !defined( $this->{responses}->{ $code }->{content}->{ $ct }->{schema} ) ||
                        ref( $this->{responses}->{ $code }->{content}->{ $ct }->{schema} ) ne 'HASH' )
                    {
                        return( $self->error( "Property 'schema' found is not an hash reference in this response for content-type $ct for the response code $code in path $path and method $meth" ) );
                    }
                    # schema can either be a '$ref', or an object of 'properties', or some 'array', or some 'string', possibly with the format parameter
                    $self->message( 4, "\U${meth}\E ${path} Loading response properties..." );
                    my $props = $load_properties->( $this->{responses}->{ $code }->{content}->{ $ct }->{schema}, 
                        context => $def->{ $path }->{ $meth },
                        prefix => ["\U${meth}\E ${path}"],
                    ) || return( $self->pass_error );
                    $resps->{ $code }->{ $ct } = $props;
                }
            }
            $def->{ $path }->{ $meth }->{response} = $resps;
        }
    }
    $self->{endpoints} = $def;
    return( $self );
}

sub pid { return( shift->_set_get_scalar( 'pid', @_ ) ); }

sub port
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->{port} = shift( @_ );
    }
    else
    {
        $self->bind || return( $self->pass_error );
    }
    return( $self->{port} );
}

sub pretty { return( shift->_set_get_boolean( 'pretty', @_ ) ); }

sub socket { return( shift->_set_get_scalar( 'socket', @_ ) ); }

sub specs { return( shift->_set_get_hash( 'specs', @_ ) ); }

sub start
{
    my $self = shift( @_ );
    # my $cb = shift( @_ ) || return( $self->error( "No callback code reference was provided." ) );
    # return( $self->error( "Callback provided is not a code reference." ) ) if( ref( $cb ) ne 'CODE' );
    return( $self->error( "Another mock API server is already running." ) ) if( $self->{pid} );
    $self->{pid} = fork;
    # Parent
    if( $self->{pid} )
    {
        return( $self );
    }
    # Child
    else
    {
        # for $DB::signal
        no warnings 'once';
        $DB::signal = 1;
        $SIG{INT} = sub { exit(1); };
        $SIG{TERM} = sub { exit(1); };
        # $self->curry::loop( $cb );
        my $socket = $self->socket || return( $self->error( "Socket lost somehow" ) );
        # Load the fake data stored under __END__
        my $data = $self->data;
        my $alias = $data->{alias};
        
        while(1)
        {
            accept( my $client, $socket ) || 
                return( $self->error( "Failed to accept new connections: $!" ) );
            my $parser = HTTP::Promise::Parser->new( debug => $self->debug );
            my $req = $parser->parse_fh( $socket, request => 1 ) || do
            {
                warn( "Error parsing request with error code ", $parser->error->code, " and message ", $parser->error->message ) if( $self->_is_warnings_enabled );
                last;
            };
            
            my $stat = HTTP::Promise::Status->new;
            my $uri = $req->uri;
            my $meth = $req->method->lower;
            my $req_path = $uri->path;
            $req_path =~ s/\/{2,}$/\//g;
            my $lang = 'en_GB';
            if( $req->headers->exists( 'Accept-Language' ) )
            {
                my $al = $req->headers->new_field( 'Accept-Language', $req->headers->accept_language );
                my $supported = $stat->supported_languages;
                # en_GB -> en-GB
                for( @$supported )
                {
                    $_ =~ tr/_/-/;
                }
                my $best = $al->match( $supported->list )->first;
                $lang = $best if( $best );
            }
            
            my $endpoints = $self->endpoints || do
            {
                my $msg = { code => 500, message => "No OpenAPI specifications were loaded." };
                my $payload = $self->json->encode( $msg );
                # my $resp = HTTP::Promise::Response->new( $msg->{code}, 'Internal Server Edrror', [
                my $resp = HTTP::Promise::Response->new( $msg->{code}, $stat->status_message( 500 => $lang ), [
                        @STANDARD_HEADERS,
                        Content_Type => 'application/json',
                        Content_Length => length( $payload ),
                        Date => $self->_date_now,
                    ], $payload,
                );
                $client->print( 'HTTP/1.1 ' . $resp->as_string( "\015\012" ) );
                last;
            };
            
            # Find out the appropriate endpoint handler for this request.
            my( $def, $ep_vars );
            # From the most specific to the least
            foreach my $path ( reverse( sort( keys( %$endpoints ) ) ) )
            {
                my $this = $endpoints->{ $path };
                my $re = $this->{endpoint_re};
                my @matches = ( $req_path =~ /^$re$/ );
                my $vars = { %+ };
                if( scalar( @matches ) )
                {
                    $def = $this;
                    $ep_vars = $vars;
                    last;
                }
            }
            
            # No match was found for this request
            if( !defined( $def ) )
            {
                my $msg = { code => 404, message => "No endpoint found for $req_path" };
                my $payload = $self->json->encode( $msg );
                my $resp = HTTP::Promise::Response->new( 405, $stat->status_message( 404 => $lang ), [
                        @STANDARD_HEADERS,
                        Content_Type => 'application/json',
                        Content_Length => length( $payload ),
                        Date => $self->_date_now,
                    ], $payload,
                );
                $client->print( 'HTTP/1.1 ' . $resp->as_string( "\015\012" ) );
                last;
            }
            # No match was found for this request
            elsif( !exists( $def->{ $meth } ) )
            {
                my $msg = { code => 405, message => "Method used ${meth} is not supported for this endpoint." };
                my $payload = $self->json->encode( $msg );
                my $resp = HTTP::Promise::Response->new( 405, $stat->status_message( 405 => $lang ), [
                        @STANDARD_HEADERS,
                        Content_Type => 'application/json',
                        Content_Length => length( $payload ),
                        Date => $self->_date_now,
                    ], $payload,
                );
                $client->print( 'HTTP/1.1 ' . $resp->as_string( "\015\012" ) );
                last;
            }
            $def = $def->{ $meth };
            
            my $query;
            # Check request Content-Type against what the endpoint says we can accept
            # May be empty if this is a GET, HEAD or DELETE method, but otherwise required
            my $ct = $req->headers->type;
            # NOTE: Get query parameters
            if( $meth eq 'delete' || $meth eq 'get' || $meth eq 'head' )
            {
                $query = $uri->query_form_hash;
            }
            else
            {
                if( !defined( $ct ) || !length( $ct // '' ) )
                {
                    my $msg = { code => 415, message => "No content type was provided in your ${meth} request." };
                    my $payload = $self->json->encode( $msg );
                    my $resp = HTTP::Promise::Response->new( 415, $stat->status_message( 415 => $lang ), [
                            @STANDARD_HEADERS,
                            Content_Type => 'application/json',
                            Content_Length => length( $payload ),
                            Date => $self->_date_now,
                        ], $payload,
                    );
                    $client->print( 'HTTP/1.1 ' . $resp->as_string( "\015\012" ) );
                    last;
                }
                
                my $ok_types = $def->{content_types};
                if( !scalar( grep( /^$ct$/i, @$ok_types ) ) )
                {
                    my $msg = { code => 415, message => "Content type provided ($ct) is not supported by this endpoint." };
                    my $payload = $self->json->encode( $msg );
                    my $resp = HTTP::Promise::Response->new( 415, $stat->status_message( 415 => $lang ), [
                            @STANDARD_HEADERS,
                            Content_Type => 'application/json',
                            Content_Length => length( $payload ),
                            Date => $self->_date_now,
                        ], $payload,
                    );
                    $client->print( 'HTTP/1.1 ' . $resp->as_string( "\015\012" ) );
                    last;
                }
                
                # Decode payload.
                if( $ct eq 'application/json' )
                {
                    my $payload = $req->decoded_content_utf8;
                    local $@;
                    # try-catch
                    eval
                    {
                        $query = $self->json->decode( $payload );
                    };
                    if( $@ )
                    {
                        my $msg = { code => 400, message => "JSON payload is malformed: $@" };
                        my $payload = $self->json->encode( $msg );
                        my $resp = HTTP::Promise::Response->new( 400, $stat->status_message( 400 => $lang ), [
                                @STANDARD_HEADERS,
                                Content_Type => 'application/json',
                                Content_Length => length( $payload ),
                            ], $payload,
                        );
                        $client->print( 'HTTP/1.1 ' . $resp->as_string( "\015\012" ) );
                        last;
                    }
                }
                
                # TODO: validate request parameters sent
            }
            
            # NOTE: process query
            my $op_id = $def->{id};
            my $resp;
            # Maybe there is a special handler for this operation ID
            if( my $handler = $self->can( "_${op_id}" ) )
            {
                $resp = $handler->( $self,
                    def => $def,
                    lang => $lang,
                    request => $req,
                    vars => $ep_vars,
                ) || do
                {
                    my $code = $self->error->code || 500;
                    my $msg = { code => $code, message => $self->error->message };
                    my $payload = $self->json->encode( $msg );
                    my $resp = HTTP::Promise::Response->new( $code, $stat->status_message( $code => $lang ), [
                            @STANDARD_HEADERS,
                            Content_Type => 'application/json',
                            Content_Length => length( $payload ),
                            Date => $self->_date_now,
                        ], $payload,
                    );
                    $client->print( 'HTTP/1.1 ' . $resp->as_string( "\015\012" ) );
                    last;
                };
            }
            elsif( exists( $data->{ $op_id } ) || 
                   exists( $alias->{ $op_id } ) )
            {
                my $resp_data = exists( $alias->{ $op_id } ) ? $data->{ $alias->{ $op_id } } : $data->{ $op_id };
                # otherwise, we build the response and return the data
                my $resp_cts = $def->{response}->{200};
                my $resp_cts_ok = [keys( %$resp_cts )];
                my $resp_ct;
                if( scalar( @$resp_cts_ok ) == 1 )
                {
                    $resp_ct = $resp_cts_ok->[0];
                }
                else
                {
                    my $accept = 'application/json';
                    if( $req->headers->exists( 'Accept' ) )
                    {
                        $accept = $req->headers->acceptables->match( $resp_cts_ok );
                    }
                    
                    if( exists( $resp_cts->{ $accept } ) )
                    {
                        $resp_ct = $accept;
                    }
                    else
                    {
                        my $msg = { code => 406, message => "Could not find a suitable response content-type for operation ID ${op_id} for endpoint ${req_path} and method ${meth}" };
                        my $payload = $self->json->encode( $msg );
                        my $resp = HTTP::Promise::Response->new( 406, $stat->status_message( 406 => $lang ), [
                                @STANDARD_HEADERS,
                                Content_Type => 'application/json',
                                Content_Length => length( $payload ),
                                Date => $self->_date_now,
                            ], $payload,
                        );
                        $client->print( 'HTTP/1.1 ' . $resp->as_string( "\015\012" ) );
                        last;
                    }
                }
                
                my $payload;
                if( $resp_ct eq 'application/json' )
                {
                    $payload = $self->json->encode( $resp_data );
                }
                # As-is data. More complex response should be handled by a dedicated handler
                else
                {
                    $payload = $resp_data;
                }
                $resp = HTTP::Promise::Response->new( 200, $stat->status_message( 200 => $lang ), [
                        @STANDARD_HEADERS,
                        Content_Type => $resp_ct,
                        Content_Length => length( $payload ),
                        Date => $self->_date_now,
                    ], $payload,
                );
            }
            else
            {
                my $msg = { code => 500, message => "Could not find a handler or any data entry for operation ID ${op_id} for endpoint ${req_path} and method ${meth}" };
                my $payload = $self->json->encode( $msg );
                $resp = HTTP::Promise::Response->new( 500, $stat->status_message( 500 => $lang ), [
                        @STANDARD_HEADERS,
                        Content_Type => 'application/json',
                        Content_Length => length( $payload ),
                        Date => $self->_date_now,
                    ], $payload,
                );
                $client->print( 'HTTP/1.1 ' . $resp->as_string( "\015\012" ) );
                last;
            }
            
            $client->print( 'HTTP/1.1 ' . $resp->as_string( "\015\012" ) );
            # we don't support keep-alive
            close( $client );
        }
        # exit child
        exit(0);
    }
}

sub stop
{
    my $self = shift( @_ );
    return( $self->error( "Mock server not started" ) ) unless( $self->{pid} );
    kill( 2, $self->{pid} );
    waitpid( $self->{pid}, 0 );
    delete( $self->{pid} );
}

sub url_base
{
    my $self = shift( @_ );
    my $host = $self->host;
    my $port = $self->port;
    return( URI->new( "http://${host}:${port}" ) );
}

# NOTE: GET /v1/activity
sub _GetActivity
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $activity = [];
    for( 0..23 )
    {
        push( @$activity, int( rand(30 ) ) + 1 );
    }
    my $payload = $self->json->encode( { activity => $activity } );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/activity
    # NOTE: sub _PostActivity
    *_PostActivity = \&_GetActivity;
}

# NOTE: GET /v1/author
sub _GetAuthor
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->_search( %$opts, type => 'author', total => 14410, callback => sub
    {
        my $this = shift( @_ );
        return({
            _id => $this->{user},
            _index => 'cpan_v1_01',
            _score => 1,
            _source => $this,
            _type => 'author',
        });
    }) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/author
    # NOTE: sub _PostAuthor
    *_PostAuthor = \&_GetAuthor;
}

# NOTE: GET /v1/author/by_ids
# /author/by_ids?id=PAUSE_ID1&id=PAUSE_ID2...
sub _GetAuthorByPauseID
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    if( !exists( $form->{id} ) )
    {
        return( $self->error({ code => 400, message => "Missing param: id" }) );
    }
    my $ids = ref( $form->{id} ) eq 'ARRAY' ? $form->{id} : [$form->{id}];
    my $authors = [];
    foreach my $id ( @$ids )
    {
        next if( !exists( $data->{users}->{ $id } ) );
        $data->{users}->{ $id }->{is_pause_custodial_account} = \0 unless( exists( $data->{users}->{ $id }->{is_pause_custodial_account} ) );
        push( @$authors, $data->{users}->{ $id } );
    }
    my $res =
    {
        took => 2,
        total => scalar( @$authors ),
        authors => $authors,
    };
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/author/by_ids
    # NOTE: sub _PostAuthorByPauseID
    *_PostAuthorByPauseID = \&_GetAuthorByPauseID;
}

# NOTE: GET /v1/author/by_prefix/{prefix}
sub _GetAuthorByPrefix
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $prefix = $vars->{prefix} || 
        return( $self->error({ code => 404, message => 'The requested info could not be found' }) );
    my $authors = [];
    my $from = $form->{from} // 0;
    my $size = $form->{size} // 10;
    my $n = -1;
    foreach my $user ( sort( keys( %{$data->{users}} ) ) )
    {
        last unless( index( $user, $prefix ) == 0 );
        $n++;
        next unless( $from == $n );
        push( @$authors, $data->{users}->{ $user } );
        last if( scalar( @$authors ) == $size );
    }
    my $res =
    {
        took => 2,
        total => scalar( @$authors ),
        authors => $authors,
    };
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/author/by_prefix/{prefix}
    # NOTE: sub _PostAuthorByPrefix
    *_PostAuthorByPrefix = \&_GetAuthorByPrefix;
}

# NOTE: GET /v1/author/by_user
sub _GetAuthorByUserIDQuery
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    return( $self->error({ code => 400, message => 'Missing param: user' } ) ) if( !exists( $form->{user} ) || !length( $form->{user} ) );
    my $user_id = ref( $form->{user} ) eq 'ARRAY' ? $form->{user} : [$form->{user}];
    my $need = {};
    @$need{ @$user_id } = (1) x scalar( @$user_id );
    
    my $authors = [];
    
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        if( exists( $need->{ $data->{users}->{ $user }->{user} } ) )
        {
            push( @$authors, $data->{users}->{ $user } );
        }
    }

    my $res =
    {
        took => 2,
        total => scalar( @$authors ),
        authors => $authors,
    };
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/author/by_user
    # NOTE: sub _PostAuthorByUserIDQuery
    *_PostAuthorByUserIDQuery = \&_GetAuthorByUserIDQuery;
}

# NOTE: GET /v1/author/by_user/{user}
sub _GetAuthorByUserID
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $user = $vars->{user} || 
        return( $self->error({ code => 404, message => 'The requested info could not be found' }) );
    my $authors = [];
    push( @$authors, $data->{users}->{ $user } ) if( exists( $data->{users}->{ $user } ) );
    my $res =
    {
        took => 2,
        total => scalar( @$authors ),
        authors => $authors,
    };
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/author/by_user/{user}
    # NOTE: sub _PostAuthorByUserID
    *_PostAuthorByUserID = \&_GetAuthorByUserID;
}

# NOTE: GET /v1/author/{author}
sub _GetAuthorProfile
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} || 
        return( $self->_GetAuthor( %$opts ) );
    unless( exists( $data->{users}->{ $author } ) )
    {
        return( $self->error({ code => 404, message => 'The requested info could not be found' }) );
    }
    my $payload = $self->json->encode( $data->{users}->{ $author } );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/author/{author}
    # NOTE: sub _PostAuthorProfile
    *_PostAuthorProfile = \&_GetAuthorProfile;
    
    # NOTE: GET /v1/author/_mapping
    # GetAuthorMapping is accessed directly in the data

    # NOTE: POST /v1/author/_mapping
    # PostAuthorMapping is accessed directly in the data

    # NOTE: GET /v1/author/_search
    # NOTE: POST /v1/author/_search
    # NOTE: sub _GetAuthorSearch
    # NOTE: sub _PostAuthorSearch
    *_GetAuthorSearch = \&_GetAuthor;
    *_PostAuthorSearch = \&_GetAuthor;
}

# NOTE: DELETE /v1/author/_search/scroll
# TODO: Need to find out exactly what this endpoint returns
sub _DeleteAuthorSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $msg = { code => 501, message => 'Not implemented' };
    my $payload = $self->json->encode( $msg );
    my $resp = HTTP::Promise::Response->new( $msg->{code}, HTTP::Promise::Status->status_message( $msg->{code} => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/author/_search/scroll
sub _GetAuthorSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{scroll} = 1;
    return( $self->_GetAuthorSearch( %$opts ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/author/_search/scroll
    # NOTE: sub _PostAuthorSearchScroll
    *_PostAuthorSearchScroll = \&_GetAuthorSearchScroll;
}

# NOTE: GET /v1/changes/by_releases
sub _GetChangesFileByRelease
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    # e.g.: /v1/changes/by_releases/?release=OALDERS/HTTP-Message-6.37 or /v1/changes/by_releases/?release=OALDERS/HTTP-Message-6.37&release=JDEGUEST/Module-Generic-v0.30.1
    if( !exists( $form->{release} ) ||
        !length( $form->{release} ) )
    {
        return( $self->error({ code => 400, message => 'Missing param: release' }) );
    }
    my $releases = ref( $form->{release} ) eq 'ARRAY' ? $form->{release} : [$form->{release}];
    my $changes = [];
    
    foreach my $release ( @$releases )
    {
        my( $author, $distrib ) = split( /\//, $release, 2 );
        my @parts = split( /-/, $distrib );
        my $version = pop( @parts );
        my $module = join( '::', @parts );
        if( exists( $data->{users}->{ $author } ) &&
            exists( $data->{users}->{ $author }->{modules}->{ $module } ) )
        {
            my $this = $data->{users}->{ $author }->{modules}->{ $module };
            push( @$changes,
            {
                author => $author,
                changes_file => 'Changes',
                changes_text => qq{Changes file for $module\n\n${version} 2023-08-15T09:12:17\n\n  - New stuff},
                release => $distrib,
            });
        }
    }
    
    my $result =
    {
        changes => $changes,
    };
    my $payload = $self->json->encode( $result );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    # NOTE: POST /v1/changes/by_releases
    no warnings 'once';
    *_PostChangesFileByRelease = \&_GetChangesFileByRelease;
}

# NOTE: GET /v1/changes/{distribution}
sub _GetChangesFile
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $dist = $vars->{distribution} || 
        return( $self->error({ code => 404, message => 'Not found' }) );
    ( my $package = $dist ) =~ s/-/::/g;
    $self->message( 4, "Searching for package '$package' ($dist)" );
    my $info;
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        if( exists( $data->{users}->{ $user }->{modules} ) &&
            ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' &&
            exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            $info = $self->_make_changes_from_module( $data->{users}->{ $user }->{modules}->{ $package } );
            last;
        }
    }
    
    unless( defined( $info ) )
    {
        return( $self->error({ code => 404, message => 'Not found' }) );
    }
    my $payload = $self->json->encode( $info );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    # NOTE: POST /v1/changes/{module}
    no warnings 'once';
    *_PostChangesFile = \&_GetChangesFile;
}

# NOTE: GET /v1/changes/{author}/{release}
sub _GetChangesFileAuthor
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} || 
        return( $self->error({ code => 400, message => 'Missing param: author' }) );
    my $release = $vars->{release} || 
        return( $self->error({ code => 400, message => 'Missing param: release' }) );
    my @parts = split( /-/, $release );
    my $version = pop( @parts );
    my $module = join( '::', @parts );
    my $details;
    if( exists( $data->{users}->{ $author } ) &&
        exists( $data->{users}->{ $author }->{modules}->{ $module } ) )
    {
        $details = $self->_make_changes_from_module( $data->{users}->{ $author }->{modules}->{ $module } );
    }
    else
    {
        return( $self->error({ code => 404, message => 'Not found' }) );
    }
    
    my $payload = $self->json->encode( $details );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/changes/{author}/{release}
    # NOTE: sub _PostChangesFileAuthor
    *_PostChangesFileAuthor = \&_GetChangesFileAuthor;
}

# NOTE: GET /v1/contributor/_mapping
# GetContributorMapping is accessed directly in the data

# NOTE: POST /v1/contributor/_mapping
# PostContributorMapping is accessed directly in the data

# NOTE: GET /v1/contributor/by_pauseid/{author}
sub _GetModuleContributedByPauseID
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} || 
        return( $self->error({ code => 400, message => 'Missing param: author' }) );
    # The requested number of module this author would be contributing to.
    # The list of module would be randomly generated and cached.
    my $total = $form->{total} || 3;
    # By default MetaCPAN API returns an empty hash reference if nothing was found.
    my $res = {};
    if( exists( $data->{users}->{ $author } ) &&
        exists( $data->{users}->{ $author }->{contributions} ) )
    {
        $res->{contributors} = $data->{users}->{ $author }->{contributions};
    }

    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/contributor/by_pauseid/{author}
    # NOTE: sub _PostModuleContributedByPauseID
    *_PostModuleContributedByPauseID = \&_GetModuleContributedByPauseID;
}

# NOTE: GET /v1/contributor/{author}/{release}
sub _GetModuleContributors
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} || 
        return( $self->error({ code => 400, message => 'Missing param: author' }) );
    my $release = $vars->{release} || 
        return( $self->error({ code => 400, message => 'Missing param: release' }) );
    my @parts = split( /-/, $release );
    my $version = pop( @parts );
    my $dist = join( '-', @parts );
    my $package = join( '::', @parts );
    my $res = { contributors => [] };
    if( exists( $data->{users}->{modules} ) &&
        ref( $data->{users}->{modules} ) eq 'HASH' &&
        exists( $data->{users}->{modules}->{ $package } ) &&
        ref( $data->{users}->{modules}->{ $package } ) eq 'HASH' &&
        exists( $data->{users}->{modules}->{ $package }->{contributors} ) &&
        ref( $data->{users}->{modules}->{ $package }->{contributors} ) eq 'ARRAY' )
    {
        foreach my $user ( @{$data->{users}->{ $author }->{modules}->{ $package }->{contributors}} )
        {
            push( @{$res->{contributors}}, 
            {
                distribution => $dist,
                pauseid => $user,
                release_author => $author,
                release_name => $release,
            });
        }
    }
    
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/contributor/{author}/{release}
    # NOTE: sub _PostModuleContributors
    *_PostModuleContributors = \&_GetModuleContributors;
}

# NOTE: GET /v1/cover/{release}
sub _GetModuleCover
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $release = $vars->{release} || 
        return( $self->error({ code => 400, message => 'Missing param: release' }) );
    my @parts = split( /-/, $release );
    my $version = pop( @parts );
    my $dist = join( '-', @parts );
    my $package = join( '::', @parts );
    my $res = {};
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        if( exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            $res =
            {
                criteria =>
                {
                    branch => 54.68,
                    total => 67.65,
                    condition => 57.56,
                    statement => 78.14,
                },
                version => $version,
                distribution => $dist,
                url => "http://cpancover.com/latest/${release}/index.html",
                release => $release,
            };
            last;
        }
    }
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/cover/{release}
    # NOTE: sub _PostModuleCover
    *_PostModuleCover = \&_GetModuleCover;
}

{
    no warnings 'once';
    # NOTE: sub _GetCVE for endpoint /v1/cve is skipped because I could not find any data returned for Common Vulnerabilities & Exposures
    
    # NOTE: sub _PostCVE for endpoint /v1/cve is skipped because I could not find any data returned for Common Vulnerabilities & Exposures

    # NOTE: sub _GetCVEByDistribution for endpoint /v1/cve/dist/{distribution} is skipped because I could not find any data returned for Common Vulnerabilities & Exposures
    
    # NOTE: sub _PostCVEByDistribution for endpoint /v1/cve/dist/{distribution} is skipped because I could not find any data returned for Common Vulnerabilities & Exposures

    # NOTE: sub _GetCVEByAuthorRelease for endpoint /v1/cve/release/{author}/{release} is skipped because I could not find any data returned for Common Vulnerabilities & Exposures

    # NOTE: sub _PostCVEByAuthorRelease for endpoint /v1/cve/release/{author}/{release} is skipped because I could not find any data returned for Common Vulnerabilities & Exposures

    # NOTE: sub _GetCVEByCpanID for endpoint /v1/cve/{cpanid} is skipped because I could not find any data returned for Common Vulnerabilities & Exposures

    # NOTE: sub _PostCVEByCpanID for endpoint /v1/cve/{cpanid} is skipped because I could not find any data returned for Common Vulnerabilities & Exposures
}

# NOTE: GET /v1/diff/release/{distribution}
sub _GetReleaseDiff
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $dist = $vars->{distribution} || 
        return( $self->error({ code => 400, message => 'Missing param: distribution' }) );
    ( my $package = $dist ) =~ s/-/::/g;
    my $res;

    foreach my $user ( keys( %{$data->{users}} ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) );
        if( exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $package };
            my $vers = Changes::Version->parse( $this->{version} );
            my $prev = $vers - 1;
            my $rel  = $this->{release};
            my $prev_rel = "${dist}-${prev}";
            my $now = DateTime->now;
            my $today = $now->strftime( '%Y-%m-%d' );
            my $before = $now->clone->subtract( days => 10 )->strftime( '%Y-%m-%d' );
            ( my $path = $package ) =~ s,::,/,g;
            $path .= '.pm';
            my $tags =
            {
            before => $before,
            next_rel => $rel,
            path1 => $path,
            path2 => $path,
            prev => $prev,
            prev_rel => $prev_rel,
            rel => $rel,
            today => $today,
            vers => $vers,
            distribution => $dist,
            author => $this->{author},
            };
            my $type = $req->headers->type;
            my $acceptables = $req->headers->acceptables;
            my $accept = $acceptables->match( [qw( application/json text/plain )] );
            my $return_type;
            if( ( defined( $type ) && $type eq 'text/plain' ) || 
                ( !$accept->is_empty && $accept->first eq 'text/plain' ) )
            {
                $return_type = 'text/plain';
            }
            else
            {
                $return_type = 'application/json';
            }
            
            if( $return_type eq 'text/plain' )
            {
                $res = $DIFF_RAW_TEMPLATE;
            }
            else
            {
                $res = $DIFF_JSON_TEMPLATE;
            }
            # $res =~ s/\$\{([^\}]+)\}/$tags->{ $1 }/gs;
            $res =~ s
            {
                \$\{([^\}]+)\}
            }
            {
                warn( "No tag '$1' found." ) if( !exists( $tags->{ $1 } ) );
                $tags->{ $1 }
            }gexs;
            last;
        }
    }
    
    if( defined( $res ) )
    {
        my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
                @STANDARD_HEADERS,
                Content_Type => 'text/plain; charset=UTF-8',
                Content_Length => length( $res ),
                Date => $self->_date_now,
            ], $res,
        );
        return( $resp );
    }
    else
    {
        my $payload = $self->json->encode({ message => $dist, code => 404 });
        my $resp = HTTP::Promise::Response->new( 404, HTTP::Promise::Status->status_message( 404 => $lang ), [
                @STANDARD_HEADERS,
                Content_Type => 'application/json',
                Content_Length => length( $payload ),
                Date => $self->_date_now,
            ], $payload,
        );
        return( $resp );
    }
}

{
    no warnings 'once';
    # NOTE: POST /v1/diff/release/{distribution}
    # NOTE: sub _PostReleaseDiff
    *_PostReleaseDiff = \&_GetReleaseDiff
}

# NOTE: GET /v1/diff/release/{author1}/{release1}/{author2}/{release2}
sub _Get2ReleasesDiff
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author1 = $vars->{author1} || 
        return( $self->error({ code => 400, message => 'Missing parameter: author1' }) );
    my $author2 = $vars->{author2} || 
        return( $self->error({ code => 400, message => 'Missing parameter: author2' }) );
    my $rel1 = $vars->{release1} || 
        return( $self->error({ code => 400, message => 'Missing parameter: release1' }) );
    my $rel2 = $vars->{release2} || 
        return( $self->error({ code => 400, message => 'Missing parameter: release2' }) );
    my @parts = split( /-/, $rel1 );
    my $vers1 = pop( @parts );
    my $package1 = join( '::', @parts );
    @parts = split( /-/, $rel2 );
    my $vers2 = pop( @parts );
    my $package2 = join( '::', @parts );
    my $res;

    if( exists( $data->{users}->{ $author1 } ) &&
        exists( $data->{users}->{ $author2 } ) &&
        exists( $data->{users}->{ $author1 }->{modules} ) &&
        exists( $data->{users}->{ $author2 }->{modules} ) &&
        ref( $data->{users}->{ $author1 }->{modules} ) eq 'HASH' &&
        ref( $data->{users}->{ $author2 }->{modules} ) eq 'HASH' &&
        exists( $data->{users}->{ $author1 }->{modules}->{ $package1 } ) &&
        exists( $data->{users}->{ $author2 }->{modules}->{ $package2 } ) )
#         $data->{users}->{ $author1 }->{modules}->{ $package1 }->{release} eq $rel1 &&
#         $data->{users}->{ $author2 }->{modules}->{ $package2 }->{release} eq $rel2 )
    {
        my $now = DateTime->now;
        my $today = $now->strftime( '%Y-%m-%d' );
        my $before = $now->clone->subtract( days => 10 )->strftime( '%Y-%m-%d' );
        ( my $path1 = $package1 ) =~ s,::,/,g;
        $path1 .= '.pm';
        ( my $path2 = $package2 ) =~ s,::,/,g;
        $path2 .= '.pm';
        my $tags =
        {
        before => $before,
        next_rel => $rel2,
        path1 => $path1,
        path2 => $path2,
        prev => $vers1,
        prev_rel => $rel1,
        rel => $rel2,
        today => $today,
        vers => $vers2,
        author => $author1,
        author1 => $author1,
        author2 => $author2,
        release1 => $rel1,
        release2 => $rel2,
        };
        my $type = $req->headers->type;
        my $acceptables = $req->headers->acceptables;
        my $accept = $acceptables->match( [qw( application/json text/plain )] );
        my $return_type;
        if( ( defined( $type ) && $type eq 'text/plain' ) || 
            ( !$accept->is_empty && $accept->first eq 'text/plain' ) )
        {
            $return_type = 'text/plain';
        }
        else
        {
            $return_type = 'application/json';
        }
        
        if( $return_type eq 'text/plain' )
        {
            $res = $DIFF_RAW_TEMPLATE;
        }
        else
        {
            $res = $DIFF_JSON_TEMPLATE;
        }
        # $res =~ s/\$\{([^\}]+)\}/$tags->{ $1 }/gs;
        $res =~ s
        {
            \$\{([^\}]+)\}
        }
        {
            warn( "No tag '$1' found." ) if( !exists( $tags->{ $1 } ) );
            $tags->{ $1 }
        }gexs;
    }
    
    if( defined( $res ) )
    {
        my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
                @STANDARD_HEADERS,
                Content_Type => 'text/plain; charset=UTF-8',
                Content_Length => length( $res ),
                Date => $self->_date_now,
            ], $res,
        );
        return( $resp );
    }
    else
    {
        my $resp = HTTP::Promise::Response->new( 404, HTTP::Promise::Status->status_message( 404 => $lang ), [
                @STANDARD_HEADERS,
                Content_Type => 'application/json',
                Date => $self->_date_now,
            ],
        );
        return( $resp );
    }
}

{
    no warnings 'once';
    # NOTE: POST /v1/diff/release/{author1}/{release1}/{author2}/{release2}
    # NOTE: sub _Post2ReleasesDiff
    *_Post2ReleasesDiff = \&_Get2ReleasesDiff;
}

# NOTE: GET /v1/diff/file/{file1}/{file2}
# e.g.: /v1/diff/file/AcREzFgg3ExIrFTURa0QJfn8nto/Ies7Ysw0GjCxUU6Wj_WzI9s8ysU
sub _Get2FilesDiff
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    # file ID
    my $file1 = $vars->{file1} || 
        return( $self->error({ code => 404, message => 'Not found' }) );
    my $file2 = $vars->{file2} || 
        return( $self->error({ code => 404, message => 'Not found' }) );
    
    my( $ref1, $ref2, $res );

    USERS: foreach my $user ( keys( %{$data->{users}} ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) );
        foreach my $package ( keys( %{$data->{users}->{ $user }->{modules}} ) )
        {
            if( !defined( $ref1 ) &&
                $data->{users}->{ $user }->{modules}->{ $package }->{id} eq $file1 )
            {
                $ref1 = $data->{users}->{ $user }->{modules}->{ $package };
            }
            if( !defined( $ref2 ) &&
                $data->{users}->{ $user }->{modules}->{ $package }->{id} eq $file2 )
            {
                $ref2 = $data->{users}->{ $user }->{modules}->{ $package };
            }
            last USERS if( defined( $ref1 ) && defined( $ref2 ) );
        }
    }
    
    if( defined( $ref1 ) && defined( $ref2 ) )
    {
        my $now = DateTime->now;
        my $today = $now->strftime( '%Y-%m-%d' );
        my $before = $now->clone->subtract( days => 10 )->strftime( '%Y-%m-%d' );
        my $rel1 = $ref1->{release};
        my $rel2 = $ref2->{release};
        ( my $path1 = $ref1->{package} ) =~ s,::,/,g;
        $path1 .= '.pm';
        ( my $path2 = $ref2->{package} ) =~ s,::,/,g;
        $path2 .= '.pm';
        my $vers1 = $ref1->{version};
        my $vers2 = $ref2->{version};
        my $tags =
        {
        before => $before,
        next_rel => $rel2,
        path1 => $path1,
        path2 => $path2,
        prev => $vers1,
        prev_rel => $rel1,
        rel => $rel2,
        today => $today,
        vers => $vers2,
        file1 => $file1,
        file2 => $file2,
        author => $ref1->{author},
        };
        my $type = $req->headers->type // 'application/json';
        my $acceptables = $req->headers->acceptables;
        my $accept = $acceptables->match( [qw( application/json text/plain )] );
        my $return_type;
        if( $type eq 'text/plain' || ( !$accept->is_empty && $accept->first eq 'text/plain' ) )
        {
            $return_type = 'text/plain';
        }
        else
        {
            $return_type = 'application/json';
        }
        
        if( $return_type eq 'text/plain' )
        {
            $res = $DIFF_RAW_TEMPLATE;
        }
        else
        {
            $res = $DIFF_JSON_TEMPLATE;
        }
        # $res =~ s/\$\{([^\}]+)\}/$tags->{ $1 }/gs;
        $res =~ s
        {
            \$\{([^\}]+)\}
        }
        {
            warn( "No tag '$1' found." ) if( !exists( $tags->{ $1 } ) );
            $tags->{ $1 }
        }gexs;
        my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
                @STANDARD_HEADERS,
                Content_Type => 'text/plain; charset=UTF-8',
                Content_Length => length( $res ),
                Date => $self->_date_now,
            ], $res,
        );
        return( $resp );
    }
    else
    {
        my $resp = HTTP::Promise::Response->new( 404, HTTP::Promise::Status->status_message( 404 => $lang ), [
                @STANDARD_HEADERS,
                Content_Type => 'application/json',
                Date => $self->_date_now,
            ],
        );
        return( $resp );
    }
}

{
    no warnings 'once';
    # NOTE: POST /v1/diff/file/{file1}/{file2}
    # NOTE: sub _Post2FilesDiff
    *_Post2FilesDiff = \&_Get2FilesDiff;
}

# NOTE: GET /v1/distribution
sub _GetDistribution
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->_search( %$opts, type => 'distribution', total => 44382, callback => sub
    {
        my $this = shift( @_ );
        return({
            _id => $this->{name},
            _index => 'cpan_v1_01',
            _score => 1,
            _source => { name => $this->{name} },
            _type => 'distribution',
        });
    }) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/distribution
    # NOTE: sub _PostDistribution
    *_PostDistribution = \&_GetDistribution
}

# NOTE: GET /v1/distribution/{distribution}
sub _GetModuleDistribution
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $dist = $vars->{distribution} ||
        return( $self->error({ code => 400, message => 'Missing param: distribution' }) );
    ( my $package = $dist ) =~ s/-/::/g;
    my $res;
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        if( exists( $data->{users}->{ $user }->{modules} ) &&
            ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' &&
            exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            $res =
            {
                bugs =>
                {
                    github =>
                    {
                        active => 56,
                        closed => 107,
                        open => 56,
                        source => "https://github.com/\L${user}\E/${dist}",
                    },
                    rt =>
                    {
                        active => 0,
                        closed => 58,
                        new => 0,
                        open => 0,
                        patched => 0,
                        rejected => 5,
                        resolved => 53,
                        source => "https://rt.cpan.org/Public/Dist/Display.html?Name=${dist}",
                        stalled => 0,
                    },
                },
                external_package =>
                {
                    cygwin => "perl-${dist}",
                    debian => "perl-${dist}",
                    fedora => "perl-${dist}",
                },
                name => $dist,
                river => 
                {
                    bucket => 4,
                    bus_factor => 7,
                    immediate => 1358,
                    total => 8529,
                },
            };
            last;
        }
    }
    
    my $code;
    if( !defined( $res ) )
    {
        $code = 404;
        return( $self->error({ code => $code, message => 'Not found' }) );
    }
    else
    {
        $code = 200;
    }
    
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    # NOTE: POST /v1/distribution/{distribution}
    no warnings 'once';
    # NOTE: sub _PostModuleDistribution
    *_PostModuleDistribution = \&_GetModuleDistribution;
}

# NOTE: GET /v1/distribution/river?distribution=HTTP-Message&distribution=Module-Generic
sub _GetModuleDistributionRiverWithQuery
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    $form->{distribution} = $opts->{distribution} if( exists( $opts->{distribution} ) && $opts->{distribution} );
    if( !exists( $form->{distribution} ) ||
        !length( $form->{distribution} ) )
    {
        return( $self->error({ code => 400, message => 'Missing param: distribution' }) );
    }
    my $dists = ref( $form->{distribution} ) eq 'ARRAY' ? $form->{distribution} : [$form->{distribution}];
    
    my $res = {};
    my $rivers = {};
    
    foreach my $dist ( @$dists )
    {
        ( my $package = $dist ) =~ s/-/::/g;
        foreach my $user ( keys( %{$data->{users}} ) )
        {
            if( exists( $data->{users}->{ $user }->{modules} ) &&
                ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' &&
                exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
            {
                # On purpose, same data for everyone so it is predictable, since it does not matter anyway
                $rivers->{ $dist } =
                {
                    bucket => 4,
                    bus_factor => 7,
                    immediate => 1358,
                    total => 8529,
                };
                last;
            }
        }
    }
    
    if( scalar( keys( %$rivers ) ) )
    {
        $res->{river} = $rivers;
    }

    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    # NOTE: POST /v1/distribution/river {"distribution": ["HTTP-Message", "Module-Generic"]}
    no warnings 'once';
    # NOTE: sub _PostModuleDistributionRiverWithJSON
    *_PostModuleDistributionRiverWithJSON = \&_GetModuleDistributionRiverWithQuery;
}

# NOTE: GET /v1/distribution/river/{distribution}
sub _GetModuleDistributionRiverWithParam
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $dist = $vars->{distribution} ||
        return( $self->error({ code => 400, message => 'Missing param: distribution' }) );
    # Pass it to _GetModuleDistributionRiverWithQuery()
    $opts->{distribution} = $dist;
    return( $self->_GetModuleDistributionRiverWithQuery( %$opts ) );
}

{
    # NOTE: POST /v1/distribution/river/{distribution}
    no warnings 'once';
    # NOTE: sub _PostModuleDistribution
    *_PostModuleDistributionRiverWithParam = \&_GetModuleDistributionRiverWithParam;
}

# NOTE: GET /v1/distribution/_mapping
# GetDistributionMapping is accessed directly in the data

# NOTE: POST /v1/distribution/_mapping
# PostDistributionMapping is accessed directly in the data

{
    # NOTE: GET /v1/distribution/_search
    # NOTE: POST /v1/distribution/_search
    # NOTE: sub _GetDistributionSearch
    # NOTE: sub _PostDistributionSearch
    *_GetDistributionSearch = \&_GetDistribution;
    *_PostDistributionSearch = \&_GetDistribution;
}

# NOTE: DELETE /v1/distribution/_search/scroll
# TODO: _DeleteDistributionSearchScroll
# Need to find out exactly what this endpoint returns
sub _DeleteDistributionSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $msg = { code => 501, message => 'Not implemented' };
    my $payload = $self->json->encode( $msg );
    my $resp = HTTP::Promise::Response->new( $msg->{code}, HTTP::Promise::Status->status_message( $msg->{code} => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/distribution/_search/scroll
sub _GetDistributionSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{scroll} = 1;
    return( $self->_GetDistributionSearch( %$opts ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/distribution/_search/scroll
    # NOTE: sub _PostDistributionSearchScroll
    *_PostDistributionSearchScroll = \&_GetDistributionSearchScroll;
}

# NOTE: GET /v1/download_url/{module}
sub _GetDownloadURL
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $mod = $vars->{module} ||
        return( $self->error({ code => 400, message => 'Missing param: module' }) );
    my $res;
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        if( exists( $data->{users}->{ $user }->{modules} ) &&
            ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' &&
            exists( $data->{users}->{ $user }->{modules}->{ $mod } ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $mod };
            my @keys = qw( checksum_md5 checksum_sha256 date download_url release status version );
            $res = {};
            @$res{ @keys } = @$this{ @keys };
            last;
        }
    }
    
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/download_url/{module}
    # NOTE: sub _PostDownloadURL
    *_PostDownloadURL = \&_GetDownloadURL;
}

# NOTE: GET /v1/favorite
sub _GetFavorite
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->_search( %$opts, type => 'favorite', total => 44382, callback => sub
    {
        my $this = shift( @_ );
        return({
            _id => $this->{id},
            _index => 'cpan_v1_01',
            _score => 1,
            _source => 
            {
                author => $this->{author},
                date => $this->{date},
                distribution => $this->{distribution},
                id => $this->{id},
                release => $this->{release},
                user => $this->{release},
            },
            _type => 'favorite',
        });
    }) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/favorite
    # NOTE: sub _PostFavorite
    *_PostFavorite = \&_GetFavorite
}

# NOTE: GET /v1/favorite/{user}/{distribution}
sub _GetFavoriteByUserModule
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    # e.g.: 8IClg1rxdhRV1BvxqR0rKYyiLmQ
    my $id = $vars->{user} ||
        return( $self->error({ code => 400, message => 'Missing param: user' }) );
    # e.g.: DBI
    my $dist = $vars->{distribution} ||
        return( $self->error({ code => 400, message => 'Missing param: distribution' }) );
    ( my $module = $dist ) =~ s/-/::/g;
    my $res;
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        my $this = $data->{users}->{ $user };
        if( $this->{user} eq $id && exists( $this->{modules}->{ $module } ) )
        {
            $res =
            {
                author => $this->{author},
                date => $this->{modules}->{ $module }->{date},
                distribution => $dist,
                id => $this->{modules}->{ $module }->{id},
                release => $this->{modules}->{ $module }->{release},
                user => $id,
            };
            last;
        }
    }
    
    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => 'Nothing found' };
    }
    
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    # NOTE: POST /v1/favorite/agg_by_distributions
    no warnings 'once';
    # NOTE: sub _PostFavoriteAggregateDistribution
    *_PostFavoriteByUserModule = \&_GetFavoriteByUserModule;
}

# NOTE: GET /v1/favorite/agg_by_distributions
sub _GetFavoriteAggregateDistribution
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $dist = $form->{distribution} ||
        return( $self->error({ code => 400, message => 'Missing param: distribution' }) );
    $dist = [$dist] unless( ref( $dist ) eq 'ARRAY' );
    my $res = 
    {
        favorites => {},
        myfavorites => {},
        took => 5,
    };
    foreach my $d ( @$dist )
    {
        ( my $package = $d ) =~ s/-/::/g;
        foreach my $user ( keys( %{$data->{users}} ) )
        {
            if( exists( $data->{users}->{ $user }->{modules} ) &&
                ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' &&
                exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
            {
                $res->{favorites}->{ $package } = int( $data->{users}->{ $user }->{modules}->{ $package }->{likes} );
            }
        }
    }
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    # NOTE: POST /v1/favorite/agg_by_distributions
    no warnings 'once';
    # NOTE: sub _PostFavoriteAggregateDistribution
    *_PostFavoriteAggregateDistribution = \&_GetFavoriteAggregateDistribution;
}

# NOTE: GET /v1/favorite/by_user/{user}
# Example: /v1/favorite/by_user/q_15sjOkRminDY93g9DuZQ
sub _GetFavoriteByUser
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    # e.g.: 8IClg1rxdhRV1BvxqR0rKYyiLmQ
    my $id = $vars->{user} ||
        return( $self->error({ code => 400, message => 'Missing param: user' }) );
    my $favs = {};
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        if( $data->{users}->{ $user }->{user} eq $id )
        {
            my $this = $data->{users}->{ $user };
            $favs = 
            {
                favorites => $data->{users}->{ $user }->{user},
                took => 15,
            };
        }
    }
    my $payload = $self->json->encode( $favs );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/favorite/by_user/{user}
    # NOTE sub _PostFavoriteByUser
    *_PostFavoriteByUser = \&_GetFavoriteByUser;
}

# NOTE: GET /v1/favorite/leaderboard
sub _GetFavoriteLeaderboard
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $top = {};
    foreach my $user ( sort( keys( %{$data->{users}} ) ) )
    {
        if( exists( $data->{users}->{ $user }->{modules} ) &&
            ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' )
        {
            foreach my $package ( keys( %{$data->{users}->{ $user }->{modules}} ) )
            {
                my $this = $data->{users}->{ $user }->{modules}->{ $package };
                $top->{ $this->{likes} } = [] if( !exists( $top->{ $this->{likes} } ) );
                push( @{$top->{ $this->{likes} }}, $this->{distribution} );
            }
        }
    }
    
    my $mods = [];
    foreach my $n ( sort( keys( %$top ) ) )
    {
        push( @$mods, +{ map( ( key => $_, doc_count => $n ), @{$top->{ $n }} ) } );
    }

    my $res = 
    {
        leaderboard => $mods,
        took => 22,
        total => scalar( @$mods ),
    };
    
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/favorite/by_user/{user}
    # NOTE sub _PostFavoriteByUser
    *_PostFavoriteLeaderboard = \&_GetFavoriteLeaderboard;
}

# NOTE: GET /v1/favorite/recent
sub _GetFavoriteRecent
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $page = $form->{page} //= 1;
    my $size = $form->{size} //= 10;
    # $page cannot be 0. It falls back to 1
    $page ||= 1;
    my $recent = $self->_build_recent || 
        return( $self->pass_error );
    
    my $favorites = [];
    my $offset = ( ( $page - 1 ) * $size );
    my $n = 0;
    my @keys = qw( author date distribution id release user );
    # foreach my $dt ( sort{ $a <=> $b } keys( %$recent ) )
    foreach my $dt ( sort( keys( %$recent ) ) )
    {
        if( $n >= $offset )
        {
            my $this = $recent->{ $dt };
            my $ref = {};
            @$ref{ @keys } = @$this{ @keys };
            push( @$favorites, $ref );
        }
        $n++;
        last if( $n > ( $offset + $size ) );
    }
    my $res =
    {
    favorites => $favorites,
    took => 8,
    total => scalar( keys( %$recent ) ),
    };
    
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/favorite/recent
    # NOTE sub _PostFavoriteRecent
    *_PostFavoriteRecent = \&_GetFavoriteRecent;
}

# NOTE: GET /v1/favorite/users_by_distribution/{distribution}
# Example: /v1/favorite/users_by_distribution/Nice-Try
sub _GetFavoriteUsers
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    # e.g.: DBI
    my $dist = $vars->{distribution} ||
        return( $self->error({ code => 400, message => 'Not found' }) );
    ( my $package = $dist ) =~ s/-/::/g;
    my $users = [];
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        if( exists( $data->{users}->{ $user }->{modules} ) &&
            ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' &&
            exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $package };
            foreach my $author ( @{$this->{likers}} )
            {
                foreach my $user ( keys( %{$data->{users}} ) )
                {
                    if( $user eq $author )
                    {
                        push( @$users, $data->{users}->{ $user }->{id} );
                        last;
                    }
                }
            }
        }
    }
    # Returns an empty hash reference if nothing found.
    my $res = { users => $users };
    
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/favorite/users_by_distribution/{distribution}
    # NOTE sub _PostFavoriteUsers
    *_PostFavoriteUsers = \&_GetFavoriteUsers;
}

# NOTE: GET /v1/favorite/_mapping
# GetFavoriteMapping is accessed directly in the data

# NOTE: POST /v1/favorite/_mapping
# PostFavoriteMapping is accessed directly in the data

{
    no warnings 'once';
    # NOTE: GET /v1/favorite/_search
    # NOTE: POST /v1/favorite/_search
    # NOTE: sub _GetFavoriteSearch
    # NOTE: sub _PostFavoriteSearch
    *_GetFavoriteSearch = \&_GetFavorite;
    *_PostFavoriteSearch = \&_GetFavorite;
}

# NOTE: DELETE /v1/favorite/_search/scroll
# TODO: _DeleteFavoriteSearchScroll
# Need to find out exactly what this endpoint returns
sub _DeleteFavoriteSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $msg = { code => 501, message => 'Not implemented' };
    my $payload = $self->json->encode( $msg );
    my $resp = HTTP::Promise::Response->new( $msg->{code}, HTTP::Promise::Status->status_message( $msg->{code} => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/favorite/_search/scroll
sub _GetFavoriteSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{scroll} = 1;
    return( $self->_GetFavoriteSearch( %$opts ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/favorite/_search/scroll
    # NOTE: sub _PostFavoriteSearchScroll
    *_PostFavoriteSearchScroll = \&_GetFavoriteSearchScroll;
}

# NOTE: GET /v1/file
sub _GetFile
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->_search( %$opts, type => 'file', total => 29178111, callback => sub
    {
        my $this = shift( @_ );
        return({
            _id => $this->{id},
            _index => 'cpan_v1_01',
            _score => 1,
            _source => $this,
            _type => 'file',
        });
    }) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/file
    # NOTE: sub _PostFile
    *_PostFile = \&_GetFile;
}

# NOTE GET /v1/file/{author}/{release}/{path}
# Example: /v1/file/JDEGUEST/Nice-Try-v1.3.4/lib/Nice/Try.pm
sub _GetFileByAuthorReleaseFilePath
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $rel = $vars->{release} ||
        return( $self->error({ code => 400, message => 'Missing parameter: release' }) );
    my $path = $vars->{path};
    my @parts = split( /-/, $rel );
    my $vers = pop( @parts );
    my $dist = join( '-', @parts );
    ( my $package = $dist ) =~ s/-/::/g;
    my $res;
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
        if( exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $package };
            my $is_dir = ( !length( $path ) || substr( $path, -1, 1 ) eq '/' ) ? \1 : \0;
            my @keys = qw(
                abstract author authorized date deprecated description distribution
                download_url id maturity stat status version version_numified
            );
            $res = 
            {
            binary => \0,
            directory => $is_dir,
            dist_fav_count => scalar( @{$this->{likers}} ),
            documentation => $package,
            indexed => \1,
            level => 2,
            mime => ( $is_dir ? 'text/plain' : 'text/x-script.perl-module' ),
            module => [
                {
                associated_pod => "${author}/${rel}/${path}",
                authorized => \1,
                indexed => \1,
                name => $package,
                version => $vers,
                version_numified => $this->{version_numified},
                }],
                name => ( $path ? [split( /\//, $path )]->[-1] : $rel ),
                path => $path,
                pod => '',
                pod_lines => [[1234, 5678]],
                release => $rel,
                sloc => 1234,
                slop => 456,
                suggest => { input => [$package], payload => { doc_name => $package }, weight => 123 },
            };
            @$res{ @keys } = @$this{ @keys };
            last;
        }
    }
    
    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => 'Not found' };
    }
    
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/file/{author}/{release}/{path}
    # NOTE: sub _PostFileByAuthorReleaseFilePath
    *_PostFileByAuthorReleaseFilePath = \&_GetFileByAuthorReleaseFilePath;
}

# NOTE GET /v1/file/dir/{path}
# Example: /v1/file/dir/JDEGUEST/Module-Generic-v0.31.0/lib/Module/Generic
sub _GetFilePathDirectoryContent
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $path = $vars->{path} ||
        return( $self->error({ code => 400, message => 'Missing parameter: path' }) );
    my $res = 
    {
        dir => [],
    };
    if( substr( $path, -1, 1 ) eq '/' )
    {
        my @parts = split( /\//, $path );
        my $author = shift( @parts );
        my $rel = shift( @parts );
        my $dir_path = join( '/', @parts );
        $dir_path =~ s,/+$,,g;
        @parts = split( /-/, $rel );
        my $vers = pop( @parts );
        my $file = $parts[-1] . '.pm';
        my $std_path = join( '/', 'lib', @parts[0..$#parts-1] );
        my $dist = join( '-', @parts );
        ( my $package = $dist ) =~ s/-/::/g;
        # This is just mock data, so we only accept standard top directory path for this distribution
        $dir_path = $std_path if( $dir_path ne $std_path );
        foreach my $user ( keys( %{$data->{users}} ) )
        {
            next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
            if( exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
            {
                my $this = $data->{users}->{ $user }->{modules}->{ $package };
                $res->{dir} = [{
                    directory => \0,
                    documentation => $package,
                    mime => 'text/x-script.perl-module',
                    name => $file,
                    path => "${dir_path}/${file}",
                    slop => 123,
                    'stat.mtime' => $this->{stat}->{mtime},
                    'stat.size' => $this->{stat}->{size},
                }];
                last;
            }
        }
    }
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE POST /v1/file/dir/{path}
    # NOTE: sub _PostFilePathDirectoryContent
    *_PostFilePathDirectoryContent = \&_GetFilePathDirectoryContent;
}

# NOTE: GET /v1/file/_mapping
# GetFileMapping is accessed directly in the data

# NOTE: POST /v1/file/_mapping
# PostFileMapping is accessed directly in the data

{
    no warnings 'once';
    # NOTE: GET /v1/file/_search
    # NOTE: POST /v1/file/_search
    # NOTE: sub _GetFileSearch
    # NOTE: sub _PostFileSearch
    *_GetFileSearch = \&_GetFile;
    *_PostFileSearch = \&_GetFile;
}

# NOTE: DELETE /v1/file/_search/scroll
# TODO: _DeleteFileSearchScroll
# Need to find out exactly what this endpoint returns
sub _DeleteFileSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $msg = { code => 501, message => 'Not implemented' };
    my $payload = $self->json->encode( $msg );
    my $resp = HTTP::Promise::Response->new( $msg->{code}, HTTP::Promise::Status->status_message( $msg->{code} => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/file/_search/scroll
sub _GetFileSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{scroll} = 1;
    return( $self->_GetFileSearch( %$opts ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/file/_search/scroll
    # NOTE: sub _PostFileSearchScroll
    *_PostFileSearchScroll = \&_GetFileSearchScroll;
}

# TODO
# NOTE: GET /v1/history/documentation/{module}/{path}
sub _GetDocumentationHistory
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $res;
    my $payload = $self->json->utf8->encode( $res );

    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'text/html; charset=UTF-8',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/history/documentation/{module}/{path}
    # NOTE: sub _PostDocumentationHistory
    *_PostDocumentationHistory = \&_GetDocumentationHistory;
}

# TODO
# NOTE: GET /v1/search/history/file/{distribution}/{path}
sub _GetFileHistory
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $res;
    my $payload = $self->json->utf8->encode( $res );

    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'text/html; charset=UTF-8',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/search/history/file/{distribution}/{path}
    # NOTE: sub _PostFileHistory
    *_PostFileHistory = \&_GetFileHistory;
}

# TODO
# NOTE: GET /v1/search/history/module/{module}/{path}
sub _GetModuleHistory
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $res;
    my $payload = $self->json->utf8->encode( $res );

    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'text/html; charset=UTF-8',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/search/history/module/{module}/{path}
    # NOTE: sub _PostModuleHistory
    *_PostModuleHistory = \&_GetModuleHistory;
}

# NOTE: GET /v1/login/index
sub _GetLoginPage
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $html = qq{<pre><h1>Login via</h1><ul><li><a href="/login/github">GitHub</a></li> <li><a href="/login/google">Google</a></li> <li><a href="/login/pause">PAUSE</a></li> <li><a href="/login/twitter">Twitter</a></li></ul></pre>};
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'text/html; charset=UTF-8',
            Content_Length => length( $html ),
            Date => $self->_date_now,
        ], $html,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/login/index
    # NOTE: sub _PostLoginPage
    *_PostLoginPage = \&_GetLoginPage;
}

# NOTE: GET /v1/mirror
sub _GetMirror
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $res =
    {
        mirrors => [
            {
                ccode => "zz",
                city => "Everywhere",
                contact => [{ contact_site => "perl.org", contact_user => "cpan" }],
                continent => "Global",
                country => "Global",
                distance => undef,
                dnsrr => "N",
                freq => "instant",
                http => "http://www.cpan.org/",
                inceptdate => "2021-04-09T00:00:00",
                location => [0, 0],
                name => "www.cpan.org",
                org => "Global CPAN CDN",
                src => "rsync://cpan-rsync.perl.org/CPAN/",
                tz => 0,
            },
        ],
        took => 7,
        total => 1,
    };
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/mirror
    # NOTE: sub _PostMirror
    *_PostMirror = \&_GetMirror;
}

{
    no warnings 'once';
    # NOTE: GET /v1/mirror/search
    # NOTE: sub _GetMirrorSearch
    *_GetMirrorSearch = \&_GetMirror;
    # NOTE: POST /v1/mirror/search
    # NOTE: sub _PostMirrorSearch
    *_PostMirrorSearch = \&_GetMirror;
}

# NOTE: GET /v1/module
sub _GetModule
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->_search( %$opts, type => 'distribution', total => 29178966, callback => sub
    {
        my $this = shift( @_ );
        return({
            _id => $this->{id},
            _index => 'cpan_v1_01',
            _score => 1,
            _source => $this,
            _type => 'file',
        });
    }) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/module
    # NOTE: sub _PostModule
    *_PostModule = \&_GetModule;
}

# NOTE: GET /v1/module/{module}
# Example: /v1/module/HTTP::Message
sub _GetModuleFile
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $mod = $vars->{module} ||
        return( $self->error({ code => 400, message => 'Missing parameter: module' }) );
    my $res;
    foreach my $user ( sort( keys( %{$data->{users}} ) ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
        if( exists( $data->{users}->{ $user }->{modules}->{ $mod } ) )
        {
            $res = $data->{users}->{ $user }->{modules}->{ $mod };
            last;
        }
    }

    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => 'Not found' };
    }
    
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/module/{module}
    # NOTE: sub _PostModuleFile
    *_PostModuleFile = \&_GetModuleFile;
}

# NOTE: GET /v1/module/_mapping
# GetModuleMapping is accessed directly in the data

# NOTE: POST /v1/module/_mapping
# PostModuleMapping is accessed directly in the data

{
    no warnings 'once';
    # NOTE: GET /v1/module/_search
    # NOTE: POST /v1/module/_search
    # NOTE: sub _GetModuleSearch
    # NOTE: sub _PostModuleSearch
    *_GetModuleSearch = \&_GetModule;
    *_PostModuleSearch = \&_GetModule;
}

# NOTE: DELETE /v1/module/_search/scroll
# TODO: _DeleteModuleSearchScroll
# Need to find out exactly what this endpoint returns
sub _DeleteModuleSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $msg = { code => 501, message => 'Not implemented' };
    my $payload = $self->json->encode( $msg );
    my $resp = HTTP::Promise::Response->new( $msg->{code}, HTTP::Promise::Status->status_message( $msg->{code} => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/module/_search/scroll
sub _GetModuleSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{scroll} = 1;
    return( $self->_GetModuleSearch( %$opts ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/module/_search/scroll
    # NOTE: sub _PostModuleSearchScroll
    *_PostModuleSearchScroll = \&_GetModuleSearchScroll;
}

# NOTE: GET /v1/package
sub _GetPackage
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->_search( %$opts, type => 'package', total => 29178966, callback => sub
    {
        my $this = shift( @_ );
        return({
            _id => $this->{package},
            _index => 'cpan_v1_01',
            _score => 1,
            _source => 
            {
                author => $this->{author},
                dist_version => $this->{version},
                distribution => $this->{distribution},
                file => join( '/', substr( $this->{author}, 0, 1 ), substr( $this->{author}, 0, 2 ), $this->{author}, $this->{archive} ),
                module_name => $this->{package},
                version => $this->{version},
            },
            _type => 'package',
        });
    }) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/package
    # NOTE: sub _PostPackage
    *_PostPackage = \&_GetPackage;
}

# NOTE: GET /v1/package/modules/{distribution}
sub _GetPackageDistributionList
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $dist = $vars->{distribution} ||
        return( $self->error({ code => 400, message => 'Missing parameter: distribution' }) );
    ( my $package = $dist ) =~ s/-/::/g;
    my $res;
    foreach my $user ( sort( keys( %{$data->{users}} ) ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
        if( exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            $res = { modules => [ $package ] };
            last;
        }
    }

    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => "Cannot find last release for ${dist}" };
    }
    
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/package/modules/{distribution}
    # NOTE: sub _PostPackageDistributionList
    *_PostPackageDistributionList = \&_GetPackageDistributionList;
}

# NOTE: GET /v1/package/{module}
# Example: /v1/package/HTTP::Message
sub _GetModulePackage
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $mod = $vars->{module} ||
        return( $self->error({ code => 400, message => 'Missing parameter: module' }) );
    my $res;
    foreach my $user ( sort( keys( %{$data->{users}} ) ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
        if( exists( $data->{users}->{ $user }->{modules}->{ $mod } ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $mod };
            $res = 
            {
            author => $this->{author},
            dist_version => $this->{version},
            distribution => $this->{distribution},
            file => join( '/', substr( $this->{author}, 0, 1 ), substr( $this->{author}, 0, 2 ), $this->{author}, $this->{archive} ),
            module_name => $this->{package},
            version => $this->{version},
            };
            last;
        }
    }
    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => 'Not found' };
    }
    
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/package/modules/{distribution}
    # NOTE: sub _PostModulePackage
    *_PostModulePackage = \&_GetModulePackage;
}

# NOTE: GET /v1/permission
# Example: /v1/package/HTTP::Message
sub _GetPermission
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->_search( %$opts, type => 'permission', total => 29178966, callback => sub
    {
        my $this = shift( @_ );
        return({
            _id => $this->{package},
            _index => 'cpan_v1_01',
            _score => 1,
            _source => 
            {
                co_maintainers => $this->{contributors},
                module_name => $this->{package},
                owner => $this->{author},
            },
            _type => 'permission',
        });
    }) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/permission
    # NOTE: sub _PostPermission
    *_PostPermission = \&_GetPermission;
}

# NOTE: GET /v1/permission/by_author/{author}
# Example: /v1/permission/by_author/OALDERS
sub _GetPermissionByAuthor
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $res = { permissions => [] };
    if( exists( $data->{users}->{ $author } ) )
    {
        my $mods = {};
        foreach my $package ( keys( %{$data->{users}->{ $author }->{modules}} ) )
        {
            $mods->{ $package } =
            {
                co_maintainers => [],
                module_name => $package,
                owner => $author,
            };
        }
        foreach my $package ( keys( %{$data->{users}->{ $author }->{modules}} ) )
        {
            foreach my $ref ( @{$data->{users}->{ $author }->{modules}->{ $package }->{contributions}} )
            {
                ( my $class = $ref->{distribution} ) =~ s/-/::/g;
                $mods->{ $class } =
                {
                    co_maintainers => [$author],
                    module_name => $class,
                    owner => undef,
                };
            }
        }
        push( @{$res->{permissions}}, map( $mods->{ $_ }, sort( keys( %$mods ) ) ) );
    }

    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/permission/by_author/{author}
    # NOTE: sub _PostPermissionByAuthor
    *_PostPermissionByAuthor = \&_GetPermissionByAuthor;
}

# NOTE: GET /v1/permission/by_module
# Example: /v1/permission/by_module?module=DBD::DBM::Statement
sub _GetPermissionByModuleQueryString
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    $form->{module} = $opts->{module} if( exists( $opts->{module} ) );
    if( !exists( $form->{module} ) || !length( $form->{module} // '' ) )
    {
        return( $self->error({ code => 400, message => 'Missing parameter: module' }) );
    }
    # If called by _GetPermissionByModule() or by query string or JSON payload
    my $mods = ref( $form->{module} ) eq 'ARRAY'
        ? $form->{module}
        : [$form->{module}];
    my $res = { permissions => [] };
    foreach my $package ( @$mods )
    {
        foreach my $user ( sort( keys( %{$data->{users}} ) ) )
        {
            next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
            if( exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
            {
                my $this = $data->{users}->{ $user }->{modules}->{ $package };
                push( @{$res->{permissions}}, 
                {
                    co_maintainers => [map( $_->{pauseid}, @{$this->{contributions}} )],
                    module_name => $package,
                    owner => $this->{author},
                });
                last;
            }
        }
    }
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/permission/by_module
    # NOTE: sub _PostPermissionByModuleJSON
    *_PostPermissionByModuleJSON = \&_GetPermissionByModuleQueryString;
}

# NOTE: GET /v1/permission/by_module/{module}
sub _GetPermissionByModule
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $vars = $opts->{vars};
    my $module = $vars->{module} ||
        return( $self->error({ code => 400, message => 'Missing parameter: module' }) );
    return( $self->_GetPermissionByModuleQueryString( %$opts, module => $module ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/permission/by_module/{module}
    # NOTE: sub _PostPermissionByModule
    *_PostPermissionByModule = \&_GetPermissionByModule;
}

# NOTE: GET /v1/permission/{module}
# Example: /v1/permission/HTTP::Message
sub _GetModulePermission
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $vars = $opts->{vars};
    my $module = $vars->{module} ||
        return( $self->error({ code => 400, message => 'Missing parameter: module' }) );
    return( $self->_GetPermissionByModuleQueryString( %$opts, module => $module ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/permission/{module}
    # NOTE: sub _PostModulePermission
    *_PostModulePermission = \&_GetModulePermission;
}

# NOTE: GET /v1/pod_render
# Example:
# =encoding utf-8\n\n=head1 Hello World\n\nSomething here\n\n=oops\n\n=cut\n
# /v1/pod_render?pod=3Dencoding+utf-8%0A%0A%3Dhead1+Hello+World%0A%0ASomething+here%0A%0A%3Doops%0A%0A%3Dcut%0A
# 
sub _GetRenderPOD
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $pod = $form->{pod};
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'text/plain; charset=UTF-8',
            Content_Length => length( $pod // '' ),
            Date => $self->_date_now,
        ], $pod,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/pod_render
    # NOTE: sub _PostRenderPOD
    *_PostRenderPOD = \&_GetRenderPOD;
}

# NOTE GET /v1/pod/{module}
# Example: /v1/pod/HTTP::Message?content-type=text/plain
sub _GetModulePOD
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    # So this can also be called from _GetModuleReleasePod()
    my $module = exists( $opts->{module} )
        ? $opts->{module}
        : $vars->{module};
    return( $self->error({ code => 400, message => 'Missing parameter: module' }) ) if( !length( $module // '' ) );
    my $type = $form->{'content-type'} || 'text/plain';
    $type = 'text/html' unless( $type =~ m,^text/(?:html|plain|x-markdown|x-pod)$,i );
    $type = lc( $type );
    my $res;
    foreach my $user ( sort( keys( %{$data->{users}} ) ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
        if( exists( $data->{users}->{ $user }->{modules}->{ $module } ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $module };
            my $info = $data->{users}->{ $user };
            if( $type eq 'text/html' )
            {
                $res = <<EOT;
<ul id="index">
  <li><a href="#NAME">NAME</a></li>
  <li><a href="#VERSION">VERSION</a></li>
  <li><a href="#SYNOPSIS">SYNOPSIS</a></li>
  <li><a href="#DESCRIPTION">DESCRIPTION</a></li>
  <li><a href="#AUTHOR">AUTHOR</a></li>
  <li><a href="#COPYRIGHT-AND-LICENSE">COPYRIGHT AND LICENSE</a></li>
</ul>

<h1 id="NAME">NAME</h1>

<p>${module} - $this->{abstract}</p>

<h1 id="VERSION">VERSION</h1>

<p>version $this->{version}</p>

<h1 id="SYNOPSIS">SYNOPSIS</h1>

<h1 id="DESCRIPTION">DESCRIPTION</h1>

<h1 id="AUTHOR">AUTHOR</h1>

<p>$info->{name} &lt;$info->{email}->[0]&gt;</p>

<h1 id="COPYRIGHT-AND-LICENSE"><a id="COPYRIGHT"></a>COPYRIGHT AND LICENSE</h1>

<p>This software is copyright (c) 2023 by $info->{name}.</p>

<p>This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.</p>

EOT
            }
            elsif( $type eq 'text/plain' )
            {
                $res = <<EOT;
NAME
    ${module} - $this->{abstract}

VERSION
    version $this->{version}

SYNOPSIS

DESCRIPTION

AUTHOR
    $info->{name} <$info->{email}->[0]>

COPYRIGHT AND LICENSE
    This software is copyright (c) 2023 by $info->{name}.

    This is free software; you can redistribute it and/or modify it under the
    same terms as the Perl 5 programming language system itself.
EOT
            }
            elsif( $type eq 'text/x-markdown' )
            {
                $res = <<EOT;
# NAME

${module} - $this->{abstract}

# VERSION

version $this->{version}

# SYNOPSIS

# DESCRIPTION

# AUTHOR

$info->{name} <$info->{email}->[0]>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by $info->{name}.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

EOT
            }
            elsif( $type eq 'text/x-pod' )
            {
                $res = <<EOT;
=head1 NAME

${module} - $this->{abstract}

=head1 VERSION

version $this->{version}

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

$info->{name} <$info->{email}->[0]>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by $info->{name}.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

EOT
            }
        }
    }
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => $type,
            Content_Length => length( $res // '' ),
            Date => $self->_date_now,
        ], $res,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/pod/{module}
    # NOTE: sub _PostModulePOD
    *_PostModulePOD = \&_GetModulePOD;
}

# NOTE: GET /v1/pod/{author}/{release}/{path}
# Example: /v1/pod/OALDERS/HTTP-Message-6.36/lib/HTTP/Message.pm?content-type=text/x-markdown
sub _GetModuleReleasePod
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $release = $vars->{release} ||
        return( $self->error({ code => 400, message => 'Missing parameter: release' }) );
    my $path = $vars->{path} ||
        return( $self->error({ code => 400, message => 'Missing parameter: path' }) );
    my @parts = split( /-/, $release );
    my $vers = pop( @parts );
    my $dist = join( '-', @parts );
    ( my $package = $dist ) =~ s/-/::/g;
    return( $self->_GetModulePOD( %$opts, module => $package ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/pod/{module}
    # NOTE: sub _PostModuleReleasePod
    *_PostModuleReleasePod = \&_GetModuleReleasePod;
}

# NOTE: GET /v1/rating
sub _GetRating
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->_search( %$opts, type => 'rating', total => 29178966, callback => sub
    {
        my $this = shift( @_ );
        return({
            _id => $this->{id},
            _index => 'cpan_v1_01',
            _score => 1,
            _source => 
            {
                author => $this->{author},
                date => $this->{date},
                distribution => $this->{distribution},
                rating => '4.0',
                release => 'PLACEHOLDER',
                user => 'CPANRatings',
            },
            _type => 'rating',
        });
    }) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/rating
    # NOTE: sub _PostRating
    *_PostRating = \&_GetRating;
}

# NOTE: GET /v1/rating/by_distributions
# Example: /v1/rating/by_distributions?distribution=HTTP-Message
sub _GetRatingByDistribution
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    return( $self->error({ code => 400, message => 'Missing param: distribution' }) ) if( !exists( $form->{distribution} ) );
    my $dists = ref( $form->{distribution} ) eq 'ARRAY' ? $form->{distribution} : [$form->{distribution}];
    my $res;
    foreach my $dist ( @$dists )
    {
        ( my $package = $dist ) =~ s/-/::/g;
        foreach my $user ( sort( keys( %{$data->{users}} ) ) )
        {
            next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
            if( exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
            {
                my $this = $data->{users}->{ $user }->{modules}->{ $package };
                $res = { distributions => {}, took => 8, total => 19 } if( !defined( $res ) );
                $res->{distributions}->{ $package } =
                {
                    # Imaginary numbers, and all the same for this mock data
                    avg => 4.90000009536743,
                    count => 19,
                    max => 4.90000009536743,
                    min => 4.90000009536743,
                    sum => 93.1000018119812,
                };
            }
        }
    }
    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => 'Not found' };
    }
    
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/rating/by_distributions
    # NOTE: sub _PostRatingByDistribution
    *_PostRatingByDistribution = \&_GetRatingByDistribution;
}

# NOTE: GET /v1/rating/_mapping
# GetRatingMapping is accessed directly in the data

# NOTE: POST /v1/rating/_mapping
# PostRatingMapping is accessed directly in the data

{
    no warnings 'once';
    # NOTE: GET /v1/rating/_search
    # NOTE: POST /v1/rating/_search
    # NOTE: sub _GetRatingSearch
    # NOTE: sub _PostRatingSearch
    *_GetRatingSearch = \&_GetRating;
    *_PostRatingSearch = \&_GetRating;
}

# NOTE: DELETE /v1/rating/_search/scroll
# TODO: _DeleteRatingSearchScroll
# Need to find out exactly what this endpoint returns
sub _DeleteRatingSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $msg = { code => 501, message => 'Not implemented' };
    my $payload = $self->json->encode( $msg );
    my $resp = HTTP::Promise::Response->new( $msg->{code}, HTTP::Promise::Status->status_message( $msg->{code} => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/rating/_search/scroll
sub _GetRatingSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{scroll} = 1;
    return( $self->_GetRatingSearch( %$opts ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/rating/_search/scroll
    # NOTE: sub _PostRatingSearchScroll
    *_PostRatingSearchScroll = \&_GetRatingSearchScroll;
}

# NOTE: GET /v1/release
sub _GetRelease
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    # Properties to copy
    my @keys = qw(
        abstract archive author authorized changes_file checksum_md5 checksum_sha256 
        date dependency deprecated distribution download_url first id license main_module
        maturity metadata name provides resources stat status version version_numified
    );
    return( $self->_search( %$opts, type => 'distribution', total => 14410, callback => sub
    {
        my $this = shift( @_ );
        my $ref = {};
        @$ref{ @keys } = @$this{ @keys };
        return({
            _id => $this->{id},
            _index => 'cpan_v1_01',
            _score => 1,
            _source => $ref,
            _type => 'release',
        });
    }) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release
    # NOTE: sub _PostRelease
    *_PostRelease = \&_GetRelease;
}

# NOTE: GET /v1/release/{distribution}
sub _GetReleaseDistribution
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $dist = $opts->{distribution} || $vars->{distribution} ||
        return( $self->error({ code => 400, message => 'Missing parameter: distribution' }) );
    ( my $package = $dist ) =~ s/-/::/g;
    # Properties to copy
    my @keys = qw(
        abstract archive author authorized changes_file checksum_md5 checksum_sha256 
        date dependency deprecated distribution download_url first id license main_module
        maturity metadata name provides resources stat status version version_numified
    );
    my $res;
    foreach my $user ( sort( keys( %{$data->{users}} ) ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
        if( exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $package };
            $res = {};
            @$res{ @keys } = @$this{ @keys };
            last;
        }
    }
    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => 'Not found' };
    }
    
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/{distribution}
    # NOTE: sub _PostReleaseDistribution
    *_PostReleaseDistribution = \&_GetReleaseDistribution;
}

# NOTE: GET /v1/release/{author}/{release}
# Example: /v1/release/OALDERS/HTTP-Message-6.36
sub _GetAuthorReleaseDistribution
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $rel = $vars->{release} ||
        return( $self->error({ code => 400, message => 'Missing parameter: release' }) );
    my @parts = split( /-/, $rel );
    my $vers = pop( @parts );
    my $dist = join( '-', @parts );
    return( $self->_GetReleaseDistribution( %$opts, distribution => $dist ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/{author}/{release}
    # NOTE: sub _PostAuthorReleaseDistribution
    *_PostAuthorReleaseDistribution = \&_GetAuthorReleaseDistribution;
}

# NOTE: GET /v1/release/all_by_author/{author}
# Example: /v1/release/all_by_author/JDEGUEST
sub _GetAllReleasesByAuthor
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $all = [];
    my @keys = qw(
        abstract author authorized date distribution download_url maturity name status
        version
    );
    if( exists( $data->{users}->{ $author } ) )
    {
        foreach my $package ( sort( keys( %{$data->{users}->{ $author }->{modules}} ) ) )
        {
            my $this = $data->{users}->{ $author }->{modules}->{ $package };
            my $ref = {};
            @$ref{ @keys } = @$this{ @keys };
            push( @$all, $ref );
        }
    }
    my $res =
    {
        release => $all,
        took => 12,
        total => scalar( @$all ),
    };
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/all_by_author/{author}
    # NOTE: sub _PostAllReleasesByAuthor
    *_PostAllReleasesByAuthor = \&_GetAllReleasesByAuthor;
    # NOTE: GET /v1/release/by_author/{author}
    # NOTE: sub _GetReleaseByAuthor
    * _GetReleaseByAuthor = \&_GetAllReleasesByAuthor;
    # NOTE: POST /v1/release/by_author/{author}
    # NOTE: sub _PostReleaseByAuthor
    *_PostReleaseByAuthor = \&_GetAllReleasesByAuthor;
}

# NOTE: GET /v1/release/contributors/{author}/{release}
# Example: /v1/release/contributors/OALDERS/HTTP-Message-6.36
sub _GetReleaseDistributionContributors
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $rel = $vars->{release} ||
        return( $self->error({ code => 400, message => 'Missing parameter: release' }) );
    my @parts = split( /-/, $rel );
    my $vers = pop( @parts );
    my $dist = join( '-', @parts );
    ( my $package = $dist ) =~ s/-/::/g;
    my $all = [];
    if( exists( $data->{users}->{ $author } ) &&
        exists( $data->{users}->{ $author }->{modules} ) &&
        ref( $data->{users}->{ $author }->{modules} ) eq 'HASH' &&
        exists( $data->{users}->{ $author }->{modules}->{ $package } ) )
    {
        my $this = $data->{users}->{ $author }->{modules}->{ $package };
        my $contributors = $this->{contributors};
        foreach my $user ( @$contributors )
        {
            if( exists( $data->{users}->{ $user } ) )
            {
                my $info = $data->{users}->{ $user };
                my $ref = {};
                @$ref{qw( email name )} = @$info{qw( email name )};
                push( @$all, $ref );
            }
        }
    }
    my $res = { contributors => $all };
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/contributors/{author}/{release}
    # NOTE: sub _PostReleaseDistributionContributors
    *_PostReleaseDistributionContributors = \&_GetReleaseDistributionContributors;
}

# NOTE: GET /v1/release/files_by_category/{author}/{release}
sub _GetReleaseKeyFilesByCategory
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $rel = $vars->{release} ||
        return( $self->error({ code => 400, message => 'Missing parameter: release' }) );
    my @parts = split( /-/, $rel );
    my $vers = pop( @parts );
    my $dist = join( '-', @parts );
    ( my $package = $dist ) =~ s/-/::/g;
    my $res;
    if( exists( $data->{users}->{ $author } ) &&
        exists( $data->{users}->{ $author }->{modules} ) &&
        ref( $data->{users}->{ $author }->{modules} ) eq 'HASH' &&
        exists( $data->{users}->{ $author }->{modules}->{ $package } ) )
    {
        my $this = $data->{users}->{ $author }->{modules}->{ $package };
        my $info = $data->{users}->{ $author };
        $res =
        {
            categories =>
            {
                changelog =>
                [{
                    author => $this->{author},
                    category => 'changelog',
                    distribution => $dist,
                    name => 'Changes',
                    path => 'Changes',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                }],
                contributing =>
                [{
                    author => $this->{author},
                    category => 'contributing',
                    distribution => $dist,
                    name => 'CONTRIBUTING.md',
                    path => 'CONTRIBUTING.md',
                    release => $rel,
                    status => 'cpan',
                }],
                dist => 
                [{
                    author => $this->{author},
                    category => 'dist',
                    distribution => $dist,
                    name => 'Makefile.PL',
                    path => 'Makefile.PL',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                },
                {
                    author => $this->{author},
                    category => 'dist',
                    distribution => $dist,
                    name => 'META.json',
                    path => 'META.json',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                },
                {
                    author => $this->{author},
                    category => 'dist',
                    distribution => $dist,
                    name => 'META.yml',
                    path => 'META.yml',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                }],
                install => 
                [{
                    author => $this->{author},
                    category => 'dist',
                    distribution => $dist,
                    name => 'INSTALL',
                    path => 'INSTALL',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                }],
                license => 
                [{
                    author => $this->{author},
                    category => 'license',
                    distribution => $dist,
                    name => 'LICENSE',
                    path => 'LICENSE',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                }],
                other => 
                [{
                    author => $this->{author},
                    category => 'other',
                    distribution => $dist,
                    name => 'README.md',
                    path => 'README.md',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                }], 
            },
            took => 10,
            total => 8,
        };
    }
    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => 'Not found' };
    }
    
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/files_by_category/{author}/{release}
    # NOTE: sub _PostReleaseKeyFilesByCategory
    *_PostReleaseKeyFilesByCategory = \&_GetReleaseKeyFilesByCategory;
}

# NOTE: GET /v1/release/interesting_files/{author}/{release}
sub _GetReleaseInterestingFiles
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $rel = $vars->{release} ||
        return( $self->error({ code => 400, message => 'Missing parameter: release' }) );
    my @parts = split( /-/, $rel );
    my $vers = pop( @parts );
    my $dist = join( '-', @parts );
    ( my $package = $dist ) =~ s/-/::/g;
    my $res;
    if( exists( $data->{users}->{ $author } ) &&
        exists( $data->{users}->{ $author }->{modules} ) &&
        ref( $data->{users}->{ $author }->{modules} ) eq 'HASH' &&
        exists( $data->{users}->{ $author }->{modules}->{ $package } ) )
    {
        my $this = $data->{users}->{ $author }->{modules}->{ $package };
        my $info = $data->{users}->{ $author };
        $res =
        {
            files => [
                {
                    author => $this->{author},
                    category => 'changelog',
                    distribution => $dist,
                    name => 'Changes',
                    path => 'Changes',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                },
                {
                    author => $this->{author},
                    category => 'contributing',
                    distribution => $dist,
                    name => 'CONTRIBUTING.md',
                    path => 'CONTRIBUTING.md',
                    release => $rel,
                    status => 'cpan',
                },
                {
                    author => $this->{author},
                    category => 'dist',
                    distribution => $dist,
                    name => 'Makefile.PL',
                    path => 'Makefile.PL',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                },
                {
                    author => $this->{author},
                    category => 'dist',
                    distribution => $dist,
                    name => 'META.json',
                    path => 'META.json',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                },
                {
                    author => $this->{author},
                    category => 'dist',
                    distribution => $dist,
                    name => 'META.yml',
                    path => 'META.yml',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                },
                {
                    author => $this->{author},
                    category => 'dist',
                    distribution => $dist,
                    name => 'INSTALL',
                    path => 'INSTALL',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                },
                {
                    author => $this->{author},
                    category => 'license',
                    distribution => $dist,
                    name => 'LICENSE',
                    path => 'LICENSE',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                },
                {
                    author => $this->{author},
                    category => 'other',
                    distribution => $dist,
                    name => 'README.md',
                    path => 'README.md',
                    pod_lines => [],
                    release => $rel,
                    status => 'cpan',
                }, 
            ],
            took => 10,
            total => 8,
        };
    }
    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => 'Not found' };
    }
    
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/interesting_files/{author}/{release}
    # NOTE: sub _PostReleaseInterestingFiles
    *_PostReleaseInterestingFiles = \&_GetReleaseInterestingFiles;
}

# NOTE: GET /v1/release/latest_by_author/{author}
# Example: /v1/release/latest_by_author/OALDERS
sub _GetLatestReleaseByAuthor
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $res = { releases => [] };
    my @keys = qw( abstract author date distribution name status );
    if( exists( $data->{users}->{ $author } ) &&
        exists( $data->{users}->{ $author }->{modules} ) &&
        ref( $data->{users}->{ $author }->{modules} ) eq 'HASH' )
    {
        foreach my $package ( sort( keys( %{$data->{users}->{ $author }->{modules}} ) ) )
        {
            my $this = $data->{users}->{ $author }->{modules}->{ $package };
            my $ref = {};
            @$ref{ @keys } = @$this{ @keys };
            push( @{$res->{releases}}, $ref );
        }
    }
    $res->{took} = 10;
    $res->{total} = scalar( @{$res->{releases}} );
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/latest_by_author/{author}
    # NOTE: sub _PostLatestReleaseByAuthor
    *_PostLatestReleaseByAuthor = \&_GetLatestReleaseByAuthor;
}

# NOTE: GET /v1/release/latest_by_distribution/{distribution}
sub _GetLatestReleaseByDistribution
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $dist = $vars->{distribution} ||
        return( $self->error({ code => 400, message => 'Missing parameter: distribution' }) );
    ( my $package = $dist ) =~ s/-/::/g;
    # Properties to copy
    my @keys = qw(
        abstract archive author authorized changes_file checksum_md5 checksum_sha256 
        date dependency deprecated distribution download_url first id license main_module
        maturity metadata name provides resources stat status version version_numified
    );
    my $res;
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        if( exists( $data->{users}->{ $user } ) &&
            exists( $data->{users}->{ $user }->{modules} ) &&
            ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' &&
            exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $package };
            my $ref = {};
            @$ref{ @keys } = @$this{ @keys };
            $res = 
            {
                release => $ref,
                took => 3,
                total => 1,
            };
        }
    }

    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => 'Not found' };
    }
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/latest_by_distribution/{distribution}
    # NOTE: sub _PostLatestReleaseByDistribution
    *_PostLatestReleaseByDistribution = \&_GetLatestReleaseByDistribution;
}

# NOTE: GET /v1/release/modules/{author}/{release}
# Example: /v1/release/modules/OALDERS/HTTP-Message-6.36
sub _GetReleaseModules
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $rel = $vars->{release} ||
        return( $self->error({ code => 400, message => 'Missing parameter: release' }) );
    my @parts = split( /-/, $rel );
    my $vers = pop( @parts );
    my $dist = join( '-', @parts );
    ( my $package = $dist ) =~ s/-/::/g;
    my $res = { files => [], took => 10, total => 1 };
    my @keys = qw(
        abstract archive author authorized changes_file checksum_md5 checksum_sha256 
        date dependency deprecated distribution download_url first id license main_module
        maturity metadata name provides resources stat status version version_numified
    );
    if( exists( $data->{users}->{ $author } ) &&
        exists( $data->{users}->{ $author }->{modules} ) &&
        ref( $data->{users}->{ $author }->{modules} ) eq 'HASH' &&
        exists( $data->{users}->{ $author }->{modules}->{ $package } ) )
    {
        my $this = $data->{users}->{ $author }->{modules}->{ $package };
        my $ref = {};
        @$ref{ @keys } = @$this{ @keys };
        push( @{$res->{files}}, $ref );
    }
    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => $code, message => 'Not found' };
    }
    
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/modules/{author}/{release}
    # NOTE: sub _PostReleaseModules
    *_PostReleaseModules = \&_GetReleaseModules;
}

# NOTE: GET /v1/release/recent
# See also _GetFavoriteRecent()
sub _GetReleaseRecent
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $page = $form->{page} //= 1;
    my $size = $form->{size} //= 10;
    # $page cannot be 0. It falls back to 1
    $page ||= 1;
    my $recent = $self->_build_recent || 
        return( $self->pass_error );
    
    my $releases = [];
    my $offset = ( ( $page - 1 ) * $size );
    my $n = 0;
    my @keys = qw( author date distribution id release user );
    # foreach my $dt ( sort{ $a <=> $b } keys( %$recent ) )
    foreach my $dt ( sort( keys( %$recent ) ) )
    {
        if( $n >= $offset )
        {
            my $this = $recent->{ $dt };
            my $ref = {};
            @$ref{ @keys } = @$this{ @keys };
            push( @$releases, $ref );
        }
        $n++;
        last if( $n > ( $offset + $size ) );
    }
    my $res =
    {
    releases => $releases,
    took => 8,
    total => scalar( keys( %$recent ) ),
    };
    
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/recent
    # NOTE: sub _PostReleaseRecent
    *_PostReleaseRecent = \&_GetReleaseRecent;
}

# NOTE: GET /v1/release/top_uploaders
sub _GetTopReleaseUploaders
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $all = {};
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        $all->{ $user } = scalar( keys( %{$data->{users}->{ $user }->{modules}} ) );
    }
    my $res = { counts => $all, took => 10, total => scalar( keys( %$all ) ) };
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/top_uploaders
    # NOTE: sub _PostTopReleaseUploaders
    *_PostTopReleaseUploaders = \&_GetTopReleaseUploaders;
}

# NOTE: GET /v1/release/versions/{distribution}
sub _GetAllReleasesByVersion
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $dist = $vars->{distribution} ||
        return( $self->error({ code => 400, message => 'Missing parameter: distribution' }) );
    ( my $package = $dist ) =~ s/-/::/g;
    my $res = { releases => [], took => 10, total => 1 };
    my @keys = qw( author authorized date download_url maturity name status version );
    foreach my $user ( sort( keys( %{$data->{users}} ) ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
        if( exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $package };
            my $ref = {};
            @$ref{ @keys } = @$this{ @keys };
            push( @{$res->{releases}}, $ref );
            last;
        }
    }
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/versions/{distribution}
    # NOTE: sub _PostAllReleasesByVersion
    *_PostAllReleasesByVersion = \&_GetAllReleasesByVersion;
}

# NOTE: GET /v1/release/_mapping
# GetReleaseMapping is accessed directly in the data

# NOTE: POST /v1/release/_mapping
# PostReleaseMapping is accessed directly in the data

{
    no warnings 'once';
    # NOTE: GET /v1/release/_search
    # NOTE: POST /v1/release/_search
    # NOTE: sub _GetReleaseSearch
    # NOTE: sub _PostReleaseSearch
    *_GetReleaseSearch = \&_GetRelease;
    *_PostReleaseSearch = \&_GetRelease;
}

# NOTE: DELETE /v1/release/_search/scroll
# TODO: _DeleteReleaseSearchScroll
# Need to find out exactly what this endpoint returns
sub _DeleteReleaseSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $msg = { code => 501, message => 'Not implemented' };
    my $payload = $self->json->encode( $msg );
    my $resp = HTTP::Promise::Response->new( $msg->{code}, HTTP::Promise::Status->status_message( $msg->{code} => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/release/_search/scroll
sub _GetReleaseSearchScroll
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{scroll} = 1;
    return( $self->_GetReleaseSearch( %$opts ) );
}

{
    no warnings 'once';
    # NOTE: POST /v1/release/_search/scroll
    # NOTE: sub _PostReleaseSearchScroll
    *_PostReleaseSearchScroll = \&_GetReleaseSearchScroll;
}

# NOTE: GET /v1/reverse_dependencies/dist/{distribution}
# TODO: finalise code for this, but is it really necessary?
sub _GetReverseDependencyDist
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $dist = $vars->{distribution} ||
        return( $self->error({ code => 400, message => 'Missing parameter: distribution' }) );
    my $res = { data => [], took => 10, total => 0 };
#     foreach my $user ( sort( keys( %{$data->{users}} ) ) )
#     {
#         next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
#         if( exists( $data->{users}->{ $user }->{modules}->{ $module } ) )
#         {
#             my $this = $data->{users}->{ $user }->{modules}->{ $module };
#             my $ref = {};
#             @$ref{ @keys } = @$this{ @keys };
#             push( @{$res->{data}}, $ref );
#             last;
#         }
#     }
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/reverse_dependencies/dist/{distribution}
    # NOTE: sub _PostReverseDependencyDist
    *_PostReverseDependencyDist = \&_GetReverseDependencyDist;
}

# NOTE: GET /v1/reverse_dependencies/module/{module}
# TODO: finalise code for this, but is it really necessary?
sub _GetReverseDependencyModule
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $module = $vars->{module} ||
        return( $self->error({ code => 400, message => 'Missing parameter: module' }) );
    my $res = { data => [], took => 10, total => 0 };
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/reverse_dependencies/module/{module}
    # NOTE: sub _PostReverseDependencyModule
    *_PostReverseDependencyModule = \&_GetReverseDependencyModule;
}

# NOTE: GET /v1/search
# TODO: I have tried query with 'q', but it does not seem to work. Need to investigate (2023-08-25)
sub _GetSearchResult
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $msg = { code => 501, message => 'Not implemented' };
    my $payload = $self->json->encode( $msg );
    my $resp = HTTP::Promise::Response->new( $msg->{code}, HTTP::Promise::Status->status_message( $msg->{code} => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/search/autocomplete
sub _GetSearchAutocompleteResult
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    # Including JSON payload, such as:
    # {"query": {"match_all":{}},"filter":{"and":[{"term":{"pauseid":"JOHNDOE"}}]}}
    my $form = $req->as_form_data;
    my $q = $form->{'q'} || do
    {
        my $res =
        {
           source => \1,
           type => undef,
           inflate => 1,
           _refresh => 0,
           'index' => undef,
        };
        my $payload = $self->json->encode( $res );
        my $resp = HTTP::Promise::Response->new( 400, HTTP::Promise::Status->status_message( 400 => $lang ), [
                @STANDARD_HEADERS,
                Content_Type => 'application/json',
                Content_Length => length( $payload ),
                Date => $self->_date_now,
            ], $payload,
        );
        return( $resp );
    };
    my $query = "${q}.*";
    return( $self->_search( %$opts, query => $query, type => 'file', callback => sub
    {
        my $this = shift( @_ );
        return({
            _id => $this->{id},
            _index => "cpan_v1_01",
            _score => 6.99089,
            _type => "file",
            _version => 22,
            fields => {
               author => $this->{author},
               distribution => $this->{distribution},
               documentation => $this->{package},
               release => $this->{release}
            },
            'sort' => [
               6.99089,
               $this->{package},
            ]
        });
    }) );
}

# NOTE: GET /v1/search/autocomplete/suggest
sub _GetSearchAutocompleteSuggestResult
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    # Including JSON payload, such as:
    # {"query": {"match_all":{}},"filter":{"and":[{"term":{"pauseid":"JOHNDOE"}}]}}
    my $form = $req->as_form_data;
    my $q = $form->{'q'} || do
    {
        my $res =
        {
           source => \1,
           type => undef,
           inflate => 1,
           _refresh => 0,
           'index' => undef,
        };
        my $payload = $self->json->encode( $res );
        my $resp = HTTP::Promise::Response->new( 400, HTTP::Promise::Status->status_message( 400 => $lang ), [
                @STANDARD_HEADERS,
                Content_Type => 'application/json',
                Content_Length => length( $payload ),
                Date => $self->_date_now,
            ], $payload,
        );
        return( $resp );
    };
    
    my $suggestions = [];
    my @keys = qw( author date deprecated distribution name release );
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) );
        foreach my $package ( keys( %{$data->{users}->{ $user }->{modules}} ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $package };
            if( $this->{package} =~ /^$q/ )
            {
                my $ref = {};
                @$ref{ @keys } = @$this{ @keys };
                push( @$suggestions, $ref );
            }
        }
    }
    my $res = { suggestions => $suggestions };
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/search/first
sub _GetSearchFirstResult
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    # Including JSON payload, such as:
    # {"query": {"match_all":{}},"filter":{"and":[{"term":{"pauseid":"JOHNDOE"}}]}}
    my $form = $req->as_form_data;
    my $q = $form->{'q'} || do
    {
        my $res =
        {
           source => \1,
           type => undef,
           inflate => 1,
           _refresh => 0,
           'index' => undef,
        };
        my $payload = $self->json->encode( $res );
        my $resp = HTTP::Promise::Response->new( 400, HTTP::Promise::Status->status_message( 400 => $lang ), [
                @STANDARD_HEADERS,
                Content_Type => 'application/json',
                Content_Length => length( $payload ),
                Date => $self->_date_now,
            ], $payload,
        );
        return( $resp );
    };
    
    my $res;
    my @keys = qw( author authorized date description distribution documentation id indexed pod_lines release status );
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) );
        foreach my $package ( keys( %{$data->{users}->{ $user }->{modules}} ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $package };
            if( $this->{package} =~ /^$q/ )
            {
                $res = 
                {
                    'abstract.analyzed' => $this->{abstract},
                    dist_fav_count => scalar( @{$this->{likers}} ),
                    path => 'lib/' . join( '/', split( /::/, $this->{package} ) ) . '.pm',
                };
                @$res{ @keys } = @$this{ @keys };
            }
        }
    }
    
    my $code = 200;
    if( !defined( $res ) )
    {
        $code = 404;
        $res = { code => 404, message => 'The requested info could not be found' };
    }
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/search/web
sub _GetSearchWebResult
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    # Including JSON payload, such as:
    # {"query": {"match_all":{}},"filter":{"and":[{"term":{"pauseid":"JOHNDOE"}}]}}
    my $form = $req->as_form_data;
    my $from = $form->{from} // 0;
    my $size = $form->{size} // 10;
    my $q = $form->{'q'} || do
    {
        my $res =
        {
           source => \1,
           type => undef,
           inflate => 1,
           _refresh => 0,
           'index' => undef,
        };
        my $payload = $self->json->encode( $res );
        my $resp = HTTP::Promise::Response->new( 400, HTTP::Promise::Status->status_message( 400 => $lang ), [
                @STANDARD_HEADERS,
                Content_Type => 'application/json',
                Content_Length => length( $payload ),
                Date => $self->_date_now,
            ], $payload,
        );
        return( $resp );
    };
    
    my $results = [];
    my $offset = 0;
    my @keys = qw(
        abstract author authorized date description distribution documentation
        favorites id indexed module pod_lines release score status
    );
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        next unless( exists( $data->{users}->{ $user }->{modules} ) );
        $self->message( 4, scalar( keys( %{$data->{users}->{ $user }->{modules}} ) ), " modules for user $user" );
        foreach my $package ( keys( %{$data->{users}->{ $user }->{modules}} ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $package };
            $self->message( 4, "$user -> $package -> package = '$this->{package}', abstract = '$this->{abstract}', name = '$this->{name}', distribution = '$this->{distribution}'." );
            if( $this->{package} =~ /$q/ ||
                $this->{abstract} =~ /$q/ ||
                $this->{name} =~ /$q/ ||
                $this->{distribution} =~ /$q/ )
            {
                if( $offset >= $from )
                {
                    my $ref = {};
                    @$ref{ @keys } = @$this{ @keys };
                    my $result = 
                    {
                        distribution => $this->{distribution},
                        hits => [ $ref ],
                        total => 1,
                    };
                    push( @$results, $result );
                }
                $offset++;
                last if( scalar( @$results ) == $size );
            }
        }
    }
    my $res = { collapsed => \1, results => $results, took => 10, total => 1234 };
    my $payload = $self->json->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

# NOTE: GET /v1/source/{author}/{release}/{path}
sub _GetSourceReleasePath
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $author = $vars->{author} ||
        return( $self->error({ code => 400, message => 'Missing parameter: author' }) );
    my $rel = $vars->{release} ||
        return( $self->error({ code => 400, message => 'Missing parameter: release' }) );
    my @parts = split( /-/, $rel );
    my $vers = pop( @parts );
    my $dist = join( '-', @parts );
    my $package = join( '::', @parts );
    my $res;
    if( exists( $data->{users}->{ $author } ) &&
        exists( $data->{users}->{ $author }->{modules} ) &&
        ref( $data->{users}->{ $author }->{modules} ) eq 'HASH' &&
        exists( $data->{users}->{ $author }->{modules}->{ $package } ) )
    {
        $res = <<EOT;
package ${package};
# This is a fake representation of ${dist}

1;

EOT
    }
    my $code = 200;
    my $type = 'text/plain';
    if( !defined( $res ) )
    {
        $code = 404;
        $res = $self->json->encode({ code => $code, message => 'Not found' });
        $type = 'application/json';
    }
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => $type,
            Content_Length => length( $res ),
            Date => $self->_date_now,
        ], $res,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/source/{author}/{release}/{path}
    # NOTE: sub _PostSourceReleasePath
    *_PostSourceReleasePath = \&_GetSourceReleasePath;
}

# NOTE: GET /v1/source/{module}
sub _GetModuleSource
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    my $form = $req->as_form_data;
    my $vars = $opts->{vars};
    my $package = $vars->{module} ||
        return( $self->error({ code => 400, message => 'Missing parameter: module' }) );
    my $res;
    foreach my $user ( keys( %{$data->{users}} ) )
    {
        if( exists( $data->{users}->{ $user }->{modules} ) &&
            ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' &&
            exists( $data->{users}->{ $user }->{modules}->{ $package } ) )
        {
            my $this = $data->{users}->{ $user }->{modules}->{ $package };
            my $dist = $this->{distribution};
            $res = <<EOT;
package ${package};
# This is a fake representation of ${dist}

1;

EOT
            last;
        }
    }
    my $code = 200;
    my $type = 'text/plain';
    if( !defined( $res ) )
    {
        $code = 404;
        $res = $self->json->encode({ code => $code, message => 'Not found' });
        $type = 'application/json';
    }
    my $resp = HTTP::Promise::Response->new( $code, HTTP::Promise::Status->status_message( $code => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => $type,
            Content_Length => length( $res ),
            Date => $self->_date_now,
        ], $res,
    );
    return( $resp );
}

{
    no warnings 'once';
    # NOTE: POST /v1/source/{module}
    # NOTE: sub _PostModuleSource
    *_PostModuleSource = \&_GetModuleSource;
}

sub _build_recent
{
    my $self = shift( @_ );
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $recent;
    unless( $recent = $self->{_recent} )
    {
        my $fmt = DateTime::Format::Strptime->new(
            # iso8601
            pattern => '%FT%T',
        );
        $recent = {};
        foreach my $user ( keys( %{$data->{users}} ) )
        {
            next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
            foreach my $package ( keys( %{$data->{users}->{ $user }->{modules}} ) )
            {
                my $this = $data->{users}->{ $user }->{modules}->{ $package };
                local $@;
                # try-catch
                eval
                {
                    my $dt = $fmt->parse_datetime( $this->{date} );
                    $recent->{ $dt } = $this;
                };
                if( $@ )
                {
                    warn( "Error parsing module $package date: $@" );
                    next;
                }
            }
        }
        $self->{_recent} = $recent;
    }
    return( $recent );
}

sub _date_now
{
    my $self = shift( @_ );
    # Fri, 18 Aug 2023 01:49:43 GMT
    my $fmt = DateTime::Format::Strptime->new(
        pattern => '%a, %d %b %Y %H:%M:%S GMT',
        locale => 'en_GB',
    );
    my $now = DateTime->now;
    $now->set_formatter( $fmt );
    return( $now );
}

sub _make_changes_from_module
{
    my( $self, $this ) = @_;
    my @keys = qw( author date distribution download_url id maturity version version_numified );
    my $info = 
    {
        binary => \0,
        category => 'changelog',
        content => "Changes file for $this->{package}\n\n$this->{version} 2023-08-15T09:12:17\n\n  - New stuff",
        directory => \0,
        indexed => \0,
        level => 0,
        mime => '',
        module => [],
        name => 'Changes',
        path => 'Changes',
        pod => '',
        pod_lines => [],
        release => join( '-', @$this{qw( distribution version )} ),
        sloc => 487,
        slop => 0,
        stat => 
        {
            mode => 33188,
            mtime => 1690672351,
            size => 35529,
        },
        status => 'latest',
    };
    @$info{ @keys } = @$this{ @keys };
    $info->{authorized} = $info->{authorized} ? \1 : \0;
    $info->{deprecated} = $info->{deprecated} ? \1 : \0;
    return( $info );
}

sub _search
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $def = $opts->{def};
    my $data = $self->data || 
        return( $self->error( "No mock data could be found." ) );
    my $lang = $opts->{lang} || DEFAULT_LANG;
    my $req = $opts->{request} || return( $self->error( "No request object was provided." ) );
    # Including JSON payload, such as:
    # {"query": {"match_all":{}},"filter":{"and":[{"term":{"pauseid":"JOHNDOE"}}]}}
    my $form = $req->as_form_data;
    my $hits = [];
    my $from = $form->{from} // 0;
    my $size = $form->{size} // 10;
    my $type = $opts->{type} || 
        return( $self->error({ code => 500, message => 'Missing "type" parameter for _search method.' }) );
    my $cb = $opts->{callback} || 
        return( $self->error({ code => 500, message => 'Missing "callback" parameter for _search method.' }) );
    my $q;
    if( exists( $opts->{query} ) &&
        defined( $opts->{query} ) &&
        length( $opts->{query} ) )
    {
        $q = $opts->{query};
    }
    elsif( $req->method eq 'POST' && 
        $req->headers->type && 
        $req->headers->type eq 'application/json' )
    {
        # Because this is only a fake interface, what can be queried and how it can be is predetermined.
        $q = $form->{filter}->{and}->[0]->{term}->{pauseid};
    }
    else
    {
        $q = $form->{ 'q' } // '';
    }
    
    my $matches = [];
    my $total;
    if( !length( $q ) )
    {
        if( $type eq 'author' )
        {
            $matches = [values( %{$data->{users}} )];
        }
        else
        {
            foreach my $user ( keys( %{$data->{users}} ) )
            {
                next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
                push( @$matches, map( $data->{users}->{ $user }->{modules}->{ $_ }, keys( %{$data->{users}->{ $user }->{modules}} ) ) );
            }
        }
        # Actual number of CPAN modules
        $total = $opts->{total} // 29178966;
    }
    else
    {
        $self->message( 4, "Query is '$q'" );
        # my $re = qr/$q/;
        my( $prop, $query );
        if( index( $q, ':' ) != -1 )
        {
            ( $prop, $query ) = split( /:/, $q, 2 );
        }
        else
        {
            $query = $q;
        }
        my $re = qr/$query/;
        $self->message( 4, "Using regular expression -> $re" );
        if( $type eq 'author' )
        {
            foreach my $user ( sort( keys( %{$data->{users}} ) ) )
            {
                my $this = $data->{users}->{ $user };
                if( $this->{pauseid} =~ /$re/ ||
                    $this->{name} =~ /$re/ ||
                    $this->{email} =~ /$re/ ||
                    $this->{city} =~ /$re/ )
                {
                    push( @$matches, $this );
                }
            }
        }
        else
        {
            foreach my $user ( sort( keys( %{$data->{users}} ) ) )
            {
                next unless( exists( $data->{users}->{ $user }->{modules} ) && ref( $data->{users}->{ $user }->{modules} ) eq 'HASH' );
                foreach my $package ( sort( keys( %{$data->{users}->{ $user }->{modules}} ) ) )
                {
                    my $this = $data->{users}->{ $user }->{modules}->{ $package };
                    if( defined( $prop ) )
                    {
                        if( $this->{ $prop } =~ /$re/ )
                        {
                            push( @$matches, $this );
                        }
                    }
                    elsif( $this->{abstract} =~ /$re/ ||
                        $this->{author} =~ /$re/ ||
                        $this->{distribution} =~ /$re/ ||
                        $this->{id} =~ /$re/ ||
                        $this->{name} =~ /$re/ ||
                        $this->{package} =~ /$re/ ||
                        ( exists( $this->{provides} ) && ref( $this->{provides} ) eq 'ARRAY' && join( ' ', @{$this->{provides}} ) =~ /$re/ ) )
                    {
                        push( @$matches, $this );
                    }
                }
            }
        }
        $total = scalar( @$matches );
    }
    
    for( my $i = $from; $i < scalar( @$matches ); $i++ )
    {
        my $info = $matches->[$i];
        my $ref = $cb->( $info );
        push( @$hits, $ref );
        last if( scalar( @$hits ) == $size );
    }
    my $res = 
    {
        _shards =>
        {
            failed => 0,
            successful => 3,
            total => 3,
        },
        hits =>
        {
            hits => $hits,
            max_score => 1,
            total => $total,
        },
        timed_out => \0,
        took => 4,
    };
    
    if( $opts->{scroll} )
    {
        $res->{_scroll_id} = 'cXVlcnlUaGVuRmV0Y2g7Mzs0MDE0MzQ1MTQ6N2NvRzNSdklTYkdiRmNPNi04VXFjQTs2NzEwNTc1NTE6OWtIOUE2b2xUaHk3cU5iWkl6ajZrUTsxMDcyNDY5OTMxOk1lZVhCR1J4VG1tT0QxWjRFd2J0Z2c7MDs=';
    }
    
    my $payload = $self->json->utf8->encode( $res );
    my $resp = HTTP::Promise::Response->new( 200, HTTP::Promise::Status->status_message( 200 => $lang ), [
            @STANDARD_HEADERS,
            Content_Type => 'application/json',
            Content_Length => length( $payload ),
            Date => $self->_date_now,
        ], $payload,
    );
    return( $resp );
}

sub DESTROY
{
    my $self = shift( @_ );
    eval
    {
        if( $self->pid )
        {
            $self->stop || die( $self->error );
        }
    };
}

# Make Test::Pod happy
=encoding utf-8

=cut

# NOTE: DATA
# The data below are anonymous data using completely fake names, and e-mail addresses, 
# but real module names with fictitious version number
$DATA = <<'EOT';
{
    alias => {
        PostAuthorMapping => "GetAuthorMapping",
        PostContributorMapping => "GetContributorMapping",
        PostCVE => "GetCVE",
        PostCVEByAuthorRelease => "GetCVEByAuthorRelease",
        PostCVEByCpanID => "GetCVEByCpanID",
        PostCVEByDistribution => "GetCVEByDistribution",
        PostDistributionMapping => "GetDistributionMapping",
        PostFavoriteMapping => "GetFavoriteMapping",
        PostFileMapping => "GetFileMapping",
        PostModuleMapping => "GetModuleMapping",
        PostRatingMapping => "GetRatingMapping",
        PostReleaseMapping => "GetReleaseMapping",
    },
    GetAuthorMapping => {
        cpan_v1_01 => {
            mappings => {
                author => {
                    dynamic => \0,
                    properties => {
                        asciiname => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        blog => {
                            dynamic => \1,
                            properties => {
                                feed => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                url => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                            },
                        },
                        city => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        country => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        donation => {
                            dynamic => \1,
                            properties => {
                                id => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                name => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                            },
                        },
                        email => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        gravatar_url => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        is_pause_custodial_account => { type => "boolean" },
                        location => { type => "geo_point" },
                        name => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        pauseid => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        perlmongers => {
                            dynamic => \1,
                            properties => {
                                name => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                url => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                            },
                        },
                        profile => {
                            dynamic => \0,
                            include_in_root => 1,
                            properties => {
                                id => {
                                    fields => {
                                        analyzed => {
                                            analyzer => "simple",
                                            fielddata => { format => "disabled" },
                                            store => 1,
                                            type => "string",
                                        },
                                    },
                                    ignore_above => 2048,
                                    index => "not_analyzed",
                                    type => "string",
                                },
                                name => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                            },
                            type => "nested",
                        },
                        region => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        updated => { format => "strict_date_optional_time||epoch_millis", type => "date" },
                        user => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        website => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                    },
                },
            },
        },
    },
    GetContributorMapping => {
        cpan_v1_01 => {
            mappings => {
                contributor => {
                    dynamic => "false",
                    properties => {
                        distribution => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        pauseid => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        release_author => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        release_name => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                    },
                },
            },
        },
    },
    GetCVE => {
        _shards => { failed => 0, successful => 3, total => 3 },
        hits => { hits => [], max_score => undef, total => 0 },
        timed_out => 0,
        took => 2,
    },
    GetCVEByAuthorRelease => { cve => [] },
    GetCVEByCpanID => { cve => [] },
    GetCVEByDistribution => { cve => [] },
    GetDistributionMapping => {
        cpan_v1_01 => {
            mappings => {
                distribution => {
                    dynamic => \0,
                    properties => {
                        bugs => {
                            dynamic => \1,
                            properties => {
                                github => {
                                    dynamic => \1,
                                    properties => {
                                        active => { type => "integer" },
                                        closed => { type => "integer" },
                                        open => { type => "integer" },
                                        source => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                    },
                                },
                                rt => {
                                    dynamic => \1,
                                    properties => {
                                        "<html>" => { type => "double" },
                                        active => { type => "integer" },
                                        closed => { type => "integer" },
                                        new => { type => "integer" },
                                        open => { type => "integer" },
                                        patched => { type => "integer" },
                                        rejected => { type => "integer" },
                                        resolved => { type => "integer" },
                                        source => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                        stalled => { type => "integer" },
                                    },
                                },
                            },
                        },
                        external_package => {
                            dynamic => \1,
                            properties => {
                                cygwin => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                debian => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                fedora => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                            },
                        },
                        name => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        river => {
                            dynamic => \1,
                            properties => {
                                bucket => { type => "integer" },
                                bus_factor => { type => "integer" },
                                immediate => { type => "integer" },
                                total => { type => "integer" },
                            },
                        },
                    },
                },
            },
        },
    },
    GetFavoriteMapping => {
        cpan_v1_01 => {
            mappings => {
                favorite => {
                    dynamic => \0,
                    properties => {
                        author => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        date => { format => "strict_date_optional_time||epoch_millis", type => "date" },
                        distribution => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        id => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        release => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        user => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                    },
                },
            },
        },
    },
    GetFileMapping => {
        cpan_v1_01 => {
            mappings => {
                file => {
                    dynamic => \0,
                    properties => {
                        abstract => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        author => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        authorized => { type => "boolean" },
                        binary => { type => "boolean" },
                        date => { format => "strict_date_optional_time||epoch_millis", type => "date" },
                        deprecated => { type => "boolean" },
                        description => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        dir => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        directory => { type => "boolean" },
                        dist_fav_count => { type => "integer" },
                        distribution => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                                camelcase => { analyzer => "camelcase", store => 1, type => "string" },
                                lowercase => { analyzer => "lowercase", store => 1, type => "string" },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        documentation => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                                camelcase => { analyzer => "camelcase", store => 1, type => "string" },
                                edge => { analyzer => "edge", store => 1, type => "string" },
                                edge_camelcase => { analyzer => "edge_camelcase", store => 1, type => "string" },
                                lowercase => { analyzer => "lowercase", store => 1, type => "string" },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        download_url => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        id => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        indexed => { type => "boolean" },
                        level => { type => "integer" },
                        maturity => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        mime => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        module => {
                            dynamic => \0,
                            include_in_root => 1,
                            properties => {
                                associated_pod => { type => "string" },
                                authorized => { type => "boolean" },
                                indexed => { type => "boolean" },
                                name => {
                                    fields => {
                                        analyzed => {
                                            analyzer => "standard",
                                            fielddata => { format => "disabled" },
                                            store => 1,
                                            type => "string",
                                        },
                                        camelcase => { analyzer => "camelcase", store => 1, type => "string" },
                                        lowercase => { analyzer => "lowercase", store => 1, type => "string" },
                                    },
                                    ignore_above => 2048,
                                    index => "not_analyzed",
                                    type => "string",
                                },
                                version => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                version_numified => { type => "float" },
                            },
                            type => "nested",
                        },
                        name => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        path => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        pod => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    term_vector => "with_positions_offsets",
                                    type => "string",
                                },
                            },
                            index => "no",
                            type => "string",
                        },
                        pod_lines => { doc_values => 1, ignore_above => 2048, index => "no", type => "string" },
                        release => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                                camelcase => { analyzer => "camelcase", store => 1, type => "string" },
                                lowercase => { analyzer => "lowercase", store => 1, type => "string" },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        sloc => { type => "integer" },
                        slop => { type => "integer" },
                        stat => {
                            dynamic => \1,
                            properties => {
                                gid => { type => "long" },
                                mode => { type => "integer" },
                                mtime => { type => "integer" },
                                size => { type => "integer" },
                                uid => { type => "long" },
                            },
                        },
                        status => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        suggest => {
                            analyzer => "simple",
                            max_input_length => 50,
                            payloads => 1,
                            preserve_position_increments => 1,
                            preserve_separators => 1,
                            type => "completion",
                        },
                        version => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        version_numified => { type => "float" },
                    },
                },
            },
        },
    },
    GetModuleMapping => {
        cpan_v1_01 => {
            mappings => {
                file => {
                    dynamic => \0,
                    properties => {
                        abstract => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        author => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        authorized => { type => "boolean" },
                        binary => { type => "boolean" },
                        date => { format => "strict_date_optional_time||epoch_millis", type => "date" },
                        deprecated => { type => "boolean" },
                        description => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        dir => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        directory => { type => "boolean" },
                        dist_fav_count => { type => "integer" },
                        distribution => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                                camelcase => { analyzer => "camelcase", store => 1, type => "string" },
                                lowercase => { analyzer => "lowercase", store => 1, type => "string" },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        documentation => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                                camelcase => { analyzer => "camelcase", store => 1, type => "string" },
                                edge => { analyzer => "edge", store => 1, type => "string" },
                                edge_camelcase => { analyzer => "edge_camelcase", store => 1, type => "string" },
                                lowercase => { analyzer => "lowercase", store => 1, type => "string" },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        download_url => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        id => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        indexed => { type => "boolean" },
                        level => { type => "integer" },
                        maturity => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        mime => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        module => {
                            dynamic => \0,
                            include_in_root => 1,
                            properties => {
                                associated_pod => { type => "string" },
                                authorized => { type => "boolean" },
                                indexed => { type => "boolean" },
                                name => {
                                    fields => {
                                        analyzed => {
                                            analyzer => "standard",
                                            fielddata => { format => "disabled" },
                                            store => 1,
                                            type => "string",
                                        },
                                        camelcase => { analyzer => "camelcase", store => 1, type => "string" },
                                        lowercase => { analyzer => "lowercase", store => 1, type => "string" },
                                    },
                                    ignore_above => 2048,
                                    index => "not_analyzed",
                                    type => "string",
                                },
                                version => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                version_numified => { type => "float" },
                            },
                            type => "nested",
                        },
                        name => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        path => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        pod => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    term_vector => "with_positions_offsets",
                                    type => "string",
                                },
                            },
                            index => "no",
                            type => "string",
                        },
                        pod_lines => { doc_values => 1, ignore_above => 2048, index => "no", type => "string" },
                        release => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                                camelcase => { analyzer => "camelcase", store => 1, type => "string" },
                                lowercase => { analyzer => "lowercase", store => 1, type => "string" },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        sloc => { type => "integer" },
                        slop => { type => "integer" },
                        stat => {
                            dynamic => \1,
                            properties => {
                                gid => { type => "long" },
                                mode => { type => "integer" },
                                mtime => { type => "integer" },
                                size => { type => "integer" },
                                uid => { type => "long" },
                            },
                        },
                        status => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        suggest => {
                            analyzer => "simple",
                            max_input_length => 50,
                            payloads => 1,
                            preserve_position_increments => 1,
                            preserve_separators => 1,
                            type => "completion",
                        },
                        version => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        version_numified => { type => "float" },
                    },
                },
            },
        },
    },
    GetRatingMapping => {
        cpan_v1_01 => {
            mappings => {
                rating => {
                    dynamic => \0,
                    properties => {
                        author => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        date => { format => "strict_date_optional_time||epoch_millis", type => "date" },
                        details => {
                            dynamic => \0,
                            properties => {
                                documentation => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                            },
                        },
                        distribution => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        helpful => {
                            dynamic => \0,
                            properties => {
                                user => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                value => { type => "boolean" },
                            },
                        },
                        rating => { type => "float" },
                        release => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        user => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                    },
                },
            },
        },
    },
    GetReleaseMapping => {
        cpan_v1_01 => {
            mappings => {
                release => {
                    dynamic => \0,
                    properties => {
                        abstract => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        archive => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        author => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        authorized => { type => "boolean" },
                        changes_file => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        checksum_md5 => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        checksum_sha256 => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        date => { format => "strict_date_optional_time||epoch_millis", type => "date" },
                        dependency => {
                            dynamic => \0,
                            include_in_root => 1,
                            properties => {
                                module => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                phase => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                relationship => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                version => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                            },
                            type => "nested",
                        },
                        deprecated => { type => "boolean" },
                        distribution => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                                camelcase => { analyzer => "camelcase", store => 1, type => "string" },
                                lowercase => { analyzer => "lowercase", store => 1, type => "string" },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        download_url => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        first => { type => "boolean" },
                        id => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        license => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        main_module => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        maturity => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        name => {
                            fields => {
                                analyzed => {
                                    analyzer => "standard",
                                    fielddata => { format => "disabled" },
                                    store => 1,
                                    type => "string",
                                },
                                camelcase => { analyzer => "camelcase", store => 1, type => "string" },
                                lowercase => { analyzer => "lowercase", store => 1, type => "string" },
                            },
                            ignore_above => 2048,
                            index => "not_analyzed",
                            type => "string",
                        },
                        provides => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        resources => {
                            dynamic => \1,
                            include_in_root => 1,
                            properties => {
                                bugtracker => {
                                    dynamic => \1,
                                    include_in_root => 1,
                                    properties => {
                                        mailto => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                        web => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                    },
                                    type => "nested",
                                },
                                homepage => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                license => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                repository => {
                                    dynamic => \1,
                                    include_in_root => 1,
                                    properties => {
                                        type => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                        url => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                        web => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                                    },
                                    type => "nested",
                                },
                            },
                            type => "nested",
                        },
                        stat => {
                            dynamic => \1,
                            properties => {
                                gid => { type => "long" },
                                mode => { type => "integer" },
                                mtime => { type => "integer" },
                                size => { type => "integer" },
                                uid => { type => "long" },
                            },
                        },
                        status => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        tests => {
                            dynamic => \1,
                            properties => {
                                fail => { type => "integer" },
                                na => { type => "integer" },
                                pass => { type => "integer" },
                                unknown => { type => "integer" },
                            },
                        },
                        version => { ignore_above => 2048, index => "not_analyzed", type => "string" },
                        version_numified => { type => "float" },
                    },
                },
            },
        },
    },
    users => {
        AFONASEIANTONOV => {
            asciiname => "Afonasei Antonov",
            city => "Moscow",
            contributions => [
                {
                    distribution => "Dist-Zilla-Plugin-ProgCriticTests",
                    pauseid => "AFONASEIANTONOV",
                    release_author => "RACHELSEGAL",
                    release_name => "Dist-Zilla-Plugin-ProgCriticTests-v1.48.19",
                },
            ],
            country => "RU",
            email => ["afonasei.antonov\@example.ru"],
            favorites => [
                {
                    author => "LILLIANSTEWART",
                    date => "2010-03-06T13:55:15",
                    distribution => "Task-Dancer",
                },
                {
                    author => "ALEXANDRAPOWELL",
                    date => "2006-09-07T17:59:00",
                    distribution => "Geo-Postcodes",
                },
                {
                    author => "TEDDYSAPUTRA",
                    date => "2005-10-23T16:25:35",
                    distribution => "Math-Symbolic-Custom-Pattern",
                },
                {
                    author => "RANGSANSUNTHORN",
                    date => "2002-05-06T12:31:19",
                    distribution => "Giza",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/YcD1vpcPaRrCCXfhehNnAkmTeyqgFqUt?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/A/AF/AFONASEIANTONOV",
                cpan_directory => "http://cpan.org/authors/id/A/AF/AFONASEIANTONOV",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=AFONASEIANTONOV",
                cpantesters_reports => "http://cpantesters.org/author/A/AFONASEIANTONOV.html",
                cpants => "http://cpants.cpanauthors.org/author/AFONASEIANTONOV",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/AFONASEIANTONOV",
                repology => "https://repology.org/maintainer/AFONASEIANTONOV%40cpan",
            },
            modules => {
                "Apache::XPointer" => {
                    abstract => "mod_perl handler to address XML fragments.",
                    archive => "Apache-XPointer-2.18.tar.gz",
                    author => "AFONASEIANTONOV",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "b0da0635221cf4c9f8cd398774d50012",
                    checksum_sha256 => "15874f970468e44a461432878237a67e6547dde43155dfb3c9a6e24911f88bc4",
                    contributors => [qw( HELEWISEGIROUX BUDAEJUNG DOHYUNNCHOI )],
                    date => "2004-11-13T23:40:57",
                    dependency => [
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => "v5.6.0",
                        },
                        {
                            module => "mod_perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.29,
                        },
                        {
                            module => "XML::LibXML",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.58,
                        },
                        {
                            module => "XML::LibXML::XPathContext",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.06,
                        },
                        {
                            module => "Test::Simple",
                            phase => "build",
                            relationship => "requires",
                            version => 0.47,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Apache-XPointer",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AF/AFONASEIANTONOV/Apache-XPointer-2.18.tar.gz",
                    first => 1,
                    id => "3yKx3djv3Bfh96NwXgDHBeD7b_c",
                    license => ["perl_5"],
                    likers => [qw( ALEXANDRAPOWELL TAKASHIISHIKAWA )],
                    likes => 2,
                    main_module => "Apache::XPointer",
                    maturity => "released",
                    metadata => {
                        abstract => "mod_perl handler to address XML fragments.",
                        author => ["Aaron Straup Cope E<lt>ascope\@cpan.orgE<gt>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.25_02, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Apache-XPointer",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::Simple" => 0.47 },
                            },
                            runtime => {
                                requires => {
                                    mod_perl => 1.29,
                                    perl => "v5.6.0",
                                    "XML::LibXML" => 1.58,
                                    "XML::LibXML::XPathContext" => 0.06,
                                },
                            },
                        },
                        provides => {
                            "Apache::XPointer" => { file => "lib/Apache/XPointer.pm", version => "1.0" },
                            "Apache::XPointer::XPath" => { file => "lib/Apache/XPointer/XPath.pm", version => "1.0" },
                        },
                        release_status => "stable",
                        version => "1.0",
                    },
                    name => "Apache-XPointer",
                    package => "Apache::XPointer",
                    provides => [qw( Apache::XPointer Apache::XPointer::XPath )],
                    release => "Apache-XPointer-2.18",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1100389257, size => 5414, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "x2i7nBeZY4kM0BlRn4gnwV",
                    version => 2.18,
                    version_numified => "2.180",
                },
                "Crypt::OpenSSL::CA" => {
                    abstract => "The crypto parts of an X509v3 Certification Authority",
                    archive => "Crypt-OpenSSL-CA-1.95.tar.gz",
                    author => "AFONASEIANTONOV",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "7b95cd2f52d7e218f55fede4ad3042d4",
                    checksum_sha256 => "f775bf9cc6f9f9ba6b56915692b8d6f3b4d2746dac166f76561238decb0d61fa",
                    contributors => ["ENGYONGCHANG"],
                    date => "2010-08-27T18:07:51",
                    dependency => [
                        {
                            module => "Module::Build",
                            phase => "configure",
                            relationship => "requires",
                            version => 0.36,
                        },
                        {
                            module => "Convert::ASN1",
                            phase => "build",
                            relationship => "requires",
                            version => 0.2,
                        },
                        {
                            module => "FindBin",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "IO::File",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Inline::C",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "POSIX",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "MIME::Base64",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Module::Build::Compat",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Net::SSLeay",
                            phase => "build",
                            relationship => "requires",
                            version => 1.25,
                        },
                        {
                            module => "File::Slurp",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Devel::Mallinfo",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Module::Build",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "IPC::Run",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Devel::Leak",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Fatal",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::Group",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Temp",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::Builder",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Spec::Unix",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Find",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Path",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Spec",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Inline",
                            phase => "build",
                            relationship => "requires",
                            version => 0.4,
                        },
                        {
                            module => "File::Spec::Functions",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "XSLoader",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Crypt-OpenSSL-CA",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AF/AFONASEIANTONOV/Crypt-OpenSSL-CA-1.95.tar.gz",
                    first => 0,
                    id => "ZPGq3kgIFKLCcyCzky1AILW2UQk",
                    license => ["perl_5"],
                    likers => ["RANGSANSUNTHORN"],
                    likes => 1,
                    main_module => "Crypt::OpenSSL::CA",
                    maturity => "released",
                    metadata => {
                        abstract => "The crypto parts of an X509v3 Certification Authority",
                        author => ["Dominique Quatravaux <domq\@cpan.org>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.3603, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Crypt-OpenSSL-CA",
                        no_index => {
                            directory => [qw(
                                examples inc t lib/Crypt/OpenSSL/CA/Inline t xt inc
                                local perl5 fatlib example blib examples eg
                            )],
                            namespace => ["Crypt::OpenSSL::CA::Inline"],
                        },
                        prereqs => {
                            build => {
                                requires => {
                                    "Convert::ASN1" => 0.2,
                                    "Devel::Leak" => 0,
                                    "Devel::Mallinfo" => 0,
                                    Fatal => 0,
                                    "File::Find" => 0,
                                    "File::Path" => 0,
                                    "File::Slurp" => 0,
                                    "File::Spec" => 0,
                                    "File::Spec::Functions" => 0,
                                    "File::Spec::Unix" => 0,
                                    "File::Temp" => 0,
                                    FindBin => 0,
                                    Inline => 0.4,
                                    "Inline::C" => 0,
                                    "IO::File" => 0,
                                    "IPC::Run" => 0,
                                    "MIME::Base64" => 0,
                                    "Module::Build" => 0,
                                    "Module::Build::Compat" => 0,
                                    "Net::SSLeay" => 1.25,
                                    POSIX => 0,
                                    "Test::Builder" => 0,
                                    "Test::Group" => 0,
                                    "Test::More" => 0,
                                },
                            },
                            configure => {
                                requires => { "Module::Build" => 0.36 },
                            },
                            runtime => {
                                requires => { XSLoader => 0 },
                            },
                        },
                        provides => {
                            "Crypt::OpenSSL::CA" => { file => "lib/Crypt/OpenSSL/CA.pm", version => "0.20" },
                            "Crypt::OpenSSL::CA::CONF" => { file => "lib/Crypt/OpenSSL/CA.pm" },
                            "Crypt::OpenSSL::CA::ENGINE" => { file => "lib/Crypt/OpenSSL/CA.pm" },
                            "Crypt::OpenSSL::CA::Error" => { file => "lib/Crypt/OpenSSL/CA.pm" },
                            "Crypt::OpenSSL::CA::PrivateKey" => { file => "lib/Crypt/OpenSSL/CA.pm" },
                            "Crypt::OpenSSL::CA::PublicKey" => { file => "lib/Crypt/OpenSSL/CA.pm" },
                            "Crypt::OpenSSL::CA::X509" => { file => "lib/Crypt/OpenSSL/CA.pm" },
                            "Crypt::OpenSSL::CA::X509_CRL" => { file => "lib/Crypt/OpenSSL/CA.pm" },
                            "Crypt::OpenSSL::CA::X509_NAME" => { file => "lib/Crypt/OpenSSL/CA.pm" },
                            "Crypt::OpenSSL::CA::X509V3_EXT" => { file => "lib/Crypt/OpenSSL/CA.pm" },
                        },
                        release_status => "stable",
                        resources => { license => ["http://dev.perl.org/licenses/"] },
                        version => "0.20",
                    },
                    name => "Crypt-OpenSSL-CA",
                    package => "Crypt::OpenSSL::CA",
                    provides => [qw(
                        Crypt::OpenSSL::CA Crypt::OpenSSL::CA::CONF
                        Crypt::OpenSSL::CA::ENGINE Crypt::OpenSSL::CA::Error
                        Crypt::OpenSSL::CA::PrivateKey
                        Crypt::OpenSSL::CA::PublicKey Crypt::OpenSSL::CA::X509
                        Crypt::OpenSSL::CA::X509V3_EXT
                        Crypt::OpenSSL::CA::X509_CRL
                        Crypt::OpenSSL::CA::X509_NAME
                    )],
                    release => "Crypt-OpenSSL-CA-1.95",
                    resources => { license => ["http://dev.perl.org/licenses/"] },
                    stat => { gid => 1009, mode => 33204, mtime => 1282932471, size => 140587, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 4, na => 1, pass => 43, unknown => 0 },
                    user => "x2i7nBeZY4kM0BlRn4gnwV",
                    version => 1.95,
                    version_numified => "1.950",
                },
                "FileHandle::Rollback" => {
                    abstract => "FileHandle with commit, rollback, and journaled crash recovery",
                    archive => "FileHandle-Rollback-v0.88.10.tar.gz",
                    author => "AFONASEIANTONOV",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "68632720c04ff224218883327adc703e",
                    checksum_sha256 => "c79ee1342e20b03c96597a80303f7f2d47d7ba1deee578873f05f8cae63c6952",
                    contributors => [qw( FLORABARRETT ENGYONGCHANG )],
                    date => "2003-07-15T07:20:16",
                    dependency => [],
                    deprecated => 0,
                    distribution => "FileHandle-Rollback",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AF/AFONASEIANTONOV/FileHandle-Rollback-v0.88.10.tar.gz",
                    first => 0,
                    id => "3UPI46zJ5EwKd91k6UrSWoV9Hw0",
                    license => ["unknown"],
                    likers => [qw( ALEXANDRAPOWELL SIEUNJANG )],
                    likes => 2,
                    main_module => "FileHandle::Rollback",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "FileHandle-Rollback",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 1.05,
                    },
                    name => "FileHandle-Rollback",
                    package => "FileHandle::Rollback",
                    provides => [qw( FileHandle::Rollback FileHandle::Rollback::Tie )],
                    release => "FileHandle-Rollback-v0.88.10",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1058253616, size => 7423, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 5, unknown => 0 },
                    user => "x2i7nBeZY4kM0BlRn4gnwV",
                    version => "v0.88.10",
                    version_numified => "0.088010",
                },
                "Net::FullAuto" => {
                    abstract => "Perl Based Secure Distributed Computing Network Process",
                    archive => "Net-FullAuto-v1.50.2.tar.gz",
                    author => "AFONASEIANTONOV",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "49236a7f12591fec39a45a52df7d0aeb",
                    checksum_sha256 => "6a72dd173cfaf511f48433a43159a12ea6564ba7dd7133fbfd3c067b8ab63400",
                    contributors => [qw( ANTHONYGOYETTE DUANLIN )],
                    date => "2010-07-29T21:19:56",
                    dependency => [
                        {
                            module => "Crypt::Rijndael",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 0,
                        },
                        {
                            module => "IO::Pty",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "MLDBM",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "LWP",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Crypt::CBC",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Mail::Internet",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Crypt::DES",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Tie::Cache",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Getopt::Long",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "MLDBM::Sync",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "MLDBM::Sync::SDBM_File",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Term::Menus",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.24,
                        },
                        {
                            module => "Sort::Versions",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "HTTP::Date",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "MemHandle",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Mail::Sender",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "URI",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Net::Telnet",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Net-FullAuto",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AF/AFONASEIANTONOV/Net-FullAuto-v1.50.2.tar.gz",
                    first => 0,
                    id => "KYVzKhXLw03_QLMD7KosypZPyNc",
                    license => ["open_source"],
                    likers => [],
                    likes => 0,
                    main_module => "Net::FullAuto",
                    maturity => "released",
                    metadata => {
                        abstract => "Perl Based Secure Distributed Computing Network Process",
                        author => ["Brian M. Kelly <Brian.Kelly\@fullautosoftware.net>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.280802, CPAN::Meta::Converter version 2.150005",
                        license => ["open_source"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Net-FullAuto",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                recommends => { "Crypt::Rijndael" => 0 },
                                requires => {
                                    "Crypt::CBC" => 0,
                                    "Crypt::DES" => 0,
                                    "Getopt::Long" => 0,
                                    "HTTP::Date" => 0,
                                    "IO::Pty" => 0,
                                    LWP => 0,
                                    "Mail::Internet" => 0,
                                    "Mail::Sender" => 0,
                                    MemHandle => 0,
                                    MLDBM => 0,
                                    "MLDBM::Sync" => 0,
                                    "MLDBM::Sync::SDBM_File" => 0,
                                    "Net::Telnet" => 0,
                                    "Sort::Versions" => 0,
                                    "Term::Menus" => 1.24,
                                    "Tie::Cache" => 0,
                                    URI => 0,
                                },
                            },
                        },
                        provides => {
                            fa_hosts => { file => "lib/Net/FullAuto/fa_hosts.pm", version => 1 },
                            fa_maps => { file => "lib/Net/FullAuto/fa_maps.pm", version => 1 },
                            File_Transfer => { file => "lib/Net/FullAuto/FA_lib.pm" },
                            menu_cfg => { file => "lib/Net/FullAuto/menu_cfg.pm", version => 1 },
                            "Net::FullAuto" => { file => "lib/Net/FullAuto.pm", version => 0.12 },
                            "Net::FullAuto::FA_DB" => { file => "lib/Net/FullAuto/FA_lib.pm" },
                            "Net::FullAuto::FA_lib" => { file => "lib/Net/FullAuto/FA_lib.pm" },
                            "Net::FullAuto::Getline" => { file => "lib/Net/FullAuto/FA_lib.pm" },
                            "Net::FullAuto::MemoryHandle" => { file => "lib/Net/FullAuto/FA_lib.pm" },
                            Rem_Command => { file => "lib/Net/FullAuto/FA_lib.pm" },
                            usr_code => { file => "lib/Net/FullAuto/usr_code.pm", version => 1 },
                        },
                        release_status => "stable",
                        resources => { license => ["http://opensource.org/licenses/gpl-license.php"] },
                        version => 0.12,
                    },
                    name => "Net-FullAuto",
                    package => "Net::FullAuto",
                    provides => [qw(
                        File_Transfer Net::FullAuto Net::FullAuto::FA_DB
                        Net::FullAuto::FA_lib Net::FullAuto::Getline
                        Net::FullAuto::MemoryHandle Rem_Command fa_hosts fa_maps
                        menu_cfg usr_code
                    )],
                    release => "Net-FullAuto-v1.50.2",
                    resources => { license => ["http://opensource.org/licenses/gpl-license.php"] },
                    stat => { gid => 1009, mode => 33204, mtime => 1280438396, size => 174763, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 12, na => 0, pass => 20, unknown => 0 },
                    user => "x2i7nBeZY4kM0BlRn4gnwV",
                    version => "v1.50.2",
                    version_numified => 1.050002,
                },
            },
            name => "Afonasei Antonov",
            pauseid => "AFONASEIANTONOV",
            profile => [{ id => 846886, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "x2i7nBeZY4kM0BlRn4gnwV",
        },
        ALESSANDROBAUMANN => {
            asciiname => "Alessandro Baumann",
            city => "Winterthur",
            contributions => [
                {
                    distribution => "XML-Atom-SimpleFeed",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "OLGABOGDANOVA",
                    release_name => "XML-Atom-SimpleFeed-v0.16.11",
                },
                {
                    distribution => "Text-PDF-API",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "ANTHONYGOYETTE",
                    release_name => "Text-PDF-API-v1.9.0",
                },
                {
                    distribution => "CGI-DataObjectMapper",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "DOHYUNNCHOI",
                    release_name => "CGI-DataObjectMapper-0.37",
                },
                {
                    distribution => "Math-Symbolic-Custom-Transformation",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "TAKAONAKANISHI",
                    release_name => "Math-Symbolic-Custom-Transformation-v1.64.5",
                },
                {
                    distribution => "App-Hachero",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "MARINAHOTZ",
                    release_name => "App-Hachero-2.49",
                },
                {
                    distribution => "PAR-Dist-InstallPPD-GUI",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "ELAINAREYES",
                    release_name => "PAR-Dist-InstallPPD-GUI-2.42",
                },
                {
                    distribution => "Text-Match-FastAlternatives",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "OLGABOGDANOVA",
                    release_name => "Text-Match-FastAlternatives-v1.88.18",
                },
                {
                    distribution => "WWW-TinySong",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "TAKAONAKANISHI",
                    release_name => "WWW-TinySong-0.24",
                },
                {
                    distribution => "Math-Symbolic-Custom-Pattern",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "TEDDYSAPUTRA",
                    release_name => "Math-Symbolic-Custom-Pattern-v1.68.6",
                },
                {
                    distribution => "Geo-Postcodes-DK",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "WEEWANG",
                    release_name => "Geo-Postcodes-DK-2.13",
                },
                {
                    distribution => "Text-Match-FastAlternatives",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "OLGABOGDANOVA",
                    release_name => "Text-Match-FastAlternatives-v1.88.18",
                },
                {
                    distribution => "Validator-Custom-HTMLForm",
                    pauseid => "ALESSANDROBAUMANN",
                    release_author => "TAKAONAKANISHI",
                    release_name => "Validator-Custom-HTMLForm-v0.40.0",
                },
            ],
            country => "CH",
            email => ["alessandro.baumann\@example.ch"],
            favorites => [
                {
                    author => "ANTHONYGOYETTE",
                    date => "2005-04-24T02:23:29",
                    distribution => "Catalyst-Plugin-XMLRPC",
                },
                {
                    author => "HEHERSONDEGUZMAN",
                    date => "2005-12-10T19:27:19",
                    distribution => "Task-App-Physics-ParticleMotion",
                },
                {
                    author => "HEHERSONDEGUZMAN",
                    date => "2006-06-22T18:12:35",
                    distribution => "Net-Lite-FTP",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/TxAmCyDsMKGVjqIIrMkI7x46Fl1E7gxt?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/A/AL/ALESSANDROBAUMANN",
                cpan_directory => "http://cpan.org/authors/id/A/AL/ALESSANDROBAUMANN",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=ALESSANDROBAUMANN",
                cpantesters_reports => "http://cpantesters.org/author/A/ALESSANDROBAUMANN.html",
                cpants => "http://cpants.cpanauthors.org/author/ALESSANDROBAUMANN",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/ALESSANDROBAUMANN",
                repology => "https://repology.org/maintainer/ALESSANDROBAUMANN%40cpan",
            },
            name => "Alessandro Baumann",
            pauseid => "ALESSANDROBAUMANN",
            profile => [{ id => 911170, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "Zzaufga4vK7mRuJ0bs31aT",
        },
        ALEXANDRAPOWELL => {
            asciiname => "Alexandra Powell",
            city => "Gibraltar",
            contributions => [
                {
                    distribution => "China-IdentityCard-Validate",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "CHRISTIANREYES",
                    release_name => "China-IdentityCard-Validate-v2.71.3",
                },
                {
                    distribution => "Text-Match-FastAlternatives",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "OLGABOGDANOVA",
                    release_name => "Text-Match-FastAlternatives-v1.88.18",
                },
                {
                    distribution => "Devel-SmallProf",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "Devel-SmallProf-v2.41.7",
                },
                {
                    distribution => "CGI-DataObjectMapper",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "DOHYUNNCHOI",
                    release_name => "CGI-DataObjectMapper-0.37",
                },
                {
                    distribution => "Compress-Bzip2",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "DOHYUNNCHOI",
                    release_name => "Compress-Bzip2-v2.0.11",
                },
                {
                    distribution => "math-image",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "SAMANDERSON",
                    release_name => "math-image-v2.97.1",
                },
                {
                    distribution => "Date-EzDate",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "FLORABARRETT",
                    release_name => "Date-EzDate-0.51",
                },
                {
                    distribution => "Tie-DB_File-SplitHash",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "YOICHIFUJITA",
                    release_name => "Tie-DB_File-SplitHash-v2.4.14",
                },
                {
                    distribution => "DBIx-Custom",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "ELAINAREYES",
                    release_name => "DBIx-Custom-2.37",
                },
                {
                    distribution => "giza",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "giza-0.35",
                },
                {
                    distribution => "Bundle-Catalyst",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Bundle-Catalyst-2.58",
                },
                {
                    distribution => "XML-Parser",
                    pauseid => "ALEXANDRAPOWELL",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "XML-Parser-2.78",
                },
            ],
            country => "UK",
            email => ["alexandra.powell\@example.uk"],
            favorites => [
                {
                    author => "WANTAN",
                    date => "2001-12-14T00:00:58",
                    distribution => "PDF-API2",
                },
                {
                    author => "AFONASEIANTONOV",
                    date => "2003-07-15T07:20:16",
                    distribution => "FileHandle-Rollback",
                },
                {
                    author => "TAKAONAKANISHI",
                    date => "2010-09-13T20:17:31",
                    distribution => "DBIx-Class-Relationship-Predicate",
                },
                {
                    author => "AFONASEIANTONOV",
                    date => "2004-11-13T23:40:57",
                    distribution => "Apache-XPointer",
                },
                {
                    author => "FLORABARRETT",
                    date => "2010-01-16T14:51:11",
                    distribution => "Validator-Custom-Ext-Mojolicious",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/EccugzASltZqv3PjB4YCHCmhVfzEuMPN?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/A/AL/ALEXANDRAPOWELL",
                cpan_directory => "http://cpan.org/authors/id/A/AL/ALEXANDRAPOWELL",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=ALEXANDRAPOWELL",
                cpantesters_reports => "http://cpantesters.org/author/A/ALEXANDRAPOWELL.html",
                cpants => "http://cpants.cpanauthors.org/author/ALEXANDRAPOWELL",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/ALEXANDRAPOWELL",
                repology => "https://repology.org/maintainer/ALEXANDRAPOWELL%40cpan",
            },
            modules => {
                "Bundle::Catalyst" => {
                    abstract => "All you need to start with Catalyst",
                    archive => "Bundle-Catalyst-2.58.tar.gz",
                    author => "ALEXANDRAPOWELL",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "db4995e7cac18df83a9127387ec9785c",
                    checksum_sha256 => "3efe358deba87359a996bbdcad4bf6cba06b10ed23c5070b90d4da80f1b23eab",
                    contributors => [qw(
                        ALEXANDRAPOWELL YOICHIFUJITA TAKAONAKANISHI
                        TAKAONAKANISHI ELAINAREYES MINSUNGJUNG
                    )],
                    date => "2005-11-19T20:19:20",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Bundle-Catalyst",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AL/ALEXANDRAPOWELL/Bundle-Catalyst-2.58.tar.gz",
                    first => 0,
                    id => "vo5KBBiRoL8J6WvIrBWRxxQDDF0",
                    license => ["unknown"],
                    likers => [qw( ENGYONGCHANG ELAINAREYES )],
                    likes => 2,
                    main_module => "Bundle::Catalyst",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.30, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Bundle-Catalyst",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.05,
                        x_installdirs => "site",
                        x_version_from => "Catalyst.pm",
                    },
                    name => "Bundle-Catalyst",
                    package => "Bundle::Catalyst",
                    provides => ["Bundle::Catalyst"],
                    release => "Bundle-Catalyst-2.58",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1132431560, size => 1648, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "xpCq7x1SitBhMrBdewVWXO",
                    version => 2.58,
                    version_numified => "2.580",
                },
                "Geo::Postcodes" => {
                    abstract => "Base class for the Geo::Postcodes::XX modules",
                    archive => "Geo-Postcodes-1.90.tar.gz",
                    author => "ALEXANDRAPOWELL",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "0423a0f3983554c9b935b71155e5978c",
                    checksum_sha256 => "1be050687d785217cb8f10fe865edc35225171a870cc3f84a04a7a285df112f0",
                    date => "2006-09-07T17:59:00",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Geo-Postcodes",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AL/ALEXANDRAPOWELL/Geo-Postcodes-1.90.tar.gz",
                    first => 0,
                    id => "JOuF6NNYRFnVJcEhQUJ4ZEWkoek",
                    license => ["unknown"],
                    likers => [qw( AFONASEIANTONOV ANTHONYGOYETTE )],
                    likes => 2,
                    main_module => "Geo::Postcodes",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.30, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Geo-Postcodes",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.21,
                        x_installdirs => "site",
                        x_version_from => "Postcodes.pm",
                    },
                    name => "Geo-Postcodes",
                    package => "Geo::Postcodes",
                    provides => [qw( Geo::Postcodes Geo::Postcodes::Update )],
                    release => "Geo-Postcodes-1.90",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1157651940, size => 11976, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 2, na => 0, pass => 1, unknown => 0 },
                    user => "xpCq7x1SitBhMrBdewVWXO",
                    version => "1.90",
                    version_numified => "1.900",
                },
                "Server::Control" => {
                    abstract => "Flexible apachectl style control for servers",
                    archive => "Server-Control-0.24.tar.gz",
                    author => "ALEXANDRAPOWELL",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "1a5572b693c25ce28f3a7070174087b6",
                    checksum_sha256 => "dd7091bae7d4245aaf029771fc946a5027ac03a3e6eb73f206179b79a8325f86",
                    contributors => [qw( WEEWANG KANTSOMSRISATI BUDAEJUNG MARINAHOTZ )],
                    date => "2009-09-11T23:24:21",
                    dependency => [
                        {
                            module => "Capture::Tiny",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Net::Server",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "POSIX",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Getopt::Long",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::Log::Dispatch",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Path",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 6.42,
                        },
                        {
                            module => "Test::Most",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::Class",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Guard",
                            phase => "build",
                            relationship => "requires",
                            version => 0.5,
                        },
                        {
                            module => "HTTP::Server::Simple",
                            phase => "build",
                            relationship => "requires",
                            version => 0.28,
                        },
                        {
                            module => "Unix::Lsof",
                            phase => "runtime",
                            relationship => "recommends",
                            version => "v0.0.9",
                        },
                        {
                            module => "Pod::Usage",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Temp",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Moose",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.66,
                        },
                        {
                            module => "IO::Socket",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Apache::ConfigParser",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.01,
                        },
                        {
                            module => "File::Which",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Proc::ProcessTable",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.42,
                        },
                        {
                            module => "Hash::MoreUtils",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Spec::Functions",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Slurp",
                            phase => "runtime",
                            relationship => "requires",
                            version => 9999.13,
                        },
                        {
                            module => "Time::HiRes",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Log::Any::Adapter::Dispatch",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.03,
                        },
                        {
                            module => "IPC::System::Simple",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.18,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => "v5.6.0",
                        },
                        {
                            module => "List::MoreUtils",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.13,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 6.42,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Server-Control",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AL/ALEXANDRAPOWELL/Server-Control-0.24.tar.gz",
                    first => 0,
                    id => "YV6pMxbACWlbab5U7RJzL54ZRQQ",
                    license => ["perl_5"],
                    likers => [qw( TAKASHIISHIKAWA ANTHONYGOYETTE )],
                    likes => 2,
                    main_module => "Server::Control",
                    maturity => "released",
                    metadata => {
                        abstract => "Flexible apachectl style control for servers",
                        author => ["Jonathan Swartz <swartz\@pobox.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.91, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Server-Control",
                        no_index => {
                            directory => [qw(
                                inc lib/Server/Control/t t xt t xt inc local perl5
                                fatlib example blib examples eg
                            )],
                            package => ["Server::Control::Util"],
                        },
                        prereqs => {
                            build => {
                                requires => {
                                    "Capture::Tiny" => 0,
                                    "ExtUtils::MakeMaker" => 6.42,
                                    "File::Path" => 0,
                                    "Getopt::Long" => 0,
                                    Guard => 0.5,
                                    "HTTP::Server::Simple" => 0.28,
                                    "Net::Server" => 0,
                                    POSIX => 0,
                                    "Test::Class" => 0,
                                    "Test::Log::Dispatch" => 0,
                                    "Test::Most" => 0,
                                },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 6.42 },
                            },
                            runtime => {
                                recommends => { "Unix::Lsof" => "v0.0.9" },
                                requires => {
                                    "Apache::ConfigParser" => 1.01,
                                    "File::Slurp" => 9999.13,
                                    "File::Spec::Functions" => 0,
                                    "File::Temp" => 0,
                                    "File::Which" => 0,
                                    "Hash::MoreUtils" => 0,
                                    "IO::Socket" => 0,
                                    "IPC::System::Simple" => 1.18,
                                    "List::MoreUtils" => 0.13,
                                    "Log::Any::Adapter::Dispatch" => 0.03,
                                    Moose => 0.66,
                                    perl => "v5.6.0",
                                    "Pod::Usage" => 0,
                                    "Proc::ProcessTable" => 0.42,
                                    "Time::HiRes" => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        resources => { license => ["http://dev.perl.org/licenses/"] },
                        version => 0.05,
                    },
                    name => "Server-Control",
                    package => "Server::Control",
                    provides => [qw(
                        Server::Control Server::Control::Apache
                        Server::Control::HTTPServerSimple
                        Server::Control::NetServer
                    )],
                    release => "Server-Control-0.24",
                    resources => { license => ["http://dev.perl.org/licenses/"] },
                    stat => { gid => 1009, mode => 33204, mtime => 1252711461, size => 37972, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 2, na => 0, pass => 2, unknown => 0 },
                    user => "xpCq7x1SitBhMrBdewVWXO",
                    version => 0.24,
                    version_numified => "0.240",
                },
                "Tk::ForDummies::Graph" => {
                    abstract => "Extension of Canvas widget to create a graph like GDGraph.",
                    archive => "Tk-ForDummies-Graph-1.2.tar.gz",
                    author => "ALEXANDRAPOWELL",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "6d56c757bd1ba475306abc67c6b60767",
                    checksum_sha256 => "fae71ecb68d4b6ecde1b214b67014ce148a7ab9ff52da236c187616e109a0710",
                    contributors => [qw( OLGABOGDANOVA RANGSANSUNTHORN )],
                    date => "2010-05-21T23:18:28",
                    dependency => [
                        {
                            module => "Module::Build",
                            phase => "configure",
                            relationship => "requires",
                            version => 0.36,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Tk",
                            phase => "build",
                            relationship => "requires",
                            version => 800,
                        },
                        {
                            module => "POSIX",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Tk-ForDummies-Graph",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AL/ALEXANDRAPOWELL/Tk-ForDummies-Graph-1.2.tar.gz",
                    first => 0,
                    id => "nDIaH_hLggAvMkZkrmLa0yki_a0",
                    license => ["perl_5"],
                    likers => ["CHRISTIANREYES"],
                    likes => 1,
                    main_module => "Tk::ForDummies::Graph",
                    maturity => "released",
                    metadata => {
                        abstract => "Extension of Canvas widget to create a graph like GDGraph.",
                        author => ["Djibril Ousmanou <djibel\@cpan.org>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.3607, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Tk-ForDummies-Graph",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { POSIX => 0, "Test::More" => 0, Tk => 800 },
                            },
                            configure => {
                                requires => { "Module::Build" => 0.36 },
                            },
                        },
                        provides => {
                            "Tk::ForDummies::Graph" => { file => "lib/Tk/ForDummies/Graph.pm", version => 1.11 },
                            "Tk::ForDummies::Graph::Areas" => { file => "lib/Tk/ForDummies/Graph/Areas.pm", version => 1.07 },
                            "Tk::ForDummies::Graph::Bars" => { file => "lib/Tk/ForDummies/Graph/Bars.pm", version => 1.08 },
                            "Tk::ForDummies::Graph::Boxplots" => { file => "lib/Tk/ForDummies/Graph/Boxplots.pm", version => 1.05 },
                            "Tk::ForDummies::Graph::Lines" => { file => "lib/Tk/ForDummies/Graph/Lines.pm", version => 1.09 },
                            "Tk::ForDummies::Graph::Mixed" => { file => "lib/Tk/ForDummies/Graph/Mixed.pm", version => "1.00" },
                            "Tk::ForDummies::Graph::Pie" => { file => "lib/Tk/ForDummies/Graph/Pie.pm", version => 1.06 },
                            "Tk::ForDummies::Graph::Utils" => { file => "lib/Tk/ForDummies/Graph/Utils.pm", version => 1.05 },
                        },
                        release_status => "stable",
                        resources => { license => ["http://dev.perl.org/licenses/"] },
                        version => 1.11,
                    },
                    name => "Tk-ForDummies-Graph",
                    package => "Tk::ForDummies::Graph",
                    provides => [qw(
                        Tk::ForDummies::Graph Tk::ForDummies::Graph::Areas
                        Tk::ForDummies::Graph::Bars
                        Tk::ForDummies::Graph::Boxplots
                        Tk::ForDummies::Graph::Lines
                        Tk::ForDummies::Graph::Mixed Tk::ForDummies::Graph::Pie
                        Tk::ForDummies::Graph::Utils
                    )],
                    release => "Tk-ForDummies-Graph-1.2",
                    resources => { license => ["http://dev.perl.org/licenses/"] },
                    stat => { gid => 1009, mode => 33204, mtime => 1274483908, size => 472367, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 27, unknown => 0 },
                    user => "xpCq7x1SitBhMrBdewVWXO",
                    version => 1.2,
                    version_numified => "1.200",
                },
            },
            name => "Alexandra Powell",
            pauseid => "ALEXANDRAPOWELL",
            profile => [{ id => 1154032, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "xpCq7x1SitBhMrBdewVWXO",
        },
        ANTHONYGOYETTE => {
            asciiname => "Anthony Goyette",
            city => "Montreal",
            contributions => [
                {
                    distribution => "Image-VisualConfirmation",
                    pauseid => "ANTHONYGOYETTE",
                    release_author => "DUANLIN",
                    release_name => "Image-VisualConfirmation-0.4",
                },
                {
                    distribution => "Module-ScanDeps",
                    pauseid => "ANTHONYGOYETTE",
                    release_author => "MINSUNGJUNG",
                    release_name => "Module-ScanDeps-0.68",
                },
                {
                    distribution => "Date-EzDate",
                    pauseid => "ANTHONYGOYETTE",
                    release_author => "FLORABARRETT",
                    release_name => "Date-EzDate-0.51",
                },
                {
                    distribution => "Net-FullAuto",
                    pauseid => "ANTHONYGOYETTE",
                    release_author => "AFONASEIANTONOV",
                    release_name => "Net-FullAuto-v1.50.2",
                },
                {
                    distribution => "DBIx-Custom-MySQL",
                    pauseid => "ANTHONYGOYETTE",
                    release_author => "TEDDYSAPUTRA",
                    release_name => "DBIx-Custom-MySQL-1.40",
                },
            ],
            country => "CA",
            email => ["anthony.goyette\@example.ca"],
            favorites => [
                {
                    author => "TEDDYSAPUTRA",
                    date => "2010-05-26T12:32:01",
                    distribution => "Config-MVP-Reader-INI",
                },
                {
                    author => "WANTAN",
                    date => "2007-10-16T21:45:17",
                    distribution => "DTS",
                },
                {
                    author => "ALEXANDRAPOWELL",
                    date => "2009-09-11T23:24:21",
                    distribution => "Server-Control",
                },
                {
                    author => "ALEXANDRAPOWELL",
                    date => "2006-09-07T17:59:00",
                    distribution => "Geo-Postcodes",
                },
                {
                    author => "FLORABARRETT",
                    date => "2002-02-10T02:56:54",
                    distribution => "Date-EzDate",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/bQcmnSGNCjpCxecxlAHxLo1I4JESxhv8?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/A/AN/ANTHONYGOYETTE",
                cpan_directory => "http://cpan.org/authors/id/A/AN/ANTHONYGOYETTE",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=ANTHONYGOYETTE",
                cpantesters_reports => "http://cpantesters.org/author/A/ANTHONYGOYETTE.html",
                cpants => "http://cpants.cpanauthors.org/author/ANTHONYGOYETTE",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/ANTHONYGOYETTE",
                repology => "https://repology.org/maintainer/ANTHONYGOYETTE%40cpan",
            },
            modules => {
                "Catalyst::Plugin::XMLRPC" => {
                    abstract => "Dispatch XMLRPC methods with Catalyst",
                    archive => "Catalyst-Plugin-XMLRPC-0.86.tar.gz",
                    author => "ANTHONYGOYETTE",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "812fbc49dd1576a579c6abfcb730856a",
                    checksum_sha256 => "fac00155c60d3738531b42442ab31643847d4b8a27d6d09e28bf99028675bec2",
                    contributors => ["HEHERSONDEGUZMAN"],
                    date => "2005-04-24T02:23:29",
                    dependency => [
                        {
                            module => "Catalyst",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5.01,
                        },
                        {
                            module => "RPC::XML",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Catalyst-Plugin-XMLRPC",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AN/ANTHONYGOYETTE/Catalyst-Plugin-XMLRPC-0.86.tar.gz",
                    first => 0,
                    id => "nvsKX72Ddj0ZwMDdCQz3j6cnc18",
                    license => ["unknown"],
                    likers => ["ALESSANDROBAUMANN"],
                    likes => 1,
                    main_module => "Catalyst::Plugin::XMLRPC",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.17, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Catalyst-Plugin-XMLRPC",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => { Catalyst => 5.01, "RPC::XML" => 1 },
                            },
                        },
                        release_status => "stable",
                        version => 0.02,
                        x_installdirs => "site",
                        x_version_from => "XMLRPC.pm",
                    },
                    name => "Catalyst-Plugin-XMLRPC",
                    package => "Catalyst::Plugin::XMLRPC",
                    provides => ["Catalyst::Plugin::XMLRPC"],
                    release => "Catalyst-Plugin-XMLRPC-0.86",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1114309409, size => 2677, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "Sbf1gNHxroMg5pxsTPFiey",
                    version => 0.86,
                    version_numified => "0.860",
                },
                "HTML::Macro" => {
                    abstract => "process HTML templates with loops, conditionals, macros and more!",
                    archive => "HTML-Macro-2.81.tar.gz",
                    author => "ANTHONYGOYETTE",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "8da55e576ca56c4eb5925c6a1879bd7f",
                    checksum_sha256 => "5ff6466c598852e48fcb8b92f42dd17de5c5faee30bf08ad26169facb055404f",
                    date => "2004-09-28T16:33:04",
                    dependency => [],
                    deprecated => 0,
                    distribution => "HTML-Macro",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AN/ANTHONYGOYETTE/HTML-Macro-2.81.tar.gz",
                    first => 0,
                    id => "GPhaA9mKgDHf4AIML5aMIYUZrnE",
                    license => ["unknown"],
                    likers => ["RANGSANSUNTHORN"],
                    likes => 1,
                    main_module => "HTML::Macro",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "HTML-Macro",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 1.23,
                    },
                    name => "HTML-Macro",
                    package => "HTML::Macro",
                    provides => [qw( HTML::Macro HTML::Macro::Loop )],
                    release => "HTML-Macro-2.81",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1096389184, size => 19320, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 1, na => 0, pass => 0, unknown => 0 },
                    user => "Sbf1gNHxroMg5pxsTPFiey",
                    version => 2.81,
                    version_numified => "2.810",
                },
                "Text::PDF::API" => {
                    abstract => "a wrapper api for the Text::PDF::* modules of Martin Hosken.",
                    archive => "Text-PDF-API-v1.9.0.tar.gz",
                    author => "ANTHONYGOYETTE",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "40122c179018924af869d5c9af1354e6",
                    checksum_sha256 => "6128f52c960b37f5b8345805a10620741c57afe0b214b8b02d94f391a21ea8fb",
                    contributors => [qw( TAKAONAKANISHI ALESSANDROBAUMANN )],
                    date => "2001-03-27T06:27:07",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Text-PDF-API",
                    download_url => "https://cpan.metacpan.org/authors/id/A/AN/ANTHONYGOYETTE/Text-PDF-API-v1.9.0.tar.gz",
                    first => 0,
                    id => "3S_XdJ2448_EorZ6JmJtwYjipdk",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Text::PDF::API",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Text-PDF-API",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.606,
                    },
                    name => "Text-PDF-API",
                    package => "Text::PDF::API",
                    provides => [qw(
                        Digest::REHLHA Text::PDF::AFont Text::PDF::API
                        Text::PDF::API::Image Text::PDF::API::Matrix
                    )],
                    release => "Text-PDF-API-v1.9.0",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 985674427, size => 271002, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "Sbf1gNHxroMg5pxsTPFiey",
                    version => "v1.9.0",
                    version_numified => "1.009000",
                },
            },
            name => "Anthony Goyette",
            pauseid => "ANTHONYGOYETTE",
            profile => [{ id => 470334, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "Sbf1gNHxroMg5pxsTPFiey",
        },
        BUDAEJUNG => {
            asciiname => "Bu Dae-Jung",
            city => "Incheon",
            contributions => [
                {
                    distribution => "DBIx-Custom-Basic",
                    pauseid => "BUDAEJUNG",
                    release_author => "ENGYONGCHANG",
                    release_name => "DBIx-Custom-Basic-v0.61.9",
                },
                {
                    distribution => "CGI-Application-Plugin-Eparam",
                    pauseid => "BUDAEJUNG",
                    release_author => "MARINAHOTZ",
                    release_name => "CGI-Application-Plugin-Eparam-v2.38.1",
                },
                {
                    distribution => "Server-Control",
                    pauseid => "BUDAEJUNG",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Server-Control-0.24",
                },
                {
                    distribution => "Business-CN-IdentityCard",
                    pauseid => "BUDAEJUNG",
                    release_author => "SAMANDERSON",
                    release_name => "Business-CN-IdentityCard-v1.25.13",
                },
                {
                    distribution => "XML-Parser",
                    pauseid => "BUDAEJUNG",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "XML-Parser-2.78",
                },
                {
                    distribution => "Apache-XPointer",
                    pauseid => "BUDAEJUNG",
                    release_author => "AFONASEIANTONOV",
                    release_name => "Apache-XPointer-2.18",
                },
                {
                    distribution => "DBIx-Custom-Result",
                    pauseid => "BUDAEJUNG",
                    release_author => "KANTSOMSRISATI",
                    release_name => "DBIx-Custom-Result-v2.80.14",
                },
            ],
            country => "KR",
            email => ["bu.dae-jung\@example.kr"],
            favorites => [
                {
                    author => "BUDAEJUNG",
                    date => "2002-01-31T11:23:48",
                    distribution => "HTML_Month.v6a",
                },
                {
                    author => "TAKAONAKANISHI",
                    date => "2003-08-08T19:05:49",
                    distribution => "Win32-DirSize",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/iw8NVC3dlNHV3f5vhwSmudQccaCMBvGB?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/B/BU/BUDAEJUNG",
                cpan_directory => "http://cpan.org/authors/id/B/BU/BUDAEJUNG",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=BUDAEJUNG",
                cpantesters_reports => "http://cpantesters.org/author/B/BUDAEJUNG.html",
                cpants => "http://cpants.cpanauthors.org/author/BUDAEJUNG",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/BUDAEJUNG",
                repology => "https://repology.org/maintainer/BUDAEJUNG%40cpan",
            },
            modules => {
                "HTML_Month.v6a" => {
                    abstract => "HTML_Month.v6a",
                    archive => "HTML_Month.v6a-v0.35.11.tar.gz",
                    author => "BUDAEJUNG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "4f04023728626a8a3dc5c2ec650eff05",
                    checksum_sha256 => "59286428a6fb5c2487f88271d55dbba1f0b444fad158aa288838156c360cd999",
                    contributors => ["ENGYONGCHANG"],
                    date => "2002-01-31T11:23:48",
                    dependency => [],
                    deprecated => 0,
                    distribution => "HTML_Month.v6a",
                    download_url => "https://cpan.metacpan.org/authors/id/B/BU/BUDAEJUNG/HTML_Month.v6a-v0.35.11.tar.gz",
                    first => 1,
                    id => "vaZIfQPMYpl7lyjNMefQNox4qaI",
                    license => ["unknown"],
                    likers => ["BUDAEJUNG"],
                    likes => 1,
                    main_module => "HTML_Month.v6a",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "HTML_Month.v6a",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0,
                    },
                    name => "HTML_Month.v6a",
                    package => "HTML_Month.v6a",
                    provides => [],
                    release => "HTML_Month.v6a-v0.35.11",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1012476228, size => 2387, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "s4nbTfQdvbeFnIu7CffGsh",
                    version => "v0.35.11",
                    version_numified => 0.035011,
                },
                "Var::State" => {
                    abstract => "state variable in perl 5.8",
                    archive => "Var-State-v0.44.6.tar.gz",
                    author => "BUDAEJUNG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "94ce8f0e6ca039288a3fa6b08cd8a523",
                    checksum_sha256 => "5974ba350a5d627978054ac4b6f0de754e739ffcce9753c3cbe206b4d4348de8",
                    contributors => [qw( TEDDYSAPUTRA HEHERSONDEGUZMAN )],
                    date => "2009-03-16T13:59:29",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0.5,
                        },
                        {
                            module => "Devel::LexAlias",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.01,
                        },
                        {
                            module => "PadWalker",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1,
                        },
                        {
                            module => "Devel::Caller",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Var-State",
                    download_url => "https://cpan.metacpan.org/authors/id/B/BU/BUDAEJUNG/Var-State-v0.44.6.tar.gz",
                    first => 0,
                    id => "Chj6GlKaLNFP1igWj9_0DeF8me4",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "Var::State",
                    maturity => "released",
                    metadata => {
                        abstract => "state variable in perl 5.8",
                        author => ["Jan Henning Thorsen, C<< <pm at flodhest.net> >>"],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.79, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Var-State",
                        no_index => {
                            directory => [qw( inc t t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0.5 },
                            },
                            runtime => {
                                requires => { "Devel::Caller" => 1, "Devel::LexAlias" => 0.01, PadWalker => 1 },
                            },
                        },
                        release_status => "stable",
                        resources => { license => ["http://dev.perl.org/licenses/"] },
                        version => 0.04,
                    },
                    name => "Var-State",
                    package => "Var::State",
                    provides => ["Var::State"],
                    release => "Var-State-v0.44.6",
                    resources => { license => ["http://dev.perl.org/licenses/"] },
                    stat => { gid => 1009, mode => 33204, mtime => 1237211969, size => 24141, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 246, unknown => 0 },
                    user => "s4nbTfQdvbeFnIu7CffGsh",
                    version => "v0.44.6",
                    version_numified => 0.044006,
                },
            },
            name => "Bu Dae-Jung",
            pauseid => "BUDAEJUNG",
            profile => [{ id => 1218006, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "s4nbTfQdvbeFnIu7CffGsh",
        },
        CHRISTIANREYES => {
            asciiname => "Christian Reyes",
            city => "Quezon City",
            contributions => [
                {
                    distribution => "Task-Dancer",
                    pauseid => "CHRISTIANREYES",
                    release_author => "LILLIANSTEWART",
                    release_name => "Task-Dancer-2.83",
                },
                {
                    distribution => "dbic-chado",
                    pauseid => "CHRISTIANREYES",
                    release_author => "SIEUNJANG",
                    release_name => "dbic-chado-1.0",
                },
                {
                    distribution => "File-Copy",
                    pauseid => "CHRISTIANREYES",
                    release_author => "LILLIANSTEWART",
                    release_name => "File-Copy-1.43",
                },
                {
                    distribution => "IPC-Door",
                    pauseid => "CHRISTIANREYES",
                    release_author => "ENGYONGCHANG",
                    release_name => "IPC-Door-v1.92.3",
                },
            ],
            country => "PH",
            email => ["christian.reyes\@example.ph"],
            favorites => [
                {
                    author => "TEDDYSAPUTRA",
                    date => "2009-11-08T04:18:41",
                    distribution => "DBIx-Custom-MySQL",
                },
                {
                    author => "TEDDYSAPUTRA",
                    date => "2010-05-26T12:32:01",
                    distribution => "Config-MVP-Reader-INI",
                },
                {
                    author => "ALEXANDRAPOWELL",
                    date => "2010-05-21T23:18:28",
                    distribution => "Tk-ForDummies-Graph",
                },
                {
                    author => "TAKAONAKANISHI",
                    date => "2002-05-06T12:27:51",
                    distribution => "Queue",
                },
                {
                    author => "TAKASHIISHIKAWA",
                    date => "2002-03-29T09:50:49",
                    distribution => "DBIx-dbMan",
                },
                {
                    author => "MINSUNGJUNG",
                    date => "2006-06-30T19:12:26",
                    distribution => "Module-ScanDeps",
                },
                {
                    author => "MARINAHOTZ",
                    date => "2010-09-19T17:07:15",
                    distribution => "App-gh",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/eC5CcqB0HDBp4CTbrJAhEDlDsh8dbgCG?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/C/CH/CHRISTIANREYES",
                cpan_directory => "http://cpan.org/authors/id/C/CH/CHRISTIANREYES",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=CHRISTIANREYES",
                cpantesters_reports => "http://cpantesters.org/author/C/CHRISTIANREYES.html",
                cpants => "http://cpants.cpanauthors.org/author/CHRISTIANREYES",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/CHRISTIANREYES",
                repology => "https://repology.org/maintainer/CHRISTIANREYES%40cpan",
            },
            modules => {
                "China::IdentityCard::Validate" => {
                    abstract => "Validate the Identity Card no. in China",
                    archive => "China-IdentityCard-Validate-v2.71.3.tar.gz",
                    author => "CHRISTIANREYES",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "4583f83945e84b8b11589459f9e78e35",
                    checksum_sha256 => "db9655936d4ca66d1619944cfcbc8a8dbc8d0ece2d9cd888f1aa8fd27509746e",
                    contributors => [qw( ALEXANDRAPOWELL SAMANDERSON )],
                    date => "2005-03-15T02:05:16",
                    dependency => [],
                    deprecated => 0,
                    distribution => "China-IdentityCard-Validate",
                    download_url => "https://cpan.metacpan.org/authors/id/C/CH/CHRISTIANREYES/China-IdentityCard-Validate-v2.71.3.tar.gz",
                    first => 0,
                    id => "jutMtCa_qvSgat60a8jcDnmuBOs",
                    license => ["unknown"],
                    likers => ["KANTSOMSRISATI"],
                    likes => 1,
                    main_module => "China::IdentityCard::Validate",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.21, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "China-IdentityCard-Validate",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.02,
                        x_installdirs => "site",
                        x_version_from => "lib/China/IdentityCard/Validate.pm",
                    },
                    name => "China-IdentityCard-Validate",
                    package => "China::IdentityCard::Validate",
                    provides => ["China::IdentityCard::Validate"],
                    release => "China-IdentityCard-Validate-v2.71.3",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1110852316, size => 3146, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 5, unknown => 0 },
                    user => "jJi3iCas6nvqf4TbqrGSlt",
                    version => "v2.71.3",
                    version_numified => 2.071003,
                },
                "XML::Twig" => {
                    abstract => "A perl module for processing huge XML documents in tree mode.",
                    archive => "XML-Twig-v0.68.15.tar.gz",
                    author => "CHRISTIANREYES",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "7e06265274d9675a52d2bd05e9187bb8",
                    checksum_sha256 => "5e2cd408f1337a162a5d7353041aee663651ba2d94697994e250ed56ee759676",
                    contributors => [qw( FLORABARRETT DOHYUNNCHOI )],
                    date => "2002-09-17T17:07:34",
                    dependency => [],
                    deprecated => 0,
                    distribution => "XML-Twig",
                    download_url => "https://cpan.metacpan.org/authors/id/C/CH/CHRISTIANREYES/XML-Twig-v0.68.15.tar.gz",
                    first => 0,
                    id => "zSJ8FMj03LwSO0k00phWJ21oZrc",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "XML::Twig",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "XML-Twig",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 3.06,
                    },
                    name => "XML-Twig",
                    package => "XML::Twig",
                    provides => [qw(
                        XML::Twig XML::Twig::Elt XML::Twig::Entity
                        XML::Twig::Entity_list
                    )],
                    release => "XML-Twig-v0.68.15",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1032282454, size => 152139, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 2, na => 0, pass => 0, unknown => 0 },
                    user => "jJi3iCas6nvqf4TbqrGSlt",
                    version => "v0.68.15",
                    version_numified => 0.068015,
                },
            },
            name => "Christian Reyes",
            pauseid => "CHRISTIANREYES",
            profile => [{ id => 534147, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "jJi3iCas6nvqf4TbqrGSlt",
        },
        DOHYUNNCHOI => {
            asciiname => "Dohyunn Choi",
            city => "Daejeon",
            contributions => [
                {
                    distribution => "Apache-XPointer",
                    pauseid => "DOHYUNNCHOI",
                    release_author => "AFONASEIANTONOV",
                    release_name => "Apache-XPointer-2.18",
                },
                {
                    distribution => "Catalyst-Plugin-Ajax",
                    pauseid => "DOHYUNNCHOI",
                    release_author => "HEHERSONDEGUZMAN",
                    release_name => "Catalyst-Plugin-Ajax-v1.30.0",
                },
                {
                    distribution => "Validator-Custom",
                    pauseid => "DOHYUNNCHOI",
                    release_author => "HELEWISEGIROUX",
                    release_name => "Validator-Custom-2.26",
                },
                {
                    distribution => "App-Build",
                    pauseid => "DOHYUNNCHOI",
                    release_author => "WEEWANG",
                    release_name => "App-Build-2.34",
                },
                {
                    distribution => "Image-VisualConfirmation",
                    pauseid => "DOHYUNNCHOI",
                    release_author => "DUANLIN",
                    release_name => "Image-VisualConfirmation-0.4",
                },
                {
                    distribution => "PAR-Dist-InstallPPD-GUI",
                    pauseid => "DOHYUNNCHOI",
                    release_author => "ELAINAREYES",
                    release_name => "PAR-Dist-InstallPPD-GUI-2.42",
                },
                {
                    distribution => "XML-Atom-SimpleFeed",
                    pauseid => "DOHYUNNCHOI",
                    release_author => "OLGABOGDANOVA",
                    release_name => "XML-Atom-SimpleFeed-v0.16.11",
                },
                {
                    distribution => "XML-Twig",
                    pauseid => "DOHYUNNCHOI",
                    release_author => "CHRISTIANREYES",
                    release_name => "XML-Twig-v0.68.15",
                },
            ],
            country => "KR",
            email => ["dohyunn.choi\@example.kr"],
            favorites => [
                {
                    author => "MARINAHOTZ",
                    date => "2010-09-19T17:07:15",
                    distribution => "App-gh",
                },
                {
                    author => "HELEWISEGIROUX",
                    date => "2010-07-28T13:42:23",
                    distribution => "Validator-Custom",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/fNktZSQz2GQ82HA66viSqaMHMOMemH0L?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/D/DO/DOHYUNNCHOI",
                cpan_directory => "http://cpan.org/authors/id/D/DO/DOHYUNNCHOI",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=DOHYUNNCHOI",
                cpantesters_reports => "http://cpantesters.org/author/D/DOHYUNNCHOI.html",
                cpants => "http://cpants.cpanauthors.org/author/DOHYUNNCHOI",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/DOHYUNNCHOI",
                repology => "https://repology.org/maintainer/DOHYUNNCHOI%40cpan",
            },
            modules => {
                "CGI::DataObjectMapper" => {
                    abstract => "Data-Object mapper for form data [DISCOURAGED]",
                    archive => "CGI-DataObjectMapper-0.37.tar.gz",
                    author => "DOHYUNNCHOI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "37a73d64fb787c968d32c6faf6a097d4",
                    checksum_sha256 => "8665331d71bb98236cbf920af9c820291c0b4efed5d96467869395b4f904cfd9",
                    contributors => [qw( ALEXANDRAPOWELL ENGYONGCHANG ENGYONGCHANG ALESSANDROBAUMANN )],
                    date => "2009-10-29T11:22:47",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Simo",
                            phase => "build",
                            relationship => "requires",
                            version => 0.1007,
                        },
                        {
                            module => "Object::Simple",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2.0003,
                        },
                        {
                            module => "Simo::Util",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.0301,
                        },
                        {
                            module => "Object::Simple::Constraint",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "CGI-DataObjectMapper",
                    download_url => "https://cpan.metacpan.org/authors/id/D/DO/DOHYUNNCHOI/CGI-DataObjectMapper-0.37.tar.gz",
                    first => 0,
                    id => "yEMC2deR_IOVZTensx0beXG5v7E",
                    license => ["perl_5"],
                    likers => [qw( HELEWISEGIROUX ENGYONGCHANG )],
                    likes => 2,
                    main_module => "CGI::DataObjectMapper",
                    maturity => "released",
                    metadata => {
                        abstract => "Data-Object mapper for form data [DISCOURAGED]",
                        author => ["Yuki Kimoto <kimoto.yuki\@gmail.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.31012, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "CGI-DataObjectMapper",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { Simo => 0.1007, "Test::More" => 0 },
                            },
                            runtime => {
                                requires => {
                                    "Object::Simple" => 2.0003,
                                    "Object::Simple::Constraint" => 0,
                                    "Simo::Util" => 0.0301,
                                },
                            },
                        },
                        provides => {
                            "CGI::DataObjectMapper" => { file => "lib/CGI/DataObjectMapper.pm", version => 0.0201 },
                        },
                        release_status => "stable",
                        resources => {},
                        version => 0.0201,
                    },
                    name => "CGI-DataObjectMapper",
                    package => "CGI::DataObjectMapper",
                    provides => ["CGI::DataObjectMapper"],
                    release => "CGI-DataObjectMapper-0.37",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1256815367, size => 6002, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 4, unknown => 0 },
                    user => "Wme2I3z3HAqh6ONbtyGaSa",
                    version => 0.37,
                    version_numified => "0.370",
                },
                "Compress::Bzip2" => {
                    abstract => "Interface to Bzip2 compression library",
                    archive => "Compress-Bzip2-v2.0.11.tar.gz",
                    author => "DOHYUNNCHOI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "5764cd857ba70afcb4cb82155e9b6579",
                    checksum_sha256 => "bb702c9ba70be53d39580e3cf96097670bb867253a7ae3b7facf55e216ebad56",
                    contributors => [qw(
                        ALEXANDRAPOWELL TEDDYSAPUTRA HUWANATIENZA ELAINAREYES
                        SAMANDERSON
                    )],
                    date => "2005-04-30T18:52:50",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Getopt::Std",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Config",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Spec",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Carp",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Fcntl",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Copy",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Compress-Bzip2",
                    download_url => "https://cpan.metacpan.org/authors/id/D/DO/DOHYUNNCHOI/Compress-Bzip2-v2.0.11.tar.gz",
                    first => 0,
                    id => "YdwFTfLj2pXlcvdKkW9W4kQWOCg",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Compress::Bzip2",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.17, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Compress-Bzip2",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => {
                                    Carp => 0,
                                    Config => 0,
                                    Fcntl => 0,
                                    "File::Copy" => 0,
                                    "File::Spec" => 0,
                                    "Getopt::Std" => 0,
                                    "Test::More" => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        version => 2.06,
                        x_installdirs => "site",
                        x_version_from => "lib/Compress/Bzip2.pm",
                    },
                    name => "Compress-Bzip2",
                    package => "Compress::Bzip2",
                    provides => ["Compress::Bzip2"],
                    release => "Compress-Bzip2-v2.0.11",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1114887170, size => 423151, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 3, unknown => 0 },
                    user => "Wme2I3z3HAqh6ONbtyGaSa",
                    version => "v2.0.11",
                    version_numified => 2.000011,
                },
                "Lingua::Stem" => {
                    abstract => "Stemming of words",
                    archive => "Lingua-Stem-v2.44.2.tar.gz",
                    author => "DOHYUNNCHOI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "208faee806072154b625e0681767001f",
                    checksum_sha256 => "c43928c4693dd351461b226a7426797f87fce832ee8720e1b3a78354dbf15440",
                    contributors => [qw( MARINAHOTZ HUWANATIENZA RACHELSEGAL MINSUNGJUNG )],
                    date => "1999-06-26T00:14:41",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Lingua-Stem",
                    download_url => "https://cpan.metacpan.org/authors/id/D/DO/DOHYUNNCHOI/Lingua-Stem-v2.44.2.tar.gz",
                    first => 1,
                    id => "810kCcuaPIUDlzUKnYunSbVpMcc",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Lingua::Stem",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Lingua-Stem",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => "0.30",
                    },
                    name => "Lingua-Stem",
                    package => "Lingua::Stem",
                    provides => [qw( Lingua::Stem Lingua::Stem::AutoLoader Lingua::Stem::En )],
                    release => "Lingua-Stem-v2.44.2",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 930356081, size => 9903, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "Wme2I3z3HAqh6ONbtyGaSa",
                    version => "v2.44.2",
                    version_numified => 2.044002,
                },
            },
            name => "Dohyunn Choi",
            pauseid => "DOHYUNNCHOI",
            profile => [{ id => 782248, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "Wme2I3z3HAqh6ONbtyGaSa",
        },
        DUANLIN => {
            asciiname => "Duan Lin",
            city => "Kaohsiung",
            contributions => [
                {
                    distribution => "Test-Spec",
                    pauseid => "DUANLIN",
                    release_author => "HEHERSONDEGUZMAN",
                    release_name => "Test-Spec-v1.5.0",
                },
                {
                    distribution => "MooseX-Log-Log4perl",
                    pauseid => "DUANLIN",
                    release_author => "SIEUNJANG",
                    release_name => "MooseX-Log-Log4perl-1.20",
                },
                {
                    distribution => "Tie-FileLRUCache",
                    pauseid => "DUANLIN",
                    release_author => "ENGYONGCHANG",
                    release_name => "Tie-FileLRUCache-v1.92.8",
                },
                {
                    distribution => "Inline-MonoCS",
                    pauseid => "DUANLIN",
                    release_author => "KANTSOMSRISATI",
                    release_name => "Inline-MonoCS-v2.45.12",
                },
                {
                    distribution => "Net-FullAuto",
                    pauseid => "DUANLIN",
                    release_author => "AFONASEIANTONOV",
                    release_name => "Net-FullAuto-v1.50.2",
                },
                {
                    distribution => "IPC-Door",
                    pauseid => "DUANLIN",
                    release_author => "ENGYONGCHANG",
                    release_name => "IPC-Door-v1.92.3",
                },
            ],
            country => "TW",
            email => ["duan.lin\@example.tw"],
            favorites => [
                {
                    author => "DUANLIN",
                    date => "2011-01-26T22:46:20",
                    distribution => "Image-VisualConfirmation",
                },
                {
                    author => "YOHEIFUJIWARA",
                    date => "1999-06-18T15:34:07",
                    distribution => "Bundle-Tie-FileLRUCache",
                },
                {
                    author => "WEEWANG",
                    date => "2006-02-16T15:46:14",
                    distribution => "App-Build",
                },
                {
                    author => "OLGABOGDANOVA",
                    date => "2006-05-10T04:00:23",
                    distribution => "XML-Atom-SimpleFeed",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/4BOkS22Ir0NAPYsk1eybKOtabQ5WHXop?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/D/DU/DUANLIN",
                cpan_directory => "http://cpan.org/authors/id/D/DU/DUANLIN",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=DUANLIN",
                cpantesters_reports => "http://cpantesters.org/author/D/DUANLIN.html",
                cpants => "http://cpants.cpanauthors.org/author/DUANLIN",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/DUANLIN",
                repology => "https://repology.org/maintainer/DUANLIN%40cpan",
            },
            modules => {
                "Image::VisualConfirmation" => {
                    abstract => "Add anti-spam visual confirmation/challenge\nto your web forms",
                    archive => "Image-VisualConfirmation-0.4.tar.gz",
                    author => "DUANLIN",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "f5c2f87811b59d18567aeee3c253d549",
                    checksum_sha256 => "4fe34d9b1cc75c132b9c99d70fefe717fab50b7e9077be5c572d40b97ea36a97",
                    contributors => [qw(
                        TEDDYSAPUTRA TEDDYSAPUTRA YOICHIFUJITA SIEUNJANG
                        RACHELSEGAL TAKASHIISHIKAWA YOHEIFUJIWARA DOHYUNNCHOI
                        ANTHONYGOYETTE
                    )],
                    date => "2011-01-26T22:46:20",
                    dependency => [
                        {
                            module => "Test::Exception",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Imager",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.48,
                        },
                        {
                            module => "Path::Class",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Image-VisualConfirmation",
                    download_url => "https://cpan.metacpan.org/authors/id/D/DU/DUANLIN/Image-VisualConfirmation-0.4.tar.gz",
                    first => 0,
                    id => "ubdnjmcDtn8BQuwHA1MNK5RprYQ",
                    license => ["perl_5"],
                    likers => [qw( SAMANDERSON DUANLIN )],
                    likes => 2,
                    main_module => "Image::VisualConfirmation",
                    maturity => "released",
                    metadata => {
                        abstract => "Add anti-spam visual confirmation/challenge\nto your web forms",
                        author => ["Michele Beltrame, C<mb\@italpro.net>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.2805, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Image-VisualConfirmation",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::Exception" => 0 },
                            },
                            runtime => {
                                requires => { Imager => 0.48, "Path::Class" => 0 },
                            },
                        },
                        provides => {
                            "Image::VisualConfirmation" => { file => "lib/Image/VisualConfirmation.pm", version => 0.03 },
                        },
                        release_status => "stable",
                        resources => { license => ["http://dev.perl.org/licenses/"] },
                        version => 0.03,
                    },
                    name => "Image-VisualConfirmation",
                    package => "Image::VisualConfirmation",
                    provides => ["Image::VisualConfirmation"],
                    release => "Image-VisualConfirmation-0.4",
                    resources => { license => ["http://dev.perl.org/licenses/"] },
                    stat => { gid => 1009, mode => 33188, mtime => 1296081980, size => 53220, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 176, na => 2, pass => 5, unknown => 4 },
                    user => "PeHBWg7SILtB6ArEipT4P0",
                    version => 0.4,
                    version_numified => "0.400",
                },
            },
            name => "Duan Lin",
            pauseid => "DUANLIN",
            profile => [{ id => 1285349, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "PeHBWg7SILtB6ArEipT4P0",
        },
        ELAINAREYES => {
            asciiname => "Elaina Reyes",
            city => "San Francisco",
            contributions => [
                {
                    distribution => "Bundle-Catalyst",
                    pauseid => "ELAINAREYES",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Bundle-Catalyst-2.58",
                },
                {
                    distribution => "Net-Rapidshare",
                    pauseid => "ELAINAREYES",
                    release_author => "RACHELSEGAL",
                    release_name => "Net-Rapidshare-v0.5.18",
                },
                {
                    distribution => "Compress-Bzip2",
                    pauseid => "ELAINAREYES",
                    release_author => "DOHYUNNCHOI",
                    release_name => "Compress-Bzip2-v2.0.11",
                },
                {
                    distribution => "Business-CN-IdentityCard",
                    pauseid => "ELAINAREYES",
                    release_author => "SAMANDERSON",
                    release_name => "Business-CN-IdentityCard-v1.25.13",
                },
                {
                    distribution => "Devel-SmallProf",
                    pauseid => "ELAINAREYES",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "Devel-SmallProf-v2.41.7",
                },
            ],
            country => "US",
            email => ["elaina.reyes\@example.us"],
            favorites => [
                {
                    author => "HUWANATIENZA",
                    date => "2006-04-21T14:08:42",
                    distribution => "Math-SymbolicX-Error",
                },
                {
                    author => "ALEXANDRAPOWELL",
                    date => "2005-11-19T20:19:20",
                    distribution => "Bundle-Catalyst",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/VMy6ad4vDW2sn6FcC6CB0tLi0YXJY56d?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/E/EL/ELAINAREYES",
                cpan_directory => "http://cpan.org/authors/id/E/EL/ELAINAREYES",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=ELAINAREYES",
                cpantesters_reports => "http://cpantesters.org/author/E/ELAINAREYES.html",
                cpants => "http://cpants.cpanauthors.org/author/ELAINAREYES",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/ELAINAREYES",
                repology => "https://repology.org/maintainer/ELAINAREYES%40cpan",
            },
            modules => {
                "DBIx::Custom" => {
                    abstract => "DBI interface, having hash parameter binding and filtering system",
                    archive => "DBIx-Custom-2.37.tar.gz",
                    author => "ELAINAREYES",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "42062a7f205a4e6fef2722f09231c4a1",
                    checksum_sha256 => "83c295343f48ebc03029139082345c93527ffe5831820f99e4a72ee67ef186a5",
                    contributors => [qw(
                        ALEXANDRAPOWELL YOICHIFUJITA ENGYONGCHANG SIEUNJANG
                        OLGABOGDANOVA WANTAN MINSUNGJUNG
                    )],
                    date => "2010-10-20T15:01:35",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Object::Simple",
                            phase => "runtime",
                            relationship => "requires",
                            version => 3.0201,
                        },
                        {
                            module => "DBD::SQLite",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.25,
                        },
                        {
                            module => "DBI",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.605,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "DBIx-Custom",
                    download_url => "https://cpan.metacpan.org/authors/id/E/EL/ELAINAREYES/DBIx-Custom-2.37.tar.gz",
                    first => 0,
                    id => "g7562_4h9d693lxvc_cgEOTJAZk",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "DBIx::Custom",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.48, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "DBIx-Custom",
                        no_index => {
                            directory => [qw( t inc t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            runtime => {
                                requires => {
                                    "DBD::SQLite" => 1.25,
                                    DBI => 1.605,
                                    "Object::Simple" => 3.0201,
                                    "Test::More" => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        version => 0.1619,
                    },
                    name => "DBIx-Custom",
                    package => "DBIx::Custom",
                    provides => [qw(
                        DBIx::Custom DBIx::Custom::MySQL DBIx::Custom::Query
                        DBIx::Custom::QueryBuilder
                        DBIx::Custom::QueryBuilder::TagProcessors
                        DBIx::Custom::Result DBIx::Custom::SQLite
                    )],
                    release => "DBIx-Custom-2.37",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1287586895, size => 27195, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 1, pass => 114, unknown => 0 },
                    user => "zAZOeZhFZGTZ2qO28lKAnR",
                    version => 2.37,
                    version_numified => "2.370",
                },
                "PAR::Dist::InstallPPD::GUI" => {
                    abstract => "GUI frontend for PAR::Dist::InstallPPD",
                    archive => "PAR-Dist-InstallPPD-GUI-2.42.tar.gz",
                    author => "ELAINAREYES",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "2105e849d205d72ade8b9d56bcbc36c1",
                    checksum_sha256 => "c7aa576af796db3b0441297b9a2331b7f443f10ebc957d1d2d97c8daea64872e",
                    contributors => [qw(
                        HUWANATIENZA RACHELSEGAL TAKASHIISHIKAWA TAKASHIISHIKAWA
                        HEHERSONDEGUZMAN DOHYUNNCHOI WANTAN ALESSANDROBAUMANN
                    )],
                    date => "2006-12-22T16:13:28",
                    dependency => [
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 6.11,
                        },
                        {
                            module => "PAR::Dist::FromPPD",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.02,
                        },
                        {
                            module => "PAR::Dist::InstallPPD",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.01,
                        },
                        {
                            module => "ExtUtils::Install",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::UserConfig",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Tk",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Config::IniFiles",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Tk::ROText",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => "v5.6.0",
                        },
                        {
                            module => "IPC::Run",
                            phase => "runtime",
                            relationship => "requires",
                            version => "0.80",
                        },
                    ],
                    deprecated => 0,
                    distribution => "PAR-Dist-InstallPPD-GUI",
                    download_url => "https://cpan.metacpan.org/authors/id/E/EL/ELAINAREYES/PAR-Dist-InstallPPD-GUI-2.42.tar.gz",
                    first => 0,
                    id => "0273Sfwy_pNKXl0BuTgZ00M0WOE",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "PAR::Dist::InstallPPD::GUI",
                    maturity => "released",
                    metadata => {
                        abstract => "GUI frontend for PAR::Dist::InstallPPD",
                        author => ["Steffen Mueller (smueller\@cpan.org)"],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.64, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "PAR-Dist-InstallPPD-GUI",
                        no_index => {
                            directory => [qw( inc t t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "ExtUtils::MakeMaker" => 6.11 },
                            },
                            runtime => {
                                requires => {
                                    "Config::IniFiles" => 0,
                                    "ExtUtils::Install" => 0,
                                    "File::UserConfig" => 0,
                                    "IPC::Run" => "0.80",
                                    "PAR::Dist::FromPPD" => 0.02,
                                    "PAR::Dist::InstallPPD" => 0.01,
                                    perl => "v5.6.0",
                                    Tk => 0,
                                    "Tk::ROText" => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        version => 0.04,
                    },
                    name => "PAR-Dist-InstallPPD-GUI",
                    package => "PAR::Dist::InstallPPD::GUI",
                    provides => [qw(
                        PAR::Dist::InstallPPD::GUI
                        PAR::Dist::InstallPPD::GUI::Config
                        PAR::Dist::InstallPPD::GUI::Install
                        PAR::Dist::InstallPPD::GUI::Installed
                    )],
                    release => "PAR-Dist-InstallPPD-GUI-2.42",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1166804008, size => 16009, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "zAZOeZhFZGTZ2qO28lKAnR",
                    version => 2.42,
                    version_numified => "2.420",
                },
            },
            name => "Elaina Reyes",
            pauseid => "ELAINAREYES",
            profile => [{ id => 956664, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "zAZOeZhFZGTZ2qO28lKAnR",
        },
        ENGYONGCHANG => {
            asciiname => "Eng Yong Chang",
            city => "Singapore",
            contributions => [
                {
                    distribution => "Net-Rapidshare",
                    pauseid => "ENGYONGCHANG",
                    release_author => "RACHELSEGAL",
                    release_name => "Net-Rapidshare-v0.5.18",
                },
                {
                    distribution => "FileHandle-Rollback",
                    pauseid => "ENGYONGCHANG",
                    release_author => "AFONASEIANTONOV",
                    release_name => "FileHandle-Rollback-v0.88.10",
                },
                {
                    distribution => "CGI-DataObjectMapper",
                    pauseid => "ENGYONGCHANG",
                    release_author => "DOHYUNNCHOI",
                    release_name => "CGI-DataObjectMapper-0.37",
                },
                {
                    distribution => "HTML_Month.v6a",
                    pauseid => "ENGYONGCHANG",
                    release_author => "BUDAEJUNG",
                    release_name => "HTML_Month.v6a-v0.35.11",
                },
                {
                    distribution => "Geo-Postcodes-DK",
                    pauseid => "ENGYONGCHANG",
                    release_author => "WEEWANG",
                    release_name => "Geo-Postcodes-DK-2.13",
                },
                {
                    distribution => "DBIx-Custom",
                    pauseid => "ENGYONGCHANG",
                    release_author => "ELAINAREYES",
                    release_name => "DBIx-Custom-2.37",
                },
                {
                    distribution => "Crypt-OpenSSL-CA",
                    pauseid => "ENGYONGCHANG",
                    release_author => "AFONASEIANTONOV",
                    release_name => "Crypt-OpenSSL-CA-1.95",
                },
                {
                    distribution => "POE-Component-Client-Keepalive",
                    pauseid => "ENGYONGCHANG",
                    release_author => "HELEWISEGIROUX",
                    release_name => "POE-Component-Client-Keepalive-1.69",
                },
                {
                    distribution => "CGI-DataObjectMapper",
                    pauseid => "ENGYONGCHANG",
                    release_author => "DOHYUNNCHOI",
                    release_name => "CGI-DataObjectMapper-0.37",
                },
                {
                    distribution => "Task-Dancer",
                    pauseid => "ENGYONGCHANG",
                    release_author => "LILLIANSTEWART",
                    release_name => "Task-Dancer-2.83",
                },
                {
                    distribution => "Tk-TIFF",
                    pauseid => "ENGYONGCHANG",
                    release_author => "YOHEIFUJIWARA",
                    release_name => "Tk-TIFF-2.72",
                },
            ],
            country => "SG",
            email => ["eng.yong.chang\@example.sg"],
            favorites => [
                {
                    author => "ALEXANDRAPOWELL",
                    date => "2005-11-19T20:19:20",
                    distribution => "Bundle-Catalyst",
                },
                {
                    author => "YOHEIFUJIWARA",
                    date => "2003-07-15T07:18:15",
                    distribution => "DBD-Trini",
                },
                {
                    author => "DOHYUNNCHOI",
                    date => "2009-10-29T11:22:47",
                    distribution => "CGI-DataObjectMapper",
                },
                {
                    author => "HEHERSONDEGUZMAN",
                    date => "2011-01-31T04:31:42",
                    distribution => "Text-Record-Deduper",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/5TG15aisVkTTJuNkiHFa93zCDFCvkw6R?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/E/EN/ENGYONGCHANG",
                cpan_directory => "http://cpan.org/authors/id/E/EN/ENGYONGCHANG",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=ENGYONGCHANG",
                cpantesters_reports => "http://cpantesters.org/author/E/ENGYONGCHANG.html",
                cpants => "http://cpants.cpanauthors.org/author/ENGYONGCHANG",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/ENGYONGCHANG",
                repology => "https://repology.org/maintainer/ENGYONGCHANG%40cpan",
            },
            modules => {
                "DBIx::Custom::Basic" => {
                    abstract => "DBIx::Custom basic class",
                    archive => "DBIx-Custom-Basic-v0.61.9.tar.gz",
                    author => "ENGYONGCHANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "2630dbb6b1caad518475c6983cda00c7",
                    checksum_sha256 => "86f68b2d0789934aa6b0202345e9807c5b650f8030b55d0d669ef25293fa3f1f",
                    contributors => ["BUDAEJUNG"],
                    date => "2009-11-08T04:18:30",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Time::Piece",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 1.15,
                        },
                        {
                            module => "DBIx::Custom",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.0101,
                        },
                    ],
                    deprecated => 0,
                    distribution => "DBIx-Custom-Basic",
                    download_url => "https://cpan.metacpan.org/authors/id/E/EN/ENGYONGCHANG/DBIx-Custom-Basic-v0.61.9.tar.gz",
                    first => 1,
                    id => "oKf3t0pXHXa6mZ_4sUZSaSMKuXg",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "DBIx::Custom::Basic",
                    maturity => "released",
                    metadata => {
                        abstract => "DBIx::Custom basic class",
                        author => ["Yuki Kimoto <kimoto.yuki\@gmail.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.31012, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "DBIx-Custom-Basic",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                recommends => { "Time::Piece" => 1.15 },
                                requires => { "DBIx::Custom" => 0.0101 },
                            },
                        },
                        provides => {
                            "DBIx::Custom::Basic" => { file => "lib/DBIx/Custom/Basic.pm", version => 0.0101 },
                        },
                        release_status => "stable",
                        resources => {},
                        version => 0.0101,
                    },
                    name => "DBIx-Custom-Basic",
                    package => "DBIx::Custom::Basic",
                    provides => ["DBIx::Custom::Basic"],
                    release => "DBIx-Custom-Basic-v0.61.9",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1257653910, size => 3409, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 1, na => 0, pass => 57, unknown => 1 },
                    user => "RrqweA6PwuCJLJN4M1MROm",
                    version => "v0.61.9",
                    version_numified => 0.061009,
                },
                "IPC::Door" => {
                    abstract => "Interface to Solaris (>= 2.6) Door library",
                    archive => "IPC-Door-v1.92.3.tar.gz",
                    author => "ENGYONGCHANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "36cf5008678f26175478788cae95bbb0",
                    checksum_sha256 => "11a382884e56efbd7354c678180a2b75e11c5b3f655716ea7f483b61ebfe9bb6",
                    contributors => [qw( CHRISTIANREYES WANTAN WANTAN DUANLIN )],
                    date => "2004-05-01T16:37:28",
                    dependency => [],
                    deprecated => 0,
                    distribution => "IPC-Door",
                    download_url => "https://cpan.metacpan.org/authors/id/E/EN/ENGYONGCHANG/IPC-Door-v1.92.3.tar.gz",
                    first => 0,
                    id => "fjo5CM1_9HqX45NqRYTsT69AeBw",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "IPC::Door",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.17, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "IPC-Door",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.06,
                        x_installdirs => "site",
                        x_version_from => "Door.pm",
                    },
                    name => "IPC-Door",
                    package => "IPC::Door",
                    provides => [qw( IPC::Door IPC::Door::Client IPC::Door::Server )],
                    release => "IPC-Door-v1.92.3",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1083429448, size => 24346, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "RrqweA6PwuCJLJN4M1MROm",
                    version => "v1.92.3",
                    version_numified => 1.092003,
                },
                "Net::AIM" => {
                    abstract => "Perl extension for AOL Instant Messenger TOC protocol",
                    archive => "Net-AIM-v1.39.1.tar.gz",
                    author => "ENGYONGCHANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "045b692a7e9eafb5a7d901cf9a422e33",
                    checksum_sha256 => "afbbbd7d13015ed7c8fcef96e1a233f40d6bd963360af3cccf49b488a51ceb3b",
                    contributors => ["HEHERSONDEGUZMAN"],
                    date => "2001-10-26T05:15:43",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Net-AIM",
                    download_url => "https://cpan.metacpan.org/authors/id/E/EN/ENGYONGCHANG/Net-AIM-v1.39.1.tar.gz",
                    first => 0,
                    id => "rqQdTLatQ_oG7pfMFkH5iTDyeN4",
                    license => ["unknown"],
                    likers => ["TAKAONAKANISHI"],
                    likes => 1,
                    main_module => "Net::AIM",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Net-AIM",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => "1.20",
                    },
                    name => "Net-AIM",
                    package => "Net::AIM",
                    provides => [qw( Net::AIM Net::AIM::Connection Net::AIM::Event )],
                    release => "Net-AIM-v1.39.1",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1004073343, size => 22103, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "RrqweA6PwuCJLJN4M1MROm",
                    version => "v1.39.1",
                    version_numified => 1.039001,
                },
                "PDF::Create" => {
                    abstract => "create PDF files",
                    archive => "perl-pdf-v1.90.3.tar.gz",
                    author => "ENGYONGCHANG",
                    authorized => 0,
                    changes_file => "Changes",
                    checksum_md5 => "4410ee7025a69cb56dac9cc98a09ba8f",
                    checksum_sha256 => "339a8c37161f405a21155283a9196342108077db80b0465c487c3d4307583477",
                    date => "2007-02-24T20:29:02",
                    dependency => [],
                    deprecated => 0,
                    distribution => "perl-pdf",
                    download_url => "https://cpan.metacpan.org/authors/id/E/EN/ENGYONGCHANG/perl-pdf-v1.90.3.tar.gz",
                    first => 1,
                    id => "WHYORFLWreKC4YAg4SiRNbKyKEI",
                    license => ["unknown"],
                    likers => ["SAMANDERSON"],
                    likes => 1,
                    main_module => "PDF::Create",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.31, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "PDF-Create",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.06,
                    },
                    name => "perl-pdf",
                    package => "PDF::Create",
                    provides => [],
                    release => "perl-pdf-v1.90.3",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1172348942, size => 32249, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "RrqweA6PwuCJLJN4M1MROm",
                    version => "v1.90.3",
                    version_numified => 1.090003,
                },
                "Tie::FileLRUCache" => {
                    abstract => "A lightweight but robust filesystem based persistent LRU cache",
                    archive => "Tie-FileLRUCache-v1.92.8.tar.gz",
                    author => "ENGYONGCHANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "cbb655ca18844dde054aa973d678cdc2",
                    checksum_sha256 => "3b75e9c3a41c26723a116f0b6d0d88bb5f973b2772211c285b897bd47a808895",
                    contributors => [qw( OLGABOGDANOVA DUANLIN )],
                    date => "1999-06-16T21:05:30",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Tie-FileLRUCache",
                    download_url => "https://cpan.metacpan.org/authors/id/E/EN/ENGYONGCHANG/Tie-FileLRUCache-v1.92.8.tar.gz",
                    first => 1,
                    id => "B_eqkfSlJK9lLIo3mQR_aVKT9QE",
                    license => ["unknown"],
                    likers => ["OLGABOGDANOVA"],
                    likes => 1,
                    main_module => "Tie::FileLRUCache",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Tie-FileLRUCache",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => "1.00",
                    },
                    name => "Tie-FileLRUCache",
                    package => "Tie::FileLRUCache",
                    provides => ["Tie::FileLRUCache"],
                    release => "Tie-FileLRUCache-v1.92.8",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 929567130, size => 5471, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "RrqweA6PwuCJLJN4M1MROm",
                    version => "v1.92.8",
                    version_numified => 1.092008,
                },
            },
            name => "Eng Yong Chang",
            pauseid => "ENGYONGCHANG",
            profile => [{ id => 619562, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "RrqweA6PwuCJLJN4M1MROm",
        },
        FLORABARRETT => {
            asciiname => "Flora Barrett",
            city => "London",
            contributions => [
                {
                    distribution => "Task-App-Physics-ParticleMotion",
                    pauseid => "FLORABARRETT",
                    release_author => "HEHERSONDEGUZMAN",
                    release_name => "Task-App-Physics-ParticleMotion-v2.3.4",
                },
                {
                    distribution => "Catalyst",
                    pauseid => "FLORABARRETT",
                    release_author => "YOHEIFUJIWARA",
                    release_name => "Catalyst-v1.92.2",
                },
                {
                    distribution => "XML-Twig",
                    pauseid => "FLORABARRETT",
                    release_author => "CHRISTIANREYES",
                    release_name => "XML-Twig-v0.68.15",
                },
                {
                    distribution => "Facebook-Graph",
                    pauseid => "FLORABARRETT",
                    release_author => "TAKASHIISHIKAWA",
                    release_name => "Facebook-Graph-v0.38.18",
                },
                {
                    distribution => "FileHandle-Rollback",
                    pauseid => "FLORABARRETT",
                    release_author => "AFONASEIANTONOV",
                    release_name => "FileHandle-Rollback-v0.88.10",
                },
                {
                    distribution => "DBIx-Custom-SQLite",
                    pauseid => "FLORABARRETT",
                    release_author => "WANTAN",
                    release_name => "DBIx-Custom-SQLite-0.2",
                },
                {
                    distribution => "math-image",
                    pauseid => "FLORABARRETT",
                    release_author => "SAMANDERSON",
                    release_name => "math-image-v2.97.1",
                },
                {
                    distribution => "giza",
                    pauseid => "FLORABARRETT",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "giza-0.35",
                },
            ],
            country => "UK",
            email => ["flora.barrett\@example.uk"],
            favorites => [
                {
                    author => "TAKASHIISHIKAWA",
                    date => "2002-03-29T09:50:49",
                    distribution => "DBIx-dbMan",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/LGpdWqlvgc6p6SgUEZluCc3eDVH5zShL?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/F/FL/FLORABARRETT",
                cpan_directory => "http://cpan.org/authors/id/F/FL/FLORABARRETT",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=FLORABARRETT",
                cpantesters_reports => "http://cpantesters.org/author/F/FLORABARRETT.html",
                cpants => "http://cpants.cpanauthors.org/author/FLORABARRETT",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/FLORABARRETT",
                repology => "https://repology.org/maintainer/FLORABARRETT%40cpan",
            },
            modules => {
                "Date::EzDate" => {
                    abstract => "Date manipulation made easy.",
                    archive => "Date-EzDate-0.51.tar.gz",
                    author => "FLORABARRETT",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "6960e67e20687f24542be53a9d60ff2d",
                    checksum_sha256 => "9e2b714fb4bf89fdedb17662ab098d96f4f20b57e3143005095cac1646cfb1ab",
                    contributors => [qw( ALEXANDRAPOWELL RACHELSEGAL ANTHONYGOYETTE )],
                    date => "2002-02-10T02:56:54",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Date-EzDate",
                    download_url => "https://cpan.metacpan.org/authors/id/F/FL/FLORABARRETT/Date-EzDate-0.51.tar.gz",
                    first => 0,
                    id => "N4GYRNfeeZp80xE2RxaDuCghE58",
                    license => ["unknown"],
                    likers => [qw( TEDDYSAPUTRA YOHEIFUJIWARA ANTHONYGOYETTE RANGSANSUNTHORN )],
                    likes => 4,
                    main_module => "Date::EzDate",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Date-EzDate",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.92,
                    },
                    name => "Date-EzDate",
                    package => "Date::EzDate",
                    provides => [qw( Date::EzDate Date::EzDateTie )],
                    release => "Date-EzDate-0.51",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1013309814, size => 12735, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 2, unknown => 0 },
                    user => "DPredH46xq6IrOOG5vefND",
                    version => 0.51,
                    version_numified => "0.510",
                },
                "PAR::Filter::Squish" => {
                    abstract => "PAR filter for reducing code size",
                    archive => "PAR-Filter-Squish-v2.52.6.tar.gz",
                    author => "FLORABARRETT",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "9cb308aeea786d5e567252d60f65d320",
                    checksum_sha256 => "9b26961162bd48e8ae6b7473a73d11ae3d2a5d7d35b338bb86b84fdf64162adf",
                    contributors => [qw( MARINAHOTZ MINSUNGJUNG )],
                    date => "2006-08-14T15:09:30",
                    dependency => [
                        {
                            module => "Perl::Squish",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.02,
                        },
                        {
                            module => "PAR",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.94,
                        },
                    ],
                    deprecated => 0,
                    distribution => "PAR-Filter-Squish",
                    download_url => "https://cpan.metacpan.org/authors/id/F/FL/FLORABARRETT/PAR-Filter-Squish-v2.52.6.tar.gz",
                    first => 1,
                    id => "8rf5z7807pOOIZRUaMo00RjTK28",
                    license => ["perl_5"],
                    likers => ["MARINAHOTZ"],
                    likes => 1,
                    main_module => "PAR::Filter::Squish",
                    maturity => "released",
                    metadata => {
                        abstract => "PAR filter for reducing code size",
                        author => ["Steffen Mueller (smueller\@cpan.org)"],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.63, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "PAR-Filter-Squish",
                        no_index => {
                            directory => [qw( inc t t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => { PAR => 0.94, "Perl::Squish" => 0.02 },
                            },
                        },
                        release_status => "stable",
                        version => 0.01,
                    },
                    name => "PAR-Filter-Squish",
                    package => "PAR::Filter::Squish",
                    provides => ["PAR::Filter::Squish"],
                    release => "PAR-Filter-Squish-v2.52.6",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1155568170, size => 11614, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "DPredH46xq6IrOOG5vefND",
                    version => "v2.52.6",
                    version_numified => 2.052006,
                },
                "PAR::Repository" => {
                    abstract => "Create and modify PAR repositories",
                    archive => "PAR-Repository-0.23.tar.gz",
                    author => "FLORABARRETT",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "1db1f4a66cf63d08f0218427857e178b",
                    checksum_sha256 => "d1ffedaddcdeb234c403eb819bb2f33c235007bf2443b4ff1399dfbeca54e7ab",
                    contributors => [qw( RANGSANSUNTHORN MINSUNGJUNG )],
                    date => "2006-09-14T08:29:46",
                    dependency => [
                        {
                            module => "File::Temp",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::Manifest",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "version",
                            phase => "runtime",
                            relationship => "requires",
                            version => "0.50",
                        },
                        {
                            module => "YAML::Syck",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.62,
                        },
                        {
                            module => "DBM::Deep",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Pod::Text",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Copy",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "PAR::Dist",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.18,
                        },
                        {
                            module => "File::Path",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Spec",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Archive::Zip",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "PAR-Repository",
                    download_url => "https://cpan.metacpan.org/authors/id/F/FL/FLORABARRETT/PAR-Repository-0.23.tar.gz",
                    first => 0,
                    id => "CSycqMi6S4ZtLj1TZ3x94AfljGU",
                    license => ["unknown"],
                    likers => [qw( HUWANATIENZA YOHEIFUJIWARA )],
                    likes => 2,
                    main_module => "PAR::Repository",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.30, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "PAR-Repository",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => {
                                    "Archive::Zip" => 0,
                                    "DBM::Deep" => 0,
                                    "ExtUtils::Manifest" => 0,
                                    "File::Copy" => 0,
                                    "File::Path" => 0,
                                    "File::Spec" => 0,
                                    "File::Temp" => 0,
                                    "PAR::Dist" => 0.18,
                                    "Pod::Text" => 0,
                                    version => "0.50",
                                    "YAML::Syck" => 0.62,
                                },
                            },
                        },
                        release_status => "stable",
                        version => 0.12,
                        x_installdirs => "site",
                        x_version_from => "lib/PAR/Repository.pm",
                    },
                    name => "PAR-Repository",
                    package => "PAR::Repository",
                    provides => [qw(
                        PAR::Repository PAR::Repository::DBM
                        PAR::Repository::Query PAR::Repository::ScanPAR
                        PAR::Repository::Zip
                    )],
                    release => "PAR-Repository-0.23",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1158222586, size => 20520, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 1, unknown => 0 },
                    user => "DPredH46xq6IrOOG5vefND",
                    version => 0.23,
                    version_numified => "0.230",
                },
                "Validator::Custom::Ext::Mojolicious" => {
                    abstract => "Validator for Mojolicious",
                    archive => "Validator-Custom-Ext-Mojolicious-0.63.tar.gz",
                    author => "FLORABARRETT",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "a294f6f21b1935d8c8d7f942ad2c1792",
                    checksum_sha256 => "0911fe6ae65f9173c6eb68b6116600552b088939b94881be3c7275344b1cbdce",
                    date => "2010-01-16T14:51:11",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Object::Simple",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2.1203,
                        },
                        {
                            module => "Validator::Custom",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.0701,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Validator-Custom-Ext-Mojolicious",
                    download_url => "https://cpan.metacpan.org/authors/id/F/FL/FLORABARRETT/Validator-Custom-Ext-Mojolicious-0.63.tar.gz",
                    first => 0,
                    id => "mY_jP2O7NnTtr3utv_xZQNu10Ic",
                    license => ["perl_5"],
                    likers => ["ALEXANDRAPOWELL"],
                    likes => 1,
                    main_module => "Validator::Custom::Ext::Mojolicious",
                    maturity => "released",
                    metadata => {
                        abstract => "Validator for Mojolicious",
                        author => ["Yuki Kimoto <kimoto.yuki\@gmail.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.31012, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Validator-Custom-Ext-Mojolicious",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                requires => { "Object::Simple" => 2.1203, "Validator::Custom" => 0.0701 },
                            },
                        },
                        provides => {
                            "Validator::Custom::Ext::Mojolicious" => {
                                file => "lib/Validator/Custom/Ext/Mojolicious.pm",
                                version => 0.0103,
                            },
                        },
                        release_status => "stable",
                        resources => {},
                        version => 0.0103,
                    },
                    name => "Validator-Custom-Ext-Mojolicious",
                    package => "Validator::Custom::Ext::Mojolicious",
                    provides => ["Validator::Custom::Ext::Mojolicious"],
                    release => "Validator-Custom-Ext-Mojolicious-0.63",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1263653471, size => 4190, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 1, na => 0, pass => 17, unknown => 0 },
                    user => "DPredH46xq6IrOOG5vefND",
                    version => 0.63,
                    version_numified => "0.630",
                },
            },
            name => "Flora Barrett",
            pauseid => "FLORABARRETT",
            profile => [{ id => 1042091, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "DPredH46xq6IrOOG5vefND",
        },
        HEHERSONDEGUZMAN => {
            asciiname => "Heherson Deguzman",
            city => "Quezon City",
            contributions => [
                {
                    distribution => "Math-BooleanEval",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "KANTSOMSRISATI",
                    release_name => "Math-BooleanEval-2.85",
                },
                {
                    distribution => "Text-Match-FastAlternatives",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "OLGABOGDANOVA",
                    release_name => "Text-Match-FastAlternatives-v1.88.18",
                },
                {
                    distribution => "Var-State",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "BUDAEJUNG",
                    release_name => "Var-State-v0.44.6",
                },
                {
                    distribution => "p5-Palm",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "YOICHIFUJITA",
                    release_name => "p5-Palm-2.38",
                },
                {
                    distribution => "XML-Parser",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "XML-Parser-2.78",
                },
                {
                    distribution => "DTS",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "WANTAN",
                    release_name => "DTS-0.64",
                },
                {
                    distribution => "MooseX-Log-Log4perl",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "SIEUNJANG",
                    release_name => "MooseX-Log-Log4perl-1.20",
                },
                {
                    distribution => "Task-Dancer",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "LILLIANSTEWART",
                    release_name => "Task-Dancer-2.83",
                },
                {
                    distribution => "Net-AIM",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "ENGYONGCHANG",
                    release_name => "Net-AIM-v1.39.1",
                },
                {
                    distribution => "PAR-Dist-InstallPPD-GUI",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "ELAINAREYES",
                    release_name => "PAR-Dist-InstallPPD-GUI-2.42",
                },
                {
                    distribution => "Catalyst-Plugin-XMLRPC",
                    pauseid => "HEHERSONDEGUZMAN",
                    release_author => "ANTHONYGOYETTE",
                    release_name => "Catalyst-Plugin-XMLRPC-0.86",
                },
            ],
            country => "PH",
            email => ["heherson.deguzman\@example.ph"],
            favorites => [
                {
                    author => "HUWANATIENZA",
                    date => "2006-02-21T16:23:24",
                    distribution => "HTML-TreeBuilder-XPath",
                },
                {
                    author => "OLGABOGDANOVA",
                    date => "2006-12-23T16:33:11",
                    distribution => "Text-Match-FastAlternatives",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/AG8RNv5bo9d0en6PXWMG17WxaqN3kkyO?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/H/HE/HEHERSONDEGUZMAN",
                cpan_directory => "http://cpan.org/authors/id/H/HE/HEHERSONDEGUZMAN",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=HEHERSONDEGUZMAN",
                cpantesters_reports => "http://cpantesters.org/author/H/HEHERSONDEGUZMAN.html",
                cpants => "http://cpants.cpanauthors.org/author/HEHERSONDEGUZMAN",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/HEHERSONDEGUZMAN",
                repology => "https://repology.org/maintainer/HEHERSONDEGUZMAN%40cpan",
            },
            modules => {
                "Catalyst::Plugin::Ajax" => {
                    abstract => "Plugin for Ajax",
                    archive => "Catalyst-Plugin-Ajax-v1.30.0.tar.gz",
                    author => "HEHERSONDEGUZMAN",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "b516d226c73ed98c58c65359ce29957b",
                    checksum_sha256 => "67a0f292b19a2542c690bff087698294cd57f2a1988940a2f5472af058de8c2d",
                    contributors => ["DOHYUNNCHOI"],
                    date => "2005-03-23T00:39:39",
                    dependency => [
                        {
                            module => "Catalyst",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Catalyst-Plugin-Ajax",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HE/HEHERSONDEGUZMAN/Catalyst-Plugin-Ajax-v1.30.0.tar.gz",
                    first => 1,
                    id => "H7qM0cPJKHuuTtud3uMsE7qlbkY",
                    license => ["unknown"],
                    likers => [qw( YOICHIFUJITA OLGABOGDANOVA )],
                    likes => 2,
                    main_module => "Catalyst::Plugin::Ajax",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.17, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Catalyst-Plugin-Ajax",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => { Catalyst => 0 },
                            },
                        },
                        release_status => "stable",
                        version => 0.01,
                        x_installdirs => "site",
                        x_version_from => "Ajax.pm",
                    },
                    name => "Catalyst-Plugin-Ajax",
                    package => "Catalyst::Plugin::Ajax",
                    provides => ["Catalyst::Plugin::Ajax"],
                    release => "Catalyst-Plugin-Ajax-v1.30.0",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1111538379, size => 2795, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "sdD6qcn0w0oqK6fdDAka23",
                    version => "v1.30.0",
                    version_numified => "1.030000",
                },
                "Net::Lite::FTP" => {
                    abstract => "Perl FTP client with support for TLS",
                    archive => "Net-Lite-FTP-v2.56.8.tar.gz",
                    author => "HEHERSONDEGUZMAN",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "e810bd926e5a25eb7f791d434f28ef57",
                    checksum_sha256 => "0abf70ce18bb8dc9640f3b0b628ea18c5c22bbb48c866b8de1b4b05ecda7164d",
                    contributors => ["RACHELSEGAL"],
                    date => "2006-06-22T18:12:35",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Net-Lite-FTP",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HE/HEHERSONDEGUZMAN/Net-Lite-FTP-v2.56.8.tar.gz",
                    first => 0,
                    id => "9p_xfNffYCMX8VLemvJkAYbNvH0",
                    license => ["unknown"],
                    likers => [qw( ALESSANDROBAUMANN RANGSANSUNTHORN )],
                    likes => 2,
                    main_module => "Net::Lite::FTP",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Net-Lite-FTP",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.45,
                    },
                    name => "Net-Lite-FTP",
                    package => "Net::Lite::FTP",
                    provides => ["Net::Lite::FTP"],
                    release => "Net-Lite-FTP-v2.56.8",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1150999955, size => 10240, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 1, unknown => 0 },
                    user => "sdD6qcn0w0oqK6fdDAka23",
                    version => "v2.56.8",
                    version_numified => 2.056008,
                },
                "Task::App::Physics::ParticleMotion" => {
                    abstract => "All modules required for the tk-motion application",
                    archive => "Task-App-Physics-ParticleMotion-v2.3.4.tar.gz",
                    author => "HEHERSONDEGUZMAN",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "d44225e17a841d68915535f93e0d2da2",
                    checksum_sha256 => "aaaef116f9e3071016ad24329322cea4d53afc61af82dac4ffe6326b210f1b1a",
                    contributors => [qw( FLORABARRETT TAKASHIISHIKAWA )],
                    date => "2005-12-10T19:27:19",
                    dependency => [
                        {
                            module => "Math::Project3D",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "App::Physics::ParticleMotion",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Math::Symbolic",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.163,
                        },
                        {
                            module => "Tk",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Config::Tiny",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => "v5.6.1",
                        },
                        {
                            module => "Math::RungeKutta",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Tk::Cloth",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::Pod",
                            phase => "build",
                            relationship => "requires",
                            version => 1,
                        },
                        {
                            module => "Test::Pod::Coverage",
                            phase => "build",
                            relationship => "requires",
                            version => 1,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Task-App-Physics-ParticleMotion",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HE/HEHERSONDEGUZMAN/Task-App-Physics-ParticleMotion-v2.3.4.tar.gz",
                    first => 1,
                    id => "0ZhjAtkDIT6Maszn4idJzw3UnBk",
                    license => ["perl_5"],
                    likers => ["ALESSANDROBAUMANN"],
                    likes => 1,
                    main_module => "Task::App::Physics::ParticleMotion",
                    maturity => "released",
                    metadata => {
                        abstract => "All modules required for the tk-motion application",
                        author => ["Steffen Mueller"],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.39, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Task-App-Physics-ParticleMotion",
                        no_index => {
                            directory => [qw( inc t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::Pod" => 1, "Test::Pod::Coverage" => 1 },
                            },
                            runtime => {
                                requires => {
                                    "App::Physics::ParticleMotion" => 0,
                                    "Config::Tiny" => 0,
                                    "Math::Project3D" => 0,
                                    "Math::RungeKutta" => 0,
                                    "Math::Symbolic" => 0.163,
                                    perl => "v5.6.1",
                                    Tk => 0,
                                    "Tk::Cloth" => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        version => "1.00",
                    },
                    name => "Task-App-Physics-ParticleMotion",
                    package => "Task::App::Physics::ParticleMotion",
                    provides => ["Task::App::Physics::ParticleMotion"],
                    release => "Task-App-Physics-ParticleMotion-v2.3.4",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1134242839, size => 13599, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "sdD6qcn0w0oqK6fdDAka23",
                    version => "v2.3.4",
                    version_numified => 2.003004,
                },
                "Test::Spec" => {
                    abstract => "Write tests in a declarative specification style",
                    archive => "Test-Spec-v1.5.0.tar.gz",
                    author => "HEHERSONDEGUZMAN",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "3612f52f7d7fa4c9a5bc7f762d8ece55",
                    checksum_sha256 => "9c879f6e12f6588e0130ae5e4af2ce925689f692c63778294e334fddf734c565",
                    contributors => ["DUANLIN"],
                    date => "2011-05-19T20:18:35",
                    dependency => [
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::Deep",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.103,
                        },
                        {
                            module => "constant",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Package::Stash",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.23,
                        },
                        {
                            module => "Exporter",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::Trap",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Tie::IxHash",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::More",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Moose",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "List::Util",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Carp",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Test-Spec",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HE/HEHERSONDEGUZMAN/Test-Spec-v1.5.0.tar.gz",
                    first => 1,
                    id => "oMtWAO1BAGQRV_XqZuUyxtWmZ_s",
                    license => ["unknown"],
                    likers => [qw( TEDDYSAPUTRA TEDDYSAPUTRA LILLIANSTEWART )],
                    likes => 3,
                    main_module => "Test::Spec",
                    maturity => "released",
                    metadata => {
                        abstract => "Write tests in a declarative specification style",
                        author => ["Philip Garrett <philip.garrett\@icainformatics.com>"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.54, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Test-Spec",
                        no_index => {
                            directory => [qw( t inc t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            runtime => {
                                requires => {
                                    Carp => 0,
                                    constant => 0,
                                    Exporter => 0,
                                    "List::Util" => 0,
                                    Moose => 0,
                                    "Package::Stash" => 0.23,
                                    "Test::Deep" => 0.103,
                                    "Test::More" => 0,
                                    "Test::Trap" => 0,
                                    "Tie::IxHash" => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        version => 0.28,
                    },
                    name => "Test-Spec",
                    package => "Test::Spec",
                    provides => [qw(
                        Test::Spec Test::Spec::Context Test::Spec::ExportProxy
                        Test::Spec::Mocks Test::Spec::Mocks::Expectation
                        Test::Spec::Mocks::MockObject Test::Spec::Mocks::Stub
                    )],
                    release => "Test-Spec-v1.5.0",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1305836315, size => 22477, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 2, pass => 95, unknown => 0 },
                    user => "sdD6qcn0w0oqK6fdDAka23",
                    version => "v1.5.0",
                    version_numified => "1.005000",
                },
                "Text::Record::Deduper" => {
                    abstract => "Separate complete, partial and near duplicate text records",
                    archive => "Text-Record-Deduper-0.69.tar.gz",
                    author => "HEHERSONDEGUZMAN",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "0e841235d7c7ac62f26f0beb48505df9",
                    checksum_sha256 => "2d5af19048f2eeaddf22ccb688d001a3ff57ff3db1d2ee6554e92b175d8a69ae",
                    date => "2011-01-31T04:31:42",
                    dependency => [
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Text-Record-Deduper",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HE/HEHERSONDEGUZMAN/Text-Record-Deduper-0.69.tar.gz",
                    first => 0,
                    id => "ihb7avPsQ9c0Io923nlbUEIfTB0",
                    license => ["unknown"],
                    likers => [qw( HELEWISEGIROUX ENGYONGCHANG )],
                    likes => 2,
                    main_module => "Text::Record::Deduper",
                    maturity => "released",
                    metadata => {
                        abstract => "Separate complete, partial and near duplicate text records",
                        author => ["Kim Ryan"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.56, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Text-Record-Deduper",
                        no_index => {
                            directory => [qw( t inc t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            runtime => { requires => {} },
                        },
                        release_status => "stable",
                        version => 0.06,
                    },
                    name => "Text-Record-Deduper",
                    package => "Text::Record::Deduper",
                    provides => ["Text::Record::Deduper"],
                    release => "Text-Record-Deduper-0.69",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1296448302, size => 9850, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 1, pass => 112, unknown => 0 },
                    user => "sdD6qcn0w0oqK6fdDAka23",
                    version => 0.69,
                    version_numified => "0.690",
                },
            },
            name => "Heherson Deguzman",
            pauseid => "HEHERSONDEGUZMAN",
            profile => [{ id => 556469, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "sdD6qcn0w0oqK6fdDAka23",
        },
        HELEWISEGIROUX => {
            asciiname => "Helewise Giroux",
            city => "Lille",
            contributions => [
                {
                    distribution => "DBIx-Custom-Result",
                    pauseid => "HELEWISEGIROUX",
                    release_author => "KANTSOMSRISATI",
                    release_name => "DBIx-Custom-Result-v2.80.14",
                },
                {
                    distribution => "Math-Symbolic-Custom-Pattern",
                    pauseid => "HELEWISEGIROUX",
                    release_author => "TEDDYSAPUTRA",
                    release_name => "Math-Symbolic-Custom-Pattern-v1.68.6",
                },
                {
                    distribution => "Apache-XPointer",
                    pauseid => "HELEWISEGIROUX",
                    release_author => "AFONASEIANTONOV",
                    release_name => "Apache-XPointer-2.18",
                },
                {
                    distribution => "DBIx-Custom-MySQL",
                    pauseid => "HELEWISEGIROUX",
                    release_author => "TEDDYSAPUTRA",
                    release_name => "DBIx-Custom-MySQL-1.40",
                },
            ],
            country => "FR",
            email => ["helewise.giroux\@example.fr"],
            favorites => [
                {
                    author => "RACHELSEGAL",
                    date => "2010-06-07T14:43:36",
                    distribution => "Dist-Zilla-Plugin-ProgCriticTests",
                },
                {
                    author => "WEEWANG",
                    date => "2006-02-16T15:46:14",
                    distribution => "App-Build",
                },
                {
                    author => "HEHERSONDEGUZMAN",
                    date => "2011-01-31T04:31:42",
                    distribution => "Text-Record-Deduper",
                },
                {
                    author => "DOHYUNNCHOI",
                    date => "2009-10-29T11:22:47",
                    distribution => "CGI-DataObjectMapper",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/WZeAIdwlhcDjfTxFs0g4YqfodQK8dVLz?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/H/HE/HELEWISEGIROUX",
                cpan_directory => "http://cpan.org/authors/id/H/HE/HELEWISEGIROUX",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=HELEWISEGIROUX",
                cpantesters_reports => "http://cpantesters.org/author/H/HELEWISEGIROUX.html",
                cpants => "http://cpants.cpanauthors.org/author/HELEWISEGIROUX",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/HELEWISEGIROUX",
                repology => "https://repology.org/maintainer/HELEWISEGIROUX%40cpan",
            },
            modules => {
                "Math::SymbolicX::NoSimplification" => {
                    abstract => "Turn off Math::Symbolic simplification",
                    archive => "Math-SymbolicX-NoSimplification-v2.85.13.tar.gz",
                    author => "HELEWISEGIROUX",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "63a8a430b82bcf4425345d4977f1b582",
                    checksum_sha256 => "66d3b3d38b765fee1118fc92933e2a94ead3d3b93fed071fda3fab25f3cf3c1b",
                    contributors => ["MINSUNGJUNG"],
                    date => "2005-01-19T13:40:28",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Math::Symbolic",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.128,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Math-SymbolicX-NoSimplification",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HE/HELEWISEGIROUX/Math-SymbolicX-NoSimplification-v2.85.13.tar.gz",
                    first => 1,
                    id => "Qm_WLaClplfRggKIKpKiV2MayAU",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Math::SymbolicX::NoSimplification",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.17, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Math-SymbolicX-NoSimplification",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => { "Math::Symbolic" => 0.128, "Test::More" => 0 },
                            },
                        },
                        release_status => "stable",
                        version => 0.01,
                        x_installdirs => "site",
                        x_version_from => "lib/Math/SymbolicX/NoSimplification.pm",
                    },
                    name => "Math-SymbolicX-NoSimplification",
                    package => "Math::SymbolicX::NoSimplification",
                    provides => ["Math::SymbolicX::NoSimplification"],
                    release => "Math-SymbolicX-NoSimplification-v2.85.13",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1106142028, size => 3263, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 6, unknown => 0 },
                    user => "Z4BNBAuuha9iQd6c4hMcjY",
                    version => "v2.85.13",
                    version_numified => 2.085013,
                },
                "POE::Component::Client::Keepalive" => {
                    abstract => "Manages and keeps alive client connections",
                    archive => "POE-Component-Client-Keepalive-1.69.tar.gz",
                    author => "HELEWISEGIROUX",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "ba3f16a560b57d7c8fa173998e72ee84",
                    checksum_sha256 => "c03f9361faf89f4fa5d3a409476853ee597cbadda9733ca624b971d78370203d",
                    contributors => [qw( ENGYONGCHANG WANTAN WANTAN )],
                    date => "2009-10-14T07:12:29",
                    dependency => [
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "POE",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.28,
                        },
                        {
                            module => "Net::IP",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.25,
                        },
                        {
                            module => "POE::Component::Client::DNS",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.051,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "POE-Component-Client-Keepalive",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HE/HELEWISEGIROUX/POE-Component-Client-Keepalive-1.69.tar.gz",
                    first => 0,
                    id => "CHGm6vorbDhiY5yeuAAnkXFmWG0",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "POE::Component::Client::Keepalive",
                    maturity => "released",
                    metadata => {
                        abstract => "Manages and keeps alive client connections",
                        author => ["Rocco Caputo <rcaputo\@cpan.org>"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.54, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "POE-Component-Client-Keepalive",
                        no_index => {
                            directory => [qw(
                                t inc mylib t xt inc local perl5 fatlib example blib
                                examples eg
                            )],
                        },
                        prereqs => {
                            build => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            runtime => {
                                requires => { "Net::IP" => 1.25, POE => 1.28, "POE::Component::Client::DNS" => 1.051 },
                            },
                        },
                        release_status => "stable",
                        resources => {
                            license => ["http://dev.perl.org/licenses/"],
                            repository => {
                                url => "http://github.com/rcaputo/poe-component-client-keepalive",
                            },
                        },
                        version => 0.261,
                    },
                    name => "POE-Component-Client-Keepalive",
                    package => "POE::Component::Client::Keepalive",
                    provides => [qw(
                        POE::Component::Client::Keepalive
                        POE::Component::Connection::Keepalive
                    )],
                    release => "POE-Component-Client-Keepalive-1.69",
                    resources => {
                        license => ["http://dev.perl.org/licenses/"],
                        repository => {
                            url => "http://github.com/rcaputo/poe-component-client-keepalive",
                        },
                    },
                    stat => { gid => 1009, mode => 33204, mtime => 1255504349, size => 25142, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 24, na => 1, pass => 22, unknown => 0 },
                    user => "Z4BNBAuuha9iQd6c4hMcjY",
                    version => 1.69,
                    version_numified => "1.690",
                },
                "Validator::Custom" => {
                    abstract => "Validates user input easily",
                    archive => "Validator-Custom-2.26.tar.gz",
                    author => "HELEWISEGIROUX",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "16b439ab06da5935d61ae9fd18aab3a4",
                    checksum_sha256 => "f599da2ecc17ac74443628eb84233ee6b25b204511f83ea778dad9efd0f558e0",
                    contributors => ["DOHYUNNCHOI"],
                    date => "2010-07-28T13:42:23",
                    dependency => [
                        {
                            module => "Object::Simple",
                            phase => "runtime",
                            relationship => "requires",
                            version => 3.0302,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Validator-Custom",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HE/HELEWISEGIROUX/Validator-Custom-2.26.tar.gz",
                    first => 0,
                    id => "NWJOqmjEinjfJqawfpkEpEhu4d0",
                    license => ["perl_5"],
                    likers => ["DOHYUNNCHOI"],
                    likes => 1,
                    main_module => "Validator::Custom",
                    maturity => "released",
                    metadata => {
                        abstract => "Validates user input easily",
                        author => ["Yuki Kimoto <kimoto.yuki\@gmail.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.31012, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Validator-Custom",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                requires => { "Object::Simple" => 3.0302 },
                            },
                        },
                        provides => {
                            "Validator::Custom" => { file => "lib/Validator/Custom.pm", version => 0.1207 },
                            "Validator::Custom::Basic::Constraints" => { file => "lib/Validator/Custom/Basic/Constraints.pm" },
                            "Validator::Custom::Result" => { file => "lib/Validator/Custom/Result.pm" },
                        },
                        release_status => "stable",
                        resources => {},
                        version => 0.1207,
                    },
                    name => "Validator-Custom",
                    package => "Validator::Custom",
                    provides => [qw(
                        Validator::Custom Validator::Custom::Basic::Constraints
                        Validator::Custom::Result
                    )],
                    release => "Validator-Custom-2.26",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1280324543, size => 16985, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 35, unknown => 0 },
                    user => "Z4BNBAuuha9iQd6c4hMcjY",
                    version => 2.26,
                    version_numified => "2.260",
                },
                "VMware::API::LabManager" => {
                    abstract => "VMware's Lab Manager public and private API",
                    archive => "VMware-API-LabManager-2.96.tar.gz",
                    author => "HELEWISEGIROUX",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "44a3989150973d97cc63eeae92c8dd0e",
                    checksum_sha256 => "e79f29fe990ba99344cc9b39c4b4ee6afbf88ba271ff6ad239dd8d592117b6c5",
                    contributors => ["MINSUNGJUNG"],
                    date => "2010-07-28T06:20:38",
                    dependency => [
                        {
                            module => "SOAP::Lite",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "VMware-API-LabManager",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HE/HELEWISEGIROUX/VMware-API-LabManager-2.96.tar.gz",
                    first => 0,
                    id => "1OvE2HxBwzIHWCyMXJmN8Zx5si0",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "VMware::API::LabManager",
                    maturity => "released",
                    metadata => {
                        abstract => "VMware's Lab Manager public and private API",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.17, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "VMware-API-LabManager",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => { "SOAP::Lite" => 0 },
                            },
                        },
                        release_status => "stable",
                        version => 1.2,
                        x_installdirs => "site",
                        x_version_from => "lib/VMware/API/LabManager.pm",
                    },
                    name => "VMware-API-LabManager",
                    package => "VMware::API::LabManager",
                    provides => ["VMware::API::LabManager"],
                    release => "VMware-API-LabManager-2.96",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1280298038, size => 11029, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 40, na => 0, pass => 0, unknown => 0 },
                    user => "Z4BNBAuuha9iQd6c4hMcjY",
                    version => 2.96,
                    version_numified => "2.960",
                },
            },
            name => "Helewise Giroux",
            pauseid => "HELEWISEGIROUX",
            profile => [{ id => 1319134, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "Z4BNBAuuha9iQd6c4hMcjY",
        },
        HUWANATIENZA => {
            asciiname => "Huwan Atienza",
            city => "Quezon City",
            contributions => [
                {
                    distribution => "Compress-Bzip2",
                    pauseid => "HUWANATIENZA",
                    release_author => "DOHYUNNCHOI",
                    release_name => "Compress-Bzip2-v2.0.11",
                },
                {
                    distribution => "Lingua-Stem",
                    pauseid => "HUWANATIENZA",
                    release_author => "DOHYUNNCHOI",
                    release_name => "Lingua-Stem-v2.44.2",
                },
                {
                    distribution => "Text-Match-FastAlternatives",
                    pauseid => "HUWANATIENZA",
                    release_author => "OLGABOGDANOVA",
                    release_name => "Text-Match-FastAlternatives-v1.88.18",
                },
                {
                    distribution => "PAR-Dist-InstallPPD-GUI",
                    pauseid => "HUWANATIENZA",
                    release_author => "ELAINAREYES",
                    release_name => "PAR-Dist-InstallPPD-GUI-2.42",
                },
                {
                    distribution => "Devel-SmallProf",
                    pauseid => "HUWANATIENZA",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "Devel-SmallProf-v2.41.7",
                },
                {
                    distribution => "App-gh",
                    pauseid => "HUWANATIENZA",
                    release_author => "MARINAHOTZ",
                    release_name => "App-gh-2.3",
                },
                {
                    distribution => "p5-Palm",
                    pauseid => "HUWANATIENZA",
                    release_author => "YOICHIFUJITA",
                    release_name => "p5-Palm-2.38",
                },
                {
                    distribution => "Tk-Pod",
                    pauseid => "HUWANATIENZA",
                    release_author => "SIEUNJANG",
                    release_name => "Tk-Pod-2.56",
                },
            ],
            country => "PH",
            email => ["huwan.atienza\@example.ph"],
            favorites => [
                {
                    author => "FLORABARRETT",
                    date => "2006-09-14T08:29:46",
                    distribution => "PAR-Repository",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/BldUO9OTh0CnGCBN4ZZEPl6R5H9XPKQV?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/H/HU/HUWANATIENZA",
                cpan_directory => "http://cpan.org/authors/id/H/HU/HUWANATIENZA",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=HUWANATIENZA",
                cpantesters_reports => "http://cpantesters.org/author/H/HUWANATIENZA.html",
                cpants => "http://cpants.cpanauthors.org/author/HUWANATIENZA",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/HUWANATIENZA",
                repology => "https://repology.org/maintainer/HUWANATIENZA%40cpan",
            },
            modules => {
                "HTML::TreeBuilder::XPath" => {
                    abstract => "add XPath support to HTML::TreeBuilder",
                    archive => "HTML-TreeBuilder-XPath-2.39.tar.gz",
                    author => "HUWANATIENZA",
                    authorized => 0,
                    changes_file => "Changes",
                    checksum_md5 => "ac6a01ce6b2a727758705ba2406c250f",
                    checksum_sha256 => "8e9693f7a7b3b9eff4dcf969b96e8a1428a681bfcf8203da00b08b9568a99184",
                    contributors => ["RACHELSEGAL"],
                    date => "2006-02-21T16:23:24",
                    dependency => [],
                    deprecated => 0,
                    distribution => "HTML-TreeBuilder-XPath",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HU/HUWANATIENZA/HTML-TreeBuilder-XPath-2.39.tar.gz",
                    first => 1,
                    id => "SOgZMPMkkb83sleBa3VtArrVOn4",
                    license => ["unknown"],
                    likers => ["HEHERSONDEGUZMAN"],
                    likes => 1,
                    main_module => "HTML::TreeBuilder::XPath",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.30_01, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "HTML-TreeBuilder-XPath",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.01,
                        x_installdirs => "site",
                        x_version_from => "lib/HTML/TreeBuilder/XPath.pm",
                    },
                    name => "HTML-TreeBuilder-XPath",
                    package => "HTML::TreeBuilder::XPath",
                    provides => [qw(
                        HTML::TreeBuilder::XPath
                        HTML::TreeBuilder::XPath::Attribute
                        HTML::TreeBuilder::XPath::Node
                        HTML::TreeBuilder::XPath::Root
                        HTML::TreeBuilder::XPath::TextNode
                    )],
                    release => "HTML-TreeBuilder-XPath-2.39",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1140539004, size => 5841, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 2, na => 0, pass => 1, unknown => 0 },
                    user => "AnC1OYZoawNEhaBbxU2G8i",
                    version => 2.39,
                    version_numified => "2.390",
                },
                "Math::SymbolicX::Error" => {
                    abstract => "Parser extension for dealing with numeric errors",
                    archive => "Math-SymbolicX-Error-v1.2.13.tar.gz",
                    author => "HUWANATIENZA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "6f62e46c9a2a332bd8e7485866d70512",
                    checksum_sha256 => "55136aa4e042db53251ff462b0d0eba49c0c338cb1fdf88d5f0e6dc5b654aaff",
                    contributors => [qw( SIEUNJANG LILLIANSTEWART )],
                    date => "2006-04-21T14:08:42",
                    dependency => [
                        {
                            module => "Math::Symbolic",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.129,
                        },
                        {
                            module => "Number::WithError",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.04,
                        },
                        {
                            module => "Test::More",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.44,
                        },
                        {
                            module => "Parse::RecDescent",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Math::SymbolicX::ParserExtensionFactory",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.01,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Math-SymbolicX-Error",
                    download_url => "https://cpan.metacpan.org/authors/id/H/HU/HUWANATIENZA/Math-SymbolicX-Error-v1.2.13.tar.gz",
                    first => 1,
                    id => "XZck_vLPZbxlJ1zMsgEgsw8EszM",
                    license => ["unknown"],
                    likers => ["ELAINAREYES"],
                    likes => 1,
                    main_module => "Math::SymbolicX::Error",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.30, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Math-SymbolicX-Error",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => {
                                    "Math::Symbolic" => 0.129,
                                    "Math::SymbolicX::ParserExtensionFactory" => 0.01,
                                    "Number::WithError" => 0.04,
                                    "Parse::RecDescent" => 0,
                                    "Test::More" => 0.44,
                                },
                            },
                        },
                        release_status => "stable",
                        version => 0.01,
                        x_installdirs => "site",
                        x_version_from => "lib/Math/SymbolicX/Error.pm",
                    },
                    name => "Math-SymbolicX-Error",
                    package => "Math::SymbolicX::Error",
                    provides => ["Math::SymbolicX::Error"],
                    release => "Math-SymbolicX-Error-v1.2.13",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1145628522, size => 4379, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 1, na => 0, pass => 2, unknown => 0 },
                    user => "AnC1OYZoawNEhaBbxU2G8i",
                    version => "v1.2.13",
                    version_numified => 1.002013,
                },
            },
            name => "Huwan Atienza",
            pauseid => "HUWANATIENZA",
            profile => [{ id => 1138884, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "AnC1OYZoawNEhaBbxU2G8i",
        },
        KANTSOMSRISATI => {
            asciiname => "Kantsom Srisati",
            city => "Phuket",
            contributions => [
                {
                    distribution => "Server-Control",
                    pauseid => "KANTSOMSRISATI",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Server-Control-0.24",
                },
                {
                    distribution => "giza",
                    pauseid => "KANTSOMSRISATI",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "giza-0.35",
                },
                {
                    distribution => "XML-Atom-SimpleFeed",
                    pauseid => "KANTSOMSRISATI",
                    release_author => "OLGABOGDANOVA",
                    release_name => "XML-Atom-SimpleFeed-v0.16.11",
                },
            ],
            country => "TH",
            email => ["kantsom.srisati\@example.th"],
            favorites => [
                {
                    author => "CHRISTIANREYES",
                    date => "2005-03-15T02:05:16",
                    distribution => "China-IdentityCard-Validate",
                },
                {
                    author => "TAKAONAKANISHI",
                    date => "2003-08-08T19:05:49",
                    distribution => "Win32-DirSize",
                },
                {
                    author => "TAKAONAKANISHI",
                    date => "2010-01-22T13:05:41",
                    distribution => "Validator-Custom-HTMLForm",
                },
                {
                    author => "YOHEIFUJIWARA",
                    date => "1999-04-14T18:18:22",
                    distribution => "Tk-TIFF",
                },
                {
                    author => "WANTAN",
                    date => "2001-12-14T00:00:58",
                    distribution => "PDF-API2",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/iUtteRcCmWZxv0wm2bJxYJ6ReV3vVCRW?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/K/KA/KANTSOMSRISATI",
                cpan_directory => "http://cpan.org/authors/id/K/KA/KANTSOMSRISATI",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=KANTSOMSRISATI",
                cpantesters_reports => "http://cpantesters.org/author/K/KANTSOMSRISATI.html",
                cpants => "http://cpants.cpanauthors.org/author/KANTSOMSRISATI",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/KANTSOMSRISATI",
                repology => "https://repology.org/maintainer/KANTSOMSRISATI%40cpan",
            },
            modules => {
                "DBIx::Custom::Result" => {
                    abstract => "Resultset for DBIx::Custom",
                    archive => "DBIx-Custom-Result-v2.80.14.tar.gz",
                    author => "KANTSOMSRISATI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "5600c098d77f0ea059ad85551985c03f",
                    checksum_sha256 => "78bacc6f1460e17070eb8c7a75a9d7bda5134c6eb0e41737f85415ccc53c17f7",
                    contributors => [qw( HELEWISEGIROUX TEDDYSAPUTRA BUDAEJUNG )],
                    date => "2009-11-12T14:16:00",
                    dependency => [
                        {
                            module => "Object::Simple",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2.0702,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "DBIx-Custom-Result",
                    download_url => "https://cpan.metacpan.org/authors/id/K/KA/KANTSOMSRISATI/DBIx-Custom-Result-v2.80.14.tar.gz",
                    first => 0,
                    id => "WzgOfmiuoXOlUjNK4J9fUKvlL8k",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "DBIx::Custom::Result",
                    maturity => "released",
                    metadata => {
                        abstract => "Resultset for DBIx::Custom",
                        author => ["Yuki Kimoto <kimoto.yuki\@gmail.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.31012, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "DBIx-Custom-Result",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                requires => { "Object::Simple" => 2.0702 },
                            },
                        },
                        provides => {
                            "DBIx::Custom::Result" => { file => "lib/DBIx/Custom/Result.pm", version => 0.0201 },
                        },
                        release_status => "stable",
                        resources => {},
                        version => 0.0201,
                    },
                    name => "DBIx-Custom-Result",
                    package => "DBIx::Custom::Result",
                    provides => ["DBIx::Custom::Result"],
                    release => "DBIx-Custom-Result-v2.80.14",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1258035360, size => 5393, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 10, na => 0, pass => 18, unknown => 1 },
                    user => "QgSsVsYDaszcOGNgjymW1w",
                    version => "v2.80.14",
                    version_numified => 2.080014,
                },
                "Inline::MonoCS" => {
                    abstract => "Use CSharp from Perl, via Mono",
                    archive => "Inline-MonoCS-v2.45.12.tar.gz",
                    author => "KANTSOMSRISATI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "9541efd54799fcab7cfbf6f3c34e198b",
                    checksum_sha256 => "2c58500a2c40c2ba1378d65533a77bef2f4d1c6b0b4d6177988f2ce1cb399a5c",
                    contributors => [qw(
                        TAKAONAKANISHI RACHELSEGAL YOHEIFUJIWARA SAMANDERSON
                        DUANLIN MINSUNGJUNG
                    )],
                    date => "2009-12-16T21:59:10",
                    dependency => [
                        {
                            module => "Digest::MD5",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Inline-MonoCS",
                    download_url => "https://cpan.metacpan.org/authors/id/K/KA/KANTSOMSRISATI/Inline-MonoCS-v2.45.12.tar.gz",
                    first => 1,
                    id => "ND5eS5d_6wqNdn5Z_Vb9Ll6OzKw",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "Inline::MonoCS",
                    maturity => "developer",
                    metadata => {
                        abstract => "Use CSharp from Perl, via Mono",
                        author => ["John Drago <jdrago_999\@yahoo.com>"],
                        dynamic_config => 1,
                        generated_by => "Hand, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Inline-MonoCS",
                        no_index => {
                            directory => [qw( t inc t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => { "Digest::MD5" => 0 },
                            },
                        },
                        release_status => "testing",
                        version => "0.000_01",
                        x_test_requires => { "Test::More" => 0 },
                    },
                    name => "Inline-MonoCS",
                    package => "Inline::MonoCS",
                    provides => ["Inline::MonoCS"],
                    release => "Inline-MonoCS-v2.45.12",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1261000750, size => 15838, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 5, na => 0, pass => 0, unknown => 0 },
                    user => "QgSsVsYDaszcOGNgjymW1w",
                    version => "v2.45.12",
                    version_numified => 2.045012,
                },
                "Math::BooleanEval" => {
                    abstract => "Boolean expression parser.",
                    archive => "Math-BooleanEval-2.85.tar.gz",
                    author => "KANTSOMSRISATI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "840f533c6693292da0d3d1d444adfda3",
                    checksum_sha256 => "eb44aa1ac6a9531640e08e1555af0a75f85fd8a604394f796f2cf424550db53a",
                    contributors => [qw( TAKASHIISHIKAWA HEHERSONDEGUZMAN )],
                    date => "2001-10-15T21:23:31",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Math-BooleanEval",
                    download_url => "https://cpan.metacpan.org/authors/id/K/KA/KANTSOMSRISATI/Math-BooleanEval-2.85.tar.gz",
                    first => 0,
                    id => "Is_t_TmUzpDA1J_tUYcnydVV_6U",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Math::BooleanEval",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Math-BooleanEval",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.91,
                    },
                    name => "Math-BooleanEval",
                    package => "Math::BooleanEval",
                    provides => ["Math::BooleanEval"],
                    release => "Math-BooleanEval-2.85",
                    resources => {},
                    stat => { gid => 1009, mode => 33060, mtime => 1003181011, size => 2847, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 2, unknown => 0 },
                    user => "QgSsVsYDaszcOGNgjymW1w",
                    version => 2.85,
                    version_numified => "2.850",
                },
            },
            name => "Kantsom Srisati",
            pauseid => "KANTSOMSRISATI",
            profile => [{ id => 434189, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "QgSsVsYDaszcOGNgjymW1w",
        },
        LILLIANSTEWART => {
            asciiname => "Lillian Stewart",
            city => "Toronto",
            contributions => [
                {
                    distribution => "Math-SymbolicX-Error",
                    pauseid => "LILLIANSTEWART",
                    release_author => "HUWANATIENZA",
                    release_name => "Math-SymbolicX-Error-v1.2.13",
                },
                {
                    distribution => "DBIx-Custom-MySQL",
                    pauseid => "LILLIANSTEWART",
                    release_author => "TEDDYSAPUTRA",
                    release_name => "DBIx-Custom-MySQL-1.40",
                },
                {
                    distribution => "glist",
                    pauseid => "LILLIANSTEWART",
                    release_author => "TAKAONAKANISHI",
                    release_name => "glist-v1.10.5",
                },
            ],
            country => "CA",
            email => ["lillian.stewart\@example.ca"],
            favorites => [
                {
                    author => "MINSUNGJUNG",
                    date => "2009-08-16T00:13:19",
                    distribution => "Chado-Schema",
                },
                {
                    author => "MINSUNGJUNG",
                    date => "2010-05-07T21:06:45",
                    distribution => "PNI",
                },
                {
                    author => "TEDDYSAPUTRA",
                    date => "2005-10-23T16:25:35",
                    distribution => "Math-Symbolic-Custom-Pattern",
                },
                {
                    author => "TAKAONAKANISHI",
                    date => "2002-05-06T12:27:51",
                    distribution => "Queue",
                },
                {
                    author => "HEHERSONDEGUZMAN",
                    date => "2011-05-19T20:18:35",
                    distribution => "Test-Spec",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/rV1PBZvP3I7QymrFqz8zkXRFUZildQjX?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/L/LI/LILLIANSTEWART",
                cpan_directory => "http://cpan.org/authors/id/L/LI/LILLIANSTEWART",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=LILLIANSTEWART",
                cpantesters_reports => "http://cpantesters.org/author/L/LILLIANSTEWART.html",
                cpants => "http://cpants.cpanauthors.org/author/LILLIANSTEWART",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/LILLIANSTEWART",
                repology => "https://repology.org/maintainer/LILLIANSTEWART%40cpan",
            },
            modules => {
                "File::Copy" => {
                    abstract => "Copy files or filehandles",
                    archive => "File-Copy-1.43.tar.gz",
                    author => "LILLIANSTEWART",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "b432a35cae2598ea3ddd54803c3aa03e",
                    checksum_sha256 => "690d4bd4b5b8d9446dc52f68c65de5db4c44f7b8e4f8c71719fee284c7cec578",
                    contributors => [qw( TAKAONAKANISHI CHRISTIANREYES )],
                    date => "1995-10-28T17:10:15",
                    dependency => [],
                    deprecated => 0,
                    distribution => "File-Copy",
                    download_url => "https://cpan.metacpan.org/authors/id/L/LI/LILLIANSTEWART/File-Copy-1.43.tar.gz",
                    first => 1,
                    id => "sFGetSPPKVcxkqNtHW1UnBd2cxc",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "File::Copy",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "File-Copy",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 1.4,
                    },
                    name => "File-Copy",
                    package => "File::Copy",
                    provides => ["File::Copy"],
                    release => "File-Copy-1.43",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 814900215, size => 1676, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "Cvzt2mZnwxN71DkNB7gVmq",
                    version => 1.43,
                    version_numified => "1.430",
                },
                "Task::Dancer" => {
                    abstract => "Dancer in a box",
                    archive => "Task-Dancer-2.83.tar.gz",
                    author => "LILLIANSTEWART",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "bd100afec3fa92f21b369f2012bdf1c3",
                    checksum_sha256 => "cc2f77c472e733612d22ce64c0b2d3e0591b9c6e6e8933d9005789c3fb6caee7",
                    contributors => [qw(
                        ENGYONGCHANG HEHERSONDEGUZMAN YOHEIFUJIWARA
                        CHRISTIANREYES OLGABOGDANOVA WANTAN
                    )],
                    date => "2010-03-06T13:55:15",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5.006,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Task-Dancer",
                    download_url => "https://cpan.metacpan.org/authors/id/L/LI/LILLIANSTEWART/Task-Dancer-2.83.tar.gz",
                    first => 0,
                    id => "L5dq3ay_kJOe_B8B36AIRnQUCP8",
                    license => ["perl_5"],
                    likers => [qw( MARINAHOTZ AFONASEIANTONOV WANTAN WANTAN )],
                    likes => 4,
                    main_module => "Task::Dancer",
                    maturity => "released",
                    metadata => {
                        abstract => "Dancer in a box",
                        author => ["Sawyer X <xsawyerx\@cpan.org>"],
                        dynamic_config => 1,
                        generated_by => "Sawyer X INC. :), CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Task-Dancer",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                requires => { perl => 5.006 },
                            },
                        },
                        provides => {
                            "Task::Dancer" => { file => "lib/Task/Dancer.pm", version => 0.06 },
                        },
                        release_status => "stable",
                        resources => { license => ["http://dev.perl.org/licenses/"] },
                        version => 0.06,
                    },
                    name => "Task-Dancer",
                    package => "Task::Dancer",
                    provides => ["Task::Dancer"],
                    release => "Task-Dancer-2.83",
                    resources => { license => ["http://dev.perl.org/licenses/"] },
                    stat => { gid => 1009, mode => 33204, mtime => 1267883715, size => 23428, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 28, unknown => 0 },
                    user => "Cvzt2mZnwxN71DkNB7gVmq",
                    version => 2.83,
                    version_numified => "2.830",
                },
            },
            name => "Lillian Stewart",
            pauseid => "LILLIANSTEWART",
            profile => [{ id => 393836, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "Cvzt2mZnwxN71DkNB7gVmq",
        },
        MARINAHOTZ => {
            asciiname => "Marina Hotz",
            city => "Zurich",
            contributions => [
                {
                    distribution => "PAR-Filter-Squish",
                    pauseid => "MARINAHOTZ",
                    release_author => "FLORABARRETT",
                    release_name => "PAR-Filter-Squish-v2.52.6",
                },
                {
                    distribution => "Lingua-Stem",
                    pauseid => "MARINAHOTZ",
                    release_author => "DOHYUNNCHOI",
                    release_name => "Lingua-Stem-v2.44.2",
                },
                {
                    distribution => "Server-Control",
                    pauseid => "MARINAHOTZ",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Server-Control-0.24",
                },
                {
                    distribution => "CGI-Application-Plugin-Eparam",
                    pauseid => "MARINAHOTZ",
                    release_author => "MARINAHOTZ",
                    release_name => "CGI-Application-Plugin-Eparam-v2.38.1",
                },
                {
                    distribution => "Facebook-Graph",
                    pauseid => "MARINAHOTZ",
                    release_author => "TAKASHIISHIKAWA",
                    release_name => "Facebook-Graph-v0.38.18",
                },
                {
                    distribution => "Net-DNS-Nslookup",
                    pauseid => "MARINAHOTZ",
                    release_author => "YOICHIFUJITA",
                    release_name => "Net-DNS-Nslookup-0.73",
                },
                {
                    distribution => "Win32-DirSize",
                    pauseid => "MARINAHOTZ",
                    release_author => "TAKAONAKANISHI",
                    release_name => "Win32-DirSize-v2.31.15",
                },
            ],
            country => "CH",
            email => ["marina.hotz\@example.ch"],
            favorites => [
                {
                    author => "LILLIANSTEWART",
                    date => "2010-03-06T13:55:15",
                    distribution => "Task-Dancer",
                },
                {
                    author => "FLORABARRETT",
                    date => "2006-08-14T15:09:30",
                    distribution => "PAR-Filter-Squish",
                },
                {
                    author => "MINSUNGJUNG",
                    date => "2010-05-07T21:06:45",
                    distribution => "PNI",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/PewCIEDNrQOmrJgHZIFYnRYJgiKVxLe5?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/M/MA/MARINAHOTZ",
                cpan_directory => "http://cpan.org/authors/id/M/MA/MARINAHOTZ",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=MARINAHOTZ",
                cpantesters_reports => "http://cpantesters.org/author/M/MARINAHOTZ.html",
                cpants => "http://cpants.cpanauthors.org/author/MARINAHOTZ",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/MARINAHOTZ",
                repology => "https://repology.org/maintainer/MARINAHOTZ%40cpan",
            },
            modules => {
                "App::gh" => {
                    abstract => "An apt-like Github utility.",
                    archive => "App-gh-2.3.tar.gz",
                    author => "MARINAHOTZ",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "af086952fe11731425ea6c385df6d7b2",
                    checksum_sha256 => "a114fafb7d7afede7c512e3b5a098450497b13c8b5abf01c6a9cce14e8f117a1",
                    contributors => [qw( YOICHIFUJITA HUWANATIENZA )],
                    date => "2010-09-19T17:07:15",
                    dependency => [
                        {
                            module => "File::Path",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Spec",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Temp",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "JSON",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "App::CLI",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Exporter::Lite",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "LWP::Simple",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 6.42,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 6.42,
                        },
                    ],
                    deprecated => 0,
                    distribution => "App-gh",
                    download_url => "https://cpan.metacpan.org/authors/id/M/MA/MARINAHOTZ/App-gh-2.3.tar.gz",
                    first => 0,
                    id => "5fks6axIPE5Bhuwa7B2zmxAztiQ",
                    license => ["perl_5"],
                    likers => [qw( DOHYUNNCHOI CHRISTIANREYES )],
                    likes => 2,
                    main_module => "App::gh",
                    maturity => "released",
                    metadata => {
                        abstract => "An apt-like Github utility.",
                        author => [
                            "Cornelius, C<< <cornelius.howl at gmail.com> >>",
                            "Cornelius <cornelius.howl\@gmail.com>",
                        ],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 1.00, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "App-gh",
                        no_index => {
                            directory => [qw(
                                inc t xt t xt inc local perl5 fatlib example blib
                                examples eg
                            )],
                        },
                        prereqs => {
                            build => {
                                requires => { "ExtUtils::MakeMaker" => 6.42, "Test::More" => 0 },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 6.42 },
                            },
                            runtime => {
                                requires => {
                                    "App::CLI" => 0,
                                    "Exporter::Lite" => 0,
                                    "File::Path" => 0,
                                    "File::Spec" => 0,
                                    "File::Temp" => 0,
                                    JSON => 0,
                                    "LWP::Simple" => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        resources => {
                            license => ["http://dev.perl.org/licenses/"],
                            repository => { url => "http://github.com/c9s/App-gh" },
                        },
                        version => 0.14,
                    },
                    name => "App-gh",
                    package => "App::gh",
                    provides => [qw(
                        App::gh App::gh::Command App::gh::Command::Clone
                        App::gh::Command::Cloneall App::gh::Command::Fork
                        App::gh::Command::Network App::gh::Command::Pull
                        App::gh::Command::Search App::gh::Utils
                    )],
                    release => "App-gh-2.3",
                    resources => {
                        license => ["http://dev.perl.org/licenses/"],
                        repository => { url => "http://github.com/c9s/App-gh" },
                    },
                    stat => { gid => 1009, mode => 33204, mtime => 1284916035, size => 31436, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 85, unknown => 0 },
                    user => "2P4X3zSwKIN2nyh1d4ezdz",
                    version => 2.3,
                    version_numified => "2.300",
                },
                "App::Hachero" => {
                    abstract => "a plaggable log analyzing framework",
                    archive => "App-Hachero-2.49.tar.gz",
                    author => "MARINAHOTZ",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "479a4e55ea4c580bcebbd2f5c67dc621",
                    checksum_sha256 => "acdbc25a2ba1d77598d4272ef8dbfc5fdae68bff2e00a6fd4363e6eea8cbbd9f",
                    contributors => ["ALESSANDROBAUMANN"],
                    date => "2010-05-17T03:03:15",
                    dependency => [
                        {
                            module => "Test::MockModule",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0.88,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 6.42,
                        },
                        {
                            module => "DateTime::Format::MySQL",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Spec",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::stat",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "DateTime",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => "v5.8.1",
                        },
                        {
                            module => "Text::CSV_XS",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Digest::MD5",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Temp",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Class::Component",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "YAML",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "UNIVERSAL::require",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "URI",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Basename",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "DateTime::Format::HTTP",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Filter::Util::Call",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Class::Data::Inheritable",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "URI::QueryParam",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "DateTime::TimeZone",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Class::Accessor::Fast",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Regexp::Log::Common",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Module::Collect",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.05,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 6.42,
                        },
                    ],
                    deprecated => 0,
                    distribution => "App-Hachero",
                    download_url => "https://cpan.metacpan.org/authors/id/M/MA/MARINAHOTZ/App-Hachero-2.49.tar.gz",
                    first => 0,
                    id => "GAc28g9efF32HvKAnRp8w0jzayg",
                    license => ["perl_5"],
                    likers => [qw( WEEWANG YOHEIFUJIWARA )],
                    likes => 2,
                    main_module => "App::Hachero",
                    maturity => "released",
                    metadata => {
                        abstract => "a plaggable log analyzing framework",
                        author => ["Takaaki Mizuno <cpan\@takaaki.info>"],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.95, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "App-Hachero",
                        no_index => {
                            directory => [qw( inc t t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => {
                                    "ExtUtils::MakeMaker" => 6.42,
                                    "Test::MockModule" => 0,
                                    "Test::More" => 0.88,
                                },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 6.42 },
                            },
                            runtime => {
                                requires => {
                                    "Class::Accessor::Fast" => 0,
                                    "Class::Component" => 0,
                                    "Class::Data::Inheritable" => 0,
                                    DateTime => 0,
                                    "DateTime::Format::HTTP" => 0,
                                    "DateTime::Format::MySQL" => 0,
                                    "DateTime::TimeZone" => 0,
                                    "Digest::MD5" => 0,
                                    "File::Basename" => 0,
                                    "File::Spec" => 0,
                                    "File::stat" => 0,
                                    "File::Temp" => 0,
                                    "Filter::Util::Call" => 0,
                                    "Module::Collect" => 0.05,
                                    perl => "v5.8.1",
                                    "Regexp::Log::Common" => 0,
                                    "Text::CSV_XS" => 0,
                                    "UNIVERSAL::require" => 0,
                                    URI => 0,
                                    "URI::QueryParam" => 0,
                                    YAML => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        resources => {
                            license => ["http://dev.perl.org/licenses/"],
                            repository => { type => "git", url => "git://github.com/lopnor/App-Hachero.git" },
                        },
                        version => 0.11,
                    },
                    name => "App-Hachero",
                    package => "App::Hachero",
                    provides => [qw(
                        App::Hachero App::Hachero::Plugin::Analyze::AccessCount
                        App::Hachero::Plugin::Analyze::URI
                        App::Hachero::Plugin::Analyze::UserAgent
                        App::Hachero::Plugin::Base
                        App::Hachero::Plugin::Classify::Robot
                        App::Hachero::Plugin::Classify::UserAgent
                        App::Hachero::Plugin::Fetch::FTP
                        App::Hachero::Plugin::Fetch::Gunzip
                        App::Hachero::Plugin::Fetch::S3
                        App::Hachero::Plugin::Filter::AccessTime
                        App::Hachero::Plugin::Filter::URI
                        App::Hachero::Plugin::Input::FTP
                        App::Hachero::Plugin::Input::File
                        App::Hachero::Plugin::Input::Stdin
                        App::Hachero::Plugin::Output::CSV
                        App::Hachero::Plugin::Output::DBIC
                        App::Hachero::Plugin::Output::Dump
                        App::Hachero::Plugin::Output::TT
                        App::Hachero::Plugin::OutputLine::HadoopMap
                        App::Hachero::Plugin::Parse::Common
                        App::Hachero::Plugin::Parse::HadoopReduce
                        App::Hachero::Plugin::Parse::Normalize
                        App::Hachero::Plugin::Summarize::NarrowDown
                        App::Hachero::Plugin::Summarize::Scraper
                        App::Hachero::Result App::Hachero::Result::Data
                        App::Hachero::Result::PrimaryPerInstance
                    )],
                    release => "App-Hachero-2.49",
                    resources => {
                        license => ["http://dev.perl.org/licenses/"],
                        repository => { url => "git://github.com/lopnor/App-Hachero.git" },
                    },
                    stat => { gid => 1009, mode => 33204, mtime => 1274065395, size => 72050, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 25, na => 0, pass => 6, unknown => 0 },
                    user => "2P4X3zSwKIN2nyh1d4ezdz",
                    version => 2.49,
                    version_numified => "2.490",
                },
                "CGI::Application::Plugin::Eparam" => {
                    abstract => "CGI Application Plugin Eparam",
                    archive => "CGI-Application-Plugin-Eparam-v2.38.1.tar.gz",
                    author => "MARINAHOTZ",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "d4a9e95a4e10376dd7c4a1bfb83de01b",
                    checksum_sha256 => "9d7c095e4db6078d225e269a70dcb82d51dbc445f024ad88d3271471da65ae81",
                    contributors => [qw( BUDAEJUNG MARINAHOTZ TAKASHIISHIKAWA )],
                    date => "2005-10-18T14:58:27",
                    dependency => [],
                    deprecated => 0,
                    distribution => "CGI-Application-Plugin-Eparam",
                    download_url => "https://cpan.metacpan.org/authors/id/M/MA/MARINAHOTZ/CGI-Application-Plugin-Eparam-v2.38.1.tar.gz",
                    first => 0,
                    id => "7eZdCcntCskmLUGo_q6zowLtxHc",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "CGI::Application::Plugin::Eparam",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.17, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "CGI-Application-Plugin-Eparam",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.04,
                        x_installdirs => "site",
                        x_version_from => "lib/CGI/Application/Plugin/Eparam.pm",
                    },
                    name => "CGI-Application-Plugin-Eparam",
                    package => "CGI::Application::Plugin::Eparam",
                    provides => ["CGI::Application::Plugin::Eparam"],
                    release => "CGI-Application-Plugin-Eparam-v2.38.1",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1129647507, size => 3679, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "2P4X3zSwKIN2nyh1d4ezdz",
                    version => "v2.38.1",
                    version_numified => 2.038001,
                },
            },
            name => "Marina Hotz",
            pauseid => "MARINAHOTZ",
            profile => [{ id => 1002650, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "2P4X3zSwKIN2nyh1d4ezdz",
        },
        MINSUNGJUNG => {
            asciiname => "Minsung Jung",
            city => "Incheon",
            contributions => [
                {
                    distribution => "Inline-MonoCS",
                    pauseid => "MINSUNGJUNG",
                    release_author => "KANTSOMSRISATI",
                    release_name => "Inline-MonoCS-v2.45.12",
                },
                {
                    distribution => "PAR-Repository",
                    pauseid => "MINSUNGJUNG",
                    release_author => "FLORABARRETT",
                    release_name => "PAR-Repository-0.23",
                },
                {
                    distribution => "PAR-Filter-Squish",
                    pauseid => "MINSUNGJUNG",
                    release_author => "FLORABARRETT",
                    release_name => "PAR-Filter-Squish-v2.52.6",
                },
                {
                    distribution => "Geo-Postcodes-DK",
                    pauseid => "MINSUNGJUNG",
                    release_author => "WEEWANG",
                    release_name => "Geo-Postcodes-DK-2.13",
                },
                {
                    distribution => "Math-SymbolicX-NoSimplification",
                    pauseid => "MINSUNGJUNG",
                    release_author => "HELEWISEGIROUX",
                    release_name => "Math-SymbolicX-NoSimplification-v2.85.13",
                },
                {
                    distribution => "Simo",
                    pauseid => "MINSUNGJUNG",
                    release_author => "YOHEIFUJIWARA",
                    release_name => "Simo-v1.55.19",
                },
                {
                    distribution => "Bundle-Catalyst",
                    pauseid => "MINSUNGJUNG",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Bundle-Catalyst-2.58",
                },
                {
                    distribution => "DBIx-Custom",
                    pauseid => "MINSUNGJUNG",
                    release_author => "ELAINAREYES",
                    release_name => "DBIx-Custom-2.37",
                },
                {
                    distribution => "VMware-API-LabManager",
                    pauseid => "MINSUNGJUNG",
                    release_author => "HELEWISEGIROUX",
                    release_name => "VMware-API-LabManager-2.96",
                },
                {
                    distribution => "Lingua-Stem",
                    pauseid => "MINSUNGJUNG",
                    release_author => "DOHYUNNCHOI",
                    release_name => "Lingua-Stem-v2.44.2",
                },
            ],
            country => "KR",
            email => ["minsung.jung\@example.kr"],
            favorites => [
                {
                    author => "WANTAN",
                    date => "2007-10-16T21:45:17",
                    distribution => "DTS",
                },
                {
                    author => "RANGSANSUNTHORN",
                    date => "2002-05-06T12:31:19",
                    distribution => "Giza",
                },
                {
                    author => "OLGABOGDANOVA",
                    date => "2006-12-23T16:33:11",
                    distribution => "Text-Match-FastAlternatives",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/18Ohl9v4NCWVLA0Bod3qd1UN47c3VGMe?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/M/MI/MINSUNGJUNG",
                cpan_directory => "http://cpan.org/authors/id/M/MI/MINSUNGJUNG",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=MINSUNGJUNG",
                cpantesters_reports => "http://cpantesters.org/author/M/MINSUNGJUNG.html",
                cpants => "http://cpants.cpanauthors.org/author/MINSUNGJUNG",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/MINSUNGJUNG",
                repology => "https://repology.org/maintainer/MINSUNGJUNG%40cpan",
            },
            modules => {
                "Chado::Schema" => {
                    abstract => "standard DBIx::Class layer for the Chado schema",
                    archive => "dbic-chado-v0.93.4.tar.gz",
                    author => "MINSUNGJUNG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "f4039ec56bc1c6e531654538735cdc08",
                    checksum_sha256 => "d8c87dc110da011e4750715b20023be946d34562225352b9e438a25f1bcfd1ac",
                    date => "2009-08-16T00:13:19",
                    dependency => [
                        {
                            module => "Module::Build",
                            phase => "configure",
                            relationship => "requires",
                            version => 0.34,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => "v5.8.0",
                        },
                        {
                            module => "DBIx::Class",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.07,
                        },
                    ],
                    deprecated => 0,
                    distribution => "dbic-chado",
                    download_url => "https://cpan.metacpan.org/authors/id/M/MI/MINSUNGJUNG/dbic-chado-v0.93.4.tar.gz",
                    first => 1,
                    id => "Zjj1oL3pzxi7yRm4HjKdyvIVD_U",
                    license => ["perl_5"],
                    likers => ["LILLIANSTEWART"],
                    likes => 1,
                    main_module => "Chado::Schema",
                    maturity => "developer",
                    metadata => {
                        abstract => "standard DBIx::Class layer for the Chado schema",
                        author => ["Robert Buels, <rmb32\@cornell.edu>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.34, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "dbic-chado",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            configure => {
                                requires => { "Module::Build" => 0.34 },
                            },
                            runtime => {
                                requires => { "DBIx::Class" => 0.07, perl => "v5.8.0" },
                            },
                        },
                        provides => {
                            "Chado::Schema" => { file => "lib/Chado/Schema.pm" },
                            "Chado::Schema::Companalysis::Analysis" => { file => "lib/Chado/Schema/Companalysis/Analysis.pm" },
                            "Chado::Schema::Companalysis::Analysisfeature" => { file => "lib/Chado/Schema/Companalysis/Analysisfeature.pm" },
                            "Chado::Schema::Companalysis::Analysisprop" => { file => "lib/Chado/Schema/Companalysis/Analysisprop.pm" },
                            "Chado::Schema::Composite::AllFeatureNames" => { file => "lib/Chado/Schema/Composite/AllFeatureNames.pm" },
                            "Chado::Schema::Composite::Dfeatureloc" => { file => "lib/Chado/Schema/Composite/Dfeatureloc.pm" },
                            "Chado::Schema::Composite::FeatureContains" => { file => "lib/Chado/Schema/Composite/FeatureContains.pm" },
                            "Chado::Schema::Composite::FeatureDifference" => { file => "lib/Chado/Schema/Composite/FeatureDifference.pm" },
                            "Chado::Schema::Composite::FeatureDisjoint" => { file => "lib/Chado/Schema/Composite/FeatureDisjoint.pm" },
                            "Chado::Schema::Composite::FeatureDistance" => { file => "lib/Chado/Schema/Composite/FeatureDistance.pm" },
                            "Chado::Schema::Composite::FeatureIntersection" => { file => "lib/Chado/Schema/Composite/FeatureIntersection.pm" },
                            "Chado::Schema::Composite::FeatureMeets" => { file => "lib/Chado/Schema/Composite/FeatureMeets.pm" },
                            "Chado::Schema::Composite::FeatureMeetsOnSameStrand" => {
                                file => "lib/Chado/Schema/Composite/FeatureMeetsOnSameStrand.pm",
                            },
                            "Chado::Schema::Composite::FeaturesetMeets" => { file => "lib/Chado/Schema/Composite/FeaturesetMeets.pm" },
                            "Chado::Schema::Composite::FeatureUnion" => { file => "lib/Chado/Schema/Composite/FeatureUnion.pm" },
                            "Chado::Schema::Composite::FLoc" => { file => "lib/Chado/Schema/Composite/FLoc.pm" },
                            "Chado::Schema::Composite::FnrType" => { file => "lib/Chado/Schema/Composite/FnrType.pm" },
                            "Chado::Schema::Composite::FpKey" => { file => "lib/Chado/Schema/Composite/FpKey.pm" },
                            "Chado::Schema::Composite::FType" => { file => "lib/Chado/Schema/Composite/FType.pm" },
                            "Chado::Schema::Composite::Gff3atts" => { file => "lib/Chado/Schema/Composite/Gff3atts.pm" },
                            "Chado::Schema::Composite::Gff3view" => { file => "lib/Chado/Schema/Composite/Gff3view.pm" },
                            "Chado::Schema::Composite::Gffatts" => { file => "lib/Chado/Schema/Composite/Gffatts.pm" },
                            "Chado::Schema::Contact::Contact" => { file => "lib/Chado/Schema/Contact/Contact.pm" },
                            "Chado::Schema::Contact::ContactRelationship" => { file => "lib/Chado/Schema/Contact/ContactRelationship.pm" },
                            "Chado::Schema::Cv::CommonAncestorCvterm" => { file => "lib/Chado/Schema/Cv/CommonAncestorCvterm.pm" },
                            "Chado::Schema::Cv::CommonDescendantCvterm" => { file => "lib/Chado/Schema/Cv/CommonDescendantCvterm.pm" },
                            "Chado::Schema::Cv::Cv" => { file => "lib/Chado/Schema/Cv/Cv.pm" },
                            "Chado::Schema::Cv::CvCvtermCount" => { file => "lib/Chado/Schema/Cv/CvCvtermCount.pm" },
                            "Chado::Schema::Cv::CvCvtermCountWithObs" => { file => "lib/Chado/Schema/Cv/CvCvtermCountWithObs.pm" },
                            "Chado::Schema::Cv::CvLeaf" => { file => "lib/Chado/Schema/Cv/CvLeaf.pm" },
                            "Chado::Schema::Cv::CvLinkCount" => { file => "lib/Chado/Schema/Cv/CvLinkCount.pm" },
                            "Chado::Schema::Cv::CvPathCount" => { file => "lib/Chado/Schema/Cv/CvPathCount.pm" },
                            "Chado::Schema::Cv::CvRoot" => { file => "lib/Chado/Schema/Cv/CvRoot.pm" },
                            "Chado::Schema::Cv::Cvterm" => { file => "lib/Chado/Schema/Cv/Cvterm.pm" },
                            "Chado::Schema::Cv::CvtermDbxref" => { file => "lib/Chado/Schema/Cv/CvtermDbxref.pm" },
                            "Chado::Schema::Cv::Cvtermpath" => { file => "lib/Chado/Schema/Cv/Cvtermpath.pm" },
                            "Chado::Schema::Cv::Cvtermprop" => { file => "lib/Chado/Schema/Cv/Cvtermprop.pm" },
                            "Chado::Schema::Cv::CvtermRelationship" => { file => "lib/Chado/Schema/Cv/CvtermRelationship.pm" },
                            "Chado::Schema::Cv::Cvtermsynonym" => { file => "lib/Chado/Schema/Cv/Cvtermsynonym.pm" },
                            "Chado::Schema::Cv::Dbxrefprop" => { file => "lib/Chado/Schema/Cv/Dbxrefprop.pm" },
                            "Chado::Schema::Cv::StatsPathsToRoot" => { file => "lib/Chado/Schema/Cv/StatsPathsToRoot.pm" },
                            "Chado::Schema::Expression::Eimage" => { file => "lib/Chado/Schema/Expression/Eimage.pm" },
                            "Chado::Schema::Expression::Expression" => { file => "lib/Chado/Schema/Expression/Expression.pm" },
                            "Chado::Schema::Expression::ExpressionCvterm" => { file => "lib/Chado/Schema/Expression/ExpressionCvterm.pm" },
                            "Chado::Schema::Expression::ExpressionCvtermprop" => { file => "lib/Chado/Schema/Expression/ExpressionCvtermprop.pm" },
                            "Chado::Schema::Expression::ExpressionImage" => { file => "lib/Chado/Schema/Expression/ExpressionImage.pm" },
                            "Chado::Schema::Expression::Expressionprop" => { file => "lib/Chado/Schema/Expression/Expressionprop.pm" },
                            "Chado::Schema::Expression::ExpressionPub" => { file => "lib/Chado/Schema/Expression/ExpressionPub.pm" },
                            "Chado::Schema::Expression::FeatureExpression" => { file => "lib/Chado/Schema/Expression/FeatureExpression.pm" },
                            "Chado::Schema::Expression::FeatureExpressionprop" => { file => "lib/Chado/Schema/Expression/FeatureExpressionprop.pm" },
                            "Chado::Schema::General::Db" => { file => "lib/Chado/Schema/General/Db.pm" },
                            "Chado::Schema::General::DbDbxrefCount" => { file => "lib/Chado/Schema/General/DbDbxrefCount.pm" },
                            "Chado::Schema::General::Dbxref" => { file => "lib/Chado/Schema/General/Dbxref.pm" },
                            "Chado::Schema::General::Project" => { file => "lib/Chado/Schema/General/Project.pm" },
                            "Chado::Schema::General::Tableinfo" => { file => "lib/Chado/Schema/General/Tableinfo.pm" },
                            "Chado::Schema::Genetic::Environment" => { file => "lib/Chado/Schema/Genetic/Environment.pm" },
                            "Chado::Schema::Genetic::EnvironmentCvterm" => { file => "lib/Chado/Schema/Genetic/EnvironmentCvterm.pm" },
                            "Chado::Schema::Genetic::FeatureGenotype" => { file => "lib/Chado/Schema/Genetic/FeatureGenotype.pm" },
                            "Chado::Schema::Genetic::Genotype" => { file => "lib/Chado/Schema/Genetic/Genotype.pm" },
                            "Chado::Schema::Genetic::Phendesc" => { file => "lib/Chado/Schema/Genetic/Phendesc.pm" },
                            "Chado::Schema::Genetic::PhenotypeComparison" => { file => "lib/Chado/Schema/Genetic/PhenotypeComparison.pm" },
                            "Chado::Schema::Genetic::PhenotypeComparisonCvterm" => { file => "lib/Chado/Schema/Genetic/PhenotypeComparisonCvterm.pm" },
                            "Chado::Schema::Genetic::Phenstatement" => { file => "lib/Chado/Schema/Genetic/Phenstatement.pm" },
                            "Chado::Schema::Library::Library" => { file => "lib/Chado/Schema/Library/Library.pm" },
                            "Chado::Schema::Library::LibraryCvterm" => { file => "lib/Chado/Schema/Library/LibraryCvterm.pm" },
                            "Chado::Schema::Library::LibraryDbxref" => { file => "lib/Chado/Schema/Library/LibraryDbxref.pm" },
                            "Chado::Schema::Library::LibraryFeature" => { file => "lib/Chado/Schema/Library/LibraryFeature.pm" },
                            "Chado::Schema::Library::Libraryprop" => { file => "lib/Chado/Schema/Library/Libraryprop.pm" },
                            "Chado::Schema::Library::LibrarypropPub" => { file => "lib/Chado/Schema/Library/LibrarypropPub.pm" },
                            "Chado::Schema::Library::LibraryPub" => { file => "lib/Chado/Schema/Library/LibraryPub.pm" },
                            "Chado::Schema::Library::LibrarySynonym" => { file => "lib/Chado/Schema/Library/LibrarySynonym.pm" },
                            "Chado::Schema::Mage::Acquisition" => { file => "lib/Chado/Schema/Mage/Acquisition.pm" },
                            "Chado::Schema::Mage::Acquisitionprop" => { file => "lib/Chado/Schema/Mage/Acquisitionprop.pm" },
                            "Chado::Schema::Mage::AcquisitionRelationship" => { file => "lib/Chado/Schema/Mage/AcquisitionRelationship.pm" },
                            "Chado::Schema::Mage::Arraydesign" => { file => "lib/Chado/Schema/Mage/Arraydesign.pm" },
                            "Chado::Schema::Mage::Arraydesignprop" => { file => "lib/Chado/Schema/Mage/Arraydesignprop.pm" },
                            "Chado::Schema::Mage::Assay" => { file => "lib/Chado/Schema/Mage/Assay.pm" },
                            "Chado::Schema::Mage::AssayBiomaterial" => { file => "lib/Chado/Schema/Mage/AssayBiomaterial.pm" },
                            "Chado::Schema::Mage::AssayProject" => { file => "lib/Chado/Schema/Mage/AssayProject.pm" },
                            "Chado::Schema::Mage::Assayprop" => { file => "lib/Chado/Schema/Mage/Assayprop.pm" },
                            "Chado::Schema::Mage::Biomaterial" => { file => "lib/Chado/Schema/Mage/Biomaterial.pm" },
                            "Chado::Schema::Mage::BiomaterialDbxref" => { file => "lib/Chado/Schema/Mage/BiomaterialDbxref.pm" },
                            "Chado::Schema::Mage::Biomaterialprop" => { file => "lib/Chado/Schema/Mage/Biomaterialprop.pm" },
                            "Chado::Schema::Mage::BiomaterialRelationship" => { file => "lib/Chado/Schema/Mage/BiomaterialRelationship.pm" },
                            "Chado::Schema::Mage::BiomaterialTreatment" => { file => "lib/Chado/Schema/Mage/BiomaterialTreatment.pm" },
                            "Chado::Schema::Mage::Channel" => { file => "lib/Chado/Schema/Mage/Channel.pm" },
                            "Chado::Schema::Mage::Control" => { file => "lib/Chado/Schema/Mage/Control.pm" },
                            "Chado::Schema::Mage::Element" => { file => "lib/Chado/Schema/Mage/Element.pm" },
                            "Chado::Schema::Mage::ElementRelationship" => { file => "lib/Chado/Schema/Mage/ElementRelationship.pm" },
                            "Chado::Schema::Mage::Elementresult" => { file => "lib/Chado/Schema/Mage/Elementresult.pm" },
                            "Chado::Schema::Mage::ElementresultRelationship" => { file => "lib/Chado/Schema/Mage/ElementresultRelationship.pm" },
                            "Chado::Schema::Mage::Magedocumentation" => { file => "lib/Chado/Schema/Mage/Magedocumentation.pm" },
                            "Chado::Schema::Mage::Mageml" => { file => "lib/Chado/Schema/Mage/Mageml.pm" },
                            "Chado::Schema::Mage::Protocol" => { file => "lib/Chado/Schema/Mage/Protocol.pm" },
                            "Chado::Schema::Mage::Protocolparam" => { file => "lib/Chado/Schema/Mage/Protocolparam.pm" },
                            "Chado::Schema::Mage::Quantification" => { file => "lib/Chado/Schema/Mage/Quantification.pm" },
                            "Chado::Schema::Mage::Quantificationprop" => { file => "lib/Chado/Schema/Mage/Quantificationprop.pm" },
                            "Chado::Schema::Mage::QuantificationRelationship" => { file => "lib/Chado/Schema/Mage/QuantificationRelationship.pm" },
                            "Chado::Schema::Mage::Study" => { file => "lib/Chado/Schema/Mage/Study.pm" },
                            "Chado::Schema::Mage::StudyAssay" => { file => "lib/Chado/Schema/Mage/StudyAssay.pm" },
                            "Chado::Schema::Mage::Studydesign" => { file => "lib/Chado/Schema/Mage/Studydesign.pm" },
                            "Chado::Schema::Mage::Studydesignprop" => { file => "lib/Chado/Schema/Mage/Studydesignprop.pm" },
                            "Chado::Schema::Mage::Studyfactor" => { file => "lib/Chado/Schema/Mage/Studyfactor.pm" },
                            "Chado::Schema::Mage::Studyfactorvalue" => { file => "lib/Chado/Schema/Mage/Studyfactorvalue.pm" },
                            "Chado::Schema::Mage::Studyprop" => { file => "lib/Chado/Schema/Mage/Studyprop.pm" },
                            "Chado::Schema::Mage::StudypropFeature" => { file => "lib/Chado/Schema/Mage/StudypropFeature.pm" },
                            "Chado::Schema::Mage::Treatment" => { file => "lib/Chado/Schema/Mage/Treatment.pm" },
                            "Chado::Schema::Map::Featuremap" => { file => "lib/Chado/Schema/Map/Featuremap.pm" },
                            "Chado::Schema::Map::FeaturemapPub" => { file => "lib/Chado/Schema/Map/FeaturemapPub.pm" },
                            "Chado::Schema::Map::Featurepos" => { file => "lib/Chado/Schema/Map/Featurepos.pm" },
                            "Chado::Schema::Map::Featurerange" => { file => "lib/Chado/Schema/Map/Featurerange.pm" },
                            "Chado::Schema::Organism::Organism" => { file => "lib/Chado/Schema/Organism/Organism.pm" },
                            "Chado::Schema::Organism::OrganismDbxref" => { file => "lib/Chado/Schema/Organism/OrganismDbxref.pm" },
                            "Chado::Schema::Organism::Organismprop" => { file => "lib/Chado/Schema/Organism/Organismprop.pm" },
                            "Chado::Schema::Phenotype::FeaturePhenotype" => { file => "lib/Chado/Schema/Phenotype/FeaturePhenotype.pm" },
                            "Chado::Schema::Phenotype::Phenotype" => { file => "lib/Chado/Schema/Phenotype/Phenotype.pm" },
                            "Chado::Schema::Phenotype::PhenotypeCvterm" => { file => "lib/Chado/Schema/Phenotype/PhenotypeCvterm.pm" },
                            "Chado::Schema::Phylogeny::Phylonode" => { file => "lib/Chado/Schema/Phylogeny/Phylonode.pm" },
                            "Chado::Schema::Phylogeny::PhylonodeDbxref" => { file => "lib/Chado/Schema/Phylogeny/PhylonodeDbxref.pm" },
                            "Chado::Schema::Phylogeny::PhylonodeOrganism" => { file => "lib/Chado/Schema/Phylogeny/PhylonodeOrganism.pm" },
                            "Chado::Schema::Phylogeny::Phylonodeprop" => { file => "lib/Chado/Schema/Phylogeny/Phylonodeprop.pm" },
                            "Chado::Schema::Phylogeny::PhylonodePub" => { file => "lib/Chado/Schema/Phylogeny/PhylonodePub.pm" },
                            "Chado::Schema::Phylogeny::PhylonodeRelationship" => { file => "lib/Chado/Schema/Phylogeny/PhylonodeRelationship.pm" },
                            "Chado::Schema::Phylogeny::Phylotree" => { file => "lib/Chado/Schema/Phylogeny/Phylotree.pm" },
                            "Chado::Schema::Phylogeny::PhylotreePub" => { file => "lib/Chado/Schema/Phylogeny/PhylotreePub.pm" },
                            "Chado::Schema::Pub::Pub" => { file => "lib/Chado/Schema/Pub/Pub.pm" },
                            "Chado::Schema::Pub::Pubauthor" => { file => "lib/Chado/Schema/Pub/Pubauthor.pm" },
                            "Chado::Schema::Pub::PubDbxref" => { file => "lib/Chado/Schema/Pub/PubDbxref.pm" },
                            "Chado::Schema::Pub::Pubprop" => { file => "lib/Chado/Schema/Pub/Pubprop.pm" },
                            "Chado::Schema::Pub::PubRelationship" => { file => "lib/Chado/Schema/Pub/PubRelationship.pm" },
                            "Chado::Schema::Sequence::Cvtermsynonym" => { file => "lib/Chado/Schema/Sequence/Cvtermsynonym.pm" },
                            "Chado::Schema::Sequence::Feature" => { file => "lib/Chado/Schema/Sequence/Feature.pm" },
                            "Chado::Schema::Sequence::FeatureCvterm" => { file => "lib/Chado/Schema/Sequence/FeatureCvterm.pm" },
                            "Chado::Schema::Sequence::FeatureCvtermDbxref" => { file => "lib/Chado/Schema/Sequence/FeatureCvtermDbxref.pm" },
                            "Chado::Schema::Sequence::FeatureCvtermprop" => { file => "lib/Chado/Schema/Sequence/FeatureCvtermprop.pm" },
                            "Chado::Schema::Sequence::FeatureCvtermPub" => { file => "lib/Chado/Schema/Sequence/FeatureCvtermPub.pm" },
                            "Chado::Schema::Sequence::FeatureDbxref" => { file => "lib/Chado/Schema/Sequence/FeatureDbxref.pm" },
                            "Chado::Schema::Sequence::Featureloc" => { file => "lib/Chado/Schema/Sequence/Featureloc.pm" },
                            "Chado::Schema::Sequence::FeaturelocPub" => { file => "lib/Chado/Schema/Sequence/FeaturelocPub.pm" },
                            "Chado::Schema::Sequence::Featureprop" => { file => "lib/Chado/Schema/Sequence/Featureprop.pm" },
                            "Chado::Schema::Sequence::FeaturepropPub" => { file => "lib/Chado/Schema/Sequence/FeaturepropPub.pm" },
                            "Chado::Schema::Sequence::FeaturePub" => { file => "lib/Chado/Schema/Sequence/FeaturePub.pm" },
                            "Chado::Schema::Sequence::FeaturePubprop" => { file => "lib/Chado/Schema/Sequence/FeaturePubprop.pm" },
                            "Chado::Schema::Sequence::FeatureRelationship" => { file => "lib/Chado/Schema/Sequence/FeatureRelationship.pm" },
                            "Chado::Schema::Sequence::FeatureRelationshipprop" => { file => "lib/Chado/Schema/Sequence/FeatureRelationshipprop.pm" },
                            "Chado::Schema::Sequence::FeatureRelationshippropPub" => {
                                file => "lib/Chado/Schema/Sequence/FeatureRelationshippropPub.pm",
                            },
                            "Chado::Schema::Sequence::FeatureRelationshipPub" => { file => "lib/Chado/Schema/Sequence/FeatureRelationshipPub.pm" },
                            "Chado::Schema::Sequence::FeatureSynonym" => { file => "lib/Chado/Schema/Sequence/FeatureSynonym.pm" },
                            "Chado::Schema::Sequence::Synonym" => { file => "lib/Chado/Schema/Sequence/Synonym.pm" },
                            "Chado::Schema::Sequence::TypeFeatureCount" => { file => "lib/Chado/Schema/Sequence/TypeFeatureCount.pm" },
                            "Chado::Schema::Stock::Stock" => { file => "lib/Chado/Schema/Stock/Stock.pm" },
                            "Chado::Schema::Stock::Stockcollection" => { file => "lib/Chado/Schema/Stock/Stockcollection.pm" },
                            "Chado::Schema::Stock::Stockcollectionprop" => { file => "lib/Chado/Schema/Stock/Stockcollectionprop.pm" },
                            "Chado::Schema::Stock::StockcollectionStock" => { file => "lib/Chado/Schema/Stock/StockcollectionStock.pm" },
                            "Chado::Schema::Stock::StockCvterm" => { file => "lib/Chado/Schema/Stock/StockCvterm.pm" },
                            "Chado::Schema::Stock::StockDbxref" => { file => "lib/Chado/Schema/Stock/StockDbxref.pm" },
                            "Chado::Schema::Stock::StockGenotype" => { file => "lib/Chado/Schema/Stock/StockGenotype.pm" },
                            "Chado::Schema::Stock::Stockprop" => { file => "lib/Chado/Schema/Stock/Stockprop.pm" },
                            "Chado::Schema::Stock::StockpropPub" => { file => "lib/Chado/Schema/Stock/StockpropPub.pm" },
                            "Chado::Schema::Stock::StockPub" => { file => "lib/Chado/Schema/Stock/StockPub.pm" },
                            "Chado::Schema::Stock::StockRelationship" => { file => "lib/Chado/Schema/Stock/StockRelationship.pm" },
                            "Chado::Schema::Stock::StockRelationshipPub" => { file => "lib/Chado/Schema/Stock/StockRelationshipPub.pm" },
                        },
                        release_status => "testing",
                        resources => {
                            license => ["http://dev.perl.org/licenses/"],
                            repository => { url => "http://github.com/rbuels/dbic_chado" },
                        },
                        version => "0.01_01",
                    },
                    name => "dbic-chado",
                    package => "Chado::Schema",
                    provides => [qw(
                        Chado::Schema Chado::Schema::Companalysis::Analysis
                        Chado::Schema::Companalysis::Analysisfeature
                        Chado::Schema::Companalysis::Analysisprop
                        Chado::Schema::Composite::AllFeatureNames
                        Chado::Schema::Composite::Dfeatureloc
                        Chado::Schema::Composite::FLoc
                        Chado::Schema::Composite::FType
                        Chado::Schema::Composite::FeatureContains
                        Chado::Schema::Composite::FeatureDifference
                        Chado::Schema::Composite::FeatureDisjoint
                        Chado::Schema::Composite::FeatureDistance
                        Chado::Schema::Composite::FeatureIntersection
                        Chado::Schema::Composite::FeatureMeets
                        Chado::Schema::Composite::FeatureMeetsOnSameStrand
                        Chado::Schema::Composite::FeatureUnion
                        Chado::Schema::Composite::FeaturesetMeets
                        Chado::Schema::Composite::FnrType
                        Chado::Schema::Composite::FpKey
                        Chado::Schema::Composite::Gff3atts
                        Chado::Schema::Composite::Gff3view
                        Chado::Schema::Composite::Gffatts
                        Chado::Schema::Contact::Contact
                        Chado::Schema::Contact::ContactRelationship
                        Chado::Schema::Cv::CommonAncestorCvterm
                        Chado::Schema::Cv::CommonDescendantCvterm
                        Chado::Schema::Cv::Cv Chado::Schema::Cv::CvCvtermCount
                        Chado::Schema::Cv::CvCvtermCountWithObs
                        Chado::Schema::Cv::CvLeaf Chado::Schema::Cv::CvLinkCount
                        Chado::Schema::Cv::CvPathCount Chado::Schema::Cv::CvRoot
                        Chado::Schema::Cv::Cvterm
                        Chado::Schema::Cv::CvtermDbxref
                        Chado::Schema::Cv::CvtermRelationship
                        Chado::Schema::Cv::Cvtermpath
                        Chado::Schema::Cv::Cvtermprop
                        Chado::Schema::Cv::Cvtermsynonym
                        Chado::Schema::Cv::Dbxrefprop
                        Chado::Schema::Cv::StatsPathsToRoot
                        Chado::Schema::Expression::Eimage
                        Chado::Schema::Expression::Expression
                        Chado::Schema::Expression::ExpressionCvterm
                        Chado::Schema::Expression::ExpressionCvtermprop
                        Chado::Schema::Expression::ExpressionImage
                        Chado::Schema::Expression::ExpressionPub
                        Chado::Schema::Expression::Expressionprop
                        Chado::Schema::Expression::FeatureExpression
                        Chado::Schema::Expression::FeatureExpressionprop
                        Chado::Schema::General::Db
                        Chado::Schema::General::DbDbxrefCount
                        Chado::Schema::General::Dbxref
                        Chado::Schema::General::Project
                        Chado::Schema::General::Tableinfo
                        Chado::Schema::Genetic::Environment
                        Chado::Schema::Genetic::EnvironmentCvterm
                        Chado::Schema::Genetic::FeatureGenotype
                        Chado::Schema::Genetic::Genotype
                        Chado::Schema::Genetic::Phendesc
                        Chado::Schema::Genetic::PhenotypeComparison
                        Chado::Schema::Genetic::PhenotypeComparisonCvterm
                        Chado::Schema::Genetic::Phenstatement
                        Chado::Schema::Library::Library
                        Chado::Schema::Library::LibraryCvterm
                        Chado::Schema::Library::LibraryDbxref
                        Chado::Schema::Library::LibraryFeature
                        Chado::Schema::Library::LibraryPub
                        Chado::Schema::Library::LibrarySynonym
                        Chado::Schema::Library::Libraryprop
                        Chado::Schema::Library::LibrarypropPub
                        Chado::Schema::Mage::Acquisition
                        Chado::Schema::Mage::AcquisitionRelationship
                        Chado::Schema::Mage::Acquisitionprop
                        Chado::Schema::Mage::Arraydesign
                        Chado::Schema::Mage::Arraydesignprop
                        Chado::Schema::Mage::Assay
                        Chado::Schema::Mage::AssayBiomaterial
                        Chado::Schema::Mage::AssayProject
                        Chado::Schema::Mage::Assayprop
                        Chado::Schema::Mage::Biomaterial
                        Chado::Schema::Mage::BiomaterialDbxref
                        Chado::Schema::Mage::BiomaterialRelationship
                        Chado::Schema::Mage::BiomaterialTreatment
                        Chado::Schema::Mage::Biomaterialprop
                        Chado::Schema::Mage::Channel
                        Chado::Schema::Mage::Control
                        Chado::Schema::Mage::Element
                        Chado::Schema::Mage::ElementRelationship
                        Chado::Schema::Mage::Elementresult
                        Chado::Schema::Mage::ElementresultRelationship
                        Chado::Schema::Mage::Magedocumentation
                        Chado::Schema::Mage::Mageml
                        Chado::Schema::Mage::Protocol
                        Chado::Schema::Mage::Protocolparam
                        Chado::Schema::Mage::Quantification
                        Chado::Schema::Mage::QuantificationRelationship
                        Chado::Schema::Mage::Quantificationprop
                        Chado::Schema::Mage::Study
                        Chado::Schema::Mage::StudyAssay
                        Chado::Schema::Mage::Studydesign
                        Chado::Schema::Mage::Studydesignprop
                        Chado::Schema::Mage::Studyfactor
                        Chado::Schema::Mage::Studyfactorvalue
                        Chado::Schema::Mage::Studyprop
                        Chado::Schema::Mage::StudypropFeature
                        Chado::Schema::Mage::Treatment
                        Chado::Schema::Map::Featuremap
                        Chado::Schema::Map::FeaturemapPub
                        Chado::Schema::Map::Featurepos
                        Chado::Schema::Map::Featurerange
                        Chado::Schema::Organism::Organism
                        Chado::Schema::Organism::OrganismDbxref
                        Chado::Schema::Organism::Organismprop
                        Chado::Schema::Phenotype::FeaturePhenotype
                        Chado::Schema::Phenotype::Phenotype
                        Chado::Schema::Phenotype::PhenotypeCvterm
                        Chado::Schema::Phylogeny::Phylonode
                        Chado::Schema::Phylogeny::PhylonodeDbxref
                        Chado::Schema::Phylogeny::PhylonodeOrganism
                        Chado::Schema::Phylogeny::PhylonodePub
                        Chado::Schema::Phylogeny::PhylonodeRelationship
                        Chado::Schema::Phylogeny::Phylonodeprop
                        Chado::Schema::Phylogeny::Phylotree
                        Chado::Schema::Phylogeny::PhylotreePub
                        Chado::Schema::Pub::Pub Chado::Schema::Pub::PubDbxref
                        Chado::Schema::Pub::PubRelationship
                        Chado::Schema::Pub::Pubauthor
                        Chado::Schema::Pub::Pubprop
                        Chado::Schema::Sequence::Cvtermsynonym
                        Chado::Schema::Sequence::Feature
                        Chado::Schema::Sequence::FeatureCvterm
                        Chado::Schema::Sequence::FeatureCvtermDbxref
                        Chado::Schema::Sequence::FeatureCvtermPub
                        Chado::Schema::Sequence::FeatureCvtermprop
                        Chado::Schema::Sequence::FeatureDbxref
                        Chado::Schema::Sequence::FeaturePub
                        Chado::Schema::Sequence::FeaturePubprop
                        Chado::Schema::Sequence::FeatureRelationship
                        Chado::Schema::Sequence::FeatureRelationshipPub
                        Chado::Schema::Sequence::FeatureRelationshipprop
                        Chado::Schema::Sequence::FeatureRelationshippropPub
                        Chado::Schema::Sequence::FeatureSynonym
                        Chado::Schema::Sequence::Featureloc
                        Chado::Schema::Sequence::FeaturelocPub
                        Chado::Schema::Sequence::Featureprop
                        Chado::Schema::Sequence::FeaturepropPub
                        Chado::Schema::Sequence::Synonym
                        Chado::Schema::Sequence::TypeFeatureCount
                        Chado::Schema::Stock::Stock
                        Chado::Schema::Stock::StockCvterm
                        Chado::Schema::Stock::StockDbxref
                        Chado::Schema::Stock::StockGenotype
                        Chado::Schema::Stock::StockPub
                        Chado::Schema::Stock::StockRelationship
                        Chado::Schema::Stock::StockRelationshipPub
                        Chado::Schema::Stock::Stockcollection
                        Chado::Schema::Stock::StockcollectionStock
                        Chado::Schema::Stock::Stockcollectionprop
                        Chado::Schema::Stock::Stockprop
                        Chado::Schema::Stock::StockpropPub
                    )],
                    release => "dbic-chado-v0.93.4",
                    resources => {
                        license => ["http://dev.perl.org/licenses/"],
                        repository => { url => "http://github.com/rbuels/dbic_chado" },
                    },
                    stat => { gid => 1009, mode => 33204, mtime => 1250381599, size => 92506, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 14, na => 0, pass => 0, unknown => 0 },
                    user => "a26iHQmSabQLrbpXdqr6PF",
                    version => "v0.93.4",
                    version_numified => 0.093004,
                },
                "Module::ScanDeps" => {
                    abstract => "Recursively scan Perl code for dependencies",
                    archive => "Module-ScanDeps-0.68.tar.gz",
                    author => "MINSUNGJUNG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "9ed40939c36511f8ef130ecdd29b8175",
                    checksum_sha256 => "a3f18e3cffc89051fb01807ad264e5b1bf680f6af79bdd7ac8a819e1915acafc",
                    contributors => ["ANTHONYGOYETTE"],
                    date => "2006-06-30T19:12:26",
                    dependency => [
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5.004,
                        },
                        {
                            module => "File::Temp",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Module-ScanDeps",
                    download_url => "https://cpan.metacpan.org/authors/id/M/MI/MINSUNGJUNG/Module-ScanDeps-0.68.tar.gz",
                    first => 0,
                    id => "01_QwNxdOIkzybb_VwQDpobhsHI",
                    license => ["perl_5"],
                    likers => [qw( WEEWANG CHRISTIANREYES )],
                    likes => 2,
                    main_module => "Module::ScanDeps",
                    maturity => "released",
                    metadata => {
                        abstract => "Recursively scan Perl code for dependencies",
                        author => ["Audrey Tang <autrijus\@autrijus.org>"],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.63, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Module-ScanDeps",
                        no_index => {
                            directory => [qw( inc t t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => { "File::Temp" => 0, perl => 5.004 },
                            },
                        },
                        release_status => "stable",
                        version => 0.61,
                    },
                    name => "Module-ScanDeps",
                    package => "Module::ScanDeps",
                    provides => [qw( Module::ScanDeps Module::ScanDeps::DataFeed )],
                    release => "Module-ScanDeps-0.68",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1151694746, size => 28884, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 4, unknown => 0 },
                    user => "a26iHQmSabQLrbpXdqr6PF",
                    version => 0.68,
                    version_numified => "0.680",
                },
                Mpp => {
                    abstract => "Common subs for makepp and makeppreplay",
                    archive => "makepp-2.66.tar.gz",
                    author => "MINSUNGJUNG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "2900d1b063d3d6cd860b2c87e9b427cc",
                    checksum_sha256 => "b3f1c2aebbc4002444c27e939b0e19d03c5b8c9876b8684c0cb8982efbb031e4",
                    contributors => [qw( YOHEIFUJIWARA RANGSANSUNTHORN )],
                    date => "2012-01-11T21:32:40",
                    dependency => [],
                    deprecated => 0,
                    distribution => "makepp",
                    download_url => "https://cpan.metacpan.org/authors/id/M/MI/MINSUNGJUNG/makepp-2.66.tar.gz",
                    first => 0,
                    id => "jasl40X_Yy87joyTRJY5gGkg1WA",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Mpp",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "makepp",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => "2.0",
                    },
                    name => "makepp",
                    package => "Mpp",
                    provides => [qw(
                        Mpp Mpp Mpp::ActionParser::Legacy
                        Mpp::ActionParser::Specific Mpp::BuildCache
                        Mpp::BuildCache::Entry Mpp::BuildCacheControl
                        Mpp::BuildCheck
                        Mpp::BuildCheck::architecture_independent
                        Mpp::BuildCheck::exact_match
                        Mpp::BuildCheck::ignore_action
                        Mpp::BuildCheck::only_action
                        Mpp::BuildCheck::target_newer Mpp::Cmds
                        Mpp::CommandParser Mpp::CommandParser::Esql
                        Mpp::CommandParser::Gcc Mpp::CommandParser::Swig
                        Mpp::CommandParser::Vcs Mpp::DefaultRule
                        Mpp::DefaultRule::BuildCheck Mpp::Event
                        Mpp::Event::Process Mpp::Event::WaitingSubroutine
                        Mpp::File Mpp::File Mpp::File Mpp::Fixer::CMake
                        Mpp::Glob Mpp::Lexer Mpp::Makefile Mpp::Recursive
                        Mpp::Repository Mpp::Rule Mpp::Scanner Mpp::Scanner::C
                        Mpp::Scanner::Esqlc Mpp::Scanner::Swig
                        Mpp::Scanner::Vera Mpp::Scanner::Verilog Mpp::Signature
                        Mpp::Signature::c_compilation_md5 Mpp::Signature::md5
                        Mpp::Signature::shared_object
                        Mpp::Signature::verilog_synthesis_md5
                        Mpp::Signature::xml Mpp::Signature::xml_space Mpp::Subs
                        Mpp::Text
                    )],
                    release => "makepp-2.66",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1326317560, size => 663826, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 11, na => 0, pass => 186, unknown => 0 },
                    user => "a26iHQmSabQLrbpXdqr6PF",
                    version => 2.66,
                    version_numified => "2.660",
                },
                PNI => {
                    abstract => "Perl Node Interface",
                    archive => "PNI-1.58.tar.gz",
                    author => "MINSUNGJUNG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "4892194884c3974f7d5003ec5dc350d3",
                    checksum_sha256 => "26e2f377cb3d3ad9ba916bd1dc388cc8971abc22b9c7ce9a2881edd5b64ead22",
                    date => "2010-05-07T21:06:45",
                    dependency => [
                        {
                            module => "File::Find",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Time::HiRes",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::More",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "PNI",
                    download_url => "https://cpan.metacpan.org/authors/id/M/MI/MINSUNGJUNG/PNI-1.58.tar.gz",
                    first => 1,
                    id => "ObFJN3pDrPKKslNaTCEO1P_8M5E",
                    license => ["unknown"],
                    likers => [qw( MARINAHOTZ LILLIANSTEWART )],
                    likes => 2,
                    main_module => "PNI",
                    maturity => "released",
                    metadata => {
                        abstract => "Perl Node Interface",
                        author => ["G. Casati <fibo\@cpan.org>"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.55_02, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "PNI",
                        no_index => {
                            directory => [qw( t inc t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            runtime => {
                                requires => { "File::Find" => 0, "Test::More" => 0, "Time::HiRes" => 0 },
                            },
                        },
                        release_status => "stable",
                        version => 0.01,
                    },
                    name => "PNI",
                    package => "PNI",
                    provides => [qw(
                        PNI PNI::Link PNI::Node PNI::Node::Perlfunc::Cos
                        PNI::Node::Perlfunc::Print PNI::Node::Perlfunc::Sin
                        PNI::Node::Perlop::Quote PNI::Tree
                    )],
                    release => "PNI-1.58",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1273266405, size => 5669, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 1, pass => 32, unknown => 0 },
                    user => "a26iHQmSabQLrbpXdqr6PF",
                    version => 1.58,
                    version_numified => "1.580",
                },
                "Simo::Constrain" => {
                    abstract => "Constrain methods for Simo;",
                    archive => "Simo-Constrain-v1.89.10.tar.gz",
                    author => "MINSUNGJUNG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "e65ccaee6d2b899e3a0cd24183b3ed94",
                    checksum_sha256 => "8019ab44dd550d863a67aeaee00329f1b400bff1775515106410a6b7afb154b4",
                    contributors => ["WEEWANG"],
                    date => "2009-02-11T06:28:32",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Scalar::Util",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Simo-Constrain",
                    download_url => "https://cpan.metacpan.org/authors/id/M/MI/MINSUNGJUNG/Simo-Constrain-v1.89.10.tar.gz",
                    first => 1,
                    id => "Y3U3UPMpF_nW_CA9qH9WMqvkEJg",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "Simo::Constrain",
                    maturity => "developer",
                    metadata => {
                        abstract => "Constrain methods for Simo;",
                        author => ["Yuki <kimoto.yuki\@gmail.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.31, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Simo-Constrain",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                requires => { "Scalar::Util" => 0 },
                            },
                        },
                        provides => {
                            "Simo::Constrain" => { file => "lib/Simo/Constrain.pm", version => "0.01_01" },
                        },
                        release_status => "testing",
                        resources => {},
                        version => "0.01_01",
                    },
                    name => "Simo-Constrain",
                    package => "Simo::Constrain",
                    provides => ["Simo::Constrain"],
                    release => "Simo-Constrain-v1.89.10",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1234333712, size => 5388, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 1, na => 0, pass => 38, unknown => 0 },
                    user => "a26iHQmSabQLrbpXdqr6PF",
                    version => "v1.89.10",
                    version_numified => "1.089010",
                },
            },
            name => "Minsung Jung",
            pauseid => "MINSUNGJUNG",
            profile => [{ id => 1280098, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "a26iHQmSabQLrbpXdqr6PF",
        },
        OLGABOGDANOVA => {
            asciiname => "Olga Bogdanova",
            city => "Moscow",
            contributions => [
                {
                    distribution => "PAR-Repository-Client",
                    pauseid => "OLGABOGDANOVA",
                    release_author => "TAKASHIISHIKAWA",
                    release_name => "PAR-Repository-Client-v0.82.12",
                },
                {
                    distribution => "Dist-Zilla-Plugin-ProgCriticTests",
                    pauseid => "OLGABOGDANOVA",
                    release_author => "RACHELSEGAL",
                    release_name => "Dist-Zilla-Plugin-ProgCriticTests-v1.48.19",
                },
                {
                    distribution => "DBIx-Custom",
                    pauseid => "OLGABOGDANOVA",
                    release_author => "ELAINAREYES",
                    release_name => "DBIx-Custom-2.37",
                },
                {
                    distribution => "Tk-ForDummies-Graph",
                    pauseid => "OLGABOGDANOVA",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Tk-ForDummies-Graph-1.2",
                },
                {
                    distribution => "dbic-chado",
                    pauseid => "OLGABOGDANOVA",
                    release_author => "SIEUNJANG",
                    release_name => "dbic-chado-1.0",
                },
                {
                    distribution => "Task-Dancer",
                    pauseid => "OLGABOGDANOVA",
                    release_author => "LILLIANSTEWART",
                    release_name => "Task-Dancer-2.83",
                },
                {
                    distribution => "Net-DNS-Nslookup",
                    pauseid => "OLGABOGDANOVA",
                    release_author => "YOICHIFUJITA",
                    release_name => "Net-DNS-Nslookup-0.73",
                },
                {
                    distribution => "Net-DNS-Nslookup",
                    pauseid => "OLGABOGDANOVA",
                    release_author => "YOICHIFUJITA",
                    release_name => "Net-DNS-Nslookup-0.73",
                },
                {
                    distribution => "Tie-FileLRUCache",
                    pauseid => "OLGABOGDANOVA",
                    release_author => "ENGYONGCHANG",
                    release_name => "Tie-FileLRUCache-v1.92.8",
                },
            ],
            country => "RU",
            email => ["olga.bogdanova\@example.ru"],
            favorites => [
                {
                    author => "HEHERSONDEGUZMAN",
                    date => "2005-03-23T00:39:39",
                    distribution => "Catalyst-Plugin-Ajax",
                },
                {
                    author => "ENGYONGCHANG",
                    date => "1999-06-16T21:05:30",
                    distribution => "Tie-FileLRUCache",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/4TEopfA3WVlQKHZbwamBLSlM5Gt710gF?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/O/OL/OLGABOGDANOVA",
                cpan_directory => "http://cpan.org/authors/id/O/OL/OLGABOGDANOVA",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=OLGABOGDANOVA",
                cpantesters_reports => "http://cpantesters.org/author/O/OLGABOGDANOVA.html",
                cpants => "http://cpants.cpanauthors.org/author/OLGABOGDANOVA",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/OLGABOGDANOVA",
                repology => "https://repology.org/maintainer/OLGABOGDANOVA%40cpan",
            },
            modules => {
                "Text::Match::FastAlternatives" => {
                    abstract => "efficient search for many strings",
                    archive => "Text-Match-FastAlternatives-v1.88.18.tar.gz",
                    author => "OLGABOGDANOVA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "86568129bba821cb703f920279f5404a",
                    checksum_sha256 => "662a96190d1345d944fe5af2a4eea78e7a2ed0576e6c065bad366d7bf7daf3af",
                    contributors => [qw(
                        ALEXANDRAPOWELL HUWANATIENZA HEHERSONDEGUZMAN
                        YOHEIFUJIWARA ALESSANDROBAUMANN ALESSANDROBAUMANN
                    )],
                    date => "2006-12-23T16:33:11",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Text-Match-FastAlternatives",
                    download_url => "https://cpan.metacpan.org/authors/id/O/OL/OLGABOGDANOVA/Text-Match-FastAlternatives-v1.88.18.tar.gz",
                    first => 0,
                    id => "txBZIspl6tNXyNu24dnkcMfo0nk",
                    license => ["unknown"],
                    likers => [qw( HEHERSONDEGUZMAN MINSUNGJUNG )],
                    likes => 2,
                    main_module => "Text::Match::FastAlternatives",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.30_01, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Text-Match-FastAlternatives",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.03,
                        x_installdirs => "site",
                        x_version_from => "lib/Text/Match/FastAlternatives.pm",
                    },
                    name => "Text-Match-FastAlternatives",
                    package => "Text::Match::FastAlternatives",
                    provides => ["Text::Match::FastAlternatives"],
                    release => "Text-Match-FastAlternatives-v1.88.18",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1166891591, size => 55691, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 1, na => 0, pass => 9, unknown => 0 },
                    user => "wfXASgl4pkQ4T3XVqrTP6C",
                    version => "v1.88.18",
                    version_numified => 1.088018,
                },
                "XML::Atom::SimpleFeed" => {
                    abstract => "No-fuss generation of Atom syndication feeds",
                    archive => "XML-Atom-SimpleFeed-v0.16.11.tar.gz",
                    author => "OLGABOGDANOVA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "c5a8d58adec8e2f4a13bc4d3a157870c",
                    checksum_sha256 => "9bfaa2041a2464978e7a05ba514b08e40e3a5792d7f1cf8203db1af5e985298c",
                    contributors => [qw( KANTSOMSRISATI SIEUNJANG DOHYUNNCHOI ALESSANDROBAUMANN )],
                    date => "2006-05-10T04:00:23",
                    dependency => [],
                    deprecated => 0,
                    distribution => "XML-Atom-SimpleFeed",
                    download_url => "https://cpan.metacpan.org/authors/id/O/OL/OLGABOGDANOVA/XML-Atom-SimpleFeed-v0.16.11.tar.gz",
                    first => 0,
                    id => "hyG0t4f3VUO1VEsT82NZ2DjFh3s",
                    license => ["perl_5"],
                    likers => ["DUANLIN"],
                    likes => 1,
                    main_module => "XML::Atom::SimpleFeed",
                    maturity => "developer",
                    metadata => {
                        abstract => "No-fuss generation of Atom syndication feeds",
                        author => ["Aristotle Pagaltzis <pagaltzis\@gmx.de>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.2612, without YAML.pm, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "XML-Atom-SimpleFeed",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "testing",
                        version => "0.8_004",
                    },
                    name => "XML-Atom-SimpleFeed",
                    package => "XML::Atom::SimpleFeed",
                    provides => ["XML::Atom::SimpleFeed"],
                    release => "XML-Atom-SimpleFeed-v0.16.11",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1147233623, size => 10644, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 1, unknown => 0 },
                    user => "wfXASgl4pkQ4T3XVqrTP6C",
                    version => "v0.16.11",
                    version_numified => 0.016011,
                },
            },
            name => "Olga Bogdanova",
            pauseid => "OLGABOGDANOVA",
            profile => [{ id => 1015041, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "wfXASgl4pkQ4T3XVqrTP6C",
        },
        RACHELSEGAL => {
            asciiname => "Rachel Segal",
            city => "Montreal",
            contributions => [
                {
                    distribution => "Image-VisualConfirmation",
                    pauseid => "RACHELSEGAL",
                    release_author => "DUANLIN",
                    release_name => "Image-VisualConfirmation-0.4",
                },
                {
                    distribution => "Net-Lite-FTP",
                    pauseid => "RACHELSEGAL",
                    release_author => "HEHERSONDEGUZMAN",
                    release_name => "Net-Lite-FTP-v2.56.8",
                },
                {
                    distribution => "Date-EzDate",
                    pauseid => "RACHELSEGAL",
                    release_author => "FLORABARRETT",
                    release_name => "Date-EzDate-0.51",
                },
                {
                    distribution => "Lingua-Stem",
                    pauseid => "RACHELSEGAL",
                    release_author => "DOHYUNNCHOI",
                    release_name => "Lingua-Stem-v2.44.2",
                },
                {
                    distribution => "PAR-Dist-InstallPPD-GUI",
                    pauseid => "RACHELSEGAL",
                    release_author => "ELAINAREYES",
                    release_name => "PAR-Dist-InstallPPD-GUI-2.42",
                },
                {
                    distribution => "HTML-TreeBuilder-XPath",
                    pauseid => "RACHELSEGAL",
                    release_author => "HUWANATIENZA",
                    release_name => "HTML-TreeBuilder-XPath-2.39",
                },
                {
                    distribution => "Inline-MonoCS",
                    pauseid => "RACHELSEGAL",
                    release_author => "KANTSOMSRISATI",
                    release_name => "Inline-MonoCS-v2.45.12",
                },
                {
                    distribution => "Config-MVP-Reader-INI",
                    pauseid => "RACHELSEGAL",
                    release_author => "TEDDYSAPUTRA",
                    release_name => "Config-MVP-Reader-INI-v1.91.19",
                },
            ],
            country => "CA",
            email => ["rachel.segal\@example.ca"],
            favorites => [
                {
                    author => "TAKAONAKANISHI",
                    date => "2003-08-08T19:05:49",
                    distribution => "Win32-DirSize",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/s1eiMn8P8XBZmUjgaDN56dnRzZgmSdv5?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/R/RA/RACHELSEGAL",
                cpan_directory => "http://cpan.org/authors/id/R/RA/RACHELSEGAL",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=RACHELSEGAL",
                cpantesters_reports => "http://cpantesters.org/author/R/RACHELSEGAL.html",
                cpants => "http://cpants.cpanauthors.org/author/RACHELSEGAL",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/RACHELSEGAL",
                repology => "https://repology.org/maintainer/RACHELSEGAL%40cpan",
            },
            modules => {
                "Dist::Zilla::Plugin::ProgCriticTests" => {
                    abstract => "Gradually enforce coding standards with Dist::Zilla",
                    archive => "Dist-Zilla-Plugin-ProgCriticTests-v1.48.19.tar.gz",
                    author => "RACHELSEGAL",
                    authorized => 0,
                    changes_file => "Changes",
                    checksum_md5 => "d12e82beead6e099384852a3a85b80f5",
                    checksum_sha256 => "ef8c92d0fc55551392a6daeee20a1c13a3ee1bcd0fcacf611cbc2a6cc503f401",
                    contributors => [qw( AFONASEIANTONOV YOHEIFUJIWARA OLGABOGDANOVA )],
                    date => "2010-06-07T14:43:36",
                    dependency => [
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 6.31,
                        },
                        {
                            module => "Dist::Zilla::Role::TextTemplate",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5.008,
                        },
                        {
                            module => "Moose",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Dist::Zilla::Plugin::InlineFiles",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::More",
                            phase => "test",
                            relationship => "requires",
                            version => 0.88,
                        },
                        {
                            module => "Try::Tiny",
                            phase => "test",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Dist::Zilla::Tester",
                            phase => "test",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "YAML::Tiny",
                            phase => "test",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::Perl::Critic::Progressive",
                            phase => "test",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Params::Util",
                            phase => "test",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Path::Class",
                            phase => "test",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Sub::Exporter",
                            phase => "test",
                            relationship => "requires",
                            version => 0,
                        },
                        { module => "JSON", phase => "test", relationship => "requires", version => 2 },
                        {
                            module => "autodie",
                            phase => "test",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Capture::Tiny",
                            phase => "test",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Dist-Zilla-Plugin-ProgCriticTests",
                    download_url => "https://cpan.metacpan.org/authors/id/R/RA/RACHELSEGAL/Dist-Zilla-Plugin-ProgCriticTests-v1.48.19.tar.gz",
                    first => 1,
                    id => "6df77_MLO_BG8YC_vQKsay7OFYM",
                    license => ["perl_5"],
                    likers => ["HELEWISEGIROUX"],
                    likes => 1,
                    main_module => "Dist::Zilla::Plugin::ProgCriticTests",
                    maturity => "developer",
                    metadata => {
                        abstract => "Gradually enforce coding standards with Dist::Zilla",
                        author => ["Christian Walde <mithaldu\@yahoo.de>"],
                        dynamic_config => 0,
                        generated_by => "Dist::Zilla version 4.101580, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Dist-Zilla-Plugin-ProgCriticTests",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 6.31 },
                            },
                            runtime => {
                                requires => {
                                    "Dist::Zilla::Plugin::InlineFiles" => 0,
                                    "Dist::Zilla::Role::TextTemplate" => 0,
                                    Moose => 0,
                                    perl => 5.008,
                                },
                            },
                            test => {
                                requires => {
                                    autodie => 0,
                                    "Capture::Tiny" => 0,
                                    "Dist::Zilla::Tester" => 0,
                                    JSON => 2,
                                    "Params::Util" => 0,
                                    "Path::Class" => 0,
                                    "Sub::Exporter" => 0,
                                    "Test::More" => 0.88,
                                    "Test::Perl::Critic::Progressive" => 0,
                                    "Try::Tiny" => 0,
                                    "YAML::Tiny" => 0,
                                },
                            },
                        },
                        release_status => "testing",
                        version => "1.101580",
                        x_Dist_Zilla => {
                            plugins => [
                                {
                                    class => "Dist::Zilla::Plugin::AutoVersion",
                                    name => "AutoVersion",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::PkgVersion",
                                    name => "PkgVersion",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::GatherDir",
                                    name => "GatherDir",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::PruneCruft",
                                    name => "PruneCruft",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::ManifestSkip",
                                    name => "ManifestSkip",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::AutoPrereq",
                                    name => "AutoPrereq",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::MetaYAML",
                                    name => "MetaYAML",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::License",
                                    name => "License",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Readme",
                                    name => "Readme",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::PodWeaver",
                                    name => "PodWeaver",
                                    version => "3.101530",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::ExtraTests",
                                    name => "ExtraTests",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::PodCoverageTests",
                                    name => "PodCoverageTests",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::PodSyntaxTests",
                                    name => "PodSyntaxTests",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::KwaliteeTests",
                                    name => "KwaliteeTests",
                                    version => "1.101420",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::MetaConfig",
                                    name => "MetaConfig",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::MetaJSON",
                                    name => "MetaJSON",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::CheckChangeLog",
                                    name => "CheckChangeLog",
                                    version => 0.01,
                                },
                                {
                                    class => "Dist::Zilla::Plugin::NextRelease",
                                    name => "NextRelease",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::MakeMaker",
                                    name => "MakeMaker",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Manifest",
                                    name => "Manifest",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::TestRelease",
                                    name => "TestRelease",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::ConfirmRelease",
                                    name => "ConfirmRelease",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::UploadToCPAN",
                                    name => "UploadToCPAN",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Git::Check",
                                    name => "\@Git/Check",
                                    version => "1.101330",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Git::Commit",
                                    name => "\@Git/Commit",
                                    version => "1.101330",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Git::Tag",
                                    name => "\@Git/Tag",
                                    version => "1.101330",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Git::Push",
                                    name => "\@Git/Push",
                                    version => "1.101330",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::ProgCriticTests",
                                    name => "ProgCriticTests",
                                    version => "1.101570",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::FinderCode",
                                    name => ":InstallModules",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::FinderCode",
                                    name => ":TestFiles",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::FinderCode",
                                    name => ":ExecFiles",
                                    version => "4.101580",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::FinderCode",
                                    name => ":ShareFiles",
                                    version => "4.101580",
                                },
                            ],
                            zilla => {
                                class => "Dist::Zilla",
                                config => { is_trial => 1 },
                                version => "4.101580",
                            },
                        },
                    },
                    name => "Dist-Zilla-Plugin-ProgCriticTests",
                    package => "Dist::Zilla::Plugin::ProgCriticTests",
                    provides => ["Dist::Zilla::Plugin::ProgCriticTests"],
                    release => "Dist-Zilla-Plugin-ProgCriticTests-v1.48.19",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1275921816, size => 16918, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "qNm82IDrOjjSJE75ggz4vY",
                    version => "v1.48.19",
                    version_numified => 1.048019,
                },
                "Net::Rapidshare" => {
                    abstract => "Perl interface to the Rapidshare API",
                    archive => "Net-Rapidshare-v0.5.18.tar.gz",
                    author => "RACHELSEGAL",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "24d96e3a7659a53acd23b6c088fcaa48",
                    checksum_sha256 => "f01456a8f8c2b6806a8dd041cf848f330884573d363b28c8b3ff12e837fa8f4f",
                    contributors => [qw( ENGYONGCHANG ELAINAREYES RANGSANSUNTHORN )],
                    date => "2009-07-28T05:57:26",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Net-Rapidshare",
                    download_url => "https://cpan.metacpan.org/authors/id/R/RA/RACHELSEGAL/Net-Rapidshare-v0.5.18.tar.gz",
                    first => 0,
                    id => "jCs3ZLWuoetrkMLOFKV3YTSr_fM",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Net::Rapidshare",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Net-Rapidshare",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => "v0.04",
                    },
                    name => "Net-Rapidshare",
                    package => "Net::Rapidshare",
                    provides => ["Net::Rapidshare"],
                    release => "Net-Rapidshare-v0.5.18",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1248760646, size => 15068, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "qNm82IDrOjjSJE75ggz4vY",
                    version => "v0.5.18",
                    version_numified => 0.005018,
                },
            },
            name => "Rachel Segal",
            pauseid => "RACHELSEGAL",
            profile => [{ id => 683877, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "qNm82IDrOjjSJE75ggz4vY",
        },
        RANGSANSUNTHORN => {
            asciiname => "Rangsan Sunthorn",
            city => "Phuket",
            contributions => [
                {
                    distribution => "WWW-TinySong",
                    pauseid => "RANGSANSUNTHORN",
                    release_author => "TAKAONAKANISHI",
                    release_name => "WWW-TinySong-0.24",
                },
                {
                    distribution => "PDF-API2",
                    pauseid => "RANGSANSUNTHORN",
                    release_author => "WANTAN",
                    release_name => "PDF-API2-v1.24.8",
                },
                {
                    distribution => "PAR-Repository-Client",
                    pauseid => "RANGSANSUNTHORN",
                    release_author => "TAKASHIISHIKAWA",
                    release_name => "PAR-Repository-Client-v0.82.12",
                },
                {
                    distribution => "PAR-Repository",
                    pauseid => "RANGSANSUNTHORN",
                    release_author => "FLORABARRETT",
                    release_name => "PAR-Repository-0.23",
                },
                {
                    distribution => "Net-Rapidshare",
                    pauseid => "RANGSANSUNTHORN",
                    release_author => "RACHELSEGAL",
                    release_name => "Net-Rapidshare-v0.5.18",
                },
                {
                    distribution => "Tk-ForDummies-Graph",
                    pauseid => "RANGSANSUNTHORN",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Tk-ForDummies-Graph-1.2",
                },
                {
                    distribution => "makepp",
                    pauseid => "RANGSANSUNTHORN",
                    release_author => "MINSUNGJUNG",
                    release_name => "makepp-2.66",
                },
            ],
            country => "TH",
            email => ["rangsan.sunthorn\@example.th"],
            favorites => [
                {
                    author => "HEHERSONDEGUZMAN",
                    date => "2006-06-22T18:12:35",
                    distribution => "Net-Lite-FTP",
                },
                {
                    author => "AFONASEIANTONOV",
                    date => "2010-08-27T18:07:51",
                    distribution => "Crypt-OpenSSL-CA",
                },
                {
                    author => "FLORABARRETT",
                    date => "2002-02-10T02:56:54",
                    distribution => "Date-EzDate",
                },
                {
                    author => "TAKAONAKANISHI",
                    date => "2000-11-06T21:10:57",
                    distribution => "Unicode-MapUTF8",
                },
                {
                    author => "SAMANDERSON",
                    date => "2005-01-28T23:57:08",
                    distribution => "Catalyst-Plugin-Email",
                },
                {
                    author => "ANTHONYGOYETTE",
                    date => "2004-09-28T16:33:04",
                    distribution => "HTML-Macro",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/Fj4gj9s1l1LtaM5GOGVo2u8OMcMOKBvb?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/R/RA/RANGSANSUNTHORN",
                cpan_directory => "http://cpan.org/authors/id/R/RA/RANGSANSUNTHORN",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=RANGSANSUNTHORN",
                cpantesters_reports => "http://cpantesters.org/author/R/RANGSANSUNTHORN.html",
                cpants => "http://cpants.cpanauthors.org/author/RANGSANSUNTHORN",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/RANGSANSUNTHORN",
                repology => "https://repology.org/maintainer/RANGSANSUNTHORN%40cpan",
            },
            modules => {
                "Devel::SmallProf" => {
                    abstract => "per-line Perl profiler",
                    archive => "Devel-SmallProf-v2.41.7.tar.gz",
                    author => "RANGSANSUNTHORN",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "482c175ae26bd1d2f913ee62c5fb7ae6",
                    checksum_sha256 => "5b9890a04bc76622971ae2df7555e8513fcd73bdbcd9314094e49c65dddfbcba",
                    contributors => [qw( ALEXANDRAPOWELL HUWANATIENZA ELAINAREYES )],
                    date => "1998-01-12T18:54:57",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Devel-SmallProf",
                    download_url => "https://cpan.metacpan.org/authors/id/R/RA/RANGSANSUNTHORN/Devel-SmallProf-v2.41.7.tar.gz",
                    first => 0,
                    id => "qYi0zskSnsxMzNo6_LtFG2eG1l4",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Devel::SmallProf",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Devel-SmallProf",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.4,
                    },
                    name => "Devel-SmallProf",
                    package => "Devel::SmallProf",
                    provides => ["Devel::SmallProf"],
                    release => "Devel-SmallProf-v2.41.7",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 884631297, size => 6885, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "OZhP8CrvfzWAzVeCR5jSV8",
                    version => "v2.41.7",
                    version_numified => 2.041007,
                },
                Giza => {
                    abstract => "Giza Catalog References",
                    archive => "giza-0.35.tar.gz",
                    author => "RANGSANSUNTHORN",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "8a5bf041ebd57ac5c923a34639382fb9",
                    checksum_sha256 => "fd89e0e49d6ad797cd376c1ce6022817b28f429213be396fd368f19343e47971",
                    contributors => [qw( FLORABARRETT ALEXANDRAPOWELL KANTSOMSRISATI )],
                    date => "2002-05-06T12:31:19",
                    dependency => [],
                    deprecated => 0,
                    distribution => "giza",
                    download_url => "https://cpan.metacpan.org/authors/id/R/RA/RANGSANSUNTHORN/giza-0.35.tar.gz",
                    first => 1,
                    id => "AFJUNf_l2cvL3cZQ6uxwP6Z9FDg",
                    license => ["unknown"],
                    likers => [qw( AFONASEIANTONOV MINSUNGJUNG )],
                    likes => 2,
                    main_module => "Giza",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "giza",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => "v1.9.22",
                    },
                    name => "giza",
                    package => "Giza",
                    provides => [qw(
                        Giza Giza::Component Giza::Component::Rate Giza::DB
                        Giza::Handler::Forward::ClickDB Giza::Modules
                        Giza::ObjView Giza::Object Giza::Search::OpenFTS
                        Giza::Template Giza::Template::FuncLoader
                        Giza::Template::Function::Catalog
                        Giza::Template::Function::Group
                        Giza::Template::Function::Preferences
                        Giza::Template::Function::TestClass
                        Giza::Template::Function::User Giza::User
                        Giza::User::SDB Version
                    )],
                    release => "giza-0.35",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1020688279, size => 241550, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "OZhP8CrvfzWAzVeCR5jSV8",
                    version => 0.35,
                    version_numified => "0.350",
                },
                "XML::Parser" => {
                    abstract => "A perl module for parsing XML documents",
                    archive => "XML-Parser-2.78.tar.gz",
                    author => "RANGSANSUNTHORN",
                    authorized => 0,
                    changes_file => "Changes",
                    checksum_md5 => "87a728a2e64f794c45c6d1da25adbfb6",
                    checksum_sha256 => "1baa8309cad4921251b7f7d5189e7478a9767c0a6627d5985c51b56c22a6cbba",
                    contributors => [qw(
                        ALEXANDRAPOWELL BUDAEJUNG TAKASHIISHIKAWA
                        TAKASHIISHIKAWA HEHERSONDEGUZMAN
                    )],
                    date => "1999-04-27T23:27:58",
                    dependency => [],
                    deprecated => 0,
                    distribution => "XML-Parser",
                    download_url => "https://cpan.metacpan.org/authors/id/R/RA/RANGSANSUNTHORN/XML-Parser-2.78.tar.gz",
                    first => 0,
                    id => "U_ejZd7unqnnP2vRzRYvkhFRoBg",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "XML::Parser",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "XML-Parser",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 2.23,
                    },
                    name => "XML-Parser",
                    package => "XML::Parser",
                    provides => [],
                    release => "XML-Parser-2.78",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 925255678, size => 524652, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "OZhP8CrvfzWAzVeCR5jSV8",
                    version => 2.78,
                    version_numified => "2.780",
                },
            },
            name => "Rangsan Sunthorn",
            pauseid => "RANGSANSUNTHORN",
            profile => [{ id => 977547, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "OZhP8CrvfzWAzVeCR5jSV8",
        },
        SAMANDERSON => {
            asciiname => "Sam Anderson",
            city => "Miami",
            contributions => [
                {
                    distribution => "Compress-Bzip2",
                    pauseid => "SAMANDERSON",
                    release_author => "DOHYUNNCHOI",
                    release_name => "Compress-Bzip2-v2.0.11",
                },
                {
                    distribution => "China-IdentityCard-Validate",
                    pauseid => "SAMANDERSON",
                    release_author => "CHRISTIANREYES",
                    release_name => "China-IdentityCard-Validate-v2.71.3",
                },
                {
                    distribution => "Inline-MonoCS",
                    pauseid => "SAMANDERSON",
                    release_author => "KANTSOMSRISATI",
                    release_name => "Inline-MonoCS-v2.45.12",
                },
            ],
            country => "US",
            email => ["sam.anderson\@example.us"],
            favorites => [
                {
                    author => "SAMANDERSON",
                    date => "2005-03-18T02:50:56",
                    distribution => "Business-CN-IdentityCard",
                },
                {
                    author => "YOHEIFUJIWARA",
                    date => "1999-04-14T18:18:22",
                    distribution => "Tk-TIFF",
                },
                {
                    author => "YOHEIFUJIWARA",
                    date => "2009-04-19T15:29:34",
                    distribution => "DB",
                },
                {
                    author => "DUANLIN",
                    date => "2011-01-26T22:46:20",
                    distribution => "Image-VisualConfirmation",
                },
                {
                    author => "ENGYONGCHANG",
                    date => "2007-02-24T20:29:02",
                    distribution => "PDF-Create",
                },
                {
                    author => "SAMANDERSON",
                    date => "2005-01-28T23:57:08",
                    distribution => "Catalyst-Plugin-Email",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/DHCodIc5hwpPqrihuNyjjgZIatKzzLF2?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/S/SA/SAMANDERSON",
                cpan_directory => "http://cpan.org/authors/id/S/SA/SAMANDERSON",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=SAMANDERSON",
                cpantesters_reports => "http://cpantesters.org/author/S/SAMANDERSON.html",
                cpants => "http://cpants.cpanauthors.org/author/SAMANDERSON",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/SAMANDERSON",
                repology => "https://repology.org/maintainer/SAMANDERSON%40cpan",
            },
            modules => {
                "App::MathImage" => {
                    abstract => "Draw some mathematical images.",
                    archive => "math-image-v2.97.1.tar.gz",
                    author => "SAMANDERSON",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "dd14a3a41af4f3caa0137d8dbefeecdb",
                    checksum_sha256 => "6bd988e3959feb1071d3b9953d16e723af66bdb7b5440ea17add8709d95f20fa",
                    contributors => [qw( FLORABARRETT ALEXANDRAPOWELL )],
                    date => "2011-03-02T00:46:14",
                    dependency => [
                        {
                            module => "Gtk2::Ex::ComboBox::PixbufType",
                            phase => "runtime",
                            relationship => "requires",
                            version => 4,
                        },
                        {
                            module => "Gtk2::Ex::Statusbar::MessageUntilKey",
                            phase => "runtime",
                            relationship => "requires",
                            version => 11,
                        },
                        {
                            module => "Scalar::Util",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.18,
                        },
                        {
                            module => "Locale::Messages",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Compress::Zlib",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Image::Base::Multiplex",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Image::Base::Gtk2::Gdk::Pixmap",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2,
                        },
                        {
                            module => "Math::PlanePath",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1,
                        },
                        {
                            module => "Glib::Object::Subclass",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Math::PlanePath::HexSpiral",
                            phase => "runtime",
                            relationship => "requires",
                            version => 9,
                        },
                        {
                            module => "Gtk2::Ex::GdkBits",
                            phase => "runtime",
                            relationship => "requires",
                            version => 23,
                        },
                        {
                            module => "Math::PlanePath::Corner",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1,
                        },
                        {
                            module => "Gtk2::Ex::ContainerBits",
                            phase => "runtime",
                            relationship => "requires",
                            version => 21,
                        },
                        {
                            module => "Glib",
                            phase => "runtime",
                            relationship => "requires",
                            version => "1.220",
                        },
                        {
                            module => "Math::PlanePath::Staircase",
                            phase => "runtime",
                            relationship => "requires",
                            version => 16,
                        },
                        {
                            module => "Math::PlanePath::KnightSpiral",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1,
                        },
                        {
                            module => "Math::PlanePath::ZOrderCurve",
                            phase => "runtime",
                            relationship => "requires",
                            version => 13,
                        },
                        {
                            module => "Gtk2::Ex::NumAxis",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2,
                        },
                        {
                            module => "Math::PlanePath::TriangleSpiral",
                            phase => "runtime",
                            relationship => "requires",
                            version => 3,
                        },
                        {
                            module => "Gtk2::Ex::WidgetEvents",
                            phase => "runtime",
                            relationship => "requires",
                            version => 21,
                        },
                        {
                            module => "Image::Base::Gtk2::Gdk::Pixbuf",
                            phase => "runtime",
                            relationship => "requires",
                            version => 3,
                        },
                        {
                            module => "Math::PlanePath::PentSpiralSkewed",
                            phase => "runtime",
                            relationship => "requires",
                            version => 3,
                        },
                        {
                            module => "File::HomeDir",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Math::PlanePath::PeanoCurve",
                            phase => "runtime",
                            relationship => "requires",
                            version => 16,
                        },
                        {
                            module => "Gtk2::Ex::ToolbarBits",
                            phase => "runtime",
                            relationship => "requires",
                            version => 36,
                        },
                        {
                            module => "Gtk2::Ex::ComboBox::Enum",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5,
                        },
                        {
                            module => "Math::PlanePath::MultipleRings",
                            phase => "runtime",
                            relationship => "requires",
                            version => 15,
                        },
                        {
                            module => "Math::PlanePath::PyramidSides",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1,
                        },
                        {
                            module => "Gtk2::Ex::ActionTooltips",
                            phase => "runtime",
                            relationship => "requires",
                            version => 10,
                        },
                        {
                            module => "Gtk2",
                            phase => "runtime",
                            relationship => "requires",
                            version => "1.220",
                        },
                        {
                            module => "Gtk2::Ex::Dragger",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2,
                        },
                        {
                            module => "Math::PlanePath::VogelFloret",
                            phase => "runtime",
                            relationship => "requires",
                            version => 12,
                        },
                        {
                            module => "Module::Util",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Glib::Ex::SourceIds",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2,
                        },
                        {
                            module => "Number::Format",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Glib::Ex::ObjectBits",
                            phase => "runtime",
                            relationship => "requires",
                            version => 12,
                        },
                        {
                            module => "Gtk2::Ex::MenuItem::Subclass",
                            phase => "runtime",
                            relationship => "requires",
                            version => 29,
                        },
                        {
                            module => "Gtk2::Ex::MenuBits",
                            phase => "runtime",
                            relationship => "requires",
                            version => 35,
                        },
                        {
                            module => "Test::Weaken::Gtk2",
                            phase => "runtime",
                            relationship => "requires",
                            version => 17,
                        },
                        {
                            module => "Gtk2::Ex::Units",
                            phase => "runtime",
                            relationship => "requires",
                            version => 13,
                        },
                        {
                            module => "Math::Prime::XS",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.23,
                        },
                        {
                            module => "List::MoreUtils",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.24,
                        },
                        {
                            module => "Math::PlanePath::TriangleSpiralSkewed",
                            phase => "runtime",
                            relationship => "requires",
                            version => 3,
                        },
                        {
                            module => "Gtk2::Ex::WidgetCursor",
                            phase => "runtime",
                            relationship => "requires",
                            version => 15,
                        },
                        {
                            module => "Glib::Ex::ConnectProperties",
                            phase => "runtime",
                            relationship => "requires",
                            version => 14,
                        },
                        {
                            module => "Gtk2::Ex::Menu::EnumRadio",
                            phase => "runtime",
                            relationship => "requires",
                            version => 6,
                        },
                        {
                            module => "Math::PlanePath::HeptSpiralSkewed",
                            phase => "runtime",
                            relationship => "requires",
                            version => 4,
                        },
                        {
                            module => "Math::PlanePath::PyramidSpiral",
                            phase => "runtime",
                            relationship => "requires",
                            version => 3,
                        },
                        {
                            module => "Scope::Guard",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Glib::Ex::SignalBits",
                            phase => "runtime",
                            relationship => "requires",
                            version => 9,
                        },
                        {
                            module => "Locale::TextDomain",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.19,
                        },
                        {
                            module => "Glib::Ex::SignalIds",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Math::PlanePath::PixelRings",
                            phase => "runtime",
                            relationship => "requires",
                            version => 19,
                        },
                        {
                            module => "Gtk2::Ex::ToolItem::OverflowToDialog",
                            phase => "runtime",
                            relationship => "requires",
                            version => 36,
                        },
                        {
                            module => "Math::PlanePath::Columns",
                            phase => "runtime",
                            relationship => "requires",
                            version => 7,
                        },
                        {
                            module => "Math::PlanePath::HilbertCurve",
                            phase => "runtime",
                            relationship => "requires",
                            version => 13,
                        },
                        {
                            module => "Math::PlanePath::TheodorusSpiral",
                            phase => "runtime",
                            relationship => "requires",
                            version => 6,
                        },
                        {
                            module => "Math::PlanePath::SacksSpiral",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5.008,
                        },
                        {
                            module => "Gtk2::Ex::PixbufBits",
                            phase => "runtime",
                            relationship => "requires",
                            version => 37,
                        },
                        {
                            module => "Math::PlanePath::HexSpiralSkewed",
                            phase => "runtime",
                            relationship => "requires",
                            version => 9,
                        },
                        {
                            module => "Math::Libm",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Module::Pluggable",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Module::Load",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Math::PlanePath::DiamondSpiral",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1,
                        },
                        {
                            module => "Math::BaseCnv",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Math::PlanePath::SquareSpiral",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5,
                        },
                        {
                            module => "Term::Size",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Image::Base",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.14,
                        },
                        {
                            module => "Math::PlanePath::Rows",
                            phase => "runtime",
                            relationship => "requires",
                            version => 7,
                        },
                        {
                            module => "Gtk2::Ex::ToolItem::ComboEnum",
                            phase => "runtime",
                            relationship => "requires",
                            version => 28,
                        },
                        {
                            module => "Text::Capitalize",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Copy",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2.14,
                        },
                        {
                            module => "Gtk2::Pango",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Geometry::AffineTransform",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Gtk2::Ex::SyncCall",
                            phase => "runtime",
                            relationship => "requires",
                            version => 12,
                        },
                        {
                            module => "Math::PlanePath::Diagonals",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2,
                        },
                        {
                            module => "Glib::Ex::EnumBits",
                            phase => "runtime",
                            relationship => "requires",
                            version => 11,
                        },
                        {
                            module => "Image::Base::Text",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Math::PlanePath::PentSpiral",
                            phase => "runtime",
                            relationship => "requires",
                            version => 4,
                        },
                        {
                            module => "Bit::Vector",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Image::Base::Gtk2::Gdk::Window",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2,
                        },
                        {
                            module => "Math::PlanePath::PyramidRows",
                            phase => "runtime",
                            relationship => "requires",
                            version => 4,
                        },
                        {
                            module => "Software::License::GPL_3",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.001,
                        },
                        {
                            module => "Gtk2::Ex::ComboBox::Text",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2,
                        },
                        {
                            module => "Math::Aronson",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 4,
                        },
                        {
                            module => "X11::Protocol::Other",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 1,
                        },
                        {
                            module => "Image::Xpm",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 0,
                        },
                        {
                            module => "Image::Base::X11::Protocol::Window",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 0,
                        },
                        {
                            module => "X11::Protocol",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 0,
                        },
                        {
                            module => "Math::Expression::Evaluator",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 0,
                        },
                        {
                            module => "Math::Symbolic",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 0.605,
                        },
                        {
                            module => "Gtk2::Ex::ErrorTextDialog::Handler",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 7,
                        },
                        {
                            module => "Gtk2::Ex::PodViewer",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 0,
                        },
                        {
                            module => "Language::Expr",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 0.14,
                        },
                        {
                            module => "Gtk2::Ex::CrossHair",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 0,
                        },
                        {
                            module => "Image::Base::X11::Protocol::Pixmap",
                            phase => "runtime",
                            relationship => "recommends",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "math-image",
                    download_url => "https://cpan.metacpan.org/authors/id/S/SA/SAMANDERSON/math-image-v2.97.1.tar.gz",
                    first => 0,
                    id => "40MmOvf_SQx_mr8Kj9Eush14a3E",
                    license => ["open_source"],
                    likers => ["TAKASHIISHIKAWA"],
                    likes => 1,
                    main_module => "App::MathImage",
                    maturity => "released",
                    metadata => {
                        abstract => "Draw some mathematical images.",
                        author => ["Kevin Ryde <user42\@zip.com.au>"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.55_02, CPAN::Meta::Converter version 2.150005",
                        license => ["open_source"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "math-image",
                        no_index => {
                            directory => [qw(
                                t inc devel t xt inc local perl5 fatlib example blib
                                examples eg
                            )],
                        },
                        optional_features => {
                            for_x11 => {
                                description => "Things for native X through X11::Protocol.",
                                prereqs => {
                                    runtime => {
                                        requires => {
                                            "Image::Base::X11::Protocol::Pixmap" => 0,
                                            "Image::Base::X11::Protocol::Window" => 0,
                                            "X11::Protocol" => 0,
                                            "X11::Protocol::Other" => 1,
                                        },
                                    },
                                },
                            },
                            gtk2_optionals => {
                                description => "Gtk2 things used if available.",
                                prereqs => {
                                    runtime => {
                                        requires => {
                                            "Gtk2::Ex::CrossHair" => 0,
                                            "Gtk2::Ex::ErrorTextDialog::Handler" => 7,
                                            "Gtk2::Ex::PodViewer" => 0,
                                        },
                                    },
                                },
                            },
                            maximum_devel => {
                                description => "Stuff used variously for development.",
                                prereqs => {
                                    runtime => {
                                        requires => { "Pod::Simple::HTML" => 0, "warnings::unused" => 0 },
                                    },
                                },
                            },
                            maximum_interoperation => {
                                description => "All the optional things Math-Image can use.",
                                prereqs => {
                                    runtime => {
                                        requires => {
                                            "Gtk2::Ex::CrossHair" => 0,
                                            "Gtk2::Ex::ErrorTextDialog::Handler" => 7,
                                            "Gtk2::Ex::PodViewer" => 0,
                                            "Image::Base::GD" => 4,
                                            "Image::Base::Imager" => 0,
                                            "Image::Base::PNGwriter" => 2,
                                            "Image::Base::Prima" => 1,
                                            "Image::Base::X11::Protocol::Pixmap" => 0,
                                            "Image::Base::X11::Protocol::Window" => 0,
                                            "Image::Xpm" => 0,
                                            "Language::Expr" => 0.14,
                                            "Math::Aronson" => 4,
                                            "Math::Expression::Evaluator" => 0,
                                            "Math::Symbolic" => 0.605,
                                            Prima => 0,
                                            "X11::Protocol" => 0,
                                            "X11::Protocol::Other" => 1,
                                        },
                                    },
                                },
                            },
                            maximum_tests => {
                                description => "Have \"make test\" do as much as possible.",
                                prereqs => {
                                    runtime => {
                                        requires => {
                                            "Image::Base::GD" => 4,
                                            "Image::Base::PNGwriter" => 2,
                                            "Image::Xpm" => 0,
                                            "Parse::CPAN::Meta" => 0,
                                            "Test::DistManifest" => 0,
                                            "Test::Pod" => "1.00",
                                            "Test::Weaken" => 3,
                                            "Test::YAML::Meta" => 0.15,
                                            YAML => 0,
                                            "YAML::Syck" => 0,
                                            "YAML::Tiny" => 0,
                                            "YAML::XS" => 0,
                                        },
                                    },
                                },
                            },
                        },
                        prereqs => {
                            build => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            runtime => {
                                recommends => {
                                    "Gtk2::Ex::CrossHair" => 0,
                                    "Gtk2::Ex::ErrorTextDialog::Handler" => 7,
                                    "Gtk2::Ex::PodViewer" => 0,
                                    "Image::Base::X11::Protocol::Pixmap" => 0,
                                    "Image::Base::X11::Protocol::Window" => 0,
                                    "Image::Xpm" => 0,
                                    "Language::Expr" => 0.14,
                                    "Math::Aronson" => 4,
                                    "Math::Expression::Evaluator" => 0,
                                    "Math::Symbolic" => 0.605,
                                    "X11::Protocol" => 0,
                                    "X11::Protocol::Other" => 1,
                                },
                                requires => {
                                    "Bit::Vector" => 0,
                                    "Compress::Zlib" => 0,
                                    "File::Copy" => 2.14,
                                    "File::HomeDir" => 0,
                                    "Geometry::AffineTransform" => 0,
                                    Glib => "1.220",
                                    "Glib::Ex::ConnectProperties" => 14,
                                    "Glib::Ex::EnumBits" => 11,
                                    "Glib::Ex::ObjectBits" => 12,
                                    "Glib::Ex::SignalBits" => 9,
                                    "Glib::Ex::SignalIds" => 0,
                                    "Glib::Ex::SourceIds" => 2,
                                    "Glib::Object::Subclass" => 0,
                                    Gtk2 => "1.220",
                                    "Gtk2::Ex::ActionTooltips" => 10,
                                    "Gtk2::Ex::ComboBox::Enum" => 5,
                                    "Gtk2::Ex::ComboBox::PixbufType" => 4,
                                    "Gtk2::Ex::ComboBox::Text" => 2,
                                    "Gtk2::Ex::ContainerBits" => 21,
                                    "Gtk2::Ex::Dragger" => 2,
                                    "Gtk2::Ex::GdkBits" => 23,
                                    "Gtk2::Ex::Menu::EnumRadio" => 6,
                                    "Gtk2::Ex::MenuBits" => 35,
                                    "Gtk2::Ex::MenuItem::Subclass" => 29,
                                    "Gtk2::Ex::NumAxis" => 2,
                                    "Gtk2::Ex::PixbufBits" => 37,
                                    "Gtk2::Ex::Statusbar::MessageUntilKey" => 11,
                                    "Gtk2::Ex::SyncCall" => 12,
                                    "Gtk2::Ex::ToolbarBits" => 36,
                                    "Gtk2::Ex::ToolItem::ComboEnum" => 28,
                                    "Gtk2::Ex::ToolItem::OverflowToDialog" => 36,
                                    "Gtk2::Ex::Units" => 13,
                                    "Gtk2::Ex::WidgetCursor" => 15,
                                    "Gtk2::Ex::WidgetEvents" => 21,
                                    "Gtk2::Pango" => 0,
                                    "Image::Base" => 1.14,
                                    "Image::Base::Gtk2::Gdk::Pixbuf" => 3,
                                    "Image::Base::Gtk2::Gdk::Pixmap" => 2,
                                    "Image::Base::Gtk2::Gdk::Window" => 2,
                                    "Image::Base::Multiplex" => 0,
                                    "Image::Base::Text" => 0,
                                    "List::MoreUtils" => 0.24,
                                    "Locale::Messages" => 0,
                                    "Locale::TextDomain" => 1.19,
                                    "Math::BaseCnv" => 0,
                                    "Math::Libm" => 0,
                                    "Math::PlanePath" => 1,
                                    "Math::PlanePath::Columns" => 7,
                                    "Math::PlanePath::Corner" => 1,
                                    "Math::PlanePath::Diagonals" => 2,
                                    "Math::PlanePath::DiamondSpiral" => 1,
                                    "Math::PlanePath::HeptSpiralSkewed" => 4,
                                    "Math::PlanePath::HexSpiral" => 9,
                                    "Math::PlanePath::HexSpiralSkewed" => 9,
                                    "Math::PlanePath::HilbertCurve" => 13,
                                    "Math::PlanePath::KnightSpiral" => 1,
                                    "Math::PlanePath::MultipleRings" => 15,
                                    "Math::PlanePath::PeanoCurve" => 16,
                                    "Math::PlanePath::PentSpiral" => 4,
                                    "Math::PlanePath::PentSpiralSkewed" => 3,
                                    "Math::PlanePath::PixelRings" => 19,
                                    "Math::PlanePath::PyramidRows" => 4,
                                    "Math::PlanePath::PyramidSides" => 1,
                                    "Math::PlanePath::PyramidSpiral" => 3,
                                    "Math::PlanePath::Rows" => 7,
                                    "Math::PlanePath::SacksSpiral" => 1,
                                    "Math::PlanePath::SquareSpiral" => 5,
                                    "Math::PlanePath::Staircase" => 16,
                                    "Math::PlanePath::TheodorusSpiral" => 6,
                                    "Math::PlanePath::TriangleSpiral" => 3,
                                    "Math::PlanePath::TriangleSpiralSkewed" => 3,
                                    "Math::PlanePath::VogelFloret" => 12,
                                    "Math::PlanePath::ZOrderCurve" => 13,
                                    "Math::Prime::XS" => 0.23,
                                    "Module::Load" => 0,
                                    "Module::Pluggable" => 0,
                                    "Module::Util" => 0,
                                    "Number::Format" => 0,
                                    perl => 5.008,
                                    "Scalar::Util" => 1.18,
                                    "Scope::Guard" => 0,
                                    "Software::License::GPL_3" => 0.001,
                                    "Term::Size" => 0,
                                    "Test::Weaken::Gtk2" => 17,
                                    "Text::Capitalize" => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        resources => {
                            homepage => "http://user42.tuxfamily.org/math-image/index.html",
                            license => ["http://www.gnu.org/licenses/gpl.html"],
                        },
                        version => 46,
                    },
                    name => "math-image",
                    package => "App::MathImage",
                    provides => [qw(
                        App::MathImage App::MathImage::Curses::Drawing
                        App::MathImage::Curses::Main App::MathImage::Generator
                        App::MathImage::Gtk2::AboutDialog
                        App::MathImage::Gtk2::Drawing
                        App::MathImage::Gtk2::Drawing::Values
                        App::MathImage::Gtk2::Ex::AdjustmentBits
                        App::MathImage::Gtk2::Ex::DirButton
                        App::MathImage::Gtk2::Ex::GdkColorBits
                        App::MathImage::Gtk2::Ex::LayoutBits
                        App::MathImage::Gtk2::Ex::Menu::ForComboBox
                        App::MathImage::Gtk2::Ex::PixbufBits
                        App::MathImage::Gtk2::Ex::QuadScroll
                        App::MathImage::Gtk2::Ex::QuadScroll::ArrowButton
                        App::MathImage::Gtk2::Ex::ScrollButtons
                        App::MathImage::Gtk2::Ex::Splash
                        App::MathImage::Gtk2::Ex::SplashGdk
                        App::MathImage::Gtk2::Ex::Statusbar::PointerPosition
                        App::MathImage::Gtk2::Ex::ToolItem::ComboText
                        App::MathImage::Gtk2::Ex::ToolItem::ComboText::MenuItem
                        App::MathImage::Gtk2::Ex::ToolItem::ComboText::MenuView
                        App::MathImage::Gtk2::Generator
                        App::MathImage::Gtk2::Main
                        App::MathImage::Gtk2::OeisSpinButton
                        App::MathImage::Gtk2::PodDialog
                        App::MathImage::Gtk2::SaveDialog
                        App::MathImage::Gtk2::X11
                        App::MathImage::Image::Base::Caca
                        App::MathImage::Image::Base::LifeBitmap
                        App::MathImage::Image::Base::LifeRLE
                        App::MathImage::Image::Base::Magick
                        App::MathImage::Image::Base::Other
                        App::MathImage::Image::Base::X::Drawable
                        App::MathImage::Image::Base::X::Pixmap
                        App::MathImage::Iterator::Aronson
                        App::MathImage::Iterator::Simple::Aronson
                        App::MathImage::NumSeq::Array
                        App::MathImage::NumSeq::File
                        App::MathImage::NumSeq::FileWriter
                        App::MathImage::NumSeq::OeisCatalogue
                        App::MathImage::NumSeq::OeisCatalogue::Base
                        App::MathImage::NumSeq::OeisCatalogue::Plugin::BuiltinCalc
                        App::MathImage::NumSeq::OeisCatalogue::Plugin::BuiltinTable
                        App::MathImage::NumSeq::OeisCatalogue::Plugin::ZFiles
                        App::MathImage::NumSeq::Radix
                        App::MathImage::NumSeq::Sequence
                        App::MathImage::NumSeq::Sequence::AbundantNumbers
                        App::MathImage::NumSeq::Sequence::All
                        App::MathImage::NumSeq::Sequence::Aronson
                        App::MathImage::NumSeq::Sequence::Base4Without3
                        App::MathImage::NumSeq::Sequence::Beastly
                        App::MathImage::NumSeq::Sequence::BinaryLengths
                        App::MathImage::NumSeq::Sequence::ChampernowneBinary
                        App::MathImage::NumSeq::Sequence::ChampernowneBinaryLsb
                        App::MathImage::NumSeq::Sequence::Count::PrimeFactors
                        App::MathImage::NumSeq::Sequence::Cubes
                        App::MathImage::NumSeq::Sequence::Digits::DigitsModulo
                        App::MathImage::NumSeq::Sequence::Digits::Fraction
                        App::MathImage::NumSeq::Sequence::Digits::Ln2Bits
                        App::MathImage::NumSeq::Sequence::Digits::PiBits
                        App::MathImage::NumSeq::Sequence::Digits::Sqrt
                        App::MathImage::NumSeq::Sequence::Emirps
                        App::MathImage::NumSeq::Sequence::Even
                        App::MathImage::NumSeq::Sequence::Expression
                        App::MathImage::NumSeq::Sequence::Expression::LanguageExpr
                        App::MathImage::NumSeq::Sequence::Factorials
                        App::MathImage::NumSeq::Sequence::Fibonacci
                        App::MathImage::NumSeq::Sequence::GolayRudinShapiro
                        App::MathImage::NumSeq::Sequence::GoldenSequence
                        App::MathImage::NumSeq::Sequence::Lines
                        App::MathImage::NumSeq::Sequence::LinesLevel
                        App::MathImage::NumSeq::Sequence::LucasNumbers
                        App::MathImage::NumSeq::Sequence::MobiusFunction
                        App::MathImage::NumSeq::Sequence::Multiples
                        App::MathImage::NumSeq::Sequence::NumaronsonA
                        App::MathImage::NumSeq::Sequence::OEIS
                        App::MathImage::NumSeq::Sequence::OEIS::File
                        App::MathImage::NumSeq::Sequence::ObstinateNumbers
                        App::MathImage::NumSeq::Sequence::Odd
                        App::MathImage::NumSeq::Sequence::Padovan
                        App::MathImage::NumSeq::Sequence::Palindromes
                        App::MathImage::NumSeq::Sequence::PellNumbers
                        App::MathImage::NumSeq::Sequence::Pentagonal
                        App::MathImage::NumSeq::Sequence::Perrin
                        App::MathImage::NumSeq::Sequence::PlanePathCoord
                        App::MathImage::NumSeq::Sequence::PlanePathDelta
                        App::MathImage::NumSeq::Sequence::Polygonal
                        App::MathImage::NumSeq::Sequence::PrimeQuadraticEuler
                        App::MathImage::NumSeq::Sequence::PrimeQuadraticHonaker
                        App::MathImage::NumSeq::Sequence::PrimeQuadraticLegendre
                        App::MathImage::NumSeq::Sequence::Primes
                        App::MathImage::NumSeq::Sequence::Pronic
                        App::MathImage::NumSeq::Sequence::RadixWithoutDigit
                        App::MathImage::NumSeq::Sequence::RepdigitAnyBase
                        App::MathImage::NumSeq::Sequence::Repdigits
                        App::MathImage::NumSeq::Sequence::SafePrimes
                        App::MathImage::NumSeq::Sequence::SemiPrimes
                        App::MathImage::NumSeq::Sequence::SophieGermainPrimes
                        App::MathImage::NumSeq::Sequence::Squares
                        App::MathImage::NumSeq::Sequence::StarNumbers
                        App::MathImage::NumSeq::Sequence::TernaryWithout2
                        App::MathImage::NumSeq::Sequence::Tetrahedral
                        App::MathImage::NumSeq::Sequence::Triangular
                        App::MathImage::NumSeq::Sequence::Tribonacci
                        App::MathImage::NumSeq::Sequence::TwinPrimes
                        App::MathImage::NumSeq::Sequence::UndulatingNumbers
                        App::MathImage::NumSeq::Sparse
                        App::MathImage::Prima::About
                        App::MathImage::Prima::Drawing
                        App::MathImage::Prima::Generator
                        App::MathImage::Prima::Main
                        App::MathImage::X11::Generator
                        App::MathImage::X11::Protocol::Splash
                        App::MathImage::X11::Protocol::XSetRoot
                        Math::PlanePath::MathImageArchimedeanChords
                        Math::PlanePath::MathImageFlowsnake
                        Math::PlanePath::MathImageHypot
                        Math::PlanePath::MathImageOctagramSpiral
                    )],
                    release => "math-image-v2.97.1",
                    resources => {
                        homepage => "http://user42.tuxfamily.org/math-image/index.html",
                        license => ["http://www.gnu.org/licenses/gpl.html"],
                    },
                    stat => { gid => 1009, mode => 33204, mtime => 1299026774, size => 533502, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 38, na => 15, pass => 0, unknown => 0 },
                    user => "DRA8DTLSghTl8xst3DyJUR",
                    version => "v2.97.1",
                    version_numified => 2.097001,
                },
                "Business::CN::IdentityCard" => {
                    abstract => "Validate the Identity Card no. in China",
                    archive => "Business-CN-IdentityCard-v1.25.13.tar.gz",
                    author => "SAMANDERSON",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "e5b23bc06a9691dbb0b45e485e3a7549",
                    checksum_sha256 => "484e9508131d8a8fc171d66456c6390bce5fd6b9ed4d1d296dae620afe4a7b83",
                    contributors => [qw( BUDAEJUNG ELAINAREYES )],
                    date => "2005-03-18T02:50:56",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Business-CN-IdentityCard",
                    download_url => "https://cpan.metacpan.org/authors/id/S/SA/SAMANDERSON/Business-CN-IdentityCard-v1.25.13.tar.gz",
                    first => 0,
                    id => "LLTxqxAmOEpouMfeui4aLgLul6o",
                    license => ["unknown"],
                    likers => ["SAMANDERSON"],
                    likes => 1,
                    main_module => "Business::CN::IdentityCard",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.25, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Business-CN-IdentityCard",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.03,
                        x_installdirs => "site",
                        x_version_from => "lib/Business/CN/IdentityCard.pm",
                    },
                    name => "Business-CN-IdentityCard",
                    package => "Business::CN::IdentityCard",
                    provides => ["Business::CN::IdentityCard"],
                    release => "Business-CN-IdentityCard-v1.25.13",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1111114256, size => 3352, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 6, unknown => 0 },
                    user => "DRA8DTLSghTl8xst3DyJUR",
                    version => "v1.25.13",
                    version_numified => 1.025013,
                },
                "Catalyst::Plugin::Email" => {
                    abstract => "Send emails with Catalyst",
                    archive => "Catalyst-Plugin-Email-2.49.tar.gz",
                    author => "SAMANDERSON",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "7dac2252152900ade0b324caedfbf5aa",
                    checksum_sha256 => "27ded294dd8c5acd022ed15b9828d743c510b1ec5cc5fd6659e16d1e9e4376a4",
                    contributors => ["SIEUNJANG"],
                    date => "2005-01-28T23:57:08",
                    dependency => [
                        {
                            module => "Catalyst",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2.99,
                        },
                        {
                            module => "Email::Simple",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Email::Send",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Email::Simple::Creator",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Catalyst-Plugin-Email",
                    download_url => "https://cpan.metacpan.org/authors/id/S/SA/SAMANDERSON/Catalyst-Plugin-Email-2.49.tar.gz",
                    first => 1,
                    id => "BBii4C1baeKOIxvkBhPa8mmPx64",
                    license => ["unknown"],
                    likers => [qw( SAMANDERSON RANGSANSUNTHORN )],
                    likes => 2,
                    main_module => "Catalyst::Plugin::Email",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.17, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Catalyst-Plugin-Email",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => {
                                    Catalyst => 2.99,
                                    "Email::Send" => 0,
                                    "Email::Simple" => 0,
                                    "Email::Simple::Creator" => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        version => 0.01,
                        x_installdirs => "site",
                        x_version_from => "Email.pm",
                    },
                    name => "Catalyst-Plugin-Email",
                    package => "Catalyst::Plugin::Email",
                    provides => ["Catalyst::Plugin::Email"],
                    release => "Catalyst-Plugin-Email-2.49",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1106956628, size => 1496, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "DRA8DTLSghTl8xst3DyJUR",
                    version => 2.49,
                    version_numified => "2.490",
                },
                "Tk::Month" => {
                    abstract => "A collapsable frame with title.",
                    archive => "Tk-Month-v1.28.17.tar.gz",
                    author => "SAMANDERSON",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "41bc1233d4421ec6d97c120da782b733",
                    checksum_sha256 => "6e3e152d24c0d4d83d1f31991db91aa4ac73636455193145b72b0ffa6a9feefc",
                    date => "2002-11-15T19:05:55",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Tk-Month",
                    download_url => "https://cpan.metacpan.org/authors/id/S/SA/SAMANDERSON/Tk-Month-v1.28.17.tar.gz",
                    first => 0,
                    id => "sG_34fyJU9ASTZ0Bbo93IW1mIlc",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Tk::Month",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Tk-Month",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 1.3,
                    },
                    name => "Tk-Month",
                    package => "Tk::Month",
                    provides => [qw( Panel Tk::Month Tk::StrfClock )],
                    release => "Tk-Month-v1.28.17",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1037387155, size => 16021, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 3, unknown => 0 },
                    user => "DRA8DTLSghTl8xst3DyJUR",
                    version => "v1.28.17",
                    version_numified => 1.028017,
                },
            },
            name => "Sam Anderson",
            pauseid => "SAMANDERSON",
            profile => [{ id => 844983, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "DRA8DTLSghTl8xst3DyJUR",
        },
        SIEUNJANG => {
            asciiname => "Sieun Jang",
            city => "Incheon",
            contributions => [
                {
                    distribution => "DBIx-Custom",
                    pauseid => "SIEUNJANG",
                    release_author => "ELAINAREYES",
                    release_name => "DBIx-Custom-2.37",
                },
                {
                    distribution => "XML-Atom-SimpleFeed",
                    pauseid => "SIEUNJANG",
                    release_author => "OLGABOGDANOVA",
                    release_name => "XML-Atom-SimpleFeed-v0.16.11",
                },
                {
                    distribution => "Image-VisualConfirmation",
                    pauseid => "SIEUNJANG",
                    release_author => "DUANLIN",
                    release_name => "Image-VisualConfirmation-0.4",
                },
                {
                    distribution => "Math-SymbolicX-Error",
                    pauseid => "SIEUNJANG",
                    release_author => "HUWANATIENZA",
                    release_name => "Math-SymbolicX-Error-v1.2.13",
                },
                {
                    distribution => "Catalyst-Plugin-Email",
                    pauseid => "SIEUNJANG",
                    release_author => "SAMANDERSON",
                    release_name => "Catalyst-Plugin-Email-2.49",
                },
            ],
            country => "KR",
            email => ["sieun.jang\@example.kr"],
            favorites => [
                {
                    author => "AFONASEIANTONOV",
                    date => "2003-07-15T07:20:16",
                    distribution => "FileHandle-Rollback",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/j0mCnsxMrVyKsOIu1nmZxQ1pB9rDIfPj?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/S/SI/SIEUNJANG",
                cpan_directory => "http://cpan.org/authors/id/S/SI/SIEUNJANG",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=SIEUNJANG",
                cpantesters_reports => "http://cpantesters.org/author/S/SIEUNJANG.html",
                cpants => "http://cpants.cpanauthors.org/author/SIEUNJANG",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/SIEUNJANG",
                repology => "https://repology.org/maintainer/SIEUNJANG%40cpan",
            },
            modules => {
                "Bio::Chado::Schema" => {
                    abstract => "standard DBIx::Class layer for the Chado schema",
                    archive => "dbic-chado-1.0.tar.gz",
                    author => "SIEUNJANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "69cf6dce5ae613e70d6c7fb7dda1510b",
                    checksum_sha256 => "6b440b6bf3e45620e89c0fcb52fba388b020e9dcefe38e00e1b4dbb183adc1cc",
                    contributors => [qw( YOICHIFUJITA CHRISTIANREYES OLGABOGDANOVA )],
                    date => "2009-08-18T17:06:22",
                    dependency => [
                        {
                            module => "DBIx::Class",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.07,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => "v5.8.0",
                        },
                        {
                            module => "Module::Build",
                            phase => "configure",
                            relationship => "requires",
                            version => 0.34,
                        },
                    ],
                    deprecated => 0,
                    distribution => "dbic-chado",
                    download_url => "https://cpan.metacpan.org/authors/id/S/SI/SIEUNJANG/dbic-chado-1.0.tar.gz",
                    first => 0,
                    id => "XYVGTF_oJarYaCT5LxfLAXd8_rk",
                    license => ["perl_5"],
                    likers => [qw( WANTAN WANTAN )],
                    likes => 2,
                    main_module => "Bio::Chado::Schema",
                    maturity => "developer",
                    metadata => {
                        abstract => "standard DBIx::Class layer for the Chado schema",
                        author => ["Robert Buels, <rmb32\@cornell.edu>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.34, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "dbic-chado",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            configure => {
                                requires => { "Module::Build" => 0.34 },
                            },
                            runtime => {
                                requires => { "DBIx::Class" => 0.07, perl => "v5.8.0" },
                            },
                        },
                        provides => {
                            "Bio::Chado::Schema" => { file => "lib/Bio/Chado/Schema.pm" },
                            "Bio::Chado::Schema::Companalysis::Analysis" => { file => "lib/Bio/Chado/Schema/Companalysis/Analysis.pm" },
                            "Bio::Chado::Schema::Companalysis::Analysisfeature" => { file => "lib/Bio/Chado/Schema/Companalysis/Analysisfeature.pm" },
                            "Bio::Chado::Schema::Companalysis::Analysisprop" => { file => "lib/Bio/Chado/Schema/Companalysis/Analysisprop.pm" },
                            "Bio::Chado::Schema::Composite::AllFeatureNames" => { file => "lib/Bio/Chado/Schema/Composite/AllFeatureNames.pm" },
                            "Bio::Chado::Schema::Composite::Dfeatureloc" => { file => "lib/Bio/Chado/Schema/Composite/Dfeatureloc.pm" },
                            "Bio::Chado::Schema::Composite::FeatureContains" => { file => "lib/Bio/Chado/Schema/Composite/FeatureContains.pm" },
                            "Bio::Chado::Schema::Composite::FeatureDifference" => { file => "lib/Bio/Chado/Schema/Composite/FeatureDifference.pm" },
                            "Bio::Chado::Schema::Composite::FeatureDisjoint" => { file => "lib/Bio/Chado/Schema/Composite/FeatureDisjoint.pm" },
                            "Bio::Chado::Schema::Composite::FeatureDistance" => { file => "lib/Bio/Chado/Schema/Composite/FeatureDistance.pm" },
                            "Bio::Chado::Schema::Composite::FeatureIntersection" => { file => "lib/Bio/Chado/Schema/Composite/FeatureIntersection.pm" },
                            "Bio::Chado::Schema::Composite::FeatureMeets" => { file => "lib/Bio/Chado/Schema/Composite/FeatureMeets.pm" },
                            "Bio::Chado::Schema::Composite::FeatureMeetsOnSameStrand" => {
                                file => "lib/Bio/Chado/Schema/Composite/FeatureMeetsOnSameStrand.pm",
                            },
                            "Bio::Chado::Schema::Composite::FeaturesetMeets" => { file => "lib/Bio/Chado/Schema/Composite/FeaturesetMeets.pm" },
                            "Bio::Chado::Schema::Composite::FeatureUnion" => { file => "lib/Bio/Chado/Schema/Composite/FeatureUnion.pm" },
                            "Bio::Chado::Schema::Composite::FLoc" => { file => "lib/Bio/Chado/Schema/Composite/FLoc.pm" },
                            "Bio::Chado::Schema::Composite::FnrType" => { file => "lib/Bio/Chado/Schema/Composite/FnrType.pm" },
                            "Bio::Chado::Schema::Composite::FpKey" => { file => "lib/Bio/Chado/Schema/Composite/FpKey.pm" },
                            "Bio::Chado::Schema::Composite::FType" => { file => "lib/Bio/Chado/Schema/Composite/FType.pm" },
                            "Bio::Chado::Schema::Composite::Gff3atts" => { file => "lib/Bio/Chado/Schema/Composite/Gff3atts.pm" },
                            "Bio::Chado::Schema::Composite::Gff3view" => { file => "lib/Bio/Chado/Schema/Composite/Gff3view.pm" },
                            "Bio::Chado::Schema::Composite::Gffatts" => { file => "lib/Bio/Chado/Schema/Composite/Gffatts.pm" },
                            "Bio::Chado::Schema::Contact::Contact" => { file => "lib/Bio/Chado/Schema/Contact/Contact.pm" },
                            "Bio::Chado::Schema::Contact::ContactRelationship" => { file => "lib/Bio/Chado/Schema/Contact/ContactRelationship.pm" },
                            "Bio::Chado::Schema::Cv::CommonAncestorCvterm" => { file => "lib/Bio/Chado/Schema/Cv/CommonAncestorCvterm.pm" },
                            "Bio::Chado::Schema::Cv::CommonDescendantCvterm" => { file => "lib/Bio/Chado/Schema/Cv/CommonDescendantCvterm.pm" },
                            "Bio::Chado::Schema::Cv::Cv" => { file => "lib/Bio/Chado/Schema/Cv/Cv.pm" },
                            "Bio::Chado::Schema::Cv::CvCvtermCount" => { file => "lib/Bio/Chado/Schema/Cv/CvCvtermCount.pm" },
                            "Bio::Chado::Schema::Cv::CvCvtermCountWithObs" => { file => "lib/Bio/Chado/Schema/Cv/CvCvtermCountWithObs.pm" },
                            "Bio::Chado::Schema::Cv::CvLeaf" => { file => "lib/Bio/Chado/Schema/Cv/CvLeaf.pm" },
                            "Bio::Chado::Schema::Cv::CvLinkCount" => { file => "lib/Bio/Chado/Schema/Cv/CvLinkCount.pm" },
                            "Bio::Chado::Schema::Cv::CvPathCount" => { file => "lib/Bio/Chado/Schema/Cv/CvPathCount.pm" },
                            "Bio::Chado::Schema::Cv::CvRoot" => { file => "lib/Bio/Chado/Schema/Cv/CvRoot.pm" },
                            "Bio::Chado::Schema::Cv::Cvterm" => { file => "lib/Bio/Chado/Schema/Cv/Cvterm.pm" },
                            "Bio::Chado::Schema::Cv::CvtermDbxref" => { file => "lib/Bio/Chado/Schema/Cv/CvtermDbxref.pm" },
                            "Bio::Chado::Schema::Cv::Cvtermpath" => { file => "lib/Bio/Chado/Schema/Cv/Cvtermpath.pm" },
                            "Bio::Chado::Schema::Cv::Cvtermprop" => { file => "lib/Bio/Chado/Schema/Cv/Cvtermprop.pm" },
                            "Bio::Chado::Schema::Cv::CvtermRelationship" => { file => "lib/Bio/Chado/Schema/Cv/CvtermRelationship.pm" },
                            "Bio::Chado::Schema::Cv::Cvtermsynonym" => { file => "lib/Bio/Chado/Schema/Cv/Cvtermsynonym.pm" },
                            "Bio::Chado::Schema::Cv::Dbxrefprop" => { file => "lib/Bio/Chado/Schema/Cv/Dbxrefprop.pm" },
                            "Bio::Chado::Schema::Cv::StatsPathsToRoot" => { file => "lib/Bio/Chado/Schema/Cv/StatsPathsToRoot.pm" },
                            "Bio::Chado::Schema::Expression::Eimage" => { file => "lib/Bio/Chado/Schema/Expression/Eimage.pm" },
                            "Bio::Chado::Schema::Expression::Expression" => { file => "lib/Bio/Chado/Schema/Expression/Expression.pm" },
                            "Bio::Chado::Schema::Expression::ExpressionCvterm" => { file => "lib/Bio/Chado/Schema/Expression/ExpressionCvterm.pm" },
                            "Bio::Chado::Schema::Expression::ExpressionCvtermprop" => {
                                file => "lib/Bio/Chado/Schema/Expression/ExpressionCvtermprop.pm",
                            },
                            "Bio::Chado::Schema::Expression::ExpressionImage" => { file => "lib/Bio/Chado/Schema/Expression/ExpressionImage.pm" },
                            "Bio::Chado::Schema::Expression::Expressionprop" => { file => "lib/Bio/Chado/Schema/Expression/Expressionprop.pm" },
                            "Bio::Chado::Schema::Expression::ExpressionPub" => { file => "lib/Bio/Chado/Schema/Expression/ExpressionPub.pm" },
                            "Bio::Chado::Schema::Expression::FeatureExpression" => { file => "lib/Bio/Chado/Schema/Expression/FeatureExpression.pm" },
                            "Bio::Chado::Schema::Expression::FeatureExpressionprop" => {
                                file => "lib/Bio/Chado/Schema/Expression/FeatureExpressionprop.pm",
                            },
                            "Bio::Chado::Schema::General::Db" => { file => "lib/Bio/Chado/Schema/General/Db.pm" },
                            "Bio::Chado::Schema::General::DbDbxrefCount" => { file => "lib/Bio/Chado/Schema/General/DbDbxrefCount.pm" },
                            "Bio::Chado::Schema::General::Dbxref" => { file => "lib/Bio/Chado/Schema/General/Dbxref.pm" },
                            "Bio::Chado::Schema::General::Project" => { file => "lib/Bio/Chado/Schema/General/Project.pm" },
                            "Bio::Chado::Schema::General::Tableinfo" => { file => "lib/Bio/Chado/Schema/General/Tableinfo.pm" },
                            "Bio::Chado::Schema::Genetic::Environment" => { file => "lib/Bio/Chado/Schema/Genetic/Environment.pm" },
                            "Bio::Chado::Schema::Genetic::EnvironmentCvterm" => { file => "lib/Bio/Chado/Schema/Genetic/EnvironmentCvterm.pm" },
                            "Bio::Chado::Schema::Genetic::FeatureGenotype" => { file => "lib/Bio/Chado/Schema/Genetic/FeatureGenotype.pm" },
                            "Bio::Chado::Schema::Genetic::Genotype" => { file => "lib/Bio/Chado/Schema/Genetic/Genotype.pm" },
                            "Bio::Chado::Schema::Genetic::Phendesc" => { file => "lib/Bio/Chado/Schema/Genetic/Phendesc.pm" },
                            "Bio::Chado::Schema::Genetic::PhenotypeComparison" => { file => "lib/Bio/Chado/Schema/Genetic/PhenotypeComparison.pm" },
                            "Bio::Chado::Schema::Genetic::PhenotypeComparisonCvterm" => {
                                file => "lib/Bio/Chado/Schema/Genetic/PhenotypeComparisonCvterm.pm",
                            },
                            "Bio::Chado::Schema::Genetic::Phenstatement" => { file => "lib/Bio/Chado/Schema/Genetic/Phenstatement.pm" },
                            "Bio::Chado::Schema::Library::Library" => { file => "lib/Bio/Chado/Schema/Library/Library.pm" },
                            "Bio::Chado::Schema::Library::LibraryCvterm" => { file => "lib/Bio/Chado/Schema/Library/LibraryCvterm.pm" },
                            "Bio::Chado::Schema::Library::LibraryDbxref" => { file => "lib/Bio/Chado/Schema/Library/LibraryDbxref.pm" },
                            "Bio::Chado::Schema::Library::LibraryFeature" => { file => "lib/Bio/Chado/Schema/Library/LibraryFeature.pm" },
                            "Bio::Chado::Schema::Library::Libraryprop" => { file => "lib/Bio/Chado/Schema/Library/Libraryprop.pm" },
                            "Bio::Chado::Schema::Library::LibrarypropPub" => { file => "lib/Bio/Chado/Schema/Library/LibrarypropPub.pm" },
                            "Bio::Chado::Schema::Library::LibraryPub" => { file => "lib/Bio/Chado/Schema/Library/LibraryPub.pm" },
                            "Bio::Chado::Schema::Library::LibrarySynonym" => { file => "lib/Bio/Chado/Schema/Library/LibrarySynonym.pm" },
                            "Bio::Chado::Schema::Mage::Acquisition" => { file => "lib/Bio/Chado/Schema/Mage/Acquisition.pm" },
                            "Bio::Chado::Schema::Mage::Acquisitionprop" => { file => "lib/Bio/Chado/Schema/Mage/Acquisitionprop.pm" },
                            "Bio::Chado::Schema::Mage::AcquisitionRelationship" => { file => "lib/Bio/Chado/Schema/Mage/AcquisitionRelationship.pm" },
                            "Bio::Chado::Schema::Mage::Arraydesign" => { file => "lib/Bio/Chado/Schema/Mage/Arraydesign.pm" },
                            "Bio::Chado::Schema::Mage::Arraydesignprop" => { file => "lib/Bio/Chado/Schema/Mage/Arraydesignprop.pm" },
                            "Bio::Chado::Schema::Mage::Assay" => { file => "lib/Bio/Chado/Schema/Mage/Assay.pm" },
                            "Bio::Chado::Schema::Mage::AssayBiomaterial" => { file => "lib/Bio/Chado/Schema/Mage/AssayBiomaterial.pm" },
                            "Bio::Chado::Schema::Mage::AssayProject" => { file => "lib/Bio/Chado/Schema/Mage/AssayProject.pm" },
                            "Bio::Chado::Schema::Mage::Assayprop" => { file => "lib/Bio/Chado/Schema/Mage/Assayprop.pm" },
                            "Bio::Chado::Schema::Mage::Biomaterial" => { file => "lib/Bio/Chado/Schema/Mage/Biomaterial.pm" },
                            "Bio::Chado::Schema::Mage::BiomaterialDbxref" => { file => "lib/Bio/Chado/Schema/Mage/BiomaterialDbxref.pm" },
                            "Bio::Chado::Schema::Mage::Biomaterialprop" => { file => "lib/Bio/Chado/Schema/Mage/Biomaterialprop.pm" },
                            "Bio::Chado::Schema::Mage::BiomaterialRelationship" => { file => "lib/Bio/Chado/Schema/Mage/BiomaterialRelationship.pm" },
                            "Bio::Chado::Schema::Mage::BiomaterialTreatment" => { file => "lib/Bio/Chado/Schema/Mage/BiomaterialTreatment.pm" },
                            "Bio::Chado::Schema::Mage::Channel" => { file => "lib/Bio/Chado/Schema/Mage/Channel.pm" },
                            "Bio::Chado::Schema::Mage::Control" => { file => "lib/Bio/Chado/Schema/Mage/Control.pm" },
                            "Bio::Chado::Schema::Mage::Element" => { file => "lib/Bio/Chado/Schema/Mage/Element.pm" },
                            "Bio::Chado::Schema::Mage::ElementRelationship" => { file => "lib/Bio/Chado/Schema/Mage/ElementRelationship.pm" },
                            "Bio::Chado::Schema::Mage::Elementresult" => { file => "lib/Bio/Chado/Schema/Mage/Elementresult.pm" },
                            "Bio::Chado::Schema::Mage::ElementresultRelationship" => {
                                file => "lib/Bio/Chado/Schema/Mage/ElementresultRelationship.pm",
                            },
                            "Bio::Chado::Schema::Mage::Magedocumentation" => { file => "lib/Bio/Chado/Schema/Mage/Magedocumentation.pm" },
                            "Bio::Chado::Schema::Mage::Mageml" => { file => "lib/Bio/Chado/Schema/Mage/Mageml.pm" },
                            "Bio::Chado::Schema::Mage::Protocol" => { file => "lib/Bio/Chado/Schema/Mage/Protocol.pm" },
                            "Bio::Chado::Schema::Mage::Protocolparam" => { file => "lib/Bio/Chado/Schema/Mage/Protocolparam.pm" },
                            "Bio::Chado::Schema::Mage::Quantification" => { file => "lib/Bio/Chado/Schema/Mage/Quantification.pm" },
                            "Bio::Chado::Schema::Mage::Quantificationprop" => { file => "lib/Bio/Chado/Schema/Mage/Quantificationprop.pm" },
                            "Bio::Chado::Schema::Mage::QuantificationRelationship" => {
                                file => "lib/Bio/Chado/Schema/Mage/QuantificationRelationship.pm",
                            },
                            "Bio::Chado::Schema::Mage::Study" => { file => "lib/Bio/Chado/Schema/Mage/Study.pm" },
                            "Bio::Chado::Schema::Mage::StudyAssay" => { file => "lib/Bio/Chado/Schema/Mage/StudyAssay.pm" },
                            "Bio::Chado::Schema::Mage::Studydesign" => { file => "lib/Bio/Chado/Schema/Mage/Studydesign.pm" },
                            "Bio::Chado::Schema::Mage::Studydesignprop" => { file => "lib/Bio/Chado/Schema/Mage/Studydesignprop.pm" },
                            "Bio::Chado::Schema::Mage::Studyfactor" => { file => "lib/Bio/Chado/Schema/Mage/Studyfactor.pm" },
                            "Bio::Chado::Schema::Mage::Studyfactorvalue" => { file => "lib/Bio/Chado/Schema/Mage/Studyfactorvalue.pm" },
                            "Bio::Chado::Schema::Mage::Studyprop" => { file => "lib/Bio/Chado/Schema/Mage/Studyprop.pm" },
                            "Bio::Chado::Schema::Mage::StudypropFeature" => { file => "lib/Bio/Chado/Schema/Mage/StudypropFeature.pm" },
                            "Bio::Chado::Schema::Mage::Treatment" => { file => "lib/Bio/Chado/Schema/Mage/Treatment.pm" },
                            "Bio::Chado::Schema::Map::Featuremap" => { file => "lib/Bio/Chado/Schema/Map/Featuremap.pm" },
                            "Bio::Chado::Schema::Map::FeaturemapPub" => { file => "lib/Bio/Chado/Schema/Map/FeaturemapPub.pm" },
                            "Bio::Chado::Schema::Map::Featurepos" => { file => "lib/Bio/Chado/Schema/Map/Featurepos.pm" },
                            "Bio::Chado::Schema::Map::Featurerange" => { file => "lib/Bio/Chado/Schema/Map/Featurerange.pm" },
                            "Bio::Chado::Schema::Organism::Organism" => { file => "lib/Bio/Chado/Schema/Organism/Organism.pm" },
                            "Bio::Chado::Schema::Organism::OrganismDbxref" => { file => "lib/Bio/Chado/Schema/Organism/OrganismDbxref.pm" },
                            "Bio::Chado::Schema::Organism::Organismprop" => { file => "lib/Bio/Chado/Schema/Organism/Organismprop.pm" },
                            "Bio::Chado::Schema::Phenotype::FeaturePhenotype" => { file => "lib/Bio/Chado/Schema/Phenotype/FeaturePhenotype.pm" },
                            "Bio::Chado::Schema::Phenotype::Phenotype" => { file => "lib/Bio/Chado/Schema/Phenotype/Phenotype.pm" },
                            "Bio::Chado::Schema::Phenotype::PhenotypeCvterm" => { file => "lib/Bio/Chado/Schema/Phenotype/PhenotypeCvterm.pm" },
                            "Bio::Chado::Schema::Phylogeny::Phylonode" => { file => "lib/Bio/Chado/Schema/Phylogeny/Phylonode.pm" },
                            "Bio::Chado::Schema::Phylogeny::PhylonodeDbxref" => { file => "lib/Bio/Chado/Schema/Phylogeny/PhylonodeDbxref.pm" },
                            "Bio::Chado::Schema::Phylogeny::PhylonodeOrganism" => { file => "lib/Bio/Chado/Schema/Phylogeny/PhylonodeOrganism.pm" },
                            "Bio::Chado::Schema::Phylogeny::Phylonodeprop" => { file => "lib/Bio/Chado/Schema/Phylogeny/Phylonodeprop.pm" },
                            "Bio::Chado::Schema::Phylogeny::PhylonodePub" => { file => "lib/Bio/Chado/Schema/Phylogeny/PhylonodePub.pm" },
                            "Bio::Chado::Schema::Phylogeny::PhylonodeRelationship" => {
                                file => "lib/Bio/Chado/Schema/Phylogeny/PhylonodeRelationship.pm",
                            },
                            "Bio::Chado::Schema::Phylogeny::Phylotree" => { file => "lib/Bio/Chado/Schema/Phylogeny/Phylotree.pm" },
                            "Bio::Chado::Schema::Phylogeny::PhylotreePub" => { file => "lib/Bio/Chado/Schema/Phylogeny/PhylotreePub.pm" },
                            "Bio::Chado::Schema::Pub::Pub" => { file => "lib/Bio/Chado/Schema/Pub/Pub.pm" },
                            "Bio::Chado::Schema::Pub::Pubauthor" => { file => "lib/Bio/Chado/Schema/Pub/Pubauthor.pm" },
                            "Bio::Chado::Schema::Pub::PubDbxref" => { file => "lib/Bio/Chado/Schema/Pub/PubDbxref.pm" },
                            "Bio::Chado::Schema::Pub::Pubprop" => { file => "lib/Bio/Chado/Schema/Pub/Pubprop.pm" },
                            "Bio::Chado::Schema::Pub::PubRelationship" => { file => "lib/Bio/Chado/Schema/Pub/PubRelationship.pm" },
                            "Bio::Chado::Schema::Sequence::Cvtermsynonym" => { file => "lib/Bio/Chado/Schema/Sequence/Cvtermsynonym.pm" },
                            "Bio::Chado::Schema::Sequence::Feature" => { file => "lib/Bio/Chado/Schema/Sequence/Feature.pm" },
                            "Bio::Chado::Schema::Sequence::FeatureCvterm" => { file => "lib/Bio/Chado/Schema/Sequence/FeatureCvterm.pm" },
                            "Bio::Chado::Schema::Sequence::FeatureCvtermDbxref" => { file => "lib/Bio/Chado/Schema/Sequence/FeatureCvtermDbxref.pm" },
                            "Bio::Chado::Schema::Sequence::FeatureCvtermprop" => { file => "lib/Bio/Chado/Schema/Sequence/FeatureCvtermprop.pm" },
                            "Bio::Chado::Schema::Sequence::FeatureCvtermPub" => { file => "lib/Bio/Chado/Schema/Sequence/FeatureCvtermPub.pm" },
                            "Bio::Chado::Schema::Sequence::FeatureDbxref" => { file => "lib/Bio/Chado/Schema/Sequence/FeatureDbxref.pm" },
                            "Bio::Chado::Schema::Sequence::Featureloc" => { file => "lib/Bio/Chado/Schema/Sequence/Featureloc.pm" },
                            "Bio::Chado::Schema::Sequence::FeaturelocPub" => { file => "lib/Bio/Chado/Schema/Sequence/FeaturelocPub.pm" },
                            "Bio::Chado::Schema::Sequence::Featureprop" => { file => "lib/Bio/Chado/Schema/Sequence/Featureprop.pm" },
                            "Bio::Chado::Schema::Sequence::FeaturepropPub" => { file => "lib/Bio/Chado/Schema/Sequence/FeaturepropPub.pm" },
                            "Bio::Chado::Schema::Sequence::FeaturePub" => { file => "lib/Bio/Chado/Schema/Sequence/FeaturePub.pm" },
                            "Bio::Chado::Schema::Sequence::FeaturePubprop" => { file => "lib/Bio/Chado/Schema/Sequence/FeaturePubprop.pm" },
                            "Bio::Chado::Schema::Sequence::FeatureRelationship" => { file => "lib/Bio/Chado/Schema/Sequence/FeatureRelationship.pm" },
                            "Bio::Chado::Schema::Sequence::FeatureRelationshipprop" => {
                                file => "lib/Bio/Chado/Schema/Sequence/FeatureRelationshipprop.pm",
                            },
                            "Bio::Chado::Schema::Sequence::FeatureRelationshippropPub" => {
                                file => "lib/Bio/Chado/Schema/Sequence/FeatureRelationshippropPub.pm",
                            },
                            "Bio::Chado::Schema::Sequence::FeatureRelationshipPub" => {
                                file => "lib/Bio/Chado/Schema/Sequence/FeatureRelationshipPub.pm",
                            },
                            "Bio::Chado::Schema::Sequence::FeatureSynonym" => { file => "lib/Bio/Chado/Schema/Sequence/FeatureSynonym.pm" },
                            "Bio::Chado::Schema::Sequence::Synonym" => { file => "lib/Bio/Chado/Schema/Sequence/Synonym.pm" },
                            "Bio::Chado::Schema::Sequence::TypeFeatureCount" => { file => "lib/Bio/Chado/Schema/Sequence/TypeFeatureCount.pm" },
                            "Bio::Chado::Schema::Stock::Stock" => { file => "lib/Bio/Chado/Schema/Stock/Stock.pm" },
                            "Bio::Chado::Schema::Stock::Stockcollection" => { file => "lib/Bio/Chado/Schema/Stock/Stockcollection.pm" },
                            "Bio::Chado::Schema::Stock::Stockcollectionprop" => { file => "lib/Bio/Chado/Schema/Stock/Stockcollectionprop.pm" },
                            "Bio::Chado::Schema::Stock::StockcollectionStock" => { file => "lib/Bio/Chado/Schema/Stock/StockcollectionStock.pm" },
                            "Bio::Chado::Schema::Stock::StockCvterm" => { file => "lib/Bio/Chado/Schema/Stock/StockCvterm.pm" },
                            "Bio::Chado::Schema::Stock::StockDbxref" => { file => "lib/Bio/Chado/Schema/Stock/StockDbxref.pm" },
                            "Bio::Chado::Schema::Stock::StockGenotype" => { file => "lib/Bio/Chado/Schema/Stock/StockGenotype.pm" },
                            "Bio::Chado::Schema::Stock::Stockprop" => { file => "lib/Bio/Chado/Schema/Stock/Stockprop.pm" },
                            "Bio::Chado::Schema::Stock::StockpropPub" => { file => "lib/Bio/Chado/Schema/Stock/StockpropPub.pm" },
                            "Bio::Chado::Schema::Stock::StockPub" => { file => "lib/Bio/Chado/Schema/Stock/StockPub.pm" },
                            "Bio::Chado::Schema::Stock::StockRelationship" => { file => "lib/Bio/Chado/Schema/Stock/StockRelationship.pm" },
                            "Bio::Chado::Schema::Stock::StockRelationshipPub" => { file => "lib/Bio/Chado/Schema/Stock/StockRelationshipPub.pm" },
                        },
                        release_status => "testing",
                        resources => {
                            license => ["http://dev.perl.org/licenses/"],
                            repository => { url => "http://github.com/rbuels/dbic_chado" },
                        },
                        version => "0.01_03",
                    },
                    name => "dbic-chado",
                    package => "Bio::Chado::Schema",
                    provides => [qw(
                        Bio::Chado::Schema
                        Bio::Chado::Schema::Companalysis::Analysis
                        Bio::Chado::Schema::Companalysis::Analysisfeature
                        Bio::Chado::Schema::Companalysis::Analysisprop
                        Bio::Chado::Schema::Composite::AllFeatureNames
                        Bio::Chado::Schema::Composite::Dfeatureloc
                        Bio::Chado::Schema::Composite::FLoc
                        Bio::Chado::Schema::Composite::FType
                        Bio::Chado::Schema::Composite::FeatureContains
                        Bio::Chado::Schema::Composite::FeatureDifference
                        Bio::Chado::Schema::Composite::FeatureDisjoint
                        Bio::Chado::Schema::Composite::FeatureDistance
                        Bio::Chado::Schema::Composite::FeatureIntersection
                        Bio::Chado::Schema::Composite::FeatureMeets
                        Bio::Chado::Schema::Composite::FeatureMeetsOnSameStrand
                        Bio::Chado::Schema::Composite::FeatureUnion
                        Bio::Chado::Schema::Composite::FeaturesetMeets
                        Bio::Chado::Schema::Composite::FnrType
                        Bio::Chado::Schema::Composite::FpKey
                        Bio::Chado::Schema::Composite::Gff3atts
                        Bio::Chado::Schema::Composite::Gff3view
                        Bio::Chado::Schema::Composite::Gffatts
                        Bio::Chado::Schema::Contact::Contact
                        Bio::Chado::Schema::Contact::ContactRelationship
                        Bio::Chado::Schema::Cv::CommonAncestorCvterm
                        Bio::Chado::Schema::Cv::CommonDescendantCvterm
                        Bio::Chado::Schema::Cv::Cv
                        Bio::Chado::Schema::Cv::CvCvtermCount
                        Bio::Chado::Schema::Cv::CvCvtermCountWithObs
                        Bio::Chado::Schema::Cv::CvLeaf
                        Bio::Chado::Schema::Cv::CvLinkCount
                        Bio::Chado::Schema::Cv::CvPathCount
                        Bio::Chado::Schema::Cv::CvRoot
                        Bio::Chado::Schema::Cv::Cvterm
                        Bio::Chado::Schema::Cv::CvtermDbxref
                        Bio::Chado::Schema::Cv::CvtermRelationship
                        Bio::Chado::Schema::Cv::Cvtermpath
                        Bio::Chado::Schema::Cv::Cvtermprop
                        Bio::Chado::Schema::Cv::Cvtermsynonym
                        Bio::Chado::Schema::Cv::Dbxrefprop
                        Bio::Chado::Schema::Cv::StatsPathsToRoot
                        Bio::Chado::Schema::Expression::Eimage
                        Bio::Chado::Schema::Expression::Expression
                        Bio::Chado::Schema::Expression::ExpressionCvterm
                        Bio::Chado::Schema::Expression::ExpressionCvtermprop
                        Bio::Chado::Schema::Expression::ExpressionImage
                        Bio::Chado::Schema::Expression::ExpressionPub
                        Bio::Chado::Schema::Expression::Expressionprop
                        Bio::Chado::Schema::Expression::FeatureExpression
                        Bio::Chado::Schema::Expression::FeatureExpressionprop
                        Bio::Chado::Schema::General::Db
                        Bio::Chado::Schema::General::DbDbxrefCount
                        Bio::Chado::Schema::General::Dbxref
                        Bio::Chado::Schema::General::Project
                        Bio::Chado::Schema::General::Tableinfo
                        Bio::Chado::Schema::Genetic::Environment
                        Bio::Chado::Schema::Genetic::EnvironmentCvterm
                        Bio::Chado::Schema::Genetic::FeatureGenotype
                        Bio::Chado::Schema::Genetic::Genotype
                        Bio::Chado::Schema::Genetic::Phendesc
                        Bio::Chado::Schema::Genetic::PhenotypeComparison
                        Bio::Chado::Schema::Genetic::PhenotypeComparisonCvterm
                        Bio::Chado::Schema::Genetic::Phenstatement
                        Bio::Chado::Schema::Library::Library
                        Bio::Chado::Schema::Library::LibraryCvterm
                        Bio::Chado::Schema::Library::LibraryDbxref
                        Bio::Chado::Schema::Library::LibraryFeature
                        Bio::Chado::Schema::Library::LibraryPub
                        Bio::Chado::Schema::Library::LibrarySynonym
                        Bio::Chado::Schema::Library::Libraryprop
                        Bio::Chado::Schema::Library::LibrarypropPub
                        Bio::Chado::Schema::Mage::Acquisition
                        Bio::Chado::Schema::Mage::AcquisitionRelationship
                        Bio::Chado::Schema::Mage::Acquisitionprop
                        Bio::Chado::Schema::Mage::Arraydesign
                        Bio::Chado::Schema::Mage::Arraydesignprop
                        Bio::Chado::Schema::Mage::Assay
                        Bio::Chado::Schema::Mage::AssayBiomaterial
                        Bio::Chado::Schema::Mage::AssayProject
                        Bio::Chado::Schema::Mage::Assayprop
                        Bio::Chado::Schema::Mage::Biomaterial
                        Bio::Chado::Schema::Mage::BiomaterialDbxref
                        Bio::Chado::Schema::Mage::BiomaterialRelationship
                        Bio::Chado::Schema::Mage::BiomaterialTreatment
                        Bio::Chado::Schema::Mage::Biomaterialprop
                        Bio::Chado::Schema::Mage::Channel
                        Bio::Chado::Schema::Mage::Control
                        Bio::Chado::Schema::Mage::Element
                        Bio::Chado::Schema::Mage::ElementRelationship
                        Bio::Chado::Schema::Mage::Elementresult
                        Bio::Chado::Schema::Mage::ElementresultRelationship
                        Bio::Chado::Schema::Mage::Magedocumentation
                        Bio::Chado::Schema::Mage::Mageml
                        Bio::Chado::Schema::Mage::Protocol
                        Bio::Chado::Schema::Mage::Protocolparam
                        Bio::Chado::Schema::Mage::Quantification
                        Bio::Chado::Schema::Mage::QuantificationRelationship
                        Bio::Chado::Schema::Mage::Quantificationprop
                        Bio::Chado::Schema::Mage::Study
                        Bio::Chado::Schema::Mage::StudyAssay
                        Bio::Chado::Schema::Mage::Studydesign
                        Bio::Chado::Schema::Mage::Studydesignprop
                        Bio::Chado::Schema::Mage::Studyfactor
                        Bio::Chado::Schema::Mage::Studyfactorvalue
                        Bio::Chado::Schema::Mage::Studyprop
                        Bio::Chado::Schema::Mage::StudypropFeature
                        Bio::Chado::Schema::Mage::Treatment
                        Bio::Chado::Schema::Map::Featuremap
                        Bio::Chado::Schema::Map::FeaturemapPub
                        Bio::Chado::Schema::Map::Featurepos
                        Bio::Chado::Schema::Map::Featurerange
                        Bio::Chado::Schema::Organism::Organism
                        Bio::Chado::Schema::Organism::OrganismDbxref
                        Bio::Chado::Schema::Organism::Organismprop
                        Bio::Chado::Schema::Phenotype::FeaturePhenotype
                        Bio::Chado::Schema::Phenotype::Phenotype
                        Bio::Chado::Schema::Phenotype::PhenotypeCvterm
                        Bio::Chado::Schema::Phylogeny::Phylonode
                        Bio::Chado::Schema::Phylogeny::PhylonodeDbxref
                        Bio::Chado::Schema::Phylogeny::PhylonodeOrganism
                        Bio::Chado::Schema::Phylogeny::PhylonodePub
                        Bio::Chado::Schema::Phylogeny::PhylonodeRelationship
                        Bio::Chado::Schema::Phylogeny::Phylonodeprop
                        Bio::Chado::Schema::Phylogeny::Phylotree
                        Bio::Chado::Schema::Phylogeny::PhylotreePub
                        Bio::Chado::Schema::Pub::Pub
                        Bio::Chado::Schema::Pub::PubDbxref
                        Bio::Chado::Schema::Pub::PubRelationship
                        Bio::Chado::Schema::Pub::Pubauthor
                        Bio::Chado::Schema::Pub::Pubprop
                        Bio::Chado::Schema::Sequence::Cvtermsynonym
                        Bio::Chado::Schema::Sequence::Feature
                        Bio::Chado::Schema::Sequence::FeatureCvterm
                        Bio::Chado::Schema::Sequence::FeatureCvtermDbxref
                        Bio::Chado::Schema::Sequence::FeatureCvtermPub
                        Bio::Chado::Schema::Sequence::FeatureCvtermprop
                        Bio::Chado::Schema::Sequence::FeatureDbxref
                        Bio::Chado::Schema::Sequence::FeaturePub
                        Bio::Chado::Schema::Sequence::FeaturePubprop
                        Bio::Chado::Schema::Sequence::FeatureRelationship
                        Bio::Chado::Schema::Sequence::FeatureRelationshipPub
                        Bio::Chado::Schema::Sequence::FeatureRelationshipprop
                        Bio::Chado::Schema::Sequence::FeatureRelationshippropPub
                        Bio::Chado::Schema::Sequence::FeatureSynonym
                        Bio::Chado::Schema::Sequence::Featureloc
                        Bio::Chado::Schema::Sequence::FeaturelocPub
                        Bio::Chado::Schema::Sequence::Featureprop
                        Bio::Chado::Schema::Sequence::FeaturepropPub
                        Bio::Chado::Schema::Sequence::Synonym
                        Bio::Chado::Schema::Sequence::TypeFeatureCount
                        Bio::Chado::Schema::Stock::Stock
                        Bio::Chado::Schema::Stock::StockCvterm
                        Bio::Chado::Schema::Stock::StockDbxref
                        Bio::Chado::Schema::Stock::StockGenotype
                        Bio::Chado::Schema::Stock::StockPub
                        Bio::Chado::Schema::Stock::StockRelationship
                        Bio::Chado::Schema::Stock::StockRelationshipPub
                        Bio::Chado::Schema::Stock::Stockcollection
                        Bio::Chado::Schema::Stock::StockcollectionStock
                        Bio::Chado::Schema::Stock::Stockcollectionprop
                        Bio::Chado::Schema::Stock::Stockprop
                        Bio::Chado::Schema::Stock::StockpropPub
                    )],
                    release => "dbic-chado-1.0",
                    resources => {
                        license => ["http://dev.perl.org/licenses/"],
                        repository => { url => "http://github.com/rbuels/dbic_chado" },
                    },
                    stat => { gid => 1009, mode => 33204, mtime => 1250615182, size => 92816, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 15, unknown => 0 },
                    user => "jwyNCMM8uHTXSfXuci25gc",
                    version => "1.0",
                    version_numified => "1.000",
                },
                "Image::Shoehorn" => {
                    abstract => "mod_perl wrapper for Image::Shoehorn",
                    archive => "Image-Shoehorn-2.12.tar.gz",
                    author => "SIEUNJANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "53292dc6e227aba57e7cbd5e5cf3285f",
                    checksum_sha256 => "75f9501e2997babb502b20034d2e351cbf50b12924f592bd9ea683c0045d1e73",
                    date => "2002-06-18T02:53:57",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Image-Shoehorn",
                    download_url => "https://cpan.metacpan.org/authors/id/S/SI/SIEUNJANG/Image-Shoehorn-2.12.tar.gz",
                    first => 0,
                    id => "jo5_mNxtOr6_BA6UtxAZOfpe4Rs",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Image::Shoehorn",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Image-Shoehorn",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 1.2,
                    },
                    name => "Image-Shoehorn",
                    package => "Image::Shoehorn",
                    provides => [qw( Apache::ImageShoehorn Image::Shoehorn )],
                    release => "Image-Shoehorn-2.12",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1024368837, size => 31883, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "jwyNCMM8uHTXSfXuci25gc",
                    version => 2.12,
                    version_numified => "2.120",
                },
                "MooseX::Log::Log4perl" => {
                    abstract => "A Logging Role for Moose based on Log::Log4perl",
                    archive => "MooseX-Log-Log4perl-1.20.tar.gz",
                    author => "SIEUNJANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "6b672fbc787b3597905c9589ad275106",
                    checksum_sha256 => "d741c50b7857068fad10e6f09edcf9dd4e3c84dacabfcf49f6f381edda414860",
                    contributors => [qw( YOICHIFUJITA HEHERSONDEGUZMAN DUANLIN )],
                    date => "2011-08-25T16:16:20",
                    dependency => [
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 6.42,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => "v5.8.0",
                        },
                        {
                            module => "Log::Log4perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.13,
                        },
                        {
                            module => "Moose",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.65,
                        },
                        {
                            module => "IO::Scalar",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 6.42,
                        },
                    ],
                    deprecated => 0,
                    distribution => "MooseX-Log-Log4perl",
                    download_url => "https://cpan.metacpan.org/authors/id/S/SI/SIEUNJANG/MooseX-Log-Log4perl-1.20.tar.gz",
                    first => 0,
                    id => "TpU3PgJWACEYQ34Q64zu9Kn1A9o",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "MooseX::Log::Log4perl",
                    maturity => "released",
                    metadata => {
                        abstract => "A Logging Role for Moose based on Log::Log4perl",
                        author => ["Roland Lammel C<< <lammel\@cpan.org> >>"],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.94, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "MooseX-Log-Log4perl",
                        no_index => {
                            directory => [qw( inc t t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "ExtUtils::MakeMaker" => 6.42, "IO::Scalar" => 0, "Test::More" => 0 },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 6.42 },
                            },
                            runtime => {
                                requires => { "Log::Log4perl" => 1.13, Moose => 0.65, perl => "v5.8.0" },
                            },
                        },
                        release_status => "stable",
                        resources => { license => ["http://dev.perl.org/licenses/"] },
                        version => 0.41,
                    },
                    name => "MooseX-Log-Log4perl",
                    package => "MooseX::Log::Log4perl",
                    provides => [qw( MooseX::Log::Log4perl MooseX::Log::Log4perl::Easy )],
                    release => "MooseX-Log-Log4perl-1.20",
                    resources => { license => ["http://dev.perl.org/licenses/"] },
                    stat => { gid => 1009, mode => 33188, mtime => 1314288980, size => 27049, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 26, na => 0, pass => 7, unknown => 0 },
                    user => "jwyNCMM8uHTXSfXuci25gc",
                    version => "1.20",
                    version_numified => "1.200",
                },
                "Tk::Pod" => {
                    abstract => "POD browser toplevel widget",
                    archive => "Tk-Pod-2.56.tar.gz",
                    author => "SIEUNJANG",
                    authorized => 0,
                    changes_file => "Changes",
                    checksum_md5 => "00bafc3519d24fa3a886d608ae62181d",
                    checksum_sha256 => "e0922500564ab1365ec93db2aa4bc6e86c031c499d09fd99bc636269556a2d13",
                    contributors => ["HUWANATIENZA"],
                    date => "2001-06-18T00:01:39",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Tk-Pod",
                    download_url => "https://cpan.metacpan.org/authors/id/S/SI/SIEUNJANG/Tk-Pod-2.56.tar.gz",
                    first => 0,
                    id => "RKs4zdOJAsNCfTSFLSKbfmvETxo",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Tk::Pod",
                    maturity => "developer",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Tk-Pod",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "testing",
                        version => "0.99_01",
                    },
                    name => "Tk-Pod",
                    package => "Tk::Pod",
                    provides => [qw(
                        Tk::More Tk::Parse Tk::Pod Tk::Pod::FindPods
                        Tk::Pod::Search Tk::Pod::Search_db Tk::Pod::Text
                        Tk::Pod::Tree
                    )],
                    release => "Tk-Pod-2.56",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 992822499, size => 35689, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "jwyNCMM8uHTXSfXuci25gc",
                    version => 2.56,
                    version_numified => "2.560",
                },
            },
            name => "Sieun Jang",
            pauseid => "SIEUNJANG",
            profile => [{ id => 514354, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "jwyNCMM8uHTXSfXuci25gc",
        },
        TAKAONAKANISHI => {
            asciiname => "Takao Nakanishi",
            city => "Tokyo",
            contributions => [
                {
                    distribution => "Bundle-Catalyst",
                    pauseid => "TAKAONAKANISHI",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Bundle-Catalyst-2.58",
                },
                {
                    distribution => "Inline-MonoCS",
                    pauseid => "TAKAONAKANISHI",
                    release_author => "KANTSOMSRISATI",
                    release_name => "Inline-MonoCS-v2.45.12",
                },
                {
                    distribution => "File-Copy",
                    pauseid => "TAKAONAKANISHI",
                    release_author => "LILLIANSTEWART",
                    release_name => "File-Copy-1.43",
                },
                {
                    distribution => "Bundle-Catalyst",
                    pauseid => "TAKAONAKANISHI",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Bundle-Catalyst-2.58",
                },
                {
                    distribution => "Net-DNS-Nslookup",
                    pauseid => "TAKAONAKANISHI",
                    release_author => "YOICHIFUJITA",
                    release_name => "Net-DNS-Nslookup-0.73",
                },
                {
                    distribution => "PDF-API2",
                    pauseid => "TAKAONAKANISHI",
                    release_author => "WANTAN",
                    release_name => "PDF-API2-v1.24.8",
                },
                {
                    distribution => "Number-WithError-LaTeX",
                    pauseid => "TAKAONAKANISHI",
                    release_author => "WEEWANG",
                    release_name => "Number-WithError-LaTeX-v0.8.1",
                },
                {
                    distribution => "Text-PDF-API",
                    pauseid => "TAKAONAKANISHI",
                    release_author => "ANTHONYGOYETTE",
                    release_name => "Text-PDF-API-v1.9.0",
                },
            ],
            country => "JP",
            email => ["takao.nakanishi\@example.jp"],
            favorites => [
                {
                    author => "ENGYONGCHANG",
                    date => "2001-10-26T05:15:43",
                    distribution => "Net-AIM",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/XldomqXd0QyVxmM4tO3ZtZYGOViKKq4T?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/T/TA/TAKAONAKANISHI",
                cpan_directory => "http://cpan.org/authors/id/T/TA/TAKAONAKANISHI",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=TAKAONAKANISHI",
                cpantesters_reports => "http://cpantesters.org/author/T/TAKAONAKANISHI.html",
                cpants => "http://cpants.cpanauthors.org/author/TAKAONAKANISHI",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/TAKAONAKANISHI",
                repology => "https://repology.org/maintainer/TAKAONAKANISHI%40cpan",
            },
            modules => {
                "DBIx::Class::Relationship::Predicate" => {
                    abstract => "Predicate methods for relationship accessors",
                    archive => "DBIx-Class-Relationship-Predicate-v0.45.2.tar.gz",
                    author => "TAKAONAKANISHI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "4976daddfbe8624458e4104844ce5cde",
                    checksum_sha256 => "01d0b81dd81ecaf688d1a568c522913ab05594dca781cd91e1f4cc223d6fa2c8",
                    date => "2010-09-13T20:17:31",
                    dependency => [
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 6.42,
                        },
                        {
                            module => "parent",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Sub::Name",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "DBIx::Class",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 6.42,
                        },
                        {
                            module => "SQL::Translator",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "DBD::SQLite",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "DBIx-Class-Relationship-Predicate",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKAONAKANISHI/DBIx-Class-Relationship-Predicate-v0.45.2.tar.gz",
                    first => 0,
                    id => "K4P86g8Rq66ARzlswurHm8O1d3k",
                    license => ["perl_5"],
                    likers => ["ALEXANDRAPOWELL"],
                    likes => 1,
                    main_module => "DBIx::Class::Relationship::Predicate",
                    maturity => "released",
                    metadata => {
                        abstract => "Predicate methods for relationship accessors",
                        author => ["Wallace Reis <wreis\@cpan.org>"],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.91, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "DBIx-Class-Relationship-Predicate",
                        no_index => {
                            directory => [qw( inc t t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => {
                                    "DBD::SQLite" => 0,
                                    "ExtUtils::MakeMaker" => 6.42,
                                    "SQL::Translator" => 0,
                                    "Test::More" => 0,
                                },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 6.42 },
                            },
                            runtime => {
                                requires => { "DBIx::Class" => 0, parent => 0, "Sub::Name" => 0 },
                            },
                        },
                        release_status => "stable",
                        resources => { license => ["http://dev.perl.org/licenses/"] },
                        version => 0.02,
                    },
                    name => "DBIx-Class-Relationship-Predicate",
                    package => "DBIx::Class::Relationship::Predicate",
                    provides => ["DBIx::Class::Relationship::Predicate"],
                    release => "DBIx-Class-Relationship-Predicate-v0.45.2",
                    resources => { license => ["http://dev.perl.org/licenses/"] },
                    stat => { gid => 1009, mode => 33204, mtime => 1284409051, size => 24744, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 3, na => 0, pass => 92, unknown => 0 },
                    user => "LcHJp4ViYcIME9j2fAyK78",
                    version => "v0.45.2",
                    version_numified => 0.045002,
                },
                "Math::Symbolic::Custom::Transformation" => {
                    abstract => "Transform Math::Symbolic trees",
                    archive => "Math-Symbolic-Custom-Transformation-v1.64.5.tar.gz",
                    author => "TAKAONAKANISHI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "2406b68ec64d2f71e425b6f6cc40af76",
                    checksum_sha256 => "ed707214c24a181f6b28a79042836782eb1cd67fd746ed735d98989c1e45d8d5",
                    contributors => ["ALESSANDROBAUMANN"],
                    date => "2006-12-12T19:09:17",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::Pod::Coverage",
                            phase => "runtime",
                            relationship => "recommends",
                            version => "1.0",
                        },
                        {
                            module => "Test::Pod",
                            phase => "runtime",
                            relationship => "recommends",
                            version => "1.0",
                        },
                        {
                            module => "Math::Symbolic::Custom::Pattern",
                            phase => "runtime",
                            relationship => "requires",
                            version => "1.20",
                        },
                        {
                            module => "Math::Symbolic",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.163,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Math-Symbolic-Custom-Transformation",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKAONAKANISHI/Math-Symbolic-Custom-Transformation-v1.64.5.tar.gz",
                    first => 0,
                    id => "s5aDTkEEaCDpwKfkkVa80SQATEM",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "Math::Symbolic::Custom::Transformation",
                    maturity => "released",
                    metadata => {
                        abstract => "Transform Math::Symbolic trees",
                        author => [
                            "Steffen Mueller <symbolic-module at steffen-mueller dot net>",
                        ],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.280501, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Math-Symbolic-Custom-Transformation",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                recommends => { "Test::Pod" => "1.0", "Test::Pod::Coverage" => "1.0" },
                                requires => {
                                    "Math::Symbolic" => 0.163,
                                    "Math::Symbolic::Custom::Pattern" => "1.20",
                                },
                            },
                        },
                        provides => {
                            "Math::Symbolic::Custom::Transformation" => {
                                file => "lib/Math/Symbolic/Custom/Transformation.pm",
                                version => "1.20",
                            },
                        },
                        release_status => "stable",
                        resources => { license => ["http://dev.perl.org/licenses/"] },
                        version => "1.20",
                    },
                    name => "Math-Symbolic-Custom-Transformation",
                    package => "Math::Symbolic::Custom::Transformation",
                    provides => ["Math::Symbolic::Custom::Transformation"],
                    release => "Math-Symbolic-Custom-Transformation-v1.64.5",
                    resources => { license => ["http://dev.perl.org/licenses/"] },
                    stat => { gid => 1009, mode => 33188, mtime => 1165950557, size => 10845, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 1, na => 0, pass => 4, unknown => 0 },
                    user => "LcHJp4ViYcIME9j2fAyK78",
                    version => "v1.64.5",
                    version_numified => 1.064005,
                },
                "PNI::Node::Tk::Canvas" => {
                    abstract => "PNI Tk nodes",
                    archive => "PNI-Node-Tk-1.77.tar.gz",
                    author => "TAKAONAKANISHI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "fcf7f1f30634cab473e49479c85fc5b1",
                    checksum_sha256 => "4367cd6bfafda3f7b1c85185fe0133231e8bc89fee11e2a33d9a6eeb0f7314df",
                    date => "2010-05-31T14:15:57",
                    dependency => [
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "PNI",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Tk",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "PNI-Node-Tk",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKAONAKANISHI/PNI-Node-Tk-1.77.tar.gz",
                    first => 0,
                    id => "xyd9Ik5Irtgd_AXQAwpfeBvQbK4",
                    license => ["unknown"],
                    likers => ["TAKASHIISHIKAWA"],
                    likes => 1,
                    main_module => "PNI::Node::Tk::Canvas",
                    maturity => "released",
                    metadata => {
                        abstract => "PNI Tk nodes",
                        author => ["G. Casati <fibo\@cpan.org>"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.56, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "PNI-Node-Tk",
                        no_index => {
                            directory => [qw( t inc t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 0 },
                            },
                            runtime => {
                                requires => { PNI => 0, Tk => 0 },
                            },
                        },
                        release_status => "stable",
                        version => 0.02,
                    },
                    name => "PNI-Node-Tk",
                    package => "PNI::Node::Tk::Canvas",
                    provides => [qw(
                        PNI::Node::Tk::Canvas PNI::Node::Tk::Canvas::CanvasBind
                        PNI::Node::Tk::MainWindow
                    )],
                    release => "PNI-Node-Tk-1.77",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1275315357, size => 2753, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 9, unknown => 0 },
                    user => "LcHJp4ViYcIME9j2fAyK78",
                    version => 1.77,
                    version_numified => "1.770",
                },
                Queue => {
                    abstract => "Bounce mails in the defer spool",
                    archive => "glist-v1.10.5.tar.gz",
                    author => "TAKAONAKANISHI",
                    authorized => 0,
                    changes_file => "Changes",
                    checksum_md5 => "413b50d0c8b4a69a5bd3984f8c9d29d0",
                    checksum_sha256 => "ad02ce140d46252efd81056b626103e5f44c838ce59cdf5b549a4d9ad6812841",
                    contributors => ["LILLIANSTEWART"],
                    date => "2002-05-06T12:27:51",
                    dependency => [],
                    deprecated => 0,
                    distribution => "glist",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKAONAKANISHI/glist-v1.10.5.tar.gz",
                    first => 1,
                    id => "srKLFC_1DByrmNqxbJ4g1G7K3tY",
                    license => ["unknown"],
                    likers => [qw( LILLIANSTEWART CHRISTIANREYES )],
                    likes => 2,
                    main_module => "Queue",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "glist",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => "v0.9.17",
                    },
                    name => "glist",
                    package => "Queue",
                    provides => [qw(
                        Fatal::Sendmail Glist Glist::Admin Glist::Bounce
                        Glist::Gconf Glist::Pickup Glist::Rewrite Glist::Send
                        Version
                    )],
                    release => "glist-v1.10.5",
                    resources => {},
                    stat => { gid => 1009, mode => 33060, mtime => 1020688071, size => 84558, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "LcHJp4ViYcIME9j2fAyK78",
                    version => "v1.10.5",
                    version_numified => 1.010005,
                },
                "Unicode::MapUTF8" => {
                    abstract => "Conversions to and from arbitrary character sets and UTF8",
                    archive => "Unicode-MapUTF8-v0.7.17.tar.gz",
                    author => "TAKAONAKANISHI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "8847d1bba7195468246c9a86d4830df3",
                    checksum_sha256 => "b980ff9136d1dbbb98b0150acba039403e0e981c6f852ecb157509973f45bb64",
                    date => "2000-11-06T21:10:57",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Unicode-MapUTF8",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKAONAKANISHI/Unicode-MapUTF8-v0.7.17.tar.gz",
                    first => 0,
                    id => "vaXyo8PU34USwBVK9rckt_FJ4Ms",
                    license => ["unknown"],
                    likers => ["RANGSANSUNTHORN"],
                    likes => 1,
                    main_module => "Unicode::MapUTF8",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Unicode-MapUTF8",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 1.08,
                    },
                    name => "Unicode-MapUTF8",
                    package => "Unicode::MapUTF8",
                    provides => ["Unicode::MapUTF8"],
                    release => "Unicode-MapUTF8-v0.7.17",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 973545057, size => 7547, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 3, unknown => 0 },
                    user => "LcHJp4ViYcIME9j2fAyK78",
                    version => "v0.7.17",
                    version_numified => 0.007017,
                },
                "Validator::Custom::HTMLForm" => {
                    abstract => "HTML Form validator based on Validator::Custom",
                    archive => "Validator-Custom-HTMLForm-v0.40.0.tar.gz",
                    author => "TAKAONAKANISHI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "b88e362a83fdb57bbc0e0104b8283946",
                    checksum_sha256 => "c9b581a4269ea8ff52ea884e669bb5903fceedd3f2ac5390f8bc9183b583ba84",
                    contributors => [qw( YOHEIFUJIWARA ALESSANDROBAUMANN )],
                    date => "2010-01-22T13:05:41",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Time::Piece",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.15,
                        },
                        {
                            module => "DateTime::Format::Strptime",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.07,
                        },
                        {
                            module => "Email::Valid",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.15,
                        },
                        {
                            module => "Email::Valid::Loose",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.04,
                        },
                        {
                            module => "Validator::Custom::Trim",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.0401,
                        },
                        {
                            module => "Date::Calc",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5.4,
                        },
                        {
                            module => "Validator::Custom",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.0605,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Validator-Custom-HTMLForm",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKAONAKANISHI/Validator-Custom-HTMLForm-v0.40.0.tar.gz",
                    first => 0,
                    id => "GiDdnwsD2oq0Ag4TDM7QcW7m9x8",
                    license => ["perl_5"],
                    likers => [qw( KANTSOMSRISATI TAKASHIISHIKAWA )],
                    likes => 2,
                    main_module => "Validator::Custom::HTMLForm",
                    maturity => "released",
                    metadata => {
                        abstract => "HTML Form validator based on Validator::Custom",
                        author => ["Yuki Kimoto <kimoto.yuki\@gmail.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.31012, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Validator-Custom-HTMLForm",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                requires => {
                                    "Date::Calc" => 5.4,
                                    "DateTime::Format::Strptime" => 1.07,
                                    "Email::Valid" => 0.15,
                                    "Email::Valid::Loose" => 0.04,
                                    "Time::Piece" => 1.15,
                                    "Validator::Custom" => 0.0605,
                                    "Validator::Custom::Trim" => 0.0401,
                                },
                            },
                        },
                        provides => {
                            "Validator::Custom::HTMLForm" => { file => "lib/Validator/Custom/HTMLForm.pm", version => 0.0502 },
                            "Validator::Custom::HTMLForm::Constraints" => { file => "lib/Validator/Custom/HTMLForm.pm" },
                        },
                        release_status => "stable",
                        resources => {},
                        version => 0.0502,
                    },
                    name => "Validator-Custom-HTMLForm",
                    package => "Validator::Custom::HTMLForm",
                    provides => [qw(
                        Validator::Custom::HTMLForm
                        Validator::Custom::HTMLForm::Constraints
                    )],
                    release => "Validator-Custom-HTMLForm-v0.40.0",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1264165541, size => 10262, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 37, unknown => 0 },
                    user => "LcHJp4ViYcIME9j2fAyK78",
                    version => "v0.40.0",
                    version_numified => "0.040000",
                },
                "Win32::DirSize" => {
                    abstract => "Calculate sizes of directories on Win32",
                    archive => "Win32-DirSize-v2.31.15.tar.gz",
                    author => "TAKAONAKANISHI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "0017998bfd2206403111174bbb514db1",
                    checksum_sha256 => "bf6f9651e64b42a538487215cdf33d52eb04823aa82d50ca338d546466ebf30f",
                    contributors => [qw( MARINAHOTZ WANTAN )],
                    date => "2003-08-08T19:05:49",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Win32-DirSize",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKAONAKANISHI/Win32-DirSize-v2.31.15.tar.gz",
                    first => 0,
                    id => "l4ZpsRWqp_L10c3P6Nd9F880LTM",
                    license => ["unknown"],
                    likers => [qw( KANTSOMSRISATI BUDAEJUNG RACHELSEGAL )],
                    likes => 3,
                    main_module => "Win32::DirSize",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Win32-DirSize",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 1.01,
                    },
                    name => "Win32-DirSize",
                    package => "Win32::DirSize",
                    provides => ["Win32::DirSize"],
                    release => "Win32-DirSize-v2.31.15",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1060369549, size => 17908, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 0, unknown => 2 },
                    user => "LcHJp4ViYcIME9j2fAyK78",
                    version => "v2.31.15",
                    version_numified => 2.031015,
                },
                "WWW::TinySong" => {
                    abstract => "Get free music links using TinySong",
                    archive => "WWW-TinySong-0.24.tar.gz",
                    author => "TAKAONAKANISHI",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "1834fd3b871d08f363ff3a9436a89046",
                    checksum_sha256 => "98226110521143f78c4633f461110bf1e3aff5001a2a9cf62ed9beb844dcb7d0",
                    contributors => [qw( ALESSANDROBAUMANN RANGSANSUNTHORN )],
                    date => "2009-01-02T20:17:24",
                    dependency => [
                        {
                            module => "HTML::Parser",
                            phase => "runtime",
                            relationship => "requires",
                            version => 3.59,
                        },
                        {
                            module => "Carp",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.04,
                        },
                        {
                            module => "CGI",
                            phase => "runtime",
                            relationship => "requires",
                            version => 3.15,
                        },
                        {
                            module => "LWP::UserAgent",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5.822,
                        },
                    ],
                    deprecated => 0,
                    distribution => "WWW-TinySong",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKAONAKANISHI/WWW-TinySong-0.24.tar.gz",
                    first => 1,
                    id => "3Pz2fbr8hbfD4hJEmts6dopNF_k",
                    license => ["unknown"],
                    likers => ["YOICHIFUJITA"],
                    likes => 1,
                    main_module => "WWW::TinySong",
                    maturity => "developer",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.30, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "WWW-TinySong",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => {
                                    Carp => 1.04,
                                    CGI => 3.15,
                                    "HTML::Parser" => 3.59,
                                    "LWP::UserAgent" => 5.822,
                                },
                            },
                        },
                        release_status => "testing",
                        version => "0.00_01",
                        x_installdirs => "site",
                        x_version_from => "lib/WWW/TinySong.pm",
                    },
                    name => "WWW-TinySong",
                    package => "WWW::TinySong",
                    provides => ["WWW::TinySong"],
                    release => "WWW-TinySong-0.24",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1230927444, size => 3112, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 2, pass => 26, unknown => 0 },
                    user => "LcHJp4ViYcIME9j2fAyK78",
                    version => 0.24,
                    version_numified => "0.240",
                },
            },
            name => "Takao Nakanishi",
            pauseid => "TAKAONAKANISHI",
            profile => [{ id => 540845, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "LcHJp4ViYcIME9j2fAyK78",
        },
        TAKASHIISHIKAWA => {
            asciiname => "Takashi Ishikawa",
            city => "Hiroshima",
            contributions => [
                {
                    distribution => "Task-App-Physics-ParticleMotion",
                    pauseid => "TAKASHIISHIKAWA",
                    release_author => "HEHERSONDEGUZMAN",
                    release_name => "Task-App-Physics-ParticleMotion-v2.3.4",
                },
                {
                    distribution => "Image-VisualConfirmation",
                    pauseid => "TAKASHIISHIKAWA",
                    release_author => "DUANLIN",
                    release_name => "Image-VisualConfirmation-0.4",
                },
                {
                    distribution => "XML-Parser",
                    pauseid => "TAKASHIISHIKAWA",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "XML-Parser-2.78",
                },
                {
                    distribution => "CGI-Application-Plugin-Eparam",
                    pauseid => "TAKASHIISHIKAWA",
                    release_author => "MARINAHOTZ",
                    release_name => "CGI-Application-Plugin-Eparam-v2.38.1",
                },
                {
                    distribution => "Math-BooleanEval",
                    pauseid => "TAKASHIISHIKAWA",
                    release_author => "KANTSOMSRISATI",
                    release_name => "Math-BooleanEval-2.85",
                },
                {
                    distribution => "Tie-DB_File-SplitHash",
                    pauseid => "TAKASHIISHIKAWA",
                    release_author => "YOICHIFUJITA",
                    release_name => "Tie-DB_File-SplitHash-v2.4.14",
                },
                {
                    distribution => "PAR-Dist-InstallPPD-GUI",
                    pauseid => "TAKASHIISHIKAWA",
                    release_author => "ELAINAREYES",
                    release_name => "PAR-Dist-InstallPPD-GUI-2.42",
                },
                {
                    distribution => "XML-Parser",
                    pauseid => "TAKASHIISHIKAWA",
                    release_author => "RANGSANSUNTHORN",
                    release_name => "XML-Parser-2.78",
                },
                {
                    distribution => "PAR-Dist-InstallPPD-GUI",
                    pauseid => "TAKASHIISHIKAWA",
                    release_author => "ELAINAREYES",
                    release_name => "PAR-Dist-InstallPPD-GUI-2.42",
                },
            ],
            country => "JP",
            email => ["takashi.ishikawa\@example.jp"],
            favorites => [
                {
                    author => "TAKAONAKANISHI",
                    date => "2010-05-31T14:15:57",
                    distribution => "PNI-Node-Tk-Canvas",
                },
                {
                    author => "ALEXANDRAPOWELL",
                    date => "2009-09-11T23:24:21",
                    distribution => "Server-Control",
                },
                {
                    author => "AFONASEIANTONOV",
                    date => "2004-11-13T23:40:57",
                    distribution => "Apache-XPointer",
                },
                {
                    author => "SAMANDERSON",
                    date => "2011-03-02T00:46:14",
                    distribution => "App-MathImage",
                },
                {
                    author => "YOICHIFUJITA",
                    date => "2011-03-22T17:28:19",
                    distribution => "Net-DNS-Nslookup",
                },
                {
                    author => "TAKASHIISHIKAWA",
                    date => "2002-03-29T09:50:49",
                    distribution => "DBIx-dbMan",
                },
                {
                    author => "TAKAONAKANISHI",
                    date => "2010-01-22T13:05:41",
                    distribution => "Validator-Custom-HTMLForm",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/Czn5MJCz4gSa9xG1vwLGMcxDpuEf7KLs?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/T/TA/TAKASHIISHIKAWA",
                cpan_directory => "http://cpan.org/authors/id/T/TA/TAKASHIISHIKAWA",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=TAKASHIISHIKAWA",
                cpantesters_reports => "http://cpantesters.org/author/T/TAKASHIISHIKAWA.html",
                cpants => "http://cpants.cpanauthors.org/author/TAKASHIISHIKAWA",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/TAKASHIISHIKAWA",
                repology => "https://repology.org/maintainer/TAKASHIISHIKAWA%40cpan",
            },
            modules => {
                "DBIx::dbMan" => {
                    abstract => "DBIx dbMan",
                    archive => "dbMan-v0.0.17.tar.gz",
                    author => "TAKASHIISHIKAWA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "e09ce5845015e7b95133cafc80623e1a",
                    checksum_sha256 => "64e91e74b826ff1c73e43314ac62208a906aff5fc5c9bd4cdc189e6aeaf0cae5",
                    date => "2002-03-29T09:50:49",
                    dependency => [],
                    deprecated => 0,
                    distribution => "dbMan",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKASHIISHIKAWA/dbMan-v0.0.17.tar.gz",
                    first => 0,
                    id => "uDoC2lxmEHgmDVNNVB98ITBpCrw",
                    license => ["unknown"],
                    likers => [qw( FLORABARRETT TAKASHIISHIKAWA CHRISTIANREYES )],
                    likes => 3,
                    main_module => "DBIx::dbMan",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "dbMan",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.16,
                    },
                    name => "dbMan",
                    package => "DBIx::dbMan",
                    provides => [qw(
                        DBIx::dbMan DBIx::dbMan::Config DBIx::dbMan::DBI
                        DBIx::dbMan::Extension DBIx::dbMan::Extension::Authors
                        DBIx::dbMan::Extension::AutoSQL
                        DBIx::dbMan::Extension::CmdAuthors
                        DBIx::dbMan::Extension::CmdConnections
                        DBIx::dbMan::Extension::CmdDescribe
                        DBIx::dbMan::Extension::CmdEditObjects
                        DBIx::dbMan::Extension::CmdExtensions
                        DBIx::dbMan::Extension::CmdHelp
                        DBIx::dbMan::Extension::CmdHistory
                        DBIx::dbMan::Extension::CmdInputCSV
                        DBIx::dbMan::Extension::CmdInputFile
                        DBIx::dbMan::Extension::CmdOutputToFile
                        DBIx::dbMan::Extension::CmdPager
                        DBIx::dbMan::Extension::CmdSetOutputFormat
                        DBIx::dbMan::Extension::CmdShowErrors
                        DBIx::dbMan::Extension::CmdShowTables
                        DBIx::dbMan::Extension::CmdStandardSQL
                        DBIx::dbMan::Extension::CmdTransaction
                        DBIx::dbMan::Extension::Connections
                        DBIx::dbMan::Extension::Describe
                        DBIx::dbMan::Extension::DescribeCompleteOracle
                        DBIx::dbMan::Extension::DescribePg
                        DBIx::dbMan::Extension::DeviceOutput
                        DBIx::dbMan::Extension::EditFallback
                        DBIx::dbMan::Extension::EditObjects
                        DBIx::dbMan::Extension::EditObjectsOracle
                        DBIx::dbMan::Extension::EditOracle
                        DBIx::dbMan::Extension::Extensions
                        DBIx::dbMan::Extension::Fallback
                        DBIx::dbMan::Extension::HelpCommands
                        DBIx::dbMan::Extension::History
                        DBIx::dbMan::Extension::InputCSV
                        DBIx::dbMan::Extension::InputFile
                        DBIx::dbMan::Extension::LineComplete
                        DBIx::dbMan::Extension::OracleSQL
                        DBIx::dbMan::Extension::Output
                        DBIx::dbMan::Extension::OutputPager
                        DBIx::dbMan::Extension::Quit
                        DBIx::dbMan::Extension::SQLOutputHTML
                        DBIx::dbMan::Extension::SQLOutputNULL
                        DBIx::dbMan::Extension::SQLOutputPlain
                        DBIx::dbMan::Extension::SQLOutputTable
                        DBIx::dbMan::Extension::SQLShowResult
                        DBIx::dbMan::Extension::ShowTables
                        DBIx::dbMan::Extension::ShowTablesOracle
                        DBIx::dbMan::Extension::StandardSQL
                        DBIx::dbMan::Extension::Transaction
                        DBIx::dbMan::Extension::TrimCmd DBIx::dbMan::History
                        DBIx::dbMan::Interface DBIx::dbMan::Interface::cmdline
                        DBIx::dbMan::Interface::tkgui DBIx::dbMan::Lang
                        DBIx::dbMan::MemPool
                    )],
                    release => "dbMan-v0.0.17",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1017395449, size => 24051, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "Fqzl9zFeefiQwxGggM4RR9",
                    version => "v0.0.17",
                    version_numified => "0.000017",
                },
                "Facebook::Graph" => {
                    abstract => "A fast and easy way to integrate your apps with Facebook.",
                    archive => "Facebook-Graph-v0.38.18.tar.gz",
                    author => "TAKASHIISHIKAWA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "f4b5845031be58f65cb326d87e187e65",
                    checksum_sha256 => "d84865d58acbf2b967d068fbf4605f7ad7e982777e1e5715eb95f858af2c58ce",
                    contributors => [qw( FLORABARRETT MARINAHOTZ WANTAN )],
                    date => "2010-08-10T20:55:24",
                    dependency => [
                        {
                            module => "Any::Moose",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.13,
                        },
                        {
                            module => "Crypt::SSLeay",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.57,
                        },
                        {
                            module => "URI",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.54,
                        },
                        {
                            module => "LWP",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5.836,
                        },
                        {
                            module => "Test::More",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "JSON",
                            phase => "runtime",
                            relationship => "requires",
                            version => 2.16,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 6.31,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Facebook-Graph",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKASHIISHIKAWA/Facebook-Graph-v0.38.18.tar.gz",
                    first => 0,
                    id => "I_hfw75ynKtqRULmVXY7rX4rihI",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "Facebook::Graph",
                    maturity => "released",
                    metadata => {
                        abstract => "A fast and easy way to integrate your apps with Facebook.",
                        author => ["JT Smith <jt\@plainblack.com>"],
                        dynamic_config => 0,
                        generated_by => "Dist::Zilla version 4.101880, CPAN::Meta::Converter version 2.101670, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Facebook-Graph",
                        no_index => {
                            directory => [qw(
                                author.t eg t xt inc local perl5 fatlib example blib
                                examples eg
                            )],
                        },
                        prereqs => {
                            build => { requires => {} },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 6.31 },
                            },
                            runtime => {
                                requires => {
                                    "Any::Moose" => 0.13,
                                    "Crypt::SSLeay" => 0.57,
                                    JSON => 2.16,
                                    LWP => 5.836,
                                    "Test::More" => 0,
                                    URI => 1.54,
                                },
                            },
                        },
                        release_status => "stable",
                        resources => {
                            bugtracker => { web => "http://github.com/rizen/Facebook-Graph/issues" },
                            repository => { type => "git", url => "git://github.com/rizen/Facebook-Graph.git" },
                        },
                        version => "0.0500",
                    },
                    name => "Facebook-Graph",
                    package => "Facebook::Graph",
                    provides => [qw(
                        Facebook::Graph Facebook::Graph::AccessToken
                        Facebook::Graph::AccessToken::Response
                        Facebook::Graph::Authorize Facebook::Graph::Picture
                        Facebook::Graph::Publish::Post Facebook::Graph::Query
                        Facebook::Graph::Response Facebook::Graph::Role::Uri
                        Facebook::Graph::Session
                    )],
                    release => "Facebook-Graph-v0.38.18",
                    resources => {
                        bugtracker => { web => "http://github.com/rizen/Facebook-Graph/issues" },
                        repository => { url => "git://github.com/rizen/Facebook-Graph.git" },
                    },
                    stat => { gid => 1009, mode => 33204, mtime => 1281473724, size => 22147, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 2, na => 0, pass => 103, unknown => 0 },
                    user => "Fqzl9zFeefiQwxGggM4RR9",
                    version => "v0.38.18",
                    version_numified => 0.038018,
                },
                "PAR::Repository::Client" => {
                    abstract => "Access PAR repositories",
                    archive => "PAR-Repository-Client-v0.82.12.tar.gz",
                    author => "TAKASHIISHIKAWA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "09a009b3087920b5a5c8e4ade5d5a0ef",
                    checksum_sha256 => "e250ec3e5161c63341378ff62ded40582e2bd9a753da81de72e7abec25449a75",
                    contributors => [qw( YOICHIFUJITA OLGABOGDANOVA RANGSANSUNTHORN )],
                    date => "2006-08-22T12:13:18",
                    dependency => [
                        {
                            module => "YAML::Tiny",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "version",
                            phase => "runtime",
                            relationship => "requires",
                            version => "0.50",
                        },
                        {
                            module => "LWP::Simple",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "PAR::Dist",
                            phase => "runtime",
                            relationship => "requires",
                            version => "0.15_01",
                        },
                        {
                            module => "File::Spec",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Archive::Zip",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "DBM::Deep",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "PAR",
                            phase => "runtime",
                            relationship => "requires",
                            version => "0.949_01",
                        },
                    ],
                    deprecated => 0,
                    distribution => "PAR-Repository-Client",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TA/TAKASHIISHIKAWA/PAR-Repository-Client-v0.82.12.tar.gz",
                    first => 0,
                    id => "p72N1jW8UlhL5dFeDN4CHJ0_XKU",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "PAR::Repository::Client",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.17, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "PAR-Repository-Client",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => {
                                    "Archive::Zip" => 0,
                                    "DBM::Deep" => 0,
                                    "File::Spec" => 0,
                                    "LWP::Simple" => 0,
                                    PAR => "0.949_01",
                                    "PAR::Dist" => "0.15_01",
                                    version => "0.50",
                                    "YAML::Tiny" => 0,
                                },
                            },
                        },
                        release_status => "stable",
                        version => 0.04,
                        x_installdirs => "site",
                        x_version_from => "lib/PAR/Repository/Client.pm",
                    },
                    name => "PAR-Repository-Client",
                    package => "PAR::Repository::Client",
                    provides => [qw(
                        PAR::Repository::Client PAR::Repository::Client::HTTP
                        PAR::Repository::Client::Local
                    )],
                    release => "PAR-Repository-Client-v0.82.12",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1156248798, size => 8743, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "Fqzl9zFeefiQwxGggM4RR9",
                    version => "v0.82.12",
                    version_numified => 0.082012,
                },
            },
            name => "Takashi Ishikawa",
            pauseid => "TAKASHIISHIKAWA",
            profile => [{ id => 597816, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "Fqzl9zFeefiQwxGggM4RR9",
        },
        TEDDYSAPUTRA => {
            asciiname => "Teddy Saputra",
            city => "Bekasi",
            contributions => [
                {
                    distribution => "Image-VisualConfirmation",
                    pauseid => "TEDDYSAPUTRA",
                    release_author => "DUANLIN",
                    release_name => "Image-VisualConfirmation-0.4",
                },
                {
                    distribution => "DBIx-Custom-Result",
                    pauseid => "TEDDYSAPUTRA",
                    release_author => "KANTSOMSRISATI",
                    release_name => "DBIx-Custom-Result-v2.80.14",
                },
                {
                    distribution => "Compress-Bzip2",
                    pauseid => "TEDDYSAPUTRA",
                    release_author => "DOHYUNNCHOI",
                    release_name => "Compress-Bzip2-v2.0.11",
                },
                {
                    distribution => "Image-VisualConfirmation",
                    pauseid => "TEDDYSAPUTRA",
                    release_author => "DUANLIN",
                    release_name => "Image-VisualConfirmation-0.4",
                },
                {
                    distribution => "Net-DNS-Nslookup",
                    pauseid => "TEDDYSAPUTRA",
                    release_author => "YOICHIFUJITA",
                    release_name => "Net-DNS-Nslookup-0.73",
                },
                {
                    distribution => "Var-State",
                    pauseid => "TEDDYSAPUTRA",
                    release_author => "BUDAEJUNG",
                    release_name => "Var-State-v0.44.6",
                },
            ],
            country => "ID",
            email => ["teddy.saputra\@example.id"],
            favorites => [
                {
                    author => "HEHERSONDEGUZMAN",
                    date => "2011-05-19T20:18:35",
                    distribution => "Test-Spec",
                },
                {
                    author => "HEHERSONDEGUZMAN",
                    date => "2011-05-19T20:18:35",
                    distribution => "Test-Spec",
                },
                {
                    author => "FLORABARRETT",
                    date => "2002-02-10T02:56:54",
                    distribution => "Date-EzDate",
                },
                {
                    author => "YOHEIFUJIWARA",
                    date => "2009-04-19T15:29:34",
                    distribution => "DB",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/PD0FQIOKUBzU9nrA1qb7IGCoAN0bL8hn?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/T/TE/TEDDYSAPUTRA",
                cpan_directory => "http://cpan.org/authors/id/T/TE/TEDDYSAPUTRA",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=TEDDYSAPUTRA",
                cpantesters_reports => "http://cpantesters.org/author/T/TEDDYSAPUTRA.html",
                cpants => "http://cpants.cpanauthors.org/author/TEDDYSAPUTRA",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/TEDDYSAPUTRA",
                repology => "https://repology.org/maintainer/TEDDYSAPUTRA%40cpan",
            },
            modules => {
                "Config::MVP::Reader::INI" => {
                    abstract => "an MVP config reader for .ini files",
                    archive => "Config-MVP-Reader-INI-v1.91.19.tar.gz",
                    author => "TEDDYSAPUTRA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "2c5876ecc396ebdd2c04e296a4a2434e",
                    checksum_sha256 => "7197dff2c517a5dbf5cacda0e09042f44739ecadde68aa5b07ba9b83c9f55ef9",
                    contributors => ["RACHELSEGAL"],
                    date => "2010-05-26T12:32:01",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "test",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Config::INI::Reader",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Moose",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Config::MVP",
                            phase => "runtime",
                            relationship => "requires",
                            version => "0.101440",
                        },
                        {
                            module => "Config::MVP::Reader::Findable::ByExtension",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 6.31,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Config-MVP-Reader-INI",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TE/TEDDYSAPUTRA/Config-MVP-Reader-INI-v1.91.19.tar.gz",
                    first => 0,
                    id => "BDHWF4BDVPuPP1rXYRXwoRfQ0Dk",
                    license => ["perl_5"],
                    likers => [qw( CHRISTIANREYES ANTHONYGOYETTE )],
                    likes => 2,
                    main_module => "Config::MVP::Reader::INI",
                    maturity => "released",
                    metadata => {
                        abstract => "an MVP config reader for .ini files",
                        author => ["Ricardo Signes <rjbs\@cpan.org>"],
                        dynamic_config => 0,
                        generated_by => "Dist::Zilla version 3.101450, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Config-MVP-Reader-INI",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 6.31 },
                            },
                            runtime => {
                                requires => {
                                    "Config::INI::Reader" => 0,
                                    "Config::MVP" => "0.101440",
                                    "Config::MVP::Reader::Findable::ByExtension" => 0,
                                    Moose => 0,
                                },
                            },
                            test => {
                                requires => { "Test::More" => 0 },
                            },
                        },
                        release_status => "stable",
                        resources => {
                            repository => { type => "git", url => "git://git.codesimply.com/Config-INI-MVP.git" },
                        },
                        version => "1.101460",
                        x_Dist_Zilla => {
                            plugins => [
                                {
                                    class => "Dist::Zilla::Plugin::GatherDir",
                                    name => "\@RJBS/\@Basic/GatherDir",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::PruneCruft",
                                    name => "\@RJBS/\@Basic/PruneCruft",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::ManifestSkip",
                                    name => "\@RJBS/\@Basic/ManifestSkip",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::MetaYAML",
                                    name => "\@RJBS/\@Basic/MetaYAML",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::License",
                                    name => "\@RJBS/\@Basic/License",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Readme",
                                    name => "\@RJBS/\@Basic/Readme",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::ExtraTests",
                                    name => "\@RJBS/\@Basic/ExtraTests",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::ExecDir",
                                    name => "\@RJBS/\@Basic/ExecDir",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::ShareDir",
                                    name => "\@RJBS/\@Basic/ShareDir",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::MakeMaker",
                                    name => "\@RJBS/\@Basic/MakeMaker",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Manifest",
                                    name => "\@RJBS/\@Basic/Manifest",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::TestRelease",
                                    name => "\@RJBS/\@Basic/TestRelease",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::ConfirmRelease",
                                    name => "\@RJBS/\@Basic/ConfirmRelease",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::UploadToCPAN",
                                    name => "\@RJBS/\@Basic/UploadToCPAN",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::AutoPrereq",
                                    name => "\@RJBS/AutoPrereq",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::AutoVersion",
                                    name => "\@RJBS/AutoVersion",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::PkgVersion",
                                    name => "\@RJBS/PkgVersion",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::MetaConfig",
                                    name => "\@RJBS/MetaConfig",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::MetaJSON",
                                    name => "\@RJBS/MetaJSON",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::NextRelease",
                                    name => "\@RJBS/NextRelease",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::PodSyntaxTests",
                                    name => "\@RJBS/PodSyntaxTests",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Repository",
                                    name => "\@RJBS/Repository",
                                    version => 0.13,
                                },
                                {
                                    class => "Dist::Zilla::Plugin::PodWeaver",
                                    name => "\@RJBS/PodWeaver",
                                    version => "3.100710",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Git::Check",
                                    name => "\@RJBS/\@Git/Check",
                                    version => "1.101330",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Git::Commit",
                                    name => "\@RJBS/\@Git/Commit",
                                    version => "1.101330",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Git::Tag",
                                    name => "\@RJBS/\@Git/Tag",
                                    version => "1.101330",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::Git::Push",
                                    name => "\@RJBS/\@Git/Push",
                                    version => "1.101330",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::FinderCode",
                                    name => ":InstallModules",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::FinderCode",
                                    name => ":TestFiles",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::FinderCode",
                                    name => ":ExecFiles",
                                    version => "3.101450",
                                },
                                {
                                    class => "Dist::Zilla::Plugin::FinderCode",
                                    name => ":ShareFiles",
                                    version => "3.101450",
                                },
                            ],
                            zilla => {
                                class => "Dist::Zilla",
                                config => { is_trial => 0 },
                                version => "3.101450",
                            },
                        },
                    },
                    name => "Config-MVP-Reader-INI",
                    package => "Config::MVP::Reader::INI",
                    provides => ["Config::MVP::Reader::INI"],
                    release => "Config-MVP-Reader-INI-v1.91.19",
                    resources => {
                        repository => { type => "git", url => "git://git.codesimply.com/Config-INI-MVP.git" },
                    },
                    stat => { gid => 1009, mode => 33204, mtime => 1274877121, size => 11136, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 39, na => 0, pass => 19, unknown => 0 },
                    user => "kdUafvI0kyGXj0OlfmsGaf",
                    version => "v1.91.19",
                    version_numified => 1.091019,
                },
                "DBIx::Custom::MySQL" => {
                    abstract => "DBIx::Custom MySQL implementation",
                    archive => "DBIx-Custom-MySQL-1.40.tar.gz",
                    author => "TEDDYSAPUTRA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "331a97fdd0c4e8caf1fc22b2885c5ec1",
                    checksum_sha256 => "00f362e9fec8259df9bb67ae35f038a0104f078e3c194185127b686bfcf35bdd",
                    contributors => [qw( HELEWISEGIROUX YOHEIFUJIWARA LILLIANSTEWART ANTHONYGOYETTE )],
                    date => "2009-11-08T04:18:41",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "DBIx::Custom::Basic",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.0101,
                        },
                        {
                            module => "DBD::mysql",
                            phase => "runtime",
                            relationship => "requires",
                            version => 4.01,
                        },
                    ],
                    deprecated => 0,
                    distribution => "DBIx-Custom-MySQL",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TE/TEDDYSAPUTRA/DBIx-Custom-MySQL-1.40.tar.gz",
                    first => 1,
                    id => "Rn2KapeIX1n6Pa3KeflPcpp74Ls",
                    license => ["perl_5"],
                    likers => ["CHRISTIANREYES"],
                    likes => 1,
                    main_module => "DBIx::Custom::MySQL",
                    maturity => "released",
                    metadata => {
                        abstract => "DBIx::Custom MySQL implementation",
                        author => ["Yuki Kimoto <kimoto.yuki\@gmail.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.31012, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "DBIx-Custom-MySQL",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                requires => { "DBD::mysql" => 4.01, "DBIx::Custom::Basic" => 0.0101 },
                            },
                        },
                        provides => {
                            "DBIx::Custom::MySQL" => { file => "lib/DBIx/Custom/MySQL.pm", version => 0.0101 },
                        },
                        release_status => "stable",
                        resources => {},
                        version => 0.0101,
                    },
                    name => "DBIx-Custom-MySQL",
                    package => "DBIx::Custom::MySQL",
                    provides => ["DBIx::Custom::MySQL"],
                    release => "DBIx-Custom-MySQL-1.40",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1257653921, size => 3617, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 29, unknown => 1 },
                    user => "kdUafvI0kyGXj0OlfmsGaf",
                    version => "1.40",
                    version_numified => "1.400",
                },
                "Math::Symbolic::Custom::Pattern" => {
                    abstract => "Pattern matching on Math::Symbolic trees",
                    archive => "Math-Symbolic-Custom-Pattern-v1.68.6.tar.gz",
                    author => "TEDDYSAPUTRA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "3bab741538bc205bbd8368ba4c0d80e7",
                    checksum_sha256 => "243db32c4c49d22ec84683b830e484185c9c2650db41375a7e5bed7fa3412418",
                    contributors => [qw( HELEWISEGIROUX ALESSANDROBAUMANN )],
                    date => "2005-10-23T16:25:35",
                    dependency => [
                        {
                            module => "Test::Pod::Coverage",
                            phase => "runtime",
                            relationship => "recommends",
                            version => "1.0",
                        },
                        {
                            module => "Test::Pod",
                            phase => "runtime",
                            relationship => "recommends",
                            version => "1.0",
                        },
                        {
                            module => "Math::Symbolic",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.162,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Math-Symbolic-Custom-Pattern",
                    download_url => "https://cpan.metacpan.org/authors/id/T/TE/TEDDYSAPUTRA/Math-Symbolic-Custom-Pattern-v1.68.6.tar.gz",
                    first => 0,
                    id => "8a_r3tD991ESRV6_mz_4TBdXbLg",
                    license => ["perl_5"],
                    likers => [qw( AFONASEIANTONOV LILLIANSTEWART )],
                    likes => 2,
                    main_module => "Math::Symbolic::Custom::Pattern",
                    maturity => "released",
                    metadata => {
                        abstract => "Pattern matching on Math::Symbolic trees",
                        author => [
                            "Steffen Mueller <symbolic-module at steffen-mueller dot net>",
                        ],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.2608, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Math-Symbolic-Custom-Pattern",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                recommends => { "Test::Pod" => "1.0", "Test::Pod::Coverage" => "1.0" },
                                requires => { "Math::Symbolic" => 0.162 },
                            },
                        },
                        provides => {
                            "Math::Symbolic::Custom::Pattern" => { file => "lib/Math/Symbolic/Custom/Pattern.pm", version => "1.10" },
                            "Math::Symbolic::Custom::Pattern::Export" => {
                                file => "lib/Math/Symbolic/Custom/Pattern/Export.pm",
                                version => "1.10",
                            },
                        },
                        release_status => "stable",
                        version => "1.10",
                    },
                    name => "Math-Symbolic-Custom-Pattern",
                    package => "Math::Symbolic::Custom::Pattern",
                    provides => [qw(
                        Math::Symbolic::Custom::Pattern
                        Math::Symbolic::Custom::Pattern::Export
                    )],
                    release => "Math-Symbolic-Custom-Pattern-v1.68.6",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1130084735, size => 8737, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 2, na => 0, pass => 4, unknown => 0 },
                    user => "kdUafvI0kyGXj0OlfmsGaf",
                    version => "v1.68.6",
                    version_numified => 1.068006,
                },
            },
            name => "Teddy Saputra",
            pauseid => "TEDDYSAPUTRA",
            profile => [{ id => 774550, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "kdUafvI0kyGXj0OlfmsGaf",
        },
        WANTAN => {
            asciiname => "Wan Tan",
            city => "Singapore",
            contributions => [
                {
                    distribution => "POE-Component-Client-Keepalive",
                    pauseid => "WANTAN",
                    release_author => "HELEWISEGIROUX",
                    release_name => "POE-Component-Client-Keepalive-1.69",
                },
                {
                    distribution => "POE-Component-Client-Keepalive",
                    pauseid => "WANTAN",
                    release_author => "HELEWISEGIROUX",
                    release_name => "POE-Component-Client-Keepalive-1.69",
                },
                {
                    distribution => "PAR-Dist-InstallPPD-GUI",
                    pauseid => "WANTAN",
                    release_author => "ELAINAREYES",
                    release_name => "PAR-Dist-InstallPPD-GUI-2.42",
                },
                {
                    distribution => "IPC-Door",
                    pauseid => "WANTAN",
                    release_author => "ENGYONGCHANG",
                    release_name => "IPC-Door-v1.92.3",
                },
                {
                    distribution => "Facebook-Graph",
                    pauseid => "WANTAN",
                    release_author => "TAKASHIISHIKAWA",
                    release_name => "Facebook-Graph-v0.38.18",
                },
                {
                    distribution => "DBIx-Custom",
                    pauseid => "WANTAN",
                    release_author => "ELAINAREYES",
                    release_name => "DBIx-Custom-2.37",
                },
                {
                    distribution => "IPC-Door",
                    pauseid => "WANTAN",
                    release_author => "ENGYONGCHANG",
                    release_name => "IPC-Door-v1.92.3",
                },
                {
                    distribution => "Win32-DirSize",
                    pauseid => "WANTAN",
                    release_author => "TAKAONAKANISHI",
                    release_name => "Win32-DirSize-v2.31.15",
                },
                {
                    distribution => "Task-Dancer",
                    pauseid => "WANTAN",
                    release_author => "LILLIANSTEWART",
                    release_name => "Task-Dancer-2.83",
                },
            ],
            country => "SG",
            email => ["wan.tan\@example.sg"],
            favorites => [
                {
                    author => "LILLIANSTEWART",
                    date => "2010-03-06T13:55:15",
                    distribution => "Task-Dancer",
                },
                {
                    author => "SIEUNJANG",
                    date => "2009-08-18T17:06:22",
                    distribution => "Bio-Chado-Schema",
                },
                {
                    author => "LILLIANSTEWART",
                    date => "2010-03-06T13:55:15",
                    distribution => "Task-Dancer",
                },
                {
                    author => "SIEUNJANG",
                    date => "2009-08-18T17:06:22",
                    distribution => "Bio-Chado-Schema",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/8bNwJBjpWOUsJMbhhpde7OilITAPYVQ9?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/W/WA/WANTAN",
                cpan_directory => "http://cpan.org/authors/id/W/WA/WANTAN",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=WANTAN",
                cpantesters_reports => "http://cpantesters.org/author/W/WANTAN.html",
                cpants => "http://cpants.cpanauthors.org/author/WANTAN",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/WANTAN",
                repology => "https://repology.org/maintainer/WANTAN%40cpan",
            },
            modules => {
                "DBIx::Custom::SQLite" => {
                    abstract => "DBIx::Custom SQLite implementation",
                    archive => "DBIx-Custom-SQLite-0.2.tar.gz",
                    author => "WANTAN",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "a63c3923e7f6e4267516dbeda925644f",
                    checksum_sha256 => "0af123551dff95f9654f4fbc24e945c5d6481b92e67b8e03ca91ef4c83088cc7",
                    contributors => ["FLORABARRETT"],
                    date => "2009-11-08T04:20:31",
                    dependency => [
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "DBD::SQLite",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.25,
                        },
                        {
                            module => "DBIx::Custom::Basic",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.0101,
                        },
                    ],
                    deprecated => 0,
                    distribution => "DBIx-Custom-SQLite",
                    download_url => "https://cpan.metacpan.org/authors/id/W/WA/WANTAN/DBIx-Custom-SQLite-0.2.tar.gz",
                    first => 1,
                    id => "zpVA3zMoUhx0mj8Cn4YC9CuFyA8",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "DBIx::Custom::SQLite",
                    maturity => "released",
                    metadata => {
                        abstract => "DBIx::Custom SQLite implementation",
                        author => ["Yuki Kimoto <kimoto.yuki\@gmail.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.31012, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "DBIx-Custom-SQLite",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::More" => 0 },
                            },
                            runtime => {
                                requires => { "DBD::SQLite" => 1.25, "DBIx::Custom::Basic" => 0.0101 },
                            },
                        },
                        provides => {
                            "DBIx::Custom::SQLite" => { file => "lib/DBIx/Custom/SQLite.pm", version => 0.0101 },
                        },
                        release_status => "stable",
                        resources => {},
                        version => 0.0101,
                    },
                    name => "DBIx-Custom-SQLite",
                    package => "DBIx::Custom::SQLite",
                    provides => ["DBIx::Custom::SQLite"],
                    release => "DBIx-Custom-SQLite-0.2",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1257654031, size => 3927, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 8, na => 0, pass => 46, unknown => 1 },
                    user => "A7MVzNYFOqkSGx0YwDeOMf",
                    version => 0.2,
                    version_numified => "0.200",
                },
                DTS => {
                    abstract => "Perl classes to access Microsoft SQL Server 2000 DTS Packages",
                    archive => "DTS-0.64.tar.gz",
                    author => "WANTAN",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "942fe222a638e3d8f9c0de535ae93297",
                    checksum_sha256 => "60ba591eda9ad926151c253582cfe09b8d5db2c72e0386e376e9e920af67e145",
                    contributors => ["HEHERSONDEGUZMAN"],
                    date => "2007-10-16T21:45:17",
                    dependency => [
                        {
                            module => "Hash::Util",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.05,
                        },
                        {
                            module => "Carp",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.04,
                        },
                        {
                            module => "Class::Accessor",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.25,
                        },
                        {
                            module => "DateTime",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.35,
                        },
                        {
                            module => "Win32::OLE",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.1704,
                        },
                    ],
                    deprecated => 0,
                    distribution => "DTS",
                    download_url => "https://cpan.metacpan.org/authors/id/W/WA/WANTAN/DTS-0.64.tar.gz",
                    first => 0,
                    id => "nGHmFCSVmbq_qQgKlDJGHCSjGH4",
                    license => ["unknown"],
                    likers => [qw( ANTHONYGOYETTE MINSUNGJUNG )],
                    likes => 2,
                    main_module => "DTS",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.30, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "DTS",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => {
                                    Carp => 1.04,
                                    "Class::Accessor" => 0.25,
                                    DateTime => 0.35,
                                    "Hash::Util" => 0.05,
                                    "Win32::OLE" => 0.1704,
                                },
                            },
                        },
                        release_status => "stable",
                        version => 0.02,
                        x_installdirs => "site",
                        x_version_from => "lib/DTS.pm",
                    },
                    name => "DTS",
                    package => "DTS",
                    provides => [qw(
                        DTS DTS::Application DTS::Assignment
                        DTS::Assignment::Constant DTS::Assignment::DataFile
                        DTS::Assignment::Destination
                        DTS::Assignment::Destination::Connection
                        DTS::Assignment::Destination::GlobalVar
                        DTS::Assignment::Destination::Package
                        DTS::Assignment::Destination::Task
                        DTS::Assignment::DestinationFactory
                        DTS::Assignment::EnvVar DTS::Assignment::GlobalVar
                        DTS::Assignment::INI DTS::Assignment::Query
                        DTS::AssignmentFactory DTS::AssignmentTypes
                        DTS::Connection DTS::Credential DTS::Package DTS::Task
                        DTS::Task::DataPump DTS::Task::DynamicProperty
                        DTS::Task::ExecutePackage DTS::Task::SendEmail
                        DTS::TaskFactory DTS::TaskTypes
                    )],
                    release => "DTS-0.64",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1192571117, size => 96543, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 8, pass => 0, unknown => 0 },
                    user => "A7MVzNYFOqkSGx0YwDeOMf",
                    version => 0.64,
                    version_numified => "0.640",
                },
                "PDF::API2" => {
                    abstract => "objects representing POD input paragraphs, commands, etc.",
                    archive => "PDF-API2-v1.24.8.tar.gz",
                    author => "WANTAN",
                    authorized => 0,
                    changes_file => "Changes",
                    checksum_md5 => "cb425f79c1ab12ee58fb8d95eab93b68",
                    checksum_sha256 => "5629b22a6435cefcf8c31cb9c20eb6f889b75f60a3c55e44bd3444cbb71dc75c",
                    contributors => [qw( TAKAONAKANISHI RANGSANSUNTHORN )],
                    date => "2001-12-14T00:00:58",
                    dependency => [],
                    deprecated => 0,
                    distribution => "PDF-API2",
                    download_url => "https://cpan.metacpan.org/authors/id/W/WA/WANTAN/PDF-API2-v1.24.8.tar.gz",
                    first => 0,
                    id => "gdrtW4dy8LAqD0YYPPoUmsAlSGo",
                    license => ["unknown"],
                    likers => [qw( ALEXANDRAPOWELL KANTSOMSRISATI )],
                    likes => 2,
                    main_module => "PDF::API2",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "PDF-API2",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "testing",
                        version => "v0.2.1.0_",
                    },
                    name => "PDF-API2",
                    package => "PDF::API2",
                    provides => [qw(
                        PDF::API2 PDF::API2::Annotation PDF::API2::Barcode
                        PDF::API2::Color PDF::API2::ColorSpace
                        PDF::API2::Content PDF::API2::CoreFont
                        PDF::API2::ExtGState PDF::API2::Font PDF::API2::Gfx
                        PDF::API2::Hybrid PDF::API2::IOString PDF::API2::Image
                        PDF::API2::JPEG PDF::API2::Matrix PDF::API2::Outline
                        PDF::API2::Outlines PDF::API2::PNG PDF::API2::PPM
                        PDF::API2::PSFont PDF::API2::Page PDF::API2::Pattern
                        PDF::API2::PdfImage PDF::API2::TTFont PDF::API2::Text
                        PDF::API2::UniMap PDF::API2::Util PDF::API2::xFont
                        Text::PDF::AFont Text::PDF::Crypt Text::PDF::Crypt::MD5
                    )],
                    release => "PDF-API2-v1.24.8",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1008288058, size => 512332, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "A7MVzNYFOqkSGx0YwDeOMf",
                    version => "v1.24.8",
                    version_numified => 1.024008,
                },
            },
            name => "Wan Tan",
            pauseid => "WANTAN",
            profile => [{ id => 651205, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "A7MVzNYFOqkSGx0YwDeOMf",
        },
        WEEWANG => {
            asciiname => "Wee Wang",
            city => "Singapore",
            contributions => [
                {
                    distribution => "Server-Control",
                    pauseid => "WEEWANG",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Server-Control-0.24",
                },
                {
                    distribution => "Simo-Constrain",
                    pauseid => "WEEWANG",
                    release_author => "MINSUNGJUNG",
                    release_name => "Simo-Constrain-v1.89.10",
                },
            ],
            country => "SG",
            email => ["wee.wang\@example.sg"],
            favorites => [
                {
                    author => "MINSUNGJUNG",
                    date => "2006-06-30T19:12:26",
                    distribution => "Module-ScanDeps",
                },
                {
                    author => "MARINAHOTZ",
                    date => "2010-05-17T03:03:15",
                    distribution => "App-Hachero",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/jTrAAwP2FAkC4RI6rScTla1rx8hSAJnV?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/W/WE/WEEWANG",
                cpan_directory => "http://cpan.org/authors/id/W/WE/WEEWANG",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=WEEWANG",
                cpantesters_reports => "http://cpantesters.org/author/W/WEEWANG.html",
                cpants => "http://cpants.cpanauthors.org/author/WEEWANG",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/WEEWANG",
                repology => "https://repology.org/maintainer/WEEWANG%40cpan",
            },
            modules => {
                "App::Build" => {
                    abstract => "extends Module::Build to build/install/configure entire applications (i.e. web applications), not just modules and programs",
                    archive => "App-Build-2.34.tar.gz",
                    author => "WEEWANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "c9fdd9ea8fb50696cb75b8e29daf0a77",
                    checksum_sha256 => "839003d17664b71084a0a724cc84fb26f9fdf37153e86020171cdfd57b865b8a",
                    contributors => ["DOHYUNNCHOI"],
                    date => "2006-02-16T15:46:14",
                    dependency => [
                        {
                            module => "Module::Build",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "File::Spec",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Module::Build",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "App::Options",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "App-Build",
                    download_url => "https://cpan.metacpan.org/authors/id/W/WE/WEEWANG/App-Build-2.34.tar.gz",
                    first => 0,
                    id => "lExtOsJ65d_6l2M4YC7q4jlpR5U",
                    license => ["perl_5"],
                    likers => [qw( HELEWISEGIROUX DUANLIN )],
                    likes => 2,
                    main_module => "App::Build",
                    maturity => "released",
                    metadata => {
                        abstract => "extends Module::Build to build/install/configure entire applications (i.e. web applications), not just modules and programs",
                        author => ["spadkins\@gmail.com"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.2611, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "App-Build",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Module::Build" => 0 },
                            },
                            runtime => {
                                requires => { "App::Options" => 0, "File::Spec" => 0, "Module::Build" => 0 },
                            },
                        },
                        provides => {
                            "App::Build" => { file => "lib/App/Build.pm", version => 0.62 },
                        },
                        release_status => "stable",
                        version => 0.62,
                    },
                    name => "App-Build",
                    package => "App::Build",
                    provides => ["App::Build"],
                    release => "App-Build-2.34",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1140104774, size => 11002, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 1, na => 0, pass => 1, unknown => 0 },
                    user => "QFFqyCNOYksRDZGzCpPm2k",
                    version => 2.34,
                    version_numified => "2.340",
                },
                "Geo::Postcodes::DK" => {
                    abstract => "Danish postcodes with associated information",
                    archive => "Geo-Postcodes-DK-2.13.tar.gz",
                    author => "WEEWANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "e2bc315c64aad742e1c4b6cf4aec51d4",
                    checksum_sha256 => "02a310412b437ceb7e694753c2cb4b5c85d49b823b1c7c409111e6af6102f8e6",
                    contributors => [qw( ENGYONGCHANG ALESSANDROBAUMANN MINSUNGJUNG )],
                    date => "2006-07-18T21:06:19",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Geo-Postcodes-DK",
                    download_url => "https://cpan.metacpan.org/authors/id/W/WE/WEEWANG/Geo-Postcodes-DK-2.13.tar.gz",
                    first => 0,
                    id => "Rib3mEJvBCU0k0q19_SYRmsCbmQ",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Geo::Postcodes::DK",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Geo-Postcodes-DK",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.02,
                    },
                    name => "Geo-Postcodes-DK",
                    package => "Geo::Postcodes::DK",
                    provides => ["Geo::Postcodes::DK"],
                    release => "Geo-Postcodes-DK-2.13",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1153256779, size => 21941, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 3, unknown => 0 },
                    user => "QFFqyCNOYksRDZGzCpPm2k",
                    version => 2.13,
                    version_numified => "2.130",
                },
                "Number::WithError::LaTeX" => {
                    abstract => "LaTeX output for Number::WithError",
                    archive => "Number-WithError-LaTeX-v0.8.1.tar.gz",
                    author => "WEEWANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "53349800cc637b64dab703ac586dfe1e",
                    checksum_sha256 => "70c8616e38930627a022e29b33d6cb950963447b9c2026f1b8a89dd1d0274b72",
                    contributors => ["TAKAONAKANISHI"],
                    date => "2006-08-30T11:22:43",
                    dependency => [
                        {
                            module => "Test::LectroTest",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0.47,
                        },
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => "v5.8.0",
                        },
                        {
                            module => "TeX::Encode",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.4,
                        },
                        {
                            module => "Math::BigFloat",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Number::WithError",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.02,
                        },
                        {
                            module => "prefork",
                            phase => "runtime",
                            relationship => "requires",
                            version => "1.00",
                        },
                        {
                            module => "Math::SymbolicX::Inline",
                            phase => "runtime",
                            relationship => "requires",
                            version => "1.00",
                        },
                        {
                            module => "Params::Util",
                            phase => "runtime",
                            relationship => "requires",
                            version => "0.10",
                        },
                    ],
                    deprecated => 0,
                    distribution => "Number-WithError-LaTeX",
                    download_url => "https://cpan.metacpan.org/authors/id/W/WE/WEEWANG/Number-WithError-LaTeX-v0.8.1.tar.gz",
                    first => 0,
                    id => "myjUbDdkNd9SfkLhCDNPd6oicQY",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "Number::WithError::LaTeX",
                    maturity => "released",
                    metadata => {
                        abstract => "LaTeX output for Number::WithError",
                        author => [
                            "Steffen Mueller <modules at steffen-mueller dot net>, L<http://steffen-mueller.net/>",
                        ],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.64, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Number-WithError-LaTeX",
                        no_index => {
                            directory => [qw( inc t t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Test::LectroTest" => 0, "Test::More" => 0.47 },
                            },
                            runtime => {
                                requires => {
                                    "Math::BigFloat" => 0,
                                    "Math::SymbolicX::Inline" => "1.00",
                                    "Number::WithError" => 0.02,
                                    "Params::Util" => "0.10",
                                    perl => "v5.8.0",
                                    prefork => "1.00",
                                    "TeX::Encode" => 0.4,
                                },
                            },
                        },
                        release_status => "stable",
                        version => 0.04,
                    },
                    name => "Number-WithError-LaTeX",
                    package => "Number::WithError::LaTeX",
                    provides => ["Number::WithError::LaTeX"],
                    release => "Number-WithError-LaTeX-v0.8.1",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1156936963, size => 18493, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "QFFqyCNOYksRDZGzCpPm2k",
                    version => "v0.8.1",
                    version_numified => 0.008001,
                },
                "POE::Loop::Tk" => {
                    abstract => "Tk event loop support for POE.",
                    archive => "POE-Loop-Tk-0.74.tar.gz",
                    author => "WEEWANG",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "34cabf5dbf36bd2e9f3e6f9d4e68a3c9",
                    checksum_sha256 => "d9fb6b210ca945c7f45553850cbf496c87cc983755ac86acc9ea82c9a6cc675f",
                    date => "2009-08-26T15:58:32",
                    dependency => [
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "POE::Test::Loops",
                            phase => "build",
                            relationship => "requires",
                            version => 1.021,
                        },
                        {
                            module => "Tk",
                            phase => "runtime",
                            relationship => "requires",
                            version => 804.028,
                        },
                        {
                            module => "POE",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.007,
                        },
                        {
                            module => "POE::Test::Loops",
                            phase => "runtime",
                            relationship => "requires",
                            version => 1.021,
                        },
                        {
                            module => "POE::Test::Loops",
                            phase => "configure",
                            relationship => "requires",
                            version => 1.021,
                        },
                        {
                            module => "ExtUtils::MakeMaker",
                            phase => "configure",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "POE-Loop-Tk",
                    download_url => "https://cpan.metacpan.org/authors/id/W/WE/WEEWANG/POE-Loop-Tk-0.74.tar.gz",
                    first => 0,
                    id => "DIwSdlXASZwcLPCw_ht91OFzK7k",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "POE::Loop::Tk",
                    maturity => "released",
                    metadata => {
                        abstract => "Tk event loop support for POE.",
                        author => ["Rocco Caputo <rcaputo\@cpan.org>"],
                        dynamic_config => 1,
                        generated_by => "ExtUtils::MakeMaker version 6.54, CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "POE-Loop-Tk",
                        no_index => {
                            directory => [qw( t inc t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "ExtUtils::MakeMaker" => 0, "POE::Test::Loops" => 1.021 },
                            },
                            configure => {
                                requires => { "ExtUtils::MakeMaker" => 0, "POE::Test::Loops" => 1.021 },
                            },
                            runtime => {
                                requires => { POE => 1.007, "POE::Test::Loops" => 1.021, Tk => 804.028 },
                            },
                        },
                        release_status => "stable",
                        resources => {
                            license => ["http://dev.perl.org/licenses/"],
                            repository => {
                                url => "https://poe.svn.sourceforge.net/svnroot/poe/trunk/polo-tk",
                            },
                        },
                        version => 1.301,
                    },
                    name => "POE-Loop-Tk",
                    package => "POE::Loop::Tk",
                    provides => [qw(
                        POE::Kernel POE::Kernel POE::Kernel POE::Loop::Tk
                        POE::Loop::Tk POE::Loop::TkActiveState
                        POE::Loop::TkCommon
                    )],
                    release => "POE-Loop-Tk-0.74",
                    resources => {
                        license => ["http://dev.perl.org/licenses/"],
                        repository => {
                            url => "https://poe.svn.sourceforge.net/svnroot/poe/trunk/polo-tk",
                        },
                    },
                    stat => { gid => 1009, mode => 33204, mtime => 1251302312, size => 8240, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 0, pass => 7, unknown => 21 },
                    user => "QFFqyCNOYksRDZGzCpPm2k",
                    version => 0.74,
                    version_numified => "0.740",
                },
            },
            name => "Wee Wang",
            pauseid => "WEEWANG",
            profile => [{ id => 663947, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "QFFqyCNOYksRDZGzCpPm2k",
        },
        YOHEIFUJIWARA => {
            asciiname => "Yōhei Fujiwara",
            city => "Fukuoka",
            contributions => [
                {
                    distribution => "Inline-MonoCS",
                    pauseid => "YOHEIFUJIWARA",
                    release_author => "KANTSOMSRISATI",
                    release_name => "Inline-MonoCS-v2.45.12",
                },
                {
                    distribution => "Dist-Zilla-Plugin-ProgCriticTests",
                    pauseid => "YOHEIFUJIWARA",
                    release_author => "RACHELSEGAL",
                    release_name => "Dist-Zilla-Plugin-ProgCriticTests-v1.48.19",
                },
                {
                    distribution => "makepp",
                    pauseid => "YOHEIFUJIWARA",
                    release_author => "MINSUNGJUNG",
                    release_name => "makepp-2.66",
                },
                {
                    distribution => "DBIx-Custom-MySQL",
                    pauseid => "YOHEIFUJIWARA",
                    release_author => "TEDDYSAPUTRA",
                    release_name => "DBIx-Custom-MySQL-1.40",
                },
                {
                    distribution => "Task-Dancer",
                    pauseid => "YOHEIFUJIWARA",
                    release_author => "LILLIANSTEWART",
                    release_name => "Task-Dancer-2.83",
                },
                {
                    distribution => "Validator-Custom-HTMLForm",
                    pauseid => "YOHEIFUJIWARA",
                    release_author => "TAKAONAKANISHI",
                    release_name => "Validator-Custom-HTMLForm-v0.40.0",
                },
                {
                    distribution => "Text-Match-FastAlternatives",
                    pauseid => "YOHEIFUJIWARA",
                    release_author => "OLGABOGDANOVA",
                    release_name => "Text-Match-FastAlternatives-v1.88.18",
                },
                {
                    distribution => "Image-VisualConfirmation",
                    pauseid => "YOHEIFUJIWARA",
                    release_author => "DUANLIN",
                    release_name => "Image-VisualConfirmation-0.4",
                },
            ],
            country => "JP",
            email => ["yohei.fujiwara\@example.jp"],
            favorites => [
                {
                    author => "MARINAHOTZ",
                    date => "2010-05-17T03:03:15",
                    distribution => "App-Hachero",
                },
                {
                    author => "FLORABARRETT",
                    date => "2002-02-10T02:56:54",
                    distribution => "Date-EzDate",
                },
                {
                    author => "FLORABARRETT",
                    date => "2006-09-14T08:29:46",
                    distribution => "PAR-Repository",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/YX3BvVEBNcPzCZ81VwXfAatHIGxfgdfP?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/Y/YO/YOHEIFUJIWARA",
                cpan_directory => "http://cpan.org/authors/id/Y/YO/YOHEIFUJIWARA",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=YOHEIFUJIWARA",
                cpantesters_reports => "http://cpantesters.org/author/Y/YOHEIFUJIWARA.html",
                cpants => "http://cpants.cpanauthors.org/author/YOHEIFUJIWARA",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/YOHEIFUJIWARA",
                repology => "https://repology.org/maintainer/YOHEIFUJIWARA%40cpan",
            },
            modules => {
                "Bundle::Tie::FileLRUCache" => {
                    abstract => "A bundle to install all Tie::FileLRUCache related modules",
                    archive => "Bundle-Tie-FileLRUCache-v2.12.9.tar.gz",
                    author => "YOHEIFUJIWARA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "7a04d3fd867072b56c19f8fb95b31539",
                    checksum_sha256 => "d69e82dc4bcd1385e52a831aae92d0d2397f5f0fc162dd09df987bb670af1256",
                    date => "1999-06-18T15:34:07",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Bundle-Tie-FileLRUCache",
                    download_url => "https://cpan.metacpan.org/authors/id/Y/YO/YOHEIFUJIWARA/Bundle-Tie-FileLRUCache-v2.12.9.tar.gz",
                    first => 1,
                    id => "HBWTi2GkP_yrUb6bigSiZM_0G_k",
                    license => ["unknown"],
                    likers => ["DUANLIN"],
                    likes => 1,
                    main_module => "Bundle::Tie::FileLRUCache",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Bundle-Tie-FileLRUCache",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 1.01,
                    },
                    name => "Bundle-Tie-FileLRUCache",
                    package => "Bundle::Tie::FileLRUCache",
                    provides => ["Bundle::Tie::FileLRUCache"],
                    release => "Bundle-Tie-FileLRUCache-v2.12.9",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 929720047, size => 859, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "b7RYLJwFNwLj5WS2rqakQm",
                    version => "v2.12.9",
                    version_numified => 2.012009,
                },
                Catalyst => {
                    abstract => "Catalyst",
                    archive => "Catalyst-v1.92.2.tar.gz",
                    author => "YOHEIFUJIWARA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "c6c1106e9bae0731e4461bd4f8bfb7d5",
                    checksum_sha256 => "73137fe01eb38f8c088740f9ba82d6b23e4c549b7667e2c52305e9bd7f6576be",
                    contributors => ["FLORABARRETT"],
                    date => "2006-12-12T16:15:50",
                    dependency => [
                        {
                            module => "perl",
                            phase => "runtime",
                            relationship => "requires",
                            version => "v5.6.1",
                        },
                        {
                            module => "Catalyst::Runtime",
                            phase => "runtime",
                            relationship => "requires",
                            version => 5.7,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Catalyst",
                    download_url => "https://cpan.metacpan.org/authors/id/Y/YO/YOHEIFUJIWARA/Catalyst-v1.92.2.tar.gz",
                    first => 0,
                    id => "_p3Z6p_anb6wHtSUxjsAeALlCkk",
                    license => ["perl_5"],
                    likers => [],
                    likes => 0,
                    main_module => "Catalyst",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "Module::Install version 0.64, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Catalyst",
                        no_index => {
                            directory => [qw( inc t t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            runtime => {
                                requires => { "Catalyst::Runtime" => 5.7, perl => "v5.6.1" },
                            },
                        },
                        release_status => "stable",
                        version => "5.7000",
                    },
                    name => "Catalyst",
                    package => "Catalyst",
                    provides => [],
                    release => "Catalyst-v1.92.2",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1165940150, size => 10626, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "b7RYLJwFNwLj5WS2rqakQm",
                    version => "v1.92.2",
                    version_numified => 1.092002,
                },
                DB => {
                    abstract => "Very simple framework for Object Oriented Perl.",
                    archive => "Simo-v1.55.19.tar.gz",
                    author => "YOHEIFUJIWARA",
                    authorized => 0,
                    changes_file => "Changes",
                    checksum_md5 => "99abea532f8b9b0367d28b0d15fddd7d",
                    checksum_sha256 => "2cea0784ce40584c488b2cd36c0f227968280253dd4eec5b92ddcc2dd0b62dc1",
                    contributors => ["MINSUNGJUNG"],
                    date => "2009-04-19T15:29:34",
                    dependency => [
                        {
                            module => "Simo::Error",
                            phase => "build",
                            relationship => "requires",
                            version => 0.0206,
                        },
                        {
                            module => "Test::More",
                            phase => "build",
                            relationship => "requires",
                            version => 0,
                        },
                        {
                            module => "Simo::Util",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0.0301,
                        },
                        {
                            module => "Storable",
                            phase => "runtime",
                            relationship => "requires",
                            version => 0,
                        },
                    ],
                    deprecated => 0,
                    distribution => "Simo",
                    download_url => "https://cpan.metacpan.org/authors/id/Y/YO/YOHEIFUJIWARA/Simo-v1.55.19.tar.gz",
                    first => 0,
                    id => "f8cvGRKm6_mParoKEKFkO15q9WY",
                    license => ["perl_5"],
                    likers => [qw( TEDDYSAPUTRA SAMANDERSON )],
                    likes => 2,
                    main_module => "DB",
                    maturity => "released",
                    metadata => {
                        abstract => "Very simple framework for Object Oriented Perl.",
                        author => ["Yuki <kimoto.yuki\@gmail.com>"],
                        dynamic_config => 1,
                        generated_by => "Module::Build version 0.31012, CPAN::Meta::Converter version 2.150005",
                        license => ["perl_5"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Simo",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {
                            build => {
                                requires => { "Simo::Error" => 0.0206, "Test::More" => 0 },
                            },
                            runtime => {
                                requires => { "Simo::Util" => 0.0301, Storable => 0 },
                            },
                        },
                        provides => {
                            DB => { file => "lib/Simo.pm" },
                            Simo => { file => "lib/Simo.pm", version => 0.1103 },
                        },
                        release_status => "stable",
                        resources => {},
                        version => 0.1103,
                    },
                    name => "Simo",
                    package => "DB",
                    provides => ["Simo"],
                    release => "Simo-v1.55.19",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1240154974, size => 25197, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 0, na => 1, pass => 0, unknown => 0 },
                    user => "b7RYLJwFNwLj5WS2rqakQm",
                    version => "v1.55.19",
                    version_numified => 1.055019,
                },
                "DBD::Trini" => {
                    abstract => "Pure Perl DBMS",
                    archive => "DBD-Trini-v0.77.10.tar.gz",
                    author => "YOHEIFUJIWARA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "bfdc2467dc4704e2068b3333fc731609",
                    checksum_sha256 => "ab512de4b4f1918f5d57f4642a9b7834ead72139d8f55f427554ca08565b8c30",
                    date => "2003-07-15T07:18:15",
                    dependency => [],
                    deprecated => 0,
                    distribution => "DBD-Trini",
                    download_url => "https://cpan.metacpan.org/authors/id/Y/YO/YOHEIFUJIWARA/DBD-Trini-v0.77.10.tar.gz",
                    first => 1,
                    id => "BBZ7qbHiAyQ8nKg4kQ6_7J0LUFc",
                    license => ["unknown"],
                    likers => ["ENGYONGCHANG"],
                    likes => 1,
                    main_module => "DBD::Trini",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "DBD-Trini",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.01,
                    },
                    name => "DBD-Trini",
                    package => "DBD::Trini",
                    provides => [qw(
                        DBD::Trini DBD::Trini::PosBlock DBD::Trini::Record
                        DBD::Trini::Recordset DBD::Trini::Table
                        DBD::Trini::datatypes::Memo
                        DBD::Trini::datatypes::VarChar DBD::Trini::db
                        DBD::Trini::dr DBD::Trini::st
                    )],
                    release => "DBD-Trini-v0.77.10",
                    resources => {},
                    stat => { gid => 1009, mode => 33188, mtime => 1058253495, size => 21157, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "b7RYLJwFNwLj5WS2rqakQm",
                    version => "v0.77.10",
                    version_numified => "0.077010",
                },
                "Tk::TIFF" => {
                    abstract => "Tk TIFF",
                    archive => "Tk-TIFF-2.72.tar.gz",
                    author => "YOHEIFUJIWARA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "2932d9b2a3b6ec5ddac32b534fa366ba",
                    checksum_sha256 => "c3825fe76233561ea405bd4990d7a6e60188bf9b22cde3c8743376d6a409da04",
                    contributors => ["ENGYONGCHANG"],
                    date => "1999-04-14T18:18:22",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Tk-TIFF",
                    download_url => "https://cpan.metacpan.org/authors/id/Y/YO/YOHEIFUJIWARA/Tk-TIFF-2.72.tar.gz",
                    first => 0,
                    id => "_ooOnVQGx9ByNTzciiv5024V4dg",
                    license => ["unknown"],
                    likers => [qw( KANTSOMSRISATI YOICHIFUJITA SAMANDERSON )],
                    likes => 3,
                    main_module => "Tk::TIFF",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Tk-TIFF",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.06,
                    },
                    name => "Tk-TIFF",
                    package => "Tk::TIFF",
                    provides => ["Tk::TIFF"],
                    release => "Tk-TIFF-2.72",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 924113902, size => 33417, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "b7RYLJwFNwLj5WS2rqakQm",
                    version => 2.72,
                    version_numified => "2.720",
                },
            },
            name => "Yōhei Fujiwara",
            pauseid => "YOHEIFUJIWARA",
            profile => [{ id => 559701, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "b7RYLJwFNwLj5WS2rqakQm",
        },
        YOICHIFUJITA => {
            asciiname => "Yōichi Fujita",
            city => "Osaka",
            contributions => [
                {
                    distribution => "MooseX-Log-Log4perl",
                    pauseid => "YOICHIFUJITA",
                    release_author => "SIEUNJANG",
                    release_name => "MooseX-Log-Log4perl-1.20",
                },
                {
                    distribution => "dbic-chado",
                    pauseid => "YOICHIFUJITA",
                    release_author => "SIEUNJANG",
                    release_name => "dbic-chado-1.0",
                },
                {
                    distribution => "PAR-Repository-Client",
                    pauseid => "YOICHIFUJITA",
                    release_author => "TAKASHIISHIKAWA",
                    release_name => "PAR-Repository-Client-v0.82.12",
                },
                {
                    distribution => "Image-VisualConfirmation",
                    pauseid => "YOICHIFUJITA",
                    release_author => "DUANLIN",
                    release_name => "Image-VisualConfirmation-0.4",
                },
                {
                    distribution => "DBIx-Custom",
                    pauseid => "YOICHIFUJITA",
                    release_author => "ELAINAREYES",
                    release_name => "DBIx-Custom-2.37",
                },
                {
                    distribution => "Bundle-Catalyst",
                    pauseid => "YOICHIFUJITA",
                    release_author => "ALEXANDRAPOWELL",
                    release_name => "Bundle-Catalyst-2.58",
                },
                {
                    distribution => "App-gh",
                    pauseid => "YOICHIFUJITA",
                    release_author => "MARINAHOTZ",
                    release_name => "App-gh-2.3",
                },
            ],
            country => "JP",
            email => ["yoichi.fujita\@example.jp"],
            favorites => [
                {
                    author => "TAKAONAKANISHI",
                    date => "2009-01-02T20:17:24",
                    distribution => "WWW-TinySong",
                },
                {
                    author => "YOHEIFUJIWARA",
                    date => "1999-04-14T18:18:22",
                    distribution => "Tk-TIFF",
                },
                {
                    author => "HEHERSONDEGUZMAN",
                    date => "2005-03-23T00:39:39",
                    distribution => "Catalyst-Plugin-Ajax",
                },
            ],
            gravatar_url => "https://secure.gravatar.com/avatar/G0ecSH4jYnSybgPUIakCpfcrr4746KKY?s=130&d=identicon",
            is_pause_custodial_account => 0,
            links => {
                backpan_directory => "https://cpan.metacpan.org/authors/id/Y/YO/YOICHIFUJITA",
                cpan_directory => "http://cpan.org/authors/id/Y/YO/YOICHIFUJITA",
                cpantesters_matrix => "http://matrix.cpantesters.org/?author=YOICHIFUJITA",
                cpantesters_reports => "http://cpantesters.org/author/Y/YOICHIFUJITA.html",
                cpants => "http://cpants.cpanauthors.org/author/YOICHIFUJITA",
                metacpan_explorer => "https://explorer.metacpan.org/?url=/author/YOICHIFUJITA",
                repology => "https://repology.org/maintainer/YOICHIFUJITA%40cpan",
            },
            modules => {
                "Net::DNS::Nslookup" => {
                    abstract => "Perl module for getting simple nslookup output.",
                    archive => "Net-DNS-Nslookup-0.73.tar.gz",
                    author => "YOICHIFUJITA",
                    authorized => 0,
                    changes_file => "Changes",
                    checksum_md5 => "8ab3b4c50ef0efbee70bc62d478d7df5",
                    checksum_sha256 => "6307e52362547f2931ddf4d2000d84d3955dbf5255cdade33752c22b703540ca",
                    contributors => [qw(
                        TEDDYSAPUTRA MARINAHOTZ TAKAONAKANISHI OLGABOGDANOVA
                        OLGABOGDANOVA
                    )],
                    date => "2011-03-22T17:28:19",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Net-DNS-Nslookup",
                    download_url => "https://cpan.metacpan.org/authors/id/Y/YO/YOICHIFUJITA/Net-DNS-Nslookup-0.73.tar.gz",
                    first => 1,
                    id => "wJCLVpJuNbEDiUNZjeozpzfGlKo",
                    license => ["unknown"],
                    likers => ["TAKASHIISHIKAWA"],
                    likes => 1,
                    main_module => "Net::DNS::Nslookup",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Net-DNS-Nslookup",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => 0.01,
                    },
                    name => "Net-DNS-Nslookup",
                    package => "Net::DNS::Nslookup",
                    provides => [],
                    release => "Net-DNS-Nslookup-0.73",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 1300814899, size => 1941, uid => 1009 },
                    status => "backpan",
                    tests => { fail => 113, na => 0, pass => 4, unknown => 1 },
                    user => "X8ddRBo9R6gWRiPHKowgzq",
                    version => 0.73,
                    version_numified => "0.730",
                },
                "Palm::PDB" => {
                    abstract => "Handles standard AppInfo block",
                    archive => "p5-Palm-2.38.tar.gz",
                    author => "YOICHIFUJITA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "0d8b6097375ff4cfd38479c5b3b1adce",
                    checksum_sha256 => "ee65f66914f183c22997b2932c126bf592baa2dc5df5dc155ae659be2877698c",
                    contributors => [qw( HUWANATIENZA HEHERSONDEGUZMAN )],
                    date => "2000-04-24T11:54:11",
                    dependency => [],
                    deprecated => 0,
                    distribution => "p5-Palm",
                    download_url => "https://cpan.metacpan.org/authors/id/Y/YO/YOICHIFUJITA/p5-Palm-2.38.tar.gz",
                    first => 1,
                    id => "dUk4CdIqW68_aiwlSFAgkwpFeNE",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Palm::PDB",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "p5-Palm",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => "v1.1.3",
                    },
                    name => "p5-Palm",
                    package => "Palm::PDB",
                    provides => [qw(
                        Palm::Address Palm::Datebook Palm::Mail Palm::Memo
                        Palm::PDB Palm::Raw Palm::StdAppInfo Palm::ToDo
                    )],
                    release => "p5-Palm-2.38",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 956577251, size => 30259, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "X8ddRBo9R6gWRiPHKowgzq",
                    version => 2.38,
                    version_numified => "2.380",
                },
                "Tie::DB_File::SplitHash" => {
                    abstract => "A wrapper around the DB_File Berkeley database system",
                    archive => "Tie-DB_File-SplitHash-v2.4.14.tar.gz",
                    author => "YOICHIFUJITA",
                    authorized => 1,
                    changes_file => "Changes",
                    checksum_md5 => "58392a57d60f8afd276db3ee658635a1",
                    checksum_sha256 => "ca0ff80b90328ef0db1252fc636636c5a7ef071b128915c382938507da3cfd48",
                    contributors => [qw( ALEXANDRAPOWELL TAKASHIISHIKAWA )],
                    date => "1999-06-16T21:05:31",
                    dependency => [],
                    deprecated => 0,
                    distribution => "Tie-DB_File-SplitHash",
                    download_url => "https://cpan.metacpan.org/authors/id/Y/YO/YOICHIFUJITA/Tie-DB_File-SplitHash-v2.4.14.tar.gz",
                    first => 1,
                    id => "6SQuW1cPx99Y1MNMSBHCrFQMvdU",
                    license => ["unknown"],
                    likers => [],
                    likes => 0,
                    main_module => "Tie::DB_File::SplitHash",
                    maturity => "released",
                    metadata => {
                        abstract => "unknown",
                        author => ["unknown"],
                        dynamic_config => 1,
                        generated_by => "CPAN::Meta::Converter version 2.150005",
                        license => ["unknown"],
                        "meta-spec" => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                        },
                        name => "Tie-DB_File-SplitHash",
                        no_index => {
                            directory => [qw( t xt inc local perl5 fatlib example blib examples eg )],
                        },
                        prereqs => {},
                        release_status => "stable",
                        version => "1.00",
                    },
                    name => "Tie-DB_File-SplitHash",
                    package => "Tie::DB_File::SplitHash",
                    provides => ["Tie::DB_File::SplitHash"],
                    release => "Tie-DB_File-SplitHash-v2.4.14",
                    resources => {},
                    stat => { gid => 1009, mode => 33204, mtime => 929567131, size => 3543, uid => 1009 },
                    status => "backpan",
                    tests => undef,
                    user => "X8ddRBo9R6gWRiPHKowgzq",
                    version => "v2.4.14",
                    version_numified => 2.004014,
                },
            },
            name => "Yōichi Fujita",
            pauseid => "YOICHIFUJITA",
            profile => [{ id => 423665, name => "stackoverflow" }],
            updated => "2023-09-24T15:50:29",
            user => "X8ddRBo9R6gWRiPHKowgzq",
        },
    },
}
EOT

# NOTE: $DIFF_RAW_TEMPLATE
our $DIFF_RAW_TEMPLATE = <<'EOT';
diff -r ${prev_rel}/CHANGES ${rel}/CHANGES
2a3,5
> ${vers} ${today}T13:10:37
>     - Updated name returned
>
diff -r ${prev_rel}/CONTRIBUTING.md ${rel}/CONTRIBUTING.md
32c32
< The versioning style used is dotted decimal, such as `${prev}`
---
> The versioning style used is dotted decimal, such as `${vers}`
diff -r ${prev_rel}/lib/${path1} ${rel}/lib/${path2}
3c3
< ## Version ${prev}
---
> ## Version ${vers}
7c7
< ## Modified ${before}
---
> ## Modified ${today}
19c19
< $VERSION = '${prev}';
---
> $VERSION = '${vers}';
29c29
< sub name { return( "John Doe" ); }
---
> sub name { return( "Urashima Taro" ); }
48c48
<     ${prev}
---
>     ${vers}
diff -r ${prev_rel}/META.json ${rel}/META.json
60c60
<    "version" : "${prev}",
---
>    "version" : "${vers}",
diff -r ${prev_rel}/META.yml ${rel}/META.yml
32c32
< version: ${prev}
---
> version: ${vers}
EOT

# NOTE: $DIFF_JSON_TEMPLATE
our $DIFF_JSON_TEMPLATE = <<'EOT';
{
   "source" : "${author}/${prev_rel}",
   "statistics" : [
      {
         "deletions" : 0,
         "diff" : "diff --git a/var/tmp/source/${author}/${prev_rel}/CHANGES b/var/tmp/target/${author}/${next_rel}/CHANGES\n--- a/var/tmp/source/${author}/${prev_rel}/CHANGES\n+++ b/var/tmp/target/${author}/${next_rel}/CHANGES\n@@ -2,5 +3,5 @@\n ${vers} ${today}T13:10:37+0900\n    - Updated name returned\n",
         "insertions" : 1,
         "source" : "${author}/${prev_rel}/CHANGES",
         "target" : "${author}/${next_rel}/CHANGES"
      },
      {
         "deletions" : 1,
         "diff" : "diff --git a/var/tmp/source/${author}/${prev_rel}/CONTRIBUTING.md b/var/tmp/target/${author}/${next_rel}/CONTRIBUTING.md\n--- a/var/tmp/source/${author}/${prev_rel}/CONTRIBUTING.md\n+++ b/var/tmp/target/${author}/${next_rel}/CONTRIBUTING.md\n@@ -32 +32 @@\n - The versioning style used is dotted decimal, such as `v0.1.0`\n + The versioning style used is dotted decimal, such as `v0.1.1`\n",
         "insertions" : 1,
         "source" : "${author}/${prev_rel}/CONTRIBUTING.md",
         "target" : "${author}/${next_rel}/CONTRIBUTING.md"
      },
      {
         "deletions" : 5,
         "diff" : "diff --git a/var/tmp/source/${author}/${prev_rel}/lib/${path1} b/var/tmp/target/${author}/${next_rel}/lib/${path2}\n--- a/var/tmp/source/${author}/${prev_rel}/lib/${path1}\n+++ b/var/tmp/target/${author}/${next_rel}/lib/${path2}\n@@ -3 +3 @@\n - ## Version ${prev}\n + Version ${vers}\n@@ -7 +7 @@\n - ## Modified ${before}\n + ## Modified ${today}\n@@ -19 +19 @@\n - $VERSION = '${prev}';\n + $VERSION = '${vers}';\n@@ -29 +29 @@\n - sub name { return( \"John Doe\" ); }\n + sub name { return( \"Urashima Taro\" ); }\n@@ -48 + 48 @@\n -     ${prev}\n +     ${vers}",
         "insertions" : 5,
         "source" : "${author}/${prev_rel}/lib/${path1}",
         "target" : "${author}/${next_rel}/lib/${path2}"
      },
      {
         "deletions" : 1,
         "diff" : "diff --git a/var/tmp/source/${author}/${prev_rel}/META.json b/var/tmp/target/${author}/${next_rel}/META.json\n--- a/var/tmp/source/${author}/${prev_rel}/META.json\n+++ b/var/tmp/target/${author}/${next_rel}/META.json\n@@ -60 +60 @@\n -    \"version\" : \"${prev}\",\n +    \"version\" : \"${vers}\",\n",
         "insertions" : 1,
         "source" : "${author}/${prev_rel}/META.json",
         "target" : "${author}/${next_rel}/META.json"
      },
      {
         "deletions" : 1,
         "diff" : "diff --git a/var/tmp/source/${author}/${prev_rel}/META.yml b/var/tmp/target/${author}/${next_rel}/META.yml\n--- a/var/tmp/source/${author}/${prev_rel}/META.yml\n+++ b/var/tmp/target/${author}/${next_rel}/META.yml\n@@ -32 +32 @@\n - version: ${prev}\n + version: ${vers}\n",
         "insertions" : 1,
         "source" : "${author}/${prev_rel}/META.yml",
         "target" : "${author}/${next_rel}/META.yml"
      }
   ],
   "target" : "${author}/${next_rel}"
}
EOT

1;
# NOTE: POD
__END__
