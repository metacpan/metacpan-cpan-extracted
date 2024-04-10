## -*- perl -*-
##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic.pm
## Version v0.35.3
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/08/24
## Modified 2024/04/10
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic;
BEGIN
{
    use v5.26.1;
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
    $MOD_PERL $AUTOLOAD $ERROR $PARAM_CHECKER_LOAD_ERROR $VERBOSE $DEBUG 
    $SILENT_AUTOLOAD $PARAM_CHECKER_LOADED $CALLER_LEVEL $COLOUR_NAME_TO_RGB 
    $true $false $DEBUG_LOG_IO %RE $stderr $stderr_raw $SERIALISER 
    $AUTOLOAD_SUBS $SUB_ATTR_LIST $DATA_POS $HAS_LOCAL_TZ $VERSION_LAX_REGEX
    $PARSE_DATE_FRACTIONAL1_RE $PARSE_DATE_WITH_MILI_SECONDS_RE $PARSE_DATE_HTTP_RE
    $PARSE_DATE_NON_STDANDARD_RE $PARSE_DATE_ONLY_RE $PARSE_DATE_ONLY_US_SHORT_RE
    $PARSE_DATE_ONLY_EU_SHORT_RE $PARSE_DATE_ONLY_US_LONG_RE $PARSE_DATE_ONLY_EU_LONG_RE
    $PARSE_DATE_DOTTED_ONLY_EU_RE $PARSE_DATE_ROMAN_RE $PARSE_DATE_DIGITS_ONLY_RE
    $PARSE_DATE_ONLY_JP_RE $PARSE_DATETIME_JP_RE $PARSE_DATE_TIMESTAMP_RE 
    $PARSE_DATETIME_RELATIVE_RE $PARSE_DATES_ALL_RE $PARSE_DATE_NON_STDANDARD2_RE
    );
    use Config;
    use Class::Load ();
    use Clone ();
    use Data::Dump;
    use Devel::StackTrace;
    use Encode ();
    use File::Spec ();
    use Module::Metadata;
    # use Nice::Try v1.3.4;
    use POSIX;
    use Scalar::Util qw( openhandle );
    use Sub::Util ();
    # use B;
    # To get some context on what the caller expect. This is used in our error() method to allow chaining without breaking
    use version;
    use Want;
    use Exporter ();
    our @ISA         = qw( Exporter );
    our @EXPORT      = qw( );
    our @EXPORT_OK   = qw( subclasses );
    our %EXPORT_TAGS = ();
    our $VERSION     = 'v0.35.3';
    # local $^W;
    # mod_perl/2.0.10
    if( exists( $ENV{MOD_PERL} )
        &&
        ( $MOD_PERL = $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ ) )
    {
        select( ( select( STDOUT ), $| = 1 )[ 0 ] );
        require Apache2::Log;
        # For _is_class_loaded method
        require Apache2::Module;
        require Apache2::ServerUtil;
        require Apache2::RequestUtil;
        require Apache2::ServerRec;
        require ModPerl::Util;
        require Apache2::Const;
        Apache2::Const->import( compile => qw( :log OK ) );
    }
    $VERBOSE     = 0;
    $DEBUG       = 0;
    $SILENT_AUTOLOAD      = 1;
    $PARAM_CHECKER_LOADED = 0;
    $CALLER_LEVEL         = 0;
    $COLOUR_NAME_TO_RGB   = {};
    no strict 'refs';
    $DEBUG_LOG_IO = undef();
    # Can use Sereal also
    $SERIALISER = 'Storable::Improved';
    $AUTOLOAD_SUBS = {};
    $SUB_ATTR_LIST = qr{
        [[:blank:]\h]* : [[:blank:]\h]*
        (?:
        # one attribute
        (?> # no backtrack
            (?! \d) \w+
            (?<nested> \( (?: [^()]++ | (?&nested)++ )*+ \) ) ?
        )
        (?: [[:blank:]\h]* : [[:blank:]\h]* | [[:blank:]\h]ss+ (?! :) )
        )*
    }x;
    # From version::regex
    $VERSION_LAX_REGEX = qr/(?^x: (?^x:
        (?<has_v>v) (?<ver>(?^:[0-9]+) (?: (?^:\.[0-9]+)+ (?^:_[0-9]+)? )?)
        |
        (?<ver>(?^:[0-9]+)? (?^:\.[0-9]+){2,} (?^:_[0-9]+)?)
    ) | (?^x: (?<ver>(?^:[0-9]+) (?: (?^:\.[0-9]+) | \. )? (?^:_[0-9]+)?)
        |
        (?<ver>(?^:\.[0-9]+) (?^:_[0-9]+)?)
        )
    )/;
    use constant HAS_THREADS  => ( $Config{useithreads} && $INC{'threads.pm'} );
};

# use strict;

# We put it here to avoid 'redefine' error
# require Module::Generic::Array;
require Module::Generic::Boolean;
# require Module::Generic::DateTime;
# require Module::Generic::Dynamic;
# require Module::Generic::Exception;
# require Module::Generic::File;
# Module::Generic::File->import( qw( stderr ) );
# require Module::Generic::Hash;
# require Module::Generic::Iterator;
# require Module::Generic::Null;
# require Module::Generic::Number;
# require Module::Generic::Scalar;

require IO::File;
our $stderr = IO::File->new;
$stderr->fdopen( fileno( STDERR ), 'w' );
$stderr->binmode( ':utf8' );
$stderr->autoflush( 1 );
our $stderr_raw = IO::File->new;
$stderr_raw->fdopen( fileno( STDERR ), 'w' );
$stderr_raw->binmode( ':raw' );
$stderr_raw->autoflush( 1 );
# $stderr = stderr( binmode => 'utf-8', autoflush => 1 );
# $stderr_raw = stderr( binmode => 'raw', autoflush => 1 );

{
    no warnings 'once';
    $true  = $Module::Generic::Boolean::true;
    $false = $Module::Generic::Boolean::false;
}

# for sub in `perl -ln -E 'say "$1" if( /^sub (\w+)[[:blank:]\v]*(?:\{|\Z|[[:blank:]\v]*:[[:blank:]\v]*lvalue)/ )' ./lib/Module/Generic.pm | LC_COLLATE=C sort -uV`; do echo "sub $sub;"; done
sub AUTOLOAD;
sub DEBUG;
sub FREEZE;
sub THAW;
sub TO_JSON;
sub VERBOSE;
sub as_hash;
sub clear;
sub clear_error;
sub clone;
sub coloured;
sub colour_close;
sub colour_closest;
sub colour_format;
sub colour_open;
sub colour_parse;
sub colour_to_rgb;
sub debug;
sub deserialise;
sub deserialize;
sub dump;
sub dumper;
sub dumpto_dumper;
sub dumpto_printer;
sub dump_hex;
sub dump_print;
sub errno;
sub error;
sub error_handler;
sub false;
sub fatal;
sub get;
sub import;
sub init;
sub log_handler;
sub messagef_colour;
sub message_colour;
sub new;
sub new_array;
sub new_datetime;
sub new_file;
sub new_glob;
sub new_hash;
sub new_json;
sub new_null;
sub new_number;
sub new_scalar;
sub new_tempdir;
sub new_tempfile;
sub new_version;
sub noexec;
sub pass_error;
sub printer;
sub quiet;
sub save;
sub serialise;
sub serialize;
sub set;
sub subclasses;
sub true;
sub verbose;
sub will;
sub _autoload_subs;
sub _can;
sub _can_overload;
sub _get_args_as_array;
sub _get_args_as_hash;
sub _get_datetime_regexp;
sub _get_stack_trace;
sub _get_symbol;
sub _has_base64;
sub _has_symbol;
sub _implement_freeze_thaw;
sub _instantiate_object;
sub _is_a;
sub _is_array;
sub _is_class_loadable;
sub _is_class_loaded;
sub _is_code;
sub _is_empty;
sub _is_glob;
sub _is_hash;
sub _is_integer;
sub _is_ip;
sub _is_number;
sub _is_object;
sub _is_overloaded;
sub _is_scalar;
sub _is_tty;
sub _is_uuid;
sub _is_warnings_enabled;
sub _list_symbols;
sub _load_class;
sub _load_classes;
sub _lvalue;
sub _message;
sub _messagef;
sub _message_check;
sub _message_frame;
sub _message_log;
sub _message_log_io;
sub _obj2h;
sub _on_error;
sub _parse_timestamp;
sub _refaddr;
sub _set_get;
sub _set_get_array;
sub _set_get_array_as_object;
sub _set_get_boolean;
sub _set_get_callback;
sub _set_get_class;
sub _set_get_class_array;
sub _set_get_class_array_object;
sub _set_get_code;
sub _set_get_datetime;
sub _set_get_file;
sub _set_get_glob;
sub _set_get_hash;
sub _set_get_hash_as_mix_object;
sub _set_get_hash_as_object;
sub _set_get_ip;
sub _set_get_lvalue;
sub _set_get_number;
sub _set_get_number_as_object;
sub _set_get_number_as_scalar;
sub _set_get_number_or_object;
sub _set_get_object;
sub _set_get_object_array;
sub _set_get_object_array2;
sub _set_get_object_array_object;
sub _set_get_object_lvalue;
sub _set_get_object_variant;
sub _set_get_object_without_init;
sub _set_get_scalar;
sub _set_get_scalar_as_object;
sub _set_get_scalar_or_object;
sub _set_get_uri;
sub _set_get_uuid;
sub _set_get_version;
sub _set_symbol;
sub _to_array_object;
sub _warnings_is_enabled;
sub _warnings_is_registered;
sub __colour_data;
sub __create_class;
sub __dbh;
sub __instantiate_object;

# no warnings 'redefine';
sub import
{
    my $self = shift( @_ );
    my( $pkg, $file, $line ) = caller();
    local $Exporter::ExportLevel = 1;
    Exporter::import( $self, @_ );
    our $SILENT_AUTOLOAD;
    
    ( my $dir = $pkg ) =~ s/::/\//g;
    my $path  = $INC{ $dir . '.pm' };
    if( defined( $path ) )
    {
        # Try absolute path name
        $path =~ s/^(.*)$dir\.pm$/${1}auto\/$dir\/autosplit.ix/;
        local $@;
        eval
        {
            local $SIG{ '__DIE__' }  = sub{ };
            local $SIG{ '__WARN__' } = sub{ };
            require $path;
        };
        if( $@ )
        {
            $path = "auto/$dir/autosplit.ix";
            local $@;
            eval
            {
                local $SIG{ '__DIE__' }  = sub{ };
                local $SIG{ '__WARN__' } = sub{ };
                require $path;
            };
        }
        if( $@ )
        {
            CORE::warn( $@ ) unless( $SILENT_AUTOLOAD );
        }
    }
}

sub new
{
    my $that  = shift( @_ );
    my $class = ref( $that ) || $that;
    my $self  = {};
    no strict 'refs';
    if( defined( ${ "${class}\::OBJECT_PERMS" } ) )
    {
        require Module::Generic::Tie;
        my %hash  = ();
        my $obj   = tie(
        %hash, 
        'Module::Generic::Tie', 
        'pkg'   => [ __PACKAGE__, $class ],
        'perms' => ${ "${class}::OBJECT_PERMS" },
        );
        $self  = \%hash;
    }
    bless( $self, $class );
    if( defined( ${ "${class}\::LOG_DEBUG" } ) )
    {
        $self->{log_debug} = ${ "${class}::LOG_DEBUG" };
    }
    
    if( Want::want( 'OBJECT' ) )
    {
        return( $self->init( @_ ) );
    }
    my $new = $self->init( @_ );
    # Returned undef; there was an error potentially
    if( !defined( $new ) )
    {
        # If we are called on an object, we hand it the error so the caller can check it using the object:
        # my $new = $old->new || die( $old->error );
        if( $self->_is_object( $that ) && $that->can( 'pass_error' ) )
        {
            return( $that->pass_error( $self->error ) );
        }
        else
        {
            return( $self->pass_error );
        }
    };
    return( $new );
}

sub new_glob
{
    my $that  = shift( @_ );
    my $class = ref( $that ) || $that;
    no warnings 'once';
    my $self = bless( \do{ local *FH } => $class );
    *$self = {};
    if( defined( ${ "${class}\::LOG_DEBUG" } ) )
    {
        *$self->{log_debug} = ${ "${class}::LOG_DEBUG" };
    }
    if( Want::want( 'OBJECT' ) )
    {
        return( $self->init( @_ ) );
    }
    my $new = $self->init( @_ );
    if( !defined( $new ) )
    {
        # If we are called on an object, we hand it the error so the caller can check it using the object:
        # my $new = $old->new || die( $old->error );
        if( $self->_is_object( $that ) && $that->can( 'pass_error' ) )
        {
            return( $that->pass_error( $self->error ) );
        }
        else
        {
            return( $self->pass_error );
        }
    };
    return( $new );
}

sub deserialise
{
    my $self = shift( @_ );
    my $data;
    $data = shift( @_ ) if( scalar( @_ ) && ( @_ % 2 ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{base64} //= '';
    $opts->{data} = $data if( defined( $data ) && length( $data ) );
    my $this  = $self->_obj2h;
    my $class = $opts->{serialiser} || $opts->{serializer} || $SERIALISER;
    return( $self->error( "No serialiser class was provided nor set in \$Module::Generic::SERIALISER" ) ) if( !defined( $class ) || !length( $class ) );
    
    # Well, nothing to do
    if( ( !defined( $opts->{file} ) || !length( $opts->{file} ) ) && 
        ( !defined( $opts->{io} ) || !length( $opts->{io} ) ) &&
        ( !defined( $opts->{data} ) || !length( $opts->{data} ) ) )
    {
        return( '' );
    }
    # The data provided may be composed only of null bytes, which is the case sometime
    # when retrieved from memory, and in such case, there is no point passing it to 
    # deserialiser. Even worse, CBOR::XS does not deal with extra null padded data in the first 
    # place, and Sereal would not like a string made only of null bytes
    elsif( CORE::exists( $opts->{data} ) && 
           CORE::defined( $opts->{data} ) && 
           $opts->{data} =~ /\x{00}$/ )
    {
        ( my $temp = $opts->{data} ) =~ s/\x{00}+$//gs;
        # There is nothing to do
        return( '' ) if( !length( $temp ) ); 
    }
    
    if( $class eq 'CBOR' || $class eq 'CBOR::XS' )
    {
        $self->_load_class( 'CBOR::XS' ) || return( $self->pass_error );
    }
    else
    {
        $self->_load_class( $class ) || return( $self->pass_error );
        if( $class eq 'Sereal' )
        {
            $self->_load_class( 'Sereal::Decoder' ) || return( $self->pass_error );
        }
    }
    
    # This should be an array with two entries: encoder and decoder handler code reference
    my $base64;
    if( defined( $opts->{base64} ) && $opts->{base64} )
    {
        $base64 = $self->_has_base64( $opts->{base64} );
        return( $self->error( "base64 option '$opts->{base64}' has been provided for deserialising, but could not get handlers." ) ) if( !$base64 );
        if( ref( $base64 ) ne 'ARRAY' ||
            scalar( @$base64 ) < 2 ||
            !defined( $base64->[0] ) ||
            !defined( $base64->[1] ) ||
            ref( $base64->[0] ) ne 'CODE' ||
            ref( $base64->[1] ) ne 'CODE' )
        {
            return( $self->error( "Value returned by _has_base64 is not an array reference containing two code references." ) );
        }
    }
    
    if( $class eq 'CBOR' || $class eq 'CBOR::XS' )
    {
        my @options = qw( max_depth max_size allow_unknown allow_sharing allow_cycles forbid_objects pack_strings text_keys text_strings validate_utf8 filter );
        my $cbor = CBOR::XS->new;
        $cbor->allow_sharing(1);
        for( @options )
        {
            next unless( CORE::exists( $opts->{ $_ } ) );
            $cbor->$_( $opts->{ $_ } );
        }
        
        if( exists( $opts->{file} ) && $opts->{file} )
        {
            my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
            return( $self->error( "File provided \"$opts->{file}\" does not exist." ) ) if( !$f->exists );
            return( $self->error( "File provided \"$opts->{file}\" is actually a directory." ) ) if( $f->is_directory );
            return( $self->error( "File provided \"$opts->{file}\" to deserialise is empty." ) ) if( $f->is_empty );
            my $data = $f->load( binmode => 'raw' );
            return( $self->pass_error( $f->error ) ) if( !defined( $data ) );
            my $ref;
            # try-catch
            local $@;
            eval
            {
                if( defined( $base64 ) )
                {
                    my $decoded = $base64->[1]->( $data );
                    ( $ref, my $bytes ) = $cbor->decode_prefix( $decoded );
                }
                else
                {
                    ( $ref, my $bytes ) = $cbor->decode_prefix( $data );
                }
            };
            if( $@ )
            {
                return( $self->error( "Error trying to deserialise data with $class: $@" ) );
            }
            return( $ref );
        }
        elsif( exists( $opts->{data} ) )
        {
            return( $self->error( "Data provided to deserialise with $class is empty." ) ) if( !defined( $opts->{data} ) || !length( $opts->{data} ) );
            my $ref;
            # try-catch
            local $@;
            eval
            {
                if( defined( $base64 ) )
                {
                    my $decoded = $base64->[1]->( $opts->{data} );
                    ( $ref, my $bytes ) = $cbor->decode_prefix( $decoded );
                }
                else
                {
                    ( $ref, my $bytes ) = $cbor->decode_prefix( $opts->{data} );
                }
            };
            if( $@ )
            {
                return( $self->error( "Error trying to deserialise data with $class: $@" ) );
            }
            return( $ref );
        }
        else
        {
            return( $self->error( "No file and no data was provided to deserialise with $class." ) );
        }
    }
    elsif( $class eq 'CBOR::Free' )
    {
        if( exists( $opts->{file} ) && $opts->{file} )
        {
            my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
            return( $self->error( "File provided \"$opts->{file}\" does not exist." ) ) if( !$f->exists );
            return( $self->error( "File provided \"$opts->{file}\" is actually a directory." ) ) if( $f->is_directory );
            return( $self->error( "File provided \"$opts->{file}\" to deserialise is empty." ) ) if( $f->is_empty );
            my $data = $f->load( binmode => 'raw' );
            return( $self->pass_error( $f->error ) ) if( !defined( $data ) );
            my $ref;
            # try-catch
            local $@;
            eval
            {
                if( defined( $base64 ) )
                {
                    my $decoded = $base64->[1]->( $data );
                    $ref = CBOR::Free::decode( $decoded );
                }
                else
                {
                    $ref = CBOR::Free::decode( $data );
                }
            };
            if( $@ )
            {
                return( $self->error( "Error trying to deserialise data with $class: $@" ) );
            }
            return( $ref );
        }
        elsif( exists( $opts->{data} ) )
        {
            return( $self->error( "Data provided to deserialise with $class is empty." ) ) if( !defined( $opts->{data} ) || !length( $opts->{data} ) );
            my $ref;
            # try-catch
            local $@;
            eval
            {
                if( defined( $base64 ) )
                {
                    my $decoded = $base64->[1]->( $opts->{data} );
                    $ref = CBOR::Free::decode( $decoded );
                }
                else
                {
                    $ref = CBOR::Free::decode( $opts->{data} );
                }
            };
            if( $@ )
            {
                return( $self->error( "Error trying to deserialise data with $class: $@" ) );
            }
            return( $ref );
        }
        else
        {
            return( $self->error( "No file and no data was provided to deserialise with $class." ) );
        }
    }
    elsif( $class eq 'JSON' )
    {
        my @options = qw(
            allow_blessed allow_nonref allow_unknown allow_tags ascii boolean_values 
            canonical convert_blessed filter_json_object filter_json_single_key_object
            indent latin1 max_depth max_size pretty relaxed space_after space_before utf8
        );
        my $json = JSON->new;
        for( @options )
        {
            next unless( CORE::exists( $opts->{ $_ } ) );
            if( my $code = $json->can( $_ ) )
            {
                $code->( $json, $opts->{ $_ } );
            }
        }
        
        if( exists( $opts->{file} ) && $opts->{file} )
        {
            my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
            return( $self->error( "File provided \"$opts->{file}\" does not exist." ) ) if( !$f->exists );
            return( $self->error( "File provided \"$opts->{file}\" is actually a directory." ) ) if( $f->is_directory );
            return( $self->error( "File provided \"$opts->{file}\" to deserialise is empty." ) ) if( $f->is_empty );
            my $data = $f->load( binmode => 'raw' );
            return( $self->pass_error( $f->error ) ) if( !defined( $data ) );
            my $ref;
            # try-catch
            local $@;
            eval
            {
                if( defined( $base64 ) )
                {
                    my $decoded = $base64->[1]->( $data );
                    ( $ref, my $bytes ) = $json->decode_prefix( $decoded );
                }
                else
                {
                    ( $ref, my $bytes ) = $json->decode_prefix( $data );
                }
            };
            if( $@ )
            {
                return( $self->error( "Error trying to serialise data with $class: $@" ) );
            }
            return( $ref );
        }
        elsif( exists( $opts->{data} ) )
        {
            return( $self->error( "Data provided to deserialise with $class is empty." ) ) if( !defined( $opts->{data} ) || !length( $opts->{data} ) );
            my $ref;
            # try-catch
            local $@;
            eval
            {
                if( defined( $base64 ) )
                {
                    my $decoded = $base64->[1]->( $opts->{data} );
                    ( $ref, my $bytes ) = $json->decode_prefix( $decoded );
                }
                else
                {
                    ( $ref, my $bytes ) = $json->decode_prefix( $opts->{data} );
                }
            };
            if( $@ )
            {
                return( $self->error( "Error trying to serialise data with $class: $@" ) );
            }
            return( $ref );
        }
        else
        {
            return( $self->error( "No file and no data was provided to deserialise with $class." ) );
        }
    }
    elsif( $class eq 'Sereal' )
    {
        my @options = qw( refuse_snappy refuse_objects no_bless_objects validate_utf8 max_recursion_depth max_num_hash_entries max_num_array_entries max_string_length max_uncompressed_size incremental alias_smallint alias_varint_under use_undef set_readonly set_readonly_scalars );
        my $ref = {};
        for( @options )
        {
            $ref->{ $_ } = $opts->{ $_ } if( exists( $opts->{ $_ } ) );
        }
    
        my $code;
        my $dec = Sereal::Decoder->new( $ref );
        if( exists( $opts->{file} ) && $opts->{file} )
        {
            return( $self->error( "File provided \"$opts->{file}\" does not exist." ) ) if( !-e( "$opts->{file}" ) );
            return( $self->error( "File provided \"$opts->{file}\" is actually a directory." ) ) if( -d( "$opts->{file}" ) );
            return( $self->error( "File provided \"$opts->{file}\" to deserialise is empty." ) ) if( -z( "$opts->{file}" ) );
            if( defined( $base64 ) )
            {
                my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
                return( $self->error( "File provided \"$opts->{file}\" does not exist." ) ) if( !$f->exists );
                return( $self->error( "File provided \"$opts->{file}\" is actually a directory." ) ) if( $f->is_directory );
                return( $self->error( "File provided \"$opts->{file}\" to deserialise is empty." ) ) if( $f->is_empty );
                my $data = $f->load( binmode => 'raw' );
                return( $self->pass_error( $f->error ) ) if( !defined( $data ) );
                my $decoded = $base64->[1]->( $data );
                my $result;
                # try-catch
                local $@;
                eval
                {
                    $result = $dec->decode( $decoded );
                };
                if( $@ )
                {
                    return( $self->error( "Error trying to deserialise data with $class: $@" ) );
                }
                return( $result );
            }
            else
            {
                my $result;
                # try-catch
                local $@;
                eval
                {
                    $result = $dec->decode_from_file( "$opts->{file}" => $code );
                };
                if( $@ )
                {
                    return( $self->error( "Error trying to deserialise data with $class: $@" ) );
                }
                return( $result );
            }
        }
        elsif( exists( $opts->{data} ) )
        {
            return( $self->error( "Data provided to deserialise with $class is empty." ) ) if( !defined( $opts->{data} ) || !length( $opts->{data} ) );
            my $is_sereal = sub
            {
                my $type = Sereal::Decoder->looks_like_sereal( $_[0] );
                # return( $self->error( "Data retrieved from share memory block does not look like sereal data." ) ) if( !$type );
            };
            
            # try-catch
            local $@;
            eval
            {
                if( defined( $base64 ) )
                {
                    my $decoded = $base64->[1]->( $opts->{data} );
                    $is_sereal->( $decoded ) if( $self->debug );
                    $dec->decode( $decoded => $code );
                }
                else
                {
                    $is_sereal->( $opts->{data} ) if( $self->debug );
                    $dec->decode( $opts->{data} => $code );
                }
            };
            if( $@ )
            {
                return( $self->error( "Error trying to deserialise with $class ", CORE::length( $opts->{data} ), " bytes of data (", ( CORE::length( $opts->{data} ) > 128 ? ( substr( $opts->{data}, 0, 128 ) . '(trimmed)' ) : $opts->{data} ), ": $@" ) );
            }
        }
        else
        {
            return( $self->error( "No file and no data was provided to deserialise with $class." ) );
        }
        return( $code );
    }
    elsif( $class eq 'Storable::Improved' || $class eq 'Storable' )
    {
        if( exists( $opts->{file} ) && $opts->{file} )
        {
            return( $self->error( "File provided \"$opts->{file}\" does not exist." ) ) if( !-e( "$opts->{file}" ) );
            return( $self->error( "File provided \"$opts->{file}\" is actually a directory." ) ) if( -d( "$opts->{file}" ) );
            return( $self->error( "File provided \"$opts->{file}\" to deserialise is empty." ) ) if( -z( "$opts->{file}" ) );
            # We need to check if the serialised data were created with Storable::store
            # or by Storable::freeze then stored into a file separately with print or syswrite
            # The latter would not have the necessary headers
            # As per Storable documentation, if the following return an hash it is a
            # valid file with header, otherwise it would return undef
            my $info = &{"${class}\::file_magic"}( "$opts->{file}" );
            if( ref( $info ) eq 'HASH' )
            {
                if( $this->{debug} || $opts->{debug} )
                {
                    print( STDOUT <<EOT );
Byte order... : $info->{byteorder}
File......... : $info->{file}
Header size.. : $info->{hdrsize}
Integer size. : $info->{intsize}
Long size.... : $info->{longsize}
Major version : $info->{major}
Minor version : $info->{minor}
Net order.... : $info->{netorder}
NV size...... : $info->{nvsize}
PTR size..... : $info->{ptrsize}
Version...... : $info->{version}
Version NV... : $info->{version_nv}
EOT
                }
                
                if( defined( $base64 ) )
                {
                    my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
                    return( $self->error( "File provided \"$opts->{file}\" does not exist." ) ) if( !$f->exists );
                    return( $self->error( "File provided \"$opts->{file}\" is actually a directory." ) ) if( $f->is_directory );
                    return( $self->error( "File provided \"$opts->{file}\" to deserialise is empty." ) ) if( $f->is_empty );
                    $f->lock( shared => 1 ) if( $opts->{lock} );
                    my $data = $f->load( binmode => 'raw' );
                    $f->unlock;
                    return( $self->pass_error( $f->error ) ) if( !defined( $data ) );
                    my $decoded = $base64->[1]->( $data );
                    my $result;
                    # try-catch
                    local $@;
                    eval
                    {
                        $result = &{"${class}\::thaw"}( $decoded );
                    };
                    if( $@ )
                    {
                        return( $self->error( "Error trying to deserialise data with $class: $@" ) );
                    }
                    return( $result );
                }
                elsif( $opts->{lock} )
                {
                    my $rv;
                    # try-catch
                    local $@;
                    eval
                    {
                        $rv = &{"${class}\::lock_retrieve"}( "$opts->{file}" );
                    };
                    if( $@ )
                    {
                        return( $self->error( "Error trying to deserialise data with $class: $@" ) );
                    }
                    return( $rv );
                }
                else
                {
                    my $rv;
                    # try-catch
                    local $@;
                    eval
                    {
                        $rv = &{"${class}\::retrieve"}( "$opts->{file}" );
                    };
                    if( $@ )
                    {
                        return( $self->error( "Error trying to deserialise data with $class: $@" ) );
                    }
                    return( $rv );
                }
            }
            else
            {
                my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
                $f->lock( shared => 1 ) if( $opts->{lock} );
                my $data = $f->load( binmode => 'raw' );
                $f->unlock;
                return( $data ) if( !defined( $data ) || !length( $data ) );
                my $decoded;
                # try-catch
                local $@;
                eval
                {
                    $decoded = &{"${class}\::thaw"}( $data );
                };
                if( $@ )
                {
                    return( $self->error( "Error trying to deserialise data with $class: $@" ) );
                }
                # return( &{"${class}\::thaw"}( $data ) );
                return( $decoded );
            }
        }
        elsif( exists( $opts->{data} ) )
        {
            return( $self->error( "Data provided to deserialise with $class is empty." ) ) if( !defined( $opts->{data} ) || !length( $opts->{data} ) );
            my $rv;
            # try-catch
            local $@;
            eval
            {
                if( defined( $base64 ) )
                {
                    my $decoded = $base64->[1]->( $opts->{data} );
                    $rv = &{"${class}\::thaw"}( $decoded );
                }
                else
                {
                    $rv = &{"${class}\::thaw"}( $opts->{data} );
                }
            };
            if( $@ )
            {
                return( $self->error( "Error trying to deserialise data with $class: $@" ) );
            }
            return( $rv );
        }
        elsif( exists( $opts->{io} ) )
        {
            return( $self->error( "File handle provided ($opts->{io}) is not an actual file handle to get data to deserialise." ) ) if( ( Scalar::Util::reftype( $opts->{io} ) // '' ) ne 'GLOB' );
            if( defined( $base64 ) )
            {
                my $data = '';
                while( read( $opts->{io}, my $buff, 2048 ) )
                {
                    $data .= $buff;
                }
                my $decoded = $base64->[1]->( $data );
                my $rv;
                # try-catch
                local $@;
                eval
                {
                    $rv = &{"${class}\::thaw"}( $decoded );
                };
                if( $@ )
                {
                    return( $self->error( "Error trying to deserialise data with $class: $@" ) );
                }
                return( $rv );
            }
            else
            {
                my $rv;
                # try-catch
                local $@;
                eval
                {
                    $rv = &{"${class}\::fd_retrieve"}( $opts->{io} );
                };
                if( $@ )
                {
                    return( $self->error( "Error trying to deserialise data with $class: $@" ) );
                }
                return( $rv );
            }
        }
        else
        {
            return( $self->error( "No file and no data was provided to deserialise with $class." ) );
        }
    }
    else
    {
        return( $self->error( "Unsupporterd serialiser \"$class\"." ) );
    }
}

sub deserialize { return( shift->deserialise( @_ ) ); }

sub debug
{
    my $self  = shift( @_ );
    my $class = ( ref( $self ) || $self );
    my $this  = $self->_obj2h;
    no strict 'refs';
    no warnings 'once';
    if( @_ )
    {
        my $flag = shift( @_ );
        $this->{debug} = $flag;
        if( $this->{debug} &&
            !$this->{debug_level} )
        {
            $this->{debug_level} = $this->{debug};
        }
    }
    return( $this->{debug} || ${"$class\:\:DEBUG"} );
}

sub dump
{
    my $self = shift( @_ );
    my $opts = {};
    if( @_ > 1 && 
        ref( $_[-1] ) eq 'HASH' && 
        exists( $_[-1]->{filter} ) && 
        ref( $_[-1]->{filter} ) eq 'CODE' )
    {
        $opts = pop( @_ );
        if( $self->_load_class( 'Data::Pretty' ) )
        {
            return( Data::Pretty::dumpf( @_, $opts->{filter} ) );
        }
        elsif( $self->_load_class( 'Data::Dump' ) )
        {
            return( Data::Dump::dumpf( @_, $opts->{filter} ) );
        }
        else
        {
            return( "# Neither Data::Pretty or Data::Dump are installed." );
        }
    }
    else
    {
        if( $self->_load_class( 'Data::Pretty' ) )
        {
            return( Data::Pretty::dump( @_ ) );
        }
        elsif( $self->_load_class( 'Data::Dump' ) )
        {
            return( Data::Dump::dump( @_ ) );
        }
        else
        {
            return( "# Neither Data::Pretty or Data::Dump are installed." );
        }
    }
}

{
    no warnings 'once';
    *dumpto = \&dumpto_dumper;
}

sub error
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    our $MOD_PERL;
    my $this = $self->_obj2h;
    my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $o;
    no strict 'refs';
    no warnings 'once';
    my $want_return = 
    {
        array => sub
        {
            return( [] );
        },
        code => sub
        {
            return( sub{} );
        },
        'glob' => sub
        {
            open( my $tmp, '>', \undef );
            return( $tmp );
        },
        hash => sub
        {
            return( {} );
        },
        object => sub
        {
            require Module::Generic::Null;
            my $null = Module::Generic::Null->new( $o, { debug => $this->{debug}, has_error => 1, wants => 'object' });
            return( $null );
        },
        'scalar' => sub
        {
            my $dummy = undef;
            return( \$dummy );
        },
    };
    
    my $want_what = Want::wantref();
    
    # Ensure this is lowercase and at the same time that this is defined
    $want_what = lc( $want_what // '' );
    # What type of expected value we support to prevent perl error upon undef.
    # By default: object
    my $want_ok = [qw( object )];

    if( @_ )
    {
        my $args = {};
        # We got an object as first argument. It could be a child from our exception package or from another package
        # Either way, we use it as it is
        if( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic::Exception' ) ) ||
            Scalar::Util::blessed( $_[0] ) )
        {
            $o = shift( @_ );
        }
        elsif( ref( $_[0] ) eq 'HASH' )
        {
            $args  = shift( @_ );
        }
        else
        {
            $args->{message} = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @_ ) );
        }
        $args->{class} //= '';
        my $max_len = ( CORE::exists( $this->{error_max_length} ) && $this->{error_max_length} =~ /^[-+]?\d+$/ )
            ? $this->{error_max_length}
            : 0;
        $args->{message} = substr( $args->{message}, 0, $this->{error_max_length} ) if( $max_len > 0 && length( $args->{message} ) > $max_len );
        # Reset it
        $this->{_msg_no_exec_sub} = 0;
        # Note Taken from Carp to find the right point in the stack to start from
        my $caller_func;
        $caller_func = \&{"CORE::GLOBAL::caller"} if( defined( &{"CORE::GLOBAL::caller"} ) );
        # What type of expected value we support to prevent perl error upon undef.
        # By default: object
        if( exists( $args->{want} ) && 
            Scalar::Util::reftype( $args->{want} // '' ) eq 'ARRAY' )
        {
            $want_ok = CORE::delete( $args->{want} );
        }
        
        if( scalar( grep( $_ eq 'all', @$want_ok ) ) )
        {
            foreach my $t ( keys( %$want_return ) )
            {
                push( @$want_ok, $t ) unless( scalar( grep( /^$t$/i, @$want_ok ) ) );
            }
        }
        
        push( @$want_ok, 'OBJECT' ) unless( scalar( grep( /^object$/i, @$want_ok ) ) );
        
        if( defined( $o ) )
        {
            $this->{error} = ${ $class . '::ERROR' } = $o;
        }
        else
        {
            $args->{debug} = $self->debug unless( CORE::exists( $args->{debug} ) );
            my $ex_class = CORE::length( $args->{class} )
                ? $args->{class}
                : ( CORE::exists( $this->{_exception_class} ) && CORE::length( $this->{_exception_class} ) )
                    ? $this->{_exception_class}
                    : ( defined( ${"${class}\::EXCEPTION_CLASS"} ) && CORE::length( ${"${class}\::EXCEPTION_CLASS"} ) )
                        ? ${"${class}\::EXCEPTION_CLASS"}
                        : 'Module::Generic::Exception';
            unless( $self->_is_class_loaded( $ex_class ) || scalar( keys( %{"${ex_class}\::"} ) ) )
            {
                my $pl = "use $ex_class;";
                local $SIG{__DIE__} = sub{};
                local $@;
                eval( $pl );
                # We have to die, because we have an error within another error
                die( __PACKAGE__ . "::error() is unable to load exception class \"$ex_class\": $@" ) if( $@ );
            }
            $o = $this->{error} = ${ $class . '::ERROR' } = $ex_class->new( $args );
        }
        
        my $err_callback = $self->_on_error;
        if( !defined( $err_callback ) &&
            CORE::exists( $args->{callback} ) &&
            ref( $args->{callback} ) eq 'CODE' )
        {
            $err_callback = $args->{callback};
        }
        
        if( defined( $err_callback ) && 
            ref( $err_callback ) eq 'CODE' )
        {
            local $SIG{__WARN__} = sub{};
            local $SIG{__DIE__} = sub{};
            local $@;
            eval
            {
                $err_callback->( $self, $o );
            };
        }
        
        # Get the warnings status of the caller. We use caller(1) to skip one frame further, ie our caller's caller
        # This can be changed by using 'no warnings'
        my $should_display_warning = 0;
        my $no_use_warnings = 1;
        unless( $this->{quiet} )
        {
            # Try to get the warnings status if is enabled at all.
            $should_display_warning = $self->_warnings_is_enabled;
            $no_use_warnings = 0;
        
            # If no warnings are registered for our package, we display warnings.
            if( $no_use_warnings && !defined( $warnings::Bits{ $class } ) )
            {
                $no_use_warnings = 0;
                $should_display_warning = 1;
            }
        }
        
        if( $no_use_warnings )
        {
            my $call_offset = 0;
            while( my @call_data = $caller_func ? $caller_func->( $call_offset ) : caller( $call_offset ) )
            {
                my @prev_stack = $caller_func ? $caller_func->( $call_offset - 1 ) : caller( $call_offset - 1 );
                unless( $call_offset > 0 && $call_data[0] ne $class && $prev_stack[0] eq $class )
                {
                    $call_offset++;
                    next;
                }
                last if( $call_data[9] || ( $call_offset > 0 && $prev_stack[0] ne $class ) );
                $call_offset++;
            }
            my $bitmask = $caller_func ? ($caller_func->( $call_offset ))[9] : ( caller( $call_offset ) )[9];
            my $offset = $warnings::Offsets{uninitialized};
            $should_display_warning = vec( $bitmask, $offset, 1 );
        }
        
        my $r;
        if( $MOD_PERL )
        {
            # try-catch
            local $@;
            eval
            {
                $r = Apache2::RequestUtil->request;
                $r->warn( $o->as_string ) if( $r );
            };
            if( $@ )
            {
                print( STDERR "Error trying to get the global Apache2::ApacheRec: $@\n" );
            }
        }
        
        my $err_handler = $self->error_handler;
        if( $err_handler && ref( $err_handler ) eq 'CODE' )
        {
            $err_handler->( $o );
        }
        elsif( $r )
        {
            if( my $log_handler = $r->get_handlers( 'PerlPrivateErrorHandler' ) )
            {
                $log_handler->( $o );
            }
            else
            {
                $r->warn( $o->as_string ) if( $should_display_warning );
            }
        }
        elsif( $this->{fatal} || $args->{fatal} || ( defined( ${"${class}\::FATAL_ERROR"} ) && ${"${class}\::FATAL_ERROR"} ) )
        {
            # my $enc_str = eval{ Encode::encode( 'UTF-8', "$o", Encode::FB_CROAK ) };
            # die( $@ ? $o : $enc_str );
            die( $o );
        }
        elsif( $should_display_warning )
        {
            if( $r )
            {
                $r->warn( $o->as_string );
            }
            else
            {
                local $@;
                my $enc_str = eval{ Encode::encode( 'UTF-8', "$o", Encode::FB_CROAK ) };
                # Display warnings if warnings for this class is registered and enabled or if not registered
                warn( $@ ? $o : $enc_str );
            }
        }
        
        if( overload::Overloaded( $self ) )
        {
            my $overload_meth_ref = overload::Method( $self, '""' );
            my $overload_meth_name = '';
            $overload_meth_name = Sub::Util::subname( $overload_meth_ref ) if( ref( $overload_meth_ref ) );
            # use Sub::Identify ();
            # my( $over_file, $over_line ) = Sub::Identify::get_code_location( $overload_meth_ref );
            # my( $over_call_pack, $over_call_file, $over_call_line ) = caller();
            my $call_sub = $caller_func ? ($caller_func->(1))[3] : (caller(1))[3];
            # overloaded method name can be, for example: My::Package::as_string
            # or, for anonymous sub: My::Package::__ANON__[lib/My/Package.pm:12]
            # caller sub will reliably be the same, so we use it to check if we are called from an overloaded stringification and return undef right here.
            # Want::want check of being called in an OBJECT context triggers a perl segmentation fault
            if( length( $overload_meth_name ) && $overload_meth_name eq $call_sub )
            {
                return;
            }
        }
        
        # When used inside an lvalue method
        if( $args->{lvalue} && $args->{assign} )
        {
            return( $data->{__dummy} = 'dummy' );
        }
        # https://metacpan.org/pod/Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef
        # https://perlmonks.org/index.pl?node_id=741847
        # Because in list context this would create a lit with one element undef()
        # A bare return will return an empty list or an undef scalar
        # return( undef() );
        # return;
        # As of 2019-10-13, Module::Generic version 0.6, we use this special package Module::Generic::Null to be returned in chain without perl causing the error that a method was called on an undefined value
        # 2020-05-12: Added the no_return_null_object to instruct not to return a null object
        # This is especially needed when an error is called from TIEHASH that returns a special object.
        # A Null object would trigger a fatal perl segmentation fault
        elsif( !$args->{no_return_null_object} && 
               (
                   ( $want_what && CORE::exists( $want_return->{ $want_what } ) && scalar( grep( /^$want_what$/i, @$want_ok ) ) ) || 
                   $args->{object}
               ) )
        {
            if( $args->{object} )
            {
                rreturn( $want_return->{object}->() );
            }
            else
            {
                rreturn( $want_return->{ $want_what }->() );
            }
        }
        elsif( $args->{lvalue} && want( 'RVALUE' ) )
        {
            rreturn;
        }
        return;
    }
    
    # To avoid the perl error of 'called on undefined value' and so the user can do
    # $o->error->_message for example without concerning himself/herself whether an exception object is actually set
    if( !$this->{error} )
    {
        if( $want_what && 
            CORE::exists( $want_return->{ $want_what } ) &&
            scalar( grep( /^$want_what$/i, @$want_ok ) ) )
        {
            rreturn( $want_return->{ $want_what }->() );
        }
    }
    return( ref( $self ) ? $this->{error} : ${ $class . '::ERROR' } );
}

sub error_handler { return( shift->_set_get_code( '_error_handler', @_ ) ); }

{
    no warnings 'once';
    *errstr = \&error;
}

sub fatal { return( shift->_set_get_boolean( 'fatal', @_ ) ); }

sub get
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my @data = map{ $data->{ $_ } } @_;
    return( wantarray() ? @data : $data[ 0 ] );
}

sub init
{
    my $self = shift( @_ );
    my $pkg  = ref( $self );
    no warnings 'uninitialized';
    no overloading;
    my $this = $self->_obj2h;
    no strict 'refs';
    $this->{verbose} = defined( ${ $pkg . '::VERBOSE' } ) ? ${ $pkg . '::VERBOSE' } : 0 if( !length( $this->{verbose} ) );
    $this->{debug}   = defined( ${ $pkg . '::DEBUG' } ) ? ${ $pkg . '::DEBUG' } : 0 if( !length( $this->{debug} ) );
    $this->{version} = ${ $pkg . '::VERSION' } if( !defined( $this->{version} ) && defined( ${ $pkg . '::VERSION' } ) );
    # $this->{level}   = 0;
    $this->{_colour_open} = undef unless( CORE::exists( $this->{_colour_open} ) );
    $this->{_colour_close} = undef unless( CORE::exists( $this->{_colour_close} ) );
    $this->{_exception_class} = 'Module::Generic::Exception' unless( CORE::defined( $this->{_exception_class} ) && CORE::length( $this->{_exception_class} ) );
    $this->{_init_params_order} = [] unless( ref( $this->{_init_params_order} ) );
    # If no debug level was provided when calling message, this level will be assumed
    # Example: message( "Hello" );
    # If _message_default_level was set to 3, this would be equivalent to message( 3, "Hello" )
    $this->{_init_strict_use_sub} = 0 unless( length( $this->{_init_strict_use_sub} ) );
    $this->{_log_handler} = '' unless( length( $this->{_log_handler} ) );
    $this->{_message_default_level} = 0;
    $this->{_msg_no_exec_sub} = 0 unless( length( $this->{_msg_no_exec_sub} ) );
    $this->{_error_max_length} = '' unless( length( $this->{_error_max_length} ) );
    my $data = $this;
    if( $this->{_data_repo} )
    {
        $this->{ $this->{_data_repo} } = {} if( !$this->{ $this->{_data_repo} } );
        $data = $this->{ $this->{_data_repo} };
    }
    
    # If the calling module wants to set up object cleanup
    if( $this->{_mod_perl_cleanup} && $MOD_PERL )
    {
        # try-catch
        local $@;
        eval
        {
            local $SIG{__DIE__};
            # Must enable GlobalRequest for this to work.
            my $r = Apache2::RequestUtil->request;
            if( $r )
            {
                $r->pool->cleanup_register(sub
                {
                    map{ delete( $this->{ $_ } ) } keys( %$this );
                    undef( %$this );
                    return(1);
                });
            }
        };
        if( $@ )
        {
            print( STDERR "Error trying to get the global Apache2::ApacheRec object and setting up a cleanup handler: $@\n" );
        }
    }
    
    @_ = () if( @_ == 1 && !defined( $_[0] ) );
    if( @_ )
    {
        my @args = @_;
        my $vals;
        if( ref( $args[0] ) eq 'HASH' ||
            ( Scalar::Util::blessed( $args[0] ) && $args[0]->isa( 'Module::Generic::Hash' ) ) )
        {
            my $h = shift( @args );
            my $debug_value;
            $debug_value = CORE::delete( $h->{debug} ) if( CORE::exists( $h->{debug} ) );
            $vals = [ %$h ];
            unshift( @$vals, debug => $debug_value ) if( CORE::defined( $debug_value ) );
        }
        elsif( ref( $args[0] ) eq 'ARRAY' )
        {
            $vals = $args[0];
        }
        # Special case when there is an undefined value passed (null) even though it is declared as a hash or object
        elsif( scalar( @args ) == 1 && !defined( $args[0] ) )
        {
            return( $self->error( "Only argument is provided to init ", ref( $self ), " object and its value is undefined." ) );
        }
        elsif( ( scalar( @args ) % 2 ) )
        {
            return( $self->error( sprintf( "Uneven number of parameters provided (%d). Should receive key => value pairs. Parameters provided are: %s", scalar( @args ), join( ', ', @args ) ) ) );
        }
        else
        {
            $vals = \@args;
        }
        
        my $order = ( CORE::exists( $this->{_init_params_order} ) && Scalar::Util::reftype( $this->{_init_params_order} ) eq 'ARRAY' ) ? $this->{_init_params_order} : [];
        if( scalar( @$order ) )
        {
            my $new = [];
            foreach my $param ( @$order )
            {
                for( my $i = 0; $i < scalar( @$vals ); $i += 2 )
                {
                    if( defined( $vals->[$i] ) && $vals->[$i] eq $param )
                    {
                        push( @$new, splice( @$vals, $i, 2 ) );
                    }
                }
            }
            if( scalar( @$new ) )
            {
                push( @$new, @$vals );
                @$vals = @$new;
            }
        }
        
        if( CORE::exists( $this->{_init_preprocess} ) &&
            ref( $this->{_init_preprocess} ) eq 'CODE' )
        {
            $vals = eval
            {
                $this->{_init_preprocess}->( $vals );
            };
            # try-catch
            local $@;
            if( $@ )
            {
                die( "Pre-processing of init data failed: $@" );
            }
            elsif( Scalar::Util::reftype( $vals // '' ) ne 'ARRAY' )
            {
                die( "Pre-processing of init data returned a ", ( ref( $vals ) // 'string' ), ", but was expecting an array reference." );
            }
        }
        
        # Check if there is a debug parameter, and if we find one, set it first so that that 
        # calls to the package subroutines can produce verbose feedback as necessary
        for( my $i = 0; $i < scalar( @$vals ); $i++ )
        {
            next if( !defined( $vals->[$i] ) );
            if( $vals->[$i] eq 'debug' )
            {
                my $v = $vals->[$i + 1];
                $self->debug( $v );
                CORE::splice( @$vals, $i, 2 );
            }
        }
        
        for( my $i = 0; $i < scalar( @$vals ); $i++ )
        {
            my $name = $vals->[ $i ];
            my $val  = $vals->[ ++$i ];
            # Ensure the name has any dash ("-") converted to underscore ("_")
            my $orig = $name;
            my $transformed = ( $name =~ tr/-/_/ );
            my $meth = $self->can( $name );
            if( defined( $meth ) )
            {
                if( !defined( $self->$name( $val ) ) )
                {
                    if( defined( $val ) && $self->error )
                    {
                        warn( "Warning: method $name returned undef while initialising object ", ref( $self ), ": ", ( $self->error ? $self->error->message : '' ), "\n" );
                        return;
                    }
                }
                next;
            }
            elsif( $this->{_init_strict_use_sub} )
            {
                $self->error( "Unknown method $name in class $pkg" );
                next;
            }
            elsif( exists( $data->{ $name } ) ||
                   exists( $data->{ $orig } ) )
            {
                # Pre-existing field value looks like a module package and that package is already loaded
                if( ( index( $data->{ $name }, '::' ) != -1 || $data->{ $name } =~ /^[a-zA-Z][a-zA-Z\_]*[a-zA-Z]$/ ) &&
                    $self->_is_class_loaded( $data->{ $name } ) )
                {
                    my $thisPack = $data->{ $name };
                    if( !Scalar::Util::blessed( $val ) )
                    {
                        return( $self->error( "$name parameter expects a package $thisPack object, but instead got '$val'." ) );
                    }
                    elsif( !$val->isa( $thisPack ) )
                    {
                        return( $self->error( "$name parameter expects a package $thisPack object, but instead got an object from package '", ref( $val ), "'." ) );
                    }
                }
                elsif( $this->{_init_strict} )
                {
                    if( exists( $data->{ $orig } ) && ref( $data->{ $orig } ) eq 'ARRAY' )
                    {
                        return( $self->error( "$orig parameter expects an array reference, but instead got '$val'." ) ) if( ( Scalar::Util::reftype( $val ) // '' ) ne 'ARRAY' );
                    }
                    elsif( exists( $data->{ $orig } ) && ref( $data->{ $orig } ) eq 'HASH' )
                    {
                        return( $self->error( "$orig parameter expects an hash reference, but instead got '$val'." ) ) if( ( Scalar::Util::reftype( $val ) // '' ) ne 'HASH' );
                    }
                    elsif( exists( $data->{ $orig } ) && ref( $data->{ $orig } ) eq 'SCALAR' )
                    {
                        return( $self->error( "$orig parameter expects a scalar reference, but instead got '$val'." ) ) if( ( Scalar::Util::reftype( $val ) // '' ) ne 'SCALAR' );
                    }
                    elsif( $transformed )
                    {
                        if( exists( $data->{ $name } ) && ref( $data->{ $name } ) eq 'ARRAY' )
                        {
                            return( $self->error( "$name parameter expects an array reference, but instead got '$val'." ) ) if( ( Scalar::Util::reftype( $val ) // '' ) ne 'ARRAY' );
                        }
                        elsif( exists( $data->{ $name } ) && ref( $data->{ $name } ) eq 'HASH' )
                        {
                            return( $self->error( "$name parameter expects an hash reference, but instead got '$val'." ) ) if( ( Scalar::Util::reftype( $val ) // '' ) ne 'HASH' );
                        }
                        elsif( exists( $data->{ $name } ) && ref( $data->{ $name } ) eq 'SCALAR' )
                        {
                            return( $self->error( "$name parameter expects a scalar reference, but instead got '$val'." ) ) if( ( Scalar::Util::reftype( $val ) // '' ) ne 'SCALAR' );
                        }
                    }
                }
            }
            # The name parameter does not exist
            else
            {
                # If we are strict, we reject
                next if( $this->{_init_strict} );
            }
            # We passed all tests
            $data->{ $name } = $val;
        }
    }
    return( $self );
}

sub log_handler { return( shift->_set_get_code( '_log_handler', @_ ) ); }

{
    no warnings 'once';
    # NOTE: aliasing message to _message
    *message = \&_message;

    # NOTE: aliasing messagec to message_colour
    *messagec = \&message_colour;

    # NOTE: aliasing message_check to _message_check
    *message_check = \&_message_check;

    # NOTE: aliasing message_color to message_colour
    *message_color = \&message_colour;

    # NOTE: aliasing message_frame to _message_frame
    *message_frame = \&_message_frame;

    # NOTE: aliasing message_log to _message_log
    *message_log = \&_message_log;

    # NOTE: aliasing message_log_io to _message_log_io
    *message_log_io = \&_message_log_io;

    # NOTE: aliasing messagef to _messagef
    *messagef = \&_messagef;
}

sub new_array
{
    my $self = shift( @_ );
    require Module::Generic::Array;
    my $v = Module::Generic::Array->new( @_ );
    return( $self->pass_error( Module::Generic::Array->error ) ) if( !defined( $v ) );
    return( $v );
}

sub new_datetime
{
    my $self = shift( @_ );
    require Module::Generic::DateTime;
    my $v = Module::Generic::DateTime->new( @_ );
    return( $self->pass_error( Module::Generic::DateTime->error ) ) if( !defined( $v ) );
    return( $v );
}

sub new_file
{
    my $self = shift( @_ );
    require Module::Generic::File;
    my $v = Module::Generic::File->new( @_ );
    return( $self->pass_error( Module::Generic::File->error ) ) if( !defined( $v ) );
    return( $v );
}

sub new_hash
{
    my $self = shift( @_ );
    require Module::Generic::Hash;
    my $v = Module::Generic::Hash->new( @_ );
    return( $self->pass_error( Module::Generic::Hash->error ) ) if( !defined( $v ) );
    return( $v );
}

sub new_json
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $self->_load_class( 'JSON' ) || return( $self->pass_error );
    my $j = JSON->new->allow_nonref->allow_blessed->convert_blessed->allow_tags->relaxed;
    # Same as in Module::Generic::File::unload_json()
    my $equi =
    {
        order => 'canonical',
        ordered => 'canonical',
        sorted => 'canonical',
        sort => 'canonical',
    };
    
    foreach my $opt ( keys( %$opts ) )
    {
        my $ref;
        $ref = $j->can( exists( $equi->{ $opt } ) ? $equi->{ $opt } : $opt ) || do
        {
            warn( "Unknown JSON option '${opt}'\n" ) if( $self->_warnings_is_enabled );
            next;
        };
        
        # try-catch
        local $@;
        eval
        {
            $ref->( $j, $opts->{ $opt } );
        };
        if( $@ )
        {
            if( $@ =~ /perl[[:blank:]\h]+structure[[:blank:]\h]+exceeds[[:blank:]\h]+maximum[[:blank:]\h]+nesting[[:blank:]\h]+level/i )
            {
                my $max = $j->get_max_depth;
                return( $self->error( "Unable to set json option ${opt}: $@ (max_depth value is ${max})" ) );
            }
            else
            {
                return( $self->error( "Unable to set json option ${opt}: $@" ) );
            }
        }
    }
    return( $j );
}

sub new_null
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $what;
    if( CORE::exists( $opts->{type} ) &&
        CORE::length( $opts->{type} // '' ) &&
        $opts->{type} =~ /^(array|code|hash|object|refscalar)$/i )
    {
        $what = $opts->{type};
    }
    else
    {
        $what = Want::want( 'LIST' )
            ? 'LIST'
            : Want::want( 'HASH' )
                ? 'HASH'
                : Want::want( 'ARRAY' )
                    ? 'ARRAY'
                    : Want::want( 'OBJECT' )
                        ? 'OBJECT'
                        : Want::want( 'CODE' )
                            ? 'CODE'
                            : Want::want( 'REFSCALAR' )
                                ? 'REFSCALAR'
                                : Want::want( 'BOOLEAN' )
                                    ? 'BOOLEAN'
                                    : Want::want( 'GLOB' )
                                        ? 'GLOB'
                                        : Want::want( 'SCALAR' )
                                            ? 'SCALAR'
                                            : Want::want( 'VOID' )
                                                ? 'VOID'
                                                : '';
    }
    
    if( $what eq 'OBJECT' )
    {
        require Module::Generic::Null;
        return( Module::Generic::Null->new( @_ ) );
    }
    elsif( $what eq 'ARRAY' )
    {
        return( [] );
    }
    elsif( $what eq 'HASH' )
    {
        return( {} );
    }
    elsif( $what eq 'CODE' )
    {
        return( sub{ return; } );
    }
    elsif( $what eq 'REFSCALAR' )
    {
        return( \undef );
    }
    else
    {
        return;
    }
}

sub new_number
{
    my $self = shift( @_ );
    require Module::Generic::Number;
    my $v = Module::Generic::Number->new( @_ );
    return( $self->pass_error( Module::Generic::Number->error ) ) if( !defined( $v ) );
    return( $v );
}

sub new_scalar
{
    my $self = shift( @_ );
    require Module::Generic::Scalar;
    my $v = Module::Generic::Scalar->new( @_ );
    return( $self->pass_error( Module::Generic::Scalar->error ) ) if( !defined( $v ) );
    return( $v );
}

sub new_tempdir
{
    my $self = shift( @_ );
    require Module::Generic::File;
    return( Module::Generic::File::tempdir( @_ ) );
}

sub new_tempfile
{
    my $self = shift( @_ );
    require Module::Generic::File;
    return( Module::Generic::File::tempfile( @_ ) );
}

sub new_version
{
    my $self = shift( @_ );
    my $v = shift( @_ );
    if( !defined( $v ) )
    {
        return( $self->error( "No version was provided." ) );
    }
    elsif( !CORE::length( "$v" ) )
    {
        return( $self->error( "Value provided, to create a version object, is empty." ) );
    }
    
    my $vers;
    # try-catch
    local $@;
    eval
    {
        $vers = version->parse( "$v" );
    };
    if( $@ )
    {
        return( $self->error( "Unable to create a version object from '$v': $@" ) );
    }
    return( $vers );
}

sub noexec { $_[0]->{_msg_no_exec_sub} = 1; return( $_[0] ); }

# Purpose is to get an error object thrown from, possibly another package, 
# and make it ours and pass it along
# e.g.:
# $self->pass_error
# $self->pass_error( 'Some error that will be passed to error()' );
# $self->pass_error( $error_object );
# $self->pass_error( $error_object, { class => 'Some::ExceptionClass', code => 400 } );
# $self->pass_error({ class => 'Some::ExceptionClass' });
sub pass_error
{
    my $self = shift( @_ );
    my $pack = ref( $self ) || $self;
    my $this = $self->_obj2h;
    my $opts = {};
    my $err;
    my $class;
    my $code;
    my $callback;
    no strict 'refs';
    if( scalar( @_ ) )
    {
        # Either an hash defining a new error and this will be passed along to error(); or
        # an hash with a single property: { class => 'Some::ExceptionClass' }
        if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
        {
            $opts = $_[0];
        }
        else
        {
            # $self->pass_error( $error_object, { class => 'Some::ExceptionClass' } );
            if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' )
            {
                $opts = pop( @_ );
            }
            $err = $_[0];
        }
    }
    $err = $opts->{error} if( !defined( $err ) && CORE::exists( $opts->{error} ) && defined( $opts->{error} ) && CORE::length( $opts->{error} ) );
    # We set $class only if the hash provided is a one-element hash and not an error-defining hash
    # $class = CORE::delete( $opts->{class} ) if( scalar( keys( %$opts ) ) == 1 && [keys( %$opts )]->[0] eq 'class' );
    $class = $opts->{class} if( CORE::exists( $opts->{class} ) && defined( $opts->{class} ) && CORE::length( $opts->{class} ) );
    $code  = $opts->{code} if( CORE::exists( $opts->{code} ) && defined( $opts->{code} ) && CORE::length( $opts->{code} ) );
    $callback = $opts->{callback} if( CORE::exists( $opts->{callback} ) && defined( $opts->{callback} ) && ref( $opts->{callback} ) );
    
    # called with no argument, most likely from the same class to pass on an error 
    # set up earlier by another method; or
    # with an hash containing just one argument class => 'Some::ExceptionClass'
    if( !defined( $err ) && ( !scalar( @_ ) || defined( $class ) ) )
    {
        my $error = ref( $self ) ? $this->{error} : length( ${ $pack . '::ERROR' } ) ? ${ $pack . '::ERROR' } : undef;
        if( !defined( $error ) )
        {
            warn( "No error object provided and no previous error set either! It seems the previous method call returned a simple undef\n", $self->_get_stack_trace );
        }
        else
        {
            $err = ( defined( $class ) ? bless( $error => $class ) : $error );
            $err->code( $code ) if( defined( $code ) );
        }
    }
    elsif( defined( $err ) && 
           Scalar::Util::blessed( $err ) && 
           ( scalar( @_ ) == 1 || 
             ( scalar( @_ ) == 2 && defined( $class ) ) 
           ) )
    {
        $this->{error} = ${ $pack . '::ERROR' } = ( defined( $class ) ? bless( $err => $class ) : $err );
        $this->{error}->code( $code ) if( defined( $code ) );
        my $err_callback = $self->_on_error;
        $err_callback = $callback if( !defined( $err_callback ) && defined( $callback ) );
        if( defined( $err_callback ) && 
            ref( $err_callback ) eq 'CODE' )
        {
            local $SIG{__WARN__} = sub{};
            local $SIG{__DIE__} = sub{};
            local $@;
            eval
            {
                $err_callback->( $self, $this->{error} );
            };
        }
        
        if( $this->{fatal} || ( defined( ${"${class}\::FATAL_ERROR"} ) && ${"${class}\::FATAL_ERROR"} ) )
        {
            die( $this->{error} );
        }
    }
    # If the error provided is not an object, we call error to create one
    else
    {
        return( $self->error( @_ ) );
    }
    
    if( want( 'OBJECT' ) )
    {
        require Module::Generic::Null;
        my $null = Module::Generic::Null->new( $err, { debug => $this->{debug}, has_error => 1 });
        rreturn( $null );
    }
    if( $self->debug )
    {
        my $wantarray = wantarray();
        my $caller = [caller(1)];
    }
    return;
}

sub quiet { return( shift->_set_get( 'quiet', @_ ) ); }

sub serialise
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    return( $self->error( "No data to serialise was provided." ) ) if( !defined( $data ) || !length( $data ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my $class = $opts->{serialiser} || $opts->{serializer} || $SERIALISER;
    return( $self->error( "No serialiser class was provided nor set in \$Module::Generic::SERIALISER" ) ) if( !defined( $class ) || !length( $class ) );
    $opts->{base64} //= '';

    if( $class eq 'CBOR' || $class eq 'CBOR::XS' )
    {
        $self->_load_class( 'CBOR::XS' ) || return( $self->pass_error );
    }
    else
    {
        $self->_load_class( $class ) || return( $self->pass_error );
        if( $class eq 'Sereal' )
        {
            $self->_load_class( 'Sereal::Encoder' ) || return( $self->pass_error );
        }
    }

    # This should be an array with two entries: encoder and decoder handler code reference
    my $base64;
    if( defined( $opts->{base64} ) && $opts->{base64} )
    {
        $base64 = $self->_has_base64( $opts->{base64} );
        return( $self->error( "base64 option '$opts->{base64}' has been provided for deserialising, but could not get handlers." ) ) if( !$base64 );
        if( ref( $base64 ) ne 'ARRAY' ||
            scalar( @$base64 ) < 2 ||
            !defined( $base64->[0] ) ||
            !defined( $base64->[1] ) ||
            ref( $base64->[0] ) ne 'CODE' ||
            ref( $base64->[1] ) ne 'CODE' )
        {
            return( $self->error( "Value returned by _has_base64 is not an array reference containing two code references." ) );
        }
    }
    
    if( $class eq 'CBOR' || $class eq 'CBOR::XS' )
    {
        my @options = qw(
            max_depth max_size allow_unknown allow_sharing allow_cycles forbid_objects 
            pack_strings text_keys text_strings validate_utf8 filter
        );
        my $cbor = CBOR::XS->new;
        for( @options )
        {
            next unless( CORE::exists( $opts->{ $_ } ) );
            if( my $code = $cbor->can( $_ ) )
            {
                $code->( $cbor, $opts->{ $_ } );
            }
        }
        
        my $serialised;
        # try-catch
        local $@;
        eval
        {
            $serialised = $cbor->encode( $data );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to serialise data with $class: $@" ) );
        }
        
        if( defined( $base64 ) )
        {
            $serialised = $base64->[0]->( $serialised );
        }
        
        if( exists( $opts->{file} ) && $opts->{file} )
        {
            my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
            $f->unload( $serialised, { binmode => 'raw' } ) || return( $self->pass_error( $f->error ) );
        }
        return( $serialised );
    }
    if( $class eq 'CBOR::Free' )
    {
        my @options = qw(
            canonical string_encode_mode preserve_references scalar_references
        );
        my $params = {};
        for( @options )
        {
            next unless( CORE::exists( $opts->{ $_ } ) );
            $params->{ $_ } = $opts->{ $_ };
        }
        
        # try-catch
        local $@;
        my $serialised;
        eval
        {
            $serialised = CBOR::Free::encode( $data, ( scalar( keys( %$params ) ) ? %$params : () ) );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to serialise data with $class: $@" ) );
        }
        
        if( defined( $base64 ) )
        {
            $serialised = $base64->[0]->( $serialised );
        }
        
        if( exists( $opts->{file} ) && $opts->{file} )
        {
            my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
            $f->unload( $serialised, { binmode => 'raw' } ) || return( $self->pass_error( $f->error ) );
        }
        return( $serialised );
    }
    elsif( $class eq 'JSON' )
    {
        my @options = qw(
            allow_blessed allow_nonref allow_unknown allow_tags ascii boolean_values 
            canonical convert_blessed filter_json_object filter_json_single_key_object
            indent latin1 max_depth max_size pretty relaxed space_after space_before utf8
        );
        my $json = JSON->new;
        for( @options )
        {
            next unless( CORE::exists( $opts->{ $_ } ) );
            if( my $code = $json->can( $_ ) )
            {
                $code->( $json, $opts->{ $_ } );
            }
        }
        
        # try-catch
        local $@;
        my $serialised;
        eval
        {
            $serialised = $json->encode( $data );
        };
        if( $@ )
        {
            return( $self->error( "Error trying to serialise data with $class: $@" ) );
        }
        
        if( defined( $base64 ) )
        {
            $serialised = $base64->[0]->( $serialised );
        }
        
        if( exists( $opts->{file} ) && $opts->{file} )
        {
            my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
            $f->unload( $serialised, { binmode => 'raw' } ) || return( $self->pass_error( $f->error ) );
        }
        return( $serialised );
    }
    elsif( $class eq 'Sereal' )
    {
        my @options = qw( compress compress_threshold compress_level snappy snappy_incr snappy_threshold croak_on_bless freeze_callbacks no_bless_objects undef_unknown stringify_unknown warn_unknown max_recursion_depth  canonical canonical_refs sort_keys no_shared_hashkeys dedupe_strings aliased_dedupe_strings protocol_version use_protocol_v1 );
        my $ref = {};
        for( @options )
        {
            $ref->{ $_ } = $opts->{ $_ } if( exists( $opts->{ $_ } ) );
        }
        
        my $enc = Sereal::Encoder->new( $ref );
        if( exists( $opts->{file} ) && $opts->{file} )
        {
            if( defined( $base64 ) )
            {
                my $serialised = $enc->encode( $data );
                $serialised = $base64->[0]->( $serialised );
                my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
                $f->unload( $serialised, { binmode => 'raw' } ) || return( $self->pass_error( $f->error ) );
                return( $serialised );
            }
            else
            {
                # try-catch
                local $@;
                my $rv;
                eval
                {
                    $rv = $enc->encode_to_file( "$opts->{file}", $data, ( exists( $opts->{append} ) ? $opts->{append} : 0 ) );
                };
                if( $@ )
                {
                    return( $self->error( "Error trying to serialise data with $class: $@" ) );
                }
                return( $rv );
            }
        }
        else
        {
            # try-catch
            local $@;
            my $serialised;
            eval
            {
                $serialised = $enc->encode( $data );
            };
            if( $@ )
            {
                return( $self->error( "Error trying to serialise data with $class: $@" ) );
            }
            
            if( defined( $base64 ) )
            {
                return( $base64->[0]->( $serialised ) );
            }
            return( $serialised );
        }
    }
    elsif( $class eq 'Storable::Improved' || $class eq 'Storable' )
    {
        if( exists( $opts->{file} ) && $opts->{file} )
        {
            if( defined( $base64 ) )
            {
                my $serialised = &{"${class}\::freeze"}( $data );
                $serialised = $base64->[0]->( $serialised );
                my $f = $self->new_file( $opts->{file} ) || return( $self->pass_error );
                $f->unload( $serialised, { binmode => 'raw' } ) || return( $self->pass_error( $f->error ) );
                return( $serialised );
            }
            elsif( $opts->{lock} )
            {
                # try-catch
                local $@;
                my $rv;
                eval
                {
                    $rv = &{"${class}\::lock_store"}( $data => "$opts->{file}" );
                };
                if( $@ )
                {
                    return( $self->error( "Error trying to serialise data with $class: $@" ) );
                }
                return( $rv );
            }
            else
            {
                # try-catch
                local $@;
                my $rv;
                eval
                {
                    $rv = &{"${class}\::store"}( $data => "$opts->{file}" );
                };
                if( $@ )
                {
                    return( $self->error( "Error trying to serialise data with $class: $@" ) );
                }
                return( $rv );
            }
        }
        elsif( exists( $opts->{io} ) )
        {
            return( $self->error( "File handle provided ($opts->{io}) is not an actual file handle to serialise data to." ) ) if( ( Scalar::Util::reftype( $opts->{io} ) // '' ) ne 'GLOB' );
            if( defined( $base64 ) )
            {
                my $serialised = &{"${class}\::freeze"}( $data );
                $serialised = $base64->[0]->( $serialised );
                
                my $bytes = syswrite( $opts->{io}, $serialised );
                return( $self->error( "Unable to write ", CORE::length( $serialised ), " bytes of Storable serialised data to file handle '$opts->{io}': $!" ) ) if( !defined( $bytes ) );
                return( $serialised );
            }
            else
            {
                # try-catch
                local $@;
                my $rv;
                eval
                {
                    $rv = &{"${class}\::store_fd"}( $data => $opts->{io} );
                };
                if( $@ )
                {
                    return( $self->error( "Error trying to serialise data with $class: $@" ) );
                }
                return( $rv );
            }
        }
        else
        {
            # try-catch
            local $@;
            my $serialised;
            eval
            {
                $serialised = &{"${class}\::freeze"}( $data );
            };
            if( $@ )
            {
                return( $self->error( "Error trying to serialise data with $class: $@" ) );
            }
            
            if( defined( $base64 ) )
            {
                return( $base64->[0]->( $serialised ) );
            }
            return( $serialised );
        }
    }
    else
    {
        return( $self->error( "Unsupporterd serialiser \"$class\"." ) );
    }
}

sub serialize { return( shift->serialise( @_ ) ); }

sub set
{
    my $self = shift( @_ );
    my %arg  = ();
    if( @_ )
    {
        %arg = ( @_ );
        my $this = $self->_obj2h;
        my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
        my @keys = keys( %arg );
        @$data{ @keys } = @arg{ @keys };
    }
    return( scalar( keys( %arg ) ) );
}

sub true  { return( $Module::Generic::Boolean::true ); }

sub false { return( $Module::Generic::Boolean::false ); }

sub verbose
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    if( @_ )
    {
        my $flag = shift( @_ );
        $this->{verbose} = $flag;
    }
    return( $this->{verbose} );
}

sub will
{
    ( @_ >= 2 && @_ <= 3 ) || die( 'Usage: $obj->can( "method" ) or Module::Generic::will( $obj, "method" )' );
    my( $obj, $meth, $level );
    if( @_ == 3 && ref( $_[ 1 ] ) )
    {
        $obj  = $_[ 1 ];
        $meth = $_[ 2 ];
    }
    else
    {
        ( $obj, $meth, $level ) = @_;
    }
    return if( !ref( $obj ) && index( $obj, '::' ) == -1 );
    no strict 'refs';
    # Give a chance to UNIVERSAL::can
    my $ref = undef;
    if( Scalar::Util::blessed( $obj ) && ( $ref = $obj->can( $meth ) ) )
    {
        return( $ref );
    }
    my $class = ref( $obj ) || $obj;
    my $origi = $class;
    if( index( $meth, '::' ) != -1 )
    {
        $origi = substr( $meth, 0, rindex( $meth, '::' ) );
        $meth  = substr( $meth, rindex( $meth, '::' ) + 2 );
    }
    $ref = \&{ "$class\::$meth" } if( defined( &{ "$class\::$meth" } ) );
    return( $ref ) if( defined( $ref ) );
    # We do not go further down the rabbit hole if level is greater or equal to 10
    $level ||= 0;
    return if( $level >= 10 );
    $level++;
    # Let's see what Alice has got for us... :-)
    # We look in the @ISA to see if the method exists in the package from which we
    # possibly inherited
    if( @{ "$class\::ISA" } )
    {
        foreach my $pack ( @{ "$class\::ISA" } )
        {
            my $ref = &will( $pack, "$origi\::$meth", $level );
            return( $ref ) if( defined( $ref ) );
        }
    }
    # Then, maybe there is an AUTOLOAD to trap undefined routine?
    # But, we do not want any loop, do we?
    # Since will() is called from Module::Generic::AUTOLOAD to check if EXTRA_AUTOLOAD exists
    # we are not going to call Module::Generic::AUTOLOAD for EXTRA_AUTOLOAD...
    if( $class ne 'Module::Generic' && $meth ne 'EXTRA_AUTOLOAD' && defined( &{ "$class\::AUTOLOAD" } ) )
    {
        my $sub = sub
        {
            $class::AUTOLOAD = "$origi\::$meth";
            &{ "$class::AUTOLOAD" }( @_ );
        };
        return( $sub );
    }
    return;
}

sub __instantiate_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $o;
    my $callback;
    my $def = {};
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        return( $self->error( "No property 'field' was provided in the parameters of _set_get_object" ) ) if( !length( $field // '' ) );
        if( CORE::exists( $def->{callback} ) &&
            defined( $def->{callback} ) &&
            ref( $def->{callback} ) eq 'CODE' )
        {
            $callback = $def->{callback};
        }
    }

    # try-catch
    local $@;
    eval
    {
        # https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
        # require $class unless( defined( *{"${class}::"} ) );
        # Either it passes and returns the class loaded or it raises an error trapped in catch
        my $rc = Class::Load::load_class( $class );
        @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
        if( defined( $callback ) )
        {
            $o = $callback->(
                $class => [@_],
            );
        }
        else
        {
            $o = scalar( @_ ) ? $class->new( @_ ) : $class->new;
        }
    };
    if( $@ )
    {
        return( $self->error({ code => 500, message => $@ }) );
    }
    return( $self->error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
    $o->debug( $this->{debug} ) if( $o->can( 'debug' ) );
    return( $o );
}

sub _can
{
    my $self = shift( @_ );
    no overloading;
    # Nothing provided
    return if( !scalar( @_ ) );
    return if( !defined( $_[0] ) );
    return if( !Scalar::Util::blessed( $_[0] ) );
    if( $self->_is_array( $_[1] ) )
    {
        foreach my $meth ( @{$_[1]} )
        {
            return(0) unless( $_[0]->can( $meth ) );
        }
        return(1);
    }
    else
    {
        return( $_[0]->can( $_[1] ) );
    }
}

sub _get_args_as_array
{
    my $self = shift( @_ );
    return( [] ) if( !scalar( @_ ) );
    my $ref = [];
    if( scalar( @_ ) == 1 && $self->_is_array( $_[0] ) )
    {
        $ref = shift( @_ );
    }
    else
    {
        $ref = [ @_ ];
    }
    return( $ref );
}

sub _get_args_as_hash
{
    my $self = shift( @_ );
    return( {} ) if( !scalar( @_ ) );
    no warnings 'uninitialized';
    my $ref = {};
    my $order = $self->new_array;
    my $need_list = Want::want( 'LIST' ) ? 1 : 0;
    my $ok = {};
    
    my $process = sub
    {
        my $this = shift( @_ );
        # Check if among the parameters there is a special args_list one and its value is an array reference
        if( scalar( grep( !Scalar::Util::blessed( $_ ) && $_ eq 'args_list', @$this ) ) )
        {
            for( my $i = 0; $i < scalar( @$this ); $i++ )
            {
                if( defined( $this->[$i] ) && $this->[$i] eq 'args_list' && 
                    defined( $this->[$i+1] ) && ( Scalar::Util::reftype( $this->[$i+1] ) // '' ) eq 'ARRAY' )
                {
                    my $list = $this->[$i+1];
                    @$ok{ @$list } = (1) x scalar( @$list );
                    last;
                }
            }
        }
        
        # If we have a restricted list of parameters, obey it
        if( scalar( keys( %$ok ) ) )
        {
            for( my $i = 0; $i < scalar( @$this ); $i++ )
            {
                if( exists( $ok->{ $this->[$i] } ) )
                {
                    $ref->{ $this->[$i] } = $this->[$i+1];
                    $order->push( $this->[$i] ) if( $need_list );
                    splice( @$this, $i, 2 );
                    $i--;
                }
            }
        }
        # or, if we have simple a list of key-value pairs, take this and put it into an hash reference
        elsif( !( scalar( @$this ) % 2 ) )
        {
            $ref = { @$this };
            if( $need_list )
            {
                for( my $i = 0; $i < scalar( @$this ); $i += 2 )
                {
                    $order->push( $this->[$i] );
                }
            }
        }
        return( $ref, $order );
    };
    
    # A single hash reference was provided
    if( scalar( @_ ) == 1 && $self->_is_hash( $_[0] ) )
    {
        $ref = shift( @_ );
        $order = $self->new_array( [sort( keys( %$ref ) )] ) if( $need_list );
    }
    elsif( scalar( @_ ) == 1 && ( Scalar::Util::reftype( $_[0] ) // '' ) eq 'ARRAY' ||
           ( scalar( @_ ) == 3 && ( Scalar::Util::reftype( $_[0] ) // '' ) eq 'ARRAY' && defined( $_[1] ) && $_[1] eq 'args_list' && defined( $_[2] ) && ( Scalar::Util::reftype( $_[2] ) // '' ) eq 'ARRAY' ) )
    {
        if( @_ > 1 )
        {
            my $list = $_[2];
            @$ok{ @$list } = (1) x scalar( @$list );
        }
        ( $ref, $order ) = $process->( $_[0] );
    }
    else
    {
        ( $ref, $order ) = $process->( \@_ );
    }
    return( $need_list ? ( $ref, $order ) : $ref );
}

# Call to the actual method doing the work
# The reason for doing so is because _instantiate_object() may be inherited, but
# _set_get_class or _set_get_hash_as_object created dynamic class which requires to call _instantiate_object
# If _instantiate_object is inherited, it will yield unpredictable results
sub _instantiate_object { return( shift->__instantiate_object( @_ ) ); }

sub _get_stack_trace
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{skip_frames} //= 0;
    my $trace = Devel::StackTrace->new( skip_frames => ( 1 + $opts->{skip_frames} ), indent => 1 );
    return( $trace );
}

sub _is_a
{
    my $self = shift( @_ );
    my $obj = shift( @_ );
    my $pkg = shift( @_ );
    no overloading;
    return if( !$obj || !$pkg );
    return if( !$self->_is_object( $obj ) );
    if( $self->_is_array( $pkg ) )
    {
        for( @$pkg )
        {
            if( $_ !~ /^\w+(?:\:\:\w+)*$/ )
            {
                warn( "Warning only: package name provided \"$_\" contains illegal characters.\n" );
            }
            return(1) if( $obj->isa( $_ ) );
        }
        return(0);
    }
    else
    {
        if( $pkg !~ /^\w+(?:\:\:\w+)*$/ )
        {
            warn( "Warning only: package name provided \"$pkg\" contains illegal characters.\n" );
        }
        return( $obj->isa( $pkg ) );
    }
}

# UNIVERSAL::isa works for both array or array as objects
# sub _is_array { return( UNIVERSAL::isa( $_[1], 'ARRAY' ) ); }
sub _is_array
{
    return(0) if( scalar( @_ < 2 ) );
    return(0) if( !defined( $_[1] ) );
    my $type = Scalar::Util::reftype( $_[1] );
    return(0) if( !defined( $type ) );
    return( $type eq 'ARRAY' );
}

sub _is_class_loadable
{
    my $self = shift( @_ );
    my $class = shift( @_ ) || return(0);
    my $version = shift( @_ );
    no strict 'refs';
    my $file  = File::Spec->catfile( split( /::/, $class ) ) . '.pm';
    my $inc   = File::Spec::Unix->catfile( split( /::/, $class ) ) . '.pm';
    if( defined( $INC{ $inc } ) )
    {
        if( defined( $version ) )
        {
            my $alter_version = ${"${class}\::VERSION"};
            # try-catch
            local $@;
            my $rv;
            eval
            {
                $rv = version->parse( $alter_version ) >= version->parse( $version );
            };
            if( $@ )
            {
                return( $self->error( "An unexpected error occurred while trying to check if module \"$class\" with version '$version' is loadable: $@" ) );
            }
            return( $rv );
        }
        else
        {
            return(1);
        }
    }
    
    foreach my $dir ( @INC )
    {
        my $fpath = File::Spec->catfile( $dir, $file );
        next if( !-e( $fpath ) || !-r( $fpath ) || -z( $fpath ) );
        if( defined( $version ) )
        {
            my $info = Module::Metadata->new_from_file( $fpath );
            my $alter_version = $info->version;
            
            # try-catch
            local $@;
            my $rv;
            eval
            {
                $rv = version->parse( $alter_version ) >= version->parse( $version );
            };
            if( $@ )
            {
                return( $self->error( "An unexpected error occurred while trying to check if module \"$class\" with version '$version' is loadable: $@" ) );
            }
            return( $rv );
        }
        return(1);
    }
    return(0);
}

sub _is_class_loaded
{
    my $self = shift( @_ );
    my $class = shift( @_ );
    if( $MOD_PERL )
    {
        # https://perl.apache.org/docs/2.0/api/Apache2/Module.html#C_loaded_
        my $rv = Apache2::Module::loaded( $class );
        return(1) if( $rv );
    }
    else
    {
        ( my $pm = $class ) =~ s{::}{/}gs;
        $pm .= '.pm';
        return(1) if( CORE::exists( $INC{ $pm } ) );
    }
    no strict 'refs';
    my $ns = \%{ $class . '::' };
    if( exists( $ns->{ISA} ) || 
        exists( $ns->{BEGIN} ) || 
        (
            exists( $ns->{VERSION} ) &&
            Scalar::Util::reftype( \$ns->{VERSION} ) eq 'GLOB' &&
            defined( ${*{\$ns->{VERSION}}{SCALAR}} )
        ) )
    {
        return(1);
    }
    return(0);
}

sub _is_code
{
    return(0) if( scalar( @_ < 2 ) );
    return(0) if( !defined( $_[1] ) );
    my $type = ref( $_[1] );
    return(0) if( !defined( $type ) );
    return( $type eq 'CODE' );
}

sub _is_glob
{
    return(0) if( scalar( @_ < 2 ) );
    return(0) if( !defined( $_[1] ) );
    my $type = Scalar::Util::reftype( $_[1] );
    return(0) if( !defined( $type ) );
    return( $type eq 'GLOB' );
}

sub _is_hash
{
    return(0) if( scalar( @_ < 2 ) );
    return(0) if( !defined( $_[1] ) );
    my $type;
    if( @_ > 2 && defined( $_[2] ) && $_[2] eq 'strict' )
    {
        $type = ref( $_[1] );
    }
    else
    {
        $type = Scalar::Util::reftype( $_[1] );
    }
    return(0) if( !defined( $type ) );
    return( $type eq 'HASH' );
}

sub _is_integer
{
    return(0) if( scalar( @_ < 2 ) );
    return(0) if( !defined( $_[1] ) || !length( $_[1] ) );
    return( $_[1] =~ /^[\+\-]?\d+$/ ? 1 : 0 );
}

sub _is_ip
{
    my $self = shift( @_ );
    my $ip   = shift( @_ );
    return(0) if( !defined( $ip ) || !length( $ip ) );
    # Already loaded
    unless( $RE{net}{IPv4} )
    {
        $self->_load_class( 'Regexp::Common' ) || return( $self->pass_error );
        Regexp::Common->import( 'net' );
    }
    # We need to return either 1 or 0. By default, perl return undef for false
    # supports IPv4 and IPv6 in CIDR notation or not
    my $ip4or6 = qr/($RE{net}{IPv4}(\/(3[0-2]|[1-2][0-9]|[0-9]))?)|($RE{net}{IPv6}(\/(12[0-8]|1[0-1][0-9]|[1-9][0-9]|[0-9]))?)/;
    return( $ip =~ /^$ip4or6$/ ? 1 : 0 );
}

sub _is_number
{
    return(0) if( scalar( @_ < 2 ) );
    return(0) if( !defined( $_[1] ) || !length( $_[1] ) );
    $_[0]->_load_class( 'Regexp::Common' ) || return( $_[0]->pass_error );
    no warnings 'once';
    return( $_[1] =~ /^$Regexp::Common::RE{num}{real}$/ );
}

sub _is_object
{
    return(0) if( scalar( @_ < 2 ) );
    return(0) if( !defined( $_[1] ) );
    return( Scalar::Util::blessed( $_[1] ) );
}

sub _is_scalar
{
    return(0) if( scalar( @_ < 2 ) );
    return(0) if( !defined( $_[1] ) );
    return( ( Scalar::Util::reftype( $_[1] ) // '' ) eq 'SCALAR' );
}

sub _is_uuid
{
    return(0) if( scalar( @_ < 2 ) );
    return(0) if( !defined( $_[1] ) || !length( $_[1] ) );
    return( $_[1] =~ /^[a-fA-F0-9]{8}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{12}$/ ? 1 : 0 );
}

sub _is_warnings_enabled { return( shift->_warnings_is_enabled( @_ ) ); }

sub _load_class
{
    my $self  = shift( @_ );
    my $class = shift( @_ ) || return( $self->error( "No package name was provided to load." ) );
    my $opts  = {};
    $opts     = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $args  = $self->_get_args_as_array( @_ );
    # Get the caller's package so we load the module in context
    my $caller_class = $opts->{caller} || CORE::caller;
    # Return if already loaded
    if( $self->_is_class_loaded( $class ) )
    {
        return( $class );
    }
    my $pl = "package ${caller_class}; use $class";
    $pl .= ' ' . $opts->{version} if( CORE::defined( $opts->{version} ) && CORE::length( $opts->{version} ) );
    if( scalar( @$args ) )
    {
        $pl .= ' qw( ' . CORE::join( ' ', @$args ) . ' );';
    }
    elsif( $opts->{no_import} )
    {
        $pl .= ' ();';
    }
    local $SIG{__DIE__} = sub{};
    local $@;
    eval( $pl );
    return( $self->error( "Unable to load package ${class}: $@" ) ) if( $@ );
    return( $self->_is_class_loaded( $class ) ? $class : '' );
}

sub _load_classes
{
    my $self  = shift( @_ );
    my $ref   = shift( @_ ) || return( $self->error( "No array reference of classes to load was provided." ) );
    return( $self->error( "Value provided is not an array reference." ) ) if( !$self->_is_array( $ref ) );
    my $opts = $self->_get_args_as_hash( @_ );
    for( @$ref )
    {
        $self->_load_class( $_, $opts ) || return( $self->pass_error );
    }
    return( $self );
}

sub _lvalue : lvalue { return( shift->_set_get_callback( @_ ) ); }

sub _message
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this = $self->_obj2h;
    no strict 'refs';
    no warnings 'once';
    if( $this->{verbose} || 
        $this->{debug} || 
        ${ $class . '::DEBUG' } || 
        # Last parameter is an hash and there is a debug property
        ( scalar( @_ ) && ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{debug} ) && $_[-1]->{debug} ) )
    {
        my $r;
        if( $MOD_PERL )
        {
            # try-catch
            local $@;
            eval
            {
                $r = Apache2::RequestUtil->request;
            };
            if( $@ )
            {
                print( STDERR "Error trying to get the global Apache2::ApacheRec: $@\n" );
            }
        }

        local $Module::Generic::TieHash::PAUSED = 1;
        my $ref;
        $ref = $self->_message_check( @_ );
        return(1) if( !$ref );
        
        my $opts = {};
        # NOTE: make sure to update this if there is use of additional parameters
        if( ref( $ref->[-1] ) eq 'HASH' &&
            scalar( grep( /^(caller_info|colour|color|level|message|no_encoding|no_exec|prefix|skip_frames|type)$/, keys( %{$ref->[-1]} ) ) ) )
        {
            $opts = pop( @$ref );
        }

        my $stackFrame = $self->_message_frame( (caller(1))[3] ) || 0;
        $stackFrame = 0 unless( $stackFrame =~ /^\d+$/ );
        $stackFrame += int( $opts->{skip_frames} ) if( CORE::exists( $opts->{skip_frames} ) );
        while( ( (caller( $stackFrame + 1 ))[3] // '' ) =~ /^Module::Generic::(?:_)?(messagef|message|messagec|message_color|message_colour|AUTOLOAD)/ )
        {
            $stackFrame++;
        }
        
        my( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
        my $sub = ( caller( $stackFrame + 1 ) )[3] // '';
        my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
        if( ref( $this->{_message_frame} ) eq 'HASH' )
        {
            if( CORE::exists( $this->{_message_frame}->{ $sub2 } ) )
            {
                my $frameNo = int( $this->{_message_frame}->{ $sub2 } );
                if( $frameNo > 0 )
                {
                    ( $pkg, $file, $line, $sub ) = caller( $frameNo );
                    $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
                }
            }
        }

        my $txt;
        if( $opts->{message} )
        {
            if( ref( $opts->{message} ) eq 'ARRAY' )
            {
                $txt = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : ( $_ // '' ), @{$opts->{message}} ) );
            }
            else
            {
                $txt = $opts->{message};
            }
        }
        else
        {
            $txt = join( '', map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} && !$opts->{no_exec} ) ? $_->() : ( $_ // '' ), @$ref ) );
        }
        # Reset it
        $this->{_msg_no_exec_sub} = 0;
        
        # Process colours if needed
        if( $opts->{colour} || $opts->{color} )
        {
            $txt = $self->colour_parse( $txt );
        }
        
        my $prefix = CORE::length( $opts->{prefix} ) ? $opts->{prefix} : '##';
        no overloading;
        $opts->{caller_info} = 1 if( !CORE::exists( $opts->{caller_info} ) || !CORE::length( $opts->{caller_info} ) );
        my $proc_info = " [PID: $$]";
        if( HAS_THREADS )
        {
            my $tid = threads->tid;
            $proc_info .= ' -> [thread id ' . $tid . ']' if( $tid );
        }
        my $mesg_raw = $opts->{caller_info} ? ( "${pkg}::${sub2}( $self ) [$line]${proc_info}: " . $txt ) : $txt;
        $mesg_raw    =~ s/\n$//gs;
        my $mesg = "${prefix} " . join( "\n${prefix} ", split( /\n/, $mesg_raw ) );
        
        my $info = 
        {
        'formatted' => $mesg,
        'message'   => $txt,
        'file'      => $file,
        'line'      => $line,
        'package'   => $class,
        'sub'       => $sub2,
        'level'     => ( $_[0] =~ /^\d+$/ ? $_[0] : CORE::exists( $opts->{level} ) ? $opts->{level} : 0 ),
        };
        $info->{type} = $opts->{type} if( $opts->{type} );
        
        ## If Mod perl is activated AND we are not using a private log
        if( $r && !${ "${class}::LOG_DEBUG" } )
        {
            if( my $log_handler = $r->get_handlers( 'PerlPrivateLogHandler' ) )
            {
                $log_handler->( $mesg_raw );
            }
            elsif( $this->{_log_handler} && ref( $this->{_log_handler} ) eq 'CODE' )
            {
                $this->{_log_handler}->( $info );
            }
            else
            {
                $r->log->debug( $mesg_raw );
            }
        }
        # Using ModPerl Server to log
        elsif( $MOD_PERL && !${ "${class}::LOG_DEBUG" } )
        {
            require Apache2::ServerUtil;
            my $s = Apache2::ServerUtil->server;
            $s->log->debug( $mesg );
        }
        # e.g. in our package, we could set the handler using the curry module like $self->{_log_handler} = $self->curry::log
        elsif( !-t( STDIN ) && $this->{_log_handler} && ref( $this->{_log_handler} ) eq 'CODE' )
        {
            $this->{_log_handler}->( $info );
        }
        elsif( !-t( STDIN ) && ${ $class . '::MESSAGE_HANDLER' } && ref( ${ $class . '::MESSAGE_HANDLER' } ) eq 'CODE' )
        {
            my $h = ${ $class . '::MESSAGE_HANDLER' };
            $h->( $info );
        }
        # Or maybe then into a private log file?
        # This way, even if the log method is superseeded, we can keep using ours without interfering with the other one
        elsif( $self->_message_log( $mesg, "\n" ) )
        {
            return(1);
        }
        # Otherwise just on the stderr
        else
        {
            if( $opts->{no_encoding} )
            {
                $stderr_raw->print( $mesg, "\n" );
            }
            else
            {
                $stderr->print( $mesg, "\n" );
            }
        }
    }
    return(1);
}

sub _message_check
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this = $self->_obj2h;
    no warnings 'uninitialized';
    no strict 'refs';
    if( @_ )
    {
        local $Module::Generic::TieHash::PAUSED = 1;
        if( $_[0] !~ /^\d/ )
        {
            # The last parameter is an options parameter which has the level property set
            if( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) )
            {
                # Then let's use this
            }
            elsif( $this->{_message_default_level} =~ /^\d+$/ &&
                $this->{_message_default_level} > 0 )
            {
                unshift( @_, $this->{_message_default_level} );
            }
            else
            {
                unshift( @_, 1 );
            }
        }
        # If the first argument looks line a number, and there is more than 1 argument
        # and it is greater than 1, and greater than our current debug level
        # well, we do not output anything then...
        if( ( $_[0] =~ /^\d+$/ || 
              ( ref( $_[-1] ) eq 'HASH' && 
                CORE::exists( $_[-1]->{level} ) && 
                $_[-1]->{level} =~ /^\d+$/ 
              )
            ) && @_ > 1 )
        {
            my $message_level = 0;
            if( $_[0] =~ /^\d+$/ )
            {
                $message_level = shift( @_ );
            }
            elsif( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{level} ) )
            {
                $message_level = $_[-1]->{level};
            }
            my $target_re = '';
            if( ref( ${ "${class}::DEBUG_TARGET" } ) eq 'ARRAY' )
            {
                $target_re = scalar( @${ "${class}::DEBUG_TARGET" } ) ? join( '|', @${ "${class}::DEBUG_TARGET" } ) : '';
            }
            if( ( exists( $this->{debug} ) && int( $this->{debug} ) >= $message_level ) ||
                ( exists( $this->{verbose} ) && int( $this->{verbose} ) >= $message_level ) ||
                ( defined( ${ $class . '::DEBUG' } ) && ${ $class . '::DEBUG' } >= $message_level ) ||
                ( ref( $_[-1] ) eq 'HASH' && CORE::exists( $_[-1]->{debug} ) && defined( $_[-1]->{debug} ) && $_[-1]->{debug} >= $message_level ) ||
                ( exists( $this->{debug_level} ) && int( $this->{debug_level} ) >= $message_level ) ||
                int( $this->{debug} ) >= 100 || 
                ( length( $target_re ) && $class =~ /^$target_re$/ && ${ $class . '::GLOBAL_DEBUG' } >= $message_level ) )
            {
                return( [ @_ ] );
            }
            else
            {
                return(0);
            }
        }
    }
    return(0);
}

sub _message_frame
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    $this->{_message_frame } = {} if( !exists( $this->{_message_frame} ) );
    my $mf = $this->{_message_frame};
    if( @_ )
    {
        my $args = {};
        if( ref( $_[0] ) eq 'HASH' )
        {
            $args = shift( @_ );
            my @k = keys( %$args );
            @$mf{ @k } = @$args{ @k };
        }
        elsif( !( @_ % 2 ) )
        {
            $args = { @_ };
            my @k = keys( %$args );
            @$mf{ @k } = @$args{ @k };
        }
        elsif( scalar( @_ ) == 1 )
        {
            my $sub = shift( @_ );
            $sub = substr( $sub, rindex( $sub, '::' ) + 2 ) if( index( $sub, '::' ) != -1 );
            return( $mf->{ $sub } );
        }
        else
        {
            return( $self->error( "I was expecting a key => value pair such as routine => stack frame (integer)" ) );
        }
    }
    return( $mf );
}

sub _message_log
{
    my $self = shift( @_ );
    my $io   = $self->_message_log_io;
    return( undef() ) if( !$io );
    return( undef() ) if( !Scalar::Util::openhandle( $io ) && $io );
    # 2019-06-14: I decided to remove this test, because if a log is provided it should print to it
    # If we are on the command line, we can easily just do tail -f log_file.txt for example and get the same result as
    # if it were printed directly on the console
    my $rc = $io->print( scalar( localtime( time() ) ), " [$$]: ", @_ ) || return( $self->error( "Unable to print to log file: $!" ) );
    return( $rc );
}

sub _message_log_io
{
    #return( shift->_set_get( 'log_io', @_ ) );
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    no strict 'refs';
    if( @_ )
    {
        my $io = shift( @_ );
        $self->_set_get( 'log_io', $io );
    }
    elsif( ${ "${class}::LOG_DEBUG" } && 
        !$self->_set_get( 'log_io' ) && 
        ${ "${class}::DEB_LOG" } )
    {
        our $DEB_LOG = ${ "${class}::DEB_LOG" };
        unless( $DEBUG_LOG_IO )
        {
            require Module::Generic::File;
            $DEB_LOG = Module::Generic::File::file( $DEB_LOG );
            $DEBUG_LOG_IO = $DEB_LOG->open( '>>', { binmode => 'utf-8', autoflush => 1 }) || 
                die( "Unable to open debug log file $DEB_LOG in append mode: $!\n" );
        }
        $self->_set_get( 'log_io', $DEBUG_LOG_IO );
    }
    return( $self->_set_get( 'log_io' ) );
}

sub _messagef
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    no strict 'refs';
    if( $this->{verbose} || $this->{debug} || ${ $class . '::DEBUG' } )
    {
        my $level = ( $_[0] =~ /^\d+$/ ? shift( @_ ) : undef() );
        my $opts = {};
        if( scalar( @_ ) > 1 && 
            ref( $_[-1] ) eq 'HASH' && 
            (
                CORE::exists( $_[-1]->{level} ) || 
                CORE::exists( $_[-1]->{type} ) || 
                CORE::exists( $_[-1]->{message} ) || 
                CORE::exists( $_[-1]->{colour} ) 
            ) )
        {
            $opts = pop( @_ );
        }
        $level = $opts->{level} if( !defined( $level ) && CORE::exists( $opts->{level} ) );
        my( $ref, $fmt );
        if( $opts->{message} )
        {
            if( ref( $opts->{message} ) eq 'ARRAY' )
            {
                $ref = $opts->{message};
                $fmt = shift( @$ref );
            }
            else
            {
                $fmt = $opts->{message};
                $ref = \@_;
            }
        }
        else
        {
            $ref = \@_;
            $fmt = shift( @$ref );
        }
        my $txt = sprintf( $fmt, map( ( ref( $_ ) eq 'CODE' && !$this->{_msg_no_exec_sub} ) ? $_->() : $_, @$ref ) );
        $txt = $self->colour_parse( $txt ) if( $opts->{colour} );
        $opts->{message} = $txt;
        $opts->{level} = $level if( defined( $level ) );
        return( $self->_message( ( $level || 0 ), $opts ) );
    }
    return(1);
}

sub _obj2h
{
    my $self = shift( @_ );
    # The method that called message was itself called using the package name like My::Package->some_method
    # We are going to check if global $DEBUG or $VERBOSE variables are set and create the related debug and verbose entry into the hash we return
    no strict 'refs';
    if( !ref( $self ) )
    {
        my $class = $self;
        my $hash =
        {
        debug   => ${ "${class}\::DEBUG" },
        verbose => ${ "${class}\::VERBOSE" },
        error   => ${ "${class}\::ERROR" },
        };
        return( bless( $hash => $class ) );
    }
    elsif( ( Scalar::Util::reftype( $self ) // '' ) eq 'HASH' )
    {
        return( $self );
    }
    elsif( ( Scalar::Util::reftype( $self ) // '' ) eq 'GLOB' )
    {
        if( ref( *$self ) eq 'HASH' )
        {
            return( *$self );
        }
        else
        {
            return( \%{*$self} );
        }
    }
    # Because object may be accessed as My::Package->method or My::Package::method
    # there is not always an object available, so we need to fake it to avoid error
    # This is primarly itended for generic methods error(), errstr() to work under any conditions.
    else
    {
        return( {} );
    }
}

sub _refaddr { return( Scalar::Util::refaddr( $_[1] ) ); }

sub _set_get
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = ( @_ == 1 ) ? shift( @_ ) : [ @_ ];
        $data->{ $field } = $val;
    }
    if( wantarray() )
    {
        if( ref( $data->{ $field } ) eq 'ARRAY' )
        {
            return( @{ $data->{ $field } } );
        }
        elsif( ref( $data->{ $field } ) eq 'HASH' )
        {
            return( %{ $data->{ $field } } );
        }
        else
        {
            return( ( $data->{ $field } ) );
        }
    }
    else
    {
        return( $data->{ $field } );
    }
}

sub _set_get_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        my $val = ( @_ == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
        if( !defined( $data->{ $field } ) && want( 'ARRAY' ) )
        {
            # The call context is an array reference.
            # To avoid the perl of 'Not an ARRAY reference', we return an empty array
            return( [] );
        }
        $data->{ $field } = $val;
    }
    return( $data->{ $field } );
}

sub _set_get_array_as_object : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;

    my $callbacks = {};
    my $def = {};
    # If this is set to true, this method will return a list in list context
    $def->{wantlist} //= 0;
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        $callbacks = $def->{callbacks} if( CORE::exists( $def->{callbacks} ) && ref( $def->{callbacks} ) eq 'HASH' );
    }
    
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            my $ctx = $_;
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
            {
                require Module::Generic::Array;
                my $o = Module::Generic::Array->new( ( defined( $data->{ $field } ) && CORE::length( $data->{ $field } ) ) ? $data->{ $field } : [] );
                $data->{ $field } = $o;
            }
            
            if( $def->{wantlist} && $ctx->{list} )
            {
                return( $data->{ $field } ? $data->{ $field }->list : () );
            }
            else
            {
                return( $data->{ $field } );
            }
        },
        set => sub
        {
            my $self = shift( @_ );
            my $ctx = $_;
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            my $val = ( @_ == 1 && ( ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'ARRAY' ) ) || ref( $_[0] ) eq 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
            require Module::Generic::Array;
            my $o = $data->{ $field };
            # Some existing data, like maybe default value
            if( $o )
            {
                if( !$self->_is_object( $o ) )
                {
                    my $tmp = $o;
                    $o = Module::Generic::Array->new( $tmp );
                }
                $o->set( $val );
            }
            else
            {
                $o = Module::Generic::Array->new( $val );
                $data->{ $field } = $o;
                if( scalar( keys( %$callbacks ) ) && 
                    ( CORE::exists( $callbacks->{add} ) || CORE::exists( $callbacks->{set} ) ) )
                {
                    my $coderef;
                    foreach my $t ( qw( add set ) )
                    {
                        if( CORE::exists( $callbacks->{ $t } ) )
                        {
                            $coderef = ref( $callbacks->{ $t } ) eq 'CODE'
                                ? $callbacks->{ $t }
                                : $self->can( $callbacks->{ $t } );
                            last if( defined( $coderef ) );
                        }
                    }
                    if( defined( $coderef ) && ref( $coderef ) eq 'CODE' )
                    {
                        $coderef->( $self, $data->{ $field } );
                    }
                }
            }
            
            if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
            {
                require Module::Generic::Array;
                my $o = Module::Generic::Array->new( ( defined( $data->{ $field } ) && CORE::length( $data->{ $field } ) ) ? $data->{ $field } : [] );
                $data->{ $field } = $o;
            }
            
            if( $def->{wantlist} && $ctx->{list} )
            {
                return( $data->{ $field } ? $data->{ $field }->list : () );
            }
            else
            {
                return( $data->{ $field } );
            }
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_boolean : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;

    my $callbacks = {};
    my $def = {};
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        $callbacks = $def->{callbacks} if( CORE::exists( $def->{callbacks} ) && ref( $def->{callbacks} ) eq 'HASH' );
    }
    
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            # If there is a value set, like a default value and it is not an object or at least not one we recognise
            # We transform it into a Module::Generic::Boolean object
            if( defined( $data->{ $field } ) &&
                CORE::length( $data->{ $field } ) && 
                ( 
                    !Scalar::Util::blessed( $data->{ $field } ) || 
                    ( 
                        Scalar::Util::blessed( $data->{ $field } ) && 
                        !$data->{ $field }->isa( 'Module::Generic::Boolean' ) && 
                        !$data->{ $field }->isa( 'JSON::PP::Boolean' ) 
                    ) 
                ) )
            {
                my $val = $data->{ $field };
                $data->{ $field } = $val ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
            }
            elsif( defined( $data->{ $field } ) &&
                   CORE::length( $data->{ $field } ) &&
                   Scalar::Util::reftype( $data->{ $field } // '' ) eq 'SCALAR' )
            {
                my $val = $data->{ $field };
                $data->{ $field } = $$val ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
            }
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            my $val = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            $val //= '';
            no warnings 'uninitialized';
            if( Scalar::Util::blessed( $val ) && 
                ( $val->isa( 'JSON::PP::Boolean' ) || $val->isa( 'Module::Generic::Boolean' ) ) )
            {
                $data->{ $field } = $val;
            }
            elsif( ( Scalar::Util::reftype( $val ) // '' ) eq 'SCALAR' )
            {
                $data->{ $field } = defined( $$val )
                    ? $$val
                        ? Module::Generic::Boolean->true
                        : Module::Generic::Boolean->false
                    : Module::Generic::Boolean->false;
            }
            elsif( lc( $val ) eq 'true' || lc( $val ) eq 'false' )
            {
                $data->{ $field } = lc( $val ) eq 'true' ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
            }
            else
            {
                $data->{ $field } = $val
                    ? Module::Generic::Boolean->true
                    : Module::Generic::Boolean->false;
            }

            if( scalar( keys( %$callbacks ) ) && 
                ( CORE::exists( $callbacks->{add} ) || CORE::exists( $callbacks->{set} ) ) )
            {
                my $coderef;
                foreach my $t ( qw( add set ) )
                {
                    if( CORE::exists( $callbacks->{ $t } ) )
                    {
                        $coderef = ref( $callbacks->{ $t } ) eq 'CODE'
                            ? $callbacks->{ $t }
                            : $self->can( $callbacks->{ $t } );
                        last if( defined( $coderef ) );
                    }
                }
                if( defined( $coderef ) && ref( $coderef ) eq 'CODE' )
                {
                    $coderef->( $self, $data->{ $field } );
                }
            }
            
            # If there is a value set, like a default value and it is not an object or at least not one we recognise
            # We transform it into a Module::Generic::Boolean object
            if( CORE::length( $data->{ $field } ) && 
                ( 
                    !Scalar::Util::blessed( $data->{ $field } ) || 
                    ( 
                        Scalar::Util::blessed( $data->{ $field } ) && 
                        !$data->{ $field }->isa( 'Module::Generic::Boolean' ) && 
                        !$data->{ $field }->isa( 'JSON::PP::Boolean' ) 
                    ) 
                ) )
            {
                my $val = $data->{ $field };
                $data->{ $field } = $val ? Module::Generic::Boolean->true : Module::Generic::Boolean->false;
            }
            return( $data->{ $field } );
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_callback : lvalue
{
    my $self = shift( @_ );
    my $def  = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my( $getter, $setter, $field ) = @$def{qw( get set field )};
    if( defined( $getter ) )
    {
        die( "Getter code value provided is actually not a code reference." ) if( ref( $getter ) ne 'CODE' );
    }
    else
    {
        $getter = sub{};
    }
    
    if( defined( $setter ) )
    {
        die( "Setter code value provided is actually not a code reference." ) if( ref( $setter ) ne 'CODE' );
    }
    else
    {
        $setter = sub{};
    }
    die( "Field value specified is empty." ) if( defined( $field ) && !CORE::length( "$field" ) );
    my $context = {};
    my $args;
    my @rv;
    if( want( qw( LVALUE ASSIGN ) ) )
    {
        $args = [want( 'ASSIGN' )];
        $context->{assign}++;
        $context->{lvalue}++;
    }
    else
    {
        if( @_ )
        {
            $args = [@_];
        }
        
        if( want( 'LVALUE' ) )
        {
            $context->{lvalue}++;
        }
        elsif( want( 'RVALUE' ) )
        {
            $context->{rvalue}++;
        }
        
        my $expect = Want::want( 'LIST' )
            ? 'LIST'
            : Want::want( 'HASH' )
                ? 'HASH'
                : Want::want( 'ARRAY' )
                    ? 'ARRAY'
                    : Want::want( 'OBJECT' )
                        ? 'OBJECT'
                        : Want::want( 'CODE' )
                            ? 'CODE'
                            : Want::want( 'REFSCALAR' )
                                ? 'REFSCALAR'
                                : Want::want( 'BOOL' )
                                    ? 'BOOLEAN'
                                    : Want::want( 'GLOB' )
                                        ? 'GLOB'
                                        : Want::want( 'SCALAR' )
                                            ? 'SCALAR'
                                            : Want::want( 'VOID' )
                                                ? 'VOID'
                                                : '';
        $context->{ lc( $expect ) }++ if( length( $expect ) );
        $context->{count} = Want::want( 'COUNT' );
    }
    $context->{eval} = $^S;
    
    if( CORE::defined( $args ) && scalar( @$args ) )
    {
        local $_ = $context;
        if( $context->{list} )
        {
            @rv = $setter->( $self, @$args );
        }
        else
        {
            $rv[0] = $setter->( $self, @$args );
        }
        
        
        if( ( !scalar( @rv ) || ( scalar( @rv ) == 1 && !defined( $rv[0] ) ) ) && 
            ( my $has_error = $self->error ) )
        {
            if( $context->{assign} )
            {
                $data->{__lvalue_error} = undef;
                return( $data->{__lvalue_error} );
            }
            else
            {
                return( $self->pass_error );
            }
        }
        else
        {
            if( $context->{assign} )
            {
                if( defined( $field ) )
                {
                    return( $data->{ $field } );
                }
                else
                {
                    return( $data->{__lvalue} = $rv[0] );
                }
            }
            elsif( $context->{list} )
            {
                return( @rv );
            }
            elsif( $context->{lvalue} )
            {
                if( !$self->_is_object( $rv[0] ) && $context->{object} )
                {
                    require Module::Generic::Null;
                    return( Module::Generic::Null->new( wants => 'OBJECT' ) ) if( $context->{lvalue} );
                }
                return( $rv[0] );
            }
            else
            {
                if( !$self->_is_object( $rv[0] ) && $context->{object} )
                {
                    require Module::Generic::Null;
                    rreturn( Module::Generic::Null->new( wants => 'OBJECT' ) );
                }
                rreturn( $rv[0] );
            }
            return;
        }
    }
    
    local $_ = $context;
    if( $context->{list} )
    {
        @rv = $getter->( $self );
    }
    else
    {
        $rv[0] = $getter->( $self );
    }
    
    if( !scalar( @rv ) && 
        ( my $has_error = $self->error ) )
    {
        if( $context->{rvalue} )
        {
            if( $context->{object} )
            {
                require Module::Generic::Null;
                rreturn( Module::Generic::Null->new( wants => 'OBJECT' ) );
            }
            rreturn;
        }
        else
        {
            if( $context->{object} )
            {
                require Module::Generic::Null;
                return( Module::Generic::Null->new( wants => 'OBJECT' ) );
            }
            return;
        }
    }
    else
    {
        if( $context->{rvalue} )
        {
            if( $context->{list} )
            {
                rreturn( @rv );
            }
            else
            {
                if( !$self->_is_object( $rv[0] ) && $context->{object} )
                {
                    require Module::Generic::Null;
                    rreturn( Module::Generic::Null->new( wants => 'OBJECT' ) );
                }
                rreturn( $rv[0] );
            }
        }
        else
        {
            if( $context->{list} )
            {
                return( @rv );
            }
            else
            {
                if( !$self->_is_object( $rv[0] ) && $context->{object} )
                {
                    require Module::Generic::Null;
                    return( Module::Generic::Null->new( wants => 'OBJECT' ) ) if( $context->{lvalue} );
                    rreturn( Module::Generic::Null->new( wants => 'OBJECT' ) );
                }
                return( $rv[0] ) if( $context->{lvalue} );
                rreturn( $rv[0] );
            }
        }
    }
    return;
}

# $self->_set_get_class( 'my_field', {
# _class => 'My::Class',
# field1 => { type => 'datetime' },
# field2 => { type => 'scalar' },
# field3 => { type => 'boolean' },
# field4 => { type => 'object', class => 'Some::Class' },
# }, @_ );
sub _set_get_class
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $def   = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( ref( $def ) ne 'HASH' )
    {
        CORE::warn( "Warning only: dynamic class field definition hash ($def) for field \"$field\" is not a hash reference." );
        return;
    }
    
    my $class = $self->__create_class( $field, $def ) || die( "Failed to create the dynamic class for field \"$field\".\n" );
    
    if( @_ )
    {
        my $hash = shift( @_ );
        $hash->{debug} = $self->debug if( ref( $hash ) eq 'HASH' && !exists( $hash->{debug} ) );
        # my $o = $class->new( $hash );
        # my $o = $self->__instantiate_object( $field, $class, ( %$hash, debug => $self->debug ) );
        my $o = $self->__instantiate_object( $field, $class, $hash );
        $data->{ $field } = $o;
    }
    
    if( !$data->{ $field } )
    {
        my $o = $self->__instantiate_object( $field, $class );
        $o->debug( $self->debug ) if( $o && $o->can( 'debug' ) );
        $data->{ $field } = $o;
    }
    return( $data->{ $field } );
}

sub _set_get_class_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $def   = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( ref( $def ) ne 'HASH' )
    {
        CORE::warn( "Warning only: dynamic class field definition hash ($def) for field \"$field\" is not a hash reference." );
        return;
    }
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    my $class = $self->__create_class( $field, $def ) || die( "Failed to create the dynamic class for field \"$field\".\n" );
    # return( $self->_set_get_object_array( $field, $class, @_ ) );
    if( @_ )
    {
        my $ref = shift( @_ );
        return( $self->error( "I was expecting an array ref, but instead got '$ref'. _is_array returned: '", $self->_is_array( $ref ), "'" ) ) if( !$self->_is_array( $ref ) );
        my $arr = [];
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            if( ref( $ref->[$i] ) ne 'HASH' )
            {
                return( $self->error( "Array offset $i is not a hash reference. I was expecting a hash reference to instantiate an object of class $class." ) );
            }
            my $o = $self->__instantiate_object( $field, $class, $ref->[$i] ) || return( $self->pass_error );
            # If an error occurred, we report it to the caller and do not add it, since even if we did add it, it would be undef, because no object would have been created.
            # And the caller needs to know there has been some errors
            CORE::push( @$arr, $o );
        }
        $data->{ $field } = $arr;
    }
    return( $data->{ $field } );
}

sub _set_get_code : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $opts = {};

    if( ref( $field ) eq 'HASH' )
    {
        $opts = $field;
        if( CORE::exists( $opts->{field} ) && 
            defined( $opts->{field} ) && 
            CORE::length( $opts->{field} ) )
        {
            $field = $opts->{field};
        }
        else
        {
            $field = undef;
        }
    }
    $opts->{undef_ok} //= 0;
    $opts->{return_undef} //= 0;
    
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            my $ctx = $_;
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            if( ( !defined( $data->{ $field } ) || !$data->{ $field } ) && 
                !$opts->{return_undef} &&
                $ctx->{object} )
            {
                return( sub{} );
            }
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            my $ctx = $_;
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            my $v = $arg;
            if( ( ( $opts->{undef_ok} && defined( $v ) ) || !$opts->{undef_ok} ) && 
                ref( $v ) ne 'CODE' )
            {
                return( $self->error( "Value provided for \"$field\" ($v) is not an anonymous subroutine (code). You can pass as argument something like \$self->curry::my_sub or something like sub { some_code_here; }" ) );
            }
            $data->{ $field } = $v;

            if( ( !defined( $data->{ $field } ) || !$data->{ $field } ) && 
                !$opts->{return_undef} &&
                $ctx->{object} )
            {
                return( sub{} );
            }
            return( $data->{ $field } );
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_file : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    no overloading;
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            if( $data->{ $field } && !$self->_is_a( $data->{ $field } => 'Module::Generic::File' ) )
            {
                require Module::Generic::File;
                $data->{ $field } = Module::Generic::File->new( $data->{ $field } . '' ) ||
                    return( $self->error( Module::Generic::File->error ) );
            }
            return( $data->{ $field } )
        },
        set => sub
        {
            my $self = shift( @_ );
            @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
            my $arg = shift( @_ );
            require Module::Generic::File;
            my $val;
            if( $self->_is_a( $arg => 'Module::Generic::File' ) )
            {
                $val = $arg;
            }
            elsif( defined( $arg ) )
            {
                $val = Module::Generic::File->new( $arg ) || 
                    return( $self->pass_error( Module::Generic::File->error ) );
            }
            return( $data->{ $field } = $val );
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_glob : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
            my $arg = shift( @_ );
            if( defined( $arg ) && Scalar::Util::reftype( $arg ) ne 'GLOB' )
            {
                return( $self->error( "Method $field takes only a glob, but value provided ($arg) is not supported" ) );
            }
            return( $data->{ $field } = $arg );
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_hash : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;

    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
            my $arg;
            if( @_ )
            {
                if( ref( $_[0] ) eq 'HASH' )
                {
                    $arg = shift( @_ );
                }
                elsif( !( @_ % 2 ) )
                {
                    $arg = { @_ };
                }
                else
                {
                    $arg = shift( @_ );
                }
            }
            if( defined( $arg ) && ref( $arg ) ne 'HASH' )
            {
                return( $self->error( "Method $field takes only a hash or reference to a hash, but value provided ($arg) is not supported" ) );
            }
            return( $data->{ $field } = $arg );
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_hash_as_mix_object : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $opts = {};
    
    if( ref( $field ) eq 'HASH' )
    {
        $opts = $field;
        if( CORE::exists( $opts->{field} ) && 
            defined( $opts->{field} ) && 
            CORE::length( $opts->{field} ) )
        {
            $field = $opts->{field};
        }
        else
        {
            $field = undef;
        }
    }
    $opts->{undef_ok} //= 0;
    $opts->{return_undef} //= 0;

    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            my $ctx = $_;
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            if( !defined( $data->{ $field } ) )
            {
                # If the call context is either an hash or an object, we instantiate an empty object, and return it,
                # but we do not affect the current property value of our object
                if( $ctx->{object} || $ctx->{hash} )
                {
                    require Module::Generic::Hash;
                    local $Module::Generic::Hash::DEBUG = $self->debug;
                    my $o = Module::Generic::Hash->new( $data->{ $field } );
                    return( $o );
                }
                return;
            }
            elsif( $data->{ $field } && !$self->_is_object( $data->{ $field } ) )
            {
                require Module::Generic::Hash;
                local $Module::Generic::Hash::DEBUG = $self->debug;
                my $o = Module::Generic::Hash->new( $data->{ $field } );
                $data->{ $field } = $o;
            }
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            my $ctx = $_;
            my $arg;
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) && !$opts->{undef_ok} );
            if( @_ )
            {
                if( ref( $_[0] ) eq 'HASH' )
                {
                    $arg = shift( @_ );
                }
                elsif( ref( $_[0] ) eq 'Module::Generic::Hash' )
                {
                    $arg = $_[0]->clone;
                }
                elsif( ( @_ % 2 ) )
                {
                    $arg = { @_ };
                }
                elsif( !defined( $_[0] ) && $opts->{undef_ok} )
                {
                    $arg = undef;
                }
                else
                {
                    $arg = shift( @_ );
                    return( $self->error( "Method $field takes only a hash or reference to a hash, but value provided ($arg) is not supported" ) );
                }
            }
            my $val = $arg;
            if( !defined( $val ) )
            {
                $data->{ $field } = undef;
            }
            elsif( ref( $val ) eq 'Module::Generic::Hash' )
            {
                return( $data->{ $field } = $val );
            }
            else
            {
                require Module::Generic::Hash;
                local $Module::Generic::Hash::DEBUG = $self->debug;
                $data->{ $field } = Module::Generic::Hash->new( $val );
            }
            
            if( !defined( $data->{ $field } ) )
            {
                # If the call context is either an hash or an object, we instantiate an empty object, and return it,
                # but we do not affect the current property value of our object
                if( $ctx->{object} || $ctx->{hash} )
                {
                    require Module::Generic::Hash;
                    local $Module::Generic::Hash::DEBUG = $self->debug;
                    my $o = Module::Generic::Hash->new( $data->{ $field } );
                    return( $o );
                }
                return;
            }
            elsif( $data->{ $field } && !$self->_is_object( $data->{ $field } ) )
            {
                require Module::Generic::Hash;
                local $Module::Generic::Hash::DEBUG = $self->debug;
                my $o = Module::Generic::Hash->new( $data->{ $field } );
                $data->{ $field } = $o;
            }
            return( $data->{ $field } );
        },
        field => $field,
    }, @_ ) );
}

# There is no lvalue here on purpose
sub _set_get_hash_as_object
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    my $field = shift( @_ ) || return( $self->error( "No field provided for _set_get_hash_as_object" ) );
    my $class;
    @_ = () if( @_ == 1 && !defined( $_[0] ) );
    no strict 'refs';
    if( @_ )
    {
        # No class was provided
        if( ( Scalar::Util::reftype( $_[0] ) // '' ) eq 'HASH' )
        {
            my $new_class = $field;
            $new_class =~ tr/-/_/;
            $new_class =~ s/\_{2,}/_/g;
            $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
            $class = ( ref( $self ) || $self ) . "\::${new_class}";
        }
        elsif( ref( $_[0] ) )
        {
            return( $self->error( "Class name in _set_get_hash_as_object helper method cannot be a reference. Received: \"", overload::StrVal( $_[0] // 'undef' ), "\"." ) );
        }
        elsif( CORE::length( $_[0] // '' ) )
        {
            $class = shift( @_ );
        }
    }
    else
    {
        my $new_class = $field;
        $new_class =~ tr/-/_/;
        $new_class =~ s/\_{2,}/_/g;
        $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
        $class = ( ref( $self ) || $self ) . "\::${new_class}";
    }
    # my $class = shift( @_ );
    my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    unless( Class::Load::is_class_loaded( $class ) )
    {
        my $perl .= <<EOT;
package $class;
BEGIN
{
    use strict;
    use warnings::register;
    use Module::Generic;
    use parent qw( Module::Generic::Dynamic );
};

use strict;
use warnings;

1;

EOT
        local $@;
        my $rc = eval( $perl );
        die( "Unable to dynamically create module \"$class\" for field \"$field\" based on our own class \"", ( ref( $self ) || $self ), "\": $@" ) if( $@ );
    }
    
    if( @_ )
    {
        my $hash = shift( @_ );
        no warnings 'once';
        $Module::Generic::Dynamic::DEBUG = $self->debug unless( CORE::exists( $hash->{debug} ) );
        my $o = $self->__instantiate_object( $field, $class, $hash ) || return( $self->pass_error );
        $data->{ $field } = $o;
    }
    
    if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
    {
        my $o = $data->{ $field } = $self->__instantiate_object( $field, $class, $data->{ $field } );
    }
    return( $data->{ $field } );
}

sub _set_get_ip : lvalue
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;

    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            my $v = $self->_is_a( $data->{ $field }, 'Module::Generic::Scalar' )
                ? $data->{ $field }
                : $self->new_scalar( $data->{ $field } );
            if( !$v->defined )
            {
                return;
            }
            else
            {
                return( $v );
            }
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            my $ctx = $_;
            my $v = $arg;
            # If the user wants to remove it
            if( !defined( $v ) )
            {
                $data->{ $field } = $v;
            }
            # If the user provided a string, let's check it
            elsif( length( $v ) && !$self->_is_ip( $v ) )
            {
                return( $self->error( "Value provided ($v) is not a valid ip address." ) );
            }
            $data->{ $field } = $self->new_scalar( $v );
            
            $v = $self->_is_a( $data->{ $field }, 'Module::Generic::Scalar' )
                ? $data->{ $field }
                : $self->new_scalar( $data->{ $field } );
            if( !$v->defined )
            {
                return;
            }
            else
            {
                return( $v );
            }
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_lvalue : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
            my $val  = shift( @_ );
            $data->{ $field } = $val;
            # lnoreturn;
            return( $data->{ $field } );
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_number : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    no overload;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $opts = {};
    
    my $callbacks = {};
    if( ref( $field ) eq 'HASH' )
    {
        $opts = $field;
        if( CORE::exists( $opts->{field} ) && 
            defined( $opts->{field} ) && 
            CORE::length( $opts->{field} ) )
        {
            $field = $opts->{field};
        }
        else
        {
            $field = undef;
        }
        $callbacks = $opts->{callbacks} if( CORE::exists( $opts->{callbacks} ) && ref( $opts->{callbacks} ) eq 'HASH' );
    }
    # $opts->{undef_ok} //= 0;
    
    my $do_callback = sub
    {
        if( scalar( keys( %$callbacks ) ) && 
            ( CORE::exists( $callbacks->{add} ) || CORE::exists( $callbacks->{set} ) ) )
        {
            my $coderef;
            foreach my $t ( qw( add set ) )
            {
                if( CORE::exists( $callbacks->{ $t } ) )
                {
                    $coderef = ref( $callbacks->{ $t } ) eq 'CODE'
                        ? $callbacks->{ $t }
                        : $self->can( $callbacks->{ $t } );
                    last if( defined( $coderef ) );
                }
            }
            if( defined( $coderef ) && ref( $coderef ) eq 'CODE' )
            {
                $coderef->( $self, $data->{ $field } );
            }
        }
    };
    
    require Module::Generic::Number;

    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            if( CORE::length( $data->{ $field } ) && !ref( $data->{ $field } ) )
            {
                my $v = Module::Generic::Number->new( $data->{ $field } );
                $data->{ $field } = $v if( defined( $v ) );
            }
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            if( ( !defined( $_[0] ) || !scalar( @_ ) ) )
            {
                if( CORE::exists( $opts->{undef_ok} ) && !$opts->{undef_ok} )
                {
                    return( $self->error( "Number provided is undef, which is not permitted for '${field}'" ) );
                }
                else
                {
                    $data->{ $field } = shift( @_ );
                }
            }
            else
            {
                my $v = Module::Generic::Number->new( shift( @_ ) );
                return( $self->pass_error( Module::Generic::Number->error ) ) if( !defined( $v ) );
                $data->{ $field } = $v;
            }
            $do_callback->();

            if( CORE::length( $data->{ $field } // '' ) && !ref( $data->{ $field } ) )
            {
                my $v = Module::Generic::Number->new( $data->{ $field } );
                $data->{ $field } = $v if( defined( $v ) );
            }
            return( $data->{ $field } );
        },
        field => $field
    }, @_ ) );
}

sub _set_get_number_as_object : lvalue { return( shift->_set_get_number( @_ ) ); }

sub _set_get_number_as_scalar : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    no overload;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    
    my $callbacks = {};
    my $def = {};
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        $callbacks = $def->{callbacks} if( CORE::exists( $def->{callbacks} ) && ref( $def->{callbacks} ) eq 'HASH' );
    }
    
    my $do_callback = sub
    {
        if( scalar( keys( %$callbacks ) ) && 
            ( CORE::exists( $callbacks->{add} ) || CORE::exists( $callbacks->{set} ) ) )
        {
            my $coderef;
            foreach my $t ( qw( add set ) )
            {
                if( CORE::exists( $callbacks->{ $t } ) )
                {
                    $coderef = ref( $callbacks->{ $t } ) eq 'CODE'
                        ? $callbacks->{ $t }
                        : $self->can( $callbacks->{ $t } );
                    last if( defined( $coderef ) );
                }
            }
            if( defined( $coderef ) && ref( $coderef ) eq 'CODE' )
            {
                $coderef->( $self, $data->{ $field } );
            }
        }
    };

    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            my $v = $arg;
            require Regexp::Common;
            Regexp::Common->import( 'number' );
            # If the user wants to remove it
            if( defined( $v ) && $v !~ /^$RE{num}{real}$/ )
            {
                return( $self->error( "Method $field takes only a number, but value provided ($arg) is not a number" ) );
            }
            $data->{ $field } = $v;
            $do_callback->();
            
            return( $data->{ $field } );
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_number_or_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        if( ref( $_[0] ) eq 'HASH' || Scalar::Util::blessed( $_[0] ) )
        {
            return( $self->_set_get_object( $field, $class, @_ ) );
        }
        else
        {
            return( $self->_set_get_number( $field, @_ ) );
        }
    }
    if( !CORE::length( $data->{ $field } // '' ) && want( 'OBJECT' ) )
    {
        require Module::Generic::Null;
        return( Module::Generic::Null->new( wants => 'OBJECT' ) );
    }
    return( $data->{ $field } );
}

sub _set_get_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    no overloading;

    my $def = {};
    # no_init
    my $callback;
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        return( $self->error( "No property 'field' was provided in the parameters of _set_get_object" ) ) if( !length( $field // '' ) );
        if( CORE::exists( $def->{callback} ) &&
            defined( $def->{callback} ) &&
            ref( $def->{callback} ) eq 'CODE' )
        {
            $callback = $def->{callback};
        }
    }
    
    # Parameters are provided to instantiate the object
    if( @_ )
    {
        if( scalar( @_ ) == 1 )
        {
            # User removed the value by passing it an undefined value
            if( !defined( $_[0] ) )
            {
                $data->{ $field } = undef();
            }
            # User pass an object
            elsif( Scalar::Util::blessed( $_[0] ) )
            {
                my $o = shift( @_ );
                if( ref( $class ) eq 'ARRAY' )
                {
                    my $ok = 0;
                    foreach my $c ( @$class )
                    {
                        if( $o->isa( $c ) )
                        {
                            $ok++, last;
                        }
                    }
                    return( $self->error( "Object provided (", ref( $o ), ") for $field does not match any of the possible classes: '", join( "', '", @$class ), "'." ) ) if( !$ok );
                }
                else
                {
                    return( $self->error( "Object provided (", ref( $o ), ") for $field is not a valid $class object" ) ) if( !$o->isa( "$class" ) );
                }
                $data->{ $field } = $o;
            }
            else
            {
                $class = $class->[0] if( ref( $class ) eq 'ARRAY' );
                my $o = $self->_instantiate_object( { field => $field, ( defined( $callback ) ? ( callback => $callback ) : () ) }, $class, @_ ) || do
                {
                    if( $class->can( 'error' ) )
                    {
                        return( $self->pass_error( $class->error ) );
                    }
                    else
                    {
                        return( $self->error( "Unable to instantiate an object for class \"$class\" and values provided: '", join( "', '", @_ ), "'." ) );
                    }
                };
                $data->{ $field } = $o;
            }
        }
        elsif( $def->{no_init} && !$data->{ $field } )
        {
            # We do nothing
        }
        else
        {
            $class = $class->[0] if( ref( $class ) eq 'ARRAY' );
            # There is already an object, so we pass any argument to the existing object
            if( $data->{ $field } && $self->_is_a( $data->{ $field }, $class ) )
            {
                warn( "Re-setting existing object '", overload::StrVal( $data->{ $field } // 'undef' ), "' for field '$field' and class '$class'\n" );
            }
            
            my $o = $self->_instantiate_object( { field => $field, ( defined( $callback ) ? ( callback => $callback ) : () ) }, $class, @_ ) || do
            {
                if( $class->can( 'error' ) )
                {
                    return( $self->pass_error( $class->error ) );
                }
                else
                {
                    return( $self->error( "Unable to instantiate an object for class \"$class\" with no value provided." ) );
                }
            };
            $data->{ $field } = $o;
        }
    }
    # If nothing has been set for this field, ie no object, but we are called in chain
    # we set a dummy object that will just call itself to avoid perl complaining about undefined value calling a method
    if( !$data->{ $field } && want( 'OBJECT' ) )
    {
        if( $def->{no_init} )
        {
            require Module::Generic::Null;
            my $null = Module::Generic::Null->new( '', { debug => $this->{debug} });
            return( $null );
        }
        else
        {
            $class = $class->[0] if( ref( $class ) eq 'ARRAY' );
            my $o = $self->_instantiate_object( { field => $field, ( defined( $callback ) ? ( callback => $callback ) : () ) }, $class, @_ ) || do
            {
                if( $class->can( 'error' ) )
                {
                    return( $self->pass_error( $class->error ) );
                }
                else
                {
                    return( $self->error( "Unable to instantiate an object for class \"$class\" with no value provided." ) );
                }
            };
            $data->{ $field } = $o;
            return( $o );
        }        
    }
    return( $data->{ $field } );
}

sub _set_get_object_lvalue : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    no overloading;
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;

    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            my $ctx = $_;
            if( !defined( $arg ) )
            {
                $data->{ $field } = undef();
            }
            # User pass an object
            elsif( Scalar::Util::blessed( $arg ) )
            {
                if( ref( $class ) eq 'ARRAY' )
                {
                    my $ok = 0;
                    foreach my $c ( @$class )
                    {
                        if( $arg->isa( $c ) )
                        {
                            $ok++, last;
                        }
                    }
                    return( $self->error( "Object provided (" . ref( $arg ) . ") for $field does not match any of the possible classes: '" . join( "', '", @$class ) . "'." ) );
                }
                else
                {
                    if( !$arg->isa( "$class" ) )
                    {
                        return( $self->error( "Object provided (" . ref( $arg ) . ") for $field is not a valid $class object" ) );
                    }
                }
                $data->{ $field } = $arg;
            }
            else
            {
                return( $self->error( "Value provided (" . overload::StrVal( $arg // '' ) . " is not an object." ) );
            }
            # We need to return something else than our object, or by virtue of perl's way of working
            # we would return our object as coded below, and that object will be assigned the
            # very value we will have passed in assignment !
            return( $data->{__dummy} = 'dummy' ) if( $ctx->{assign} );
            return( $data->{ $field } );
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_object_without_init
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    no overloading;
    
    my $def = {};
    my $callback;
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        return( $self->error( "No property 'field' was provided in the parameters of _set_get_object" ) ) if( !length( $field // '' ) );
        # Callback used to instantiate the object
        if( CORE::exists( $def->{callback} ) &&
            defined( $def->{callback} ) &&
            ref( $def->{callback} ) eq 'CODE' )
        {
            $callback = $def->{callback};
        }
    }

    if( @_ )
    {
        if( scalar( @_ ) == 1 )
        {
            # User removed the value by passing it an undefined value
            if( !defined( $_[0] ) )
            {
                $data->{ $field } = undef();
            }
            # User pass an object
            elsif( Scalar::Util::blessed( $_[0] ) )
            {
                my $o = shift( @_ );
                if( ref( $class ) eq 'ARRAY' )
                {
                    my $ok = 0;
                    foreach my $c ( @$class )
                    {
                        if( $o->isa( $c ) )
                        {
                            $ok++, last;
                        }
                    }
                    return( $self->error( "Object provided (", ref( $o ), ") for $field does not match any of the possible classes: '", join( "', '", @$class ), "'." ) ) if( !$ok );
                }
                else
                {
                    return( $self->error( "Object provided (", ref( $o ), ") for $field is not a valid $class object" ) ) if( !$o->isa( "$class" ) );
                }
                $data->{ $field } = $o;
            }
            else
            {
                # return( $self->error( "Only undef or an ", ( ref( $class ) eq 'ARRAY' ? join( ', ', @$class ) : $class ), " object can be provided." ) );
                my $o = $self->_instantiate_object( { field => $field, ( defined( $callback ) ? ( callback => $callback ) : () ) }, $class, @_ ) || do
                {
                    if( $class->can( 'error' ) )
                    {
                        return( $self->pass_error( $class->error ) );
                    }
                    else
                    {
                        return( $self->error( "Unable to instantiate an object for class \"$class\" and values provided: '", join( "', '", @_ ), "'." ) );
                    }
                };
                $data->{ $field } = $o;
            }
        }
        else
        {
            # return( $self->error( "Only undef or an ", ( ref( $class ) eq 'ARRAY' ? join( ', ', @$class ) : $class ), " object can be provided." ) );
            my $o = $self->_instantiate_object( { field => $field, ( defined( $callback ) ? ( callback => $callback ) : () ) }, $class, @_ ) || do
            {
                if( $class->can( 'error' ) )
                {
                    return( $self->pass_error( $class->error ) );
                }
                else
                {
                    return( $self->error( "Unable to instantiate an object for class \"$class\" with no value provided." ) );
                }
            };
            $data->{ $field } = $o;
        }
    }
    # If nothing has been set for this field, ie no object, but we are called in chain, this will fail on purpose.
    # To avoid this, use _set_get_object
    return( $data->{ $field } );
}

sub _set_get_object_array2
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    
    my $def = {};
    my $callback;
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        return( $self->error( "No property 'field' was provided in the parameters of _set_get_object" ) ) if( !length( $field // '' ) );
        if( CORE::exists( $def->{callback} ) &&
            defined( $def->{callback} ) &&
            ref( $def->{callback} ) eq 'CODE' )
        {
            $callback = $def->{callback};
        }
    }
    
    if( @_ )
    {
        my $data_to_process = shift( @_ );
        return( $self->error( "I was expecting an array ref, but instead got '$data_to_process'. _is_array returned: '", $self->_is_array( $data_to_process ), "'" ) ) if( !$self->_is_array( $data_to_process ) );
        my $arr1 = [];
        foreach my $ref ( @$data_to_process )
        {
            return( $self->error( "I was expecting an embeded array ref, but instead got '$ref'." ) ) if( ref( $ref ) ne 'ARRAY' );
            my $arr = [];
            for( my $i = 0; $i < scalar( @$ref ); $i++ )
            {
                my $o;
                if( defined( $ref->[$i] ) )
                {
                    return( $self->error( "Parameter provided for adding object of class $class is not a reference." ) ) if( !ref( $ref->[$i] ) );
                    if( Scalar::Util::blessed( $ref->[$i] ) )
                    {
                        return( $self->error( "Array offset $i contains an object from class ", $ref->[$i], ", but was expecting an object of class $class." ) ) if( !$ref->[$i]->isa( $class ) );
                        $o = $ref->[$i];
                    }
                    elsif( ref( $ref->[$i] ) eq 'HASH' )
                    {
                        #$o = $class->new( $h, $ref->[$i] );
                        $o = $self->_instantiate_object( { field => $field, ( defined( $callback ) ? ( callback => $callback ) : () ) }, $class, $ref->[$i] );
                    }
                    else
                    {
                        $self->error( "Warning only: data provided to instaantiate object of class $class is not a hash reference" );
                    }
                }
                else
                {
                    #$o = $class->new( $h );
                    $o = $self->_instantiate_object( { field => $field, ( defined( $callback ) ? ( callback => $callback ) : () ) }, $class );
                }
                return( $self->error( "Unable to instantiate an object of class $class: ", $class->error ) ) if( !defined( $o ) );
                # $o->{_parent} = $self->{_parent};
                push( @$arr, $o );
            }
            push( @$arr1, $arr );
        }
        $data->{ $field } = $arr1;
    }
    return( $data->{ $field } );
}

sub _set_get_object_array
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );

    my $def = {};
    my $callback;
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        return( $self->error( "No property 'field' was provided in the parameters of _set_get_object_array" ) ) if( !CORE::length( $field // '' ) );
        if( CORE::exists( $def->{callback} ) &&
            defined( $def->{callback} ) &&
            ref( $def->{callback} ) eq 'CODE' )
        {
            $callback = $def->{callback};
        }
    }
    $def->{empty_ok} //= 0;
    $def->{skip_empty} //= 0;
    
    my $process = sub
    {
        my $ref = shift( @_ );
        return( $self->error( "I was expecting an array ref, but instead got '$ref'. _is_array returned: '", $self->_is_array( $ref ), "'" ) ) if( !$self->_is_array( $ref ) );
        my $arr = [];
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            if( defined( $ref->[$i] ) || $def->{empty_ok} )
            {
#                 return( $self->error( "Array offset $i is not a reference. I was expecting an object of class $class or an hash reference to instantiate an object." ) ) if( !ref( $ref->[$i] ) );
                if( Scalar::Util::blessed( $ref->[$i] ) )
                {
                    return( $self->error( "Array offset $i contains an object from class ", $ref->[$i], ", but was expecting an object of class $class." ) ) if( !$ref->[$i]->isa( $class ) );
                    push( @$arr, $ref->[$i] );
                }
                elsif( $self->_is_empty( $ref->[$i] ) && $def->{skip_empty} )
                {
                    next;
                }
                else
                {
                    my $o = $self->_instantiate_object( { field => $field, ( defined( $callback ) ? ( callback => $callback ) : () ) }, $class, $ref->[$i] ) || return( $self->pass_error );
                    push( @$arr, $o );
                }
            }
            elsif( $def->{skip_empty} )
            {
                next;
            }
            else
            {
                return( $self->error( "Array offset $i contains an undefined value. I was expecting an object of class $class." ) );
                # my $o = $self->_instantiate_object( $field, $class ) || return( $self->pass_error );
                # push( @$arr, $o );
            }
        }
        return( $arr );
    };
    
    if( @_ )
    {
        $data->{ $field } = $process->( @_ );
    }
    # For example, if the object property is set at init, without using a method
    if( $data->{ $field } && ref( $data->{ $field } ) ne 'ARRAY' )
    {
        $data->{ $field } = $process->( $data->{ $field } );
    }
    return( $data->{ $field } );
}

sub _set_get_object_array_object
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field name was provided for this array of object." ) );
    my $class = shift( @_ ) || return( $self->error( "No class was provided for this array of objects." ) );
    my $this = $self->_obj2h;
    my $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    require Module::Generic::Array;
    
    my $def = {};
    my $callback;
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        return( $self->error( "No property 'field' was provided in the parameters of _set_get_object_array" ) ) if( !CORE::length( $field // '' ) );
        if( CORE::exists( $def->{callback} ) &&
            defined( $def->{callback} ) &&
            ref( $def->{callback} ) eq 'CODE' )
        {
            $callback = $def->{callback};
        }
    }
    else
    {
        $def = { field => $field };
    }
    
    my $process = sub
    {
        my $that = ( scalar( @_ ) == 1 && UNIVERSAL::isa( $_[0], 'ARRAY' ) ) ? shift( @_ ) : [ @_ ];
        my $ref = $self->_set_get_object_array( $def, $class, $that ) || return( $self->pass_error );
        return( Module::Generic::Array->new( $ref ) );
    };
    
    if( @_ )
    {
        $data->{ $field } = $process->( @_ );
    }
    ## Default value so that call to the caller's method like my_sub->length will not produce something like "Can't call method "length" on an undefined value"
    ## Also, this will make it possible to set default value in caller's object and we would turn it into array object.
    if( !$data->{ $field } || !$self->_is_a( $data->{ $field }, 'Module::Generic::Array' ) )
    {
        $data->{ $field } = $process->( CORE::defined( $data->{ $field } ) ? $data->{ $field } : () );
    }
    return( $data->{ $field } );
}

sub _set_get_object_variant
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    # The class precisely depends on what we find looking ahead
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    
    my $def = {};
    my $callback;
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        return( $self->error( "No property 'field' was provided in the parameters of _set_get_object_array" ) ) if( !CORE::length( $field // '' ) );
        if( CORE::exists( $def->{callback} ) &&
            defined( $def->{callback} ) &&
            ref( $def->{callback} ) eq 'CODE' )
        {
            $callback = $def->{callback};
        }
    }
    
    my $process = sub
    {
        if( ref( $_[0] ) eq 'HASH' )
        {
            my $o = $self->_instantiate_object( $field, $class, @_ );
            return( $o );
        }
        # An array of objects hash
        elsif( ref( $_[0] ) eq 'ARRAY' )
        {
            my $arr = shift( @_ );
            my $res = [];
            foreach my $data ( @$arr )
            {
                my $o = $self->_instantiate_object( { field => $field, ( defined( $callback ) ? ( callback => $callback ) : () ) }, $class, $data ) || return( $self->error( "Unable to create object: ", $self->error ) );
                push( @$res, $o );
            }
            return( $res );
        }
    };
    
    if( @_ )
    {
        $data->{ $field } = $process->( @_ );
    }
    return( $data->{ $field } );
}

sub _set_get_scalar : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;

    my $callbacks = {};
    my $def = {};
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        $callbacks = $def->{callbacks} if( CORE::exists( $def->{callbacks} ) && ref( $def->{callbacks} ) eq 'HASH' );
    }

    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            my $v = $data->{ $field };
            # If we have a callback, call it and get the resulting value
            if( scalar( keys( %$callbacks ) ) && 
                CORE::exists( $callbacks->{get} ) &&
                ref( $callbacks->{get} ) eq 'CODE' )
            {
                $v = $callbacks->{get}->( $self, $v );
            }
            return( $v );
        },
        set => sub
        {
            my $self = shift( @_ );
            my $val = ( @_ == 1 ) ? shift( @_ ) : join( '', @_ );
            # Just in case, we force stringification
            # $val = "$val" if( defined( $val ) );
            if( ref( $val ) eq 'HASH' || ref( $val ) eq 'ARRAY' )
            {
                return( $self->error( "Method $field takes only a scalar, but value provided ($val) is a reference" ) );
            }
            # return( $data->{ $field } = $val );
            $data->{ $field } = $val;

            if( scalar( keys( %$callbacks ) ) && 
                ( CORE::exists( $callbacks->{add} ) || CORE::exists( $callbacks->{set} ) ) )
            {
                my $coderef;
                foreach my $t ( qw( add set ) )
                {
                    if( CORE::exists( $callbacks->{ $t } ) )
                    {
                        $coderef = ref( $callbacks->{ $t } ) eq 'CODE'
                            ? $callbacks->{ $t }
                            : $self->can( $callbacks->{ $t } );
                        last if( defined( $coderef ) );
                    }
                }
                if( defined( $coderef ) && ref( $coderef ) eq 'CODE' )
                {
                    $coderef->( $self, $data->{ $field } );
                }
            }
            return( $data->{ $field } );
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_scalar_as_object : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;

    my $callbacks = {};
    my $def = {};
    if( ref( $field ) eq 'HASH' )
    {
        $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        $callbacks = $def->{callbacks} if( CORE::exists( $def->{callbacks} ) && ref( $def->{callbacks} ) eq 'HASH' );
    }

    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            my $ctx = $_;
            if( !$self->_is_object( $data->{ $field } ) || ( $self->_is_object( $data->{ $field } ) && ref( $data->{ $field } ) ne ref( $self ) ) )
            {
                require Module::Generic::Scalar;
                $data->{ $field } = Module::Generic::Scalar->new( $data->{ $field } );
            }
            my $v = $data->{ $field };
            # If we have a callback, call it and get the resulting value
            if( scalar( keys( %$callbacks ) ) && 
                CORE::exists( $callbacks->{get} ) &&
                ref( $callbacks->{get} ) eq 'CODE' )
            {
                $v = $callbacks->{get}->( $self, $v );
            }
            
            if( !CORE::defined( $v ) || !$v->defined )
            {
                # We might have need to specify, because I found a race condition where
                # even though the context is object, once in Null, the context became 'code'
                # return( Module::Generic::Null->new( wants => 'OBJECT' ) );
                if( $ctx->{object} && CORE::defined( $v ) )
                {
                    return( $v );
                }
                else
                {
                    return;
                }
            }
            else
            {
                return( $v );
            }
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            my $ctx = $_;
            my $val;
            if( ref( $arg ) eq 'SCALAR' || 
                UNIVERSAL::isa( $arg, 'SCALAR' ) )
            {
                $val = $$arg;
            }
            elsif( ref( $arg ) && 
                   $self->_is_object( $arg ) && 
                   overload::Overloaded( $arg ) && 
                   overload::Method( $arg, '""' ) )
            {
                $val = "$arg";
            }
            elsif( ref( $arg ) )
            {
                return( $self->error( "I was expecting a string or a scalar reference, but instead got '$arg'" ) );
            }
            else
            {
                $val = $arg;
            }

            my $o = $data->{ $field };
            if( ref( $o ) )
            {
                $o->set( $val );
            }
            else
            {
                require Module::Generic::Scalar;
                $data->{ $field } = Module::Generic::Scalar->new( $val );
            }
            
            if( scalar( keys( %$callbacks ) ) && 
                ( CORE::exists( $callbacks->{add} ) || CORE::exists( $callbacks->{set} ) ) )
            {
                my $coderef;
                foreach my $t ( qw( add set ) )
                {
                    if( CORE::exists( $callbacks->{ $t } ) )
                    {
                        $coderef = ref( $callbacks->{ $t } ) eq 'CODE'
                            ? $callbacks->{ $t }
                            : $self->can( $callbacks->{ $t } );
                        last if( defined( $coderef ) );
                    }
                }
                if( defined( $coderef ) && ref( $coderef ) eq 'CODE' )
                {
                    $coderef->( $self, $data->{ $field } );
                }
            }
            
            if( !$self->_is_object( $data->{ $field } ) || ( $self->_is_object( $data->{ $field } ) && ref( $data->{ $field } ) ne ref( $self ) ) )
            {
                require Module::Generic::Scalar;
                $data->{ $field } = Module::Generic::Scalar->new( $data->{ $field } );
            }
            my $v = $data->{ $field };
            if( !$v->defined )
            {
                # We might have need to specify, because I found a race condition where
                # even though the context is object, once in Null, the context became 'code'
                # return( Module::Generic::Null->new( wants => 'OBJECT' ) );
                if( $ctx->{object} )
                {
                    return( $v );
                }
                else
                {
                    return;
                }
            }
            else
            {
                return( $v );
            }
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_scalar_or_object
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $class = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    if( @_ )
    {
        if( ref( $_[0] ) eq 'HASH' || Scalar::Util::blessed( $_[0] ) )
        {
            return( $self->_set_get_object( $field, $class, @_ ) );
        }
        else
        {
            return( $self->_set_get_scalar( $field, @_ ) );
        }
    }
    if( !$data->{ $field } && want( 'OBJECT' ) )
    {
        require Module::Generic::Null;
        my $null = Module::Generic::Null->new({ debug => $this->{debug}, has_error => 1 });
        rreturn( $null );
    }
    return( $data->{ $field } );
}

sub _set_get_uri : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;

    my $uri_class = 'URI';
    if( ref( $field ) eq 'HASH' )
    {
        my $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        $uri_class = $def->{class} if( CORE::exists( $def->{class} ) && ref( $def->{class} ) eq 'HASH' );
    }
    
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            $self->_load_class( $uri_class ) || return( $self->pass_error );
            # Data was pre-set or directly set but is not an URI object, so we convert it now
            if( $data->{ $field } && !$self->_is_a( $data->{ $field }, $uri_class ) )
            {
                # Force stringification if this is an overloaded value
                $data->{ $field } = $uri_class->new( $data->{ $field } . '' );
            }
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            $self->_load_class( $uri_class ) || return( $self->pass_error );
            my $str = $arg;
            if( Scalar::Util::blessed( $str ) && $str->isa( $uri_class ) )
            {
                $data->{ $field } = $str;
            }
            elsif( defined( $str ) && ( $str =~ /^[a-zA-Z]+:\/{2}/ || $str =~ /^urn\:[a-z]+\:/ || $str =~ /^[a-z]+\:/ ) )
            {
                $data->{ $field } = $uri_class->new( $str );
                warn( "$uri_class subclass is missing to handle this specific URI '$str'\n" ) if( !$data->{ $field }->has_recognized_scheme );
            }
            # Is it an absolute path?
            elsif( substr( $str, 0, 1 ) eq '/' )
            {
                $data->{ $field } = $uri_class->new( $str );
            }
            elsif( defined( $str ) )
            {
                # try-catch
                local $@;
                eval
                {
                    die( "Cannot use a reference as an URI. Received '$str'" ) if( ref( $str ) && !$self->_is_object( $str ) );
                    my $u = $uri_class->new( $str );
                    $data->{ $field } = $u;
                };
                if( $@ )
                {
                    return( $self->error( "URI value provided '$str' does not look like an URI, so I do not know what to do with it: $@" ) );
                }
            }
            else
            {
                $data->{ $field } = undef();
            }
            
            # Data was pre-set or directly set but is not an URI object, so we convert it now
            if( $data->{ $field } && !$self->_is_a( $data->{ $field }, $uri_class ) )
            {
                # Force stringification if this is an overloaded value
                $data->{ $field } = $uri_class->new( $data->{ $field } . '' );
            }
            return( $data->{ $field } );
        },
        field => $field,
    }, @_ ) );
}

# Universally Unique Identifier
sub _set_get_uuid : lvalue
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;

    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            my $v = $self->_is_a( $data->{ $field }, 'Module::Generic::Scalar' )
                ? $data->{ $field }
                : $self->new_scalar( $data->{ $field } );
            if( !$v->defined )
            {
                return;
            }
            else
            {
                return( $v );
            }
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            my $v = $arg;
            # If the user wants to remove it
            if( !defined( $v ) )
            {
                $data->{ $field } = $v;
            }
            # If the user provided a string, let's check it
            elsif( length( $v ) && !$self->_is_uuid( $v ) )
            {
                return( $self->error( "Value provided is not a valid uuid." ) );
            }
            $v = $data->{ $field } = $self->new_scalar( $v );
            if( !$v->defined )
            {
                return;
            }
            else
            {
                return( $v );
            }
        },
        field => $field,
    }, @_ ) );
}

sub _set_get_version : lvalue
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;

    my $version_class = 'version';
    if( ref( $field ) eq 'HASH' )
    {
        my $def = $field;
        if( CORE::exists( $def->{field} ) && 
            defined( $def->{field} ) && 
            CORE::length( $def->{field} ) )
        {
            $field = $def->{field};
        }
        else
        {
            $field = undef;
        }
        $version_class = $def->{class} if( CORE::exists( $def->{class} ) );
    }
    
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            $self->_load_class( $version_class ) || return( $self->pass_error );
            if( !CORE::defined( $data->{ $field } ) )
            {
                return;
            }
            else
            {
                my $v = $data->{ $field };
                if( CORE::length( "$v" ) &&
                    !$self->_is_a( $v => $version_class ) )
                {
                    # try-catch
                    local $@;
                    eval
                    {
                        $v = $version_class->can( 'parse' ) ? $version_class->parse( "$v" ) : $version_class->new( "$v" );
                    };
                    if( $@ )
                    {
                        warn( "Value set for property '${field}' is not a valid version: $@\n" );
                    }
                }
                return( $v );
            }
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            return( $self->error( "No field name was provided." ) ) if( !defined( $field ) );
            $self->_load_class( $version_class ) || return( $self->pass_error );
            my $v = $arg;
            my $version;
            # If the user wants to remove it
            if( !defined( $v ) )
            {
                $data->{ $field } = $v;
            }
            elsif( $self->_is_a( $v => $version_class ) )
            {
                $version = $v;
            }
            # If the user provided a string, let's check it
            elsif( length( $v ) )
            {
                my $error;
                if( $v !~ /^$VERSION_LAX_REGEX$/ )
                {
                    $error = "Value provided is not a valid version.";
                }
                else
                {
                    # try-catch
                    local $@;
                    eval
                    {
                        $version = $version_class->can( 'parse' ) ? $version_class->parse( "$v" ) : $version_class->new( "$v" );
                    };
                    if( $@ )
                    {
                        $error = "Value provided is not a valid version: $@";
                    }
                }
                return( $self->error( $error ) ) if( defined( $error ) );
            }
            $data->{ $field } = $version;
            
            if( !CORE::defined( $data->{ $field } ) )
            {
                return;
            }
            else
            {
                my $v = $data->{ $field };
                if( CORE::length( "$v" ) &&
                    !$self->_is_a( $v => $version_class ) )
                {
                    # try-catch
                    local $@;
                    eval
                    {
                        $v = $version_class->can( 'parse' ) ? $version_class->parse( "$v" ) : $version_class->new( "$v" );
                    };
                    if( $@ )
                    {
                        warn( "Value set for property '${field}' is not a valid version: $@\n" );
                    }
                }
                return( $v );
            }
        },
        field => $field,
    }, @_ ) );
}

sub _to_array_object
{
    my $self = shift( @_ );
    my $data = scalar( @_ ) == 1 && $self->_is_array( $_[0] ) 
        ? shift( @_ ) 
        : ( scalar( @_ ) == 0 || ( scalar( @_ ) == 1 && !defined( $_[0] ) ) )
            ? [] 
            : [ @_ ];
    return( $self->new_array( $data ) );
}

# $self->_warnings_is_enabled()
# $self->_warnings_is_enabled( $other_object );
sub _warnings_is_enabled
{
    my $self = shift( @_ );
    # I hate dying, but here this is a show-stopper
    die( "Object provided is undef!\n" ) if( @_ && !defined( $_[0] ) );
    my $obj = @_ ? shift( @_ ) : $self;
    return(0) if( !$self->_warnings_is_registered( $obj ) );
    return( warnings::enabled( ref( $obj ) || $obj ) );
}

sub _warnings_is_registered
{
    my $self = shift( @_ );
    # I hate dying, but here this is a show-stopper
    die( "Object provided is undef!\n" ) if( @_ && !defined( $_[0] ) );
    my $obj = @_ ? shift( @_ ) : $self;
    return(1) if( defined( $warnings::Bits{ ref( $obj ) || $obj } ) );
    return(0);
}

sub _autoload_subs
{
    $AUTOLOAD_SUBS = 
    {
    # NOTE: as_hash()
    as_hash => <<'PERL',
sub as_hash
{
    my $self = shift( @_ );
    my $p = $self->_get_args_as_hash( @_ );
    # $p = shift( @_ ) if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' );
    $p->{convert_array} //= 1;
    my $me = $self->_obj2h;
    my $seen = $p->{seen} || {};
    my $levels = $p->{levels} || [];
    my $keys = $p->{fields} || [];

    my $added_subs = CORE::exists( $me->{_added_method} ) && ref( $me->{_added_method} ) eq 'HASH'
        ? $me->{_added_method}
        : {};
    
    my $crawl;
    $crawl = sub
    {
        my $this = shift( @_ );
        my $rval = ref( $this ) ? $this : \$this;
        my( $dataref, $class, $type, $id );
        my $strval = $dataref = overload::StrVal( $rval // 'undef' );
        # Parse $strval without using regexps, in order not to clobber $1, $2,...
        if( ( my $i = rindex( $dataref, '=' ) ) >= 0 )
        {
            $class = substr( $dataref, 0, $i );
            $dataref = substr( $dataref, $i + 1 );
        }
        if( ( my $i = index( $dataref, "(0x" ) ) >= 0 )
        {
            $type = substr( $dataref, 0, $i );
            $id = substr( $dataref, $i + 2, -1 );
        }
        
        my $levels = shift( @_ );
        my $prefix = join( '->', @$levels ) . ':';
        
        if( defined( $class ) )
        {
            if( $class eq 'JSON::PP::Boolean' ||
                $class eq 'Module::Generic::Boolean' )
            {
                return( $$this ? 1 : 0 );
            }
            # NOTE: Not sure why I did this, because as_hash is about converting into hash, not stringifying everything
            # elsif( $this->can( 'as_hash' ) && 
            #     overload::Overloaded( $this ) && 
            #     overload::Method( $this, '""' ) )
            # {
            #     return( $this . '' );
            # }
            elsif( $this->can( 'as_hash' ) )
            {
                if( $self->_is_array( $this ) && !$p->{convert_array} )
                {
                    return( $this );
                }
                elsif( ++$seen->{ Scalar::Util::refaddr( $this ) } < 2 )
                {
                    my $old_debug;
                    $old_debug = $this->debug if( $this->can( 'debug' ) );
                    my $rv = $this->as_hash( { %$p, seen => $seen, levels => $levels } );
                    $this->debug( $old_debug ) if( defined( $old_debug ) );
                    
                    if( Scalar::Util::blessed( $rv ) )
                    {
                        return( $crawl->( $rv, [@$levels, $strval] ) );
                    }
                    else
                    {
                        return( $rv );
                    }
                }
                else
                {
                    return( $this );
                }
            }
            # If the object can be overloaded, and has no TO_JSON method we get its string representation here.
            # If it has a TO_JSON and we are asked to return data for json, we let the JSON module call the TO_JSON method
            # NOTE: Not sure why I did this, because as_hash is about converting into hash, not stringifying everything
            # elsif( overload::Overloaded( $this ) && 
            #     overload::Method( $this, '""' ) )
            # {
            #     if( $p->{json} && $this->can( 'TO_JSON' ) )
            #     {
            #         return( $this );
            #     }
            #     else
            #     {
            #         return( "$this" );
            #     }
            # }
            else
            {
                return( $this );
            }
        }
        elsif( $type eq 'HASH' )
        {
            my $hash = {};
            foreach my $k ( keys( %$this ) )
            {
                if( ref( $this->{ $k } ) )
                {
                    if( ++$seen->{ Scalar::Util::refaddr( $this->{ $k } ) } > 1 )
                    {
                        next;
                    }
                }
                my $rv = $crawl->( $this->{ $k }, [@$levels, $k] );
                $hash->{ $k } = $rv;
            }
            return( $hash );
        }
        elsif( $type eq 'ARRAY' )
        {
            my $array = [];
            for( my $i = 0; $i < scalar( @$this ); $i++ )
            {
                if( ref( $this->[$i] ) )
                {
                    if( ++$seen->{ Scalar::Util::refaddr( $this->[$i] ) } > 1 )
                    {
                        next;
                    }
                }
                my $rv = $crawl->( $this->[$i], [@$levels, "[$i]"] );
                push( @$array, $rv );
            }
            return( $array );
        }
        elsif( !ref( $this ) )
        {
            defined( $this )
                ? return( $this )
                : return;
        }
        elsif( $type eq 'SCALAR' )
        {
            my $str = $$this;
            return( \$str );
        }
        elsif( $type eq 'CODE' )
        {
            return( $this );
        }
        elsif( $type eq 'GLOB' )
        {
            return( $this );
        }
        elsif( $type eq 'VSTRING' )
        {
            return( $this );
        }
        else
        {
            die( "$prefix: Unknown reference ", overload::StrVal( $this // 'undef' ), " with value $this" );
        }
    };
    
    my $ref = {};
    my @keys = ();
    if( $self->_is_array( $keys ) && scalar( @$keys ) )
    {
        @keys = @$keys;
    }
    else
    {
        @keys = grep( !/^(debug|verbose)$/, keys( %$me ) );
        push( @keys, 'debug' ) if( $self->_has_symbol( 'debug' ) );
        push( @keys, 'verbose' ) if( $self->_has_symbol( 'verbose' ) );
    }
    foreach my $k ( @keys )
    {
        next if( substr( $k, 0, 1 ) eq '_' );
        next if( CORE::exists( $added_subs->{ $k } ) );
        my $rv = $crawl->( $me->{ $k }, [@$levels, $k] );
        next if( !defined( $rv ) );
        $ref->{ $k } = $rv;
    }
    return( $ref );
}
PERL
    # NOTE: clear()
    clear => <<'PERL',
sub clear
{
    return( shift->clear_error );
}
PERL
    # NOTE: clear_error()
    clear_error => <<'PERL',
sub clear_error
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    no strict 'refs';
    $this->{error} = ${ "$class\::ERROR" } = '';
    return( $self );
}
PERL
    # NOTE: clone()
    clone => <<'PERL',
sub clone
{
    my $self = shift( @_ );
    my $new;
    # try-catch
    local $@;
    eval
    {
        if( $self->_is_object( $self ) )
        {
            $new = Clone::clone( $self );
        }
        else
        {
            $new = $self->new;
        }
    };
    if( $@ )
    {
        return( $self->error( "Error cloning object \"", overload::StrVal( $self // 'undef' ), "\": $@" ) );
    }
    return( $new );
}
PERL
    # NOTE: colour_close()
    colour_close => <<'PERL',
sub colour_close { return( shift->_set_get( '_colour_close', @_ ) ); }
PERL
    # NOTE: colour_closest()
    colour_closest => <<'PERL',
sub colour_closest
{
    my $self    = shift( @_ );
    my $colour  = uc( shift( @_ ) );
    my $this  = $self->_obj2h;
    my $colours = 
    {
    '000000000' => 'black',
    '000000255' => 'blue',
    '000255000' => 'green',
    '000255255' => 'cyan',
    '255000000' => 'red',
    '255000255' => 'magenta',
    '255255000' => 'yellow',
    '255255255' => 'white',
    };
    my( $red, $green, $blue ) = ( '', '', '' );
    our $COLOUR_NAME_TO_RGB;
    if( $colour =~ /^[A-Z]+([A-Z\s]+)*$/ )
    {
        if( !scalar( keys( %$COLOUR_NAME_TO_RGB ) ) )
        {
            my $colour_data = $self->__colour_data;
            local $@;
            $COLOUR_NAME_TO_RGB = eval( $colour_data );
            if( $@ )
            {
                return( $self->error( "An error occurred loading data from __colour_data: $@" ) );
            }
        }
        if( CORE::exists( $COLOUR_NAME_TO_RGB->{ lc( $colour ) } ) )
        {
            ( $red, $green, $blue ) = @{$COLOUR_NAME_TO_RGB->{ lc( $colour ) }};
        }
    }
    # Colour all in decimal??
    elsif( $colour =~ /^\d{9}$/ )
    {
        $red   = substr( $colour, 0, 3 );
        $green = substr( $colour, 3, 3 );
        $blue  = substr( $colour, 6, 3 );
    }
    # Colour in hexadecimal, convert it
    elsif( $colour =~ /^[A-F0-9]+$/ )
    {
        $red   = hex( substr( $colour, 0, 2 ) );
        $green = hex( substr( $colour, 2, 2 ) );
        $blue  = hex( substr( $colour, 4, 2 ) );
    }
    # Clueless
    else
    {
        # Not undef, but rather empty string. Undef is associated with an error
        return( '' );
    }
    my $dec_colour = CORE::sprintf( '%3d%3d%3d', $red, $green, $blue );
    my $last = '';
    my @colours = reverse( sort( keys( %$colours ) ) );
    $red    = CORE::sprintf( '%03d', $red );
    $green  = CORE::sprintf( '%03d', $green );
    $blue   = CORE::sprintf( '%03d', $blue );
    my $cur = CORE::sprintf( '%03d%03d%03d', $red, $green, $blue );
    my( $red_ok, $green_ok, $blue_ok ) = ( 0, 0, 0 );
    for( my $i = 0; $i < scalar( @colours ); $i++ )
    {
        my $r = CORE::sprintf( '%03d', substr( $colours[ $i ], 0, 3 ) );
        my $g = CORE::sprintf( '%03d', substr( $colours[ $i ], 3, 3 ) );
        my $b = CORE::sprintf( '%03d', substr( $colours[ $i ], 6, 3 ) );
 
        my $r_p = CORE::sprintf( '%03d', substr( $colours[ $i - 1 ], 0, 3 ) );
        my $g_p = CORE::sprintf( '%03d', substr( $colours[ $i - 1 ], 3, 3 ) );
        my $b_p = CORE::sprintf( '%03d', substr( $colours[ $i - 1 ], 6, 3 ) );
 
        if( $red == $r ||
            ( $red < $r && $red > int( $r / 2 ) ) ||
            ( $red > $r && $red < int( $r_p / 2 ) && $r_p ) ||
            $red > $r )
        {
            $red_ok++;
        }
 
        if( $red_ok )
        {
            if( $green == $g ||
                ( $green < $g && $green > int( $g / 2 ) ) ||
                ( $green > $g && $green < int( $g_p / 2 ) && $g_p ) ||
                $green > $g )
            {
                $blue_ok++;
            }
        } 
 
        if( $blue_ok )
        {
            if( $blue == $b ||
                ( $blue < $b && $blue > int( $b / 2 ) ) ||
                ( $blue > $b && $blue < int( $b_p / 2 ) && $b_p ) ||
                $blue > $b )
            {
                $last = $colours[ $i ];
                last;
            }
        }
    }
    return( $colours->{ $last } );
}
PERL
    # NOTE: colour_format()
    colour_format => <<'PERL',
sub colour_format
{
    my $self = shift( @_ );
    # style, colour or color and text
    my $opts = shift( @_ );
    return( $self->error( "Parameter hash provided is not an hash reference." ) ) if( !$self->_is_hash( $opts ) );
    my $this = $self->_obj2h;
    # To make it possible to use either text or message property
    $opts->{text} = CORE::delete( $opts->{message} ) if( CORE::length( $opts->{message} ) && !CORE::length( $opts->{text} ) );
    return( $self->error( "No text was provided to format." ) ) if( !CORE::length( $opts->{text} ) );
    
    $opts->{colour} //= CORE::delete( $opts->{color} ) || CORE::delete( $opts->{fg_colour} ) || CORE::delete( $opts->{fg_color} ) || CORE::delete( $opts->{fgcolour} ) || CORE::delete( $opts->{fgcolor} );
    $opts->{bgcolour} //= CORE::delete( $opts->{bgcolor} ) || CORE::delete( $opts->{bg_colour} ) || CORE::delete( $opts->{bg_color} );
    
    my $bold      = "\e[1m";
    my $underline = "\e[4m";
    my $reverse   = "\e[7m";
    my $normal    = "\e[m";
    my $cls       = "\e[H\e[2J";
    my $styles =
    {
    # Bold
    b       => 1,
    bold    => 1,
    strong  => 1,
    # Italic
    i       => 3,
    italic  => 3,
    # Underline
    u       => 4,
    underline => 4,
    underlined => 4,
    blink   => 5,
    # Reverse
    r       => 7,
    reverse => 7,
    reversed => 7,
    # Concealed
    c       => 8,
    conceal => 8,
    concealed => 8,
    strike  => 9,
    striked  => 9,
    striken  => 9,
    };
    
    my $convert_24_To_8bits = sub
    {
        my( $r, $g, $b ) = @_;
        return( ( POSIX::floor( $r * 7 / 255 ) << 5 ) +
                ( POSIX::floor( $g * 7 / 255 ) << 2 ) +
                ( POSIX::floor( $b * 3 / 255 ) ) 
              );
    };
    
    # opacity * original + (1-opacity)*background = resulting pixel
    # https://stackoverflow.com/a/746934/4814971
    my $colour_with_alpha = sub
    {
        my( $r, $g, $b, $a, $bg ) = @_;
        ## Assuming a white background (255)
        my( $bg_r, $bg_g, $bg_b ) = ( 255, 255, 255 );
        if( ref( $bg ) eq 'HASH' )
        {
            ( $bg_r, $bg_g, $bg_b ) = @$bg{qw( red green blue )};
        }
        $r = POSIX::round( ( $a * $r ) + ( ( 1 - $a ) * $bg_r ) );
        $g = POSIX::round( ( $a * $g ) + ( ( 1 - $a ) * $bg_g ) );
        $b = POSIX::round( ( $a * $b ) + ( ( 1 - $a ) * $bg_b ) );
        return( [$r, $g, $b] );
    };
    
    my $check_colour = sub
    {
        my $col = shift( @_ );
        # $colours or $bg_colours
        my $map = shift( @_ );
        my $code;
        my $light;
        # Example: 'light red' or 'light_red'
        if( $col =~ /^(?:(?<light>bright|light)[[:blank:]\_]+)?
        (?<colour>
            (?:[a-zA-Z]+)(?:[[:blank:]]+\w+)?
            |
            (?<rgb_type>rgb[a]?)\([[:blank:]]*(?<red>\d{1,3})[[:blank:]]*\,[[:blank:]]*(?<green>\d{1,3})[[:blank:]]*\,[[:blank:]]*(?<blue>\d{1,3})
            (?:[[:blank:]]*\,[[:blank:]]*(?<opacity>\d(?:\.\d+)?))?[[:blank:]]*
            \)
        )$/xi )
        {
            my %regexp = %+;
            ( $light, $col ) = ( $+{light}, $+{colour} );
            if( CORE::length( $+{rgb_type} ) &&
                CORE::length( $+{red} ) &&
                CORE::length( $+{green} ) &&
                CORE::length( $+{blue} ) )
            {
                if( $+{opacity} || $light )
                {
                    my $opacity = CORE::length( $+{opacity} )
                        ? $+{opacity}
                        : $light
                            ? 0.5
                            : 1;
                    $col = CORE::sprintf( 'rgba(%03d%03d%03d,%.1f)', $+{red}, $+{green}, $+{blue}, $opacity );
                }
                else
                {
                    $col = CORE::sprintf( 'rgb(%03d%03d%03d)', $+{red}, $+{green}, $+{blue} );
                }
            }
            else
            {
            }
        }
        elsif( $col =~ /^(?<rgb_type>rgb[a]?)\([[:blank:]]*(?<red>\d{1,3})[[:blank:]]*\,[[:blank:]]*(?<green>\d{1,3})[[:blank:]]*\,[[:blank:]]*(?<blue>\d{1,3})[[:blank:]]*(?:\,[[:blank:]]*(?<opacity>\d(?:\.\d+)?))?[[:blank:]]*\)$/i )
        {
            if( $+{opacity} )
            {
                $col = CORE::sprintf( 'rgba(%03d%03d%03d,%.1f)', $+{red}, $+{green}, $+{blue}, $+{opacity} );
            }
            else
            {
                $col = CORE::sprintf( '%03d%03d%03d', $+{red}, $+{green}, $+{blue} );
            }
        }
        else
        {
        }
        
        my $col_ref;
        if( $col =~ /^rgb[a]?\((?<red>\d{3})(?<green>\d{3})(?<blue>\d{3})\)$/i )
        {
            $col_ref = {};
            %$col_ref = %+;
            return({
                _24bits => [@$col_ref{qw( red green blue )}],
                _8bits => $convert_24_To_8bits->( @$col_ref{qw( red green blue )} )
            });
        }
        # Treating opacity to make things lighter; not ideal, but standard scheme
        elsif( $col =~ /^rgba\((?<red>\d{3})(?<green>\d{3})(?<blue>\d{3})[[:blank:]]*\,[[:blank:]]*(?<opacity>\d(?:\.\d)?)\)$/i )
        {
            $col_ref = {};
            %$col_ref = %+;
            if( $+{opacity} )
            {
                my $opacity = $+{opacity};
                my $bg;
                if( $opts->{bgcolour} )
                {
                    $bg = $self->colour_to_rgb( $opts->{bgcolour} );
                }
                my $new_col = $colour_with_alpha->( @$col_ref{qw( red green blue )}, $opacity, $bg );
                @$col_ref{qw( red green blue )} = @$new_col;
            }
            return({
                _24bits => [@$col_ref{qw( red green blue )}],
                _8bits => $convert_24_To_8bits->( @$col_ref{qw( red green blue )} )
            });
        }
        elsif( $self->_message( 9, "Checking if rgb value exists for colour '$col'" ) &&
               ( $col_ref = $self->colour_to_rgb( $col ) ) )
        {
            # $code = $map->{ $col };
            return({
                _24bits => [@$col_ref{qw( red green blue )}],
                _8bits => $convert_24_To_8bits->( @$col_ref{qw( red green blue )} )
            });
        }
        else
        {
            return( {} );
        }
#         my $is_bg = ( CORE::substr( $code, 0, 1 ) == 4 );
#         if( CORE::length( $code ) && $light )
#         {
#             ## If the colour is a background colour, replace 4 by 10 (e.g.: 42 becomes 103)
#             ## and if foreground colour, replace 3 by 9
#             CORE::substr( $code, 0, 1 ) = ( $is_bg ? 10 : 9 );
#         }
#         return( $code );
    };
    my $data = [];
    my $data8 = [];
    my $params = [];
    # 8 bits parameters compatible
    my $params8 = [];
    if( $opts->{colour} || $opts->{color} || $opts->{fgcolour} || $opts->{fgcolor} || $opts->{fg_colour} || $opts->{fg_color} )
    {
        $opts->{colour} ||= CORE::delete( $opts->{color} ) || CORE::delete( $opts->{fg_colour} ) || CORE::delete( $opts->{fg_color} ) || CORE::delete( $opts->{fgcolour} ) || CORE::delete( $opts->{fgcolor} );
        # my $col_ref = $check_colour->( $opts->{colour}, $colours );
        my $col_ref = $check_colour->( $opts->{colour} );
        # CORE::push( @$params, $col ) if( CORE::length( $col ) );
        if( scalar( keys( %$col_ref ) ) )
        {
            CORE::push( @$params8, sprintf( '38;5;%d', $col_ref->{_8bits} ) );
            CORE::push( @$params, sprintf( '38;2;%d;%d;%d', @{$col_ref->{_24bits}} ) );
        }
        else
        {
        }
    }
    if( $opts->{bgcolour} || $opts->{bgcolor} || $opts->{bg_colour} || $opts->{bg_color} )
    {
        $opts->{bgcolour} ||= CORE::delete( $opts->{bgcolor} ) || CORE::delete( $opts->{bg_colour} ) || CORE::delete( $opts->{bg_color} );
        # my $col_ref = $check_colour->( $opts->{bgcolour}, $bg_colours );
        my $col_ref = $check_colour->( $opts->{bgcolour} );
        ## CORE::push( @$params, $col ) if( CORE::length( $col ) );
        if( scalar( keys( %$col_ref ) ) )
        {
            CORE::push( @$params8, sprintf( '48;5;%d', $col_ref->{_8bits} ) );
            CORE::push( @$params, sprintf( '48;2;%d;%d;%d', @{$col_ref->{_24bits}} ) );
        }
        else
        {
        }
    }
    if( $opts->{style} )
    {
        my $those_styles = [CORE::split( /\|/, $opts->{style} )];
        foreach my $s ( @$those_styles )
        {
            if( CORE::exists( $styles->{lc($s)} ) )
            {
                CORE::push( @$params, $styles->{lc($s)} );
                # We add the 8 bits compliant version only if any colour was provided, i.e.
                # This is not just a style definition
                CORE::push( @$params8, $styles->{lc($s)} ) if( scalar( @$params8 ) );
            }
        }
    }
    CORE::push( @$data, "\e[" . CORE::join( ';', @$params8 ) . "m" ) if( scalar( @$params8 ) );
    CORE::push( @$data, "\e[" . CORE::join( ';', @$params ) . "m" ) if( scalar( @$params ) );
    # If the text contains libe breaks, we must stop the formatting before, or else there would be an ugly formatting on the entire screen following the line break
    if( scalar( @$params ) && $opts->{text} =~ /\n+/ )
    {
        my $text_parts = [CORE::split( /\n/, $opts->{text} )];
        my $fmt = CORE::join( '', @$data );
        my $fmt8 = CORE::join( '', @$data8 );
        for( my $i = 0; $i < scalar( @$text_parts ); $i++ )
        {
            # Empty due to \n repeated
            next if( !CORE::length( $text_parts->[$i] ) );
            $text_parts->[$i] = $fmt . $text_parts->[$i] . $normal;
        }
        $opts->{text} = CORE::join( "\n", @$text_parts );
        CORE::push( @$data, $opts->{text} );
    }
    else
    {
        CORE::push( @$data, $opts->{text} );
        CORE::push( @$data, $normal, $normal ) if( scalar( @$params ) );
    }
    return( CORE::join( '', @$data ) );
}
PERL
    # NOTE: colour_open()
    colour_open => <<'PERL',
sub colour_open { return( shift->_set_get( '_colour_open', @_ ) ); }
PERL
    # NOTE: colour_parse()
    colour_parse => <<'PERL',
sub colour_parse
{
    my $self = shift( @_ );
    my $txt  = join( '', @_ );
    my $this  = $self->_obj2h;
    my @opens = ( '{', '<' );
    my @closes = ( '}', '>' );
    my $cust_open = $self->colour_open;
    my $cust_close = $self->colour_close;
    if( defined( $cust_open ) &&
        length( $cust_open ) &&
        !scalar( grep( /^\Q$cust_open\E$/, @opens ) ) )
    {
        push( @opens, $cust_open );
    }
    if( defined( $cust_close ) &&
        length( $cust_close ) &&
        !scalar( grep( /^\Q$cust_close\E$/, @closes ) ) )
    {
        push( @closes, $cust_close );
    }
    my $open = join( '|', @opens );
    my $close = join( '|', @closes );
    my $is_tty = $self->_is_tty;
    no strict;
    my $re = qr/
(?<all>
(?<open>$open)(?!\/)(?<params>.*?)(?<close>$close)
    (?<content>
        (?:
            (?> [^$open|$close]+ )
            |
            (?R)
        )*+
    )
\g{open}\/\g{close}
)
    /x;
    my $colour_re = qr/(?:(?:bright|light)[[:blank:]])?(?:[a-zA-Z]+(?:[[:blank:]]+[\w\-]+)?|rgb[a]?\([[:blank:]]*\d{1,3}[[:blank:]]*\,[[:blank:]]*\d{1,3}[[:blank:]]*\,[[:blank:]]*\d{1,3}[[:blank:]]*(?:\,[[:blank:]]*\d(?:\.\d)?)?[[:blank:]]*\))/;
    my $style_re = qr/(?:bold|faint|italic|underline|blink|reverse|conceal|strike)/;
    my $parse;
    $parse = sub
    {
        my $str = shift( @_ );
        1 while( $str =~ s{$re}
        {
            my $re = { %- };
            my $catch = substr( $str, $-[0], $+[0] - $-[0] );
            my $all = $+{all};
            my $ct = $+{content};
            # Are we connected to a tty ?
            if( !$is_tty )
            {
                # Return the content without formatting then
                $ct;
            }
            else
            {
                my $params = $+{params};
                if( index( $ct, $open ) != -1 && index( $ct, $close ) != -1 )
                {
                    $ct = $parse->( $ct );
                }
                my $def = {};
                if( $params =~ /^[[:blank:]]*(?:(?<style1>$style_re)[[:blank:]]+)?(?<fg_colour>$colour_re)(?:[[:blank:]]+(?<style2>$style_re))?(?:[[:blank:]]+on[[:blank:]]+(?<bg_colour>$colour_re))?[[:blank:]]*$/i )
                {
                    my $style = $+{style1} || $+{style2};
                    my $fg = $+{fg_colour};
                    my $bg = $+{bg_colour};
                    $def = 
                    {
                    style => $style,
                    colour => $fg,
                    bg_colour => $bg,
                    };
                }
                else
                {
                    local $SIG{__WARN__} = sub{};
                    local $SIG{__DIE__} = sub{};
                    local $@;
                    my @res = eval( $params );
                    $def = { @res } if( scalar( @res ) && !( scalar( @res ) % 2 ) );
                    if( $@ || ref( $def ) ne 'HASH' )
                    {
                        my $err = $@ || "Invalid styling \"${params}\"";
                        $def = {};
                    }
                }

                if( scalar( keys( %$def ) ) )
                {
                    if( !defined( $ct ) || !CORE::length( $ct // '' ) )
                    {
                        '';
                    }
                    else
                    {
                        $def->{text} = $ct;
                        my $res = $self->colour_format( $def );
                        length( $res ) ? $res : $catch;
                    }
                }
                else
                {
                    $catch;
                }
            }
        }gex );
        return( $str );
    };
    return( $parse->( $txt ) );
}
PERL
    # NOTE: colour_to_rgb()
    colour_to_rgb => <<'PERL',
sub colour_to_rgb
{
    my $self    = shift( @_ );
    my $colour  = lc( shift( @_ ) );
    my $this  = $self->_obj2h;
    my( $red, $green, $blue ) = ( '', '', '' );
    our $COLOUR_NAME_TO_RGB;
    if( $colour =~ /^[A-Za-z]+([\w\-]+)*([[:blank:]]+\w+)?$/ )
    {
        if( !scalar( keys( %$COLOUR_NAME_TO_RGB ) ) )
        {
            my $colour_data = $self->__colour_data;
            local $@;
            $COLOUR_NAME_TO_RGB = eval( $colour_data );
            if( $@ )
            {
                return( $self->error( "An error occurred loading data from __colour_data: $@" ) );
            }
        }
        if( CORE::exists( $COLOUR_NAME_TO_RGB->{ $colour } ) )
        {
            ( $red, $green, $blue ) = @{$COLOUR_NAME_TO_RGB->{ $colour }};
        }
        else
        {
            return( '' );
        }
    }
    ## Colour all in decimal??
    elsif( $colour =~ /^\d{9}$/ )
    {
        $red   = substr( $colour, 0, 3 );
        $green = substr( $colour, 3, 3 );
        $blue  = substr( $colour, 6, 3 );
    }
    ## Colour in hexadecimal, convert it
    elsif( $colour =~ /^[A-F0-9]+$/ )
    {
        $red   = hex( substr( $colour, 0, 2 ) );
        $green = hex( substr( $colour, 2, 2 ) );
        $blue  = hex( substr( $colour, 4, 2 ) );
    }
    ## Clueless
    else
    {
        ## Not undef, but rather empty string. Undef is associated with an error
        return( '' );
    }
    return({ red => $red, green => $green, blue => $blue });
}
PERL
    # NOTE: coloured()
    coloured => <<'PERL',
sub coloured
{
    my $self = shift( @_ );
    my $pref = shift( @_ );
    my $text = CORE::join( '', @_ );
    my $this  = $self->_obj2h;
    my( $style, $fg, $bg );
    ## my $colour_re = qr/(?:(?:bright|light)[[:blank:]])?[a-zA-Z]+/;
    my $colour_re = qr/(?:(?:bright|light)[[:blank:]])?(?:[a-zA-Z]+(?:[[:blank:]]+[\w\-]+)?|rgb[a]?\([[:blank:]]*\d{1,3}[[:blank:]]*\,[[:blank:]]*\d{1,3}[[:blank:]]*\,[[:blank:]]*\d{1,3}[[:blank:]]*(?:\,[[:blank:]]*\d(?:\.\d)?)?[[:blank:]]*\))/;
    my $style_re = qr/(?:bold|faint|italic|underline|blink|reverse|conceal|strike)/;
    if( $pref =~ /^(?:(?<style1>$style_re)[[:blank:]]+)?(?<fg_colour>$colour_re)(?:[[:blank:]]+(?<style2>$style_re))?(?:[[:blank:]]+on[[:blank:]]+(?<bg_colour>$colour_re))?$/i )
    {
        $style = $+{style1} || $+{style2};
        $fg = $+{fg_colour};
        $bg = $+{bg_colour};
        return( $self->colour_format({ text => $text, style => $style, colour => $fg, bg_colour => $bg }) );
    }
    else
    {
        return( '' );
    }
}
PERL
    # NOTE: dump_hex()
    dump_hex => <<'PERL',
sub dump_hex
{
    my $self = shift( @_ );
    my $rv;
    # try-catch
    local $@;
    eval
    {
        require Devel::Hexdump;
        $rv = Devel::Hexdump::xd( shift( @_ ) );
    };
    if( $@ )
    {
        return( $self->error( "Devel::Hexdump is not installed on your system." ) );
    }
    return( $rv );
}
PERL
    # NOTE: dump_print()
    dump_print => <<'PERL',
# For backward compatibility and traceability
sub dump_print { return( shift->dumpto_printer( @_ ) ); }
PERL
    # NOTE: dumper()
    dumper => <<'PERL',
sub dumper
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' );
    my $rv;
    # try-catch
    local $@;
    eval
    {
        no warnings 'once';
        require Data::Dumper;
        # local $Data::Dumper::Sortkeys = 1;
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Maxdepth = $opts->{depth} if( CORE::length( $opts->{depth} ) );
        local $Data::Dumper::Sortkeys = sub
        {
            my $h = shift( @_ );
            return( [ sort( grep{ ref( $h->{ $_ } ) !~ /^(DateTime|DateTime\:\:)/ } keys( %$h ) ) ] );
        };
        $rv = Data::Dumper::Dumper( @_ );
    };
    if( $@ )
    {
        return( $self->error( "Data::Dumper is not installed on your system." ) );
    }
    return( $rv );
}
PERL
    # NOTE: dumpto_printer()
    dumpto_printer => <<'PERL',
sub dumpto_printer
{
    my $self  = shift( @_ );
    my( $data, $file ) = @_;
    require Module::Generic::File;
    $file = Module::Generic::File::file( $file );
    my $fh =  $file->open( '>', { binmode => 'utf-8', autoflush => 1 }) || 
        die( "Unable to create file '$file': $!\n" );
    $fh->print( Data::Dump::dump( $data ), "\n" );
    $fh->close;
    # 666 so it can work under command line and web alike
    chmod( 0666, $file );
    return(1);
}
PERL
    # NOTE: dumpto_dumper()
    dumpto_dumper => <<'PERL',
sub dumpto_dumper
{
    my $self  = shift( @_ );
    my( $data, $file ) = @_;
    my $rv;
    # try-catch
    local $@;
    eval
    {
        require Data::Dumper;
        local $Data::Dumper::Sortkeys = 1;
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Useqq = 1;
        require Module::Generic::File;
        $file = Module::Generic::File::file( $file );
        my $fh =  $file->open( '>', { autoflush => 1 }) || 
            die( "Unable to create file '$file': $!\n" );
        if( ref( $data ) )
        {
            $fh->print( Data::Dumper::Dumper( $data ), "\n" );
        }
        else
        {
            $fh->binmode( ':utf8' );
            $fh->print( $data );
        }
        $fh->close;
        # 666 so it can work under command line and web alike
        chmod( 0666, $file );
        $rv = 1;
    };
    if( $@ )
    {
        return( $self->error( "Unable to dump data to \"$file\" using Data::Dumper: $@" ) );
    }
    return( $rv );
}
PERL
    # NOTE: errno()
    errno => <<'PERL',
sub errno
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    if( @_ )
    {
        $this->{errno} = shift( @_ ) if( $_[ 0 ] =~ /^\-?\d+$/ );
        return( $self->error( @_ ) ) if( @_ );
    }
    return( $this->{errno} );
}
PERL
    # NOTE: message_colour()
    message_colour => <<'PERL',
sub message_colour
{
    my $self  = shift( @_ );
    my $this  = $self->_obj2h;
    my $opts = {};
    my $args = [@_];
    if( scalar( @$args ) > 1 && 
        ref( $args->[-1] ) eq 'HASH' && 
        (
            CORE::exists( $args->[-1]->{level} ) || 
            CORE::exists( $args->[-1]->{type} ) || 
            CORE::exists( $args->[-1]->{message} ) 
        ) )
    {
        $opts = pop( @$args );
    }
    $opts->{colour} = 1;
    return( $self->_message( @$args, $opts ) );
}
PERL
    # NOTE: messagef_colour()
    messagef_colour => <<'PERL',
sub messagef_colour
{
    my $self  = shift( @_ );
    my $this  = $self->_obj2h;
    my $opts = {};
    my $args = [@_];
    no strict 'refs';
    if( scalar( @$args ) > 1 && 
        ref( $args->[-1] ) eq 'HASH' && 
        (
            CORE::exists( $args->[-1]->{level} ) || 
            CORE::exists( $args->[-1]->{type} ) || 
            CORE::exists( $args->[-1]->{message} ) 
        ) )
    {
        $opts = pop( @$args );
    }
    $opts->{colour} = 1;
    return( $self->_messagef( @$args, $opts ) );
}
PERL
    # NOTE: printer()
    printer => <<'PERL',
sub printer
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' );
    my $rv;
    # try-catch
    local $@;
    eval
    {
        local $SIG{__WARN__} = sub{ };
        require Data::Printer;
        if( scalar( keys( %$opts ) ) )
        {
            $rv = Data::Printer::np( @_, %$opts );
        }
        else
        {
            $rv = Data::Printer::np( @_ );
        }
    };
    if( $@ )
    {
        return( $self->error( "Data::Printer is not installed on your system." ) );
    }
    return( $rv );
}
PERL
    # NOTE: save()
    save => <<'PERL',
sub save
{
    my $self = shift( @_ );
    my $this = $self->_obj2h;
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my( $file, $data );
    if( @_ == 2 )
    {
        $opts->{data} = shift( @_ );
        $opts->{file} = shift( @_ );
    }
    return( $self->error( "No file was provided to save data to." ) ) if( !$opts->{file} );
    require Module::Generic::File;
    $file = Module::Generic::File::file( $opts->{file} );
    my $fh = $file->open( '>', {
        ( $opts->{encoding} ? ( binmode => $opts->{encoding} ) : () ),
        autoflush => 1,
    }) ||
        return( $self->error( "Unable to open file \"$file\" in write mode: $!" ) );
    if( !defined( $fh->print( ref( $opts->{data} ) eq 'SCALAR' ? ${$opts->{data}} : $opts->{data} ) ) )
    {
        return( $self->error( "Unable to write data to file \"$file\": $!" ) )
    }
    $fh->close;
    my $bytes = -s( $opts->{file} );
    return( $bytes );
}
PERL
    # NOTE: subclasses()
    subclasses => <<'PERL',
sub subclasses
{
    my $self  = shift( @_ );
    my $that  = '';
    $that     = @_ ? shift( @_ ) : $self;
    my $base  = ref( $that ) || $that;
    $base  =~ s,::,/,g;
    $base .= '.pm';
    
    require IO::Dir;
    # remove '.pm'
    my $dir = substr( $INC{ $base }, 0, ( length( $INC{ $base } ) ) - 3 );
    
    my @packages = ();
    my $io = IO::Dir->open( $dir );
    if( defined( $io ) )
    {
        @packages = map{ substr( $_, 0, length( $_ ) - 3 ) } grep{ substr( $_, -3 ) eq '.pm' && -f( "$dir/$_" ) } $io->read();
        $io->close ||
        warn( "Unable to close directory \"$dir\": $!\n" );
    }
    else
    {
        warn( "Unable to open directory \"$dir\": $!\n" );
    }
    return( wantarray() ? @packages : \@packages );
}
PERL
    __dbh => <<'PERL',
sub __dbh
{
    my $self  = shift( @_ );
    my $class = ref( $self ) || $self;
    my $this  = $self->_obj2h;
    no strict 'refs';
    if( !$this->{__dbh} )
    {
        return( '' ) if( !${ "$class\::DB_DSN" } );
        require DBI;
        ## Connecting to database
        my $db_opt = {};
        $db_opt->{RaiseError} = ${ "$class\::DB_RAISE_ERROR" } if( length( ${ "$class\::DB_RAISE_ERROR" } ) );
        $db_opt->{AutoCommit} = ${ "$class\::DB_AUTO_COMMIT" } if( length( ${ "$class\::DB_AUTO_COMMIT" } ) );
        $db_opt->{PrintError} = ${ "$class\::DB_PRINT_ERROR" } if( length( ${ "$class\::DB_PRINT_ERROR" } ) );
        $db_opt->{ShowErrorStatement} = ${ "$class\::DB_SHOW_ERROR_STATEMENT" } if( length( ${ "$class\::DB_SHOW_ERROR_STATEMENT" } ) );
        $db_opt->{client_encoding} = ${ "$class\::DB_CLIENT_ENCODING" } if( length( ${ "$class\::DB_CLIENT_ENCODING" } ) );
        my $dbh = DBI->connect_cached( ${ "$class\::DB_DSN" } ) ||
        die( "Unable to connect to sql database with dsn '", ${ "$class\::DB_DSN" }, "'\n" );
        $dbh->{pg_server_prepare} = 1 if( ${ "$class\::DB_SERVER_PREPARE" } );
        $this->{__dbh} = $dbh;
    }
    return( $this->{__dbh} );
}
PERL
    # NOTE: __colour_data()
    __colour_data => <<'PERL',
# Initially those data were stored after the __END__, but it seems some module is interfering with <DATA>
# and so those data could not be loaded reliably
# This is called once by colour_to_rgb to generate the hash reference COLOUR_NAME_TO_RGB
sub __colour_data
{
    my $colour_data = <<EOT;
{'alice blue' => ['240','248','255'],'aliceblue' => ['240','248','255'],'antique white' => ['250','235','215'],'antiquewhite' => ['250','235','215'],'antiquewhite1' => ['255','239','219'],'antiquewhite2' => ['238','223','204'],'antiquewhite3' => ['205','192','176'],'antiquewhite4' => ['139','131','120'],'aquamarine' => ['127','255','212'],'aquamarine1' => ['127','255','212'],'aquamarine2' => ['118','238','198'],'aquamarine3' => ['102','205','170'],'aquamarine4' => ['69','139','116'],'azure' => ['240','255','255'],'azure1' => ['240','255','255'],'azure2' => ['224','238','238'],'azure3' => ['193','205','205'],'azure4' => ['131','139','139'],'beige' => ['245','245','220'],'bisque' => ['255','228','196'],'bisque1' => ['255','228','196'],'bisque2' => ['238','213','183'],'bisque3' => ['205','183','158'],'bisque4' => ['139','125','107'],'black' => ['0','0','0'],'blanched almond' => ['255','235','205'],'blanchedalmond' => ['255','235','205'],'blue' => ['0','0','255'],'blue violet' => ['138','43','226'],'blue1' => ['0','0','255'],'blue2' => ['0','0','238'],'blue3' => ['0','0','205'],'blue4' => ['0','0','139'],'blueviolet' => ['138','43','226'],'brown' => ['165','42','42'],'brown1' => ['255','64','64'],'brown2' => ['238','59','59'],'brown3' => ['205','51','51'],'brown4' => ['139','35','35'],'burlywood' => ['222','184','135'],'burlywood1' => ['255','211','155'],'burlywood2' => ['238','197','145'],'burlywood3' => ['205','170','125'],'burlywood4' => ['139','115','85'],'cadet blue' => ['95','158','160'],'cadetblue' => ['95','158','160'],'cadetblue1' => ['152','245','255'],'cadetblue2' => ['142','229','238'],'cadetblue3' => ['122','197','205'],'cadetblue4' => ['83','134','139'],'chartreuse' => ['127','255','0'],'chartreuse1' => ['127','255','0'],'chartreuse2' => ['118','238','0'],'chartreuse3' => ['102','205','0'],'chartreuse4' => ['69','139','0'],'chocolate' => ['210','105','30'],'chocolate1' => ['255','127','36'],'chocolate2' => ['238','118','33'],'chocolate3' => ['205','102','29'],'chocolate4' => ['139','69','19'],'coral' => ['255','127','80'],'coral1' => ['255','114','86'],'coral2' => ['238','106','80'],'coral3' => ['205','91','69'],'coral4' => ['139','62','47'],'cornflower blue' => ['100','149','237'],'cornflowerblue' => ['100','149','237'],'cornsilk' => ['255','248','220'],'cornsilk1' => ['255','248','220'],'cornsilk2' => ['238','232','205'],'cornsilk3' => ['205','200','177'],'cornsilk4' => ['139','136','120'],'cyan' => ['0','255','255'],'cyan1' => ['0','255','255'],'cyan2' => ['0','238','238'],'cyan3' => ['0','205','205'],'cyan4' => ['0','139','139'],'dark blue' => ['0','0','139'],'dark cyan' => ['0','139','139'],'dark goldenrod' => ['184','134','11'],'dark gray' => ['169','169','169'],'dark green' => ['0','100','0'],'dark grey' => ['169','169','169'],'dark khaki' => ['189','183','107'],'dark magenta' => ['139','0','139'],'dark olive green' => ['85','107','47'],'dark orange' => ['255','140','0'],'dark orchid' => ['153','50','204'],'dark red' => ['139','0','0'],'dark salmon' => ['233','150','122'],'dark sea green' => ['143','188','143'],'dark slate blue' => ['72','61','139'],'dark slate gray' => ['47','79','79'],'dark slate grey' => ['47','79','79'],'dark turquoise' => ['0','206','209'],'dark violet' => ['148','0','211'],'darkblue' => ['0','0','139'],'darkcyan' => ['0','139','139'],'darkgoldenrod' => ['184','134','11'],'darkgoldenrod1' => ['255','185','15'],'darkgoldenrod2' => ['238','173','14'],'darkgoldenrod3' => ['205','149','12'],'darkgoldenrod4' => ['139','101','8'],'darkgray' => ['169','169','169'],'darkgreen' => ['0','100','0'],'darkgrey' => ['169','169','169'],'darkkhaki' => ['189','183','107'],'darkmagenta' => ['139','0','139'],'darkolivegreen' => ['85','107','47'],'darkolivegreen1' => ['202','255','112'],'darkolivegreen2' => ['188','238','104'],'darkolivegreen3' => ['162','205','90'],'darkolivegreen4' => ['110','139','61'],'darkorange' => ['255','140','0'],'darkorange1' => ['255','127','0'],'darkorange2' => ['238','118','0'],'darkorange3' => ['205','102','0'],'darkorange4' => ['139','69','0'],'darkorchid' => ['153','50','204'],'darkorchid1' => ['191','62','255'],'darkorchid2' => ['178','58','238'],'darkorchid3' => ['154','50','205'],'darkorchid4' => ['104','34','139'],'darkred' => ['139','0','0'],'darksalmon' => ['233','150','122'],'darkseagreen' => ['143','188','143'],'darkseagreen1' => ['193','255','193'],'darkseagreen2' => ['180','238','180'],'darkseagreen3' => ['155','205','155'],'darkseagreen4' => ['105','139','105'],'darkslateblue' => ['72','61','139'],'darkslategray' => ['47','79','79'],'darkslategray1' => ['151','255','255'],'darkslategray2' => ['141','238','238'],'darkslategray3' => ['121','205','205'],'darkslategray4' => ['82','139','139'],'darkslategrey' => ['47','79','79'],'darkturquoise' => ['0','206','209'],'darkviolet' => ['148','0','211'],'deep pink' => ['255','20','147'],'deep sky blue' => ['0','191','255'],'deeppink' => ['255','20','147'],'deeppink1' => ['255','20','147'],'deeppink2' => ['238','18','137'],'deeppink3' => ['205','16','118'],'deeppink4' => ['139','10','80'],'deepskyblue' => ['0','191','255'],'deepskyblue1' => ['0','191','255'],'deepskyblue2' => ['0','178','238'],'deepskyblue3' => ['0','154','205'],'deepskyblue4' => ['0','104','139'],'dim gray' => ['105','105','105'],'dim grey' => ['105','105','105'],'dimgray' => ['105','105','105'],'dimgrey' => ['105','105','105'],'dodger blue' => ['30','144','255'],'dodgerblue' => ['30','144','255'],'dodgerblue1' => ['30','144','255'],'dodgerblue2' => ['28','134','238'],'dodgerblue3' => ['24','116','205'],'dodgerblue4' => ['16','78','139'],'firebrick' => ['178','34','34'],'firebrick1' => ['255','48','48'],'firebrick2' => ['238','44','44'],'firebrick3' => ['205','38','38'],'firebrick4' => ['139','26','26'],'floral white' => ['255','250','240'],'floralwhite' => ['255','250','240'],'forest green' => ['34','139','34'],'forestgreen' => ['34','139','34'],'gainsboro' => ['220','220','220'],'ghost white' => ['248','248','255'],'ghostwhite' => ['248','248','255'],'gold' => ['255','215','0'],'gold1' => ['255','215','0'],'gold2' => ['238','201','0'],'gold3' => ['205','173','0'],'gold4' => ['139','117','0'],'goldenrod' => ['218','165','32'],'goldenrod1' => ['255','193','37'],'goldenrod2' => ['238','180','34'],'goldenrod3' => ['205','155','29'],'goldenrod4' => ['139','105','20'],'gray' => ['190','190','190'],'gray0' => ['0','0','0'],'gray1' => ['3','3','3'],'gray10' => ['26','26','26'],'gray100' => ['255','255','255'],'gray11' => ['28','28','28'],'gray12' => ['31','31','31'],'gray13' => ['33','33','33'],'gray14' => ['36','36','36'],'gray15' => ['38','38','38'],'gray16' => ['41','41','41'],'gray17' => ['43','43','43'],'gray18' => ['46','46','46'],'gray19' => ['48','48','48'],'gray2' => ['5','5','5'],'gray20' => ['51','51','51'],'gray21' => ['54','54','54'],'gray22' => ['56','56','56'],'gray23' => ['59','59','59'],'gray24' => ['61','61','61'],'gray25' => ['64','64','64'],'gray26' => ['66','66','66'],'gray27' => ['69','69','69'],'gray28' => ['71','71','71'],'gray29' => ['74','74','74'],'gray3' => ['8','8','8'],'gray30' => ['77','77','77'],'gray31' => ['79','79','79'],'gray32' => ['82','82','82'],'gray33' => ['84','84','84'],'gray34' => ['87','87','87'],'gray35' => ['89','89','89'],'gray36' => ['92','92','92'],'gray37' => ['94','94','94'],'gray38' => ['97','97','97'],'gray39' => ['99','99','99'],'gray4' => ['10','10','10'],'gray40' => ['102','102','102'],'gray41' => ['105','105','105'],'gray42' => ['107','107','107'],'gray43' => ['110','110','110'],'gray44' => ['112','112','112'],'gray45' => ['115','115','115'],'gray46' => ['117','117','117'],'gray47' => ['120','120','120'],'gray48' => ['122','122','122'],'gray49' => ['125','125','125'],'gray5' => ['13','13','13'],'gray50' => ['127','127','127'],'gray51' => ['130','130','130'],'gray52' => ['133','133','133'],'gray53' => ['135','135','135'],'gray54' => ['138','138','138'],'gray55' => ['140','140','140'],'gray56' => ['143','143','143'],'gray57' => ['145','145','145'],'gray58' => ['148','148','148'],'gray59' => ['150','150','150'],'gray6' => ['15','15','15'],'gray60' => ['153','153','153'],'gray61' => ['156','156','156'],'gray62' => ['158','158','158'],'gray63' => ['161','161','161'],'gray64' => ['163','163','163'],'gray65' => ['166','166','166'],'gray66' => ['168','168','168'],'gray67' => ['171','171','171'],'gray68' => ['173','173','173'],'gray69' => ['176','176','176'],'gray7' => ['18','18','18'],'gray70' => ['179','179','179'],'gray71' => ['181','181','181'],'gray72' => ['184','184','184'],'gray73' => ['186','186','186'],'gray74' => ['189','189','189'],'gray75' => ['191','191','191'],'gray76' => ['194','194','194'],'gray77' => ['196','196','196'],'gray78' => ['199','199','199'],'gray79' => ['201','201','201'],'gray8' => ['20','20','20'],'gray80' => ['204','204','204'],'gray81' => ['207','207','207'],'gray82' => ['209','209','209'],'gray83' => ['212','212','212'],'gray84' => ['214','214','214'],'gray85' => ['217','217','217'],'gray86' => ['219','219','219'],'gray87' => ['222','222','222'],'gray88' => ['224','224','224'],'gray89' => ['227','227','227'],'gray9' => ['23','23','23'],'gray90' => ['229','229','229'],'gray91' => ['232','232','232'],'gray92' => ['235','235','235'],'gray93' => ['237','237','237'],'gray94' => ['240','240','240'],'gray95' => ['242','242','242'],'gray96' => ['245','245','245'],'gray97' => ['247','247','247'],'gray98' => ['250','250','250'],'gray99' => ['252','252','252'],'green' => ['0','255','0'],'green yellow' => ['173','255','47'],'green1' => ['0','255','0'],'green2' => ['0','238','0'],'green3' => ['0','205','0'],'green4' => ['0','139','0'],'greenyellow' => ['173','255','47'],'grey' => ['190','190','190'],'grey0' => ['0','0','0'],'grey1' => ['3','3','3'],'grey10' => ['26','26','26'],'grey100' => ['255','255','255'],'grey11' => ['28','28','28'],'grey12' => ['31','31','31'],'grey13' => ['33','33','33'],'grey14' => ['36','36','36'],'grey15' => ['38','38','38'],'grey16' => ['41','41','41'],'grey17' => ['43','43','43'],'grey18' => ['46','46','46'],'grey19' => ['48','48','48'],'grey2' => ['5','5','5'],'grey20' => ['51','51','51'],'grey21' => ['54','54','54'],'grey22' => ['56','56','56'],'grey23' => ['59','59','59'],'grey24' => ['61','61','61'],'grey25' => ['64','64','64'],'grey26' => ['66','66','66'],'grey27' => ['69','69','69'],'grey28' => ['71','71','71'],'grey29' => ['74','74','74'],'grey3' => ['8','8','8'],'grey30' => ['77','77','77'],'grey31' => ['79','79','79'],'grey32' => ['82','82','82'],'grey33' => ['84','84','84'],'grey34' => ['87','87','87'],'grey35' => ['89','89','89'],'grey36' => ['92','92','92'],'grey37' => ['94','94','94'],'grey38' => ['97','97','97'],'grey39' => ['99','99','99'],'grey4' => ['10','10','10'],'grey40' => ['102','102','102'],'grey41' => ['105','105','105'],'grey42' => ['107','107','107'],'grey43' => ['110','110','110'],'grey44' => ['112','112','112'],'grey45' => ['115','115','115'],'grey46' => ['117','117','117'],'grey47' => ['120','120','120'],'grey48' => ['122','122','122'],'grey49' => ['125','125','125'],'grey5' => ['13','13','13'],'grey50' => ['127','127','127'],'grey51' => ['130','130','130'],'grey52' => ['133','133','133'],'grey53' => ['135','135','135'],'grey54' => ['138','138','138'],'grey55' => ['140','140','140'],'grey56' => ['143','143','143'],'grey57' => ['145','145','145'],'grey58' => ['148','148','148'],'grey59' => ['150','150','150'],'grey6' => ['15','15','15'],'grey60' => ['153','153','153'],'grey61' => ['156','156','156'],'grey62' => ['158','158','158'],'grey63' => ['161','161','161'],'grey64' => ['163','163','163'],'grey65' => ['166','166','166'],'grey66' => ['168','168','168'],'grey67' => ['171','171','171'],'grey68' => ['173','173','173'],'grey69' => ['176','176','176'],'grey7' => ['18','18','18'],'grey70' => ['179','179','179'],'grey71' => ['181','181','181'],'grey72' => ['184','184','184'],'grey73' => ['186','186','186'],'grey74' => ['189','189','189'],'grey75' => ['191','191','191'],'grey76' => ['194','194','194'],'grey77' => ['196','196','196'],'grey78' => ['199','199','199'],'grey79' => ['201','201','201'],'grey8' => ['20','20','20'],'grey80' => ['204','204','204'],'grey81' => ['207','207','207'],'grey82' => ['209','209','209'],'grey83' => ['212','212','212'],'grey84' => ['214','214','214'],'grey85' => ['217','217','217'],'grey86' => ['219','219','219'],'grey87' => ['222','222','222'],'grey88' => ['224','224','224'],'grey89' => ['227','227','227'],'grey9' => ['23','23','23'],'grey90' => ['229','229','229'],'grey91' => ['232','232','232'],'grey92' => ['235','235','235'],'grey93' => ['237','237','237'],'grey94' => ['240','240','240'],'grey95' => ['242','242','242'],'grey96' => ['245','245','245'],'grey97' => ['247','247','247'],'grey98' => ['250','250','250'],'grey99' => ['252','252','252'],'honeydew' => ['240','255','240'],'honeydew1' => ['240','255','240'],'honeydew2' => ['224','238','224'],'honeydew3' => ['193','205','193'],'honeydew4' => ['131','139','131'],'hot pink' => ['255','105','180'],'hotpink' => ['255','105','180'],'hotpink1' => ['255','110','180'],'hotpink2' => ['238','106','167'],'hotpink3' => ['205','96','144'],'hotpink4' => ['139','58','98'],'indian red' => ['205','92','92'],'indianred' => ['205','92','92'],'indianred1' => ['255','106','106'],'indianred2' => ['238','99','99'],'indianred3' => ['205','85','85'],'indianred4' => ['139','58','58'],'ivory' => ['255','255','240'],'ivory1' => ['255','255','240'],'ivory2' => ['238','238','224'],'ivory3' => ['205','205','193'],'ivory4' => ['139','139','131'],'khaki' => ['240','230','140'],'khaki1' => ['255','246','143'],'khaki2' => ['238','230','133'],'khaki3' => ['205','198','115'],'khaki4' => ['139','134','78'],'lavender' => ['230','230','250'],'lavender blush' => ['255','240','245'],'lavenderblush' => ['255','240','245'],'lavenderblush1' => ['255','240','245'],'lavenderblush2' => ['238','224','229'],'lavenderblush3' => ['205','193','197'],'lavenderblush4' => ['139','131','134'],'lawn green' => ['124','252','0'],'lawngreen' => ['124','252','0'],'lemon chiffon' => ['255','250','205'],'lemonchiffon' => ['255','250','205'],'lemonchiffon1' => ['255','250','205'],'lemonchiffon2' => ['238','233','191'],'lemonchiffon3' => ['205','201','165'],'lemonchiffon4' => ['139','137','112'],'light blue' => ['173','216','230'],'light coral' => ['240','128','128'],'light cyan' => ['224','255','255'],'light goldenrod' => ['238','221','130'],'light goldenrod yellow' => ['250','250','210'],'light gray' => ['211','211','211'],'light green' => ['144','238','144'],'light grey' => ['211','211','211'],'light pink' => ['255','182','193'],'light salmon' => ['255','160','122'],'light sea green' => ['32','178','170'],'light sky blue' => ['135','206','250'],'light slate blue' => ['132','112','255'],'light slate gray' => ['119','136','153'],'light slate grey' => ['119','136','153'],'light steel blue' => ['176','196','222'],'light yellow' => ['255','255','224'],'lightblue' => ['173','216','230'],'lightblue1' => ['191','239','255'],'lightblue2' => ['178','223','238'],'lightblue3' => ['154','192','205'],'lightblue4' => ['104','131','139'],'lightcoral' => ['240','128','128'],'lightcyan' => ['224','255','255'],'lightcyan1' => ['224','255','255'],'lightcyan2' => ['209','238','238'],'lightcyan3' => ['180','205','205'],'lightcyan4' => ['122','139','139'],'lightgoldenrod' => ['238','221','130'],'lightgoldenrod1' => ['255','236','139'],'lightgoldenrod2' => ['238','220','130'],'lightgoldenrod3' => ['205','190','112'],'lightgoldenrod4' => ['139','129','76'],'lightgoldenrodyellow' => ['250','250','210'],'lightgray' => ['211','211','211'],'lightgreen' => ['144','238','144'],'lightgrey' => ['211','211','211'],'lightpink' => ['255','182','193'],'lightpink1' => ['255','174','185'],'lightpink2' => ['238','162','173'],'lightpink3' => ['205','140','149'],'lightpink4' => ['139','95','101'],'lightsalmon' => ['255','160','122'],'lightsalmon1' => ['255','160','122'],'lightsalmon2' => ['238','149','114'],'lightsalmon3' => ['205','129','98'],'lightsalmon4' => ['139','87','66'],'lightseagreen' => ['32','178','170'],'lightskyblue' => ['135','206','250'],'lightskyblue1' => ['176','226','255'],'lightskyblue2' => ['164','211','238'],'lightskyblue3' => ['141','182','205'],'lightskyblue4' => ['96','123','139'],'lightslateblue' => ['132','112','255'],'lightslategray' => ['119','136','153'],'lightslategrey' => ['119','136','153'],'lightsteelblue' => ['176','196','222'],'lightsteelblue1' => ['202','225','255'],'lightsteelblue2' => ['188','210','238'],'lightsteelblue3' => ['162','181','205'],'lightsteelblue4' => ['110','123','139'],'lightyellow' => ['255','255','224'],'lightyellow1' => ['255','255','224'],'lightyellow2' => ['238','238','209'],'lightyellow3' => ['205','205','180'],'lightyellow4' => ['139','139','122'],'lime green' => ['50','205','50'],'limegreen' => ['50','205','50'],'linen' => ['250','240','230'],'magenta' => ['255','0','255'],'magenta1' => ['255','0','255'],'magenta2' => ['238','0','238'],'magenta3' => ['205','0','205'],'magenta4' => ['139','0','139'],'maroon' => ['176','48','96'],'maroon1' => ['255','52','179'],'maroon2' => ['238','48','167'],'maroon3' => ['205','41','144'],'maroon4' => ['139','28','98'],'medium aquamarine' => ['102','205','170'],'medium blue' => ['0','0','205'],'medium orchid' => ['186','85','211'],'medium purple' => ['147','112','219'],'medium sea green' => ['60','179','113'],'medium slate blue' => ['123','104','238'],'medium spring green' => ['0','250','154'],'medium turquoise' => ['72','209','204'],'medium violet red' => ['199','21','133'],'mediumaquamarine' => ['102','205','170'],'mediumblue' => ['0','0','205'],'mediumorchid' => ['186','85','211'],'mediumorchid1' => ['224','102','255'],'mediumorchid2' => ['209','95','238'],'mediumorchid3' => ['180','82','205'],'mediumorchid4' => ['122','55','139'],'mediumpurple' => ['147','112','219'],'mediumpurple1' => ['171','130','255'],'mediumpurple2' => ['159','121','238'],'mediumpurple3' => ['137','104','205'],'mediumpurple4' => ['93','71','139'],'mediumseagreen' => ['60','179','113'],'mediumslateblue' => ['123','104','238'],'mediumspringgreen' => ['0','250','154'],'mediumturquoise' => ['72','209','204'],'mediumvioletred' => ['199','21','133'],'midnight blue' => ['25','25','112'],'midnightblue' => ['25','25','112'],'mint cream' => ['245','255','250'],'mintcream' => ['245','255','250'],'misty rose' => ['255','228','225'],'mistyrose' => ['255','228','225'],'mistyrose1' => ['255','228','225'],'mistyrose2' => ['238','213','210'],'mistyrose3' => ['205','183','181'],'mistyrose4' => ['139','125','123'],'moccasin' => ['255','228','181'],'navajo white' => ['255','222','173'],'navajowhite' => ['255','222','173'],'navajowhite1' => ['255','222','173'],'navajowhite2' => ['238','207','161'],'navajowhite3' => ['205','179','139'],'navajowhite4' => ['139','121','94'],'navy' => ['0','0','128'],'navy blue' => ['0','0','128'],'navyblue' => ['0','0','128'],'old lace' => ['253','245','230'],'oldlace' => ['253','245','230'],'olive drab' => ['107','142','35'],'olivedrab' => ['107','142','35'],'olivedrab1' => ['192','255','62'],'olivedrab2' => ['179','238','58'],'olivedrab3' => ['154','205','50'],'olivedrab4' => ['105','139','34'],'orange' => ['255','165','0'],'orange red' => ['255','69','0'],'orange1' => ['255','165','0'],'orange2' => ['238','154','0'],'orange3' => ['205','133','0'],'orange4' => ['139','90','0'],'orangered' => ['255','69','0'],'orangered1' => ['255','69','0'],'orangered2' => ['238','64','0'],'orangered3' => ['205','55','0'],'orangered4' => ['139','37','0'],'orchid' => ['218','112','214'],'orchid1' => ['255','131','250'],'orchid2' => ['238','122','233'],'orchid3' => ['205','105','201'],'orchid4' => ['139','71','137'],'pale goldenrod' => ['238','232','170'],'pale green' => ['152','251','152'],'pale turquoise' => ['175','238','238'],'pale violet red' => ['219','112','147'],'palegoldenrod' => ['238','232','170'],'palegreen' => ['152','251','152'],'palegreen1' => ['154','255','154'],'palegreen2' => ['144','238','144'],'palegreen3' => ['124','205','124'],'palegreen4' => ['84','139','84'],'paleturquoise' => ['175','238','238'],'paleturquoise1' => ['187','255','255'],'paleturquoise2' => ['174','238','238'],'paleturquoise3' => ['150','205','205'],'paleturquoise4' => ['102','139','139'],'palevioletred' => ['219','112','147'],'palevioletred1' => ['255','130','171'],'palevioletred2' => ['238','121','159'],'palevioletred3' => ['205','104','137'],'palevioletred4' => ['139','71','93'],'papaya whip' => ['255','239','213'],'papayawhip' => ['255','239','213'],'peach puff' => ['255','218','185'],'peachpuff' => ['255','218','185'],'peachpuff1' => ['255','218','185'],'peachpuff2' => ['238','203','173'],'peachpuff3' => ['205','175','149'],'peachpuff4' => ['139','119','101'],'peru' => ['205','133','63'],'pink' => ['255','192','203'],'pink1' => ['255','181','197'],'pink2' => ['238','169','184'],'pink3' => ['205','145','158'],'pink4' => ['139','99','108'],'plum' => ['221','160','221'],'plum1' => ['255','187','255'],'plum2' => ['238','174','238'],'plum3' => ['205','150','205'],'plum4' => ['139','102','139'],'powder blue' => ['176','224','230'],'powderblue' => ['176','224','230'],'purple' => ['160','32','240'],'purple1' => ['155','48','255'],'purple2' => ['145','44','238'],'purple3' => ['125','38','205'],'purple4' => ['85','26','139'],'red' => ['255','0','0'],'red1' => ['255','0','0'],'red2' => ['238','0','0'],'red3' => ['205','0','0'],'red4' => ['139','0','0'],'rosy brown' => ['188','143','143'],'rosybrown' => ['188','143','143'],'rosybrown1' => ['255','193','193'],'rosybrown2' => ['238','180','180'],'rosybrown3' => ['205','155','155'],'rosybrown4' => ['139','105','105'],'royal blue' => ['65','105','225'],'royalblue' => ['65','105','225'],'royalblue1' => ['72','118','255'],'royalblue2' => ['67','110','238'],'royalblue3' => ['58','95','205'],'royalblue4' => ['39','64','139'],'saddle brown' => ['139','69','19'],'saddlebrown' => ['139','69','19'],'salmon' => ['250','128','114'],'salmon1' => ['255','140','105'],'salmon2' => ['238','130','98'],'salmon3' => ['205','112','84'],'salmon4' => ['139','76','57'],'sandy brown' => ['244','164','96'],'sandybrown' => ['244','164','96'],'sea green' => ['46','139','87'],'seagreen' => ['46','139','87'],'seagreen1' => ['84','255','159'],'seagreen2' => ['78','238','148'],'seagreen3' => ['67','205','128'],'seagreen4' => ['46','139','87'],'seashell' => ['255','245','238'],'seashell1' => ['255','245','238'],'seashell2' => ['238','229','222'],'seashell3' => ['205','197','191'],'seashell4' => ['139','134','130'],'sienna' => ['160','82','45'],'sienna1' => ['255','130','71'],'sienna2' => ['238','121','66'],'sienna3' => ['205','104','57'],'sienna4' => ['139','71','38'],'sky blue' => ['135','206','235'],'skyblue' => ['135','206','235'],'skyblue1' => ['135','206','255'],'skyblue2' => ['126','192','238'],'skyblue3' => ['108','166','205'],'skyblue4' => ['74','112','139'],'slate blue' => ['106','90','205'],'slate gray' => ['112','128','144'],'slate grey' => ['112','128','144'],'slateblue' => ['106','90','205'],'slateblue1' => ['131','111','255'],'slateblue2' => ['122','103','238'],'slateblue3' => ['105','89','205'],'slateblue4' => ['71','60','139'],'slategray' => ['112','128','144'],'slategray1' => ['198','226','255'],'slategray2' => ['185','211','238'],'slategray3' => ['159','182','205'],'slategray4' => ['108','123','139'],'slategrey' => ['112','128','144'],'snow' => ['255','250','250'],'snow1' => ['255','250','250'],'snow2' => ['238','233','233'],'snow3' => ['205','201','201'],'snow4' => ['139','137','137'],'spring green' => ['0','255','127'],'springgreen' => ['0','255','127'],'springgreen1' => ['0','255','127'],'springgreen2' => ['0','238','118'],'springgreen3' => ['0','205','102'],'springgreen4' => ['0','139','69'],'steel blue' => ['70','130','180'],'steelblue' => ['70','130','180'],'steelblue1' => ['99','184','255'],'steelblue2' => ['92','172','238'],'steelblue3' => ['79','148','205'],'steelblue4' => ['54','100','139'],'tan' => ['210','180','140'],'tan1' => ['255','165','79'],'tan2' => ['238','154','73'],'tan3' => ['205','133','63'],'tan4' => ['139','90','43'],'thistle' => ['216','191','216'],'thistle1' => ['255','225','255'],'thistle2' => ['238','210','238'],'thistle3' => ['205','181','205'],'thistle4' => ['139','123','139'],'tomato' => ['255','99','71'],'tomato1' => ['255','99','71'],'tomato2' => ['238','92','66'],'tomato3' => ['205','79','57'],'tomato4' => ['139','54','38'],'turquoise' => ['64','224','208'],'turquoise1' => ['0','245','255'],'turquoise2' => ['0','229','238'],'turquoise3' => ['0','197','205'],'turquoise4' => ['0','134','139'],'violet' => ['238','130','238'],'violet red' => ['208','32','144'],'violetred' => ['208','32','144'],'violetred1' => ['255','62','150'],'violetred2' => ['238','58','140'],'violetred3' => ['205','50','120'],'violetred4' => ['139','34','82'],'wheat' => ['245','222','179'],'wheat1' => ['255','231','186'],'wheat2' => ['238','216','174'],'wheat3' => ['205','186','150'],'wheat4' => ['139','126','102'],'white' => ['255','255','255'],'white smoke' => ['245','245','245'],'whitesmoke' => ['245','245','245'],'yellow' => ['255','255','0'],'yellow green' => ['154','205','50'],'yellow1' => ['255','255','0'],'yellow2' => ['238','238','0'],'yellow3' => ['205','205','0'],'yellow4' => ['139','139','0'],'yellowgreen' => ['154','205','50']}
EOT
}
PERL
    # NOTE: __create_class()
    __create_class => <<'PERL',
sub __create_class
{
    my $self  = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field was provided to create a dynamic class." ) );
    my $def   = shift( @_ );
    my $class;
    if( $def->{_class} )
    {
        $class = $def->{_class};
    }
    else
    {
        my $new_class = $field;
        $new_class =~ tr/-/_/;
        $new_class =~ s/\_{2,}/_/g;
        $new_class = join( '', map( ucfirst( lc( $_ ) ), split( /\_/, $new_class ) ) );
        $class = ( ref( $self ) || $self ) . "\::${new_class}";
    }
    if( Class::Load::is_class_loaded( $class ) )
    {
        my $ref = eval( "\\%${class}::" );
    }
    
    unless( Class::Load::is_class_loaded( $class ) )
    {
        my $type2func =
        {
        array       => '_set_get_array',
        array_as_object => '_set_get_array_as_object',
        boolean     => '_set_get_boolean',
        class       => '_set_get_class',
        class_array => '_set_get_class_array',
        code        => '_set_get_code',
        datetime    => '_set_get_datetime',
        decimal     => '_set_get_number',
        file        => '_set_get_file',
        float       => '_set_get_number',
        glob        => '_set_get_glob',
        hash        => '_set_get_hash',
        hash_as_object => '_set_get_hash_as_mix_object',
        integer     => '_set_get_number',
        ip          => '_set_get_ip',
        long        => '_set_get_number',
        number      => '_set_get_number',
        object      => '_set_get_object',
        object_array => '_set_get_object_array',
        object_array_object => '_set_get_object_array_object',
        scalar      => '_set_get_scalar',
        scalar_as_object => '_set_get_scalar_as_object',
        scalar_or_object => '_set_get_scalar_or_object',
        uri         => '_set_get_uri',
        uuid        => '_set_get_uuid',
        version     => '_set_get_version',
        };
        # Alias
        $type2func->{string} = $type2func->{scalar};
        
        my $perl = <<EOT;
package $class;
BEGIN
{
    use strict;
    use Module::Generic;
    use parent -norequire, qw( Module::Generic );
};

sub init
{
    my \$self = shift( \@_ );
    \$self->{_fields} = [qw(
EOT
        $perl .= join( ' ', sort( keys( %$def ) ) ) . "\n";
        $perl .= <<EOT;
    )];
    return( \$self->SUPER::init( \@_ ) );
}
EOT
        my $call_sub = ( split( /::/, ( caller(1) )[3] ) )[-1];
        my $call_frame = $call_sub eq '_set_get_class' ? 1 : 0;
        my( $pack, $file, $line ) = caller( $call_frame );
        my $code_lines = [];
        foreach my $f ( sort( keys( %$def ) ) )
        {
            my $info;
            # Allow for lazy field => $type_value definition instead of field => { type => $type_value }
            # Also helps trap if the definition is not an hash as we expect and avoid a perl error
            if( !ref( $def->{ $f } // '' ) )
            {
                if( !defined( $def->{ $f } ) )
                {
                    warn( "Warning only: _set_get_class was called from package $pack at line $line in file $file, but the type provided has value 'undef', so we are skipping this field \"$f\" in the creation of our virtual class.\n" );
                    next;
                }
                $info = { type => $def->{ $f } };
            }
            else
            {
                $info = $def->{ $f };
            }
            my $type = lc( $info->{type} );
            # Convenience
            $info->{class} = $info->{package} if( $info->{package} && !length( $info->{class} ) );
            if( !CORE::exists( $type2func->{ $type } ) )
            {
                warn( "Warning only: _set_get_class was called from package $pack at line $line in file $file, but the type provided \"$type\" is unknown to us, so we are skipping this field \"$f\" in the creation of our virtual class.\n" . ( $type eq 'url' ? qq{Maybe you meant to use "uri" instead of "url" ?\n} : '' ) );
                next;
            }
            my $func = $type2func->{ $type };
            if( $type eq 'object' || 
                $type eq 'scalar_or_object' || 
                $type eq 'object_array_object' ||
                $type eq 'object_array' )
            {
                if( !$info->{class} && !$info->{package} )
                {
                    warn( "Warning only: _set_get_class was called from package $pack at line $line in file $file, and class \"$class\" field \"$f\" is to require an object, but no object class name was provided. Use the \"class\" or \"package\" property parameter. So we are skipping this field \"$f\" in the creation of our virtual class.\n" );
                    next;
                }
                my $this_class = $info->{class} || $info->{package};
                CORE::push( @$code_lines, "sub $f { return( shift->${func}( '$f', '$this_class', \@_ ) ); }" );
            }
            elsif( $type eq 'class' || $type eq 'class_array' || $type eq 'class_array_object' )
            {
                my $this_def = $info->{definition} // $info->{def};
                if( !CORE::exists( $info->{definition} ) && !CORE::exists( $info->{def} ) )
                {
                    warn( "Warning only: No dynamic class fields definition was provided for this field \"$f\". Skipping this field.\n" );
                    next;
                }
                elsif( ref( $this_def ) ne 'HASH' )
                {
                    warn( "Warning only: I was expecting a fields definition hash reference for dynamic class field \"$f\", but instead got '$this_def'. Skipping this field.\n" );
                    next;
                }
                # my $d = Data::Dumper->new( [ $this_def ] );
                # $d->Indent( 0 );
                # $d->Purity( 1 );
                # $d->Pad( '' );
                # $d->Terse( 1 );
                # $d->Sortkeys( 1 );
                # my $hash_str = $d->Dump;
                my $hash_str = Data::Dump::dump( $this_def );
                CORE::push( @$code_lines, "sub $f { return( shift->${func}( '$f', $hash_str, \@_ ) ); }" );
            }
            elsif( $type eq 'version' && ( exists( $info->{def} ) || exists( $info->{definition} ) ) )
            {
                my $this_def = $info->{definition} // $info->{def};
                my $hash_str = Data::Dump::dump( $this_def );
                CORE::push( @$code_lines, "sub $f { return( shift->${func}( '$f', $hash_str, \@_ ) ); }" );
            }
            else
            {
                CORE::push( @$code_lines, "sub $f { return( shift->${func}( '$f', \@_ ) ); }" );
            }
        }
        CORE::push( @$code_lines, "sub _fields { return( shift->_set_get_array_as_object( '_fields', \@_ ) ); }" );
        $perl .= join( "\n\n", @$code_lines );

        $perl .= <<EOT;


sub TO_JSON { return( shift->as_hash ); }

1;

EOT
        local $@;
        my $rc = eval( $perl );
        die( "Unable to dynamically create module $class: $@" ) if( $@ );
    }
    return( $class );
}
PERL
    # NOTE: _can_overload
    _can_overload => <<'PERL',
sub _can_overload
{
    my $self = shift( @_ );
    no overloading;
    # Nothing provided
    return if( !scalar( @_ ) );
    return if( !defined( $_[0] ) );
    return if( !Scalar::Util::blessed( $_[0] ) );
    if( $self->_is_array( $_[1] ) )
    {
        foreach my $op ( @{$_[1]} )
        {
            return(0) unless( overload::Method( $_[0] => $op ) );
        }
        return(1);
    }
    else
    {
        return( overload::Method( $_[0] => $_[1] ) );
    }
}
PERL
    # NOTE: _get_datetime_regexp
    _get_datetime_regexp => <<'PERL',
sub _get_datetime_regexp
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    use utf8;
    unless( defined( $PARSE_DATE_FRACTIONAL1_RE ) )
    {
        my $aliases = [qw( JST )];
        if( $self->_load_class( 'DateTime::TimeZone::Catalog::Extend', { version => 'v0.2.0' } ) )
        {
            $aliases = DateTime::TimeZone::Catalog::Extend->aliases;
        }
        my $tz_aliases = join( '|', @$aliases );
        $PARSE_DATE_FRACTIONAL1_RE = qr/
            (?<year>\d{4})
            (?<d_sep>[^\d\+])
            (?<month>\d{1,2})
            [^\d\+]
            (?<day>\d{1,2})
            (?<sep>[\s\t]+)
            (?<hour>\d{1,2})
            (?<t_sep>[^\d\+])
            (?<minute>\d{1,2})
            (?:[^\d\+](?<second>\d{1,2}))?
            (?<tz>
                (?:
                    (?<blank2>[[:blank:]]*)
                    (?<tz1>[-+]?\d{2,4})
                )
                |
                (?:
                    (?<blank2>(?:[[:blank:]]+|[-+]))
                    (?<tz2>$tz_aliases)
                )
            )?
        /x;
    }
    
    # 2019-06-19 23:23:57.000000000+0900
    # From PostgreSQL: 2019-06-20 11:02:36.306917+09
    # From SQLite: 2019-06-20 02:03:14
    # From MySQL: 2019-06-20 11:04:01
    # ISO 8601: 2019-06-20T11:08:27
    # ISO 8601: 2019-06-20T11:08:27Z
    # 2022-11-17T08:12:31+0900
    unless( defined( $PARSE_DATE_WITH_MILI_SECONDS_RE ) )
    {
        $PARSE_DATE_WITH_MILI_SECONDS_RE = qr/
        (?<year>\d{4})
        (?<d_sep>[-|\/])
        (?<month>\d{1,2})
        [-|\/]
        (?<day>\d{1,2})
        (?<sep>[[:blank:]]+|T)
        (?:
            (?<time>\d{1,2}:\d{1,2}:\d{1,2})
            |
            (?<time_short>\d{1,2}:\d{1,2})
        )
        (?:\.(?<milli>\d+))?
        (?:
            (?<tz>(?:\+|\-)(?:\d{2,4}|\d{2}:\d{2}))
            |
            (?<tz_utc>Z)
        )?
        /x;
    }

    # e.g. Sun, 06 Oct 2019 06:41:11 GMT
    unless( defined( $PARSE_DATE_HTTP_RE ) )
    {
        $PARSE_DATE_HTTP_RE = qr/
        (?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)
        ,[[:blank:]]+
        (?<day>\d{2})
        [[:blank:]]+
        (?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
        [[:blank:]]+
        (?<year>\d{4})
        [[:blank:]]+
        (?<hour>\d{2})
        :
        (?<minute>\d{2})
        :
        (?<second>\d{2})
        [[:blank:]]+
        GMT
        /x;
    }
    
    # 12 March 2001 17:07:30 JST
    # 12-March-2001 17:07:30 JST
    # 12/March/2001 17:07:30 JST
    # 12 March 2001 17:07
    # 12 March 2001 17:07 JST
    # 12 March 2001 17:07:30+0900
    # 12 March 2001 17:07:30 +0900
    # Monday, 12 March 2001 17:07:30 JST
    # Monday, 12 Mar 2001 17:07:30 JST
    # 03/Feb/1994:00:00:00 0000
    unless( defined( $PARSE_DATE_NON_STDANDARD_RE ) )
    {
        my $aliases = [qw( JST )];
        if( $self->_load_class( 'DateTime::TimeZone::Catalog::Extend', { version => 'v0.2.0' } ) )
        {
            $aliases = DateTime::TimeZone::Catalog::Extend->aliases;
        }
        my $tz_aliases = join( '|', @$aliases );
        
        $PARSE_DATE_NON_STDANDARD_RE = qr/
        (?:
            (?:
                (?<wd>Mon|Tue|Wed|Thu|Fri|Sat|Sun)
                |
                (?<wd_long>Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)
            )
            (?<wd_comma>\,)?(?<blank0>[[:blank:]]+)
        )?
        (?<day>\d{1,2})
        (?<sep1>[[:blank:]]+|[-\/])
        (?:
            (?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
            |
            (?<month_long>January|February|March|April|May|June|July|August|September|Octocber|November|December)
        )
        (?<sep2>[[:blank:]]+|[-\/])
        (?<year>\d{2}|\d{4})
        (?<blank1>[[:blank:]]+|\:)
        (?<hour>\d{1,2})
        :
        (?<minute>\d{1,2})
        (?:\:(?<second>\d{1,2}))?
        (?<tz>
            (?:
                (?<blank2>[[:blank:]]*)
                (?<tz1>[-+]?\d{2,4})
            )
            |
            (?:
                (?<blank2>[[:blank:]]+)
                (?<tz2>$tz_aliases)
            )
        )?
        /x;
    }

    # Fri Mar 25 12:18:36 2011
    # Fri Mar 25 12:16:25 ADT 2011
    # Fri Mar 25 2011
    unless( defined( $PARSE_DATE_NON_STDANDARD2_RE ) )
    {
        my $aliases = [qw( JST )];
        if( $self->_load_class( 'DateTime::TimeZone::Catalog::Extend', { version => 'v0.2.0' } ) )
        {
            $aliases = DateTime::TimeZone::Catalog::Extend->aliases;
        }
        my $tz_aliases = join( '|', @$aliases );
        
        $PARSE_DATE_NON_STDANDARD2_RE = qr/
        (?:
            (?<wd>Mon|Tue|Wed|Thu|Fri|Sat|Sun)
            |
            (?<wd_long>Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)
        )
        (?<blank1>[[:blank:]\h]+)
        (?:
            (?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
            |
            (?<month_long>January|February|March|April|May|June|July|August|September|Octocber|November|December)
        )
        (?<blank2>[[:blank:]\h]+)
        (?<day>\d{1,2})
        (?<blank3>[[:blank:]\h]+)
        (?:
            (?<time>\d{1,2}:\d{1,2}:\d{1,2})
            (?<blank4>[[:blank:]\h]+)
            (?:
                (?<tz>$tz_aliases)
                (?<blank5>[[:blank:]\h]+)
            )?
        )?
        (?<year>\d{4})
        /x;
    }
    
    # 2019-06-20
    # 2019/06/20
    # 2016.04.22
    unless( defined( $PARSE_DATE_ONLY_RE ) )
    {
        $PARSE_DATE_ONLY_RE = qr/
        (?<year>\d{4})
        (?<d_sep>\D)
        (?<month>\d{1,2})
        \D
        (?<day>\d{1,2})
        /x;
    }
    
    # 2014, Feb 17
    unless( defined( $PARSE_DATE_ONLY_US_SHORT_RE ) )
    {
        $PARSE_DATE_ONLY_US_SHORT_RE = qr/
            (?<year>\d{4})
            ,(?<sep1>[[:blank:]\h]+)
            (?<month>[a-zA-Z]{3,4})
            (?<sep2>[[:blank:]\h]+)
            (?<day>\d{1,2})
        /x;
    }
    
    # 17 Feb, 2014
    unless( defined( $PARSE_DATE_ONLY_EU_SHORT_RE ) )
    {
        $PARSE_DATE_ONLY_EU_SHORT_RE = qr/
            (?<day>\d{1,2})
            (?<sep1>[[:blank:]\h]+)
            (?<month>[a-zA-Z]{3,4})
            ,(?<sep2>[[:blank:]\h]+)
            (?<year>\d{4})
        /x;
    }
    
    # February 17, 2009
    unless( defined( $PARSE_DATE_ONLY_US_LONG_RE ) )
    {
        $PARSE_DATE_ONLY_US_LONG_RE = qr/
            (?<month>[a-zA-Z]{3,9})
            (?<sep1>[[:blank:]\h]+)
            (?<day>\d{1,2})
            ,(?<sep2>[[:blank:]\h]+)
            (?<year>\d{4})
        /x;
    }
    
    # 15 July 2021
    unless( defined( $PARSE_DATE_ONLY_EU_LONG_RE ) )
    {
        $PARSE_DATE_ONLY_EU_LONG_RE = qr/
            (?<day>\d{1,2})
            (?<sep1>[[:blank:]\h]+)
            (?<month>[a-zA-Z]{3,9})
            (?<sep2>[[:blank:]\h]+)
            (?<year>\d{4})
        /x;
    }
    
    # 22.04.2016
    # 22-04-2016
    # 17. 3. 2018.
    unless( defined( $PARSE_DATE_DOTTED_ONLY_EU_RE ) )
    {
        $PARSE_DATE_DOTTED_ONLY_EU_RE = qr/
            (?<day>\d{1,2})
            (?<sep>\D)
            (?<blank1>[[:blank:]\h]+)?
            (?<month>\d{1,2})
            \D
            (?<blank2>[[:blank:]\h]+)?
            (?<year>\d{4})
            (?<trailing_dot>\.)?
        /x;
    }
    
    # 17.III.2020
    # 17. III. 2018.
    unless( defined( $PARSE_DATE_ROMAN_RE ) )
    {
        $PARSE_DATE_ROMAN_RE = qr/
            (?<day>\d{1,2})
            \.
            (?<blank1>[[:blank:]\h]+)?
            (?<month>XI{0,2}|I{0,3}|IV|VI{0,3}|IX)
            \.
            (?<blank2>[[:blank:]\h]+)?
            (?<year>\d{4})
            (?<trailing_dot>\.)?
        /x;
    }
    
    # 20030613
    unless( defined( $PARSE_DATE_DIGITS_ONLY_RE ) )
    {
        $PARSE_DATE_DIGITS_ONLY_RE = qr/
            (?<year>\d{4})
            (?<month>\d{2})
            (?<day>\d{2})
        /x;
    }
    
    # 2021年7月14日
    # 令和3年7月14日
    # 2021年7月14日18時7分10秒
    # 2021年7月14日18時7分
    # 令和3年7月14日18時7分10秒
    # 令和3年7月14日18時7分
    unless( defined( $PARSE_DATETIME_JP_RE ) )
    {
        $PARSE_DATETIME_JP_RE = qr/
            (?<era>[\p{Han}]+)?
            (?<year>\d{1,4})年
            (?<month>\d{1,2})月
            (?<day>\d{1,2})日
            (?<time>
                (?<hour>[\d]{1,2})(?<hour_suffix>時)?
                (?:
                    (?<hour_sep>|:|：)?(?<minute>[\d]{1,2})(?<minute_suffix>分)
                    (?:
                        (?<minute_sep>|:|：)?(?<second>[\d]{1,2})(?<second_suffix>秒)
                    )?
                )?
            )?
        /x;
    }
    
    unless( defined( $PARSE_DATE_TIMESTAMP_RE ) )
    {
        $PARSE_DATE_TIMESTAMP_RE = qr/
            (?<timestamp>\d{1,10})
            (?:\.(?<milli>\d+))?
        /x;
    }
    
    unless( defined( $PARSE_DATETIME_RELATIVE_RE ) )
    {
        $PARSE_DATETIME_RELATIVE_RE = qr/
            ([\+\-]?\d+)
            ([YyMDdhms])?
        /x;
    }
    
    unless( defined( $PARSE_DATES_ALL_RE ) )
    {
        $PARSE_DATES_ALL_RE = qr/
        (?<parse_datetime>
            $PARSE_DATE_FRACTIONAL1_RE
            |
            $PARSE_DATE_WITH_MILI_SECONDS_RE
            |
            $PARSE_DATE_HTTP_RE
            |
            $PARSE_DATE_NON_STDANDARD_RE
            |
            $PARSE_DATE_NON_STDANDARD2_RE
            |
            $PARSE_DATE_ONLY_RE
            |
            $PARSE_DATE_ONLY_US_SHORT_RE
            |
            $PARSE_DATE_ONLY_EU_SHORT_RE
            |
            $PARSE_DATE_ONLY_US_LONG_RE
            |
            $PARSE_DATE_ONLY_EU_LONG_RE
            |
            $PARSE_DATE_DOTTED_ONLY_EU_RE
            |
            $PARSE_DATE_ROMAN_RE
            |
            $PARSE_DATE_DIGITS_ONLY_RE
            |
            $PARSE_DATETIME_JP_RE
            |
            $PARSE_DATE_TIMESTAMP_RE
            |
            $PARSE_DATETIME_RELATIVE_RE
        )
        /x;
    }
    my $def = 
    {
        incomplete => $PARSE_DATE_FRACTIONAL1_RE,
        iso8601 => $PARSE_DATE_WITH_MILI_SECONDS_RE,
        http => $PARSE_DATE_HTTP_RE,
        non_standard => $PARSE_DATE_NON_STDANDARD_RE,
        non_standard2 => $PARSE_DATE_NON_STDANDARD2_RE,
        date_only => $PARSE_DATE_ONLY_RE,
        us_short => $PARSE_DATE_ONLY_US_SHORT_RE,
        eu_short => $PARSE_DATE_ONLY_EU_SHORT_RE,
        us_long => $PARSE_DATE_ONLY_US_LONG_RE,
        eu_long => $PARSE_DATE_ONLY_EU_LONG_RE,
        date_only_eu => $PARSE_DATE_DOTTED_ONLY_EU_RE,
        date_roman => $PARSE_DATE_ROMAN_RE,
        date_digits => $PARSE_DATE_DIGITS_ONLY_RE,
        japan => $PARSE_DATETIME_JP_RE,
        unix => $PARSE_DATE_TIMESTAMP_RE,
        relative => $PARSE_DATETIME_RELATIVE_RE,
        all => $PARSE_DATES_ALL_RE,
    };
    return( ( CORE::defined( $elem ) && CORE::exists( $def->{ $elem } ) ) ? $def->{ $elem } : $def );
}
PERL
    # NOTE: _get_symbol
    _get_symbol => <<'PERL',
sub _get_symbol
{
    my $self = shift( @_ );
    my( $class, $var ) = ( @_ >= 2 ) ? splice( @_, 0, 2 ) : ( ( ref( $self ) || $self ), shift( @_ ) );
    if( $class !~ /^[a-zA-Z_][a-zA-Z0-9_]+(?:\:{2}[a-zA-Z0-9_]+)*$/ )
    {
        return( $self->error( "Invalid class name '$class'" ) );
    }
    elsif( !defined( $var ) || !length( $var ) )
    {
        return( $self->error( "No variable was aprovided." ) );
    }

    no strict 'refs';
    my $ns = \%{$class . '::'};
    my $map = 
    {
    '$' => 'SCALAR',
    '@' => 'ARRAY',
    '%' => 'HASH',
    '&' => 'CODE',
    ''  => 'IO',
    };
    my( $sigil, $type );
    if( exists( $map->{ substr( $var, 0, 1 ) } ) )
    {
        $sigil = substr( $var, 0, 1, '' );
        $type = $map->{ $sigil };
    }
    else
    {
        $type = $map->{ '' };
    }
    
    if( !exists( $ns->{ $var } ) )
    {
        return( wantarray ? () : undef );
    }
    my $glob = \$ns->{ $var };
    if( Scalar::Util::reftype( $glob ) eq 'GLOB' )
    {
        return( *{$glob}{$type} );
    }
    elsif( $type eq 'CODE' )
    {
        if( $] < 5.013004 )
        {
            return( \&{ $class . '::' . $var } );
        }
        else
        {
            return( *{ $ns->{ $var } }{CODE} );
        }
    }
    else
    {
        return( wantarray ? () : undef );
    }
}
PERL
    # NOTE: _has_base64()
    _has_base64 => <<'PERL',
sub _has_base64
{
    my $self = shift( @_ );
    my $val  = shift( @_ );
    return( '' ) if( !defined( $val ) || !length( $val ) );
    if( ref( $val ) eq 'ARRAY' && 
        scalar( @$val ) >= 2 && 
        defined( $val->[0] ) && 
        defined( $val->[1] ) &&
        ref( $val->[0] ) eq 'CODE' && 
        ref( $val->[1] ) eq 'CODE' )
    {
        return( $val );
    }
    
    my $class = ref( $self ) || $self;
    
    unless( defined( ${"${class}\::HAS_B64"} ) && ref( ${"${class}\::HAS_B64"} ) eq 'HASH' )
    {
        my $ref = ${"${class}\::HAS_B64"} = {};
        if( $self->_is_class_loadable( 'MIME::Base64' ) )
        {
            $ref->{ 'MIME::Base64' } =
            [
                sub{ return( &{"MIME::Base64\::encode_base64"}( shift( @_ ), '' ) ); },
                \&{"MIME::Base64\::decode_base64"},
            ];
        }
        if( $self->_is_class_loadable( 'Crypt::Misc' ) )
        {
            $ref->{ 'Crypt::Misc' } =
            [
                \&{"Crypt::Misc\::encode_b64"},
                \&{"Crypt::Misc\::decode_b64"},
            ];
        }
    }
    my $ref = ${"${class}\::HAS_B64"};
    return( '' ) if( !scalar( keys( %$ref ) ) );
    
    my $prefs = [];
    if( $val eq 'Crypt::Misc' || $val eq 'CryptX' )
    {
        push( @$prefs, qw( Crypt::Misc MIME::Base64 ) );
    }
    # for any other value, including 'MIME::Base64'
    else
    {
        push( @$prefs, qw( MIME::Base64 Crypt::Misc ) );
    }
    
    foreach my $mod ( @$prefs )
    {
        if( exists( $ref->{ $mod } ) && $self->_load_class( $mod ) )
        {
            return( $ref->{ $mod } );
        }
    }
    return( '' );
}
PERL
    # NOTE: _has_symbol
    _has_symbol => <<'PERL',
sub _has_symbol
{
    my $self = shift( @_ );
    my( $class, $var ) = ( @_ >= 2 ) ? splice( @_, 0, 2 ) : ( ( ref( $self ) || $self ), shift( @_ ) );
    if( $class !~ /^[a-zA-Z_][a-zA-Z0-9_]+(?:\:{2}[a-zA-Z0-9_]+)*$/ )
    {
        return( $self->error( "Invalid class name '$class'" ) );
    }
    elsif( !defined( $var ) || !length( $var ) )
    {
        return( $self->error( "No variable was aprovided." ) );
    }

    no strict 'refs';
    my $ns = \%{$class . '::'};
    my $map = 
    {
    '$' => 'SCALAR',
    '@' => 'ARRAY',
    '%' => 'HASH',
    '&' => 'CODE',
    ''  => 'IO',
    };
    my( $sigil, $type );
    if( exists( $map->{ substr( $var, 0, 1 ) } ) )
    {
        $sigil = substr( $var, 0, 1, '' );
        $type = $map->{ $sigil };
    }
    else
    {
        $type = $map->{ '' };
    }
    return(0) if( !exists( $ns->{ $var } ) );
    my $glob = \$ns->{ $var };
    if( Scalar::Util::reftype( $glob ) eq 'GLOB' )
    {
        if( $type eq 'SCALAR' )
        {
            return( defined( ${ *{$glob}{$type} } ) ? 1 : 0 );
        }
        else
        {
            return( defined( *{$glob}{$type} ) ? 1 : 0 );
        }
    }
    else
    {
        return( $type eq 'CODE' ? 1 : 0 );
    }
}
PERL
    # NOTE: _implement_freeze_thaw()
    _implement_freeze_thaw => <<'PERL',
sub _implement_freeze_thaw
{
    my $self = shift( @_ );
    my @classes = @_;
    foreach my $class ( @classes )
    {
        unless( defined( &{"${class}\::STORABLE_freeze"} ) )
        {
            no warnings 'once';
            *{"${class}\::STORABLE_freeze"} = sub
            {
                my $self = CORE::shift( @_ );
                my $serialiser = CORE::shift( @_ ) // '';
                my $class = CORE::ref( $self );
                my %hash  = %$self;
                # Return an array reference rather than a list so this works with Sereal and CBOR
                CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' || $serialiser eq 'CBOR' );
                # But Storable/Storable::Improved want a list with the first element being the serialised element
                CORE::return( $class, \%hash );
            };
        }
        
        unless( defined( &{"${class}\::STORABLE_thaw"} ) )
        {
            no warnings 'once';
            *{"${class}\::STORABLE_thaw"} = sub
            {
                # STORABLE_thaw would issue $cloning as the 2nd argument, while CBOR would issue
                # 'CBOR' as the second value.
                my( $self, undef, @args ) = @_;
                my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
                my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
                my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
                my $new;
                # Storable pattern requires to modify the object it created rather than returning a new one
                if( CORE::ref( $self ) )
                {
                    foreach( CORE::keys( %$hash ) )
                    {
                        $self->{ $_ } = CORE::delete( $hash->{ $_ } );
                    }
                    $new = $self;
                }
                else
                {
                    $new = CORE::bless( $hash => $class );
                }
                CORE::return( $new );
            };
        }
        
        unless( defined( &{"${class}\::FREEZE"} ) )
        {
            no warnings 'once';
            *{"${class}::FREEZE"} = sub
            {
                my $self = CORE::shift( @_ );
                my $serialiser = CORE::shift( @_ ) // '';
                my @args = &{"${class}::STORABLE_freeze"}( $self );
                CORE::return( \@args ) if( $serialiser eq 'Sereal' || $serialiser eq 'CBOR' );
                CORE::return( @args );
            };
        }

        unless( defined( &{"${class}::THAW"} ) )
        {
            no warnings 'once';
            *{"${class}::THAW"} = sub
            {
                my( $self, undef, @args ) = @_;
                my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
                $self = bless( {} => $self ) unless( ref( $self ) );
                CORE::return( &{"${class}::STORABLE_thaw"}( $self, undef, @$ref ) );
            };
        }
    }
}
PERL
    # NOTE: _is_empty()
    _is_empty => <<'PERL',
sub _is_empty
{
    my $self = shift( @_ );
    return(1) if( !@_ );
    return(1) if( !defined( $_[0] ) );
    if( (
            Scalar::Util::reftype( $_[0] ) eq 'SCALAR' && 
            !CORE::length( ${$_[0]} // '' )
        ) || 
        (
            !ref( $_[0] ) &&
            !CORE::length( $_[0] // '' )
        ) )
    {
        return(1);
    }
    elsif( Scalar::Util::reftype( $_[0] ) eq 'ARRAY' &&
        !scalar( @{$_[0]} ) )
    {
        return(1);
    }
    elsif( Scalar::Util::reftype( $_[0] ) eq 'HASH' &&
        Scalar::Util::blessed( $_[0] ) && 
        $_[0]->can( 'is_empty' ) && 
        ( $_[0]->is_empty ? 1 : 0 ) )
    {
        return(1);
    }
    elsif( ref( $_[0] ) eq 'HASH' && 
        !scalar( keys( %{$_[0]} ) ) )
    {
        return(1);
    }
    return(0);
}
PERL
    # NOTE: _is_overloaded()
    _is_overloaded => <<'PERL',
sub _is_overloaded
{
    my $self = shift( @_ );
    no overloading;
    # Nothing provided
    return if( !scalar( @_ ) );
    return if( !defined( $_[0] ) );
    return if( !Scalar::Util::blessed( $_[0] ) );
    return( overload::Overloaded( $_[0] ) ? 1 : 0 );
}
PERL
    # NOTE: _is_tty
    _is_tty => <<'PERL',
sub _is_tty
{
    return( -t( STDIN ) && ( -t( STDOUT ) || !( -f STDOUT || -c STDOUT ) ) );
}
PERL
    # NOTE: _list_symbols
    _list_symbols => <<'PERL',
sub _list_symbols
{
    # $type can be SCALAR, ARRAY, HASH or CODE (case insensitive)
    my $self = shift( @_ );
    my( $class, $type );
    if( !scalar( @_ ) )
    {
        $class = ( ref( $self ) || $self );
    }
    elsif( scalar( @_ ) >= 2 )
    {
        ( $class, $type ) = splice( @_, 0, 2 );
    }
    else
    {
        $class = shift( @_ );
    }
    if( $class !~ /^[a-zA-Z_][a-zA-Z0-9_]+(?:\:{2}[a-zA-Z0-9_]+)*$/ )
    {
        return( $self->error( "Invalid class name '$class'" ) );
    }
    no strict 'refs';
    my $ns = \%{$class . '::'};
    unless( defined( $type ) )
    {
        return( keys( %$ns ) );
    }
    $type = uc( $type );

    if( $type eq 'CODE' )
    {
        return( grep
        {
            Scalar::Util::reftype( \$ns->{ $_ } ) ne 'GLOB' ||
            defined( *{ $ns->{ $_ } }{CODE} )
        } keys( %$ns ) );
    }
    elsif( $type eq 'SCALAR' )
    {
        return( grep
        {
            Scalar::Util::reftype( \$ns->{ $_ } ) eq 'GLOB' &&
            defined( ${*{ $ns->{ $_ } }{SCALAR}} )
        } keys( %$ns ) );
    }
    else
    {
        return( grep
        {
            Scalar::Util::reftype( \$ns->{ $_ } ) eq 'GLOB' &&
            defined( *{$ns->{ $_ }}{ $type} )
        } keys( %$ns ) );
    }
}
PERL
    # NOTE: _on_error()
    _on_error => <<'PERL',
sub _on_error { return( shift->_set_get_code( '_on_error', @_ ) ); }
PERL
    # NOTE: _parse_timestamp()
    _parse_timestamp => <<'PERL',
# Ref:
# <https://en.wikipedia.org/wiki/Date_format_by_country>
sub _parse_timestamp
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    # No value was actually provided
    return if( !length( $str ) );
    my $params = $self->_get_args_as_hash( @_ );
    $str = "$str";
    my $this = $self->_obj2h;
    my $class = ref( $self ) || $self;
    # Load the regular expressions
    $self->_get_datetime_regexp;
    $self->_load_class( 'DateTime::Format::Strptime' ) || return( $self->pass_error );
    my $tz;
    # DateTime::TimeZone::Local will die ungracefully if the local timezeon is not set with the error:
    # "Cannot determine local time zone"
    if( !defined( $HAS_LOCAL_TZ ) )
    {
        $self->_load_class( 'DateTime::TimeZone' ) || return( $self->pass_error );
        # try-catch
        local $@;
        eval
        {
            $tz = DateTime::TimeZone->new( name => 'local' );
            $HAS_LOCAL_TZ = 1;
        };
        if( $@ )
        {
            $tz = DateTime::TimeZone->new( name => 'UTC' );
            $HAS_LOCAL_TZ = 0;
            warn( "Your system is missing key timezone components. ${class}::_parse_timestamp is reverting to UTC instead of local time zone.\n" ) if( $self->_warnings_is_enabled );
        }
        
        # try-catch
        local $@;
        eval
        {
            if( CORE::exists( $params->{tz} ) && CORE::defined( $params->{tz} ) && $params->{tz} )
            {
                $tz = DateTime::TimeZone->new( name => "$params->{tz}" );
            }
        };
        if( $@ )
        {
            warn( "Failed setting the specified time zone $params->{tz}: $@\n" ) if( $self->_warnings_is_enabled );
        }
    }
    else
    {
        # try-catch
        local $@;
        eval
        {
            $tz = ( CORE::exists( $params->{tz} ) && CORE::defined( $params->{tz} ) && $params->{tz} )
                ? DateTime::TimeZone->new( name => "$params->{tz}" )
                : DateTime::TimeZone->new( name => ( $HAS_LOCAL_TZ ? 'local' : 'UTC' ) );
        };
        if( $@ )
        {
            warn( "Error trying to set a DateTime object using ", ( $HAS_LOCAL_TZ ? 'local' : 'UTC' ), " time zone\n" );
            $tz = DateTime::TimeZone->new( name => 'UTC' );
        }
    }
    
    # my $tz = DateTime::TimeZone->new( name => 'Europe/Berlin' );
    unless( DateTime->can( 'TO_JSON' ) )
    {
        no warnings 'once';
        *DateTime::TO_JSON = sub
        {
            return( $_[0]->stringify );
        };
    }
    my $error = 0;
    # For some Japanese here
    use utf8;
    my $opt = 
    {
    pattern   => '%Y-%m-%d %T',
    time_zone => $tz->name,
    on_error => 'croak',
    };
    
    my $fmt =
    {
    pattern   => '%Y-%m-%d %T',
    locale    => 'en_GB',
    time_zone => $tz->name,
    };
    
    my $formatter = 'DateTime::Format::Strptime';
    
    my $roman2regular =
    {
    I   => 1,
    II  => 2,
    III => 3,
    IV  => 4,
    V   => 5,
    VI  => 6,
    VII => 7,
    VIII=> 8,
    IX  => 9,
    X   => 10,
    XI  => 11,
    XII => 12,
    i   => 1,
    ii  => 2,
    iii => 3,
    iv  => 4,
    v   => 5,
    vi  => 6,
    vii => 7,
    viii=> 8,
    ix  => 9,
    x   => 10,
    xi  => 11,
    xii => 12,
    };
    # (^(?=[MDCLXVI])M*(C[MD]|D?C{0,3})(X[CL]|L?X{0,3})(I[XV]|V?I{0,3})$)
    # <https://stackoverflow.com/a/36576402/4814971>
    # 
    # ^(I[VX]|VI{0,3}|I{1,3})|((X[LC]|LX{0,3}|X{1,3})(I[VX]|V?I{0,3}))|((C[DM]|DC{0,3}|C{1,3})(X[LC]|L?X{0,3})(I[VX]|V?I{0,3}))|(M+(C[DM]|D?C{0,3})(X[LC]|L?X{0,3})(I[VX]|V?I{0,3}))$
    # <https://stackoverflow.com/a/60469651/4814971>
    
    # Of course, when an era starts and another era ends, it is during the same Gregorian year, so we use the new era for the year start although it is perfectly correct to use the nth year for the year end as well, but that would mean two eras for the same year, and although for humans it is ok, for computing it does not work.
    # For example end of Meiji is in 1912 (45th year) which is also the first of the Taisho era
    # Ref: <http://www.ajnet.ne.jp/benri/conversion.hpml>
    
    # GNU PO file
    # 2019-10-03 19-44+0000
    # 2019-10-03 19:44:01+0000
    # 2001-03-12 17:07+JST
    # if( $str =~ /^(?<year>\d{4})(?<d_sep>\D)(?<month>\d{1,2})\D(?<day>\d{1,2})(?<sep>[\s\t]+)(?<hour>\d{1,2})(?<t_sep>\D)(?<minute>\d{1,2})(?:\D(?<second>\d{1,2}))?(?<tz>([+-])(\d{2})(\d{2}))$/ )
    if( $str =~ /^$PARSE_DATE_FRACTIONAL1_RE$/x )
    {
        my $re = { %+ };
        my @buff = ();
        my @buff_fmt = ();
        push( @buff, '%F %T' );
        # $fmt->{pattern} = join( $re->{d_sep}, qw( %Y %m %d ) ) . $re->{sep} . join( $re->{t_sep}, qw( %H %M ) );
        push( @buff_fmt, join( $re->{d_sep}, qw( %Y %m %d ) ) . $re->{sep} . join( $re->{t_sep}, qw( %H %M ) ) );
        if( length( $re->{second} ) )
        {
            # $fmt->{pattern} .= $re->{t_sep} . '%S';
            push( @buff_fmt, $re->{t_sep} . '%S' );
        }
        # $fmt->{pattern} .= '%z';
        # push( @buff_fmt, '%z' );
        $str = join( '-', @$re{qw( year month day )} ) . ' ' . join( ':', @$re{qw( hour minute )}, ( length( $re->{second} ) ? $re->{second} : '00' ) ) . ( $re->{tz} // '' );
        
        if( CORE::defined( $re->{tz1} ) || CORE::defined( $re->{tz2} ) )
        {
            if( CORE::defined( $re->{tz1} ) && length( $re->{tz1} ) )
            {
                $fmt->{time_zone} = $opt->{time_zone} = $re->{tz};
                my $tz_sign = substr( $re->{tz1}, 0, 1 );
                if( $tz_sign eq '+' || $tz_sign eq '-' )
                {
                    push( @buff, ( $re->{blank2} // '' ) . '%z' );
                    push( @buff_fmt, ( $re->{blank2} // '' ) . '%z' );
                    CORE::delete( $fmt->{time_zone} );
                    CORE::delete( $opt->{time_zone} );
                }
                else
                {
                    push( @buff_fmt, $re->{blank2} . $re->{tz1} );
                }
            }
            elsif( CORE::defined( $re->{tz2} ) && length( $re->{tz2} ) )
            {
                $self->_load_class( 'DateTime::TimeZone::Catalog::Extend' ) ||
                    warn( "Warning only: could not load module DateTime::TimeZone::Catalog::Extend: ", $self->error, "\n" ) if( $self->_warnings_is_enabled );
                my $map = DateTime::TimeZone::Catalog::Extend->zone_map;
                $opt->{zone_map} = $map;

                # try-catch
                local $@;
                eval
                {
                    $tz = DateTime::TimeZone->new( name => $re->{tz2} );
                };
                if( $@ )
                {
                    warn( "Warning only: error trying to set the time zone object using '$re->{tz2}': $@\n" ) if( $self->_warnings_is_enabled );
                }
                push( @buff, ( $re->{blank2} // '' ) . '%O' );
                push( @buff_fmt, ( $re->{blank2} // '' ) . $re->{tz2} );
                $opt->{time_zone} = $fmt->{time_zone} = $tz->name;
            }
        }
        # $opt->{pattern} = '%F %T%z';
        $opt->{pattern} = join( '', @buff );
        $fmt->{pattern} = join( '', @buff_fmt );
    }
    # 2019-06-19 23:23:57.000000000+0900
    # From PostgreSQL: 2019-06-20 11:02:36.306917+09
    # ISO 8601: 2019-06-20T11:08:27
    # elsif( $str =~ /^(?<year>\d{4})(?<d_sep>[-|\/])(?<month>\d{1,2})[-|\/](?<day>\d{1,2})(?<sep>[[:blank:]]+|T)(?<time>\d{1,2}:\d{1,2}:\d{1,2})(?:\.(?<milli>\d+))?(?<tz>(?:\+|\-)\d{2,4})?$/ )
    elsif( $str =~ /^$PARSE_DATE_WITH_MILI_SECONDS_RE$/x )
    {
        my $re = { %+ };
        $opt->{pattern} = join( $re->{d_sep}, qw( %Y %m %d ) ) . $re->{sep} . ( defined( $re->{time_short} ) ? '%H:%M' : '%T' );
        $str = join( $re->{d_sep}, @$re{qw( year month day )} ) . $re->{sep} . ( defined( $re->{time_short} ) ? $re->{time_short} : $re->{time} );
        if( length( $re->{milli} ) )
        {
            $opt->{pattern} .= '.%' . length( $re->{milli} ) . 'N';
            $str .= '.' . $re->{milli};
        }
        $fmt->{pattern} = $opt->{pattern};
        
        if( length( $re->{tz} ) )
        {
            $opt->{pattern} .= '%z';
            $re->{tz} .= '00' if( length( $re->{tz} ) == 3 );
            $str .= $re->{tz};
            $fmt->{pattern} .= '%z';
            $fmt->{time_zone} = $opt->{time_zone} = $re->{tz};
        }
        elsif( length( $re->{tz_utc} // '' ) )
        {
            $str .= $re->{tz_utc};
            $opt->{pattern} .= 'Z';
            $fmt->{pattern} .= 'Z';
            $fmt->{time_zone} = $opt->{time_zone} = 'UTC';
        }
    }
    # From SQLite: 2019-06-20 02:03:14
    # From MySQL: 2019-06-20 11:04:01
    elsif( $str =~ /^(?<year>\d{4})(?<d_sep>[-|\/])(?<month>\d{1,2})[-|\/](?<day>\d{1,2})(?<sep>[[:blank:]]+|T)(?<time>\d{1,2}:\d{1,2}:\d{1,2})$/ )
    {
        my $re = { %+ };
        # $opt->{pattern} = $fmt->{pattern} = join( $re->{d_sep}, qw( %Y %m %d ) ) . $re->{sep} . $re->{time};
        $opt->{pattern} = $fmt->{pattern} = join( $re->{d_sep}, qw( %Y %m %d ) ) . $re->{sep} . '%T';
        $str = join( $re->{d_sep}, @$re{qw( year month day )} ) . $re->{sep} . $re->{time};
        my $dt = DateTime->now( time_zone => $tz );
        my $offset = $dt->offset;
        # e.g. 9 or possibly 9.5
        my $offset_hour = ( $offset / 3600 );
        # e.g. 9.5 => 0.5 * 60 = 30
        my $offset_min  = ( $offset_hour - CORE::int( $offset_hour ) ) * 60;
        $str .= sprintf( '%+03d%02d', $offset_hour, $offset_min );
        $opt->{pattern} .= '%z';
    }
    # e.g. Sun, 06 Oct 2019 06:41:11 GMT
    # elsif( $str =~ /^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),[[:blank:]]+(?<day>\d{2})[[:blank:]]+(?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[[:blank:]]+(?<year>\d{4})[[:blank:]]+(?<hour>\d{2}):(?<minute>\d{2}):(?<second>\d{2})[[:blank:]]+GMT$/ )
    elsif( $str =~ /^$PARSE_DATE_HTTP_RE$/x )
    {
        my $re = { %+ };
        $opt->{pattern} = $fmt->{pattern} = q{%a, %d %b %Y %T GMT};
        $fmt->{time_zone} = $opt->{time_zone} = 'UTC';
    }
    # 12 March 2001 17:07:30 JST
    # 12-March-2001 17:07:30 JST
    # 12/March/2001 17:07:30 JST
    # 12 March 2001 17:07
    # 12 March 2001 17:07 JST
    # 12 March 2001 17:07:30+0900
    # 12 March 2001 17:07:30 +0900
    # Monday, 12 March 2001 17:07:30 JST
    # Monday, 12 Mar 2001 17:07:30 JST
    # 03/Feb/1994:00:00:00 0000
    elsif( $str =~ /^$PARSE_DATE_NON_STDANDARD_RE$/x )
    {
        my $re = { %+ };
        my @buff = ();
        my @buff_fmt = ();
        if( $re->{wd} || $re->{wd_long} )
        {
            # push( @buff, ( $re->{wd} || $re->{wd_long} ) );
            push( @buff, ( defined( $re->{wd} ) ? '%a' : '%A' ) );
            push( @buff, ',' ) if( $re->{wd_comma} );
            push( @buff, $re->{blank0} ) if( defined( $re->{blank0} ) );
        }
        push( @buff, length( $re->{day} ) > 1 ? '%d' : '%e' );
        push( @buff, $re->{sep1} );
        push( @buff, ( $re->{month} ? '%b' : '%B' ) );
        push( @buff, $re->{sep2} );
        push( @buff, length( $re->{year} ) == 2 ? '%y' : '%Y' );
        push( @buff, $re->{blank1} );
        if( $re->{hour} && $re->{minute} && $re->{second} )
        {
            push( @buff, '%T' );
        }
        elsif( $re->{hour} && $re->{minute} )
        {
            push( @buff, '%H:%M' );
        }
        
        push( @buff_fmt, @buff );
        if( CORE::defined( $re->{tz} ) || CORE::defined( $re->{tz2} ) )
        {
            if( CORE::defined( $re->{tz1} ) && length( $re->{tz1} ) )
            {
                my $tz_sign = substr( $re->{tz1}, 0, 1 );
                if( $tz_sign eq '+' || $tz_sign eq '-' )
                {
                    push( @buff, ( $re->{blank2} // '' ) . '%z' );
                    push( @buff_fmt, ( $re->{blank2} // '' ) . '%z' );
                    CORE::delete( $fmt->{time_zone} );
                    CORE::delete( $opt->{time_zone} );
                }
                else
                {
                    push( @buff_fmt, $re->{blank2} . $re->{tz1} );
                }
            }
            elsif( CORE::defined( $re->{tz2} ) && length( $re->{tz2} ) )
            {
                $self->_load_class( 'DateTime::TimeZone::Catalog::Extend' ) ||
                    warn( "Warning only: could not load module DateTime::TimeZone::Catalog::Extend: ", $self->error, "\n" ) if( $self->_warnings_is_enabled );
                my $map = DateTime::TimeZone::Catalog::Extend->zone_map;
                $opt->{zone_map} = $map;

                # try-catch
                local $@;
                eval
                {
                    $tz = DateTime::TimeZone->new( name => $re->{tz2} );
                };
                if( $@ )
                {
                    warn( "Warning only: error trying to set the time zone object using '$re->{tz2}': $@\n" ) if( $self->_warnings_is_enabled );
                }
                push( @buff, ( $re->{blank2} // '' ) . '%O' );
                push( @buff_fmt, ( $re->{blank2} // '' ) . $re->{tz2} );
                $opt->{time_zone} = $fmt->{time_zone} = $tz->name;
            }
        }
        $opt->{pattern} = join( '', @buff );
        $fmt->{pattern} = join( '', @buff_fmt );
    }
    # Fri Mar 25 12:18:36 2011
    # Fri Mar 25 12:16:25 ADT 2011
    # Fri Mar 25 2011
    elsif( $str =~ /^$PARSE_DATE_NON_STDANDARD2_RE$/x )
    {
        my $re = { %+ };
        my @buff = ();
        my @buff_fmt = ();
        if( $re->{wd} || $re->{wd_long} )
        {
            push( @buff, ( defined( $re->{wd} ) ? '%a' : '%A' ) );
            push( @buff, ',' ) if( $re->{wd_comma} );
            push( @buff, $re->{blank1} );
        }
        push( @buff, ( $re->{month} ? '%b' : '%B' ) );
        push( @buff, $re->{blank2} );
        push( @buff, length( $re->{day} ) > 1 ? '%d' : '%e' );
        push( @buff, $re->{blank3} );
        if( defined( $re->{time} ) )
        {
            push( @buff, '%T' );
            push( @buff, $re->{blank4} );
        }
        push( @buff_fmt, @buff );
        if( length( $re->{tz} // '' ) )
        {
            $self->_load_class( 'DateTime::TimeZone::Catalog::Extend' ) ||
                warn( "Warning only: could not load module DateTime::TimeZone::Catalog::Extend: ", $self->error, "\n" ) if( $self->_warnings_is_enabled );
            my $map = DateTime::TimeZone::Catalog::Extend->zone_map;
            $opt->{zone_map} = $map;

            # try-catch
            local $@;
            eval
            {
                $tz = DateTime::TimeZone->new( name => $re->{tz} );
            };
            if( $@ )
            {
                warn( "Warning only: error trying to set the time zone object using '$re->{tz}': $@\n" ) if( $self->_warnings_is_enabled );
            }
            push( @buff, '%O' . ( $re->{blank5} // '' ) );
            push( @buff_fmt, $re->{tz} . ( $re->{blank5} // '' ) );
            $opt->{time_zone} = $fmt->{time_zone} = $tz->name;
        }
        push( @buff, length( $re->{year} ) == 2 ? '%y' : '%Y' );
        push( @buff_fmt, length( $re->{year} ) == 2 ? '%y' : '%Y' );
        $opt->{pattern} = join( '', @buff );
        $fmt->{pattern} = join( '', @buff_fmt );
    }
    # 2019-06-20
    # 2019/06/20
    # 2016.04.22
    # elsif( $str =~ /^(?<year>\d{4})(?<d_sep>\D)(?<month>\d{1,2})\D(?<day>\d{1,2})$/ )
    elsif( $str =~ /^$PARSE_DATE_ONLY_RE$/x )
    {
        my $re = { %+ };
        $str = join( $re->{d_sep}, @$re{qw( year month day )} );
        $opt->{pattern} = $fmt->{pattern} = join( $re->{d_sep}, qw( %Y %m %d ) );
    }
    # 2014, Feb 17
    # elsif( $str =~ /^(?<year>\d{4}),(?<sep1>[[:blank:]\h]+)(?<month>[a-zA-Z]{3,4})(?<sep2>[[:blank:]\h]+)(?<day>\d{1,2})$/ )
    elsif( $str =~ /^$PARSE_DATE_ONLY_US_SHORT_RE$/x )
    {
        my $re = { %+ };
        $opt->{pattern} = $fmt->{pattern} = '%Y,' . $re->{sep1} . '%b' . $re->{sep2} . '%d';
    }
    # 17 Feb, 2014
    # elsif( $str =~ /^(?<day>\d{1,2})(?<sep1>[[:blank:]\h]+)(?<month>[a-zA-Z]{3,4}),(?<sep2>[[:blank:]\h]+)(?<year>\d{4})$/ )
    elsif( $str =~ /^$PARSE_DATE_ONLY_EU_SHORT_RE$/x )
    {
        my $re = { %+ };
        $opt->{pattern} = $fmt->{pattern} = '%d' . $re->{sep1} . '%b,' . $re->{sep2} . '%Y';
    }
    # February 17, 2009
    # elsif( $str =~ /^(?<month>[a-zA-Z]{3,9})(?<sep1>[[:blank:]\h]+)(?<day>\d{1,2}),(?<sep2>[[:blank:]\h]+)(?<year>\d{4})$/ )
    elsif( $str =~ /^$PARSE_DATE_ONLY_US_LONG_RE$/x )
    {
        my $re = { %+ };
        $opt->{pattern} = $fmt->{pattern} = '%B' . $re->{sep1} . '%d,' . $re->{sep2} . '%Y';
    }
    # 15 July 2021
    # elsif( $str =~ /^(?<day>\d{1,2})(?<sep1>[[:blank:]\h]+)(?<month>[a-zA-Z]{3,9})(?<sep2>[[:blank:]\h]+)(?<year>\d{4})$/ )
    elsif( $str =~ /^$PARSE_DATE_ONLY_EU_LONG_RE$/x )
    {
        my $re = { %+ };
        $opt->{pattern} = $fmt->{pattern} = '%d' . $re->{sep1} . '%B' . $re->{sep2} . '%Y';
    }
    # 22.04.2016
    # 22-04-2016
    # 17. 3. 2018.
    # elsif( $str =~ /^(?<day>\d{1,2})(?<sep>\D)(?<blank1>[[:blank:]\h]+)?(?<month>\d{1,2})\D(?<blank2>[[:blank:]\h]+)?(?<year>\d{4})(?<trailing_dot>\.)?$/ )
    elsif( $str =~ /^$PARSE_DATE_DOTTED_ONLY_EU_RE$/x )
    {
        my $re = { %+ };
        # $opt->{pattern} = $fmt->{pattern} = join( $re->{sep}, qw( %d %m %Y ) );
        $opt->{pattern} = $fmt->{pattern} = "%d$re->{sep}" . ( $re->{blank1} // '' ) . "%m$re->{sep}" . ( $re->{blank2} // '' ) . "%Y" . ( $re->{trailing_dot} // '' );
        $fmt->{leading_zero} = 1 if( substr( $re->{day}, 0, 1 ) == 0 || substr( $re->{month}, 0, 1 ) == 0 );
        {
            package
                DateTime::Format::DMY;
            sub new
            {
                my $this = shift( @_ );
                my $hash = { @_ };
                return( bless( $hash => ( ref( $this ) || $this ) ) );
            }
            sub format_datetime
            {
                my( $self, $dt ) = @_;
                my $d = $dt->day;
                my $m = $dt->month;
                my $y = $dt->year;
                my $pat = $self->{pattern};
                $pat =~ s/\%d/$d/;
                $pat =~ s/\%m/$m/;
                $pat =~ s/\%Y/$y/;
                return( $pat );
            }
        }
        if( $fmt->{leading_zero} )
        {
            # We do not want it to interfere with the module supported parameters
            delete( $fmt->{leading_zero} );
        }
        else
        {
            $formatter = 'DateTime::Format::DMY';
        }
    }
    # 17.III.2020
    # 17. III. 2018.
    # elsif( $str =~ /^(?<day>\d{1,2})\.(?<blank1>[[:blank:]\h]+)?(?<month>XI{0,2}|I{0,3}|IV|VI{0,3}|IX)\.(?<blank2>[[:blank:]\h]+)?(?<year>\d{4})(?<trailing_dot>\.)?$/i )
    elsif( $str =~ /^$PARSE_DATE_ROMAN_RE$/xi )
    {
        my $re = { %+ };
        $re->{month} = $roman2regular->{ $re->{month} };
        $str = join( '-', @$re{qw( year month day )} );
        $opt->{pattern} = '%F';
        $fmt->{pattern} = "%d." . ( $re->{blank1} // '' ) . "%m." . ( $re->{blank2} // '' ) . "%Y" . ( $re->{trailing_dot} // '' );
        {
            package
                DateTime::Format::RomanDDXXXYYYY;
            our $ROMAN2REGULAR = $roman2regular;
            sub new
            {
                my $this = shift( @_ );
                my $hash = { @_ };
                return( bless( $hash => ( ref( $this ) || $this ) ) );
            }
            
            sub parse_datetime {}
            
            sub parse_duration {}
            
            sub format_duration {}
            
            sub format_datetime
            {
                my( $self, $dt ) = @_;
                my $d = $dt->day;
                my $m = $dt->month;
                my $y = $dt->year;
                foreach my $k ( keys( %$ROMAN2REGULAR ) )
                {
                    # Skip lowercase ones
                    next if( $k =~ /^[a-z]+$/ );
                    if( $ROMAN2REGULAR->{ $k } == $m )
                    {
                        $m = $k;
                        last;
                    }
                }
                my $pat = $self->{pattern};
                $pat =~ s/\%d/$d/;
                $pat =~ s/\%m/$m/;
                $pat =~ s/\%Y/$y/;
                return( $pat );
            }
        }
        $formatter = 'DateTime::Format::RomanDDXXXYYYY';
    }
    # 20030613
    # elsif( $str =~ /^(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})$/ )
    elsif( $str =~ /^$PARSE_DATE_DIGITS_ONLY_RE$/x )
    {
        my $re = { %+ };
        $opt->{pattern} = '%F';
        $str = join( '-', @$re{qw( year month day )} );
        $fmt->{pattern} = join( '', qw( %Y %m %d ) );
        # $opt->{pattern} = $fmt->{pattern} = join( '', qw( %d %m %Y ) );
    }
    # 2021年7月14日
    # 令和3年7月14日
    # elsif( $str =~ /^(?<era>\p{Han})?(?<year>\d{1,4})年(?<month>\d{1,2})月(?<day>\d{1,2})日$/ )
    elsif( $str =~ /^$PARSE_DATETIME_JP_RE$/x )
    {
        my $re = { %+ };
        use utf8;
        $self->_load_class( 'DateTime::Format::JP' ) || return( $self->pass_error );
        my $pattern;
        if( defined( $re->{era} ) && $re->{era} )
        {
            $pattern = '%E%y年%m月%d日';
        }
        else
        {
            $pattern = '%Y年%m月%d日';
        }
        
        if( $re->{time} )
        {
            $pattern .= '%H' . ( $re->{hour_suffix} // '' );
            if( $re->{minute} )
            {
                $pattern .= ( $re->{hour_sep} // '' ) . '%M' . ( $re->{minute_suffix} // '' );
            }
            if( $re->{second} )
            {
                $pattern .= ( $re->{minute_sep} // '' ) . '%S' . ( $re->{second_suffix} // '' );
            }
        }
        
        my $use_full_width = 0;
        if( $re->{year} =~ /^[\x{FF10}-\x{FF19}]+$/ )
        {
            $use_full_width++;
        }
        
        my $parser;
        # try-catch
        local $@;
        eval
        {
            $parser = DateTime::Format::JP->new(
                pattern => $pattern,
                time_zone => $tz,
                ( $use_full_width ? ( zenkaku => 1 ) : () ),
            );
        };
        if( $@ )
        {
            warn( "Your system is missing key timezone components. ${class}::_parse_timestamp is reverting to UTC instead of local time zone.\n" ) if( $self->_warnings_is_enabled );
            $parser = DateTime::Format::JP->new(
                pattern => $pattern,
                time_zone => 'UTC',
                ( $use_full_width ? ( zenkaku => 1 ) : () ),
            );
        }
        
        # try-catch
        my $dt;
        eval
        {
            $dt = $parser->parse_datetime( $str );
            $dt->set_formatter( $parser );
        };
        if( $@ )
        {
            return( $self->error( "An error occurred while trying to use DateTime::Format::JP: $@" ) );
        }
        return( $dt );
    }
    # <https://en.wikipedia.org/wiki/Date_format_by_country>
    # Possibly followed by a dot and some integer for milliseconds as provided by Time::HiRes
    elsif( $str =~ /^$PARSE_DATE_TIMESTAMP_RE$/x )
    {
        my $re = { %+ };
        # try-catch
        local $@;
        my $dt;
        eval
        {
            $dt = DateTime->from_epoch( epoch => $str, time_zone => $tz );
            $opt->{pattern} = ( CORE::index( $str, '.' ) != -1 ? '%s.%' . CORE::length( $re->{milli} ) . 'N' : '%s' );
            my $strp = DateTime::Format::Strptime->new( %$opt );
            $dt->set_formatter( $strp );
        };
        if( $@ )
        {
            return( $self->error( "An error occurred while parsing the time stamp based on the unix timestamp '$str': $@" ) );
        }
        return( $dt );
    }
    elsif( $str =~ /^$PARSE_DATETIME_RELATIVE_RE$/x )
    {
        my( $num, $unit ) = ( $1, $2 );
        $unit = 's' if( !length( $unit ) );
        my $interval =
        {
            's' => 1,
            'm' => 60,
            'h' => 3600,
            'D' => 86400,
            'd' => 86400,
            'M' => 86400 * 30,
            'Y' => 86400 * 365,
            'y' => 86400 * 365,
        };
        my $offset = ( $interval->{ $unit } || 1 ) * int( $num );
        my $ts = time() + $offset;
        my $dt;
        # try-catch
        local $@;
        eval
        {
            $dt = DateTime->from_epoch( epoch => $ts, time_zone => $tz );
        };
        if( $@ )
        {
            # Exception raised by DateTime::TimeZone::Local
            if( $@ =~ /Cannot[[:blank:]\h]+determine[[:blank:]\h]+local[[:blank:]\h]+time[[:blank:]\h]+zone/i )
            {
                warn( "Your system is missing key timezone components. ${class}::_parse_timestamp is reverting to UTC instead of local time zone.\n" ) if( $self->_warnings_is_enabled );
                $dt = DateTime->from_epoch( epoch => $ts, time_zone => 'UTC' );
                return( $dt );
            }
            else
            {
                return( $self->error( "An error occurred while trying to create a DateTime object with the relative timestamp '$str' that translated into the unix time stamp '$ts': $@" ) );
            }
        }
        return( $dt );
    }
    elsif( lc( $str ) eq 'now' )
    {
        $dt = DateTime->now( time_zone => $tz );
        return( $dt );
    }
    else
    {
        return( '' );
    }
    
    my $dt;
    # try-catch
    local $@;
    eval
    {
        my $strp = DateTime::Format::Strptime->new( %$opt );
        $dt = $strp->parse_datetime( $str );
        my $strp2 = $formatter->new( %$fmt );
        # To enable the date string to be stringified to its original format
        $dt->set_formatter( $strp2 ) if( $dt );
    };
    if( $@ )
    {
        return( $self->error( "Error creating a DateTime object with the timestamp '$str': $@" ) );
    }
    return( $dt );
}
PERL
    # NOTE: _set_get_class_array_object
    _set_get_class_array_object => <<'PERL',
sub _set_get_class_array_object
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $def   = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $ref = $self->_set_get_class_array( $field, $def, @_ );

    if( ref( $def ) ne 'HASH' )
    {
        CORE::warn( "Warning only: dynamic class field definition hash ($def) for field \"$field\" is not a hash reference." );
        return;
    }
    $def->{wantlist} //= 0;

    if( !$data->{ $field } || !$self->_is_object( $data->{ $field } ) )
    {
        require Module::Generic::Array;
        my $o = Module::Generic::Array->new( ( defined( $data->{ $field } ) && CORE::length( $data->{ $field } ) ) ? $data->{ $field } : [] );
        $data->{ $field } = $o;
    }
    
    if( $def->{wantlist} && want( 'LIST' ) )
    {
        return( $data->{ $field } ? $data->{ $field }->list : () );
    }
    else
    {
        return( $data->{ $field } );
    }
}
PERL
    # NOTE: _set_get_datetime()
    _set_get_datetime => <<'PERL',
sub _set_get_datetime : lvalue
{
    my $self  = shift( @_ );
    my $field = shift( @_ );
    my $this  = $self->_obj2h;
    my $data  = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    my $class = ref( $self ) || $self;

    my $opts;
    if( ref( $field ) eq 'HASH' )
    {
        my $def = { %$field };
        if( CORE::exists( $def->{field} ) && defined( $def->{field} ) && CORE::length( $def->{field} ) )
        {
            $field = CORE::delete( $def->{field} );
        }
        else
        {
            warn( "No 'field' parameter provided in calling _set_get_datetime\n" ) if( $self->_warnings_is_enabled );
        }
        # The rest of the options are passed to _parse_timestamp() as parameters
        $opts = $def;
    }

    my $process = sub
    {
        my $time = shift( @_ );
        my $now;
        if( Scalar::Util::blessed( $time ) )
        {
            return( $self->error( "Object provided as value for $field, but this is not a DateTime or a Module::Generic::DateTime object" ) ) if( !$time->isa( 'DateTime' ) && !$time->isa( 'Module::Generic::DateTime' ) );
            $data->{ $field } = $time;
            return( $data->{ $field } );
        }
        elsif( $time =~ /^\d+$/ && $time !~ /^\d{1,10}$/ )
        {
            return( $self->error( "DateTime value ($time) provided for field $field does not look like a unix timestamp" ) );
        }
        # Parsed successfully and transformed into a DateTime object
        elsif( $now = $self->_parse_timestamp( $time, ( CORE::defined( $opts ) ? ( %$opts ) : () ) ) )
        {
            # Found a parsed datetime value
            # $data->{ $field } = $now;
            # return( $now );
        }
        
        unless( Scalar::Util::blessed( $now ) && ( $now->isa( 'DateTime' ) || $now->isa( 'Module::Generic::DateTime' ) ) )
        {
            $self->_load_class( 'DateTime' ) || return( $self->pass_error );
            if( !defined( $HAS_LOCAL_TZ ) )
            {
                # try-catch
                local $@;
                eval
                {
                    $now = DateTime->from_epoch(
                        epoch => $time,
                        time_zone => 'local',
                    );
                    $HAS_LOCAL_TZ = 1;
                };
                if( $@ )
                {
                    warn( "Your system is missing key timezone components. ${class}::_set_get_datetime is reverting to UTC instead of local time zone -> $@\n" );
                    $now = DateTime->from_epoch(
                        epoch => $time,
                        time_zone => 'UTC',
                    );
                    $HAS_LOCAL_TZ = 0;
                }
                
                if( CORE::defined( $opts ) && 
                    CORE::exists( $opts->{tz} ) && 
                    CORE::defined( $opts->{tz} ) && 
                    CORE::length( $opts->{tz} ) )
                {
                    $now = DateTime->from_epoch(
                        epoch => $time,
                        time_zone => "$opts->{tz}",
                    );
                }
            }
            else
            {
                # try-catch
                local $@;
                eval
                {
                    $now = ( CORE::defined( $opts ) && CORE::exists( $opts->{tz} ) && CORE::defined( $opts->{tz} ) && CORE::length( $opts->{tz} ) )
                        ? DateTime->from_epoch( epoch => $time, time_zone => "$opts->{tz}" )
                        : DateTime->from_epoch( epoch => $time, time_zone => ( $HAS_LOCAL_TZ ? 'local' : 'UTC' ) );
                };
                if( $@ )
                {
                    warn( "Error trying to set a DateTime object using ", ( ( CORE::defined( $opts ) && CORE::exists( $opts->{tz} ) && CORE::defined( $opts->{tz} ) && CORE::length( $opts->{tz} ) ) ? $opts->{tz} : ( $HAS_LOCAL_TZ ? 'local' : 'UTC' ) ), " time zone -> ", $@->as_string );
                    $now = DateTime->from_epoch( epoch => $time, time_zone => 'UTC' );
                }
            }
        }
        
        # We only set a default formatter if one was not set already
        unless( $now->formatter )
        {
            $self->_load_class( 'DateTime::Format::Strptime' ) || return( $self->pass_error );
            # try-catch
            local $@;
            eval
            {
                my $strp = DateTime::Format::Strptime->new(
                    pattern => '%s',
                    locale => 'en_GB',
                );
                $now->set_formatter( $strp );
            };
            if( $@ )
            {
                warn( "Error creating DateTime object: $@\n" );
            }
        }
        return( $now );
    };
    
    return( $self->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            # So that a call to this field will not trigger an error: "Can't call method "xxx" on an undefined value"
            if( !$data->{ $field } )
            {
                return;
            }
            elsif( defined( $data->{ $field } ) && 
                   length( $data->{ $field } ) && 
                   !$self->_is_a( $data->{ $field }, 'DateTime' ) )
            {
                my $now = $process->( $data->{ $field } ) || return( $self->pass_error );
                $data->{ $field } = $now;
            }
            return( $data->{ $field } );
        },
        set => sub
        {
            my $self = shift( @_ );
            my $arg = shift( @_ );
            my $time = $arg;
            if( !defined( $time ) )
            {
                return( $data->{ $field } = $time );
            }
            my $now = $process->( $time ) || do
            {
                return( $self->pass_error );
            };
            $data->{ $field } = $now;

            # So that a call to this field will not trigger an error: "Can't call method "xxx" on an undefined value"
            if( !$data->{ $field } )
            {
                return;
            }
            elsif( defined( $data->{ $field } ) && 
                   length( $data->{ $field } ) && 
                   !$self->_is_a( $data->{ $field }, 'DateTime' ) )
            {
                my $now = $process->( $data->{ $field } ) || return( $self->pass_error );
                $data->{ $field } = $now;
            }
            return( $data->{ $field } );
        }
    }, @_ ) );
}
PERL
    # NOTE: _set_symbol
    _set_symbol => <<'PERL',
# $o->_set_symbol(
# class => 'Foo::Bar',
# variable => '$some_var',
# value => 'some value',
# filename => '/some/where/file.pl',
# start_line => 10,
# end_line => 15,
# );
sub _set_symbol
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !CORE::exists( $opts->{class} ) )
    {
        $opts->{class} = ( ref( $self ) || $self );
    }
    
    if( !defined( $opts->{class} ) ||
        !CORE::length( $opts->{class} // '' ) )
    {
        return( $self->error( "No class name was provided to add symbol." ) );
    }
    elsif( $opts->{class} !~ /^[a-zA-Z_][a-zA-Z0-9_]+(?:\:{2}[a-zA-Z0-9_]+)*$/ )
    {
        return( $self->error( "Invalid class name '$opts->{class}'" ) );
    }
    elsif( !CORE::exists( $opts->{variable} ) ||
        !defined( $opts->{variable} ) ||
        !CORE::length( $opts->{variable} // '' ) )
    {
        return( $self->error( "No variable was aprovided." ) );
    }
    my $class = $opts->{class};
    my $var = $opts->{variable};
    no strict 'refs';
    my $ns = \%{$class . '::'};
    require Symbol;
    my $map = 
    {
    '$' => 'SCALAR',
    '@' => 'ARRAY',
    '%' => 'HASH',
    '&' => 'CODE',
    '*' => 'GLOB',
    };
    my $defaults = 
    {
        ARRAY => [],
        CODE => sub{},
        HASH => {},
        GLOB => Symbol::geniosym,
        SCALAR => \undef,
    };
    my( $name, $sigil, $type );
    if( CORE::exists( $opts->{type} ) &&
        defined( $opts->{type} ) &&
        CORE::exists( $defaults->{uc( $opts->{type} )} ) )
    {
        $sigil = substr( $name = $var, 0, 1, '' );
        $type = $opts->{type};
    }
    elsif( exists( $map->{ substr( $var, 0, 1 ) } ) )
    {
        $sigil = substr( $name = $var, 0, 1, '' );
        $type = $map->{ $sigil };
    }
    else
    {
        # $type = $map->{ '' };
        return( $self->error( "Unsupported variable ${var}. You can only set array, hash, scalar, code or glob" ) );
    }
    
    my $value;
    if( CORE::exists( $opts->{value} ) &&
        defined( $opts->{value} ) )
    {
        my $refval = Scalar::Util::reftype( $opts->{value} );
        if( $type eq 'SCALAR' &&
            ( $refval eq 'HASH' || $refval eq 'ARRAY' || $refval eq 'CODE' ) )
        {
            $type = $refval;
            $value = \$opts->{value};
        }
        else
        {
            $value = $opts->{value};
        }
        
        if( $type eq 'ARRAY' ||
              $type eq 'CODE' ||
              $type eq 'HASH' ||
              $type eq 'GLOB' )
        {
            return( $self->error( "Value of type ${refval} provided for ${var} is incompatible." ) ) if( $refval ne $type );
        }
        elsif( $refval ne 'SCALAR' &&
            $refval ne 'REF' &&
            $refval ne 'LVALUE' &&
            $refval ne 'REGEXP' &&
            $refval ne 'VSTRING' )
        {
            return( $self->error( "Value of type ${refval} provided for ${var} cannot be used." ) );
        }
        
        # cheap fail-fast check for PERLDBf_SUBLINE and '&'
        if( $^P && 
            ( $^P & 0x10 ) && 
            $sigil eq '&' )
        {
            no warnings 'once';
            my $filename = $opts->{filename};
            my $start_line = $opts->{start_line};
            ( $filename, $start_line ) = (caller)[1,2] if( !defined( $filename ) );
            my $end_line = $opts->{end_line} || ( $start_line ||= 0 );
            # <http://perldoc.perl.org/perldebguts.html#Debugger-Internals>
            $DB::sub{ $class . '::' . $name } = "${filename}:${start_line}-${end_line}";
        }
    }
    
    if( defined( $value ) )
    {
        no strict 'refs';
        no warnings 'redefine';
        *{ $class . '::' . $name } = ref( $value )
            ? $value
            : \$value;
    }
    else
    {
        no strict 'refs';
        # Broken ISA assignment
        if( $] < 5.012 && 
            $name eq 'ISA' )
        {
            *{ $class . '::' . $name };
        }
        else
        {
            *{ $class . '::' . $name } = $defaults->{ $type };
        }
    }
}
PERL
    };
}

sub DEBUG
{
    my $self = shift( @_ );
    my $pkg  = ref( $self ) || $self;
    my $this = $self->_obj2h;
    no strict 'refs';
    return( ${ $pkg . '::DEBUG' } );
}

# NOTE: Works with CBOR and Sereal <https://metacpan.org/pod/Sereal::Encoder#FREEZE/THAW-CALLBACK-MECHANISM>
sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my $ref = $self->_obj2h;
    my %hash = %$ref;
    $hash{_is_glob} = ( Scalar::Util::reftype( $self ) // '' ) eq 'GLOB' ? 1 : 0;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

# sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

# sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: Works with CBOR and Sereal <https://metacpan.org/pod/Sereal::Encoder#FREEZE/THAW-CALLBACK-MECHANISM>
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $is_glob = CORE::delete( $hash->{_is_glob} );
    my $new;
    if( $is_glob )
    {
        $new = CORE::ref( $self ) ? $self : $class->new_glob;
        foreach( CORE::keys( %$hash ) )
        {
            *$new->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
    }
    else
    {
        # Storable pattern requires to modify the object it created rather than returning a new one
        if( CORE::ref( $self ) )
        {
            foreach( CORE::keys( %$hash ) )
            {
                $self->{ $_ } = CORE::delete( $hash->{ $_ } );
            }
            $new = $self;
        }
        else
        {
            $new = bless( $hash => $class );
        }
    }
    CORE::return( $new );
}

sub VERBOSE
{
    my $self = shift( @_ );
    my $pkg  = ref( $self ) || $self;
    my $this = $self->_obj2h;
    no strict 'refs';
    return( ${ $pkg . '::VERBOSE' } );
}

# NOTE:: AUTOLOAD
sub AUTOLOAD : lvalue
{
    my $self;
    $self = shift( @_ ) if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Module::Generic' ) );
    my( $class, $meth );
    $class = ref( $self ) || $self;
    # Leave this commented out as we need it a little bit lower
    my( $pkg, $file, $line ) = caller();
    my $sub = ( caller(1) )[3];
    no overloading;
    no strict 'refs';
    if( CORE::defined( $sub ) && $sub eq 'Module::Generic::AUTOLOAD' )
    {
        my $trace = $self->_get_stack_trace;
        my $mesg = "Module::Generic::AUTOLOAD (called at line '$line') is looping for autoloadable method '$AUTOLOAD' and args '" . join( "', '", @_ ) . "'. Trace is: " . $trace->as_string;
        if( $MOD_PERL )
        {
            # try-catch
            local $@;
            eval
            {
                my $r = Apache2::RequestUtil->request;
                $r->log->debug( $mesg );
            };
            if( $@ )
            {
                print( STDERR "Error trying to get the global Apache2::ApacheRec: $@\n" );
            }
        }
        else
        {
            print( $stderr $mesg, "\n" );
        }
        exit(0);
    }
    $meth = $AUTOLOAD;
    if( CORE::index( $meth, '::' ) != -1 )
    {
        my $idx = rindex( $meth, '::' );
        $class = substr( $meth, 0, $idx );
        $meth  = substr( $meth, $idx + 2 );
    }
    
    # printf( STDERR __PACKAGE__ . "::AUTOLOAD: %d autoload subs found.\n", scalar( keys( %$AUTOLOAD_SUBS ) ) ) if( $DEBUG >= 4 );
    unless( scalar( keys( %$AUTOLOAD_SUBS ) ) )
    {
        &Module::Generic::_autoload_subs();
        # printf( STDERR __PACKAGE__ . "::AUTOLOAD: there are now %d autoload classes found: %s\n", scalar( keys( %$AUTOLOAD_SUBS ) ), join( ', ', sort( keys( %$AUTOLOAD_SUBS ) ) ) ) if( $DEBUG >= 4 );
    }
    
    # print( STDERR "Checking if sub '$meth' from class '$class' ($AUTOLOAD) is within the autoload subroutines\n" ) if( $DEBUG >= 4 );
    my $code;
    if( CORE::exists( $AUTOLOAD_SUBS->{ $meth } ) )
    {
        $code = $AUTOLOAD_SUBS->{ $meth };
        # $code = Nice::Try->implement( $code ) if( CORE::index( $code, 'try' ) != -1 );
        # print( STDERR __PACKAGE__, "::AUTOLOAD: updated code for method \"$meth\" ($AUTOLOAD) and \$self '$self' is:\n$code\n" ) if( $DEBUG >= 4 );
        my $saved = $@;
        local $@;
        {
            no strict;
            eval( $code );
        }
        if( $@ )
        {
            $@ =~ s/ at .*\n//;
            die( $@ );
        }
        $@ = $saved;
        # defined( &$AUTOLOAD ) || die( "AUTOLOAD inconsistency error for dynamic sub \"$meth\"." );
        my $ref = $class->can( $meth ) || die( "AUTOLOAD inconsistency error for dynamic sub \"$meth\"." );
        # No need to keep it in the cache
        # delete( $AUTOLOAD_SUBS->{ $meth } );
        # goto( &$AUTOLOAD );
        return( &$meth( $self, @_ ) ) if( $self );
        return( &$AUTOLOAD( @_ ) );
    }
    
    if( $self && $self->can( 'autoload' ) )
    {
        if( my $code = $self->autoload( $meth ) )
        {
            return( $code->( $self, @_ ) ) if( $code );
        }
    }
    
    $meth = lc( $meth );
    my $this;
    $this = $self->_obj2h if( defined( $self ) );
    my $data;
    if( $this )
    {
        $data = $this->{_data_repo} ? $this->{ $this->{_data_repo} } : $this;
    }
    # Check if the object has a property some-thing for a given call to method some_thing
    my $meth_dashed = $meth;
    $meth_dashed =~ tr/_/-/;
    if( $data && CORE::exists( $data->{ $meth } ) )
    {
        if( @_ )
        {
            my $val = ( @_ == 1 ) ? shift( @_ ) : [ @_ ];
            $data->{ $meth } = $val;
        }
        if( wantarray() )
        {
            if( ref( $data->{ $meth } ) eq 'ARRAY' )
            {
                return( @{ $data->{ $meth } } );
            }
            elsif( ref( $data->{ $meth } ) eq 'HASH' )
            {
                return( %{ $data->{ $meth } } );
            }
            else
            {
                return( ( $data->{ $meth } ) );
            }
        }
        else
        {
            return( $data->{ $meth } );
        }
    }
    elsif( $data && CORE::exists( $data->{ $meth_dashed } ) )
    {
        if( @_ )
        {
            my $val = ( @_ == 1 ) ? shift( @_ ) : [ @_ ];
            $data->{ $meth_dashed } = $val;
        }
        if( wantarray() )
        {
            if( ref( $data->{ $meth_dashed } ) eq 'ARRAY' )
            {
                return( @{ $data->{ $meth_dashed } } );
            }
            elsif( ref( $data->{ $meth_dashed } ) eq 'HASH' )
            {
                return( %{ $data->{ $meth_dashed } } );
            }
            else
            {
                return( ( $data->{ $meth_dashed } ) );
            }
        }
        else
        {
            return( $data->{ $meth_dashed } );
        }
    }
    # Because, if it does not exist in the caller's package, 
    # calling the method will get us here infinitly,
    # since UNIVERSAL::can will somehow return true even if it does not exist
    elsif( $self && $self->can( $meth ) && defined( &{ "$class\::$meth" } ) )
    {
        return( $self->$meth( @_ ) );
    }
    elsif( defined( &$meth ) )
    {
        no strict 'refs';
        *$meth = \&$meth;
        return( &$meth( $self, @_ ) ) if( $self );
        return( &$meth( @_ ) );
    }
    else
    {
        my $sub = $AUTOLOAD;
        my( $pkg, $func ) = ( $sub =~ /(.*)::([^:]+)$/ );
        my $mesg = "Module::Generic::AUTOLOAD(): Searching for routine '$func' from package '$pkg'.";
        if( $MOD_PERL )
        {
            # try-catch
            local $@;
            eval
            {
                my $r = Apache2::RequestUtil->request;
                $r->log->debug( $mesg );
            };
            if( $@ )
            {
                print( STDERR "Error trying to get the global Apache2::ApacheRec: $@\n" );
            }
        }
        else
        {
            print( STDERR $mesg . "\n" ) if( $DEBUG );
        }
        $pkg =~ s/::/\//g;
        my $filename;
        if( defined( $filename = $INC{ "$pkg.pm" } ) )
        {
            $filename =~ s/^(.*)$pkg\.pm\z/$1auto\/$pkg\/$func.al/s;
            if( -r( $filename ) )
            {
                unless( $filename =~ m|^/|s )
                {
                    $filename = "./$filename";
                }
            }
            else
            {
                $filename = undef();
            }
        }
        if( !defined( $filename ) )
        {
            $filename = "auto/$sub.al";
            $filename =~ s/::/\//g;
        }
        my $save = $@;
        local $@;
        eval
        {
            local $SIG{ '__DIE__' }  = sub{ };
            local $SIG{ '__WARN__' } = sub{ };
            require $filename;
        };
        if( $@ )
        {
            if( substr( $sub, -9 ) eq '::DESTROY' )
            {
                *$sub = sub {};
            }
            else
            {
                # The load might just have failed because the filename was too
                # long for some old SVR3 systems which treat long names as errors.
                # If we can succesfully truncate a long name then it's worth a go.
                # There is a slight risk that we could pick up the wrong file here
                # but autosplit should have warned about that when splitting.
                if( $filename =~ s/(\w{12,})\.al$/substr( $1, 0, 11 ) . ".al"/e )
                {
                    local $@;
                    eval
                    {
                        local $SIG{ '__DIE__' }  = sub{ };
                        local $SIG{ '__WARN__' } = sub{ };
                        require $filename
                    };
                }
                if( $@ )
                {
                    ## Look up in our caller's @ISA to see if there is any package that has this special
                    ## EXTRA_AUTOLOAD() sub routine
                    my $sub_ref = '';
                    die( "EXTRA_AUTOLOAD: ", join( "', '", @_ ), "\n" ) if( $func eq 'EXTRA_AUTOLOAD' );
                    if( $self && $func ne 'EXTRA_AUTOLOAD' && ( $sub_ref = $self->will( 'EXTRA_AUTOLOAD' ) ) )
                    {
                        return( $sub_ref->( $self, $AUTOLOAD, @_ ) );
                    }
                    else
                    {
                        my $keys = CORE::join( ',', keys( %$data ) );
                        my $msg  = "Method $func() is not defined in class $class and not autoloadable in package $pkg in file $file at line $line.\n";
                        $msg    .= "There are actually the following fields in the object '$self': '$keys'\n";
                        die( $msg );
                    }
                }
            }
        }
        $@ = $save;
        if( $DEBUG )
        {
            my $mesg = "unshifting '$self' to args for sub '$sub'.";
            if( $MOD_PERL )
            {
                # try-catch
                local $@;
                eval
                {
                    my $r = Apache2::RequestUtil->request;
                    $r->log->debug( $mesg );
                };
                if( $@ )
                {
                    print( STDERR "Error trying to get the global Apache2::ApacheRec: $@\n" );
                }
            }
            else
            {
                print( $stderr "$mesg\n" );
            }
        }
        unshift( @_, $self ) if( $self );
        goto &$sub;
    }
};

DESTROY
{
    # Do nothing
};

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Module::Generic - Generic Module to inherit from

=head1 SYNOPSIS

    package MyModule;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
    };

    sub init
    {
        my $self = shift( @_ );
        # Requires parameters provided to have their equivalent method
        $self->{_init_strict_use_sub} = 1;
        # Smartly accepts key-value pairs as list or hash reference
        $self->SUPER::init( @_ );
        # This won't be affected by parameters provided during instantiation
        $self->{_private_param} = 'some value';
        return( $self );
    }
    
    sub active { return( shift->_set_get_boolean( 'active', @_ ) ); }
    sub address { return( shift->_set_get_object( 'address', 'My::Address', @_ ) ); }
    sub age { return( shift->_set_get_number( 'age', @_ ) ); }
    sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }
    sub uuid { return( shift->_set_get_uuid( 'uuid', @_ ) ); }
    sub remote_addr { return( shift->_set_get_ip( 'remote_addr', @_ ) ); }
    sub discount
    {
        return( shift->_set_get_class_array( 'discount',
        {
        amount      => { type => 'number' },
        discount    => { type => 'object', class => 'My::Discount' },
        }, @_ ) );
    }
    sub settings 
    {
        return( shift->_set_get_class( 'settings',
        {
        # Will create a Module::Generic::Array array object of objects of class MY::Item
        items => { type => 'object_array_object', class => 'My::Item' },
        notify => { type => 'boolean' },
        resumes_at => { type => 'datetime' },
        timeout => { type => 'integer' },
        customer => {
                definition => {
                    billing_address => { package => "My::Address", type => "object" },
                    email => { type => "scalar" },
                    name => { type => "scalar" },
                    shipping_address => { package => "My::Address", type => "object" },
                },
                type => "class",
            },
        }, @_ ) );
    }

=head1 VERSION

    v0.35.3

=head1 DESCRIPTION

L<Module::Generic> as its name says it all, is a generic module to inherit from.
It is designed to be fast and provide a useful framework and speed up coding and debugging.
It contains standard and support methods that may be superseded by your module.

It also contains an AUTOLOAD transforming any hash object key into dynamic methods and also recognize the dynamic routine a la AutoLoader. The reason is that while C<AutoLoader> provides the user with a convenient AUTOLOAD, I wanted a way to also keep the functionnality of L<Module::Generic> AUTOLOAD that were not included in C<AutoLoader>. So the only solution was a merger.

=head1 METHODS

=head2 import

B<import>() is used for the AutoLoader mechanism and hence is not a public method.
It is just mentionned here for info only.

=head2 new

B<new> will create a new object for the package, pass any argument it might receive to the special standard routine B<init> that I<must> exist. 
Then it returns what returns L</"init">.

To protect object inner content from sneaking by third party, you can declare the package global variable I<OBJECT_PERMS> and give it a Unix permission, but only 1 digit.
It will then work just like Unix permission. That is, if permission is 7, then only the module who generated the object may read/write content of the object. However, if you set 5, the, other may look into the content of the object, but may not modify it.
7, as you would have guessed, allow other to modify the content of an object.
If I<OBJECT_PERMS> is not defined, permissions system is not activated and hence anyone may access and possibly modify the content of your object.

If the module runs under mod_perl, and assuming you have set the variable C<GlobalRequest> in your Apache configuration, it is recognised and a clean up registered routine is declared to Apache to clean up the content of the object.

This methods calls L</init>, which does all the work of setting object properties and calling methods to that effect.

=head2 as_hash

This will recursively transform the object into an hash suitable to be encoded in json.

It does this by calling each method of the object and build an hash reference with the method name as the key and the method returned value as the value.

If the method returned value is an object, it will call its L</"as_hash"> method if it supports it.

It returns the hash reference built

=head2 clear

Alias for L</clear_error>

=head2 clear_error

Clear all error from the object and from the available global variable C<$ERROR>.

This is a handy method to use at the beginning of other methods of calling package, so the end user may do a test such as:

    $obj->some_method( 'some arguments' );
    die( $obj->error() ) if( $obj->error() );

    # some_method() would then contain something like:
    sub some_method
    {
        my $self = shift( @_ );
        ## Clear all previous error, so we may set our own later one eventually
        $self->clear_error();
        # ...
    }

This way the end user may be sure that if C<$obj->error()> returns true something wrong has occured.

=head2 clone

Clone the current object if it is of type hash or array reference. It returns an error if the type is neither.

It returns the clone.

=head2 colour_close

The marker to be used to set the closing of a command line colour sequence.

Defaults to ">"

=head2 colour_closest

Provided with a colour, this returns the closest standard one supported by terminal.

A colour provided can be a colour name, or a 9 digits rgb value or an hexadecimal value

=head2 colour_format

Provided with a hash reference of parameters, this will return a string properly formatted to display colours on the command line.

Parameters are:

=over 4

=item * C<text> or I<message>

This is the text to be formatted in colour.

=item * C<bgcolour> or I<bgcolor> or I<bg_colour> or I<bg_color>

The value for the background colour.

=item * C<colour> or I<color> or I<fg_colour> or I<fg_color> or I<fgcolour> or I<fgcolor>

The value for the foreground colour.

Valid value can be a colour name, an rgb value like C<255255255>, a rgb annotation like C<rgb(255, 255, 255)> or a rgba annotation like C<rgba(255,255,255,0.5)>

A colour can be preceded by the words C<light> or C<bright> to provide slightly lighter colour where supported.

Similarly, if an rgba value is provided, and the opacity is less than 1, this is equivalent to using the keyword C<light>

It returns the text properly formatted to be outputted in a terminal.

=item * C<style>

The possible values are: I<bold>, I<italic>, I<underline>, I<blink>, I<reverse>, I<conceal>, I<strike>

=back

=head2 colour_open

The marker to be used to set the opening of a command line colour sequence.

Defaults to "<"

=head2 colour_parse

Provided with a string, this will parse the string for colour formatting. Formatting can be encapsulated in another formatting, and can be expressed in 2 different ways. For example:

    $self->colour_parse( "And {style => 'i|b', color => green}what about{/} {style => 'blink', color => yellow}me{/} ?" );

would result with the words C<what about> in italic, bold and green colour and the word C<me> in yellow colour blinking (if supported).

Another way is:

    $self->colour_parse( "And {bold light red on white}what about{/} {underline yellow}me too{/} ?" );

would return a string with the words C<what about> in light red bold text on a white background, and the words C<me too> in yellow with an underline.

    $self->colour_parse( "Hello {bold red on white}everyone! This is {underline rgb(0,0,255)}embedded{/}{/} text..." );

would return a string with the words C<everyone! This is> in bold red characters on white background and the word C<embedded> in underline blue color

The idea for this syntax, not the code, is taken from L<Term::ANSIColor>

=head2 colour_to_rgb

Convert a human colour keyword like C<red>, C<green> into a rgb equivalent.

=head2 coloured

Provided with a colouring preference expressed as the first argument as string, and followed by 1 or more arguments that are concatenated to form the text string to format. For example:

    print( $o->coloured( 'bold white on red', "Hello it's me!\n" ) );

A colour can be expressed as a rgb, such as :

    print( $o->coloured( 'underline rgb( 0, 0, 255 ) on white', "Hello everyone!" ), "\n" );

rgb can also be rgba with the last decimal, normally an opacity used here to set light color if the value is less than 1. For example :

    print( $o->coloured( 'underline rgba(255, 0, 0, 0.5)', "Hello everyone!" ), "\n" );

=head2 debug

Set or get the debug level. This takes and return an integer.

Based on the value, L</"message"> will or will not print out messages. For example :

    $self->debug( 2 );
    $self->message( 2, "Debugging message here." );

Since C<2> used in L</"message"> is equal to the debug value, the debugging message is printed.

If the debug value is switched to 1, the message will be silenced.

=head2 deserialise

    my $ref = $self->deserialise( %hash_of_options );
    my $ref = $self->deserialise( $hash_reference_of_options );
    my $ref = $self->deserialise( $serialised_data, %hash_of_options );
    my $ref = $self->deserialise( $serialised_data, $hash_reference_of_options );

This method use a specified serialiser class and deserialise the given data either directly from a specified file or being provided, and returns the perl data.

The serialisers currently supported are: L<CBOR::Free>, L<CBOR::XS>, L<JSON>, L<Sereal> and L<Storable::Improved> (or the legacy L<Storable>). They are not required by L<Module::Generic>, so you must install them yourself. If the serialiser chosen is not installed, this will set an L<errr|Module::Generic/error> and return C<undef>.

It takes an hash or hash reference of options. You can also provide the data to deserialise as the first argument followed by an hash or hash reference of options.

It can then:

=over 4

=item * retrieve data directly from File

=item * retrieve data from a file handle (only with L<Storable>)

=item * Return the deserialised data

=back

The supported options are:

=over 4

=item * C<base64>

Thise can be set to a true value like C<1>, or to your preferred base64 encoder/decoder, or to an array reference containing 2 code references, the first one for encoding and the second one for decoding.

If this is set simply to a true value, C<deserialise> will call L</_has_base64> to find out any installed base64 modules. Currently the ones supported are: L<Crypt::Misc> and L<MIME::Base64>. Of course, you need to have one of those modules installed first before it can be used.

If this option is set and no appropriate module could be found, C<deserialise> will return an error.

=item * C<data>

Data to be deserialised.

=item * C<file>

Provides a file path from which to read the serialised data.

=item * C<io>

A file handle. This is used when the serialiser is L<Storable> to call its function L<Storable::Improved/store_fd> and L<Storable::Improved/fd_retrieve>

=item * I<lock>

Boolean. If true, this will lock the file before reading from it. This works only in conjonction with I<file> and the serialiser L<Storable::Improved>

=item * C<serialiser>

Specify the class name of the serialiser to use. Supported serialiser can either be C<CBOR> or L<CBOR::XS>, L<Sereal> and L<Storable|Storable::Improved>

If the serialiser is L<CBOR::XS> the following additional options are supported: C<max_depth>, C<max_size>, C<allow_unknown>, C<allow_sharing>, C<allow_cycles>, C<forbid_objects>, C<pack_strings>, C<text_keys>, C<text_strings>, C<validate_utf8>, C<filter>

See L<CBOR::XS> for detail on those options.

If the serialiser is L<Sereal>, the following additional options are supported: C<refuse_snappy>, C<refuse_objects>, C<no_bless_objects>, C<validate_utf8>, C<max_recursion_depth>, C<max_num_hash_entries>, C<max_num_array_entries>, C<max_string_length>, C<max_uncompressed_size>, C<incremental>, C<alias_smallint>, C<alias_varint_under>, C<use_undef>, C<set_readonly>, C<set_readonly_scalars>

See L<Sereal> for detail on those options.

=back

If an error occurs, this sets an L<error|Module::Generic/error> and return C<undef>

=head2 deserialize

Alias for L</deserialise>

=head2 dump

Provided with some data, this will return a string representation of the data formatted by L<Data::Printer>

=head2 dump_hex

Returns an hexadecimal dump of the data provided.

This requires the module L<Devel::Hexdump> and will return C<undef> and set an L</error> if not found.

=head2 dump_print

Provided with a file to write to and some data, this will format the string representation of the data using L<Data::Printer> and save it to the given file.

=head2 dumper

Provided with some data, and optionally an hash reference of parameters as last argument, this will create a string representation of the data using L<Data::Dumper> and return it.

This sets L<Data::Dumper> to be terse, to indent, to use C<qq> and optionally to not exceed a maximum I<depth> if it is provided in the argument hash reference.

=head2 dumpto

Alias for L</dumpto_dumper>

=head2 printer

Same as L</"dumper">, but using L<Data::Printer> to format the data.

=head2 dumpto_printer

Same as L</"dump_print"> above that is an alias of this method.

=head2 dumpto_dumper

Same as L</"dumpto_printer"> above, but using L<Data::Dumper>

=head2 errno

Sets or gets an error number.

=head2 error

    my $o = Foo::Bar->new;
    $o->do_something || return( $self->error( "Some error", "message." ) );
    # or
    $o->do_something || return( $self->error({
        message => "Some error message.",
        # will be loaded if necessary
        class => 'My::Exception::Class',
        # by default 'object' only
        # it could also be simply 'all' to imply all the ones below
        want => [qw( array code glob hash object scalar )],
        debug => 4,
        # code to execute upon error
        callback => sub
        {
            # do some cleanup
            $dbh->rollback if( $dbh->transaction );
        },
        # make it fatal
        fatal => 1,
        # When used inside an lvalue method
        # lvalue => 1,
        # assign => 1,
    }) );

Provided with a list of strings or an hash reference of parameters and this will set the current error issuing a L<Module::Generic::Exception> object, call L<perlfunc/warn>, or C<$r->warn> under Apache2 modperl, and returns undef() or an empty list in list context:

    if( $some_condition )
    {
        return( $self->error( "Some error." ) );
    }

Note that you do not have to worry about a trailing line feed sequence.
L</error> takes care of it.

The script calling your module could write calls to your module methods like this:

    my $cust_name = $object->customer->name ||
        die( "Got an error in file ", $object->error->file, " at line ", $object->error->line, ": ", $object->error->trace, "\n" );
    # or simply:
    my $cust_name = $object->customer->name ||
        die( "Got an error: ", $object->error, "\n" );

If you want to use an hash reference instead, you can pass the following parameters. Any other parameters will be passed to the exception class.

=over 4

=item * C<assign>

Boolean. Set this to a true value if this is called within an assign method, such as one using lvalue.

=item * C<callback>

Specify a code reference such as a reference to a subroutine. This is designed to be called upon error to do some cleanup for example.

=item * C<class>

The package name or class to use to instantiate the error object. By default, it will use L<Module::Generic::Exception> class or the one specified with the object property C<_exception_class>

    $self->do_something_bad ||
        return( $self->error({
            code => 500,
            message => "Oopsie",
            class => "My::NoWayException",
        }) );
    my $exception = $self->error; # an My::NoWayException object

Note, however, that if the class specified cannot be loaded for some reason, L<Module::Generic/error> will die since this would be an error within another error.

=item * C<debug>

Integer. Specify a value to set the debugging value for this exception.

=item * C<fatal>

Boolean. Specify a true value to make this error fatal. This means that instead of issuing a C<warn>, it will die.

=item * C<lvalue>

Boolean. Set this to a true value if this is called within an assign method, such as one using lvalue.

=item * C<message>

Specify a string for the error message.

The error message.

=item * C<want>

An array reference of data types that you allow this method to return when such data type is expected by the original caller.

Supported data types are: C<ARRAY>, C<CODE>, C<GLOB>, C<HASH>, C<OBJECT>, C<SCALAR>

Note that, actually, the data type you provide is case insensitive.

For example, you have a method that returns an array, but an error occurs, and it returns C<undef> instead:

    sub your_method
    {
        my $self = shift( @_ );
        return( $self->error( "Something is wrong" ) ) if( $self->something_is_missing );
        return( $self->{array} );
    }

    my $array = $obj->your_method; # array is undef

If the user does:

    $obj->your_method->[0]; # perl error occurs

This would trigger a perl error C<Can't use an undefined value as an ARRAY reference>, which may be fine if this is what you want, but if you want instead to ensure the user does not get an error, but instead an empty array, in your method C<your_method>, you could write this C<your_method> this way instead, passing the C<want> parameter:

    sub your_method
    {
        my $self = shift( @_ );
        return( $self->error( { message => "Something is wrong", want => [qw( array )] ) ) if( $self->something_is_missing );
        return( $self->{array} );
    }

Then, if the user calls this method in array context and an error occurs, it would now return instead an empty array.

    my $array = $obj->your_method->[0]; # undef

Note that, by default, the C<object> call context is always activated, so you do not have to specify it.

=back

Note also that by calling L</error> it will not clear the current error. For that
you have to call L</clear_error> explicitly.

Also, when an error is set, the global variable I<ERROR> in the inheriting package is set accordingly. This is
especially usefull, when your initiating an object and that an error occured. At that
time, since the object could not be initiated, the end user can not use the object to 
get the error message, and then can get it using the global module variable 
I<ERROR>, for example:

    my $obj = Some::Package->new ||
    die( $Some::Package::ERROR, "\n" );

If the caller has disabled warnings using the pragma C<no warnings>, L</error> will 
respect it and not call B<warn>. Calling B<warn> can also be silenced if the object has
a property I<quiet> set to true.

The error message can be split in multiple argument. L</error> will concatenate each argument to form a complete string. An argument can even be a reference to a sub routine and will get called to get the resulting string, unless the object property I<_msg_no_exec_sub> is set to false. This can switched off with the method L</"noexec">

If perl runs under Apache2 modperl, and an error handler is set with L</error_handler>, this will call the error handler with the error string.

If an Apache2 modperl log handler has been set, this will also be called to log the error.

If the object property I<fatal> is set to true, this will call die instead of L<perlfunc/"warn">.

Last, but not least since L</error> returns undef in scalar context or an empty list in list context, if the method that triggered the error is chained, it would normally generate a perl error that the following method cannot be called on an undefined value. To solve this, when an object is expected, L</error> returns a special object from module L<Module::Generic::Null> that will enable all the chained methods to be performed and return the error when requested to. For example:

    my $o = My::Package->new;
    my $total $o->get_customer(10)->products->total || die( $o->error, "\n" );

Assuming this method here C<get_customer> returns an error, the chaining will continue, but produce nothing and ultimately returns undef.

=head2 error_handler

Sets or gets a code reference that will be called to handle errors that have been triggered when calling L</error>

=head2 errors

Used by B<error>() to store the error sent to him for history.

It returns an array of all error that have occured in lsit context, and the last 
error in scalar context.

=head2 errstr

Set/get the error string, period. It does not produce any warning like B<error> would do.

=head2 fatal

Boolean. If enabled, any error will call L<perlfunc/die> instead of returning L<perlfunc/undef> and setting an L<error|Module::Generic/error>.

Defaults to false.

You can enable it in your own package by initialising it in your own C<init> method like this:

    sub init
    {
        my $self = shift( @_ );
        $self->{fatal} = 1;
        return( $self->SUPER::init( @_ ) );
    }

=head2 get

Uset to get an object data key value:

    $obj->set( 'verbose' => 1, 'debug' => 0 );
    ## ...
    my $verbose = $obj->get( 'verbose' );
    my @vals = $obj->get( qw( verbose debug ) );
    print( $out "Verbose level is $vals[ 0 ] and debug level is $vals[ 1 ]\n" );

This is no more needed, as it has been more conveniently bypassed by the AUTOLOAD
generic routine with which you may say:

    $obj->verbose(1);
    $obj->debug(0);
    ## ...
    my $verbose = $obj->verbose();

Much better, no?

=head2 init

This is the L</new> package object initializer. It is called by L</new>
and is used to set up any parameter provided in a hash like fashion:

    my $obj My::Module->new( 'verbose' => 1, 'debug' => 0 );

You may want to superseed L</init> to have it suit your needs.

L</init> needs to returns the object it received in the first place or an error if
something went wrong, such as:

    sub init
    {
        my $self = shift( @_ );
        my $dbh  = DB::Object->connect() ||
        return( $self->error( "Unable to connect to database server." ) );
        $self->{dbh} = $dbh;
        return( $self );
    }

In this example, using L</error> will set the global variable C<$ERROR> that will
contain the error, so user can say:

    my $obj = My::Module->new() || die( $My::Module::ERROR );

If the global variable I<VERBOSE>, I<DEBUG>, I<VERSION> are defined in the module,
and that they do not exist as an object key, they will be set automatically and
accordingly to those global variable.

The supported data type of the object generated by the L</"new"> method may either be
a hash reference or a glob reference. Those supported data types may very well be
extended to an array reference in a near future.

When provided with an hash reference, and when object property I<_init_strict_use_sub> is set to true, L</init> will call each method corresponding to the key name and pass it the key value and it will set an error and skip it if the corresponding method does not exist. Otherwise, it calls each corresponding method and pass it whatever value was provided and check for that method return value. If the return value is L<perlfunc/undef> and the value provided is B<not> itself C<undef>, then it issues a warning and return the L</error> that is assumed having being set by that method.

Otherwise if the object property I<_init_strict> is set to true, it will check the object property matching the hash key for the default value type and set an error and return undef if it does not match. Foe example, L</"init"> in your module could be like this:

    sub init
    {
        my $self = shift( @_ );
        $self->{_init_strict} = 1;
        $self->{products} = [];
        return( $self->SUPER::init( @_ ) );
    }

Then, if init is called like this:

    $object->init({ products => $some_string_but_not_array }) || die( $object->error, "\n" );

This would cause your script to die, because C<products> value is a string and not an array reference.

Otherwise, if none of those special object properties are set, the init will create an object property matching the key of the hash and set its value accordingly. For example :

    sub init
    {
        my $self = shift( @_ );
        return( $self->SUPER::init( @_ ) );
    }

Then, if init is called like this:

    $object->init( products => $array_ref, first_name => 'John', last_name => 'Doe' });

The object would then contain the properties I<products>, I<first_name> and I<last_name> and can be accessed as methods, such as :

    my $fname = $object->first_name;

You can also alter the way L</init> process the parameters received using the following properties you can set in your own C<init> method, for example:

    sub init
    {
        my $self = shift( @_ );
        # Set the order in which the parameters are processed, because some methods may rely on other methods' value
        $self->{_init_params_order} [qw( method1 method2 )];
        # Enable strict sub, which means the corresponding method must exist for the parameter provided
        $self->{_init_strict_use_sub} = 1;
        # Set the class name of the exception to use in error()
        # Here My::Package::Exception should inherit from Module::Generic::Exception or some other Exception package
        $self->{_exception_class} = 'My::Package::Exception';
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        return( $self );
    }

You can also specify a default exception class that will be used by L</error> to create exception object, by setting the object property C<_exception_class>:

    sub init
    {
        my $self = shift( @_ );
        $self->{name} = 'default_name';
        # For any key-value pairs to be matched by a corresponding method
        $self->{_init_strict_use_sub} = 1;
        $self->{_exception_class} = 'My::Exception';
        return( $self->SUPER::init( @_ ) );
    }

=head2 log_handler

Provided a reference to a sub routine or an anonymous sub routine, this will set the handler that is called by L</"message">

It returns the current value set.

=head2 message

B<message>() is used to display verbose/debug output. It will display something to the extend that either I<verbose> or I<debug> are toggled on.

If so, all debugging message will be prepended by C< E<35>E<35> > by default or the prefix string specified with the I<prefix> option, to highlight the fact that this is a debugging message.

Addionally, if a number is provided as first argument to B<message>(), it will be treated as the minimum required level of debugness. So, if the current debug state level is not equal or superior to the one provided as first argument, the message will not be displayed.

For example:

    # Set debugness to 3
    $obj->debug( 3 );
    # This message will not be printed
    $obj->message( 4, "Some detailed debugging stuff that we might not want." );
    # This will be displayed
    $obj->message( 2, "Some more common message we want the user to see." );

Now, why debug is used and not verbose level? Well, because mostly, the verbose level needs only to be true, that is equal to 1 to be efficient. You do not really need to have a verbose level greater than 1. However, the debug level usually may have various level.

Also, the text provided can be separated by comma, and even be a code reference, such as:

    $self->message( 2, "I have found", "something weird here:", sub{ $self->dumper( $data ) } );

If the object has a property I<_msg_no_exec_sub> set to true, then a code reference will not be called and instead be added to the string as is. This can be done simply like this:

    $self->noexec->message( 2, "I have found", "something weird here:", sub{ $self->dumper( $data ) } );

L</message> also takes an optional hash reference as the last parameter with the following recognised options:

=over 4

=item * C<caller_info>

This is a boolean value, which is true by default.

When true, this will prepend the debug message with information about the caller of L</message>

=item * C<level>

An integer. Debugging level.

=item * C<message>

The text of the debugging message. This is optional since this can be provided as first or consecutive arguments like in a list as demonstrated in the example above. This allows you to do something like this:

    $self->message( 2, { message => "Some debug message here", prefix => ">>" });

or

    $self->message( { message => "Some debug message here", prefix => ">>", level => 2 });

=item * C<no_encoding>

Boolean value. If true and when the debugging is set to be printed to a file, this will not set the binmode to C<utf-8>

=item * C<prefix>

By default this is set to C<E<35>E<35>>. This value is used as the prefix used in debugging output.

=item * C<type>

Type of debugging

=back

=head2 message_check

This is called by L</"message">

Provided with a list of arguments, this method will check if the first argument is an integer and find out if a debug message should be printed out or not. It returns the list of arguments as an array reference.

=head2 message_color

Alias for L</message_colour>

=head2 message_colour

This is the same as L</"message">, except this will check for colour formatting, which
L</"message"> does not do. For example:

    $self->message_colour( 3, "And {bold light white on red}what about{/} {underline green}me again{/} ?" );

L</"message_colour"> can also be called as B<message_color>

See also L</"colour_format"> and L</"colour_parse">

=head2 message_frame

Return the optional hash reference of parameters, if any, that can be provided as the last argument to L</message>

=head2 messagec

This is an alias for L</message_colour>

=head2 messagef

This works like L<perlfunc/"sprintf">, so provided with a format and a list of arguments, this print out the message. For example :

    $self->messagef( 1, "Customer name is %s", $cust->name );

Where 1 is the debug level set with L</"debug">

=head2 messagef_colour

This method is same as L</message_colour> and L<messagef> combined.

It enables to pass sprintf-like parameters while enabling colours.

=head2 message_log

This is called from L</"message">.

Provided with a message to log, this will check if L</"message_log_io"> returns a valid file handler, presumably to log file, and if so print the message to it.

If no file handle is set, this returns undef, other it returns the value from C<$io->print>

=head2 message_log_io

Set or get the message log file handle. If set, L</"message_log"> will use it to print messages received from L</"message">

If no argument is provided bu your module has a global variable C<LOG_DEBUG> set to true and global variable C<DEB_LOG> set presumably to the file path of a log file, then this attempts to open in write mode the log file.

It returns the current log file handle, if any.

=head2 new_array

Instantiate a new L<Module::Generic::Array> object. If any arguments are provided, it will pass it to L<Module::Generic::Array/new> and return the object.

=head2 new_datetime

Provided with some optional arguments and this will instantiate a new L<Module::Generic::DateTime> object, passing it whatever argument was provided.

Example:

    my $dt = DateTime->now( time_zone => 'Asia/Tokyo' );
    # Returns a new Module::Generic::DateTime object
    my $d = $o->new_datetime( $dt );

    # Returns a new Module::Generic::DateTime object with DateTime initiated automatically
    # to now with time zone set by default to UTC
    my $d = $o->new_datetime;

=head2 new_file

Instantiate a new L<Module::Generic::File> object. If any arguments are provided, it will pass it to L<Module::Generic::File/new> and return the object.

=head2 new_glob

This method is called instead of L</new> in your package for GLOB type module.

It will set an hash of options provided and call L</init> and return the newly instantiated object upon success, or C<undef> upon error.

=head2 new_hash

Instantiate a new L<Module::Generic::Hash> object. If any arguments are provided, it will pass it to L<Module::Generic::Hash/new> and return the object.

=head2 new_json

This method tries to load L<JSON> and create a new object.

By default it enables the following L<JSON> object properties:

=over 4

=item L<JSON/allow_blessed>

=item L<JSON/allow_nonref>

=item L<JSON/convert_blessed>

=item L<JSON/relaxed>

=back

Additional supported options are as follows, including any of the L<JSON> supported options:

=over 4

=item * C<allow_blessed>

Boolean. When enabled, this will not return an error when it encounters a blessed reference that L<JSON> cannot convert otherwise. Instead, a JSON C<null> value is encoded instead of the object.

=item * C<allow_nonref>

Boolean. When enabled, this will convert a non-reference into its corresponding string, number or null L<JSON> value. Default is enabled.

=item * C<allow_tags>

Boolean. When enabled, upon encountering a blessed object, this will check for the availability of the C<FREEZE> method on the object's class. If found, it will be used to serialise the object into a nonstandard tagged L<JSON> value (that L<JSON> decoders cannot decode). 

=item * C<allow_unknown>

Boolean. When enabled, this will not return an error when L<JSON> encounters values it cannot represent in JSON (for example, filehandles) but instead will encode a L<JSON> "null" value.

=item * C<ascii>

Boolean. When enabled, will not generate characters outside the code range 0..127 (which is ASCII).

=item * C<canonical> or C<ordered>

Boolean value. If true, the JSON data will be ordered. Note that it will be slower, especially on a large set of data.

=item * C<convert_blessed>

Boolean. When enabled, upon encountering a blessed object, L<JSON> will check for the availability of the C<TO_JSON> method on the object's class. If found, it will be called in scalar context and the resulting scalar will be encoded instead of the object.

=item * C<indent>

Boolean. When enabled, this will use a multiline format as output, putting every array member or object/hash key-value pair into its own line, indenting them properly.

=item * C<latin1>

Boolean. When enabled, this will encode the resulting L<JSON> text as latin1 (or iso-8859-1),

=item * C<max_depth>

Integer. This sets the maximum nesting level (default 512) accepted while encoding or decoding. When the limit is reached, this will return an error.

=item * C<pretty>

Boolean value. If true, the JSON data will be generated in a human readable format. Note that this will take considerably more space.

=item * C<space_after>

Boolean. When enabled, this will add an extra optional space after the ":" separating keys from values.

=item * C<space_before>

Boolean. When enabled, this will add an extra optional space before the ":" separating keys from values.

=item * C<utf8>

Boolean. This option is ignored, because the JSON data are saved to file using UTF-8 and double encoding would produce mojibake.

=back

=head2 new_null

Returns a null value based on the expectations of the caller and thus without breaking the caller's call flow.

You can also optionally provide an hash or hash reference containing the option C<type> with a value being either C<ARRAY>, C<CODE>, C<HASH>, C<OBJECT> or C<SCALARREF> to force C<new_null> to return the corresponding data without using the caller's context.

If the caller wants an hash reference, it returns an empty hash reference.

If the caller wants an array reference, it returns an empty array reference.

If the caller wants a code reference, it returns an anonymous subroutine that returns C<undef> or an empty list.

If the caller is calling another method right after, this means this is an object context and L</new_null> will instantiate a new L<Module::Generic::Null> object. If any arguments were provided to L</new_null>, they will be passed along to L<Module::Generic::Null/new> and the new object will be returned.

In any other context, C<undef> is returned or an empty list.

Without using L</new_null>, if you return simply undef, like:

    my $val = $object->return_false->[0];
    
    sub return_false { return }

The above would trigger an error that the value returned by C<return_false> is not an array reference.
Instead of checking on the recipient end what kind of returned value was returned, the caller only need to check if it is defined or not, no matter the context in which it is called.

For example:

    my $this = My::Object->new;
    my $val  = $this->call1;
    # return undef)
    
    # object context
    $val = $this->call1->call_again;
    # $val is undefined
    
    # hash reference context
    $val = $this->call1->fake->{name};
    # $val is undefined
    
    # array reference context
    $val = $this->call1->fake->[0];
    # $val is undefined

    # code reference context
    $val = $this->call1->fake->();
    # $val is undefined

    # scalar reference context
    $val = ${$this->call1->fake};
    # $val is undefined

    # simple scalar
    $val = $this->call1->fake;
    # $val is undefined

    package My::Object;
    use parent qw( Module::Generic );

    sub call1
    {
        return( shift->call2 );
    }

    sub call2 { return( shift->new_null ); }

    sub call_again
    {
        my $self = shift( @_ );
        print( "Got here in call_again\n" );
        return( $self );
    }

This technique is also used by L</error> to set an error object and return undef but still allow chaining beyond the error. See L</error> and L<Module::Generic::Exception> for more information.

=head2 new_number

Instantiate a new L<Module::Generic::Number> object. If any arguments are provided, it will pass it to L<Module::Generic::Number/new> and return the object.

=head2 new_scalar

Instantiate a new L<Module::Generic::Scalar> object. If any arguments are provided, it will pass it to L<Module::Generic::Scalar/new> and return the object.

=head2 new_tempdir

Returns a new temporary directory by calling L<Module::Generic::File/tempdir>

=head2 new_tempfile

Returns a new temporary directory by calling L<Module::Generic::File/tempfile>

=head2 new_version

Provided with a version and this will return a new L<version> object.

If the value provided is not a suitable version, this will set an L<error|Module::Generic/error> and return C<undef>

=head2 noexec

Sets the module property I<_msg_no_exec_sub> to true, so that any call to L</"message"> whose arguments include a reference to a sub routine, will not try to execute the code. For example, imagine you have a sub routine such as:

    sub hello
    {
        return( "Hello !" );
    }

And in your code, you write:

    $self->message( 2, "Someone said: ", \&hello );

If I<_msg_no_exec_sub> is set to false (by default), then the above would print out the following message:

    Someone said Hello !

But if I<_msg_no_exec_sub> is set to true, then the same would rather produce the following :

    Someone said CODE(0x7f9103801700)

=head2 pass_error

Provided with an error, typically a L<Module::Generic::Exception> object, but it could be anything as long as it is an object, hopefully an exception object, this will set the error value to the error provided, and without issuing any new warning nor creating a new L<Module::Generic::Exception> object.

It makes it possible to pass the error along so the caller can retrieve it later. This is typically used by a method calling another one in another module that produced an error. For example :

    sub getCustomerInfo
    {
        my $self = shift( @_ );
        # Maybe a LWP::UserAgent sub class?
        my $client = $self->lwp_client_object;
        my $res = $client->get( $remote_api_endpoint ) ||
            return( $self->pass_error( $client->error ) );
    }

Then :

    my $client_info = $object->getCustomerInfo || die( $object->error, "\n" );

Which would return the http client error that has been passed along

You can optionally provide an hash of parameters as the last argument, such as:

    return( $self->pass_error( $obj->error, { class => 'My::Exception', code => 400 } ) );

Or, you could also pass all parameters as an hash reference, such as:

    return( $self->pass_error({
        error => $obj->error,
        class => 'My::Exception',
        code => 400,
    }) );

Supported options are:

=over 4

=item * C<callback>

A code reference, such as a subroutine reference or an anonymous code that will be executed. This is designed to be used to do some cleanup.

=item * C<class>

The name of a class name to re-bless the error object provided.

=item * C<code>

The error code to set in the error object being passed.

=item * C<error>

The error object to be passed on.

If this is not provided, it will get it with the object C<error> method, or the class global variable C<$ERROR>

=back

=head2 quiet

Set or get the object property I<quiet> to true or false. If this is true, no warning will be issued when L</"error"> is called.

=head2 save

Provided with some data and a file path, or alternatively an hash reference of options with the properties I<data>, I<encoding> and I<file>, this will write to the given file the provided I<data> using the encoding I<encoding>.

This is designed to simplify the tedious task of write to files.

If it cannot open the file in write mode, or cannot print to it, this will set an error and return undef. Otherwise this returns the size of the file in bytes.

=head2 serialise

This method use a specified serialiser class and serialise the given data either by returning it or by saving it directly to a given file.

The serialisers currently supported are: L<CBOR::Free>, L<CBOR::XS>, L<JSON>, L<Sereal> and L<Storable::Improved> (or the legacy version L<Storable>). They are not required by L<Module::Generic>, so you must install them yourself. If the serialiser chosen is not installed, this will set an L<errr|Module::Generic/error> and return C<undef>.

This method takes some data and an optional hash or hash reference of parameters. It can then:

=over 4

=item * save data directly to File

=item * save data to a file handle (only with L<Storable::Improved> / L<Storable>)

=item * Return the serialised data

=back

The supported parameters are:

=over 4

=item * I<append>

Boolean. If true, the serialised data will be appended to the given file. This works only in conjonction with I<file>

=item * I<base64>

Thise can be set to a true value like C<1>, or to your preferred base64 encoder/decoder, or to an array reference containing 2 code references, the first one for encoding and the second one for decoding.

If this is set simply to a true value, C<serialise> will call L</_has_base64> to find out any installed base64 modules. Currently the ones supported are: L<Crypt::Misc> and L<MIME::Base64>. Of course, you need to have one of those modules installed first before it can be used.

If this option is set and no appropriate module could be found, C<serialise> will return an error.

=item * I<file>

String. A file path where to store the serialised data.

=item * I<io>

A file handle. This is used when the serialiser is L<Storable::Improved> / L<Storable> to call its function L<Storable::Improved/store_fd> and L<Storable::Improved/fd_retrieve>

=item * I<lock>

Boolean. If true, this will lock the file before writing to it. This works only in conjonction with I<file> and the serialiser L<Storable::Improved>

=item * I<serialiser> or I<serializer>

A string being the class of the serialiser to use. This can be only either L<Sereal> or L<Storable::Improved>

=back

Additionally the following options are supported and passed through directly for each serialiser:

=over 4

=item * L<CBOR::Free>: C<canonical>, C<string_encode_mode>, C<preserve_references>, C<scalar_references>

=item * L<CBOR|CBOR::XS>: C<max_depth>, C<max_size>, C<allow_unknown>, C<allow_sharing>, C<allow_cycles>, C<forbid_objects>, C<pack_strings>, C<text_keys>, C<text_strings>, C<validate_utf8>, C<filter>

=item * L<JSON>: C<allow_blessed> C<allow_nonref> C<allow_unknown> C<allow_tags> C<ascii> C<boolean_values> C<canonical> C<convert_blessed> C<filter_json_object> C<filter_json_single_key_object> C<indent> C<latin1> C<max_depth> C<max_size> C<pretty> C<relaxed> C<space_after> C<space_before> C<utf8>

=item * L<Sereal::Decoder/encode> if the serialiser is L<Sereal>: C<aliased_dedupe_strings>, C<canonical>, C<canonical_refs>, C<compress>, C<compress_level>, C<compress_threshold>, C<croak_on_bless>, C<dedupe_strings>, C<freeze_callbacks>, C<max_recursion_depth>, C<no_bless_objects>, C<no_shared_hashkeys>, C<protocol_version>, C<snappy>, C<snappy_incr>, C<snappy_threshold>, C<sort_keys>, C<stringify_unknown>, C<undef_unknown>, C<use_protocol_v1>, C<warn_unknown>

=item * L<Storable::Improved> / L<Storable>: no option available

=back

If an error occurs, this sets an L<error|Module::Generic/error> and return C<undef>

=head2 serialize

Alias for L</serialise>

=head2 set

B<set>() sets object inner data type and takes arguments in a hash like fashion:

    $obj->set( 'verbose' => 1, 'debug' => 0 );

=head2 subclasses

Provided with a I<CLASS> value, this method try to guess all the existing sub classes of the provided I<CLASS>.

If I<CLASS> is not provided, the class into which was blessed the calling object will
be used instead.

It returns an array of subclasses in list context and a reference to an array of those
subclasses in scalar context.

If an error occured, undef is returned and an error is set accordingly. The latter can
be retrieved using the B<error> method.

=head2 true

Returns a C<true> variable from L<Module::Generic::Boolean>

=head2 false

Returns a C<false> variable from L<Module::Generic::Boolean>

=head2 verbose

Set or get the verbosity level with an integer.

=head2 will

This will try to find out if an object supports a given method call and returns the code reference to it or undef if none is found.

=head2 AUTOLOAD

The special B<AUTOLOAD>() routine is called by perl when no matching routine was found
in the module.

B<AUTOLOAD>() will then try hard to process the request.
For example, let's assue we have a routine B<foo>.

It will first, check if an equivalent entry of the routine name that was called exist in
the hash reference of the object. If there is and that more than one argument were
passed to this non existing routine, those arguments will be stored as a reference to an
array as a value of the key in the object. Otherwise the single argument will simply be stored
as the value of the key of the object.

Then, if called in list context, it will return a array if the value of the key entry was an array
reference, or a hash list if the value of the key entry was a hash reference, or finally the value
of the key entry.

If this non existing routine that was called is actually defined, the routine will be redeclared and
the arguments passed to it.

If this fails too, it will try to check for an AutoLoadable file in C<auto/PackageName/routine_name.al>

If the filed exists, it will be required, the routine name linked into the package name space and finally
called with the arguments.

If the require process failed or if the AutoLoadable routine file did not exist, B<AUTOLOAD>() will
check if the special routine B<EXTRA_AUTOLOAD>() exists in the module. If it does, it will call it and pass
it the arguments. Otherwise, B<AUTOLOAD> will die with a message explaining that the called routine did 
not exist and could not be found in the current class.

=head1 SUPPORT METHODS

Those methods are designed to be called from the package inheriting from L<Module::Generic> to perform various function and speed up development.

=head2 __create_class

Provided with an object property name and an hash reference representing a dictionary and this will produce a dynamically created class/module.

If a property I<_class> exists in the dictionary, it will be used as the class/package name, otherwise a name will be derived from the calling object class and the object property name. For example, in your module :

    sub products { return( 'products', shift->_set_get_class(
    {
    name        => { type => 'scalar' },
    customer    => { type => 'object', class => 'My::Customer' },
    orders      => { type => 'array_as_object' },
    active      => { type => 'boolean' },
    created     => { type => 'datetime' },
    metadata    => { type => 'hash' },
    stock       => { type => 'number' },
    url         => { type => 'uri' },
    }, @_ ) ); }

Then calling your module method B<products> such as :

    my $prod = $object->products({
        name => 'Cool product',
        customer => { first_name => 'John', last_name => 'Doe', email => 'john.doe@example.com' },
        orders => [qw( 123 987 456 654 )],
        active => 1,
        metadata => { transaction_id => 123, api_call_id => 456 },
        stock => 10,
        uri => 'https://example.com/p/20'
    });

Using the resulting object C<$prod>, we can access this dynamically created class/module such as :

    printf( <<EOT, $prod->name, $prod->orders->length, $prod->customer->last_name,, $prod->url->path )
    Product name: %s
    No of orders: %d
    Customer name: %s
    Product page path: %s
    EOT

=head2 __instantiate_object

    my $o = $self->__instantiate_object( 'emails', 'Some::Module', @_ );
    # or, with a callback
    my $o = $self->__instantiate_object({ field => 'emails', callback => sub
    {
        my( $class, $args ) = @_;
        return( $class->parse_bare_address( $args->[0] ) );
    }}, 'Email::Address::XS', @_ );

Provided with an object property name, and a class/package name, this will attempt to load the module if it is not already loaded. It does so using L<Class::Load/load_class>. Once loaded, it will init an object passing it the other arguments received. It returns the object instantiated upon success or undef and sets an L</error>

This is a support method used by L</"_instantiate_object">

Alternatively, you can pass an hash reference, instead of the object property name, with the following properties:

=over 4

=item * C<field>

Mandatory. The object property name.

=item * C<callback>

Optional. A code reference like an anonymous subroutine that will be called with the class and an array reference of values provided, but possibly empty.

=back

This is a useful callback when the module instantiation either does not use the C<new> method or does not simply take one or multiple arguments, such as when the instantiation method would require an hash of parameters, such as L<Email::Address::XS>

=head2 _instantiate_object

This does the same thing as L</"__instantiate_object"> and the purpose is for this method to be potentially superseded in your own module. In your own module, you would call L</"__instantiate_object">

=head2 _can

Provided with a value and a method name, and this will return true if the value provided is an object that L<UNIVERSAL/can> perform the method specified, or false otherwise.

You can also provide an array of method names to check instead of just a method name. In that case, all method names provided must be supported by the object otherwise it will return false.

This makes it more convenient to write:

    if( $self->_can( $obj, 'some_method' ) )
    {
        # ...
    }

or

    if( $self->_can( $obj, [qw(some_method other_method )] ) )
    {
        # ...
    }

than to write:

    if( Scalar::Util::bless( $obj ) && $obj->can( 'some_method' )
    {
        # ...
    }

=head2 _can_overload

    my $rv = $self->_can_overload( undef, '""' ); # false
    my $rv = $self->_can_overload( '', '""' ); # false
    my $rv = $self->_can_overload( $some_object_not_overloaded, '""' ); # false
    # In this example, it would return false, because, although it is an overloaded value provided, that object has no support for the operators specified.
    my $rv = $self->_can_overload( $some_object_overloaded, '""' ); # false
    my $rv = $self->_can_overload( $some_good_object_overloaded, '""' ); # true
    my $rv = $self->_can_overload( $some_good_object_overloaded, [ '""', 'bool' ] ); # true

Provided with some value and a string representing an operator, or an array reference of operators, and this will return true if the value is an object that has the specified operator, or operators in case of an array reference of operators provided, overloaded.

It returns false otherwise.

=head2 _get_args_as_array

Provided with arguments and this support method will return the arguments provided as an array reference irrespective of whether they were initially provided as array reference or a simple array.

For example:

    my $array = $self->_get_args_as_array(qw( those are arguments ));
    # returns an array reference containing: 'those', 'are', 'arguments'
    my $array = $self->_get_args_as_array( [qw( those are arguments )] );
    # same result as previous example
    my $array = $self->_get_args_as_array(); # no args provided
    # returns an empty array reference

=head2 _get_args_as_hash

Provided with arguments and this support method will return the arguments provided as hash reference irrespective of whether they were initially provided as hash reference or a simple hash.

In list context, this returns an hash reference and an array reference containing the order of the properties provided.

For example:

    my $ref = $self->_get_args_as_hash( first => 'John', last => 'Doe' );
    # returns hash reference { first => 'John', last => 'Doe' }
    my $ref = $self->_get_args_as_hash({ first => 'John', last => 'Doe' });
    # same result as previous example
    my $ref = $self->_get_args_as_hash(); # no args provided
    # returns an empty hash reference
    my( $ref, $keys ) = $self->_get_args_as_hash( first => 'John', last => 'Doe' );

In the last example, C<$keys> is an L<array object|Module::Generic::Array> containing the list of properties passed an in the order they were provided, i.e. C<first> and C<last>. If the properties were provided as an hash reference, the C<$keys> returned will be the sorted list of properties, such as:

    my( $ref, $keys ) = $self->_get_args_as_hash({ last => 'Doe', first => 'John' });

Here, C<$keys> will be sorted and contain the properties in their alphabetical order.

However, this will return empty:

    my $ref = $self->_get_args_as_hash( { age => 42, city => 'Tokyo' }, some_other => 'parameter' );

This returns an empty hash reference, because although the first parameter is an hash reference, there is more than one parameter.

As of version v0.24.0, this utility method allows for more advanced use and permits embedding parameters among arguments, remove them from the list and return them.

For example:

Assuming C<@_> contains: C<foo bar debug 4 baz>

    my $ref = $self->_get_args_as_hash( @_, args_list => [qw( debug )] );

This will set C<$ref> with C<debug> only.

Even the special parameter C<args_list> does not have to be at the end and could be anywhere:

    my $ref = $self->_get_args_as_hash( 'foo', 'bar', args_list => [qw( debug )], 'debug', 4, 'baz' );

If you want to modify C<@_>,because you need its content without any params, pass C<@_> as an array reference.

    my $ref = $self->_get_args_as_hash( \@_, args_list => [qw( debug )] );
    say "@_";

C<$ref> is an hash reference that would contain C<debug> and C<@_> only contains C<foo bar baz>

You can also simply pass C<@_> as a reference to simply save memory.

Assuming C<@_> is C<foo bar baz 3 debug 4>

    my $ref = $self->_get_args_as_hash( \@_ );

This would set C<$ref> to be an hash reference with keys C<foo baz debug>

=head2 _get_symbol

    my $obj = My::Class->new;
    my $sym = $obj->_get_symbol( '$VERSION' );
    my $sym = $obj->_get_symbol( 'Other::Class' => '$VERSION' );

This returns the symbol for the given variable in the current package, or, if a package is explicitly specified, in that package.

Variables can be C<scalar> with C<$>, C<array> with C<@>, C<hash> with C<%>, or C<code> with C<&>

It returns a reference if found, otherwise, if not found, C<undef> in scalar context or an empty list in list context.

If an error occurs, it sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context or an empty list in list context.

=head2 _get_stack_trace

This will return a L<Devel::StackTrace> object initiated with the following options set:

=over 4

=item C<indent> 1

This will set an initial indent tab

=item C<skip_frames> 1

This is set to 1 so this very method is not included in the frames stack

=back

=head2 _has_base64

Provided with a value and this returns an array reference containing 2 code references: one for encoding and one for decoding.

Value provided can be a simple true value, such as C<1>, and then C<_has_base64> will check if L<Crypt::Misc> and L<MIME::Base64> are installed on the system and will use in priority L<MIME::Base64>

The value provided can also be an array reference already containing 2 code references, and in such case, that value is simply returned. Nothing more is done.

Finally, the value provided can be a module class name. C<_has_base64> knows only of L<Crypt::Misc> and L<MIME::Base64>, so if you want to use any other one, arrange yourself to pass to C<_has_base64> an array reference of 2 code references as explained above.

=head2 _has_symbol

    my $obj = My::Class->new;
    my $bool = $obj->_has_symbol( '$VERSION' );
    my $bool = $obj->_has_symbol( 'Other::Class' => '$VERSION' );

This returns true (1) if the specified variable exists in the current package, or, if a package is explicitly specified, in that package. It returns false (0) if the package does not have that variable.

Variables can be C<scalar> with C<$>, C<array> with C<@>, C<hash> with C<%>, or C<code> with C<&>

If an error occurs, it sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context or an empty list in list context.

=head2 _implement_freeze_thaw

Provided with a list of package names and this method will implement in each of them the subroutines necessary to handle L<Storable::Improved> (or the legacy L<Storable>), L<CBOR|CBOR::XS> and L<Sereal> serialisation.

In effect, it will check that the subroutines C<FREEZE>, C<THAW>, C<STORABLE_freeze> and C<STORABLE_thaw> exists or sets up simple ones if they are not defined.

This works for packages that use hash-based objects. However, you need to make sure there is no specific package requirements, and if there is, you might need to customise those subroutines by yourself.

=head2 _is_a

Provided with an object and a package name and this will return true if the object is a blessed object from this package name (or a sub package of it), or false if not.

The value of this is to reduce the burden of having to check whether the object actually exists, i.e. is not null or undef, if it is an object and if it is from that class. This allows to do it in just one method call like this:

    if( $self->_is_a( $obj, 'My::Package' ) )
    {
        # Do something
    }

Of course, if you are sure the object is actually an object, then you can directly do:

    if( $obj->isa( 'My::Package' ) )
    {
        # Do something
    }

=head2 _is_array

Provided with some data, this checks if the data is of type array, even if it is an object.

This uses L<Scalar::Util/"reftype"> to achieve that purpose. So for example, an object such as :

    package My::Module;

    sub new
    {
        return( bless( [] => ( ref( $_[0] ) || $_[0] ) ) );
    }

This would produce an object like :

    My::Module=ARRAY(0x7f8f3b035c20)

When checked with L</"_is_array"> this, would return true just like an ordinary array.

If you would use :

    ref( $object );

It would rather return the module package name: C<My::Module>

=head2 _is_class_loadable

Takes a module name and an optional version number and this will check if the module exist and can be loaded by looking at the C<@INC> and using L<version> to compare required version and existing version.

It returns true if the module can be loaded or false otherwise.

=head2 _is_class_loaded

Provided with a class/package name, this returns true if the module is already loaded or false otherwise.

It performs this test by checking if the module is already in C<%INC>.

=head2 _is_class_loadable

Provided with a package name, a.k.a. a class, and an optional version and this will endeavour to check if that class is installed and if a version is provided, if it is greater or equal to the version provided.

If the module is not already loaded and a version was provided, it uses L<Module::Metadata> to get that module version.

It returns true if the module can be loaded or false otherwise.

If an error occurred, it sets an L<error|/error> and returns C<undef>, so be sure to check whether the return value is defined.

=head2 _is_class_loaded

Provided with a package name, a.k.a. a class, and this returns true if the class has already been loaded or false otherwise.

If you are running under mod_perl, this method will use L<Apache2::Module/loaded> to find out, otherwise, it will simply check if the class exists in C<%INC>

=head2 _is_code

Provided with some value, possibly, undefined, and this returns true if it is a C<CODE>, such as a subroutine reference or an anonymous subroutine, or false otherwise.

=head2 _is_empty

This checks if a value was provided, and if it is defined, or if it has a positive length, or is a scalar object that has the method C<defined>, which returns false.

Based on those checks, it returns true (1) if it appears the value is undefined or empty, and false (0) otherwise.

=head2 _is_glob

Provided with some value, possibly, undefined, and this returns true if it is a filehandle, or false otherwise.

=head2 _is_hash

Same as L</"_is_array">, but for hash reference.

You can pass also the additional argument C<strict>, in which case, this will apply only to non-objects.

For example:

    my $hash = {};
    say $this->_is_hash( $hash ); # true
    my $obj = Foo::Bar->new;
    say $this->_is_hash( $obj ); # true
    # but...
    say $this->_is_hash( $obj => 'strict' ); # false

=head2 _is_integer

Returns true if the value provided is an integer, or false otherwise. A valid value includes an integer starting with C<+> or C<->

=head2 _is_ip

Returns true if the given IP has a syntax compliant with IPv4 or IPv6 including CIDR notation or not, false otherwise.

For this method to work, you need to have installed L<Regexp::Common::net>

=head2 _is_number

Returns true if the provided value looks like a number, false otherwise.

=head2 _is_object

Provided with some data, this checks if the data is an object. It uses L<Scalar::Util/"blessed"> to achieve that purpose.

=head2 _is_overloaded

Provided with some value, presumably an object, and this will return true if it is overloaded in some way, or false if it is not.

=head2 _is_scalar

Provided with some data, this checks if the data is of type scalar reference, e.g. C<SCALAR(0x7fc0d3b7cea0)>, even if it is an object.

=head2 _is_tty

Returns true if the program is attached to a tty (terminal), meaning that it is run interactively, or false otherwise, such as when its output is piped.

=head2 _is_uuid

Provided with a non-zero length value and this will check if it looks like a valid C<UUID>, i.e. a unique universal ID, and upon successful validation will set the value and return its representation as a L<Module::Generic::Scalar> object.

An empty string or C<undef> can be provided and will not be checked.

=head2 _list_symbols

    my $obj = My::Class->new;
    my @symbols = $obj->_list_symbols;
    my @symbols = $obj->_list_symbols( 'Other::Class' );
    # possible types are: scalar, array, hash and code
    # specify a type to get only the symbols of that type
    my @symbols = $obj->_list_symbols( 'My::Class' => 'scalar' );

This returns a list of all the symbols for the current package, or, if a package is explicitly specified, from that package.

A symbol type can optionally be specified to limit the list of symbols returned. However, if you want to specify a type, you also need to specify a package, even if it is for the current package.

If an error occurs, it sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context or an empty list in list context.

=head2 _load_class

    $self->_load_class( 'My::Module' ) || die( $self->error );
    $self->_load_class( 'My::Module', qw( :some_tags SOME_CONSTANTS_TO_IMPORT ) ) || die( $self->error );
    $self->_load_class(
        'My::Module',
        qw( :some_tags SOME_CONSTANTS_TO_IMPORT ),
        { version => 'v1.2.3', caller => 'Its::Me' }
    ) || die( $self->error );
    $self->_load_class( 'My::Module', { no_import => 1 } ) || die( $self->error );

Provided with a class/package name, some optional list of semantics to import, and, as the last parameter, an optional hash reference of options and this will attempt to load the module. This uses L<perlfunc/use>, no external module.

Upon success, it returns the package name loaded.

It traps any error with an eval and return L<perlfunc/undef> if an error occurred and sets an L</error> accordingly.

Possible options are:

=over 4

=item * C<caller>

The package name of the caller. If this is not provided, it will default to the value provided with L<perlfunc/caller>

=item * C<no_import>

Set to a true value and this will prevent the loaded module from importing anything into your namespace.

This is the equivalent of doing:

    use My::Module ();

=item * C<version>

The minimum version for this class to load. This value is passed directly to L<perlfunc/use>

=back

=head2 _load_classes

This will load multiple classes by providing it an array reference of class name to load and an optional hash or hash reference of options, similar to those provided to L</_load_class>

If one of those classes failed to load, it will return immediately after setting an L</error>.

=head2 _lvalue

This provides a generic L<lvalue|perlsub> method that can be used both in assign context or lvalue context.

As of version C<0.29.6>, this is an alias for L</_set_get_callback>, which provides more extensive features.

=head2 _obj2h

This ensures the module object is an hash reference, such as when the module object is based on a file handle for example. This permits L<Module::Generic> to work no matter what is the underlying data type blessed into an object.

=head2 _on_error

Sets or gets a code reference, acting as a callback that will be triggered upon call to L</error> or L</pass_error> with an error.

    return( $self->error( "Oops" ) ) if( $something_bad_happened );
    # or
    return( $self->pass_error( $another_error_object ) ) if( $something_bad_happened );

=head2 _parse_timestamp

Provided with a string representing a date or datetime, and this will try to parse it and return a L<DateTime> object. It will also create a L<DateTime::Format::Strptime> to preserve the original date/datetime string representation and assign it to the L<DateTime> object. So when the L<DateTime> object is stringified, it displays the same string that was originally parsed.

Supported formats are:

=over 4

=item C<2019-10-03 19-44+0000> or C<2019-10-03 19:44:01+0000>

Found in GNU PO files for example.

=item C<2019-06-19 23:23:57.000000000+0900>

Found in PostgreSQL

=item C<2019-06-20T11:08:27>

Matching ISO8601 format

=item C<2019-06-20 02:03:14>

Found in SQLite

=item C<2019-06-20 11:04:01>

Found in MySQL

=item C<Sun, 06 Oct 2019 06:41:11 GMT>

Standard HTTP dates

=item C<12 March 2001 17:07:30 JST>

=item C<12-March-2001 17:07:30 JST>

=item C<12/March/2001 17:07:30 JST>

=item C<12 March 2001 17:07>

=item C<12 March 2001 17:07 JST>

=item C<12 March 2001 17:07:30+0900>

=item C<12 March 2001 17:07:30 +0900>

=item C<Monday, 12 March 2001 17:07:30 JST>

=item C<Monday, 12 Mar 2001 17:07:30 JST>

=item C<03/Feb/1994:00:00:00 0000>

=item C<2019-06-20>

=item C<2019/06/20>

=item C<2016.04.22>

=item C<2014, Feb 17>

=item C<17 Feb, 2014>

=item C<February 17, 2009>

=item C<15 July 2021>

=item C<22.04.2016>

=item C<22-04-2016>

=item C<17. 3. 2018.>

=item C<17.III.2020>

=item C<17. III. 2018.>

=item C<20030613>

=item C<2021年7月14日>

Japanese regular date using occidental years

=item C<令和3年7月14日>

Japanese regular date using Japanese era years

=item Unix timestamp possibly followed by a dot and milliseconds

=item Relative date to current date and time

Example:

    -5Y - 5 years
    +2M + 2 months
    +3D + 3 days
    -2h - 2 hours
    -4m - 4 minutes
    -10s - 10 seconds

=item 'now'

The word now will set the return value to the current date and time

=back

=head2 _set_get

    sub name { return( shift->_set_get( 'name', @_ ) ); }

Provided with an object property name and some value and this will set or get that value for that property.

However, if the value stored is an array and is called in list context, it will return the array as a list and not the array reference. Same thing for an hash reference. It will return an hash in list context. In scalar context, it returns whatever the value is, such as array reference, hash reference or string, etc.

=head2 _set_get_array

Provided with an object property name and some data and this will store the data as an array reference.

It returns the current value stored, such as an array reference notwithstanding it is called in list or scalar context.

Example :

    sub products { return( shift->_set_get_array( 'products', @_ ) ); }

=head2 _set_get_array_as_object

Provided with an object property name and some data and this will store the data as an object of L<Module::Generic::Array>

If this is called with no data set, an object is created with no data inside and returned

Example :

    # In your module
    sub products { return( shift->_set_get_array_as_object( 'products', @_ ) ); }

And using your method:

    printf( "There are %d products\n", $object->products->length );
    $object->products->push( $new_product );

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

=over 4

=item callbacks

An hash reference of operation type C<add> (or C<set>)) to callback subroutine name or code reference pairs.

=item field

The object property name

=item wantlist

Boolean. If true, then it will return a list in list context instead of the array object.

=back

For example:

    sub children { return( shift->set_get_array_as_object({
        field => 'children',
        callbacks => 
        {
            set => '_some_add_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

=head2 _set_get_boolean

    sub is_true { return( shift->_set_get_boolean( 'is_true', @_ ) ); }

Provided with an object property name and some data and this will store the data as a boolean value.

If the data provided is a L<JSON::PP::Boolean> or L<Module::Generic::Boolean> object, the data is stored as is.

If the data is a scalar reference, its referenced value is check and L<Module::Generic::Boolean/"true"> or L<Module::Generic::Boolean/"false"> is set accordingly.

If the data is a string with value of C<true> or C<val> L<Module::Generic::Boolean/"true"> or L<Module::Generic::Boolean/"false"> is set accordingly.

Otherwise the data provided is checked if it is a true value or not and L<Module::Generic::Boolean/"true"> or L<Module::Generic::Boolean/"false"> is set accordingly.

If no value is provided, and the object property has already been set, this performs the same checks as above and returns either a L<JSON::PP::Boolean> or a L<Module::Generic::Boolean> object.

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

=over 4

=item field

The object property name

=item callbacks

An hash reference of operation type C<add> (or C<set>) to callback subroutine name or code reference pairs.

=back

For example:

    sub is_valid { return( shift->set_get_boolean({
        field => 'is_valid',
        callbacks => 
        {
            set => '_some_add_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

=head2 _set_get_callback

    sub name : lvalue { return( shift->_set_get_callback({
        get => sub
        {
            my $self = shift( @_ );
            # The context hash is available with $_
            if( $_->{list} )
            {
                return( @{$self->{name}} );
            }
            else
            {
                return( $self->{name} );
            }
        },
        set => sub
        {
            my $self = shift( @_ );
            $self->message( 1, "Got here for 'name' in setter callback" );
            return( $self->{name} = shift( @_ ) );
        },
        field => 'name'
    }, @_ ) ); }
    # ^^^^
    # Don't forget the @_ !

Then, it can be called indifferently as:

    my $rv = $obj->name( 'John' );
    # $rv is John
    $rv = $obj->name;
    # $rv is John
    $obj->name = 'Peter';
    $rv = $obj->name;
    # $rv is Peter

    $obj->colours( qw( orange blue ) );
    my @colours = $obj->colours;
    # returns a list of colours orange and blue
    my $colour = $obj->colours;
    # $colour is 'orange'

Given an hash reference of parameters, and this support method will call the accessor C<get> callback or mutator C<set> callback depending on whether any arguments were provided.

This support method supports C<lvalue> methods as described in L<perlfunc/"Lvalue subroutines">

It is similar as L<Sentinel>, but on steroid, since it handles exception, and provides context, which is often critical.

If a fatal exception occurs in a callback, it is trapped using L<try-catch block|Nice::Try> and an L<error object|Module::Generic::Exception> is set and C<undef> is returned.

However if an error occurs while operating in an C<lvalue> assigned context, such as:

    $obj->name = 'Peter';

Then, to check if there was an error, you could do:

    if( $obj->error )
    {
        # Do something here
    }

If the C<fatal> option is set to true, then it would simply die instead.

Supported options are:

=over 4

=item * C<fatal>

Boolean. If true, this will result in any exception becoming fatal and thus die.

=item * C<field>

The name of the object field for which this helper method is used. This is optional.

=item * C<get>

The accessor subroutine reference or anonymous subroutine that will handle retrieving data.

This is a mandatory option and this support method will die if this is not provided.

It will be passed the current object, and return whatever is returned in list context, or in any other context, the first value that this callback would return.

Also the special variable C<$_> will be available and contain the call context.

=item * C<set>

The mutator subroutine reference or anonymous subroutine that will handle storing data.

This is an optional option. This means you can set only an accessor C<get> callback without specifying a mutator C<set> callback.

It will be passed the current object, and the list of arguments. If the method is used as a regular method, as opposed to an lvalue subroutine, then multiple arguments may be passed:

    $obj->colours( qw( blue orange ) );

but, if used as an C<lvalue> method, of course, only one argument will be available:

    $obj->name = 'John';

Also the special variable C<$_> will be available and contain the call context.

The value returned is passed back to the caller.

=back

The C<context> provided with the special variable C<$_> inside the callback may have the following properties:

=over 4

=item * C<assign>

This is true when the call context is an C<lvalue> subroutine to which a value is being assigned, such as:

    $obj->name = 'John';

=item * C<boolean>

This is true when the call context is a boolean, such as:

    if( $obj->active )
    {
        # Do something
    }

=item * C<code>

This is true when the call context is a code reference, such as:

    $obj->my_callback->();

=item * C<count>

Contains the number of arguments expected by the caller. This is especially interesting when in list context.

=item * C<glob>

This is true when the call context is a glob.

=item * C<hash>

This is true when the call context is an hash reference, such as:

    $obj->meta({ client_id => 1234567 });
    my $id = $obj->meta->{client_id};

=item * C<list>

This is true when the call context is a list, such as:

    my @colours = $obj->colours;

=item * C<lvalue>

This is true when the call context is an C<lvalue> subroutine, such as:

    $obj->name = 'John';

=item * C<object>

This is true when the call context is an object, such as:

    $obj->something->another_method();

=item * C<refscalar>

    my $name = ${$obj->name};

=item * C<rvalue>

This is true when the call context is from the right-hand side.

    my $name = $obj->name;

=item * C<scalar>

This is true when the call context is a scalar:

    my $name = $obj->name;
    say $name; # John

=item * C<void>

This is true when the call context is void, such as:

    $obj->pointless();

=back

See also L<Want> for more on this context-rich information.

=head2 _set_get_class

Given an object property name, a dynamic class fiels definition hash (dictionary), and optional arguments, this special method will create perl packages on the fly by calling the support method L</"__create_class">

For example, consider the following:

    #!/usr/local/bin/perl
    BEGIN
    {
        use strict;
        use Data::Dumper;
    };

    {
        my $o = MyClass->new( debug => 3 );
        $o->setup->age( 42 );
        print( "Age is: ", $o->setup->age, "\n" );
        print( "Setup object is: ", $o->setup, "\n" );
        $o->setup->billing->interval( 'month' );
        print( "Billing interval is: ", $o->setup->billing->interval, "\n" );
        print( "Billing object is: ", $o->setup->billing, "\n" );
        $o->setup->rgb( 255, 122, 100 );
        print( "rgb: ", join( ', ', @{$o->setup->rgb} ), "\n" );
        exit( 0 );
    }

    package MyClass;
    BEGIN
    {
        use strict;
        use lib './lib';
        use parent qw( Module::Generic );
    };

    sub setup 
    {
        return( shift->_set_get_class( 'setup',
        {
        name => { type => 'scalar' },
        # or being lazy:
        # name => 'scalar',
        age => { type => 'number' },
        metadata => { type => 'hash' },
        rgb => { type => 'array' },
        url => { type => 'uri' },
        online => { type => 'boolean' },
        created => { type => 'datetime' },
        billing => { type => 'class', definition =>
            {
            interval => { type => 'scalar' },
            frequency => { type => 'number' },
            nickname => { type => 'scalar' },
            }}
        }) );
    }

    1;

    __END__

This will yield:

    Age is: 42
    Setup object is: MyClass::Setup=HASH(0x7fa805abcb20)
    Billing interval is: month
    Billing object is: MyClass::Setup::Billing=HASH(0x7fa804ec3f40)
    rgb: 255, 122, 100

The advantage of this over B<_set_get_hash_as_object> is that here one controls what fields / method are supported and with which data type.

=head2 _set_get_class_array

Provided with an object property name, a dictionary to create a dynamic class with L</"__create_class"> and an array reference of hash references and this will create an array of object, each one matching a set of data provided in the array reference. So for example, imagine you had a method such as below in your module :

    sub products { return( shift->_set_get_class_array( 'products', 
    {
    name        => { type => 'scalar' },
    customer    => { type => 'object', class => 'My::Customer' },
    orders      => { type => 'array_as_object' },
    active      => { type => 'boolean' },
    created     => { type => 'datetime' },
    metadata    => { type => 'hash' },
    stock       => { type => 'number' },
    url         => { type => 'uri' },
    }, @_ ) ); }

Then your script would call this method like this :

    $object->products([
    { name => 'Cool product', customer => { first_name => 'John', last_name => 'Doe', email => 'john.doe@example.com' }, active => 1, stock => 10, created => '2020-04-12T07:10:30' },
    { name => 'Awesome tool', customer => { first_name => 'Mary', last_name => 'Donald', email => 'm.donald@example.com' }, active => 1, stock => 15, created => '2020-05-12T15:20:10' },
    ]);

And this would store an array reference containing 2 objects with the above data.

=head2 _set_get_class_array_object

Same as L</=head2 _set_get_class_array>, but this returns an L<array object|Module::Generic::Array> instead of just a perl array.

When called in list context, it will return its values as a list, otherwise it will return an L<array object|Module::Generic::Array>

=head2 _set_get_code

Provided with an object property name and some code reference and this stores and retrieve the current value.

It returns under and set an error if the provided value is not a code reference.

=head2 _set_get_datetime

    sub created_on { return( shift->_set_get_datetime( 'created_on', @_ ) ); }

Provided with an object property name and asome date or datetime string and this will attempt to parse it and save it as a L<DateTime> object.

If the data is a 10 digits integer, this will treat it as a unix timestamp.

Parsing also recognise special word such as C<now>

The created L<DateTime> object is associated a L<DateTime::Format::Strptime> object which enables the L<DateTime> object to be stringified as a unix timestamp using local time stamp, whatever it is.

Even if there is no value set, and this method is called in chain, it returns a L<Module::Generic::Null> whose purpose is to enable chaining without doing anything meaningful. For example, assuming the property I<created> of your object is not set yet, but in your script you call it like this:

    $object->created->iso8601

Of course, the value of C<iso8601> will be empty since this is a fake method produced by L<Module::Generic::Null>. The return value of a method should always be checked.

=head2 _set_get_file

    sub file { return( shift->_set_get_file( 'file', @_ ) ); }

Provided with an object property name and a file and this will store the given file as a L<Module::Generic::File> object.

It returns C<undef> and set an L<error|/error> if the provided value is not a proper file.

Note that the files does not need to exist and it can also be a directory or a symbolic link or any other file on the system.

=head2 _set_get_glob

    sub handle { return( shift->_set_get_glob( 'handle', @_ ) ); }

Provided with an object property name and a glob (file handle) and this will store the given glob.

It returns C<undef> and set an L<error|/error> if the provided value is not a glob.

=head2 _set_get_hash

    sub metadata { return( shift->_set_get_hash( 'metadata', @_ ) ); }

Provided with an object property name and an hash reference and this set the property name with this hash reference.

You can even pass it an associative array, and it will be saved as a hash reference, such as :

    $object->metadata(
        transaction_id => 123,
        customer_id => 456
    );

    my $hash = $object->metadata;

=head2 _set_get_hash_as_mix_object

    sub metadata { return( shift->_set_get_hash_as_mix_object( 'metadata', @_ ) ); }

Provided with an object property name, and an optional hash reference and this returns a L<Module::Generic::Hash> object, which allows to manipulate the hash just like any regular hash, but it provides on top object oriented method described in details in L<Module::Generic::Hash>.

This is different from L</_set_get_hash_as_object> below whose keys and values are accessed as dynamic methods and method arguments.

=head2 _set_get_hash_as_object

Provided with an object property name, an optional class name and an hash reference and this does the same as in L</"_set_get_hash">, except it will create a class/package dynamically with a method for each of the hash keys, so that you can call the hash keys as method.

Also it does this recursively while handling looping, in which case, it will reuse the object previously created, and also it takes care of adapting the hash key to a proper field name, so something like C<99more-options> would become C<more_options>. If the value itself is a hash, it processes it recursively transforming C<99more-options> to a proper package name C<MoreOptions> prepended by C<$class_name> provided as argument or whatever upper package was used in recursion processing.

For example in your module :

    sub metadata { return( shift->_set_get_hash_as_object( 'metadata', @_ ) ); }

Then populating the data :

    $object->metadata({
        first_name => 'John',
        last_name => 'Doe',
        email => 'john.doe@example.com',
    });

    printf( "Customer name is %s\n", $object->metadata->last_name );

=head2 _set_get_ip

    sub ip { return( shift->_set_get_ip( 'ip', @_ ) ); }

This helper method takes a value and check if it is a valid IP address using L</_is_ip>. If C<undef> or zero-byte value is provided, it will merely accept it, as it can be used to reset the value by the caller.

If a value is successfully set, it returns a L<Module::Generic::Scalar> object representing the string passed.

From there you can pass the result to L<Net::IP> in your own code, assuming you have that module installed.

=head2 _set_get_lvalue

This is now an alias for L</_set_get_callback>

=head2 _set_get_number

Provided with an object property name and a number, and this will create a L<Module::Generic::Number> object and return it.

As of version v0.13.0 it also works as a lvalue method. See L<perlsub>

In your module:

    package MyObject;
    use parent qw( Module::Generic );
    
    sub level : lvalue { return( shift->_set_get_number( 'level', @_ ) ); }

In the script using module C<MyObject>:

    my $obj = MyObject->new;
    $obj->level = 3; # level is now 3
    # or
    $obj->level( 4 ) # level is now 4
    print( "Level is: ", $obj->level, "\n" ); # Level is 4
    print( "Is it an odd number: ", $obj->level->is_odd ? 'yes' : 'no', "\n" );
    # Is it an od number: no
    $obj->level++; # level is now 5

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

=over 4

=item * C<callbacks>

An hash reference of operation type C<add> (or C<set>) to callback subroutine name or code reference pairs.

=item * C<field>

The object property name

=item * C<undef_ok>

If this is set to a true value, this support method will allow undef to be set. Default to false, which means an undefined value passed will be ignored.

=back

For example:

    sub length { return( shift->set_get_number({
        field => 'length',
        callbacks => 
        {
            set => '_some_add_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

=head2 _set_get_number_or_object

Provided with an object property name and a number or an object and this call the value using L</"_set_get_number"> or L</"_set_get_object"> respectively

=head2 _set_get_object

    sub myobject { return( shift->_set_get_object({ field => 'myobject', no_init => 1 }, My::Class, @_ ) ); }

    sub myobject { return( shift->_set_get_object({
        field => 'myobject',
        no_init => 1,
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->new( $args->[0] ) );
        },
    }, My::Class, @_ ) ); }

    sub myobject { return( shift->_set_get_object( 'myobject', My::Class, @_ ) ); }

Provided with an object property name, a class/package name and some data and this will initiate a new object of the given class passing it the data.

The property name can also be an hash reference that will be used to provide more granular settings:

=over 4

=item * C<callback>

A callback code reference that will be passed the module class name and the arguments as an array reference.

This is used to instantiate the module object in a particular way and/or to have finer control about object instantiation.

Any fatal error during object instantiation is caught and an L<error|Module::Generic::Exception> would be set and C<undef> would be returned in scalar context, or an empty list in list context.

=item * C<field>

The actual property name

=item * C<no_init>

Boolean that, when set, instruct to not instantiate a class object if one is not instantiated yet.

=back

If you pass an undefined value, it will set the property as undefined, removing whatever was set before.

You can also provide an existing object of the given class. L</"_set_get_object"> will check the object provided does belong to the specified class or it will set an error and return undef.

It returns the object currently set, if any.

=head2 _set_get_object_lvalue

Same as L</_set_get_object_without_init> but with the possibility of setting the object value as an lvalue method:

    $o->my_property = $my_object;

=head2 _set_get_object_without_init

    sub mymethod { return( shift->_set_get_object_without_init( 'mymethod', 'Some::Module', @_ ) ); }
    # or
    sub mymethod { return( shift->_set_get_object_without_init({
        field => 'mymethod',
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->new( $args->[0] ) );
        },
    }, 'Some::Module', @_ ) ); }
    # then
    my $this = $obj->mymethod; # possibly undef if it was never instantiated
    # return the C<Some::Module> object after having instantiated it
    my $this = $obj->mymethod( some => parameters );

Sets or gets an object, but contrary to L</_set_get_object> this method will not try to instantiate the object, unless of course you pass it some values.

Alternatively, you can pass an hash reference, instead of the object property name, with the following properties:

=over 4

=item * C<field>

Mandatory. The object property name.

=item * C<callback>

Optional. A code reference like an anonymous subroutine that will be called with the class and an array reference of values provided, but possibly empty.

Whatever this returns will set the value for this object property.

=back

This is a useful callback when the module instantiation either does not use the C<new> method or does not simply take one or multiple arguments, such as when the instantiation method would require an hash of parameters, such as L<Email::Address::XS>

=head2 _set_get_object_array2

    sub mymethod { return( shift->_set_get_object_array2( 'mymethod', 'Some::Module', @_ ) ); }
    # or
    sub mymethod { return( shift->_set_get_object_array2({
        field => 'mymethod',
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->new( $args->[0] ) );
        },
    }, 'Some::Module', @_ ) ); }

Provided with an object property name, a class/package name and some array reference itself containing array references each containing hash references or objects, and this will create an array of array of objects.

Alternatively, you can pass an hash reference, instead of the object property name, with the following properties:

=over 4

=item * C<field>

Mandatory. The object property name.

=item * C<callback>

Optional. A code reference like an anonymous subroutine that will be called with the class and an array reference of values provided, but possibly empty.

=back

This is a useful callback when the module instantiation either does not use the C<new> method or does not simply take one or multiple arguments, such as when the instantiation method would require an hash of parameters, such as L<Email::Address::XS>

=head2 _set_get_object_array

    sub mymethod { return( shift->_set_get_object_array( 'mymethod', 'Some::Module', @_ ) ); }
    # or
    sub mymethod { return( shift->_set_get_object_array({
        field => 'mymethod',
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->new( $args->[0] ) );
        },
    }, 'Some::Module', @_ ) ); }

Provided with an object property name and a class/package name and similar to L</_set_get_object_array2> this will create an array reference of objects.

Alternatively, you can pass an hash reference, instead of the object property name, with the following properties:

=over 4

=item * C<field>

Mandatory. The object property name.

=item * C<callback>

Optional. A code reference like an anonymous subroutine that will be called with the class and an array reference of values provided, but possibly empty.

=back

This is a useful callback when the module instantiation either does not use the C<new> method or does not simply take one or multiple arguments, such as when the instantiation method would require an hash of parameters, such as L<Email::Address::XS>

    sub emails { return( shift->_set_get_object_array({
        field => 'emails',
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->parse_bare_address( $args->[0] ) );
        },
    }, 'Email::Address::XS', @_ ) ); }

=head2 _set_get_object_array_object

Provided with an object property name, a class/package name and some data and this will create an array of object similar to L</_set_get_object_array>, except the array produced is a L<Module::Generic::Array>

This method accepts the same arguments as L</_set_get_object_array>

=head2 _set_get_object_variant

Provided with an object property name, a class/package name and some data, and depending whether the data provided is an hash reference or an array reference, this will either instantiate an object for the given hash reference or an array of objects with the hash references in the given array.

This means the value stored for the object property will vary between an hash or array reference.

Alternatively, you can pass an hash reference, instead of the object property name, with the following properties:

=over 4

=item * C<field>

Mandatory. The object property name.

=item * C<callback>

Optional. A code reference like an anonymous subroutine that will be called with the class and an array reference of values provided, but possibly empty.

=back

This is a useful callback when the module instantiation either does not use the C<new> method or does not simply take one or multiple arguments, such as when the instantiation method would require an hash of parameters, such as L<Email::Address::XS>

    sub emails { return( shift->_set_get_object_variant({
        field => 'emails',
        callback => sub
        {
            my( $class, $args ) = @_;
            return( $class->parse_bare_address( $args->[0] ) );
        },
    }, 'Email::Address::XS', @_ ) ); }

=head2 _set_get_scalar

    sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

Provided with an object property name, and a string, possibly a number or anything really and this will set the property value accordingly. Very straightforward.

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

=over 4

=item field

The object property name

=item callbacks

An hash reference of operation type C<add> (or C<set>), or C<get> to callback subroutine name or code reference pairs.

=back

For example:

    sub name { return( shift->set_get_scalar({
        field => 'name',
        callbacks => 
        {
            set => '_some_add_callback',
            get => sub
            {
                my $self = shift( @_ );
                # do something that returns a value.
            },
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

It returns the currently value stored.

=head2 _set_get_scalar_as_object

Provided with an object property name, and a string or a scalar reference and this stores it as an object of L<Module::Generic::Scalar>

If there is already an object set for this property, the value provided will be assigned to it using L<Module::Generic::Scalar/"set">

If it is called and not value is set yet, this will instantiate a L<Module::Generic::Scalar> object with no value.

So a call to this method can safely be chained to access the L<Module::Generic::Scalar> methods. For example :

    sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

Then, calling it :

    $object->name( 'John Doe' );

Getting the value :

    my $cust_name = $object->name;
    print( "Nothing set yet.\n" ) if( !$cust_name->length );

Alternatively, you can pass an hash reference instead of an object property to provide callbacks that will be called upon addition or removal of value.

This hash reference can contain the following properties:

=over 4

=item field

The object property name

=item callbacks

An hash reference of operation type C<add> (or C<set>), or C<get> to callback subroutine name or code reference pairs.

=back

For example:

    sub name { return( shift->set_get_scalar_as_object({
        field => 'name',
        callbacks => 
        {
            set => '_some_add_callback',
        },
    }), @_ ); }

The value of the callback can be either a subroutine name or a code reference.

=head2 _set_get_scalar_or_object

Provided with an object property name, and a class/package name and this stores the value as an object calling L</"_set_get_object"> if the value is an object of class I<class> or as a string calling L</"_set_get_scalar">

If no value has been set yet, this returns a L<Module::Generic::Null> object to enable chaining.

=head2 _set_get_uri

    sub uri { return( shift->_set_get_uri( 'uri', @_ ) ); }
    sub uri { return( shift->_set_get_uri( { field => 'uri', class => 'URI::Fast' }, @_ ) ); }

Provided with an object property name, and an uri and this creates an L<URI> object and sets the property value accordingly.

Alternatively, the property name can be an hash with the following properties:

=over 4

=item * C<field>

The object property name

=item * C<class>

The URI class to use. By default, L<URI>, but you could also use L<URI::Fast>, or other class of your choice. That class will be loaded, if it is not loaded already.

=back

It accepts an L<URI> object (or any other URI class object), an uri or urn string, or an absolute path, i.e. a string starting with C</>.

It returns the current value, if any, so the return value could be undef, thus it cannot be chained. Maybe it should return a L<Module::Generic::Null> object ?

=head2 _set_get_uuid

Provided with an object, a property name, and an UUID (Universal Unique Identifier) and this stores it as an object of L<Module::Generic::Scalar>.

If an empty or undefined value is provided, it will be stored as is.

However, if there is no value and this method is called in object context, such as in chaining, this will return a special L<Module::Generic::Null> object that prevents perl error that whatever method follows was called on an undefined value.

=head2 _set_get_version

    sub version { return( shift->_set_get_version( 'version', @_ ) ); }
    # or
    sub version : lvalue { return( shift->_set_get_version( 'version', @_ ) ); }
    # or
    sub version : lvalue { return( shift->_set_get_version( { field => 'version', class => 'Perl::Version' }, @_ ) ); }

Provided with an object, a property name, and a version string and this stores it as an object of L<version> by default.

Alternatively, the property name can be an hash with the following properties:

=over 4

=item * C<field>

The object property name

=item * C<class>

The version class to use. By default, L<version>, but you could also use L<Perl::Version>, or other class of your choice. That class will be loaded, if it is not loaded already.

=back

The value can also be assigned as an lvalue. Assuming you have a method C<version> that implements C<_set_get_version>:

    $obj->version = $version;

would work, but of course also:

    $obj->version( $version );

The value can be a legitimate version string, or a version object matching the C<class> to be used, which is by default L<version>. If it is a string, it will be made an object of the class specified using C<parse> if that class supports it, or by simply calling C<new>.

When called in get mode, it will convert any value pre-set, if any, into a version object of the specified class if the value is not an object of that class already, and return it, or else it will return an empty string or undef whatever you will have set in your object for this property.

=head2 _set_symbol

    $o->_set_symbol(
        # class defaults to the current object class
        variable => '$some_scalar_ref',
        # variable value defaults to scalar reference to undef
        # or [], {}, sub{} depending on the variable type
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        variable => '$some_scalar_name',
        value => \"some string reference",
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        variable => '@some_array_name',
        value => $an_array_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        variable => '%some_array_name',
        value => $an_hash_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        variable => '&some_sub_name',
        value => $an_hash_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        # explicitly specify the variable type
        type => 'hash',
        variable => '$some_hash_name',
        value => $an_hash_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        type => 'array',
        variable => '$some_array_name',
        value => $an_array_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        type => 'scalar',
        variable => '$some_array_name',
        value => $a_scalar_reference,
    );
    # or
    $o->_set_symbol(
        class => 'Foo::Bar',
        type => 'code',
        variable => '$some_sub_name',
        # Like \&some_thing, or maybe sub{ # do something here }
        value => $a_code_reference,
    );

This method is used to add a new symbol to a given class, a.k.a. package. A proper symbol type can only be an array reference, an hash reference, a scalar, a code reference, or a glob.

This takes the following options:

=over 4

=item * C<class>

The class, or package name to add the new symbol to.

=item * C<end_line>

An integer to specify the end line of the the code reference, represented by the variable, in the class provided. If none is provided, the value for C<start_line> will be used.

=item * C<filename>

An optional filename to associate the new symbol with. For example C</some/where/file.pl>

This is only used when perl debugging is enabled and for variables that are code reference.

If no filename is provided, it will default to the value returned by L<perlfunc/caller>

=item * C<start_line>

An integer to specify the start line of the code reference, represented by the variable, in the class provided.

If no start line is provided, it will default to 0.

=item * C<type>

The optional variable type. This can be either C<array>, C<code>, C<glob>, C<hash>, or C<scalar>

If this is not explicitly specified, the type will be derived from the sigil, i.e. the first character of the variable name.

The sigil will determine how the variable will be accessed from the package name. Fer example:

    $o->_set_symbol(
        class => 'Foo::Bar',
        variable => '@some_array',
        value => [qw( John Peter Paul )],
    );

The C<@Foo::Bar::some_array> is accessible, but not C<$Foo::Bar::some_array>, but if you do:

    $o->_set_symbol(
        class => 'Foo::Bar',
        variable => '$some_array',
        value => [qw( John Peter Paul )],
    );

then, C<$Foo::Bar::some_array> is accessible, but not C<@Foo::Bar::some_array>

If you prefer providing a variable with a dollar for the name, because you use a reference, it is ok too. The type will be derived from the value you provide if the value is an array, a code reference or an hash.

There will be a slight difference in the symbol table. Variable starting with C<%>, or C<@> can only then be retrieved with the same sigil. If an array, hash or code reference variable is stored with C<$>, it will be stored as C<REF>, and must be dereferenced when the symbol is later retrieved. For example:

    $o->_set_symbol(
        variable => '$some_array_name',
        value => [qw( John Peter Paul )],
    );
    my $sym = $o->_get_symbol( '$some_array_name' );
    my $ref = $$sym;
    say "@$ref"; # John Peter Paul

Whereas:

    $o->_set_symbol(
        variable => '@some_array_name',
        value => [qw( John Peter Paul )],
    );
    my $sym = $o->_get_symbol( '@some_array_name' );
    say "@$sym"; # John Peter Paul

Acceptable value types are: C<array>, C<code>, C<glob>, C<hash>, or C<scalar>, but also C<lvalue>, C<regexp>, and C<vstring>

=item * C<value>

Specifies an appropriate value for this new symbol. If the value is not suitable for the new symbol, an error is returned.

=item * C<variable>

A variable including its C<sigil>, i.e. the first character of a variable name, such as C<$>, C<%>, C<@>, or C<&>

=back

=head2 _to_array_object

Provided with arguments or not, and this will return a L<Module::Generic::Array> object of those data.

    my $array = $self->_to_array_object( qw( Hello world ) ); # Becomes an array object of 'Hello' and 'world'
    my $array = $self->_to_array_object( [qw( Hello world )] ); # Becomes an array object of 'Hello' and 'world'

=head2 _warnings_is_enabled

Called with the class object or providing another class object as argument, and this returns true if warnings are enabled for the given class, false otherwise.

Example:

    $self->_warnings_is_enabled();
    # Providing another class object
    $self->_warnings_is_enabled( $other_object );

=head2 _warnings_is_registered

Called with the class object or providing another class object as argument, and this returns true if warnings are registered for the given class, false otherwise.

This is useful, because calling C<warnings::enabled()> to check if warnings are enabled for a given class when that class has not registered for warnings using the pragma C<use warnings::register> will produce an error C<Unknown warnings category>.

Example:

    $self->_warnings_is_registered();
    # Providing another class object
    $self->_warnings_is_registered( $other_object );

=head2 __dbh

if your module has the global variables C<DB_DSN>, this will create a database handler using L<DBI>

It will also use the following global variables in your module to set the database object: C<DB_RAISE_ERROR>, C<DB_AUTO_COMMIT>, C<DB_PRINT_ERROR>, C<DB_SHOW_ERROR_STATEMENT>, C<DB_CLIENT_ENCODING>, C<DB_SERVER_PREPARE>

If C<DB_SERVER_PREPARE> is provided and true, C<pg_server_prepare> will be set to true in the database handler.

It returns the database handler object.

=for Pod::Coverage _autoload_subs

=for Pod::Coverage _autoload_add_to_cache

=head2 DEBUG

Return the value of your global variable I<DEBUG>, if any.

=head2 VERBOSE

Return the value of your global variable I<VERBOSE>, if any.

=head1 ERROR & EXCEPTION HANDLING

This module has been developed on the idea that only the main part of the application should control the flow and trigger exit. Thus, this module and all the others in this distribution do not die, but rather set and L<error|Module::Generic/error> and return undef. So you should always check for the return value.

Error triggered are transformed into an L<Module::Generic::Exception> object, or any exception class that is specified by the object property C<_exception_class>. For example:

    sub init
    {
        my $self = shift( @_ );
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        $self->{_exception_class} = 'My::Exception';
        return( $self );
    }

Those error objects can then be retrieved by calling L</error>

If, however, you wanted errors triggered to be fatal, you can set the object property C<fatal> to a true value and/or set your package global variable C<$FATAL_ERROR> to true. When L</error> is called with an error, it will L<perlfunc/die> with the error object rather than merely returning C<undef>. For example:

    package My::Module;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        our $VERSION = 'v0.1.0';
        our $FATAL_ERROR = 1;
    };

    sub init
    {
        my $self = shift( @_ );
        $self->{fatal} = 1;
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        $self->{_exception_class} = 'My::Exception';
        return( $self );
    }

To catch fatal error you can use a C<try-catch> block such as implemented by L<Nice::Try>.

Since L<perl version 5.33.7|https://perldoc.perl.org/blead/perlsyn#Try-Catch-Exception-Handling> you can use the try-catch block using an experimental feature C<use feature 'try';>, but this does not support C<catch> by exception class.

=head1 SERIALISATION

The modules in the L<Module::Generic> distribution all supports L<Storable::Improved> (or the legacy L<Storable>), L<Sereal> and L<CBOR|CBOR::XS> serialisation, by implementing the methods C<FREEZE>, C<THAW>, C<STORABLE_freeze>, C<STORABLE_thaw>

Even the IO modules like L<Module::Generic::File::IO> and L<Module::Generic::Scalar::IO> can be serialised and deserialised if the methods C<FREEZE> and C<THAW> are used. By design the methods C<STORABLE_freeze> and C<STORABLE_thaw> are not implemented in those modules because it would trigger a L<Storable> exception "Unexpected object type (8) in store_hook()". Instead it is strongly encouraged you use the improved L<Storable::Improved> which addresses and mitigate those issues.

For serialisation with L<Sereal>, make sure to instantiate the L<Sereal encoder|Sereal::Encoder> with the C<freeze_callbacks> option set to true, otherwise, C<Sereal> will not use the C<FREEZE> and C<THAW> methods.

See L<Sereal::Encoder/"FREEZE/THAW CALLBACK MECHANISM"> for more information.

For L<CBOR|CBOR::XS>, it is recommended to use the option C<allow_sharing> to enable the reuse of references, such as:

    my $cbor = CBOR::XS->new->allow_sharing;

Also, if you use the option C<allow_tags> with L<JSON>, then all of those modules will work too, since this option enables support for the C<FREEZE> and C<THAW> methods.

=head1 SEE ALSO

L<Module::Generic::Exception>, L<Module::Generic::Array>, L<Module::Generic::Scalar>, L<Module::Generic::Boolean>, L<Module::Generic::Number>, L<Module::Generic::Null>, L<Module::Generic::Dynamic> and L<Module::Generic::Tie>, L<Module::Generic::File>, L<Module::Generic::Finfo>, L<Module::Generic::SharedMem>, L<Module::Generic::Scalar::IO>

L<Number::Format>, L<Class::Load>, L<Scalar::Util>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2000-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
