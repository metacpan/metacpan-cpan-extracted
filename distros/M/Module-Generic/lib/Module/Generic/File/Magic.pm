##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/File/Magic.pm
## Version v0.1.1
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/07
## Modified 2026/03/10
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::File::Magic;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $BACKEND @EXPORT_OK %EXPORT_TAGS %LIBMAGIC_FLAGS );
    use Exporter qw( import );
    use File::Spec  ();
    use File::Temp  ();
    use Scalar::Util qw( looks_like_number );
    our $VERSION = 'v0.1.1';

    # $BACKEND is set by the XS BOOT block at load time:
    #   "xs"   - libmagic loaded successfully via dlopen
    #   "json" - libmagic absent; JSON backend + file(1) fallback available
    # Pre-set so syntax checks without the compiled .so do not die.
    $BACKEND //= 'json';

    # NOTE: libmagic flag constants - mirrored from <magic.h>
    %LIBMAGIC_FLAGS = (
        MAGIC_NONE              => 0x0000000,
        MAGIC_DEBUG             => 0x0000001,
        MAGIC_SYMLINK           => 0x0000002,
        MAGIC_COMPRESS          => 0x0000004,
        MAGIC_DEVICES           => 0x0000008,
        MAGIC_MIME_TYPE         => 0x0000010,
        MAGIC_CONTINUE          => 0x0000020,
        MAGIC_CHECK             => 0x0000040,
        MAGIC_PRESERVE_ATIME    => 0x0000080,
        MAGIC_RAW               => 0x0000100,
        MAGIC_ERROR             => 0x0000200,
        MAGIC_MIME_ENCODING     => 0x0000400,
        MAGIC_MIME              => ( 0x0000010 | 0x0000400 ),
        MAGIC_APPLE             => 0x0000800,
        MAGIC_EXTENSION         => 0x1000000,
        MAGIC_COMPRESS_TRANSP   => 0x2000000,
        MAGIC_NO_CHECK_COMPRESS => 0x0001000,
        MAGIC_NO_CHECK_TAR      => 0x0002000,
        MAGIC_NO_CHECK_SOFT     => 0x0004000,
        MAGIC_NO_CHECK_APPTYPE  => 0x0008000,
        MAGIC_NO_CHECK_ELF      => 0x0010000,
        MAGIC_NO_CHECK_TEXT     => 0x0020000,
        MAGIC_NO_CHECK_CDF      => 0x0040000,
        MAGIC_NO_CHECK_TOKENS   => 0x0100000,
        MAGIC_NO_CHECK_ENCODING => 0x0200000,
    );

    @EXPORT_OK = (
        keys( %LIBMAGIC_FLAGS ),
        qw(
            magic_from_buffer
            magic_from_file
            magic_mime_encoding
            magic_mime_type
        )
    );
    $EXPORT_TAGS{all}       = [@EXPORT_OK];
    $EXPORT_TAGS{flags}     = [keys( %LIBMAGIC_FLAGS )];
    $EXPORT_TAGS{functions} = [qw(
        magic_from_buffer
        magic_from_file
        magic_mime_encoding
        magic_mime_type
    )];

    # Generate constant subs at compile time
    no strict 'refs';
    foreach my $name ( keys( %LIBMAGIC_FLAGS ) )
    {
        my $val = $LIBMAGIC_FLAGS{$name};
        *{"Module::Generic::File::Magic::${name}"} = sub () { $val };
    }
};

use strict;
use warnings;

# We attempt to load the XS shared library (Generic.so, shared with Module::Generic).
# MODULE = Module::Generic in the .xs means the bootstrap symbol is boot_Module__Generic,
# which XSLoader resolves by loading auto/Module/Generic/Generic.so.
# PACKAGE = Module::Generic::File::Magic means all XS functions land in our namespace.
# If the .so is absent, XSLoader croaks - we catch that and stay on the pure-Perl backends.
# When the .so is present, its BOOT block sets $BACKEND to "xs".
use XSLoader;
eval
{
    XSLoader::load( 'Module::Generic', $Module::Generic::VERSION // $VERSION );
};
if( $@ )
{
    # .so absent or failed to load - stay on the pure-Perl backend
    $BACKEND //= 'json';
}

# NOTE: Package-level backend caches (populated lazily, shared by all instances)

# JSON magic database: loaded on first use, cached for the process lifetime
my $_json_db    = undef;    # arrayref of magic entries once loaded
my $_json_error = undef;    # error message if loading failed

# Cached path to the file(1) command
my $_file_cmd   = undef;    # string path or '' (not found) once searched


sub init
{
    my $self = shift( @_ );
    $self->{flags}       = MAGIC_NONE unless( defined( $self->{flags} ) );
    $self->{magic_db}    = undef      unless( exists( $self->{magic_db} ) );
    # Max bytes to read from a buffer/file for pure-Perl backends.
    # Default 512; covers all signatures in the JSON database.
    $self->{max_read}    = 512        unless( defined( $self->{max_read} ) );
    # Internal xs state
    $self->{_cookie}     = undef;
    $self->{_init_flags} = undef;
    return( $self->SUPER::init( @_ ) );
}

# Returns the active backend: "xs", "json", or "file"
sub backend : method { return( $BACKEND ) }

sub check : method
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    return( $self->error( "check() is only available with the xs backend." ) )
        unless( $BACKEND eq 'xs' );
    $file = undef unless( defined( $file ) && length( $file ) );
    if( defined( $file ) )
    {
        return( $self->error( "File not found: $file" ) ) unless( -e $file );
    }
    my $cookie = $self->_open_cookie || return( $self->pass_error );
    return( $self->error( "magic_check is not available in this version of libmagic." ) )
        unless( Module::Generic::File::Magic::magic_has_check() );
    my $rc = Module::Generic::File::Magic::magic_check( $cookie, $file );
    return( $self->error( sprintf( "magic_check failed: %s", $self->_magic_error_str ) ) ) if( $rc != 0 );
    return( $self );
}

sub close : method
{
    my $self = shift( @_ );
    if( $BACKEND eq 'xs' && defined( $self->{_cookie} ) )
    {
        Module::Generic::File::Magic::magic_close( $self->{_cookie} );
        $self->{_cookie}     = undef;
        $self->{_init_flags} = undef;
    }
    return( $self );
}

sub compile : method
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    return( $self->error( "compile() is only available with the xs backend." ) )
        unless( $BACKEND eq 'xs' );
    return( $self->error( "A file path is required." ) )
        unless( defined( $file ) && length( $file ) );
    return( $self->error( "File not found: $file" ) ) unless( -e $file );
    my $cookie = $self->_open_cookie || return( $self->pass_error );
    return( $self->error( "magic_compile is not available in this version of libmagic." ) )
        unless( Module::Generic::File::Magic::magic_has_compile() );
    my $rc = Module::Generic::File::Magic::magic_compile( $cookie, $file );
    return( $self->error( sprintf( "magic_compile failed: %s", $self->_magic_error_str ) ) ) if( $rc != 0 );
    return( $self );
}

sub flags : method
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        return( $self->error( "flags must be an integer bitmask." ) )
            unless( looks_like_number( $val ) );
        $self->{flags} = int( $val );
        if( $BACKEND eq 'xs' && defined( $self->{_cookie} ) )
        {
            my $rc = Module::Generic::File::Magic::magic_setflags( $self->{_cookie}, $self->{flags} );
            if( $rc == -1 )
            {
                return( $self->error( sprintf( "magic_setflags failed: %s", $self->_magic_error_str ) ) );
            }
            $self->{_init_flags} = $self->{flags};
        }
        return( $self );
    }
    if( $BACKEND eq 'xs' && defined( $self->{_cookie} )
        && Module::Generic::File::Magic::magic_has_getflags() )
    {
        my $live = Module::Generic::File::Magic::magic_getflags( $self->{_cookie} );
        return( $live ) if( defined( $live ) );
    }
    return( $self->{flags} );
}

sub from_buffer : method
{
    my $self   = shift( @_ );
    my $buffer = shift( @_ );
    return( $self->error( "A buffer (scalar) is required." ) )
        unless( defined( $buffer ) );
    if( utf8::is_utf8( $buffer ) )
    {
        utf8::downgrade( $buffer, 1 )
            or return( $self->error(
                "Buffer contains characters above U+00FF. "
                . "Encode it explicitly (e.g. Encode::encode('UTF-8', \$buf)) "
                . "before passing to from_buffer()."
            ) );
    }
    if( $BACKEND eq 'xs' )
    {
        my $cookie = $self->_open_cookie || return( $self->pass_error );
        my $result = Module::Generic::File::Magic::magic_buffer( $cookie, $buffer );
        return( $self->error( sprintf( "magic_buffer failed: %s", $self->_magic_error_str ) ) )
            unless( defined( $result ) );
        # magic_buffer() is unreliable for end-of-file anchored formats (e.g. ZIP)
        # on some libmagic versions (5.39, 5.46). Fall back to magic_file() via a
        # temp file when the result is the generic catch-all type.
        if( $result eq 'application/octet-stream' )
        {
            my $tmp = $self->new_tempfile( cleanup => 1 );
            $tmp->unload( $buffer, { binmode => 'raw', autoflush => 1 }) ||
                return( $self->pass_error );
            my $file_result = Module::Generic::File::Magic::magic_file( $cookie, "$tmp" );
            $result = $file_result
                if( defined( $file_result ) && $file_result ne 'application/octet-stream' );
        }
        return( $result );
    }
    else
    {
        return( $self->_pure_perl_detect_buffer( $buffer, $self->{flags} ) );
    }
}

sub from_file : method
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    return( $self->error( "A file path is required." ) )
        unless( defined( $file ) && length( $file ) );
    return( $self->error( "File not found: $file" ) ) unless( -e $file );
    if( $BACKEND eq 'xs' )
    {
        my $cookie = $self->_open_cookie || return( $self->pass_error );
        my $result = Module::Generic::File::Magic::magic_file( $cookie, $file );
        return( $self->error( sprintf( "magic_file failed: %s", $self->_magic_error_str ) ) ) unless( defined( $result ) );
        return( $result );
    }
    else
    {
        # Read up to max_read bytes from the file
        my $buffer = $self->_read_file_head( $file ) // return( $self->pass_error );
        return( $self->_pure_perl_detect_buffer( $buffer, $self->{flags}, $file ) );
    }
}

sub from_filehandle : method
{
    my $self = shift( @_ );
    my $fh   = shift( @_ );
    return( $self->error( "A filehandle is required." ) )
        unless( defined( $fh ) );
    if( $BACKEND eq 'xs' )
    {
        my $fd = fileno( $fh );
        return( $self->error(
            "Could not obtain a file descriptor from the supplied filehandle. "
            . "In-memory filehandles are not supported by the xs backend."
        ) ) unless( defined( $fd ) );
        my $cookie = $self->_open_cookie || return( $self->pass_error );
        my $result = Module::Generic::File::Magic::magic_descriptor( $cookie, $fd );
        return( $self->error( sprintf( "magic_descriptor failed: %s", $self->_magic_error_str ) ) ) unless( defined( $result ) );
        return( $result );
    }
    else
    {
        # Read from the filehandle
        my $buf  = '';
        my $max  = $self->{max_read} // 512;
        read( $fh, $buf, $max );
        return( $self->_pure_perl_detect_buffer( $buf, $self->{flags} ) );
    }
}

sub list : method
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    return( $self->error( "list() is only available with the xs backend." ) )
        unless( $BACKEND eq 'xs' );
    $file = undef unless( defined( $file ) && length( $file ) );
    if( defined( $file ) )
    {
        return( $self->error( "File not found: $file" ) ) unless( -e $file );
    }
    my $cookie = $self->_open_cookie || return( $self->pass_error );
    return( $self->error( "magic_list is not available in this version of libmagic." ) )
        unless( Module::Generic::File::Magic::magic_has_list() );
    my $rc = Module::Generic::File::Magic::magic_list( $cookie, $file );
    return( $self->error( sprintf( "magic_list failed: %s", $self->_magic_error_str ) ) ) if( $rc != 0 );
    return( $self );
}

sub magic_db : method
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $db = shift( @_ );
        if( defined( $db ) && length( $db ) )
        {
            return( $self->error( "Magic database file not found: $db" ) )
                unless( -e $db );
        }
        else
        {
            $db = undef;
        }
        $self->{magic_db} = $db;
        $self->close;
        return( $self );
    }
    return( $self->{magic_db} );
}

sub max_read : method
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        return( $self->error( "max_read must be a positive integer." ) )
            unless( looks_like_number( $val ) && int( $val ) > 0 );
        $self->{max_read} = int( $val );
        return( $self );
    }
    return( $self->{max_read} );
}

# NOTE: mime_encoding_from_*
sub mime_encoding_from_buffer : method
{
    my $self = shift( @_ );
    return( $self->_with_flags( MAGIC_MIME_ENCODING, 'from_buffer', @_ ) );
}

sub mime_encoding_from_file : method
{
    my $self = shift( @_ );
    return( $self->_with_flags( MAGIC_MIME_ENCODING, 'from_file', @_ ) );
}

sub mime_encoding_from_filehandle : method
{
    my $self = shift( @_ );
    return( $self->_with_flags( MAGIC_MIME_ENCODING, 'from_filehandle', @_ ) );
}

# NOTE: mime_from_*
sub mime_from_buffer : method
{
    my $self = shift( @_ );
    return( $self->_with_flags( MAGIC_MIME, 'from_buffer', @_ ) );
}

sub mime_from_file : method
{
    my $self = shift( @_ );
    return( $self->_with_flags( MAGIC_MIME, 'from_file', @_ ) );
}

sub mime_from_filehandle : method
{
    my $self = shift( @_ );
    return( $self->_with_flags( MAGIC_MIME, 'from_filehandle', @_ ) );
}

# NOTE: mime_type_from_*
sub mime_type_from_buffer : method
{
    my $self = shift( @_ );
    return( $self->_with_flags( MAGIC_MIME_TYPE, 'from_buffer', @_ ) );
}

sub mime_type_from_file : method
{
    my $self = shift( @_ );
    return( $self->_with_flags( MAGIC_MIME_TYPE, 'from_file', @_ ) );
}

sub mime_type_from_filehandle : method
{
    my $self = shift( @_ );
    return( $self->_with_flags( MAGIC_MIME_TYPE, 'from_filehandle', @_ ) );
}

sub version : method
{
    my $self = shift( @_ );
    return( undef ) unless( $BACKEND eq 'xs' );
    return( undef ) unless( Module::Generic::File::Magic::magic_has_version() );
    my $v = Module::Generic::File::Magic::magic_version();
    return( undef ) unless( defined( $v ) );
    return( sprintf( '%d.%02d', int( $v / 100 ), $v % 100 ) );
}

sub DESTROY
{
    my $self = shift( @_ );
    $self->close
        if( defined( $self ) && ref( $self ) && defined( $self->{_cookie} ) );
}

# NOTE: Exportable procedural interface
sub magic_from_buffer
{
    my $buffer = shift( @_ );
    my $flags  = @_ ? shift( @_ ) : MAGIC_NONE;
    my $obj = __PACKAGE__->new( flags => $flags )
        || die( __PACKAGE__->error . "\n" );
    return( $obj->from_buffer( $buffer ) );
}

sub magic_from_file
{
    my $file  = shift( @_ );
    my $flags = @_ ? shift( @_ ) : MAGIC_NONE;
    my $obj = __PACKAGE__->new( flags => $flags )
        || die( __PACKAGE__->error . "\n" );
    return( $obj->from_file( $file ) );
}

sub magic_mime_encoding
{
    my $file = shift( @_ );
    my $obj = __PACKAGE__->new( flags => MAGIC_MIME_ENCODING )
        || die( __PACKAGE__->error . "\n" );
    return( $obj->from_file( $file ) );
}

sub magic_mime_type
{
    my $file = shift( @_ );
    my $obj = __PACKAGE__->new( flags => MAGIC_MIME_TYPE )
        || die( __PACKAGE__->error . "\n" );
    return( $obj->from_file( $file ) );
}

# _find_file_command()
# Locates the file(1) executable; result cached after first call.
sub _find_file_command
{
    my $self = shift( @_ );
    # Return cached result: defined string = found path, empty string = not found
    return( $_file_cmd ) if( defined( $_file_cmd ) && length( $_file_cmd ) );
    return( undef )      if( defined( $_file_cmd ) && !length( $_file_cmd ) );
    foreach my $candidate (
        qw(
            /usr/bin/file
            /bin/file
            /usr/local/bin/file
            /opt/homebrew/bin/file
            /opt/local/bin/file
        )
    )
    {
        if( -x $candidate )
        {
            $_file_cmd = $candidate;
            return( $_file_cmd );
        }
    }
    require File::Which;
    my $try_bin = File::Which::which( 'file' );
    if( -x( $try_bin ) )
    {
        $_file_cmd = $try_bin;
        return( $_file_cmd );
    }
    $_file_cmd = '';
    return( undef );
}

# _file_backend_path( $path, $flags )
# Invokes file(1) and parses its output.
sub _file_backend_path
{
    my $self  = shift( @_ );
    my $path  = shift( @_ );
    my $flags = shift( @_ ) // MAGIC_NONE;

    my $file_cmd = $self->_find_file_command;
    return( $self->error( "The file(1) command was not found. Install it with: sudo apt-get install file" ) ) 
        unless( defined( $file_cmd ) );

    my $want_mime = ( $flags & ( MAGIC_MIME_TYPE | MAGIC_MIME_ENCODING | MAGIC_MIME ) );
    my @cmd = ( $file_cmd, '-b' );
    push( @cmd, '-i' ) if( $want_mime );
    push( @cmd, '-z' ) if( $flags & MAGIC_COMPRESS );
    push( @cmd, '-L' ) if( $flags & MAGIC_SYMLINK );
    push( @cmd, $path );

    my $output;
    {
        local $SIG{PIPE} = 'IGNORE';
        open( my $fh, '-|', @cmd ) or
            return( $self->error( "Could not run file(1): $!" ) );
        $output = do { local $/; <$fh> };
        close( $fh );
    }
    return( $self->error( "file(1) produced no output for: $path" ) )
        unless( defined( $output ) && length( $output ) );
    chomp( $output );
    return( $self->_parse_file_output( $output, $flags ) );
}

# _load_json_db()
# Loads and caches the magic.json database.
# Returns the arrayref on success, undef on failure.
sub _load_json_db
{
    my $self = shift( @_ );
    return( $_json_db ) if( defined( $_json_db ) );
    return( undef )     if( defined( $_json_error ) );

    # Locate magic.json relative to this module's path
    my $pm_path = $INC{'Module/Generic/File/Magic.pm'};
    my $json_path;
    if( defined( $pm_path ) )
    {
        # $pm_path is .../lib/Module/Generic/File/Magic.pm
        # JSON is at .../lib/Module/Generic/File/magic.json
        ( $json_path = $pm_path ) =~ s/Magic\.pm$/magic.json/;
    }

    unless( defined( $json_path ) && -r( $json_path ) )
    {
        $_json_error = "magic.json not found (looked near ${\($pm_path//'?')})";
        return( undef );
    }

    local $@;
    my $json_text = do
    {
        open( my $fh, '<:utf8', $json_path ) or
            do{ $_json_error = "Cannot open $json_path: $!"; return( undef ) };
        local $/;
        <$fh>;
    };

    my $data = eval
    {
        require JSON;
        JSON->new->utf8->decode( $json_text );
    };
    if( $@ )
    {
        $_json_error = "Failed to parse magic.json: $@";
        return( undef );
    }

    # Pre-compile hex strings to byte strings for faster matching
    foreach my $entry ( @$data )
    {
        foreach my $m ( @{$entry->{matches}} )
        {
            $m->{_bytes} = pack( 'H*', $m->{bytes} );
            $m->{_mask}  = defined( $m->{mask} ) ? pack( 'H*', $m->{mask} ) : undef;
            _precompile_match( $m );
        }
    }

    $_json_db = $data;
    return( $_json_db );
}

# _magic_error_str()
sub _magic_error_str
{
    my $self = shift( @_ );
    return( '' ) unless( $BACKEND eq 'xs' && defined( $self->{_cookie} ) );
    my $msg = Module::Generic::File::Magic::magic_error( $self->{_cookie} );
    return( defined( $msg ) ? $msg : '' );
}

# _match_bytes( $buf, $match_entry ) -> bool
# Tests a single match entry (and its sub-matches) against $buf.
sub _match_bytes
{
    my( $buf, $m ) = @_;
    my $want   = $m->{_bytes};
    my $mask   = $m->{_mask};
    my $offset = $m->{offset};
    my $range  = $m->{range} // 0;
    my $wlen   = length( $want );
    my $blen   = length( $buf );

    my $end = $offset + $range;
    $end    = $blen - $wlen if( $end > $blen - $wlen );

    foreach( my $pos = $offset; $pos <= $end; $pos++ )
    {
        last if( $pos + $wlen > $blen );
        my $chunk = substr( $buf, $pos, $wlen );
        if( defined( $mask ) )
        {
            # Apply mask: (buf & mask) == (want & mask)
            # Since want is already stored masked (if mask was applied at build time),
            # we just need: (chunk & mask) == want
            my $masked = $chunk & $mask;
            next unless( $masked eq $want );
        }
        else
        {
            next unless( $chunk eq $want );
        }
        # Parent matched - now check AND sub-matches
        if( $m->{and} )
        {
            my $all_ok = 1;
            foreach my $sub ( @{$m->{and}} )
            {
                unless( _match_bytes( $buf, $sub ) )
                {
                    $all_ok = 0;
                    last;
                }
            }
            return(1) if( $all_ok );
        }
        else
        {
            return(1);
        }
    }
    return(0);
}

# _open_cookie()
# Returns the current magic_t cookie, opening a new one if needed.
# Only called when $BACKEND eq "xs".
sub _open_cookie
{
    my $self  = shift( @_ );
    my $flags = $self->{flags} // MAGIC_NONE;

    if( defined( $self->{_cookie} ) &&
        defined( $self->{_init_flags} ) &&
        $self->{_init_flags} == $flags
    )
    {
        return( $self->{_cookie} );
    }

    $self->close;

    my $cookie = Module::Generic::File::Magic::magic_open( $flags );
    return( $self->error( "magic_open failed: could not allocate a magic cookie." ) )
        unless( $cookie );

    my $db = $self->{magic_db};
    my $rc = Module::Generic::File::Magic::magic_load( $cookie, defined( $db ) ? $db : undef );
    if( $rc != 0 )
    {
        my $err = Module::Generic::File::Magic::magic_error( $cookie ) // 'unknown error';
        Module::Generic::File::Magic::magic_close( $cookie );
        return( $self->error( "magic_load failed: $err" ) );
    }

    $self->{_cookie}     = $cookie;
    $self->{_init_flags} = $flags;
    return( $cookie );
}

# _parse_file_output( $output, $flags ) -> string
# Parses the output of file(1) according to the requested flags.
sub _parse_file_output
{
    my $self   = shift( @_ );
    my $output = shift( @_ );
    my $flags  = shift( @_ ) // MAGIC_NONE;

    my $is_mime_type     = ( $flags & MAGIC_MIME_TYPE )     && !( $flags & MAGIC_MIME_ENCODING );
    my $is_mime_encoding = ( $flags & MAGIC_MIME_ENCODING ) && !( $flags & MAGIC_MIME_TYPE );

    if( $is_mime_type )
    {
        ( my $type = $output ) =~ s/\s*;.*$//;
        return( $type );
    }
    elsif( $is_mime_encoding )
    {
        return( $1 ) if( $output =~ /charset=(\S+)/ );
        return( 'binary' );
    }
    return( $output );
}

# _precompile_match( $m )
# Recursively pre-compiles hex strings in match entries to byte strings.
sub _precompile_match
{
    my $m = shift( @_ );
    if( $m->{and} )
    {
        foreach my $sub ( @{$m->{and}} )
        {
            $sub->{_bytes} = pack( 'H*', $sub->{bytes} );
            $sub->{_mask}  = defined( $sub->{mask} ) ? pack( 'H*', $sub->{mask} ) : undef;
            _precompile_match( $sub );
        }
    }
}

# _pure_perl_detect_buffer( $buf, $flags, $filepath )
# Runs the JSON -> text-heuristic -> file(1) detection chain on a byte buffer.
# $filepath is optional and used only for file(1) fallback.
sub _pure_perl_detect_buffer
{
    my $self     = shift( @_ );
    my $buf      = shift( @_ );
    my $flags    = shift( @_ ) // MAGIC_NONE;
    my $filepath = shift( @_ );    # optional

    my $want_mime = ( $flags & ( MAGIC_MIME_TYPE | MAGIC_MIME_ENCODING | MAGIC_MIME ) );

    # NOTE: Level 2: JSON database
    my $mime_type = $self->_run_json_detection( $buf );

    # NOTE: Level 2.5: text heuristic
    # If no binary signature matched, classify the buffer as text/plain or
    # application/octet-stream based on byte content.  This matches the
    # behaviour of libmagic for unrecognised file types:
    #   - >85% printable ASCII (0x09/0x0A/0x0D/0x20–0x7E) -> text/plain
    #   - otherwise -> application/octet-stream
    # We only apply this when $filepath is set (from_file) so that
    # from_buffer() for unknown binary data still falls through to file(1).
    unless( defined( $mime_type ) )
    {
        if( length( $buf ) > 0 )
        {
            my $printable = ( $buf =~ tr/   

 -~// );
            if( $printable / length( $buf ) > 0.85 )
            {
                $mime_type = 'text/plain';
            }
            elsif( defined( $filepath ) )
            {
                $mime_type = 'application/octet-stream';
            }
        }
    }

    # NOTE: Level 3: file(1) subprocess
    unless( defined( $mime_type ) )
    {
        # Use the file path directly if available; otherwise write a temp file
        my $path = $filepath;
        my $tmp;
        unless( defined( $path ) )
        {
            eval
            {
                $tmp  = File::Temp->new( UNLINK => 1, SUFFIX => '.bin' );
                binmode( $tmp );
                print( $tmp $buf );
                $tmp->flush;
                $path = $tmp->filename;
            };
            return( $self->error( "Could not create temporary file: $@" ) ) if( $@ );
        }
        return( $self->_file_backend_path( $path, $flags ) );
    }

    # NOTE: Format result according to flags
    return( $self->_format_mime_result( $mime_type, $flags ) );
}

# _format_mime_result( $mime_type, $flags ) -> string
# Given a MIME type string, returns the appropriate representation
# for the requested flags (type only, encoding only, or full).
sub _format_mime_result
{
    my $self      = shift( @_ );
    my $mime_type = shift( @_ );
    my $flags     = shift( @_ ) // MAGIC_NONE;

    my $is_type     = ( $flags & MAGIC_MIME_TYPE )     && !( $flags & MAGIC_MIME_ENCODING );
    my $is_encoding = ( $flags & MAGIC_MIME_ENCODING ) && !( $flags & MAGIC_MIME_TYPE );
    my $is_mime     = ( $flags & MAGIC_MIME_TYPE )     &&  ( $flags & MAGIC_MIME_ENCODING );

    # Determine charset for binary formats
    my $charset = _charset_for_mime( $mime_type );

    if( $is_type )
    {
        return( $mime_type );
    }
    elsif( $is_encoding )
    {
        return( $charset );
    }
    elsif( $is_mime )
    {
        return( "$mime_type; charset=$charset" );
    }
    # MAGIC_NONE or other: return a brief textual description
    # For the pure-Perl backends, we just return the MIME type as the description
    # since we don't have libmagic's verbose text output
    return( $mime_type );
}

# _charset_for_mime( $mime_type ) -> charset string
# Returns a reasonable charset for a given MIME type.
# Text types default to binary (we don't do text encoding detection here;
# that requires reading the content which is better left to libmagic or file(1)).
sub _charset_for_mime
{
    my $mime = shift( @_ ) // '';
    return( 'binary' ) if( $mime =~ m{^(application|audio|video|image)/} );
    return( 'binary' ) if( $mime =~ m{^application/} );
    # Text types - return 'binary' too; proper charset detection needs more work
    return( 'binary' );
}

# _read_file_head( $path ) -> buffer | undef
# Reads up to max_read bytes from the beginning of a file.
sub _read_file_head
{
    my $self = shift( @_ );
    my $path = shift( @_ );
    my $max  = $self->{max_read} // 512;
    open( my $fh, '<:raw', $path ) or
        return( $self->error( "Cannot read $path: $!" ) );
    my $buf = '';
    read( $fh, $buf, $max );
    close( $fh );
    return( $buf );
}

# _run_json_detection( $buf ) -> mime_type | undef
# Tests the JSON magic database against $buf.
# Returns the MIME type of the first matching entry (highest priority first).
sub _run_json_detection
{
    my $self = shift( @_ );
    my $buf  = shift( @_ );

    my $db = $self->_load_json_db;
    return( undef ) unless( defined( $db ) );

    foreach my $entry ( @$db )
    {
        foreach my $m ( @{$entry->{matches}} )
        {
            if( _match_bytes( $buf, $m ) )
            {
                return( $entry->{mime} );
            }
        }
    }
    return( undef );
}

# _with_flags( $flags, $method, @args )
# Temporarily overrides flags, runs $method, restores original state.
sub _with_flags
{
    my $self   = shift( @_ );
    my $flags  = shift( @_ );
    my $method = shift( @_ );

    my $orig_flags = $self->{flags};
    $self->close if( $BACKEND eq 'xs' );
    $self->{flags} = $flags;

    my $result = $self->$method( @_ );

    $self->close if( $BACKEND eq 'xs' );
    $self->{flags} = $orig_flags;

    return( $self->pass_error ) unless( defined( $result ) );
    return( $result );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::File::Magic - File type and MIME detection with 3-level backend cascade

=head1 SYNOPSIS

    use Module::Generic::File::Magic qw( :flags );

    my $magic = Module::Generic::File::Magic->new( flags => MAGIC_MIME_TYPE ) ||
        die( Module::Generic::File::Magic->error );

    # Which backend is active?
    printf "Backend: %s\n", $magic->backend;    # xs, json, or file

    # Detect from a file path
    my $mime = $magic->from_file( '/path/to/archive.tar.gz' ) ||
        die( $magic->error );
    # -> "application/gzip"

    # Detect from an in-memory buffer
    open( my $fh, '<:raw', '/path/to/file' ) or die( $! );
    read( $fh, my $buf, 4096 );
    close( $fh );
    my $mime = $magic->from_buffer( $buf ) || die( $magic->error );

    # Detect from an open filehandle
    open( my $fh, '<:raw', '/path/to/file' ) or die( $! );
    my $mime = $magic->from_filehandle( $fh ) || die( $magic->error );

    # Convenience wrappers
    my $type = $magic->mime_type_from_file( '/path/to/file' );
    my $enc  = $magic->mime_encoding_from_file( '/path/to/file' );
    my $full = $magic->mime_from_file( '/path/to/file' );
    # -> "application/gzip; charset=binary"

    # Control the read size for pure-Perl backends (default: 512 bytes)
    my $magic2 = Module::Generic::File::Magic->new(
        flags    => MAGIC_MIME_TYPE,
        max_read => 1024,
    ) || die( Module::Generic::File::Magic->error );

    # Change max_read at any time
    $magic->max_read(1024);

    # Procedural interface
    use Module::Generic::File::Magic qw( :functions );
    my $mime = magic_mime_type( '/path/to/file' );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

C<Module::Generic::File::Magic> detects file types and MIME types using a three-level cascade, automatically selecting the best available backend:

=over 4

=item B<Level 1 - xs> (preferred)

C<libmagic.so.1> is loaded at runtime via C<dlopen(3)> - no C<magic.h>, no C<libmagic-dev> package required at build time. Full libmagic accuracy and performance. The C<MAGIC_COMPRESS>, C<MAGIC_SYMLINK>, and all other flags
are fully supported. C<compile()>, C<check()>, and C<list()> are only available at this level.

=item B<Level 2 - json>

C<libmagic> is absent. The module loads C<lib/Module/Generic/File/magic.json> (generated from the freedesktop.org shared-mime-info database, bundled with the distribution) and runs pure-Perl byte-pattern matching. Covers ~500 MIME types with magic signatures.

=item B<Level 3 - file>

No pattern matched at level 2. Invokes C<file(1)> in a subprocess as a last resort. C<from_buffer> writes a temporary file via L<File::Temp>.

=back

The active backend is available via C<< $magic->backend >> and the package variable C<$Module::Generic::File::Magic::BACKEND>.

Note that within the json backend, a text-content heuristic is applied before falling through to C<file(1)>.

=head1 CONSTRUCTOR

=head2 new

    my $magic = Module::Generic::File::Magic->new( %opts ) ||
        die( Module::Generic::File::Magic->error );

=over 4

=item * C<flags> - integer bitmask (default: C<MAGIC_NONE>)

=item * C<magic_db> - path to a custom C<.mgc> database (xs backend only)

=item * C<max_read> - maximum bytes read from a file for pure-Perl backends (default: C<512>)

=back

=head1 METHODS

=head2 backend

Returns the name of the active backend: C<"xs">, C<"json">, or C<"file">. Note that the reported value is the I<top-level> configured backend; the actual detection at runtime may cascade through multiple levels.

=head2 check( [ $filename ] )

Validates a magic database. B<xs backend only.>

=head2 close

Releases the C<magic_t> cookie. No-op on non-xs backends.

=head2 compile( $filename )

Compiles a magic source file into a C<.mgc> database. B<xs backend only.>

=head2 flags

Getter/setter for the libmagic flags bitmask.

=head2 from_buffer( $scalar )

Detects type from a raw byte scalar.

=head2 from_file( $path )

Detects type from a file path.

=head2 from_filehandle( $fh )

Detects type from an open filehandle.

=head2 list( [ $filename ] )

Prints magic database entries to stdout. B<xs backend only.>

=head2 magic_db

Getter/setter for the custom magic database path (xs backend only).

=head2 max_read( [ $bytes ] )

Getter/setter for the maximum number of bytes read from a file when using pure-Perl backends. The default is 512 bytes, which covers all signatures in the bundled JSON database. Increase this value for formats whose signatures appear at large offsets (e.g. C<application/x-tar> at offset 257).

=head2 mime_encoding_from_buffer / _from_file / _from_filehandle

Returns the charset (e.g. C<binary>).

=head2 mime_from_buffer / _from_file / _from_filehandle

Returns e.g. C<application/gzip; charset=binary>.

=head2 mime_type_from_buffer / _from_file / _from_filehandle

Returns e.g. C<application/gzip>.

=head2 version

Returns the libmagic version string (e.g. C<"5.45">), or C<undef> when not using the xs backend.

=head1 EXPORTED FUNCTIONS

    use Module::Generic::File::Magic qw( :functions );
    magic_from_buffer( $scalar [, $flags] )
    magic_from_file( $path [, $flags] )
    magic_mime_type( $path )
    magic_mime_encoding( $path )

=head1 EXPORT TAGS

C<:flags>, C<:functions>, C<:all>

=head1 FLAG CONSTANTS

    MAGIC_NONE              No flags (default)
    MAGIC_DEBUG             Print debug messages to stderr  [xs only]
    MAGIC_SYMLINK           Follow symlinks
    MAGIC_COMPRESS          Examine inside compressed files
    MAGIC_DEVICES           Look at block/char device content  [xs only]
    MAGIC_MIME_TYPE         Return MIME type
    MAGIC_MIME_ENCODING     Return MIME charset
    MAGIC_MIME              MAGIC_MIME_TYPE | MAGIC_MIME_ENCODING
    MAGIC_CONTINUE          Return all matches  [xs only]
    MAGIC_CHECK             Print warnings  [xs only]
    MAGIC_PRESERVE_ATIME    Restore access time  [xs only]
    MAGIC_RAW               Do not convert unprintable chars  [xs only]
    MAGIC_ERROR             Treat ENOENT as real error  [xs only]
    MAGIC_APPLE             Return Apple creator/type  [xs only]
    MAGIC_EXTENSION         Return file extensions  [xs only]
    MAGIC_NO_CHECK_*        Disable specific checks  [xs only]

Flags marked C<[xs only]> are silently ignored on non-xs backends.

=head1 INSTALLATION

The only requirement for the xs backend is the C<libmagic1> runtime package:

    # Debian / Ubuntu
    sudo apt-get install libmagic1

    # RPM-based
    sudo yum install file-libs

    # macOS (Homebrew)
    brew install libmagic

No C<libmagic-dev> or C<file-devel> required. The module compiles and works on any system with a C compiler (the same one that built Perl).

=head1 FILES

=over 4

=item * C<lib/Module/Generic/File/magic.json>

Bundled magic signature database generated from the freedesktop.org shared-mime-info XML. Used by the json backend. To regenerate:

    perl scripts/gen_magic_json.pl [xml_path] [out_json_path]

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::Finfo>, L<File::LibMagic>, L<File::MimeInfo>

The C<libmagic(3)> man page.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2026 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
