##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/File.pm
## Version v0.8.1
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/05/20
## Modified 2024/02/21
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::File;
BEGIN
{
    use v5.12.0;
    use strict;
    use warnings;
    use warnings::register;
    use version;
    use parent qw( Module::Generic );
    use vars qw( $OS2SEP $DIR_SEP $MODE_BITS $DEFAULT_MMAP_SIZE $FILES_TO_REMOVE 
                 $MMAP_USE_FILE_MAP $GLOBBING $ILLEGAL_CHARACTERS );
    use Data::UUID ();
    use Fcntl qw( :DEFAULT :flock SEEK_SET SEEK_CUR SEEK_END );
    use File::Copy ();
    use File::Glob ();
    use File::Spec ();
    use IO::Dir ();
    use IO::File ();
    use Module::Generic::Finfo;
    # constants are already exported with the use Fcntl
    use Module::Generic::File::IO ();
    # use Nice::Try;
    use Scalar::Util ();
    use URI ();
    use URI::file ();
    use Want;
    our @EXPORT_OK = qw( cwd file rmtree rootdir stdin stderr stdout sys_tmpdir tempfile tempdir );
    our %EXPORT_TAGS = %Fcntl::EXPORT_TAGS;
    # Export Fcntl O_* constants for convenience
    our @EXPORT = grep( /^O_/, keys( %Fcntl:: ) );
    use overload (
        q{""}    => sub{ $_[0]->filename },
        bool     => sub{ 1 },
        fallback => 1,
    );
    use constant HAS_PERLIO_MMAP => ( version->parse($]) >= version->parse('v5.16.0') ? 1 : 0 );
    # https://en.wikipedia.org/wiki/Path_(computing)
    # perlport
    our $OS2SEP  =
    {
    amigaos     => '/',
    android     => '/',
    aix         => '/',
    bsdos       => '/',
    beos        => '/',
    bitrig      => '/',
    cygwin      => '/',
    darwin      => '/',
    dec_osf     => '/',
    dgux        => '/',
    dos         => "\\",
    dragonfly   => '/',
    dynixptx    => '/',
    freebsd     => '/',
    gnu         => '/',
    gnukfreebsd => '/',
    haiku       => '/',
    hpux        => '/',
    interix     => '/',
    iphoneos    => '/',
    irix        => '/',
    linux       => '/',
    machten     => '/',
    # alias
    mac         => ':',
    macos       => ':',
    midnightbsd => '/',
    minix       => '/',
    mirbsd      => '/',
    mswin32     => "\\",
    msys        => '/',
    netbsd      => '/',
    netware     => "\\",
    next        => '/',
    nto         => '/',
    openbsd     => '/',
    os2         => '/',
    # Extended Binary Coded Decimal Interchange Code
    os390       => '/',
    os400       => '/',
    qnx         => '/',
    riscos      => '.',
    sco         => '/',
    sco_sv      => '/',
    solaris     => '/',
    sunos       => '/',
    svr4        => '/',
    svr5        => '/',
    symbian     => "\\",
    unicos      => '/',
    unicosmk    => '/',
    vms         => '/',
    vos         => '>',
    win32       => "\\",
    };
    $DIR_SEP = $OS2SEP->{ lc( $^O ) };
    # Credits: David Golden for code borrowed from Path::Tiny;
    $MODE_BITS = 
    {
    om => 0007,
    gm => 0070,
    um => 0700,
    };
    my $m = 0;
    $MODE_BITS->{ $_ } = ( 1 << $m++ ) for( qw( ox ow or gx gw gr ux uw ur ) );
    $DEFAULT_MMAP_SIZE = 10240;
    # Default to use PerlIO mmap layer if possible
    $MMAP_USE_FILE_MAP = 0;
    # Bug #92 <https://github.com/libwww-perl/URI/issues/92>
    # $URI::file::DEFAULT_AUTHORITY = undef;
    $FILES_TO_REMOVE = {};
    $GLOBBING = 0;
    # [\\/:"*?<>|]+ are illegal characters under Windows
    # <https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch08s25.html>
    # Catching non-ascii characters: [^\x00-\x7F]
    # Credits to: File::Util
    $ILLEGAL_CHARACTERS = qr/[\x5C\/\|\015\012\t\013\*\"\?\<\:\>]/;
    our $VERSION = 'v0.8.1';
};

use strict;
no warnings 'redefine';

sub init
{
    my $self = shift( @_ );
    my $file;
    if( ( ( @_ % 2 ) || 
          ( scalar( @_ ) == 2 && ref( $_[1] ) eq 'HASH' )
        ) && 
        ( !ref( $_[0] ) || ( ref( $_[0] ) && overload::Method( $_[0], '""' ) ) ) )
    {
        $file = shift( @_ );
        # stringify it if it were overloaded
        $file = "$file";
    }
    my $opts = $self->_get_args_as_hash( @_ );
    # autoremove relies on the complete filepath being set, but this happens at the end of the init, so we delay setting this property until later
    my $autoremove;
    $autoremove = CORE::delete( $opts->{auto_remove} ) if( CORE::exists( $opts->{auto_remove} ) );
    $self->{autoflush}      = 1;
    # Activated when this is a file or directory created by us, such as a temporary file
    $self->{auto_remove}    = 0;
    $self->{file}           = ( $file // '' );
    $self->{base_dir}       = '' unless( CORE::length( $self->{base_dir} ) );
    $self->{base_file}      = '';
    # Should we collapse dots? In most of the cases, it is ok, but there might be
    # symbolic links in the path that could complicate things and even create recursion
    $self->{collapse}       = 1;
    $self->{debug}          = 0;
    # Do glob on file upon resolve so that any shell meta characters are resolved
    # e.g. ~joe/some/file.txt would be resolved to /home/joe/some/file.txt
    # otherwise the filename would remain "~joe/some/file.txt"
    # This is useful when you have filename with meta characters in their file path, like:
    # /some/where/A [A-12] file.pdf
    $self->{glob}           = $GLOBBING;
    $self->{max_recursion}  = 12;
    $self->{os}             = undef;
    $self->{resolved}       = 0;
    # directory or file. This is instrumental in playing with paths before applying them to
    # the filesystem
    $self->{type}           = '';
    $self->{use_file_map}   = $MMAP_USE_FILE_MAP unless( CORE::exists( $self->{use_file_map} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( %$opts );
    $self->{_handle}        = '';
    # Pervious location prior to chdir, so we can revert to it when necessary
    $self->{_prev_cwd}      = '';
    $self->{_spec_class}    = $self->_spec_class( $self->{os} || $^O );
    $self->{_uri_file_class}= $self->_uri_file_class( $self->{os} || $^O );
    $self->{changed}        = '';
    $self->{locked}         = 0;
    $self->{opened}         = '';
    $file = $self->{file} || return( $self->error( "No file was provided." ) );
    unless( CORE::length( $self->{base_dir} ) )
    {
        my $base_dir = '';
        if( CORE::length( $self->{base_file} ) )
        {
            # base reference file is a directory
            if( -d( $self->{base_file} ) )
            {
                # base_file is already an absolute file path thanks to _make_abs
                $base_dir = $self->{base_file};
            }
            # otherwise use its parent directory
            else
            {
                my( $vol, $dirs, $element ) = $self->_spec_splitpath( $self->{base_file} );
                $base_dir = $self->_spec_catpath( $vol, $dirs );
            }
        }
        # Otherwise, use the current directory
        else
        {
            $base_dir = $self->_uri_file_cwd || do
            {
                my $tmpdir = $self->sys_tmpdir;
                CORE::chdir( $tmpdir ) || return( $self->error( "Current directory does not exist. It was most likely removed while perl was running and I could not chdir to the system temporary directory '$tmpdir': $!" ) );
                $base_dir = $tmpdir;
            };
        }
        $self->{base_dir} = $base_dir;
    }
    $file = $self->filename( $file ) || return( $self->pass_error );
    # Idea borrowed from File::Temp
    $FILES_TO_REMOVE->{ $$ }->{ $file } = $self->{auto_remove} = 1 if( defined( $autoremove ) && $autoremove );
    $self->{_orig} = [CORE::caller(1)];
    return( $self );
}

sub abs
{
    my $self = shift( @_ );
    my $path = shift( @_ );
    return( $self ) if( !defined( $path ) || !CORE::length( $path ) );
    my $file = $self->filepath;
    my $new = $self->_spec_file_name_is_absolute( $path ) ? $path : $self->_uri_file_abs( $path, $file );
    return( $self->new( $new, os => $self->{os} ) );
}

sub absolute { return( shift->abs( @_ ) ); }

# $obj->append( $string );
# $obj->append( $string, $open_options );
# $obj->append( $string, %open_options );
# $obj->append( $scalar_ref );
# $obj->append( $scalar_ref, $open_options );
# $obj->append( $scalar_ref, %open_options );
sub append
{
    my $self = shift( @_ );
    if( !$self->is_dir )
    {
        my $file = $self->filepath;
        my $data = shift( @_ );
        return( $self->error( "I was expecting a string or a scalar reference, but instead got '$data'." ) ) if( ref( $data ) && ref( $data ) ne 'SCALAR' );
        my $opts = $self->_get_args_as_hash( @_ );
        # mode could also be provided as '+<' to enable append and read afterward.
        $opts->{mode} //= '>>';
        my $opened = $self->opened;
        my $io;
        my $pos;
        # try-catch
        local $@;
        if( $opened )
        {
            return( $self->error( "I do not have the permissions to append to this opened file \"${file}\"." ) ) if( !$self->can_append );
            $io = $opened;
            # It's not that I cannot get the position in file I am writing to, but rather
            # that later, I need to seek, and thus read from the file
            if( $self->can_read )
            {
                $pos = $io->tell;
                $io->seek(0, 2);
            }
        }
        else
        {
            $io = $self->open( $opts->{mode}, @_ ) || return( $self->pass_error );
        }
        
        my $rv;
        eval
        {
            $rv = $io->print( ref( $data ) ? $$data : $data );
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error occured while trying to append ", CORE::length( ref( $data ) ? $$data : $data ), " bytes of data to file \"${file}\": $@" ) );
        }
        return( $self->error( "Unable to write ", CORE::length( ref( $data ) ? $$data : $data ), " bytes of data to file \"${file}\": $!" ) ) if( !$rv );
        
        if( $opened )
        {
            if( defined( $pos ) )
            {
                $io->seek( $pos, 0 );
            }
        }
        else
        {
            $io->close;
        }
    }
    return( $self );
}

sub as
{
    my $self = shift( @_ );
    my $os;
    if( ( !( @_ % 2 ) && !ref( $_[0] ) && ref( $_[1] ) eq 'HASH' ) ||
        ( ( @_ % 2 ) && !ref( $_[0] ) && ref( $_[1] ) ne 'HASH' ) )
    {
        $os = shift( @_ );
    }
    my $opts = $self->_get_args_as_hash( @_ );
    $os //= $opts->{os} || $^O;
    my $currentOS = $self->{os} || $^O;
    return( $self ) if( $os =~ /^(dos|mswin32|netware|symbian|win32)$/i && $currentOS =~ /^(dos|mswin32|netware|symbian|win32)$/i );
    local $URI::file::DEFAULT_AUTHORITY = undef;
    $opts->{volume} //= '';
    
    my( $volume, $parent, $file ) = $self->_spec_splitpath( $self->filename );
    my @dirs   = $self->_spec_splitdir( $parent );
    my $new_dirs = $self->_spec_catdir( [ @dirs ], $os );
    my $path = $self->_spec_catpath( $opts->{volume}, $new_dirs, $file, $os );
    return( $self->new( $path, os => $os, debug => $self->debug ) );
}

# This class does not convert to an HASH, but the TO_JSON method will convert to a string
sub as_hash { return( $_[0] ); }

sub atime { return( shift->finfo->atime ); }

# sub auto_remove { return( shift->_set_get_boolean( 'auto_remove', @_ ) ); }
sub auto_remove
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = $self->_set_get_boolean( 'auto_remove', @_ );
        $FILES_TO_REMOVE->{ $$ } = {} if( !exists( $FILES_TO_REMOVE->{ $$ } ) );
        my $file = $self->filename;
        if( $v )
        {
            $FILES_TO_REMOVE->{ $$ }->{ $file } = 1;
        }
        else
        {
            CORE::delete( $FILES_TO_REMOVE->{ $$ }->{ $file } );
        }
    }
    return( $self->_set_get_boolean( 'auto_remove' ) );
}

sub autoflush
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = $self->_set_get_boolean( 'autoflush', @_ );
        my $fh = $self->opened;
        if( $fh && !$self->is_dir )
        {
            $fh->autoflush( $v );
        }
        return( $v );
    }
    return( $self->_set_get_boolean( 'autoflush' ) );
}

sub base_dir { return( shift->_make_abs( 'base_dir', @_ ) ); }

sub base_file { return( shift->_make_abs( 'base_file', @_ ) ); }

sub baseinfo
{
    my $self = shift( @_ );
    my $exts = $self->_get_args_as_array( @_ );
    my $path = $self->filename;
    my $dir_sep = $self->_os2sep;
    if( -d( $path ) || substr( $path, -CORE::length( $dir_sep ), CORE::length( $dir_sep ) ) eq $dir_sep )
    {
        while( substr( $path, -CORE::length( $dir_sep ), CORE::length( $dir_sep ) ) eq $dir_sep )
        {
            substr( $path, -CORE::length( $dir_sep ), CORE::length( $dir_sep ), '' );
        }
        return( '' ) if( !CORE::length( $path ) );
        # my @dirs = $self->_spec_splitdir( $path );
        my( $vol, $parent, $me ) = $self->_spec_splitpath( $path );
        my $parent_path = $self->_spec_catpath( $vol, $parent );
        if( want( 'LIST' ) )
        {
            return( $me, $parent_path, '' );
        }
        else
        {
            return( $self->new_scalar( $me ) );
        }
    }
    else
    {
        # splitpath works both on files and directories
        my( $vol, $parent, $file ) = $self->_spec_splitpath( $path );
        my $suff;
        foreach my $ext ( @$exts )
        {
            $ext = ref( $ext ) eq 'Regexp' ? $ext : qr/\Q$ext\E$/i;
            if( $file =~ s/($ext)// )
            {
                $suff = $1;
                last;
            }
        }
        if( want( 'LIST' ) )
        {
            my $parent_path = $self->_spec_catpath( $vol, $parent );
            return( $file, $parent_path, $suff );
        }
        else
        {
            return( $self->new_scalar( $file ) );
        }
    }
}

sub basename { return( scalar( shift->baseinfo( @_ ) ) ); }

sub binmode { return( shift->_filehandle_method( 'binmode', 'file', @_ ) ); }

sub block_size { return( shift->finfo->block_size ); }

sub blocking { return( shift->_filehandle_method( 'blocking', 'file', @_ ) ); }

sub blocks { return( shift->finfo->blocks ); }

sub can_append
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    my $io = $self->opened;
    if( $self->is_dir )
    {
        return( -e( $file ) && -w( $file ) );
    }
    else
    {
        # File is not opened so we do not know if the file handle is writable
        return(0) if( !$io );
        my $flags;
        # try-catch
        local $@;
        eval
        {
            $flags = $io->fcntl( F_GETFL, 0 );
        };
        if( $@ )
        {
            return( $self->error( "An error occurred while trying to check if we can append to ", ( $self->is_dir ? 'directory' : 'file handle for ' ), " \"${file}\": $@" ) );
        }
        return( $flags & ( O_APPEND | O_RDWR ) );
    }
}

sub can_exec { return( shift->finfo->can_exec( @_ ) ); }

sub can_read
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    if( $self->is_dir )
    {
        return( $self->finfo->can_read );
    }
    else
    {
        my $opened = $self->opened // '';
        my $io;
        if( $opened )
        {
            $io = $opened;
        }
        else
        {
            $io = $self->open( @_ ) || return(0);
        }
        # $rv = $io->read( my $buff, 1024 );
        # try-catch
        local $@;
        my $flags;
        eval
        {
            $flags = $io->fcntl( F_GETFL, 0 );
        };
        if( $@ )
        {
            return( $self->error( "An error occurred while trying to check if we can read from ", ( $self->is_dir ? 'directory' : 'file handle for ' ), " \"${file}\": $@" ) );
        }
        
        my $v = ( ( $flags == O_RDONLY ) || ( $flags & ( O_RDONLY | O_RDWR ) ) );
        $v++ unless( $flags & O_ACCMODE );
        $io->close unless( $opened );
        return( $v );
    }
}

sub can_write
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    my $io = $self->opened;
    if( $self->is_dir )
    {
        return( -e( $file ) && -w( $file ) );
    }
    else
    {
        if( $io )
        {
            # try-catch
            local $@;
            my $flags;
            eval
            {
                $flags = $io->fcntl( F_GETFL, 0 );
            };
            if( $@ )
            {
                return( $self->error( "An error occurred while trying to check if we can write to ", ( $self->is_dir ? 'directory' : 'file handle for ' ), " \"${file}\": $@" ) );
            }
            warn( "Error getting the file handle flags: ", $io->error ) if( !defined( $flags ) );
            return( $self->pass_error( $io->error ) ) if( !defined( $flags ) );
            my $bits = ( O_APPEND | O_WRONLY | O_CREAT | O_RDWR );
            return( $flags & ( O_APPEND | O_WRONLY | O_CREAT | O_RDWR ) );
        }
        elsif( $self->finfo->can_write )
        {
            return(1);
        }
        # File is not opened so we do not know if the file handle is writable
        return(0);
    }
}

sub canonpath
{
    my $self = shift( @_ );
    my $os   = shift( @_ ) || $self->{os} || $^O;
    # return( URI::file->new( $self->filename )->file( $os ) );
    return( $self->_uri_file_class->new( $self->filename )->file( $os ) );
}

sub changed
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->_set_get_scalar( 'changed', @_ ) );
    }
    my $time = $self->_set_get_scalar( 'changed' );
    my $file = $self->filename;
    if( !$time && !-e( $file ) )
    {
        return(0);
    }
    elsif( !$time && -e( $file ) )
    {
        return(1);
    }
    return( $time != [CORE::stat( $file )]->[9] );
}

sub checksum_md5
{
    my $self = shift( @_ );
    return( $self->error( "File ", $self->filename, " does not exist." ) ) if( !$self->exists );
    return( $self->error( "File ", $self->filename, " is not a file." ) ) if( !$self->is_file );
    $self->_load_class( 'Crypt::Digest::MD5' ) || return( $self->pass_error );
    return( Crypt::Digest::MD5::md5_file_hex( $self->filename ) );
}

sub checksum_sha256
{
    my $self = shift( @_ );
    return( $self->error( "File ", $self->filename, " does not exist." ) ) if( !$self->exists );
    return( $self->error( "File ", $self->filename, " is not a file." ) ) if( !$self->is_file );
    $self->_load_class( 'Crypt::Digest::SHA256' ) || return( $self->pass_error );
    return( Crypt::Digest::SHA256::sha256_file_hex( $self->filename ) );
}

sub checksum_sha512
{
    my $self = shift( @_ );
    return( $self->error( "File ", $self->filename, " does not exist." ) ) if( !$self->exists );
    return( $self->error( "File ", $self->filename, " is not a file." ) ) if( !$self->is_file );
    $self->_load_class( 'Crypt::Digest::SHA512' ) || return( $self->pass_error );
    return( Crypt::Digest::SHA512::sha512_file_hex( $self->filename ) );
}

sub chdir
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    return( $self->error( "File \"${file}\" is not a directory, so you cannot use chdir." ) ) if( !$self->is_dir );
    my $curr = $self->cwd;
    CORE::chdir( $file ) || return( $self->error( "Cannot chdir to directory \"${file}\": $!" ) );
    $self->_prev_cwd( $curr );
    return( $self );
}

sub child
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    return( $self->error( "No child was provided for our filename \"", $self->filename, "\"." ) ) if( !defined( $file ) || !CORE::length( $file ) );
    my $new;
    my $path = $self->filename;
    my $dir_sep = $self->_os2sep;
    my( $vol, $dir, $this ) = $self->_spec_splitpath( $path );
    if( -d( $path ) || substr( $path, -CORE::length( $dir_sep ), CORE::length( $dir_sep ) ) eq $dir_sep )
    {
        while( substr( $path, -CORE::length( $dir_sep ), CORE::length( $dir_sep ) ) eq $dir_sep )
        {
            substr( $path, -CORE::length( $dir_sep ), CORE::length( $dir_sep ), '' );
        }
    }
    $new = $self->_spec_catpath( $vol, $path, $file );
    # We do not resolve the overall file path, because the user may depend on what he/she provided us initially, or here as a child
    return( $self->new( $new, { resolved => 1, os => $self->{os}, debug => $self->debug } ) );
}

sub chmod
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "No mode was provided for file \"", $self->filename, "\"." ) ) if( !defined( $this ) || !CORE::length( $this ) );
    my $mode;
    if( $this =~ /^\d+$/ )
    {
        $mode = CORE::substr( $this, 0, 1 ) eq '0' ? oct( $this ) : $this;
    }
    elsif( $this =~ /^[augo]+[=+-][rwx]+/ )
    {
        # Credits: David Golden for this nifty code borrowed from Path::Tiny
        $mode = $self->finfo->mode;
        foreach my $def ( CORE::split( /,[[:blank:]\h]*/, $this ) )
        {
            if( /^(?<who>[augo]+)(?<what>[=+-])(?<perms>[rwx]+)$/ )
            {
                my $ref = { %+ };
                $ref->{who} =~ s/a/ugo/g;
                foreach my $w ( CORE::split( //, $ref->{who} ) )
                {
                    my $p = 0;
                    $p |= $MODE_BITS->{ "${w}$_" } for( CORE::split( //, $ref->{perms} ) );
                    if ( $ref->{what} eq '=' )
                    {
                        $mode = ( $mode & ~$MODE_BITS->{ "${w}m" } ) | $p;
                    }
                    else
                    {
                        $mode = $ref->{what} eq '+' ? ( $mode | $p ) : ( $mode & ~$p );
                    }
                }
            }
            else
            {
                warnings::warn( "Relative mode definition \"$def\" is malformed.\n" ) if( warnings::enabled() );
            }
        }
    }
    my $file = $self->filename;
    CORE::chmod( $mode, $file ) || return( $self->error( sprintf( "An error occurred while changing mode for file \"$file\" to %o: $!", $mode ) ) );
    $self->finfo->reset;
    return( $self );
}

sub chown
{
    my $self = shift( @_ );
    my( $uid, $gid ) = @_;
    my $f = $self->filename;
    my $what = $self->is_dir ? 'directory' : 'file';
    # try-catch
    local $@;
    my $rv;
    eval
    {
        $rv = CORE::chown( $uid, $gid, "$f" );
    };
    if( $@ )
    {
        return( $self->error( "Unable to chown ${what} $f: $@" ) );
    }
    return( $rv );
}

sub cleanup { return( shift->_set_get_boolean( 'auto_remove', @_ ) ); }

sub close
{
    my $self = shift( @_ );
    my $io = $self->opened || return( $self );
    $io->close;
    $self->opened( undef() );
    return( $self );
}

sub code
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->_set_get_number( 'code', @_ ) );
    }
    else
    {
        $self->finfo->reset;
        my $code = $self->_set_get_number( 'code' );
        if( $self->exists )
        {
            if( $self->is_dir )
            {
                if( !$self->finfo->can_exec )
                {
                    $code = 403; # Forbidden
                }
            }
            else
            {
                if( !$self->changed )
                {
                    $code = 304; # Not modified
                }
                elsif( !$self->finfo->can_read )
                {
                    $code = 403; # Forbidden
                }
                elsif( $self->is_empty )
                {
                    if( $code == 201 )
                    {
                        # ok then
                    }
                    else
                    {
                        $code = 204; # no content
                    }
                }
            }
        }
        else
        {
            # Unless it has been removed
            unless( $code == 410 )
            {
                $code = 404; # Not found
            }
        }
        return( Module::Generic::Number->new( $code ) );
    }
}

# RFC 3986 section 5.2.4
# This is aimed for web URI initially, but is also used for filesystems in a simple way
sub collapse_dots
{
    my $self = shift( @_ );
    my $path = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    # To avoid warnings
    $opts->{separator} //= '';
    # A path separator is provided when dealing with filesystem and not web URI
    # We use this to know what to return and how to behave
    my $sep  = CORE::length( $opts->{separator} ) ? $opts->{separator} : '/';
    return( '' ) if( !CORE::length( $path ) );
    # my $u = $opts->{separator} ? URI::file->new( $path ) : URI->new( $path );
    my $u = $opts->{separator} ? $self->_uri_file_class->new( $path ) : URI->new( $path );
    $u->path( $path ) if( $path =~ /^[[:blank:]\h]+/ || $path =~ /[[:blank:]\h]+$/ );
    # unless( CORE::index( "$u", '.' ) != -1 || CORE::index( "$u", '..' ) != -1 )
    unless( $u =~ /(?:(?:(?:^|\/)\.{1,2}\/)|(?:\/\.{1,2}(?:\/|$)))/ )
    {
        return( $u );
    }
    my( @callinfo ) = caller;
    $path = $opts->{separator} ? $u->file( $self->{os} || $^O ) : $u->path;
    my @new = ();
    my $len = CORE::length( $path );
    
    # "If the input buffer begins with a prefix of "../" or "./", then remove that prefix from the input buffer"
    if( substr( $path, 0, 2 ) eq ".${sep}" )
    {
        substr( $path, 0, 2 ) = '';
    }
    elsif( substr( $path, 0, 3 ) eq "..${sep}" )
    {
        substr( $path, 0, 3 ) = '';
    }
    # "if the input buffer begins with a prefix of "/./" or "/.", where "." is a complete path segment, then replace that prefix with "/" in the input buffer"
    elsif( substr( $path, 0, 3 ) eq "${sep}.${sep}" )
    {
        substr( $path, 0, 3 ) = $sep;
    }
    elsif( substr( $path, 0, 2 ) eq "${sep}." && 2 == $len )
    {
        substr( $path, 0, 2 ) = $sep;
    }
    elsif( $path eq '..' || $path eq '.' )
    {
        $path = '';
    }
    elsif( $path eq $sep )
    {
        return( $u );
    }
    
    # -1 is used to ensure trailing blank entries do not get removed
    my @segments = CORE::split( "\Q$sep\E", $path, -1 );
    for( my $i = 0; $i < scalar( @segments ); $i++ )
    {
        my $segment = $segments[$i];
        # "if the input buffer begins with a prefix of "/../" or "/..", where ".." is a complete path segment, then replace that prefix with "/" in the input buffer and remove the last segment and its preceding "/" (if any) from the output buffer"
        if( $segment eq '..' )
        {
            pop( @new );
        }
        elsif( $segment eq '.' )
        {
            next;
        }
        else
        {
            push( @new, ( defined( $segment ) ? $segment : '' ) );
        }
    }
    # Finally, the output buffer is returned as the result of remove_dot_segments.
    my $new_path = CORE::join( $sep, @new );
    # substr( $new_path, 0, 0 ) = $sep unless( substr( $new_path, 0, 1 ) eq '/' );
    substr( $new_path, 0, 0 ) = $sep unless( $self->_spec_file_name_is_absolute( $new_path ) );
    if( $opts->{separator} )
    {
        # $u = URI::file->new( $new_path );
        $u = $self->_uri_file_class->new( $new_path );
    }
    else
    {
        $u->path( $new_path );
    }
    return( $u );
}

sub contains
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "Can only call contains on a directory." ) ) if( !$self->is_dir );
    unless( $self->_is_object( $this ) && $self->_is_a( $this => 'Module::Generic::File' )  )
    {
        if( ref( $this ) && !overload::Method( $this, '""' ) )
        {
            return( $self->error( "I was expecting a string or a stringifyable object, but instead I got '$this'." ) );
        }
        $this = $self->new( "$this", os => $self->{os} ) || return( $self->pass_error );
    }
    my $file = $self->filepath;
    my $kid  = $this->filepath;
    my $dir_sep = $self->_os2sep;
    return( CORE::index( $kid, "${file}${dir_sep}" ) == 0 ? $self->true : $self->false );
}

sub content
{
    my $self = shift( @_ );
    my $a = $self->new_array;
    return( $a ) if( !$self->exists );
    my $opts = $self->_get_args_as_hash( @_ );
    my $file = $self->filepath;
    my $opened = $self->opened;
    my $io;
    my $pos;
    if( $self->is_dir )
    {
        if( $opened )
        {
            $io = $opened;
            $pos = $io->tell;
            $io->rewind || return( $self->error( "Unable to position ourself at the top of the directory \"${file}\": $!" ) );
        }
        else
        {
            # $io = $self->open( $opts ) || return( $self->pass_error );
            if( !( $io = $self->open( $opts ) ) )
            {
                return( $self->pass_error );
            }
        }
        my $vol = $self->volume;
        $a = $self->new_array( [ map( $self->_spec_catpath( $vol, $file, $_ ), grep{ !/^\.{1,2}$/ } $io->read ) ] );
        # Put it back where it was
        eval
        {
            $io->seek( $pos ) if( defined( $pos ) );
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error has occurred while trying to get the content for \"${file}\": $@" ) );
        }
    }
    else
    {
        if( $opened )
        {
            $io = $opened;
            # Prevent error of reading on a non-readable file handle
            return( $a ) if( !$self->can_read );
            $pos = $io->tell;
            my $rv;
            # try-catch
            local $@;
            eval
            {
                $rv = $io->seek(0,0);
            };
            if( $@ )
            {
                return( $self->error( "An unexpected error has occurred while trying to get the content for \"${file}\": $@" ) );
            }
            return( $self->error( "Unable to position ourself at the top of the file \"${file}\": $!" ) ) if( !$rv );
        }
        else
        {
            $io = $self->open( '<', $opts ) || return( $self->pass_error );
        }
        $a = $self->new_array( [ $io->getlines ] );
        eval
        {
            $io->seek( $pos, Fcntl::SEEK_SET ) if( defined( $pos ) );
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error has occurred while trying to get the content for \"${file}\": $@" ) );
        }
    }
    $io->close unless( $opened );
    return( $a );
}

sub content_objects
{
    my $self = shift( @_ );
    return( $self->error( "This method \"content_objects\" can only be used on directories." ) ) if( !$self->is_dir );
    my $ref = $self->content;
    return( $self->error( "Array provided is not an array reference or an array object." ) ) if( !$self->_is_array( $ref ) );
    unless( $self->_is_a( $ref, 'Module::Generic::Array' ) )
    {
        $ref = $self->new_array( $ref ) || return( $self->pass_error );
    }
    my $new = $ref->map(sub
    {
        return( $self->new( $_, { os => $self->{os} } ) );
    });
    return( $new );
}

sub copy { return( shift->_move_or_copy( copy => @_ ) ); }

sub cp { return( shift->copy( @_ ) ); }

sub ctime { return( shift->finfo->ctime ); }

sub cwd
{
    my $cwd = URI::file->cwd;
    my $u;
    if( substr( $cwd, 0, 7 ) eq 'file://' )
    {
        $u = URI->new( $cwd );
    }
    else
    {
        $u = URI::file->new( $cwd );
    }
    return( __PACKAGE__->new( $u->file( $^O ) ) );
}

sub delete
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    my $rv;
    if( $self->is_dir )
    {
        # try-catch
        local $@;
        eval
        {
            $rv = CORE::rmdir( $file );
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error has occurred while trying to remove ", ( $self->is_dir ? 'directory' : 'file' ), " \"${file}\": $@" ) );
        }
        return( $self->error( "Unable to remove directory \"${file}\": $!" ) ) if( !$rv );
    }
    else
    {
        # try-catch
        local $@;
        eval
        {
            $rv = CORE::unlink( $file );
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error has occurred while trying to remove ", ( $self->is_dir ? 'directory' : 'file' ), " \"${file}\": $@" ) );
        }
        return( $self->error( "Unable to remove file \"${file}\": $!" ) ) if( !$rv );
    }
    $self->code(410); # Gone
    $self->finfo->reset;
    return( $self );
}

sub device { return( shift->finfo->device ); }

sub digest
{
    my $self = shift( @_ );
    my $algo;
    $algo = shift( @_ ) if( !ref( $_[0] ) );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !$self->_is_class_loadable( 'Digest' ) )
    {
        return( $self->error( "Module Digest, which is required for this method, is not installed on your system." ) );
    }
    $self->_load_class( 'Digest' ) || return( $self->pass_error );
    $opts->{algo} //= $algo // 'SHA-256';
    $opts->{algo} = 'SHA-256' if( $opts->{algo} eq 'SHA' );
    if( $opts->{algo} =~ /^([a-zA-Z]+)(\d{1,3})$/ )
    {
        $opts->{algo} = uc( $1 . '-' . $2 );
    }
    $opts->{format} //= 'hex';
    $opts->{format} = lc( $opts->{format} );
    $opts->{algo} = uc( $opts->{algo} );
    my $file = $self->filename;
    my $fh = $self->handle || return( $self->pass_error );
    $fh->seek(0,0);
    # $fh->binmode;
    my $d = Digest->new( $opts->{algo} ) ||
        return( $self->error( "Unable to instantiate an Digest object: $!" ) );
    $d->addfile( $fh );
    my $rv;
    if( $opts->{format} eq 'binary' )
    {
        # try-catch
        local $@;
        eval
        {
            $rv = $d->digest;
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error occurred while trying to get the digest with algorithm \"$opts->{algo}\" for file \"${file}\": $@" ) );
        }
    }
    elsif( $opts->{format} eq 'hex' || $opts->{format} eq 'hexdigest' )
    {
        # try-catch
        local $@;
        eval
        {
            $rv = $d->hexdigest;
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error occurred while trying to get the digest with algorithm \"$opts->{algo}\" for file \"${file}\": $@" ) );
        }
    }
    elsif( $opts->{format} eq 'base64' || 
           $opts->{format} eq 'b64' || 
           $opts->{format} eq 'base64digest' ||
           $opts->{format} eq 'b64digest' )
    {
        # try-catch
        local $@;
        eval
        {
            $rv = $d->base64digest;
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error occurred while trying to get the digest with algorithm \"$opts->{algo}\" for file \"${file}\": $@" ) );
        }
    }
    else
    {
        return( $self->error( "Unknown format \"$opts->{format}\" provided to get the digest (cryptographic hash) of \"${file}\"." ) );
    }
    return( $rv );
}

sub dirname { return( shift->parent ); }

sub empty
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    if( $self->is_dir )
    {
        return( $self->rmtree( @_ ) );
    }
    else
    {
        my $opened = $self->opened;
        my $io;
        if( $opened )
        {
            return( $self->error( "Unable to read from opened file \"${file}\"." ) ) if( !$self->can_read );
            return( $self->error( "Unable to write to opened file \"${file}\"." ) ) if( !$self->can_write );
            # Because of system portability issues with truncate, we use try-catch
            # try-catch
            local $@;
            eval
            {
                $io = $opened;
                $io->seek(0,0);
                $io->truncate( $io->tell );
            };
            if( $@ )
            {
                return( $self->error( "Unable to seek and truncate file \"${file}\": $@" ) );
            }
        }
        else
        {
            # No need to do more than this to empty
            $io = $self->open( '>' ) || return( $self->pass_error );
            $io->close;
        }
    }
    return( $self );
}

sub eof { return( shift->_filehandle_method( 'eof', 'file', @_ ) ); }

sub exists { return( shift->finfo->exists ); }

sub extension
{
    my $self = shift( @_ );
    return( '' ) if( $self->is_dir );
    my $file = $self->filepath;
    if( @_ )
    {
        my $new = shift( @_ ); # It could be empty if the user wanted to remove the extension
        $new //= '';
        if( CORE::length( $new ) )
        {
            $file =~ s/\.(\w+)$/\.${new}/;
        }
        else
        {
            $file =~ s/\.(\w+)$//;
        }
        return( $self->new( $file,
            debug     => $self->debug,
            base_dir  => $self->base_dir,
            base_file => $self->base_file,
            os        => $self->{os},
        ) );
    }
    else
    {
        my $ext = ( $file =~ /\.(\w+)$/ )[0] || '';
        return( $self->new_scalar( $ext ) );
    }
}

sub extensions
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self ) if( $self->is_dir );
        my $extensions = shift( @_ ); # It could be empty if the user wanted to remove the extension
        $extensions //= '';
        my $parent = $self->parent;
        my $base = $self->basename;
        my @parts = split( /\./, $base );
        my $top = shift( @parts );
        my $new = $parent->child( length( $extensions ) ? join( '.', $top, $extensions ) : $top );
        return( $new );
    }
    else
    {
        my $a = $self->new_array;
        # Return empty if this is a directory
        return( $a ) if( $self->is_dir );
        my $base = $self->basename;
        my @parts = split( /\./, $base );
        shift( @parts );
        $a = $self->new_array( \@parts );
        return( $a );
    }
}

sub fcntl { return( shift->_filehandle_method( 'fcntl', 'file', @_ ) ); }

sub fdopen { return( shift->_filehandle_method( 'fdopen', 'file', @_ ) ); }

sub file
{
    if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( __PACKAGE__ ) )
    {
        # file( $file_obj );
        # file( $file_obj, $options_hash_ref );
        # file( $file_obj, %options );
        if( scalar( @_ ) == 1 ||
            ( scalar( @_ ) == 2 && ref( $_[1] ) eq 'HASH' ) || 
            ( scalar( @_ ) > 2 && !( ( scalar( @_ ) - 1 ) % 2 ) ) )
        {
            return( __PACKAGE__->new( @_ ) );
        }
        # $obj->file( $file_obj );
        # $obj->file( $file_obj, $options_hash_ref );
        # $obj->file( $file_obj, %options );
        elsif( Scalar::Util::blessed( $_[1] ) && $_[1]->isa( __PACKAGE__ ) )
        {
            return( shift->new( @_ ) );
        }
        # $obj->file( '/some/file' );
        # $obj->file( '/some/file', $options_hash_ref );
        # $obj->file( '/some/file', %options );
        # $obj->file( $stringifyable_object );
        # $obj->file( $stringifyable_object, $options_hash_ref );
        # $obj->file( $stringifyable_object, %options );
        elsif( ( !ref( $_[1] ) || 
                 ( ref( $_[1] ) && overload::Method( $_[1], '""' ) )
               )
               &&
               (
                 scalar( @_ ) == 2 ||
                 # there is more than 2 parameters and what follows is an has of options
                 ( scalar( @_ ) > 2 && 
                   ( !( ( scalar( @_ ) - 2 ) % 2 ) || ref( $_[2] ) eq 'HASH' )
                 )
               ) )
        {
            return( shift->new( @_ ) );
        }
        else
        {
            return( $_[0]->error( "Unknown set of parameters: '", CORE::join( "', '", @_ ), "'." ) );
        }
    }
    else
    {
        return( __PACKAGE__->new( @_ ) );
    }
}

sub filehandle { return( shift->handle( @_ ) ); }

sub filename
{
    my $self = shift( @_ );
    my $newfile;
    if( @_ )
    {
        $newfile = shift( @_ );
        return( $self->error( "New file provided, but it was an empty string." ) ) if( !defined( $newfile ) || !CORE::length( $newfile ) );
    }

    if( defined( $newfile ) )
    {
        my $base_dir = $self->base_dir;
        my $dir_sep  = $self->_os2sep;
        $base_dir .= $dir_sep unless( substr( $base_dir, -CORE::length( $dir_sep ), CORE::length( $dir_sep ) ) eq $dir_sep );
        # Resolve the path if there is any link
        my $already_resolved = $self->resolved;
        my $resolved;
        if( !$already_resolved && ( $resolved = $self->resolve( $newfile ) ) )
        {
            $newfile = $resolved;
            $self->resolved(1);
        }
        
        # If we provide a string for the abs() method it works on Unix, but not on Windows
        # By providing an object, we make it work
        unless( $self->_spec_file_name_is_absolute( $newfile ) )
        {
            # $newfile = URI::file->new( $newfile )->abs( URI::file->new( $base_dir ) )->file( $^O );
            $newfile = $self->_uri_file_abs( $newfile, $base_dir );
        }
        if( $self->collapse )
        {
            $self->{filename} = $self->collapse_dots( $newfile, { separator => $dir_sep })->file( $self->_uri_file_os_map( $self->{os} ) || $^O );
        }
        else
        {
            # $self->{filename} = URI::file->new( $newfile )->file( $^O );
            $self->{filename} = $self->_uri_file_new( $newfile );
        }
        
        # It potentially does not exist
        my $finfo = $self->finfo( $newfile );
        if( !$finfo->exists )
        {
            $self->code(404);
        }
        else
        {
            $self->code(200);
        }
        # Force to create new Apache2::SSI::URI object
    }
    return( $self->{filename} );
}

sub fileno { return( shift->_filehandle_method( 'fileno', 'file', @_ ) ); }

## Alias
sub filepath { return( shift->filename( @_ ) ); }

sub find
{
    my $self = shift( @_ );
    my $cb;
    $cb = pop( @_ ) if( ref( $_[-1] ) eq 'CODE' );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Can only call find on a directory." ) ) if( !$self->is_dir );
    return( $self->error( "No callback code reference was provided." ) ) if( !defined( $cb ) && ( !CORE::exists( $opts->{callback} ) || ( CORE::exists( $opts->{callback} ) && ref( $opts->{callback} ) ne 'CODE' ) ) );
    $opts->{method} //= 'find';
    return( $self->error( "Unsupported method '$opts->{method}'. Use either 'find' or 'finddepth'." ) ) if( $opts->{method} ne 'find' && $opts->{method} ne 'finddepth' );
    $cb //= delete( $opts->{callback} );
    if( !$self->_is_class_loadable( 'File::Find' ) )
    {
        return( $self->error( "File::Find is required, but is not installed in your system." ) );
    }
    $self->_load_class( 'File::Find' ) || return( $self->pass_error );
    my $dir = $self->filepath;
    my $p = +{ map( ( CORE::exists( $opts->{ $_ } ) ? ( $_ => $opts->{ $_ } ) : () ), qw( bydepth dangling_symlinks follow follow_fast follow_skip no_chdir postprocess preprocess untaint untaint_pattern untaint_skip ) ) };
    $p->{wanted} = sub
    {
        local $_ = $self->new( $File::Find::name, { base_dir => $File::Find::dir, os => $self->{os} } ) || return( $self->pass_error );
        $cb->( $_ );
    };
    my $cwd = $self->cwd();
    my $skip = {};
    # It can be files or directories to skip
    if( $opts->{skip} )
    {
        return( $self->error( "Parameter \"skip\" was provided, but it is not an array reference." ) ) if( ( Scalar::Util::reftype( $opts->{skip} ) // '' ) ne 'ARRAY' );
        foreach my $f ( @{$opts->{skip}} )
        {
            my $this = file( $f );
            $skip->{ "$this" } = $this;
        }
    }
    
    $p->{preprocess} = sub
    {
        my @files = @_;
        my $curr_dir = $File::Find::dir;
        for( my $i = 0; $i <= $#files; $i++ )
        {
            my $curr_file = CORE::join( '/', $curr_dir, $files[$i] );
            if( CORE::exists( $skip->{ $curr_file } ) || $files[$i] CORE::eq '.' || $files[$i] CORE::eq '..' )
            {
                CORE::splice( @files, $i, 1 );
                $i--;
            }
        }
        @files = sort( @files ) if( $opts->{sort} );
        return( @files );
    };
    
    # try-catch
    local $@;
    eval
    {
        if( $opts->{method} eq 'finddepth' )
        {
            File::Find::finddepth( $p, $dir );
        }
        else
        {
            File::Find::find( $p, $dir );
        }
    };
    if( $@ )
    {
        return( $self->error( "An unexpected error has occurred in File::Find::$opts->{method}(): $@" ) );
    }
    return( $self );
}

sub finddepth
{
    my $self = shift( @_ );
    my $cb;
    $cb = pop( @_ ) if( ref( $_[-1] ) eq 'CODE' );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{method} = 'finddepth';
    return( $self->find( $opts, $cb ) );
}

sub finfo
{
    my $self = shift( @_ );
    my $newfile;
    if( @_ )
    {
        $newfile = shift( @_ );
        return( $self->error( "New file path specified but is an empty string." ) ) if( !defined( $newfile ) || !CORE::length( $newfile ) );
    }
    elsif( !$self->{finfo} )
    {
        $newfile = $self->filename;
        return( $self->error( "No file path set. This should not happen." ) ) if( !$newfile );
    }
    
    if( defined( $newfile ) )
    {
        $self->{finfo} = Module::Generic::Finfo->new( $newfile, debug => $self->debug );
        return( $self->pass_error( Module::Generic::Finfo->error ) ) if( !$self->{finfo} );
    }
    return( $self->{finfo} );
}

# Get the flags in effect after the file was opened
sub flags
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    my $io = $self->opened;
    return(0) if( $self->is_dir || !$io || lc( $^O ) eq 'win32' || lc( $^O ) eq 'mswin32' );
    my $flags;
    # try-catch
    local $@;
    eval
    {
        # force numeric context
        $flags = ( 0 + $io->fcntl( F_GETFL, 0 ) );
    };
    if( $@ )
    {
        warnings::warn( "An error occurred while trying to get flags for opened file \"${file}\": $@\n" ) if( warnings::enabled() );
        return(0);
    }
    return( $flags );
}

sub flatten
{
    my $self = shift( @_ );
    my $path = $self->resolved ? $self : $self->resolve( @_ );
    return( $self->pass_error ) if( !defined( $path ) );
    my $dir_sep = $self->_os2sep;
    return( $self->new( $self->collapse_dots( "$path", { separator => $dir_sep } )->file( $self->{os} || $^O ), { os => $self->{os} } ) );
}

sub flock { return( shift->_filehandle_method( 'flock', 'file', @_ ) ); }

sub flush { return( shift->_filehandle_method( 'flush', 'file', @_ ) ); }

sub format_write { return( shift->_filehandle_method( 'format_write', 'file', @_ ) ); }

sub fragments { return( shift->split( remove_leading_sep => 1 ) ); }

sub getc { return( shift->_filehandle_method( 'getc', 'file', @_ ) ); }

sub getline { return( shift->_filehandle_method( 'getline', 'file', @_ ) ); }

sub getlines { return( shift->_filehandle_method( 'getlines', 'file', @_ ) ); }

sub gid { return( shift->finfo->gid ); }

sub glob
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( @_ && ref( $_[-1] ) eq 'HASH' );
    my $os = $self->{os} || $^O;
    my $path = $self->filename;
    my $pattern;
    if( scalar( @_ ) )
    {
        # pattern provided, if any, must be a regular string
        return( $self->error( "Unsupported pattern provided ($_[0]). It must be a regular scalar, but instead is '", overload::StrVal( $_[0] ), "'" ) ) if( ref( $_[0] ) );
        $pattern = shift( @_ );
    }
    my $make_objects = ( exists( $opts->{object} ) ? CORE::delete( $opts->{object} ) : 1 );
    my $flags;
    # Parameters have been provided, so we set the flags.
    if( scalar( keys( %$opts ) ) && $os !~ /^(mswin32|win32|vms|riscos)$/i )
    {
        $opts->{brace} //= 0;
        # Expand expression starting with ~ to user home directory
        $opts->{expand} //= 1;
        $opts->{no_case} //= 0;
        $opts->{no_magic} //= 0;
        $flags = 0;
        $flags |= File::Glob::GLOB_NOCASE if( $opts->{no_case} );
        if( exists( $opts->{sort} ) )
        {
            # By default, File::Glob sort the files, but you can speed it up by providing 'sort' with a false value to indicate it not to do any sorting.
            if( $opts->{sort} )
            {
                $flags |= File::Glob::GLOB_ALPHASORT;
            }
            else
            {
                $flags |= File::Glob::GLOB_NOSORT;
            }
        }
        $flags |= File::Glob::GLOB_BRACE if( $opts->{brace} );
        $flags |= File::Glob::GLOB_NOMAGIC if( $opts->{no_magic} );
        $flags |= File::Glob::GLOB_TILDE if( $opts->{expand} );
    }
    # Those do not work in virtualisation
    if( $os eq $^O )
    {
        if( Want::want( 'LIST' ) )
        {
            my @files;
            if( $os =~ /^(mswin32|win32|vms|riscos)$/i )
            {
                require File::DosGlob;
                @files = File::DosGlob::glob( ( $self->is_dir && defined( $pattern ) ) ? CORE::join( $OS2SEP->{ lc( $os ) }, $path, $pattern ) : $path );
            }
            else
            {
                @files = File::Glob::bsd_glob( ( ( $self->is_dir && defined( $pattern ) ) ? CORE::join( $OS2SEP->{ lc( $os ) }, $path, $pattern ) : $path ), ( ( defined( $flags ) && $flags != 0 ) ? $flags : () ) );
                return( $self->error( "Error globbing with pattern '", ( defined( $pattern ) ? $pattern : $path ), "': $!" ) ) if( !scalar( @files ) && &File::Glob::GLOB_ERROR );
            }
            
            if( $make_objects )
            {
                for( my $i = 0; $i < scalar( @files ); $i++ )
                {
                    my $f = $self->new( $files[$i] ) || do
                    {
                        # Somehow, we failed at creating an object for this file, so we skip it.
                        CORE::splice( @files, $i, 1 );
                        $i--;
                        next;
                    };
                    $files[$i] = $f;
                }
            }
            return( @files );
        }
        else
        {
            if( $os =~ /^(mswin32|win32|vms|riscos)$/i )
            {
                require File::DosGlob;
                $path = File::DosGlob::glob( ( $self->is_dir && defined( $pattern ) ) ? CORE::join( $OS2SEP->{ lc( $os ) }, $path, $pattern ) : $path );
            }
            else
            {
                $path = File::Glob::bsd_glob( ( ( $self->is_dir && defined( $pattern ) ) ? CORE::join( $OS2SEP->{ lc( $os ) }, $path, $pattern ) : $path ), ( ( defined( $flags ) && $flags != 0 ) ? $flags : () ) );
                return( $self->error( "Error globbing with pattern '", ( defined( $pattern ) ? $pattern : $path ), "': $!" ) ) if( !$path && &File::Glob::GLOB_ERROR );
            }
        }
    }
    return( $path ) if( !CORE::length( $path ) );
    return( $self->new( $path, { resolved => 1, os => $self->{os} } ) );
}

sub globbing { return( shift->_set_get_boolean( 'globbing', @_ ) ); }

sub gobble { return( shift->load( @_ ) ); }

sub gush { return( shift->unload( @_ ) ); }

sub handle
{
    my $self = shift( @_ );
    my $opened = $self->opened;
    return( $opened ) if( $opened );
    $opened = $self->open( @_ ) || return( $self->pass_error );
    return( $opened );
}

sub has_valid_name
{
    my $self = shift( @_ );
    my $name = @_ ? shift( @_ ) : $self->basename;
    return( $name !~ /$ILLEGAL_CHARACTERS/ ? $self->true : $self->false );
}

sub inode { return( shift->finfo->inode ); }

sub ioctl { return( shift->_filehandle_method( 'ioctl', 'file', @_ ) ); }

sub is_absolute
{
    my $self = shift( @_ );
    return( $self->_spec_file_name_is_absolute( $self->filepath ) );
}

sub is_dir { return( shift->finfo->is_dir ); }

{
    no warnings 'once';
    *is_directory = \&is_dir;
}

sub is_empty
{
    my $self = shift( @_ );
    if( $self->is_dir )
    {
        return(1) if( !$self->exists );
        # 2022-09-27: works, but need something more efficient, because we could potentially be dealing with thousands of files
        # return( $self->content->length == 0 );
        my $file = $self->filepath;
        my $is_empty = 1;
        my $opened = $self->opened;
        my( $io, $pos, $elem );
        if( $opened )
        {
            $io = $opened;
            $pos = $io->tell;
            $io->rewind || return( $self->error( "Unable to position ourself at the top of the directory \"${file}\": $!" ) );
        }
        else
        {
            if( !( $io = $self->open ) )
            {
                return( $self->pass_error );
            }
        }
        
        while( defined( $elem = $io->read ) )
        {
            next if( $elem eq '.' || $elem eq '..' );
            $is_empty = 0, last;
        }
        $io->seek( $pos ) if( defined( $pos ) );
        $io->close unless( $opened );
        return( $is_empty );
    }
    else
    {
        $self->finfo->reset;
        return( $self->finfo->size == 0 );
    }
}

sub is_file { return( shift->finfo->is_file ); }

sub is_link { return( shift->finfo->is_link ); }

sub is_opened { return( shift->opened( @_ ) ); }

sub is_part_of
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    unless( $self->_is_object( $this ) && $self->_is_a( $this => 'Module::Generic::File' )  )
    {
        if( ref( $this ) && !overload::Method( $this, '""' ) )
        {
            return( $self->error( "I was expecting a string or a stringifyable object, but instead I got '$this'." ) );
        }
        $this = $self->new( "$this", { os => $self->{os} } ) || return( $self->pass_error );
    }
    my $file = $self->filepath;
    return( $self->error( "Directory provided \"${this}\" to check if our file \"${file}\" is part of its file path is actually not a directory." ) ) if( !$this->is_dir );
    my $parent = $this->filepath;
    my $dir_sep = $self->_os2sep;
    return( CORE::index( $file, "${parent}${dir_sep}" ) == 0 ? $self->true : $self->false );
}

sub is_relative
{
    my $self = shift( @_ );
    return( !$self->_spec_file_name_is_absolute( $self->filepath ) );
}

sub is_rootdir
{
    my $self = shift( @_ );
    return( $self->filepath eq $self->_spec_rootdir );
}

sub iterator
{
    my $self = shift( @_ );
    my $cb   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "No code reference was provided as a callback for each element found." ) ) if( ref( $cb ) ne 'CODE' );
    return( $self ) if( !$self->is_dir );
    my $seen = {};
    my $crawl;
    $crawl = sub
    {
        my $dir = shift( @_ );
        return if( !$dir->finfo->can_read );
        my $vol = $dir->volume;
        my $io = $dir->open || return( $self->pass_error );
        while( my $elem = $io->read )
        {
            next if( $elem eq '.' || $elem eq '..' );
            my $e = $self->new( $self->_spec_catpath( $vol, "$dir", $elem ), { os => $self->{os} } ) || next;
            if( $e->is_link && $opts->{follow_link} )
            {
                # Links are resolved and resulting file path made absolute
                # try-catch
                local $@;
                my $rv;
                eval
                {
                    $rv = $e->readlink;
                };
                if( $@ )
                {
                    return( $self->error( "An unexpected error occurred while crawling \"$dir\": $@" ) );
                }
                # Already been there
                next if( ++$seen->{ "$rv" } > 1 );
                $e = $rv if( $rv );
            }
            $cb->( $e );
        
            if( $e->is_dir && $opts->{recurse} )
            {
                $crawl->( $e );
            }
        }
        $io->close;
    };
    $crawl->( $self );
    return( $self );
}

sub join
{
    my $self = &_function2method( \@_ ) || return( __PACKAGE__->pass_error );
    my $frags = $self->_get_args_as_array( @_ );
    for( my $i = 0; $i < scalar( @$frags ); $i++ )
    {
        if( ref( $frags->[$i] ) && 
            $self->_is_a( $frags->[$i], 'Module::Generic::File' ) )
        {
            my $elems = $frags->[$i]->split;
            CORE::splice( @$frags, $i, 1, @$elems );
            $i += ( scalar( @$elems ) - 1 );
        } 
    }
    # For Windows OS
    my $vol = $self->volume;
    my $base = pop( @$frags );
    my $dirs = $self->_spec_catdir( [ @$frags ] );
    my $new = $self->_spec_catpath( $vol, $dirs, $base );
    return( $self->new( $new, debug => $self->debug, os => $self->{os} ) );
}

sub last_accessed { return( shift->finfo->atime ); }

sub last_modified { return( shift->finfo->mtime ); }

sub length
{
    my $self = shift( @_ );
    return( $self->new_number(0) ) if( !$self->exists );
    $self->finfo->reset;
    return( $self->finfo->size );
}

sub line
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    return( $self->error( "No callback code was provided for line()" ) ) if( !defined( $code ) || ref( $code ) ne 'CODE' );
    return( $self->error( "File \"", $self->filename, "\" is not opened." ) ) if( !$self->opened );
    return( $self->error( "File \"", $self->filename, "\" is not opened in read mode." ) ) if( !$self->can_read );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{chomp} //= 0;
    $opts->{auto_next} //= 0;
    my $l;
    while( defined( $l = $self->getline ) )
    {
        chomp( $l ) if( $opts->{chomp} );
        local $_ = $l;
        my $rv = $code->( $l );
        if( !defined( $rv ) && !$opts->{auto_next} )
        {
            last;
        }
    }
    return( $self );
}

sub lines
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "You can only call lines() on a file." ) ) unless( $self->is_file );
    my $a = $self->new_array;
    return( $a ) if( !$self->exists || $self->is_dir || !$self->finfo->can_read );
    # If binmode option was provided, the file was opened with it
    my $is_opened = $self->opened;
    my $io = $is_opened ? $is_opened : $self->open( $opts );
    return( $self->pass_error ) if( !defined( $io ) );
    my $file = $self->filepath;
    my $pos;
    my $can_read;
    my @lines = ();
    if( $is_opened )
    {
        $pos = $io->tell;
    }
    
    # try-catch
    local $@;
    eval
    {
        # Make sure we are at the top of the file
        $io->seek(0,0);
        @lines = $io->getlines;
        if( $is_opened )
        {
            $io->seek( $pos, 0 );
        }
        else
        {
            $io->close;
        }
    };
    if( $@ )
    {
        return( $self->error( "Unable to read file \"${file}\": $@" ) );
    }
    
    $a = $self->new_array( \@lines );
    if( $opts->{chomp} )
    {
        if( ref( $opts->{chomp} ) eq 'Regexp' )
        {
            s/$opts->{chomp}$//gs for( @$a );
        }
        # Much faster
        else
        {
            # Reference: <https://en.wikipedia.org/wiki/Newline>
            my $map = 
            {
            aix     => "\n",
            amigaos => "\n",
            beos    => "\n",
            darwin  => "\n",
            dos     => "\r\n",
            freebsd => "\n",
            linux   => "\n",
            netbsd  => "\n",
            openbsd => "\n",
            # Different from macos which is MacOS v9, before it moved to FreeBSD
            mac     => "\n",
            macos   => "\r",
            macosx  => "\n",
            mswin32 => "\r\n",
            os390   => "\025",
            os400   => "\025",
            riscos  => "\n",
            solaris => "\n",
            sunos   => "\n",
            symbian => "\r\n",
            unix    => "\n",
            vms     => "\n",
            windows => "\r\n",
            win32   => "\r\n",
            };
            foreach my $os ( split( /[[:blank:]]*\|[[:blank:]]*/, $opts->{chomp} ) )
            {
                local $/ = $map->{ $os } if( exists( $map->{ $os } ) );
                CORE::chomp( @$a );
            }
        }
    }
    return( $a );
}

sub load
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $file = $self->filename;
    return if( $self->is_dir );
    $opts->{binmode} //= '';
    $opts->{want_object} //= 0;
    my $binmode = $opts->{binmode};
    $binmode =~ s/^\://g;
    my $fh = $self->opened;
    unless( $fh )
    {
        # try-catch
        local $@;
        eval
        {
            $fh = IO::File->new( "<$file" );
        };
        if( $@ )
        {
            return( $self->error( "An error occured while trying to open and read file \"$file\": $@" ) );
        }        
        return( $self->error( "Unable to open file \"$file\" in read mode: $!" ) ) if( !$fh );
    }
    
    # try-catch
    local $@;
    eval
    {
        $fh->binmode( ":${binmode}" ) if( CORE::length( $binmode ) );
    };
    if( $@ )
    {
        return( $self->error( "An error occured while trying to open and read file \"$file\": $@" ) );
    }
    
    my $pos;
    if( $self->can_read )
    {
        # try-catch
        local $@;
        eval
        {
            $pos = $fh->tell;
            # Move at the beginning of the file
            $fh->seek(0, 0);
        };
        if( $@ )
        {
            return( $self->error( "An error occured while trying to open and read file \"$file\": $@" ) );
        }
    }
    my $size;
    my $buf;
    if( $binmode eq ':unix' && ( $size = -s( $fh ) ) )
    {
        # try-catch
        local $@;
        eval
        {
            $fh->read( $buf, $size );
        };
        if( $@ )
        {
            return( $self->error( "An error occured while trying to open and read file \"$file\": $@" ) );
        }
        return( $buf );
    }
    else
    {
        local $/;
        $buf = scalar( <$fh> );
    }
    if( defined( $pos ) )
    {
        # try-catch
        local $@;
        # Restore cursor position in file
        eval
        {
            $fh->seek( $pos, 0 );
        };
        if( $@ )
        {
            return( $self->error( "An error occured while trying to open and read file \"$file\": $@" ) );
        }
    }
    
    if( $opts->{want_object} || want( 'OBJECT' ) )
    {
        return( $self->new_scalar( \$buf ) );
    }
    else
    {
        return( $buf );
    }
}

sub load_json
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    # Inherited from Module::Generic
    my $j = $self->new_json || return( $self->pass_error );
    if( exists( $opts->{boolean_values} ) && 
        $self->_is_array( $opts->{boolean_values} ) )
    {
        $j->boolean_values( @{$opts->{boolean_values}} );
    }
    if( exists( $opts->{filter_json_object} ) && 
        ref( $opts->{filter_json_object} ) eq 'CODE' )
    {
        $j->filter_json_object( $opts->{filter_json_object} );
    }
    if( exists( $opts->{filter_json_single_key_object} ) && 
        ref( $opts->{filter_json_single_key_object} ) eq 'HASH' &&
        scalar( keys( %{$opts->{filter_json_single_key_object}} ) ) &&
        ref( $opts->{filter_json_single_key_object}->{ [keys( %{$opts->{filter_json_single_key_object}} ) ]->[0] } ) eq 'CODE' )
    {
        $j->filter_json_single_key_object( %{$opts->{filter_json_single_key_object}} );
    }
    if( exists( $opts->{decode_prefix} ) && 
        defined( $opts->{decode_prefix} ) && 
        CORE::length( $opts->{decode_prefix} ) )
    {
        $j->decode_prefix( $opts->{decode_prefix} );
    }
    my $json = $self->load_utf8;
    return( $self->pass_error ) if( !CORE::defined( $json ) );
    return( '' ) if( !CORE::length( $json ) );
    if( want( 'OBJECT' ) )
    {
        my $buf = $j->decode( $json );
        return( $self->new_scalar( \$buf ) );
    }
    else
    {
        # try-catch
        local $@;
        my $rv;
        eval
        {
            $rv = $j->decode( $json );
        };
        if( $@ )
        {
            return( $self->error( "Error while decoding ", CORE::length( $json ), " bytes of json data: $@" ) );
        }
        return( $rv );
    }
}

sub load_perl
{
    my $self = shift( @_ );
    # try-catch
    local $@;
    my $v;
    eval
    {
        $v = do( $self->filepath );
    };
    if( $@ )
    {
        return( $self->error( "Error while loading ", $self->length, " bytes of perl data: $@" ) );
    }
    
    if( !defined( $v ) && $@ )
    {
        return( $self->error( "Error while loading ", $self->length, " bytes of perl data: $@" ) );
    }
    elsif( !defined( $v ) && $! )
    {
        return( $self->error( "Error while loading ", $self->length, " bytes of perl data: $1" ) );
    }
    return( $v );
}

sub load_utf8
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return if( $self->is_dir );
    $opts->{binmode} = 'utf8';
    if( want( 'OBJECT' ) )
    {
        $opts->{want_object} = 1;
    }
    return( $self->load( $opts ) );
}

sub lock
{
    my $self = shift( @_ );
    my $flags;
    if( @_ && !ref( $_[0] ) && $_[0] =~ /^\d+$/ )
    {
        $flags = shift( @_ );
    }
    my $opts = $self->_get_args_as_hash( @_ );
    unless( defined( $flags ) )
    {
        $flags = 0;
        if( ( CORE::exists( $opts->{exclusive} ) && CORE::defined( $opts->{exclusive} ) && $opts->{exclusive} ) || ( CORE::exists( $opts->{mode} ) && CORE::defined( $opts->{mode} ) && $opts->{mode} eq 'exclusive' ) )
        {
            $flags |= LOCK_EX;
        }
        elsif( ( CORE::exists( $opts->{shared} ) && CORE::defined( $opts->{shared} ) && $opts->{shared} ) || ( CORE::exists( $opts->{mode} ) && CORE::defined( $opts->{mode} ) && $opts->{mode} eq 'shared' ) )
        {
            $flags |= LOCK_SH;
        }
        else
        {
            $flags |= LOCK_SH;
        }
        $flags |= LOCK_NB if( $opts->{non_blocking} || $opts->{nb} );
        $flags |= LOCK_UN if( $opts->{unlock} );
    }
    my $file = $self->filename;
    my $io = $self->opened || return( $self->error( "File is not opened yet. You must open the file \"${file}\" first to lock it." ) );
    # perlport: "(VMS, RISC OS, VOS) Not implemented"
    return(1) if( $^O =~ /^(vms|riscos|vos)$/i );
    # $type = LOCK_EX if( !defined( $type ) );
    return( $self->unlock ) if( ( $flags & LOCK_UN ) );
    # already locked
    return(1) if( $self->locked & $flags );
    $opts->{timeout} = 0 if( !defined( $opts->{timeout} ) || $opts->{timeout} !~ /^\d+$/ );
    # If the lock is different, release it first
    $self->unlock if( $self->locked );
    local $SIG{ALRM} = sub{ die( "timeout" ); };
    alarm( $opts->{timeout} );
    # try-catch
    local $@;
    my $rc;
    eval
    {
        $rc = $io->flock( $flags );
    };
    if( $@ )
    {
        return( $self->error( "Unable to set a lock on file \"${file}\": $@" ) );
    }
    return( $self->error( "Unable to set a lock on file \"$file\": $!" ) ) if( !$rc );
    alarm(0);
    $self->locked( $flags );
    return( $self );
}

sub locked { return( shift->_set_get_scalar( 'locked', @_ ) ); }

sub max_recursion { return( shift->_set_get_number( 'max_recursion', @_ ) ); }

sub makepath { return( shift->mkpath( @_ ) ); }

sub mkdir
{
    my $self = shift( @_ );
    my $oct;
    $oct = shift( @_ ) if( @_ );
    my $filename = $self->filename;
    if( $self->exists )
    {
        return( $self->error( "There is already a file \"$filename\", so I cannot create a directory." ) ) if( $self->is_file );
        return( $self->error( "Directory \"$filename\" already exists." ) );
    }
    my $rv = CORE::mkdir( $filename, ( defined( $oct ) ? $oct : () ) );
    return( $self->error( "Error creating directory \"$filename\": $!" ) ) if( !defined( $rv ) );
    return( $self );
}

sub mkpath
{
    my $self = shift( @_ );
    my $cb   = sub{1};
    $cb = pop( @_ ) if( ref( $_[-1] ) eq 'CODE' );
    my @args = @_;
    if( !scalar( @args ) )
    {
        if( $self->exists )
        {
            return( $self->new_array( [ $self ] ) );
        }
        else
        {
            @args = ( $self );
        }
    }
    # return( $self->error( "No path to create was provided." ) ) if( !scalar( @args ) );
    my $max_recursion = $self->max_recursion;
    
    my $process;
    $process = sub
    {
        my $path = shift( @_ );
        $path = $path->filepath if( $self->_is_object( $path ) && $path->isa( 'Module::Generic::File' ) );
        my $params = {};
        $params = shift( @_ ) if( @_ && ref( $_[0] ) eq 'HASH' );
        $params->{recurse} //= 0;
        return( $self->error( "Too many recursion. Exceeded the threshold of $max_recursion" ) ) if( $max_recursion > 0 && $params->{recurse} >= $max_recursion );
        # my( $vol, $dirs, $fname ) = $self->_spec_splitpath( $path );
        # my @fragments = $self->_spec_splitdir( $dirs );
        my $vol = [$self->_spec_splitpath( $path )]->[0];
        my @fragments = $self->_spec_splitdir( $path );
        my $curr = $self->new_array;
        my $parent_path  = '';
        foreach my $dir ( @fragments )
        {
            # $parent_path = $curr->length ? $self->_spec_catpath( $vol, $self->_spec_catdir( [ @$curr ] ) ) : '';
            $parent_path = $curr->length ? $self->_spec_catdir( [ @$curr ] ) : '';
            my $current_path = $self->_spec_catpath( $vol, $self->_spec_catdir( [ @$curr, $dir ] ) );
            if( !-e( "$current_path" ) )
            {
                if( !CORE::mkdir( "$current_path" ) )
                {
                    return( $self->error( "Unable to create directory \"$current_path\" ", ( CORE::length( "$parent_path" ) ? "under $parent_path" : "at filesystem root" ), ": $!" ) ) unless( $! =~ /\bFile exists\b/i );
                }
                local $_ = $current_path;
                my $rv;
                # try-catch
                local $@;
                eval
                {
                    $rv = $cb->({
                        dir    => $dir,
                        path   => $current_path,
                        parent => $parent_path,
                        volume => $vol,
                    });
                };
                if( $@ )
                {
                    return( $self->error( "Callback raised an exception on fragment \"$dir\" for path \"current_path\": $@" ) );
                }
                return if( !$rv );
            }
            # See readlink in perlport
            elsif( $^O !~ /^(mswin32|win32|vms|riscos)$/i && -l( $current_path ) )
            {
                my $actual = CORE::readlink( $current_path ) || return( $self->error( "Unable to read the symbolic link \"$current_path\": $!" ) );
                # my $before = URI::file->new( $current_path )->file( $^O );
                my $before = $self->_uri_file_new( $current_path );
                # my $after  = URI::file->new( $actual )->abs( $before )->file( $^O );
                my $after  = $self->_uri_file_abs( $actual, $before );
                $params->{recurse}++;
                # try-catch
                local $@;
                eval
                {
                    $process->( $after, $params );
                };
                if( $@ )
                {
                    return( $self->error( "An unexpected error occurred while trying to resolve the symbolic link \"$current_path\": $@" ) );
                }
            }
            elsif( !-d( $current_path ) )
            {
                return( $self->error( "Found a non-directory element \"$current_path\" ", ( CORE::length( $parent_path ) ? "under $parent_path" : "at filesystem root" ), ": $!" ) );
            }
            $curr->push( $dir );
        }
        return( $self->_spec_catpath( $vol, $self->_spec_catdir( [ @$curr ] ) ) );
    };
    
    my $new = $self->new_array;
    foreach my $path ( @args )
    {
        my $actual = $process->( $path ) || return( $self->pass_error );
        my $o = $self->new( $actual, { resolved => 1, os => $self->{os} });
        $new->push( $o );
    }
    return( $new );
}

# $self->mmap( my $var, 8196, '+<' );
# $self->mmap( my $var, 8196 );
# Use the size of $var
# $self->mmap( my $var );
# Ref: <https://www.man7.org/linux/man-pages/man2/mmap.2.html>
sub mmap
{
    my $self = shift( @_ );
    return( $self->error( "\$file->mmap( my \$variable ); or \$file->mmap( my \$variable, '+>' );" ) ) if( @_ < 1 || @_ > 3 );
    my $file = $self->filename || return( $self->error( "There is no file associated with this object!" ) );
    # Make sure the file exists
    $self->touch unless( $self->exists );
    my $opened;
    my $fh = $opened = $self->opened;
    if( !$fh )
    {
        $fh = $self->open( '+<' ) || return( $self->pass_error );
    }
    my $has_size = ( @_ >= 2 ? 1 : 0 );
    my $var_size = CORE::length( $_[0] // '' );
    my $size = (
        @_ >= 2
            ? $_[1]
            : ( CORE::defined( $_[0] ) && CORE::length( $_[0] ) )
                ? CORE::length( $_[0] ) 
                : $DEFAULT_MMAP_SIZE
    );
    return( $self->error( "mmap size is set to 0, which is not possible." ) ) if( !$size );
    my $mode = ( @_ == 3 ? $_[2] : '+<' );
    my $ok_modes = [qw( > +> >> +>> < +< )];
    my $map =
    {
    'r'  => '<',
    'r+' => '+<',
    'w'  => '>',
    'w+' => '+>',
    'a'  => '>>',
    'a+' => '+>>',
    };
    # File::Map does not recognise the mode with letters
    $mode = $map->{ lc( $mode ) } if( CORE::exists( $map->{ lc( $mode ) } ) );
    
    if( !scalar( grep( $_ eq $mode, @$ok_modes ) ) )
    {
        return( $self->error( "Unsupported file mode '$mode'" ) );
    }
    elsif( $mode eq '>' || $mode eq '+>' || $mode eq '>>' || $mode eq '+>>' )
    {
        warnings::warn( "Do not use mode '", ( $_[2] || $mode ), "', this will not work as you would expect. Alway prefer < for read-only or +< for read-write\n" ) if( warnings::enabled() );
    }
    elsif( !HAS_PERLIO_MMAP && $mode =~ /^([\<\>\+]+)[[:blank:]\h]*\:encoding\([[:blank:]\h]*utf\-?8[[:blank:]\h]*\)$/i )
    {
        $mode = "${1}:utf8";
        warnings::warn( "Use of utf8 encoding is supported by File::Map, but result is unknown\n" ) if( warnings::enabled() );
    }
    elsif( !HAS_PERLIO_MMAP && $mode =~ /\:(\w+)\([^\)]+\)/ )
    {
        return( $self->error( "You cannot use encoding $1 with File::Map. Encoding do not work with File::Map" ) );
    }
    
    $self->autoflush(1);
    # If we can write to file, we ensure the file has the same size as the one specified,
    # or else File::Map would issue an exception.
    # Afterward, when there is changes, it is ok for the data to be smaller
    if( $self->can_write )
    {
        if( $mode eq '>' || $mode eq '+>' || $mode eq '+<' || $mode eq '>>' )
        {
            my $fsize = $self->length;
            # Need to fill the file with the required allocation
            # No size argument was provided, so the size was guessed from the variable length
            # There is no prefix to the data
            if( !$has_size && $var_size )
            {
                # Position at beginning of file
                $self->seek( 0, SEEK_SET ) || return( $self->pass_error );
                $self->print( $_[0] ) || return( $self->pass_error );
                $self->truncate( $self->tell ) || return( $self->error( "Unable to truncate the file: $!" ) );
                $self->seek( 0, SEEK_SET ) || return( $self->pass_error );
            }
            else
            {
                if( $var_size && $var_size > $size )
                {
                    return( $self->error( "The mmap size specified ($size) is lower than the size of the variable provided ($var_size)." ) );
                }
                elsif( !$var_size && $size < $fsize )
                {
                    return( $self->error( "File already contain $fsize bytes of data, but required size ($size) is smaller than current content. You need to either set the required size to $fsize or empty or adjust the file content beforehand." ) );
                }
                
                if( $var_size )
                {
                    # Position at beginning of file
                    $self->seek( 0, SEEK_SET ) || return( $self->pass_error );
                    $self->print( $_[0] . ( ( $size - $var_size ) x "\000" ) ) || return( $self->pass_error );
                    # Cut everything after
                    $self->truncate( $self->tell ) || return( $self->error( "Unable to truncate the file: $!" ) );
                    $self->seek( 0, SEEK_SET ) || return( $self->pass_error );
                }
                else
                {
                    # Current file size is smaller than our required size, so we expand it with nulls
                    if( $size > $fsize )
                    {
                        # So we know how much to grab to return content initially
                        $var_size = $fsize;
                        # Position ourself
                        $self->seek( 0, SEEK_END ) || return( $self->pass_error );
                        $self->print( "\000" x ( $size - $fsize ) ) || return( $self->pass_error );
                        $self->seek( 0, SEEK_SET ) || return( $self->pass_error );
                    }
                    elsif( $size == $fsize )
                    {
                        $var_size = $fsize;
                    }
                    else
                    {
                        return( $self->error( "File already contain $fsize bytes of data, but required size ($size) is smaller than current content. You need to either set the required size to $fsize or empty or adjust the file content beforehand." ) );
                    }
                }
            }
        }
    }
    else
    {
        my $fsize = $self->length;
        if( $size > $fsize )
        {
            warnings::warn( "Required size is $size but file size is smaller with $fsize bytes, and I do not have permission to write to it to fill the gap necessary for File::Map to work.\n" ) if( warnings::enabled() );
        }
    }
    # If it was not initially opened, close it now
    # If the user had opened it, he/she will receive an error that he/she needs to close it first and that's ok for he/she to receive this error
    $self->close if( !$opened );
    
    if( HAS_PERLIO_MMAP && !$self->use_file_map )
    {
        my $io = $self->open( "${mode}:mmap" ) || return( $self->pass_error );
        my $object = tie( $_[0], 'Module::Generic::File::Map', {
            file    => $file,
            fh      => $io,
            debug   => $self->debug,
            me      => $self,
            size    => $size,
            # initial variable data length, if any. This could be zero
            length  => $var_size,
        });
        return( $object );
    }
    else
    {
        if( !$self->_load_class( 'File::Map' ) )
        {
            return( $self->error( "You perl version ($]) does not support PerlIO mmap, or you have set the property \"use_file_map\" to true and you do not have File::Map installed. Install File::Map at least if you want to use this method." ) );
        }
        
        # try-catch
        local $@;
        eval
        {
            File::Map::map_file( $_[0], $file, $mode, 0, $size );
        };
        if( $@ )
        {
            return( $self->error( "An error occurred while using mmap with File::Map: $@" ) );
        }
        return( $self );
    }
}

sub mode { return( shift->finfo->mode ); }

sub move { return( shift->_move_or_copy( move => @_ ) ); }

sub mtime { return( shift->finfo->mtime ); }

sub mv { return( shift->move( @_ ) ); }

sub nlink { return( shift->finfo->nlink ); }

sub open
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{autoflush} //= $self->autoflush;
    my $file = $self->filename;
    return( $self->error( ( $self->is_dir ? 'Directory' : 'File' ), " \"${file}\" is already opened. You need to close it first to re-open it." ) ) if( $self->opened );
    # return( $self->error( ( $self->is_dir ? 'Directory' : 'File' ), " \"${file}\" does not exist." ) ) if( !$self->exists && !CORE::length( $_[0] ) );
    my $io;
    if( $self->is_dir )
    {
        $io = IO::Dir->new( $file ) || return( $self->error( "Unable to open directory \"${file}\": $!" ) );
        $self->opened( $io );
    }
    else
    {
        my $existed = $self->exists;
        my $mode = shift( @_ ) || '<';
        if( CORE::exists( $opts->{create} ) && $opts->{create} )
        {
            $mode = '>';
        }
        elsif( CORE::exists( $opts->{append} ) && $opts->{append} )
        {
            $mode = '>>';
        }
        my $map = 
        {
        '<+' => '+<',
        };
        $mode = $map->{ $mode } if( CORE::exists( $map->{ $mode } ) );
        # try-catch
        local $@;
        eval
        {
            $io = Module::Generic::File::IO->new( "$file", "$mode", @_ );
        };
        if( $@ )
        {
            return( $self->error( "Unable to open file \"${file}\" with mode '${mode}': $@" ) );
        }
        return( $self->error( "Unable to open file \"$file\": ", Module::Generic::File::IO->error ) ) if( !$io );
        
        if( CORE::exists( $opts->{binmode} ) )
        {
            if( !defined( $opts->{binmode} ) || !CORE::length( $opts->{binmode} ) )
            {
                # try-catch
                local $@;
                my $rv;
                eval
                {
                    $rv = $io->binmode;
                };
                if( $@ )
                {
                    return( $self->error( "An unexpected error has occured while trying to open file \"${file}\": $@" ) );
                }
                return( $self->error( "Unable to set binmode to binary for file \"$file\": $!" ) ) if( !$rv );
            }
            else
            {
                $opts->{binmode} =~ s/^\://g;
                my $layer;
                if( $opts->{binmode} =~ /^(?:bytes|crlf|mmap|perlio|pop|raw|scalar|stdio|unix|utf8)\b/ )
                {
                    $layer = $opts->{binmode};
                }
                elsif( index( $opts->{binmode}, '(' ) != -1 )
                {
                    $layer = $opts->{binmode};
                }
                else
                {
                    $layer = "encoding($opts->{binmode})";
                }
                # try-catch
                local $@;
                my $rv;
                eval
                {
                    $rv = $io->binmode( ":$layer" );
                };
                if( $@ )
                {
                    return( $self->error( "An unexpected error has occured while trying to open file \"${file}\": $@" ) );
                }
                return( $self->error( "Unable to set binmode to \"$opts->{binmode}\" for file \"$file\": $!" ) ) if( !$rv );
            }
        }
        $io->autoflush( $opts->{autoflush} ) if( CORE::exists( $opts->{autoflush} ) && CORE::length( $opts->{autoflush} ) );
        $self->opened( $io );
        if( !$existed && $self->can_write )
        {
            $self->code( 201 ); # created
        }
        
        if( $opts->{lock} )
        {
            # 4 possibilities:
            # 1) regular open mode >, +>, >>, <, +<; or
            # 2) fopen style: "r", "r+", "w", "w+", "a", and "a+"; or
            # 3) Fcntl bitwise permissions to be used for sysopen, such as:
            #    O_APPEND, O_ASYNC, O_CREAT, O_DEFER, O_EXCL, O_NDELAY, O_NONBLOCK, O_SYNC, O_TRUNC
            #    O_RDONLY, O_WRONLY, O_RDWR
            #    For example: O_WRONLY|O_APPEND
            if( $mode eq '>' || $mode eq '+>' || 
                $mode eq '>>' || $mode eq '+<' || 
                $mode eq 'w' || $mode eq 'w+' || 
                $mode eq 'r+' || $mode eq 'a' || 
                $mode eq 'a+' )
            {
                $opts->{exclusive}++;
            }
            elsif( $mode eq '<' || $mode eq 'r' )
            {
                $opts->{shared}++;
            }
            elsif( $mode =~ /^\d+$/ )
            {
                if( $mode & O_CREAT || $mode & O_APPEND || 
                    $mode & O_EXCL || $mode & O_WRONLY )
                {
                    $opts->{exclusive}++;
                }
                else
                {
                    $opts->{shared}++;
                }
            }
        }
        
        if( $opts->{shared} || $opts->{exclusive} || $opts->{non_blocking} || $opts->{nb} )
        {
            $self->lock( $opts ) || return( $self->pass_error );
        }
        $io->truncate(0) if( $opts->{truncate} );
    }
    # Opening the file in read mode does not change its file information, so we only 
    # reset finfo if it was opened in write mode.
    $self->finfo->reset if( $self->can_write );
    return( $io );
}

sub open_bin
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{binmode} = ':raw';
    return( $self->open( @_, $opts ) );
}

sub open_utf8
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{binmode} = 'utf8';
    return( $self->open( @_, $opts ) );
}

sub opened
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->_set_get_scalar( 'opened', @_ ) );
    }
    else
    {
        my $fh = $self->_set_get_scalar( 'opened' );
        if( !defined( $fh ) || !Scalar::Util::blessed( $fh ) )
        {
            return( $self->new_null );
        }
        # Maybe the underlying file handle was closed, and if so we update our stored value
        if( !CORE::fileno( $fh ) )
        {
            $self->_set_get_scalar( opened => undef() );
            return( $self->new_null );
        }
        # Directory handle
        return( $fh ) if( $self->is_dir );
        if( !$fh->opened )
        {
            return( $self->new_null );
        }
        return( $fh );
    }
}

sub os { return( shift->_set_get_scalar( 'os', @_ ) ); }

sub parent
{
    my $self = shift( @_ );
    # No need to compute this twice, send what we have cached
    return( $self->{parent} ) if( $self->{parent} );
    # I deliberately did not do split( '/', $path, -1 ) so that if there is a trailing '/', it will not be counted
    # 2021-03-27: Was working well, but only on Unix systems...
    # my @segments = split( '/', $self->filename, -1 );
    my( $vol, $parent, $file ) = $self->_spec_splitpath( $self->filename );
    $vol //= '';
    $file //= '';
    my @segments = $self->_spec_splitpath( $self->_spec_catfile( [ $parent, $file ] ) );
    pop( @segments );
    return( $self ) if( !scalar( @segments ) );
    # return( $self->new( join( '/', @segments ), ( $r ? ( apache_request => $r ) : () ) ) );
    # return( $self->new( $vol . $self->_spec_catdir( [ @segments ] ) ) );
    $self->{parent} = $self->new( $self->_spec_catpath( $vol, $self->_spec_catdir( [ @segments ] ), '' ), os => $self->{os} );
    return( $self->{parent} );
}

sub print { return( shift->_filehandle_method( 'print', 'file', @_ ) ); }

sub printflush { return( shift->_filehandle_method( 'printflush', 'file', @_ ) ); }

sub printf { return( shift->_filehandle_method( 'printf', 'file', @_ ) ); }

sub println { return( shift->_filehandle_method( 'say', 'file', @_ ) ); }

sub rdev { return( shift->finfo->rdev ); }

sub read
{
    my $self = $_[0];
    return( __PACKAGE__->error( "read() must be called by an object." ) ) if( !( Scalar::Util::blessed( $self ) && $self->isa( 'Module::Generic::File' ) ) );
    my $file = $self->filepath;
    my $io = $self->opened;
    return( $self->error( ( $self->is_dir ? 'Directory' : 'File' ), " \"${file}\" is not opened." ) ) if( !$io );
    if( $self->is_dir )
    {
        my $opts = $self->_get_args_as_hash( @_[1..$#_] );
        $opts->{as_object} //= 0;
        $opts->{exclude_invisible} //= 0;
        if( want( 'LIST' ) )
        {
            # try-catch
            local $@;
            my @all;
            eval
            {
                @all = $io->read;
            };
            if( $@ )
            {
                return( $self->error( "An unexpected error has occurred while trying to read from ", ( $self->is_dir ? 'directory' : 'file' ), " \"${file}\": $@" ) );
            }
            return if( !scalar( @all ) );
            return( grep( !/^\./, @all ) ) if( $opts->{exclude_invisible} );
            return( @all );
        }
        else
        {
            # try-catch
            local $@;
            my $f;
            eval
            {
                $f = $io->read;
            };
            if( $@ )
            {
                return( $self->error( "An unexpected error has occurred while trying to read from ", ( $self->is_dir ? 'directory' : 'file' ), " \"${file}\": $@" ) );
            }
            return( $f ) if( !defined( $f ) );
            if( substr( $f, 0, 1 ) eq '.' && $opts->{exclude_invisible} )
            {
                return( $self->read( $opts ) );
            }
        
            if( $opts->{as_object} )
            {
                $f = $self->new( $f, base_dir => $self->filename ) || return( $self->pass_error );
            }
            return( $f );
        }
    }
    else
    {
        # $io->read( $buff, $size, $offset );
        return( $io->read( $_[1], $_[2], $_[3] ) ) if( scalar( @_ ) >= 4 );
        # $io->read( $buff, $size );
        return( $io->read( $_[1], $_[2] ) )        if( scalar( @_ ) >= 3 );
        # $io->read( $buff );
        return( $io->read( $_[1] ) )               if( scalar( @_ ) >= 2 );
    }
}

sub readdir
{
    my $self = shift( @_ );
    return( $self->error( "readdir() can only be called on a directory." ) ) if( !$self->is_dir );
    return( $self->read( @_ ) );
}

# perlport: "(Win32, VMS, RISC OS) Not implemented."
sub readlink
{
    my $self = shift( @_ );
    return( $self ) if( $^O =~ /^(mswin32|win32|vms|riscos)$/i );
    return( $self ) if( !$self->exists );
    return( $self ) if( !$self->is_link );
    my $file = $self->filepath;
    my $rv = CORE::readlink( $self->filepath ) || 
        return( $self->error( "An unexpected error occurred while trying to read link \"${file}\": $!" ) );
    return( $self->new( $rv, { base_dir => $self->parent, os => $self->{os} } ) );
}

sub realpath
{
    my $self = shift( @_ );
    my $path = shift( @_ ) || $self->filename;
    # try-catch
    local $@;
    my $real = eval
    {
        require Cwd;
        return( Cwd::realpath( $path ) );
    };
    return( $self->error( "Error getting the real path for $path: $@" ) ) if( $@ );
    return( $self->new( $real, { base_dir => $self->parent, os => $self->{os} } ) );
}

sub relative
{
    my $self = shift( @_ );
    my $base = @_ ? shift( @_ ) : $self->base_dir;
    return( $self->_spec_abs2rel( [ $self->filepath, $base ] ) );
}

sub remove { return( shift->delete( @_ ) ); }

sub rename { return( shift->move( @_ ) ); }

sub resolve
{
    my $self = shift( @_ );
    my $path = shift( @_ ) || $self->filename;
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{recurse} //= 0;
    my $max_recursion = $self->max_recursion // 0;
    return( $self->error( "Too many recursion. Exceeded the threshold of $max_recursion" ) ) if( $max_recursion > 0 && $opts->{recurse} >= $max_recursion );
    my $os = $self->{os} || $^O;
    my $globbing = CORE::exists( $opts->{globbing} ) ? $opts->{globbing} : $self->{globbing};
    # Those do not work in virtualisation
    if( $globbing && $os eq $^O )
    {
        if( $os =~ /^(mswin32|win32|vms|riscos)$/i )
        {
            require File::DosGlob;
            $path = File::DosGlob::glob( $path );
        }
        else
        {
            $path = File::Glob::bsd_glob( $path );
        }
    }
    my( $vol, $dirs, $fname ) = $self->_spec_splitpath( $path );
    my @fragments = $self->_spec_splitdir( $dirs );
    my $curr = $self->new_array;
    my $parent_path  = '';
    foreach my $dir ( @fragments )
    {
        my $current_path = $self->_spec_catdir( [ @$curr, $dir ] );
        # Stop right here. There is a missing path, thus we cannot resolve
        if( !-e( $current_path ) )
        {
            # Return false, but not undef, which we use for errors
            return( '' );
        }
        elsif( $os !~ /^(mswin32|win32|vms|riscos)$/i && -l( $current_path ) )
        {
            # try-catch
            local $@;
            eval
            {
                my $actual = CORE::readlink( $current_path );
                my $before = URI::file->new( $current_path, ( $self->{os} || $^O ) );
                # my $after  = URI::file->new( $actual )->abs( $before )->file( $^O );
                my $after  = $self->_uri_file_abs( $actual, $before );
                $opts->{recurse}++;
                unless( $self->_spec_file_name_is_absolute( $after ) )
                {
                    $after = $self->resolve( $after, $opts );
                }
                my @new = $self->_spec_splitdir( $after );
                $curr = $self->new_array( \@new );
            };
            if( $@ )
            {
                return( $self->error( "An unexpected error occurred while trying to resolve the symbolic link \"$current_path\": $@" ) );
            }
            next;
        }
        $curr->push( $dir );
    }
    # TODO: Remove debugging
    my $debug = $self->debug // 0;
    if( $debug >= 4 )
    {
        my $test = $self->_spec_catpath( $vol, $self->_spec_catdir( [ @$curr ] ), $fname );
        if( !CORE::length( $test ) )
        {
        }
    }
    return( $self->new( $self->_spec_catpath( $vol, $self->_spec_catdir( [ @$curr ] ), $fname ), { resolved => 1, os => $self->{os}, ( $self->{base_dir} ? ( base_dir => $self->{base_dir} ) : () ), debug => $self->debug }) );
}

sub resolved { return( shift->_set_get_boolean( 'resolved', @_ ) ); }

sub rmdir
{
    my $self = shift( @_ );
    return( $self ) if( !$self->is_dir );
    my $dir = $self->filename;
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = CORE::rmdir( $dir );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to remove the directory \"$dir\": $@" ) );
    }
    return( $self->error( "Unable to remove directory \"$dir\": $!. Is it empty?" ) ) if( !$rv );
    return( $self );
}

# $obj->rmtree( $some_dir_path );
# $obj->rmtree( $some_dir_path, $options_hashref );
# Module::Generic::File->rmtree( $some_dir_path );
# Module::Generic::File->rmtree( $some_dir_path, $options_hashref );
# rmtree( $some_dir_path );
# rmtree( $some_dir_path, $options_hashref );
# file( $some_dir_path )->rmtree;
sub rmtree
{
    my $self = &_function2method( \@_ ) || return( __PACKAGE__->pass_error );
    my $dir  = $self->filepath;
    return( $self->error( "Can only call rmtree on a directory." ) ) if( !$self->is_dir );
    my $opts = $self->_get_args_as_hash( @_ );
    if( !$self->_is_class_loadable( 'File::Find' ) )
    {
        return( $self->error( "File::Find is required, but is not installed in your system." ) );
    }
    $self->_load_class( 'File::Find' ) || return( $self->pass_error );
    $opts->{max_files} //= 0;
    $opts->{keep_root} //= 0;
    my $p = +{ map( ( CORE::exists( $opts->{ $_ } ) ? ( $_ => $opts->{ $_ } ) : () ), qw( bydepth dangling_symlinks follow follow_fast follow_skip no_chdir postprocess preprocess untaint untaint_pattern untaint_skip ) ) };
    my $files = $self->new_array;
    $p->{wanted} = sub
    {
        return if( $opts->{max_files} > 0 && $files->length >= $opts->{max_files} );
        $files->push( $File::Find::name );
    };
    
    # try-catch
    local $@;
    eval
    {
        File::Find::find( $p, $dir );
    };
    if( $@ )
    {
        return( $self->error( "An unexpected error has occurred while trying to scan directory \"$dir\": $@" ) );
    }
    
    my $total = $files->length;
    my $dirs_to_remove = $self->new_array;
    $files->for(sub
    {
        my( $i, $f ) = @_;
        if( -d( $f ) )
        {
            $dirs_to_remove->push( $f );
            $files->splice( $i, 1 );
            $files->return(-1);
        }
    });
    
    my $prefix = $opts->{dry_run} ? '[DRY RUN]' : '[LIVE]';
    
    # first, we remove all files we found with File::Find
    # then, we check those file path to derive their respective directory and we remove them as well
    # We start in reverse order to get the deepest files first
    my $error_files = $self->new_array;
    $files->foreach(sub
    {
        my $f = shift( @_ );
        if( $opts->{dry_run} )
        {
            if( !-e( $f ) || !-w( $f ) )
            {
                $error_files->push( $f );
            }
            else
            {
            }
        }
        else
        {
            # try-catch
            local $@;
            eval
            {
                CORE::unlink( $f ) || do
                {
                    $error_files->push( $f );
                };
            };
            if( $@ )
            {
                $error_files->push( $f );
                warnings::warn( "An error occurred while trying to remove file \"$f\": $@\n" ) if( warnings::enabled() );
            }
        }
        return(1);
    });
    if( my $total_err = $error_files->length )
    {
        if( $total_err > 10 )
        {
            return( $self->error( $error_files->length, " files could not be removed." ) );
        }
        else
        {
            return( $self->error( "The following files could not be removed: ", $error_files->join( ', ' )->scalar ) );
        }
    }
    
    my $cwd = $self->cwd;
    # If our current working directory is or contained by the one we want to remove, 
    # we chdir to the previous directory if any or default system one
    if( $cwd eq $self || $cwd->contains( $self ) )
    {
        my $go_there = sub
        {
            my $where = shift( @_ );
            # try-catch
            local $@;
            eval
            {
                CORE::chdir; # Switch to HOME, or LOGDIR. See chdir in perlfunc
            };
            if( $@ )
            {
                warnings::warn( "Unable to chdir to ", ( defined( $where ) ? "\"${where}\"" : 'default system location (if any)' ), ": $@\n" ) if( warnings::enabled() );
            }
        };
        
        if( my $prev_cwd = $self->_prev_cwd )
        {
            $self->chdir( $prev_cwd ) || $go_there->( $prev_cwd );
        }
        else
        {
             $go_there->();
        }
    }
    
    $dirs_to_remove->sort->reverse->foreach(sub
    {
        my $d = shift( @_ );
        if( $opts->{dry_run} )
        {
            if( !-e( $d ) || !-w( $d ) )
            {
                $error_files->push( $d );
            }
            else
            {
            }
        }
        else
        {
            # try-catch
            local $@;
            eval
            {
                CORE::rmdir( $d ) || do
                {
                    $error_files->push( $d );
                };
            };
            if( $@ )
            {
                $error_files->push( $d );
                warnings::warn( "An error occurred while trying to remove directory \"$d\": $@\n" ) if( warnings::enabled() );
            }
        }
        # Return true
        return(1);
    });
    unless( $opts->{keep_root} || !-e( $dir ) )
    {
        CORE::rmdir( $dir ) || do
        {
            warnings::warn( "Unable to remove the directory \"$dir\": $!\n" ) if( warnings::enabled() );
        };
    }
    $error_files->foreach(sub
    {
    });
    return( $self );
}

sub rewind { return( shift->_filehandle_method( 'rewind', 'directory', @_ ) ); }

sub rewinddir { return( shift->rewind( @_ ) ); }

sub root_dir
{
    my $self = shift( @_ );
    return( $self->new( $self->_spec_rootdir, { os => $self->{os} }) );
}

sub rootdir { return( shift->root_dir ); }

sub say { return( shift->_filehandle_method( 'say', 'file', @_ ) ); }

sub seek { return( shift->_filehandle_method( 'seek', 'file|directory', @_ ) ); }

sub size
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $file = $self->filepath;
    if( $self->is_dir )
    {
        if( !$self->_is_class_loadable( 'File::Find' ) )
        {
            return( $self->length );
        }
        $self->_load_class( 'File::Find' ) || return( $self->length );
        my $total = 0;
        $opts->{follow_link} //= 0;
        my $p = +{ map( ( CORE::exists( $opts->{ $_ } ) ? ( $_ => $opts->{ $_ } ) : () ), qw( bydepth dangling_symlinks follow follow_fast follow_skip no_chdir postprocess preprocess untaint untaint_pattern untaint_skip ) ) };
        $p->{follow} = CORE::delete( $opts->{follow_link} );
        $p->{wanted} = sub
        {
            $total += -s( $File::Find::name ) if( -f( $File::Find::name ) );
        };
        
        # try-catch
        local $@;
        eval
        {
            File::Find::find( $p, $file );
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error has occurred while calling File::Find::find() to compte recursively all files size in directory \"${file}\": $@" ) );
        }
        return( $self->new_number( $total ) );
    }
    else
    {
        return( $self->length );
    }
}

sub slurp { return( shift->load( @_ ) ); }

sub slurp_utf8 { return( shift->load_utf8( @_ ) ); }

sub spew { return( shift->unload( @_ ) ); }

sub spew_utf8 { return( shift->unload_utf8( @_ ) ); }

sub split
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    # e.g. /some/where/my/file.txt
    my $file = $self->filename;
    $opts->{remove_leading_sep} //= 0;
    my( $vol, $path, $base ) = $self->_spec_splitpath( $file );
    # /some/where/my/
    my $frags = [$self->_spec_splitdir( $path )];
    pop( @$frags ) if( scalar( @$frags ) > 1 && !CORE::length( $frags->[-1] ) );
    shift( @$frags ) if( scalar( @$frags ) > 1 && !CORE::length( $frags->[0] ) && $opts->{remove_leading_sep} );
    push( @$frags, $base );
    return( $self->new_array( $frags ) );
}

sub spurt { return( shift->unload( @_ ) ); }

sub spurt_utf8 { return( shift->unload_utf8( @_ ) ); }

sub stat { return( shift->finfo ); }

sub stderr { return( &_function2method( \@_ )->_standard_io( 'stderr', @_ ) ); }

sub stdin { return( &_function2method( \@_ )->_standard_io( 'stdin', @_ ) ); }

sub stdout { return( &_function2method( \@_ )->_standard_io( 'stdout', @_ ) ); }

sub suffix { return( shift->extension( @_ ) ); }

sub symlink
{
    my $self = shift( @_ );
    # perlport: "symlink (Win32, RISC OS) Not implemented"
    return( $self ) if( $^O =~ /^(mswin32|win32|riscos)$/i );
    my $this = shift( @_ );
    return( $self->error( "No target for symbolic link was provided." ) ) if( !defined( $this ) || !CORE::length( $this ) );
    unless( $self->_is_object( $this ) && $self->_is_a( $this => 'Module::Generic::File' )  )
    {
        if( ref( $this ) && !overload::Method( $this, '""' ) )
        {
            return( $self->error( "I was expecting a string or a stringifyable object, but instead I got '$this'." ) );
        }
        $this = $self->new( "$this", { os => $self->{os} } ) || return( $self->pass_error );
    }
    
    return( $self->error( "There is already a file at \"${this}\"." ) ) if( $this->exists );
    my $file = $self->filepath;
    my $dest = $this->filepath;
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = CORE::symlink( $file, $dest );
    };
    if( $@ )
    {
        return( $self->error( "An unexpected error has occurred while trying to create a symbolic link from \"${file}\" to \"${dest}\": $@" ) );
    }
    return( $self->error( "Unable to create link from \"${file}\" to \"${dest}\": $!" ) ) if( !$rv );
    return( $self );
}

sub sync { return( shift->_filehandle_method( 'sync', 'file', @_ ) ); }

sub sys_tmpdir { return( __PACKAGE__->new( ref( $_[0] ) ? shift->_spec_tmpdir : File::Spec->tmpdir ) ); }

sub sysread { return( shift->_filehandle_method( 'sysread', 'file', @_ ) ); }

sub sysseek { return( shift->_filehandle_method( 'sysseek', 'file', @_ ) ); }

sub syswrite { return( shift->_filehandle_method( 'syswrite', 'file', @_ ) ); }

sub tell { return( shift->_filehandle_method( 'tell', 'file|directory', @_ ) ); }

sub tempdir { return( &_function2method( \@_ )->tmpdir( @_ ) ); }

sub tempfile
{
    my $self = &_function2method( \@_ ) || __PACKAGE__;
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{tmpdir} //= 0;
    if( CORE::exists( $opts->{unlink} ) )
    {
        $opts->{auto_remove} = CORE::delete( $opts->{unlink} );
    }
    elsif( CORE::exists( $opts->{cleanup} ) )
    {
        $opts->{auto_remove} = CORE::delete( $opts->{cleanup} );
    }
    $opts->{auto_remove} = 0 unless( CORE::exists( $opts->{auto_remove} ) );
    my $uuid = Data::UUID->new;
    my $fname = $uuid->create_str;
    if( CORE::exists( $opts->{extension} ) && !CORE::exists( $opts->{suffix} ) )
    {
        $opts->{suffix} = CORE::delete( $opts->{extension} );
    }
    elsif( CORE::exists( $opts->{ext} ) && !CORE::exists( $opts->{suffix} ) )
    {
        $opts->{suffix} = CORE::delete( $opts->{ext} );
    }
    
    # $fname .= $opts->{suffix} if( CORE::defined( $opts->{suffix} ) && CORE::length( $opts->{suffix} ) && $opts->{suffix} =~ /^\.[\w\-\_]+$/ );
    if( CORE::defined( $opts->{suffix} ) && CORE::length( $opts->{suffix} ) && $opts->{suffix} =~ /^[\w\-\_\.]+$/ )
    {
        substr( $opts->{suffix}, 0, 0, '.' ) if( substr( $opts->{suffix}, 0, 1 ) ne '.' );
        $fname .= $opts->{suffix};
    }
    my $dir;
    my $sys_tmpdir = $self->_spec_tmpdir;
    my $base_vol = [$self->_spec_splitpath( $sys_tmpdir )]->[0];
    if( defined( $opts->{dir} ) && CORE::length( $opts->{dir} ) )
    {
        if( !-e( $opts->{dir} ) )
        {
            return( $self->error( "Directory provided \"$opts->{dir}\" does not exist." ) );
        }
        # perl resolves for us if this is a symbolic link
        elsif( !-d( $opts->{dir} ) )
        {
            return( $self->error( "Directory provided \"$opts->{dir}\" is actually not a directory." ) );
        }
        elsif( !-w( $opts->{dir} ) )
        {
            warnings::warn( "Warning only: directory provided is not writable for uid $>\n" ) if( warnings::enabled() );
        }
        $dir = $opts->{dir};
        $base_vol = [$self->_spec_splitpath( $dir )]->[0];
    }
    elsif( $opts->{tmpdir} )
    {
        # $dir = $self->_spec_catpath( $base_vol, $sys_tmpdir, $uuid->create_str );
        $dir = $self->tmpdir(
            cleanup => $opts->{auto_remove},
            tmpdir  => 1,
        );
        return( $self->error( "Found an existing directory with the name just generated: \"$dir\". This should never happen." ) ) if( -e( $dir ) );
        CORE::mkdir( $dir ) || return( $self->error( "Unable to create temporary directory \"$dir\": $!" ) );
    }
    
    unless( defined( $dir ) )
    {
        $dir = $sys_tmpdir;
    }
    CORE:delete( @$opts{ qw( dir suffix ) } );
    $opts->{open} //= 0;
    my $open = CORE::delete( $opts->{open} );
    $opts->{resolved} = 1;
    my( $parent, $me );
    ( $base_vol, $parent, $me ) = $self->_spec_splitpath( $dir );
    $dir = $self->_spec_catdir( [ $parent, $me ] );
    CORE::delete( @$opts{ qw( tmpdir tempdir ) } );
    my $new = $self->new( $self->_spec_catpath( $base_vol, $dir, $fname ), %$opts ) || return( $self->pass_error );
    if( $open )
    {
        $opts->{mode} //= '+>';
        my $mode = CORE::delete( $opts->{mode} );
        $new->open( $mode, $opts ) || return( $self->pass_error );
    }
    return( $new );
}

sub tmpdir
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $uuid = Data::UUID->new;
    my $parent;
    my $sys_tmpdir = $self->_spec_tmpdir;
    if( defined( $opts->{dir} ) && CORE::length( $opts->{dir} ) )
    {
        if( !-e( $opts->{dir} ) )
        {
            return( $self->error( "Directory provided \"$opts->{dir}\" does not exist." ) );
        }
        # perl resolves for us if this is a symbolic link
        elsif( !-d( $opts->{dir} ) )
        {
            return( $self->error( "Directory provided \"$opts->{dir}\" is actually not a directory." ) );
        }
        elsif( !-w( $opts->{dir} ) )
        {
            warnings::warn( "Warning only: directory provided is not writable for uid $>\n" ) if( warnings::enabled() );
        }
        $parent = $opts->{dir};
    }
    elsif( $opts->{tmpdir} )
    {
        $parent = $sys_tmpdir;
    }
    
    unless( defined( $parent ) )
    {
        $parent = $sys_tmpdir;
    }
    
    # Necessary contortion to accomodate systems like Windows that use 'volume'
    my( $vol, $basedir, $fname ) = $self->_spec_splitpath( $parent );
    my $dir  = $self->_spec_catpath( $vol, $self->_spec_catdir( [ $basedir, $fname ] ), $uuid->create_str );
    return( $self->error( "Found an existing directory with the name just generated: \"${dir}\". This should never happen." ) ) if( -e( $dir ) );
    CORE::mkdir( $dir ) || return( $self->error( "Unable to create temporary directory \"$dir\": $!" ) );
    $opts->{resolved} = 1;
    if( CORE::exists( $opts->{unlink} ) )
    {
        $opts->{auto_remove} = CORE::delete( $opts->{unlink} );
    }
    elsif( CORE::exists( $opts->{cleanup} ) )
    {
        $opts->{auto_remove} = CORE::delete( $opts->{cleanup} );
    }
    $opts->{auto_remove} = 0 unless( CORE::exists( $opts->{auto_remove} ) );
    return( $self->new( $dir, $opts ) );
}

sub tmpnam { return( shift->tmpname( @_ ) ); }

sub tmpname { return( shift->tempfile( @_ )->basename ); }

sub touch
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    if( !$self->exists )
    {
        my $io = $self->open( '>' ) || return( $self->pass_error );
        $io->close;
    }
    else
    {
        # works for both directory and files
        my $now = time();
        CORE::utime( $now, $now, $file );
    }
    return( $self );
}

# Idea borrowed from Path::Tiny
sub touchpath
{
    my $self = shift( @_ );
    $self->parent->mkpath || return( $self->pass_error( $self->parent->error ) );
    return( $self->touch );
}

sub truncate { return( shift->_filehandle_method( 'truncate', 'file', @_ ) ); }

sub type
{
    my $self = shift( @_ );
    if( @_ )
    {
        $self->_set_get_scalar( 'type', @_  );
    }
    # Try to guess it
    elsif( !$self->{type} && $self->exists )
    {
        $self->_set_get_scalar( type => $self->is_dir ? 'directory' : 'file' );
    }
    return( $self->_set_get_scalar( 'type' ) );
}

sub uid { return( shift->finfo->uid ); }

sub ungetc { return( shift->_filehandle_method( 'ungetc', 'file', @_ ) ); }

sub unlink
{
    my $self = shift( @_ );
    return( $self->error( "Cannot call unlink on a directory." ) ) if( $self->is_dir );
    my $file = $self->filepath;
    # Would only remove the most recent version on VMS
    CORE::unlink( $file ) || return( $self->error( "Unable to remove file \"${file}\": $!" ) );
    return( $self );
}

sub unload
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    return( $self ) if( ( ref( $data ) eq 'SCALAR' && !CORE::length( $$data ) ) || ( !ref( $data ) && !CORE::length( $data ) ) );
    return( $self->error( "I was expecting either a string or a scalar reference, but instead I got '$data'." ) ) if( ref( $data ) && ref( $data ) ne 'SCALAR' && !overload::Method( $data, '""' ) );
    return( $self ) if( $self->is_dir );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{append} //= 0;
    $opts->{lock} //= 0;
    my $file = $self->filepath;
    my $io;
    my $opened = $io = $self->opened;
    if( !$opened )
    {
        if( $opts->{append} )
        {
            $io = $self->open( '>>', $opts ) || return( $self->pass_error );
        }
        else
        {
            $io = $self->open( '>', $opts ) || return( $self->pass_error );
        }
    }
    elsif( !$self->can_write )
    {
        return( $self->error( "File \"$file\" is opened, but not in write mode. Cannot unload data into it." ) );
    }
    $self->lock if( $opts->{lock} );
    $io->print( ref( $data ) ? $$data : $data ) || return( $self->error( "Unable to print ", CORE::length( ref( $data ) ? $$data : $data ), " bytes of data to file \"${file}\": $!" ) );
    $self->unlock if( $opts->{lock} );
    # close it if it were close before we opened it
    $io->close if( !$opened );
    return( $self );
}

sub unload_json
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    # my $j = JSON->new->allow_nonref->allow_blessed->convert_blessed->allow_tags->relaxed;
    my $j = $self->new_json || return( $self->pass_error );
    my $equi =
    {
        order => 'canonical',
        ordered => 'canonical',
        sorted => 'canonical',
        sort => 'canonical',
    };
    
    foreach my $opt ( keys( %$opts ) )
    {
        # We already save the data using the binmode utf8, so we do not want JSON to also encode it into utf8
        next if( $opt eq 'utf8' );
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
                return( $self->error( "Unable to encode perl data to json: $@ (max_depth value is ${max})" ) );
            }
            else
            {
                return( $self->error( "Unable to encode perl data to json: $@" ) );
            }
        }
    }
    my $json = $j->encode( $data );
    $self->unload_utf8( $json ) || return( $self->pass_error );
}

sub unload_perl
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $callback;
    if( $opts->{callback} && ref( $opts->{callback} ) eq 'CODE' )
    {
        $callback = $opts->{callback};
    }
    else
    {
        require Data::Dump;
        local $Data::Dump::INDENT = $opts->{indent} if( exists( $opts->{indent} ) );
        local $Data::Dump::TRY_BASE64 = $opts->{max_binary_size} if( exists( $opts->{max_binary_size} ) );
        local $Data::Dump::LINEWIDTH = $opts->{max_width} if( exists( $opts->{max_width} ) );
        $callback = sub{ return( Data::Dump::dump( @_ ) ); };
    }

    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = $self->unload_utf8( $callback->( $data ) );
    };
    if( $@ )
    {
        return( $self->error( "Unable to dump perl data to file: $@" ) );
    }
    return( $self->pass_error ) if( !$rv );
    return( $rv );
}

sub unload_utf8
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{binmode} = 'utf8';
    return( $self->unload( $data, $opts ) );
}

sub unlock
{
    my $self = shift( @_ );
    return( $self ) if( !$self->locked );
    my $file = $self->filepath;
    my $io = $self->opened;
    return( $self->error( "File is not opened yet. You must open the file \"${file}\" first to unlock semaphore." ) ) if( !$io );
    # my $flags = $self->locked | LOCK_UN;
    # $flags ^= LOCK_NB if( $flags & LOCK_NB );
    my $flags = LOCK_UN;
    my $rc;
    # try-catch
    local $@;
    eval
    {
        $rc = $io->flock( $flags );
    };
    if( $@ )
    {
        return( $self->error( "An unexpected error has occurred while trying to unlock file \"${file}\": $@" ) );
    }

    if( $rc )
    {
        $self->locked(0);
    }
    else
    {
        return( $self->error( "Unable to remove the lock from file \"${file}\" using flags '$flags': $!" ) );
    }
    return( $self );
}

sub unmap
{
    my $self = shift( @_ );
    return( $self->error( "No variable provided to unmap" ) ) if( !scalar( @_ ) );
    return( $self->error( "Variable provided is undefined" ) ) if( !defined( $_[0] ) );
    if( !$self->_load_class( 'File::Map' ) )
    {
        return( $self->error( "Unable to unmap. File::Map is not installed on your system" ) );
    }
    # try-catch
    local $@;
    eval
    {
        File::Map::unmap( $_[0] );
    };
    if( $@ )
    {
        return( $self->error( "Error calling File::Map::unmap on the variable provided: $@" ) );
    }
    return( $self );
}

sub uri
{
    my $self = shift( @_ );
    return( $self->_uri_file_class->new( $self->filename ) );
}

sub use_file_map { return( shift->_set_get_boolean( 'use_file_map', @_ ) ); }

sub utime
{
    my $self = shift( @_ );
    # $atime and $mtime may very well be null, in which case, on most system this will
    # set those time to current time.. See man page of utime(2)
    my( $atime, $mtime ) = @_;
    return( CORE::utime( $atime, $mtime, $self->filename ) );
}

sub volume
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $vol = shift( @_ );
        my $fpath = $self->filepath;
        my( $old_vol, $dir, $fname ) = $self->_spec_splitpath( $fpath );
        $self->filename( $self->_spec_catpath( $vol, $dir, $fname ) );
        return( $old_vol );
    }
    return( [$self->_spec_splitpath( $self->filepath )]->[0] );
}

# $f->write( $data );
# $f->write( @list_of_data );
sub write
{
    my $self = shift( @_ );
    return( __PACKAGE__->error( "read() must be called by an object." ) ) if( !( Scalar::Util::blessed( $self ) && $self->isa( 'Module::Generic::File' ) ) );
    my $file = $self->filepath;
    # Noop
    return( $self ) if( $self->is_dir );
    my $io = $self->opened;
    return( $self->error( "File \"${file}\" is not opened." ) ) if( !$io );
    return( $self->error( "File \"${file}\" is not opened with write permission." ) ) if( !$self->can_write );
    # Nothing to write was provided
    return( $self ) if( !scalar( @_ ) );
    
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = $io->print( @_ );
    };
    if( $@ )
    {
        return( $self->error( "An unexpected error has occurred while trying to write to file \"${file}\": $@" ) );
    }
    return( $self->error( "Unable to print data to file \"${file}\": $!" ) ) if( !$rv );
    return( $self );
}

sub _filehandle_method
{
    my $self = shift( @_ );
    # e.g. print, printf, seek, tell, rewinddir, close, etc
    my $what = shift( @_ );
    # 'file' or 'directory'
    my $for  = shift( @_ );
    my $file = $self->filepath;
    my $type = $self->is_dir ? 'directory' : 'file';
    my $ok = [CORE::split( /\|/, $for )];
    return( $self->error( "You cannot call \"${what}\" on a ${type}. You can only call this on ${for}" ) ) if( !scalar( CORE::grep( $_ eq $type, @$ok ) ) );
    my $opened = $self->opened || 
        return( $self->error( ucfirst( $type ), " \"${file}\" is not opened yet." ) );
    # return( $opened->$what( @_ ) );
    my @rv = ();
    # try-catch
    local $@;
    eval
    {
        if( wantarray() )
        {
            @rv = $opened->$what( @_ );
        }
        else
        {
            $rv[0] = $opened->$what( @_ );
        }
    };
    if( $@ )
    {
        warn( "An unexpected error occurred while trying to call ${what} on ${type} \"${file}\": $@\n" );
        return( $self->error( "An unexpected error occurred while trying to call ${what} on ${type} \"${file}\": $@" ) );
    }
    return( $self->error({ skip_frames => 1, message => "Error with $what on file \"$file\": $!" }) ) if( ( !scalar( @rv ) || !CORE::defined( $rv[0] ) ) && $what ne 'getline' );
    return( wantarray() ? @rv : $rv[0] );
}

# my $self = &_function2method( \@_ );
sub _function2method
{
    my $ref = shift( @_ );
    return( __PACKAGE__ ) if( !scalar( @$ref ) );
    if( Scalar::Util::blessed( $ref->[0] ) && $ref->[0]->isa( __PACKAGE__ ) )
    {
        my @caller = caller(2);
        # if we were called from 'file' method, our directory to remove is already set in 
        # our object, so we take only one or two arguments:
        # file( $dir_to_remove )->rmtree
        if( CORE::defined( $caller[3] ) &&
            substr( $caller[3], rindex( $caller[3], '::' ) + 2 ) eq 'file' && 
            $caller[0] eq ref( $ref->[0] ) )
        {
            return( shift( @$ref ) );
        }
        # An object followed by a hash of parameters, so only 2 arguments.
        # The directory to remove is embedded in our object.
        # $obj->rmtree( $options_hashref )
        elsif( ref( $ref->[1] ) eq 'HASH' || scalar( @$ref ) == 1 )
        {
            return( shift( @$ref ) );
        }
        # The second argument is a directory:
        # $obj->rmtree( $some_dir_path );
        # or
        # $obj->rmtree( $some_dir_path, $options_hashref );
        else
        {
            # return( shift( @$ref )->new( shift( @$ref ) ) );
            return( shift( @$ref ) );
        }
    }
    # Module::Generic::File->rmtree( $dir_to_remove );
    # Module::Generic::File->rmtree( $dir_to_remove, $options_hashref );
    # Module::Generic::File->rmtree( $dir_to_remove, %options );
    # Module::Generic::File->tempfile( $options_hashref );
    # Module::Generic::File->tempfile( %options );
    elsif( CORE::index( $ref->[0], '::' ) != -1 && $ref->[0]->isa( __PACKAGE__ ) )
    {
        # The 2nd arg is a file path, either as a string or an overloaded string
        # There is nothing more or the 3rd arg is an hash ref of options or there is an even number of options
        if( ( !ref( $ref->[1] ) || ref( $ref->[1] ) && overload::Method( $ref->[1], '""' ) ) &&
            ( scalar( @$ref ) == 2 || 
              ref( $ref->[2] ) eq 'HASH' || 
              ( scalar( @$ref ) > 3 && !( scalar( @$ref ) % 2 ) )
            ) )
        {
            return( shift( @$ref )->new( shift( @$ref ) ) );
        }
        else
        {
            return( shift( @$ref ) );
        }
    }
    # Imported in the caller's namespace:
    # rmtree( $dir_to_remove );
    # or
    # rmtree( $dir_to_remove, $options_hashref );
    elsif( ref( $ref->[0] ) ne 'HASH' )
    {
        if( ( !ref( $ref->[0] ) || ref( $ref->[0] ) && overload::Method( $ref->[0], '""' ) ) &&
            ( scalar( @$ref ) == 1 || 
              ref( $ref->[1] ) eq 'HASH' || 
              ( scalar( @$ref ) > 2 && !( ( scalar( @$ref ) - 1 ) % 2 ) )
            ) )
        {
            return( __PACKAGE__->new( shift( @$ref ) ) );
        }
        else
        {
            return( __PACKAGE__ );
        }
    }
    else
    {
        return( __PACKAGE__ );
    }
}

sub _make_abs
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field provided." ) );
    if( @_ )
    {
        my $this = shift( @_ );
        if( Scalar::Util::blessed( $this ) && $this->isa( 'URI::file' ) )
        {
            # $this = URI->new_abs( $this )->file( $^O );
            $this = URI->new_abs( $this )->file( $self->{os} || $^O );
        }
        elsif( !$self->_spec_file_name_is_absolute( "$this" ) )
        {
            # $this = URI::file->new_abs( "$this" )->file( $^O );
            $this = URI::file->new_abs( "$this" )->file( $self->{os} || $^O );
            # $this = $self->_uri_file_class->new_abs( "$this" )->file( $self->{os} || $^O );
        }
        $self->{ $field } = $this;
    }
    return( $self->{ $field } );
}

sub _move_or_copy
{
    my $self = shift( @_ );
    # move or copy
    my $what = shift( @_ );
    # where
    my $dest = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "No clue what action \"$what\" is. I was expecting 'move' or 'copy'." ) ) if( $what ne 'move' && $what ne 'copy' );
    $opts->{overwrite} //= 0;
    my $file = $self->filename;
    my $new_path;
    # Check if file exists. If it does, move/copy it, otherwise, just change its filepath
    # in which case the move/copy will be virtual, like manipulating a file path
    if( $self->exists )
    {
        # If the source is a directory;
        # 1) the target is an existing directory, then we move/copy the source inside the target
        #    just like unix systems would do
        # 2) the target does not exist, then File::Copy will simply rename/create it; fine.
        # 3) the target exists and is a file. That's obviously not ok,
        if( $self->is_dir )
        {
            my $base = $self->basename;
            # We move/copy the source inside the target directory.
            # For that we provide File::Copy with dest/target otherwise File::Copy
            # would do a rename of the directory, even removing the previous one!
            # Yes, -d over a IO::Dir directory handle works...
            if( -e( $dest ) && -d( $dest ) )
            {
                # If $dest is a IO::Dir file handle, we get the underlying filepath 
                # because File::Copy does not move or copy to non file handle.
                if( $self->_is_object( $dest ) && $dest->isa( 'IO::Dir' ) )
                {
                    # Would not it be nice if IO:Dir had a public method to get the 
                    # directory name that was opened?
                    $dest = ${*$dest}{io_dir_path} if( ${*$dest}{io_dir_path} );
                }
                # If $dest is a reference or an object, File::Copy will trigger its 
                # own error which we will catch
            
                my( $vol, $path, $name ) = $self->_spec_splitpath( "$dest" );
                $new_path = $dest = $self->_spec_catpath( $vol, $self->_spec_catdir( [ $path, $name ] ), $base );
                return( $self->error( "There already exists a ", ( -d( $dest ) ? 'directory' : 'file' ), " \"${dest}\"." ) ) if( -e( $dest ) && ( !$opts->{overwrite} || !-d( $dest ) ) );
            }
            elsif( -e( $dest ) && !-d( $dest ) )
            {
                return( $self->error( "There is already a file at \"${dest}\". Cannot overwrite a file with a directory." ) );
            }
            # other cases are ok.
        }
        # We are a file
        else
        {
            # And the destination exists and is a file too
            if( -e( $dest ) && !-d( $dest ) && !$opts->{overwrite} )
            {
                return( $self->error( "Unable to copy file \"${file}\" to \"${dest}\". A file with the same name exists and the option \"overwrite\" is not enabled." ) );
            }
        }

        my $code;
        # try-catch
        local $@;
        eval
        {
            $code = File::Copy->can( $what );
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error occurred while trying to $what file \"${file}\" to \"${dest}\": $@" ) );
        }
        $code or return( $self->error( "Super weird. Could not find method '$what' in File::Copy!" ) );
    
        $code->( $file, $dest ) || 
            return( $self->error( "Unable to $what file \"${file}\" to \"${dest}\": $!" ) );
    }

    # If the destination was a directory, we formulate the new file path.
    # It would have been nice if File::Copy::move returned the new file path
    # Note that we do so even if the destination directory does not exist.
    # It would then be only virtual
    if( -d( "$dest" ) || ( $dest->isa( 'Module::Generic::File' ) && $dest->is_dir ) )
    {
        # No need to recompute it
        if( defined( $new_path ) )
        {
            $dest = $new_path;
        }
        else
        {
            my $base;
            if( $self->_is_object( $dest ) && $self->_is_a( $dest => 'Module::Generic::File' ) )
            {
                # NOTE: Maybe use child() method instead?
                $base = $self->basename;
                my( $vol, $path, $fname ) = $self->_spec_splitpath( $dest->filepath );
                $dest = $self->_spec_catpath( $vol, $self->_spec_catdir( [ $path, $fname ] ), $base );
            }
            # A regular string or an overloaded object
            elsif( !ref( $dest ) || overload::Method( $dest, '""' ) )
            {
                # We get the directory portion of the path.
                $base = $self->basename;
                my( $vol, $path, $fname ) = $self->_spec_splitpath( "$dest" );
                $dest = $self->_spec_catpath( $vol, $self->_spec_catdir( [ $path, $fname ] ), $base );
            }
            # No clue what to do with this
            else
            {
                return( $self->error( "For the dstination, I was expecting a string or a directory handle, but instead I got '$dest'." ) );
            }
        }
    }
    # Destination provided was a glob, since we cannot get the file path out of the glob
    # we return it as is, unless we can such as in File::Temp who has the 'filename' method
    # If the destination provided was a IO::Dir directory handle, it will have been turned 
    # into a directory path earlier on.
    elsif( ( Scalar::Util::reftype( $dest ) // '' ) eq 'GLOB' )
    {
        if( $self->_is_object( $dest ) && $dest->can( 'filename' ) )
        {
            $dest = $dest->filename;
        }
        # There is nothing we can do with it, so we just return it as is
        else
        {
            return( $dest );
        }
    }
    # Make a new file object and return it
    return( $self->new( $dest, base_file => $self, debug => $self->debug ) );
}

sub _os2sep
{
    my $self = shift( @_ );
    return( $OS2SEP->{lc( $self->{os} || $^O )} );
}

sub _prev_cwd { return( shift->_set_get_scalar( '_prev_cwd', @_ ) ); }

sub _spec_abs2rel
{
    my $self = shift( @_ );
    my( $args, $os ) = @_;
    my $class = $self->_spec_class( $os );
    return( $class->abs2rel( @$args ) );
}

sub _spec_canonpath
{
    my $self = shift( @_ );
    my( $path, $os ) = @_;
    my $class = $self->_spec_class( $os );
    return( $class->canonpath( $path ) );
}

sub _spec_catdir
{
    my $self = shift( @_ );
    my( $dirs, $os ) = @_;
    my $class = $self->_spec_class( $os );
    return( $class->catdir( @$dirs ) );
}

sub _spec_catfile
{
    my $self = shift( @_ );
    my( $frags, $os ) = @_;
    my $class = $self->_spec_class( $os );
    return( $class->catfile( @$frags ) );
}

sub _spec_catpath
{
    my $self = shift( @_ );
    my( $volume, $directory, $file, $os ) = @_;
    my $class = $self->_spec_class( $os );
    return( $class->catpath( $volume, $directory, ( $file // '' ) ) );
}

sub _spec_class
{
    my $self = shift( @_ );
    my $os = shift( @_ );
    # _spec_class object property would have been set upon object instantiation
    # but if $os is specified, or _spec_class is not set yet, we go on
    return( $self->{_spec_class} ) if( Scalar::Util::blessed( $self ) && $self->{_spec_class} && !defined( $os ) );
    $os = $^O if( !defined( $os ) );
    my $os_map = 
    {
    amiga   => 'AmigaOS',
    amigaos => 'AmigaOS',
    cygwin  => 'Cygwin',
    dos     => 'OS2',
    freebsd => 'Unix',
    linux   => 'Unix',
    mac     => 'Mac',
    macos   => 'Mac',
    msdos   => 'OS2',
    mswin32 => 'Win32',
    netware => 'Win32',
    os2     => 'OS2',
    symbian => 'Win32',
    vms     => 'VMS',
    win32   => 'Win32',
    };
    # Slightly different than what File::Spec does, because the os provided is provided
    # potentially by a user
    my $module = $os_map->{lc( $os )} || 'Unix';

    $self->_load_class( "File::Spec::$module" ) || return( $self->pass_error );
    return( "File::Spec::$module" );
}

sub _spec_curdir
{
    my $self = shift( @_ );
    my $os = shift( @_ );
    my $class = $self->_spec_class( $os );
    return( $class->curdir );
}

sub _spec_file_name_is_absolute
{
    my $self = shift( @_ );
    my( $path, $os ) = @_;
    my $class = $self->_spec_class( $os );
    return( $class->file_name_is_absolute( $path ) );
}

sub _spec_rel2abs
{
    my $self = shift( @_ );
    my( $args, $os ) = @_;
    my $class = $self->_spec_class( $os );
    return( $class->rel2abs( @$args ) );
}

sub _spec_rootdir
{
    my $self = shift( @_ );
    my $os = shift( @_ );
    my $class = $self->_spec_class( $os );
    return( $class->rootdir );
}

sub _spec_splitdir
{
    my $self = shift( @_ );
    my( $file, $os ) = @_;
    my $class = $self->_spec_class( $os );
    return( $class->splitdir( $file ) );
}

sub _spec_splitpath
{
    my $self = shift( @_ );
    my( $file, $os ) = @_;
    my $class = $self->_spec_class( $os );
    return( $class->splitpath( $file ) );
}

sub _spec_tmpdir
{
    my $self = shift( @_ );
    my $os = shift( @_ );
    my $class = $self->_spec_class( $os );
    return( $class->tmpdir );
}

sub _spec_updir
{
    my $self = shift( @_ );
    my $os = shift( @_ );
    my $class = $self->_spec_class( $os );
    return( $class->updir );
}

sub _standard_io
{
    my $self = shift( @_ );
    my $what = shift( @_ ) ||
        return( $self->error( "No standard io name was provided." ) );
    $what = lc( $what );
    my $opts = $self->_get_args_as_hash( @_ );
    my $map =
    {
    'stdin' => { 'fileno' => CORE::fileno( STDIN ), mode => 'r' },
    'stdout' => { 'fileno' => CORE::fileno( STDOUT ), mode => 'w' },
    'stderr' => { 'fileno' => CORE::fileno( STDERR ), mode => 'w' },
    };
    return( $self->error( "\L$what\E is not a standard io." ) ) if( !CORE::exists( $map->{ $what } ) );
    my $def = $map->{ $what };
    my $io = IO::File->new;
    $io->fdopen( @$def{qw( fileno mode )} ) || 
        return( $self->error( "Unable to fdopen io \U${what}\E with fileno ", $def->{fileno}, " and option '", $def->{mode}, "': $!" ) );
    
    if( CORE::exists( $opts->{binmode} ) )
    {
        if( !defined( $opts->{binmode} ) || !CORE::length( $opts->{binmode} ) )
        {
            $io->binmode || return( $self->error( "Unable to set binmode to binary for io \U$what\E: $!" ) );
        }
        else
        {
            $opts->{binmode} = 'encoding(utf-8)' if( lc( $opts->{binmode} ) eq 'utf-8' );
            $opts->{binmode} =~ s/^\://g;
            $io->binmode( ":$opts->{binmode}" ) || return( $self->error( "Unable to set binmode to \"$opts->{binmode}\" for io \U$what\E: $!" ) );
        }
    }
    $io->autoflush( $opts->{autoflush} ) if( CORE::exists( $opts->{autoflush} ) && CORE::length( $opts->{autoflush} ) );
    return( $io );
}

sub _uri_file_abs
{
    my $self = shift( @_ );
    my( $path, $base ) = @_;
    # Maybe better?
    # return( URI::file->new( $path )->abs( URI::file->new( $base ) )->file( $self->{os} ) );
    # URI->new expressly removes leading and trailing space, and URI::file calls URI->new
    # So, we need to create an instance and replace the modified path with the original one, i.e. the one with some leading and/or trailing spaces
    if( $path =~ /^[[:blank:]\h]+/ || $path =~ /[[:blank:]\h]+$/ )
    {
        my $u = URI::file->new( $path );
        $u->path( $path );
        return( $u->abs( $base )->file( $self->{os} ) );
    }
    else
    {
        return( URI::file->new( $path )->abs( $base )->file( $self->{os} ) );
    }
}

sub _uri_file_class
{
    my $self = shift( @_ );
    my $os = shift( @_ );
    # _uri_file_class object property would have been set upon object instantiation
    # but if $os is specified, or _uri_file_class is not set yet, we go on
    return( $self->{_uri_file_class} ) if( $self->{_uri_file_class} && !defined( $os ) );
    $os = $^O if( !defined( $os ) );
    my $os_map =
    {
    dos     => 'FAT',
    freebsd => 'Unix',
    linux   => 'Unix',
    mac     => 'Mac',
    macos   => 'Mac',
    msdos   => 'FAT',
    mswin32 => 'Win32',
    os2     => 'OS2',
    qnx     => 'QNX',
    win32   => 'Win32',
    };
    # Slightly different than what File::Spec does, because the os provided is provided
    # potentially by a user
    my $module = $os_map->{lc( $os )} || 'Unix';

    $self->_load_class( "URI::file::$module" ) || return( $self->pass_error );
    return( "URI::file::$module" );
}

sub _uri_file_cwd
{
    my $self = shift( @_ );
    # This is optional and may be undefined
    my $os   = shift( @_ );
    my $cwd  = URI::file->cwd || return( '' );
    return( URI->new( $cwd )->file( $os || $self->{os} || $^O ) );
}

sub _uri_file_new
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    # This is optional and may be undefined
    my $os   = shift( @_ );
    return( $self->_uri_file_class->new( $file )->file( $os || $self->{os} || $^O ) );
}

sub _uri_file_os_map
{
    my $self = shift( @_ );
    my $os = shift( @_ ) || return;
    my $os_map =
    {
    dos     => 'dos',
    freebsd => 'Unix',
    linux   => 'Unix',
    mac     => 'mac',
    macos   => 'MacOS',
    msdos   => 'msdos',
    mswin32 => 'MSWin32',
    os2     => 'os2',
    qnx     => 'qnx',
    unix    => 'Unix',
    win32   => 'win32',
    };
    return( $os_map->{lc( $os )} );
}

sub DESTROY
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    no warnings 'uninitialized';
    # Revert back to the directory we were before there was a chdir, if any
    # This way, we avoid making change of directory permanent throughout our entire
    # program, even after our object has died
    if( my $prev_cwd = $self->_prev_cwd )
    {
        CORE::chdir( $prev_cwd );
    }
    
    # Could use also O_TEMPORARY provided by Fcntl to instruct the system to automatically
    # remove the file, but it is not supported on all platforms.
    my $orig = $self->{_orig};
    if( $self->auto_remove )
    {
        return unless( CORE::exists( $FILES_TO_REMOVE->{ $$ }->{ $file } ) );
        CORE::delete( $FILES_TO_REMOVE->{ $$ }->{ $file } );
        my @info = caller();
        my $sub = [caller(1)]->[3];
        return unless( -e( $file ) );
        if( $self->is_dir )
        {
            $self->rmtree;
        }
        else
        {
            $self->delete;
        }
    }
    else
    {
        my @info = caller();
#         $self->debug(3);
    }
};

# NOTE: END
END
{
    # Need to be done last, so we can ensure they are empty before they are removed
    my @dirs_to_remove = ();
    # We use File::Spec to get the current directory rather than our cwd() method, 
    # because we do not want to create a new object in a destruction block
    my $cwd = File::Spec->rel2abs(File::Spec->curdir);
    foreach my $pid ( keys( %$FILES_TO_REMOVE ) )
    {
        next if( $pid ne $$ );
        foreach my $file ( keys( %{$FILES_TO_REMOVE->{ $$ }} ) )
        {
            next if( !$file || !-e( $file ) );
            if( -d( $file ) )
            {
                push( @dirs_to_remove, $file );
                next;
            }
            CORE::unlink( $file );
        }
        foreach my $dir ( @dirs_to_remove )
        {
            if( $cwd eq $dir )
            {
                my $updir = Cwd::abs_path( File::Spec->updir );
                warnings::warn( "You currently are inside a directory to remove ($dir), moving you up to $updir\n" ) if( warnings::enabled() );
                CORE::chdir( $updir ) || do
                {
                    warnings::warn( "Unable to move to directory '$updir' above current directory: $!\n" ) if( warnings::enabled() );
                    next;
                };
            }
            CORE::rmdir( $dir ) || do
            {
                warnings::warn( "Unable to remove directory $dir: $!\n" ) if( warnings::enabled() );
            };
        }
    }
};

# NOTE: For CBOR and Sereal
sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    CORE::delete( @hash{ qw( opened _handle ) } );
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
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
}

sub TO_JSON { return( shift->filepath ); }

# NOTE: IO::File class modification
{
    package
        IO::File;
    
    sub flock { CORE::flock( shift( @_ ), shift( @_ ) ); }
}

# NOTE: Module::Generic::File::Map class
{
    package
        Module::Generic::File::Map;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Tie::Scalar );
    };
    
    sub TIESCALAR
    {
        my $this = shift( @_ );
        my $class = ref( $this ) || $this;
        my $opts = shift( @_ );
        if( ref( $opts ) ne 'HASH' )
        {
            warn( "I was expecting an hash reference of options, but got instead '$opts'\n" );
            return;
        }

        my( $io, $file );
        if( !( $io = $opts->{fh} ) )
        {
            warn( "No file handle provided\n" );
            return;
        }
        if( !( $file = $opts->{file} ) )
        {
            warn( "No file path was provided.\n" );
            return;
        }
        no strict 'refs';
        my $ref = \$file;
        ${$$ref} = $opts;
        return( bless( $ref => $class ) );
    }
    
    sub FETCH
    {
        my $self = shift( @_ );
        no strict 'refs';
        my $fh;
        if( !( $fh = ${$$self}->{fh} ) )
        {
            warn( "Filehandle is gone!\n" );
            return;
        }
        my $parent  = ${$$self}->{me};
        my $data    = $parent->load;
        # Initial variable length, if any, because initially the file may be padded with nulls
        # and we do not want them. We could use unpack( 'A*', $data );, but the variable data
        # itself could have some nulls too, so we cannot rely on this.
        my $var_len = ${$$self}->{length} // 0;
        # $data =~ s/\0+$//gs;
        # $data = unpack( 'A*', $data );
        return( substr( $data, 0, $var_len ) ) if( $var_len );
        #$data = unpack( 'Z*', $data );
        $data =~ s/\0+$//g;
        return( $data );
    }
    
    sub STORE
    {
        my $self = shift( @_ );
        no strict 'refs';
        my $fh;
        if( !( $fh = ${$$self}->{fh} ) )
        {
            warn( "Filehandle is gone!\n" );
            return;
        }
        my $size   = ${$$self}->{size};
        my $parent = ${$$self}->{me};
        unless( $fh->opened )
        {
            warn( "filehandle is not opened for file \"", $parent->filename, "\".\n" );
        }
        $parent->lock( shared => 1 );
        $fh->seek(0,0) || do
        {
            warn( "Unable to set position at beginning in file \"", $parent->filename, "\": $!\n" );
            # return;
        };
        # This needs to be print and not syswrite, because we cannot mix syswrite and read/print
        if( !$fh->print( $_[0] ) )
        {
            warn( "Unable to write ", CORE::length( $_[0] // '' ), " byte(s) to file \"", $parent->filename, "\": $!\n" );
            return;
        }
        $parent->unlock;
        $fh->sync;
        $fh->flush;
        # $fh->print( "\000" x ( $size - length( $_[0] ) ) );
        if( !CORE::defined( $fh->truncate( $fh->tell ) ) )
        {
            warn( "Unable to truncate file \"", $parent->filename, "\": $!\n" );
            return;
        };
        CORE::delete( ${$$self}->{length} );
    }
    
    sub DESTROY
    {
        my $self = shift( @_ );
        undef( $self );
    }
    
    sub message
    {
        my $self = shift( @_ );
        no strict 'refs';
        my $parent = ${$$self}->{me};
        return( $parent->message( @_ ) );
    }
#     sub message
#     {
#         my $self = shift( @_ );
#         my $parent = ${$$self}->{me};
#         return if( !scalar( @_ ) );
#         return if( $_[0] =~ /^\d+$/ && $_[0] >= $parent->debug );
#         shift( @_ );
#         $txt = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : ( $_ // '' ), @_ ) );
#         my( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
#         my $sub = ( caller( $stackFrame + 1 ) )[3] // '';
#         my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
#         my $mesg_raw = "${pkg}::${sub2}( $self ) [$line]: " . $txt;
#         $mesg_raw    =~ s/\n$//gs;
#         my $prefix = '##';
#         my $mesg = "${prefix} " . join( "\n${prefix} ", split( /\n/, $mesg_raw ) );
#         print( STDERR $mesg, "\n" );
#     }
}

1;

# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::File - File Object Abstraction Class

=head1 SYNOPSIS

    use Module::Generic::File qw( cwd file rootdir tempfile tempdir sys_tmpdir stdin stderr stdout );
    my $f = Module::Generic::File->new( '/some/file' );
    $f->append( "some data" );
    $f->open && $f->write( "some data" );
    my $d = file( "/my/directory/somewhere" );
    $d->makepath;
    $d->chdir;
    $d->contains( $f );
    my $d = file( $tmpdir )->mkpath->first;
    $f->is_part_of( $d );
    $f->touchpath;
    my $f = $d->child( "file.txt" )->touch;
    $f->code == 201 && say "Created!";
    say "File is empty" if( $f->is_empty );
    
    my $file = tempfile();
    my $dir  = tempdir();
    
    my $tmpname = $f->tmpname( suffix => '.txt' );
    my $f2 = $f->abs( $tmpname );
    my $sys_tmpdir = $f->sys_tmpdir;
    my $f3 = $f2->move( $sys_tmpdir )->touch;
    my $io = $f->open;
    say "Can read" if( $f->can_read );
    say "Can write" if( $f->can_write );
    say "Can execute" if( $f->can_exec );
    $f->close if( $f->opened );
    say "File is ", $f->length, " bytes big.";
    
    my $f = tempfile({ suffix => '.txt', auto_remove => 0 })->move( sys_tmpdir() );
    $f->open( '+>', { binmode => 'utf8' } );
    $f->seek(0,0);
    $f->truncate($f->tell);
    $f->append( <<EOT );
    Mignonne, allons voir si la rose
    Qui ce matin avoit desclose
    Sa robe de pourpre au Soleil,
    A point perdu cette vesprée
    Les plis de sa robe pourprée,
    Et son teint au vostre pareil.
    EOT
    my $digest = $f->digest( 'sha256' );
    $f->close;
    say $f->extension->length; # 3
    # Enable cleanup, auto removing temporary file during perl cleanup phase

    $file->utime( time(), time() );
    # or to set the access and modification time to current time:
    $file->utime;

    # Create a file object in a different OS than yours
    my $f = file( q{C:\Documents\Some\File.pdf}, os => 'Win32' );
    $f->parent; # C:\Documents\Some
    $f->filnema; # C:\Documents\Some\File.pdf

    # Get URI:
    my $u = $f->uri;
    say $u; # file:///Documents/Some/File.pdf

    # Enable globbing globally for all future objects:
    $Module::Generic::File::GLOBBING = 1;
    # or by object:
    my $f = file( "~john/some/where/file.txt", { globbing => 1 } );

    my $d = file( './some/where' );
    my @files = $d->glob( '*.pl' );
    die( "Something went wrong: ", $d->error ) if( !@files && $d->error );
    my $last_file = $d->glob( '*.pl' ) ||
    die( "Something went wrong: ", $d->error ) if( !defined( $last_file ) );
    my @all = $d->glob( '*.pl', {
        brace => 1,
        expand => 1,
        no_case => 1,
        no_magic => 1,
        sort => 1,
    });
    $d->open || die( $d->error );
    my @files = $d->read;

    my $data = $file->load_perl || die( $file->error );
    $file->unload_perl( $data, { indent => 4, max_binary_size => 1024, max_width => 60 } ) ||
        die( $file->error );

    $file->flock(1) || die( $file->error );
    my $new_object = $file->realpath;
    my $new_object = Module::Generic::File->realpath( "/some/where/file.txt" );

=head1 VERSION

    v0.8.1

=head1 DESCRIPTION

This packages provides a comprehensive and versatile set of methods and functions to manipulate files and directories. You can even manipulate filenames as if under a different OS, by providing the C<os> parameter.

=head1 METHODS

=head2 new

Takes a file as its first parameter, whether the file actually exists or not is ok.
This will instantiate an object that is used to access other key methods. It takes the following optional parameters:

=over 4

=item I<autoflush>

Enables or disables autoflush. Takes a boolean value and defaults to true.

=item I<auto_remove>

Takes a boolean value. Automatically removes the temporary directory or file when the objects is cleaned up by perl.

=item I<base_dir>

Sets the base directory for this file. If none is provided, it will attempt to get the current working directory, and if it cannot find it, most likely because it has been removed while your perl script was running, then it will try to C<chdir> to the system temporary directory, and if that, too, fails, it will set an L<error|Module::Generic/error> return C<undef>

=item I<base_file>

Sets the base file for this file, i.e. the reference file frm which the base directory will be derived, if not already specified.

=item I<collapse>

Enables or disables the collapsing of dots in the file path.

This will attempt to resolve and remove the dots to provide an absolute file path without dots. For example:

C</../a/b/../c/./d.html> would become C</a/c/d.html>

=item I<globbing>

Boolean value, by default set to the value of the package variable C<$GLOBBING>, which itself is false by default.

If enabled, this will allow L</resolve> to do globbing on the filename, so that any shell meta characters are resolved. For example C<~joe/some/file.txt> would be resolved to C</home/joe/some/file.txt>

Otherwise the filename would remain C<~joe/some/file.txt>

This is useful when you have filename with meta characters in their file path, like C</some/where/A [A-12] file.pdf>

See also L</globbing> to change the parameter for the current object, and also the L</glob> and L</resolve>

=item I<max_recursion>

Sets the maximum recursion allowed. Defaults to 12.

Its value is used in L</mkpath> and L</resolve>

=item I<os>

If provided, this will tell L<Module::Generic::File> to treat this new file as belonging to the specified operating system. This makes it possible to manipulate files or directories as if under a different system than the one you are currently using.

Look also at L</as> to change a file to make it suitable for a different OS, such as C<Mac>, C<Win32>, C<dos>, C<Linux>, etc.

=item I<resolved>

A boolean flag which states whether this file has been resolved already or not.

=item I<type>

The type of file this is. Either a file or a directory.

=back

=head2 abs

If no argument is provided, this return the current object, since the underlying file is already changed into absolute file path.

If a file path is provided, then it will change it into an absolute one and return a new L<Module::Generic::File> object.

=head2 absolute

This is a convenient alias to L</abs>

=head2 append

Provided with some data as its first argument, and assuming the underlying file is a file and not a directory, this will open it if it is not already opened and append the data provided.

If the file was already opened, whatever position you were in the file, will be restored after having appended the data.

It returns the curent file object upon success for chaining or undef and sets an error object if an error occurred.

=head2 as

Provided with an C<OS> name, and this will return a filename with a format suitable for that operating system, notwithstanding the one you are currently using.

=head2 atime

This is a shortcut to L<Module::Generic::Finfo/atime>

=head2 auto_remove

This takes a boolean value and enables or disables the auto remove of temporary file or directory created by this module upon perl cleanup phase.

=head2 autoflush

This takes a boolean value and enables or disables the auto flush.

=head2 base_dir

This sets the base directory of reference for this file object.

=head2 base_file

This sets the base file of reference for this file object.

=head2 baseinfo

This returns a list containing:

=over 4

=item 1. the file base name

=item 2. the file directory path

=item 3. the file suffix if the file is a file or an empty string if this is a directory

=back

In scalar context, it returns the file base name as a L<Module::Generic::Scalar> object.

This method accepts as an optional parameter a list or an array reference of possible extensions.

=head2 basename

This returns the file base name as a L<Module::Generic::Scalar> object.

You can provide optionally a list or array reference of possible extensions or regular expressions.

    my $f = Module::Generic::File->new( "/some/where/my/file.txt" );
    my $base = $f->basename( [qw( .zip .txt .pl )] ); # returns "file"
    my $base = $f->basename( qr/\.(.*?)$/ ); # returns "file"

=head2 binmode

Sets or get the file binmode.

=head2 block_size

This is a shortcut to L<Module::Generic::Finfo/block_size>

=head2 blocking

Turns on or off blocking or non-blocking io for file opened.

=head2 blocks

This is a shortcut to L<Module::Generic::Finfo/blocks>

=head2 can_append

Returns true if the file or directory are writable, and data can be added to it. False otherwise.

If an error occurred, undef will be returned an an exception will be set.

=head2 can_exec

This is an alias for L<Module::Generic::Finfo/can_exec>

=head2 can_read

Returns true if the file or directory are readable. False otherwise.

If an error occurred, undef will be returned an an exception will be set.

=head2 can_write

Returns true if the file or directory are writable. False otherwise.

If an error occurred, undef will be returned an an exception will be set.

=head2 canonpath

Takes an optional parameter representing the name of the operating system for which to canonise this file path. If no operating system name is provided, this will revert to C<$^O>. See L<perlvar> for more information about this variable.

Returns the canon path of the file object based on the operating system specified.

=head2 changed

Returns true if the file was changed, false otherwise.

=head2 chdir

If the file object is a directory, this will attempt to L<perlfunc/chdir> to it.

It returns the current file object upon success, or undef and sets an exception object if an error occurred.

=head2 child

This should be called using a directory object.

Provided with a file name (not a full path), and this will return a new file object based on the combination of the directory path and the file specified.

=head2 chmod

Provided with an octal value or a human file mode such as C<a+rw> and this will attempt to set the file or directory mode accordingly.

It returns the current object upon success or undef and sets an exception object upon error.

=head2 chown

Provided with an C<uid> and a C<gid> and this will call L<perlfunc/chown> on the underlying directory or file.

Both C<uid> and C<gid> must be provided, but you can provide a value of C<-1> to tell perl you do not want to change the value.

It returns true if the file or directory was changed, or o otherwise.

If an error occurred, it sets an L<error|Module::Generic/error> and return C<undef>

See L<perlport> for C<chown> portability limitations.

=head2 cleanup

This is an alias for L</auto_remove>. It enables or disables the auto cleanup of temporary file or directory upon perl cleanup phase.

    $tmp->cleanup(1); # Enable it
    my $bool = $tmp->cleanup;

=head2 close

Close the underlying file or directory.

=head2 code

Sets or gets the http-equivalent 3-digits code describing the status of the underlying directory or file.

If a value is provided, it will set the code, but if no value is provided it will guess the code based on the file readability, existence, etc.

=head2 collapse_dots

In line with section 5.2.4 of the rfc 33986, this will flaten (i.e. remove) any dots there may be in the element file path.

It takes an optional list or hash reference of parameters, including I<separator> which is used a directory separator. If not provided, it will revert to the default value for the current system.

=head2 contains

This can only be called using a directory object and is provided with a file or file object.

It returns true if the file is contained within the directory.

=head2 content

This method returns the content of the directory or file as a L<Module::Generic::Array>

If this is a directory, it returns an L<Module::Generic::Array> object with all the files within that directory, but excluding C<.> and C<..> and only within that directory, so this is not recurring.

If this is a regular file, it returns its content as an L<Module::Generic::Array> object.

If an error occurred, it returns undef and set an exception object.

=head2 content_objects

This methods works exclusively on directory object, and will return C<undef> and set an L<error|Module::Generic/error> if you attempt to use it on anything else but a directory object.

It returns an L<array object|Module::Generic::Array> of L<file objects|Module::Generic::File>. Do not use this on directory containing very large number of items for obvious reasons.

=head2 copy

Takes a dstination, and attempt to copy itself to the destination.

If the object represents a directory and the destination exists and is also a directory, it will copy the directory below the destination.

    my $d = Module::Generic::File->new( "my/other_directory" );
    my $new = $d->copy( "./another/directory" );
    # $new now represents ./another/directory/other_directory

Of course if the destination is a regular file, undef is returned and an exception is set.

If the object represents a file and the destination exists, it will copy the file under the target directory if if the destination is a directory or replace the target regular file if the destination is a regular file.

If the object file/directory does not actually exist, this merely changes virtually its file path.

This method, just like L</move> relies on L<File::Copy>, which means you can use a C<GLOB> as the destination if you want. See L<File::Copy> documentation for more details on this.

It returns a new L<Module::Generic::File> object representing the new file path.

Note that you can also use the shortcut C<cp> instead of C<copy>

=head2 cp

Shorthand for L</copy>

=head2 checksum_md5

This uses L<Crypt::Digest::MD5> to perform a md5 checksum as an hex value and returns it.

It requires this module L<Crypt::Digest::MD5> to be installed, and also the file to be a plain text file and not a directory, otherwise this sets an L<error|Module::Generic/error> and return C<undef>

On success, this returns a md5 hex digest of the underlying file.

=head2 checksum_sha256

This uses L<Crypt::Digest::SHA256> to perform a sha256 checksum as an hex value and returns it.

It requires this module L<Crypt::Digest::SHA256> to be installed, and also the file to be a plain text file and not a directory, otherwise this sets an L<error|Module::Generic/error> and return C<undef>

On success, this returns a md5 hex digest of the underlying file.

=head2 checksum_sha512

This uses L<Crypt::Digest::SHA512> to perform a sha512 checksum as an hex value and returns it.

It requires this module L<Crypt::Digest::SHA512> to be installed, and also the file to be a plain text file and not a directory, otherwise this sets an L<error|Module::Generic/error> and return C<undef>

On success, this returns a md5 hex digest of the underlying file.

=head2 ctime

This is a shortcut to L<Module::Generic::Finfo/ctime>

=head2 cwd

Returns a new L<Module::Generic::File> object representing the current working directory.

=head2 delete

This will attempt to remove the underlying directory or file and returns the current object upon success or undef and set the exception object if an error occurred.

=head2 device

This is a shortcut to L<Module::Generic::Finfo/device>

=head2 digest

This takes a given algorithm and returns its cryptographic digest upon success or undef and sets an error object if an error occurred.

This method can only be used if you have installed the module L<Digest>

The supported algorithms the same ones mentionned on the documentation for L<Digest>, which are, for example: C<MD5>, C<SHA-1>, C<SHA-256>, C<SHA-384>, C<SHA-512>

It does not actually matter the case or whether there is or not an hyphen, so, for example, you could very well use C<sha256> instead of C<SHA-256>

=head2 dirname

Returns the current element parent directory as an object.

=head2 empty

This will remove the element's content.

If the element is a directory, it will remove all element within using L</rmtree> and if the element is a regular file, it will empty its content by truncating it if it is already opened, or by opening it in write mode and immediately close it.

It returns the current object upon success or undef and sets an exception object if an error occurred.

=head2 eof

Returns true when the end of file is reached, false otherwise.

=head2 exists

Returns true if the underlying directory or file exists, false otherwise.

This uses L<Module::Generic::Finfo/exists>

=head2 extension

If an argument is provided, and is undefined or zero byte in length, this will remove the extension characterised with the following pattern C<qr/\.(\w+)$/>. otherwise, if a non-empty value was provided, it will substitute any previous value for the new one and return a new L<Module::Generic::File> object.

If no argument is provided, this simply returns the current file extension as a L<Module::Generic::Scalar> object if it is a regular file, or an empty string if it is a directory.

Extension is simply defined with the regular expression C<\.(\w+)$>

    my $f = file( "/some/where/file.txt" );
    my $new = $f->extension( 'pl' ); # /some/where/file.pl
    my $new = $f->extension( undef() ); # /some/where/file

Keep in mind that changing the extension of the file object does not actually alter the file on the filesystem, if any. For that you need to do something like:

    my $f2 = $f->extension( 'png' );
    $f->move( $f2 ) || die( $f->error );

Now C</some/where/file.txt> has been moved to C</some/where/file.png> on the filesystem.

=head2 extensions

In retrieval mode, this returns all extensions found as an L<array object|Module::Generic::Array>.

Because the notion of "extension" is very fluid, this treats as extension anything that follows the initial dot in a filename. For example:

    my $f = Module::Generic::File->new( '/some/where/file.txt' );
    my $exts = $f->extensions;

C<$exts> contains C<txt> only, but:

    my $f = Module::Generic::File->new( '/some/where/file.txt.gz' );
    my $exts = $f->extensions;

C<$exts> now contains C<txt> and C<gz>. And:

    my $f = Module::Generic::File->new( '/some/where/file.unknown.txt.gz' );
    my $exts = $f->extensions;

C<$exts> would contain C<unknown>, C<txt> and C<gz>. However:

    my $f = Module::Generic::File->new( '/some/where/file' );
    my $exts = $f->extensions;

C<$exts> would be an empty L<array object|Module::Generic::Array>.

If this is called on a directory, this returns an empty L<array object|Module::Generic::Array>.

In assignment mode, this takes a string of one or more extensions and change the file object basename accordingly.

For example:

    my $f = Module::Generic::File->new( '/some/where/file.txt' );
    $f->extensions( 'txt.gz' );
    # $f is now /some/where/file.txt.gz

    my $f = Module::Generic::File->new( '/some/where/file.txt.gz' );
    $f->extensions( undef );
    # $f is now /some/where/file

=head2 fcntl

=head2 fdopen

Creates a new L<IO::Handle> object based on the file's file descriptor.

=head2 filehandle

Returns the current file handle for the file/directory object by calling L</handle>

If the file/directory is not opened yet, L</handle> will try to open the element and return the file handle.

=head2 filename

Returns the full absolute file path to the file/directory.

If a parameter is provided, it replaces the previous value.

See also L</filepath> for an alias.

=head2 fileno

Returns the element file descriptor by calling L<perlfunc/fileno>

=head2 filepath

This is an alias for L</filename>

=head2 find

Assuming the current object represents an existing directory, this takes an optional hash or hash reference of options followed by a code reference. This is used as a callback with the module L<File::Find/find>

The callback can also be provided with the I<callback> option.

It returns whatever L<File::Find/find> returns or undef and sets an exception object if an error occurred.

The currently supported options are:

=over 4

=item * C<callback>

A code reference representing the callback called for each element found while crawling directories.

The variable C<$_> representing the current file or directory found, will be made available as a L<Module::Generic::File> object, and will also be passed as the first argument to the callback.

=item * C<method>

The L<File::Find> method to use to perform the search. By default this is C<find>.

Possible values are: C<find> and C<finddepth>

=item * C<skip>

An array reference of files or directories path to skip.

Each of the file or directories path thus provided will be converted into an L<Module::Generic::File> with an absolute file path to avoid unpleasant surprise, since L<File::Find> L<perlfunc/chdir> into each new directory it finds.

=back

Additional L<File::Find> options supported. See L<File::Find> documentation for their description.

=over 4

=item * C<bydepth>

=item * C<dangling_symlinks>

=item * C<follow>

=item * C<follow_fast>

=item * C<follow_skip>

=item * C<no_chdir>

=item * C<postprocess>

=item * C<preprocess>

=item * C<untaint>

=item * C<untaint_pattern>

=item * C<untaint_skip>

=back

=head2 finddepth

Same as L</find>, but using C<finddepth> as the L<File::Find> method instead.

=head2 finfo

Returns the current L<Module::Generic::Finfo> object for the current element.

If a value is provided, it will replace the current L<Module::Generic::Finfo> object.

=head2 flags

Returns the bitwise flags for the current element.

If the element is a directory, it will return 0.

This uses L<perlfunc/fcntl> and C<F_GETFL> from L<Fcntl> to achieve the result.

It returns undef and sets an exception object if an error occurred.

=head2 flatten

This will resolve the file/directory path and remove the possible dots in its path.

It will return a new object, or undef and set an exception object if an error occurred.

=head2 flock

This is a thin wrapper around L<perlfunc/flock> method of the same name.

=head2 flush

This is a thin wrapper around L<IO::Handle> method of the same name.

As described in the L<IO::Handle> documentation, this "causes perl to flush any buffered data at the perlio api level. Any unread data in the buffer will be discarded, and any unwritten data will be written to the underlying file descriptor. Returns C<0 but true> on success, C<undef> on error."

=head2 format_write

This is a thin wrapper around L<IO::Handle> method of the same name.

=head2 fragments

Returns an array object (L<Module::Generic::Array>) of path fragments. For example:

Assuming the file object is: /some/where/in/time.txt

    my $frags = $f->fragments;
    # Returns: ['some', 'where', 'in', 'time.txt'];

=head2 getc

This is a thin wrapper around L<IO::Handle> method of the same name.

This "pushes a character with the given ordinal value back onto the given handle's input stream. Only one character of pushback per handle is guaranteed."

=head2 getline

This is a thin wrapper around L<IO::Handle> method of the same name.

"This works like <$io> described in C<I/O Operators> in perlop except that it's more readable and can be safely called in a list context but still returns just one line. If used as the conditional within a C<while> or C-style C<for> loop, however, you will need to emulate the functionality of <$io> with C<defined($_ = $io->getline)>."

=head2 getlines

This is a thin wrapper around L<IO::Handle> method of the same name.

"This works like <$io> when called in a list context to read all the remaining lines in a file, except that it's more readable. It will also return an error if accidentally called in a scalar context."

=head2 gid

This is a shortcut to L<Module::Generic::Finfo/gid>

=head2 glob

Provided with a pattern with meta characters, or using the current object underlying filename by default, and this will call L<perlfunc/glob> to resolve those meta characters, if any. For example:

C<~joe/some/file.txt> would be resolved to C</home/joe/some/file.txt>

otherwise the filename would remain C<~joe/some/file.txt>

This is useful when you have filename with meta characters in their file path, like:

C</some/where/A [A-12] file.pdf>

It also accepts the following options, but only for operating systems that are not Windows, VMS or RiscOS:

Quoting, for convenience, from L<File::Glob>

=over 4

=item C<brace>

"Pre-process the string to expand "{pat,pat,...}" strings like csh(1).  The pattern '{}' is left unexpanded for historical reasons (and csh(1) does the same thing to ease typing of find(1) patterns)."

=item C<expand>

"Expand patterns that start with '~' to user name home directories."

=item C<no_case>

"By default, file names are assumed to be case sensitive; this flag makes C<glob()> treat case differences as not significant."

=item C<no_magic>

"Only returns the pattern if it does not contain any of the special characters C<*>, C<?> or C<[>." This option "is provided to simplify implementing the historic csh(1) globbing behaviour and should probably not be used anywhere else."

=item C<object>

If this is false, then C<glob> will not turn each of the files found into an L<Module::Generic::File> object, which means the list returned will contain files as a regular string, essentially a pass-through from the results returned by L<File::Glob/bsd_glob>

=item C<sort>

if true, this will "sort filenames is alphabetical order (case does not matter) rather than in ASCII order."

If false, this will not sort files, which speeds up L<File::Glob/bsd_glob>.

This defaults to true.

=back

If the resulting value is empty, which means that nothing was found, it returns an empty string (not C<undef>), otherwise, it returns a new L<Module::Generic::File> object of the resolved file.

This method uses L<File::DosGlob> for windows-related platforms and L<File::Glob> for all other cases to perform globbing.

If the current file object represents a directory, the pattern provided, if any, will be expanded inside that directory.

In list context, it returns a list of all the files expanded, each one as a L<Module::Generic::File> object, and in scalar context, it returns the last file expanded, also as a L<Module::Generic::File> object.

If you call C<glob> in list context, but do not want all the files found to be turned into L<Module::Generic::File> objects, then pass the option C<object> with a false value.

Example:

    use Module::Generic::File qw( file );
    my $d = file( './some/where/' );
    my @files = $d->glob( '*.pl' );
    die( "Something went wrong: ", $d->error ) if( !@files && $d->error );
    my $last_file = $d->glob( '*.pl' ) ||
    die( "Something went wrong: ", $d->error ) if( !defined( $last_file ) );
    my @all = $d->glob( '*.pl', {
        brace => 1,
        expand => 1,
        no_case => 1,
        no_magic => 1,
        sort => 1,
    });
    my $new_file = $file->glob( './some/where/*.pl' );

=head2 globbing

Set or get the boolean value of the current object.

If enabled, globbing will be enabled and this will have the effect of performing L</glob> upon resolving the filename.

Returns the current boolean value.

=head2 gobble

Assuming this is object represents a regular file, this will return its content as a regular string.

If the object represents a directory, it will return undef.

See also L</load>

=head2 gush

This does thd countrary of L</gobble>. It will outpour the data provided into the underlying file element.

This only works on file object and if a directory object is used, this will do nothing and merely return the current object used.

See also L</unload>

=head2 handle

Returns the current file/directory handle if it is already opened, or attempts to open it.

It will return undef and set an exception object if an error occurred.

=head2 has_valid_name

This optionally takes a file name, or default to the underlying object file base name, and checks if it contains any illegal characters.

It returns true if it is clean or false otherwise.

The regular expression used is: C<< [\x5C\/\|\015\012\t\013\*\"\?\<\:\>] >>

=head2 inode

This is a shortcut to L<Module::Generic::Finfo/inode>

=head2 ioctl

This is a thin wrapper around L<IO::Handle> method of the same name.

=head2 is_absolute

Returns true if the element is an absolute path or false otherwise.

=head2 is_dir

Returns true if the element is a directory or false otherwise.

=head2 is_directory

This is an alias for L</is_dir>

=head2 is_empty

Returns true if the element is empty or false otherwise.

If the element is a directory C<empty> means there is no file or directory within.

If the element is a regular file, C<empty> means it is zero byte big.

=head2 is_file

Returns true if the element is regular file or false otherwise.

=head2 is_link

Returns true if the element is symbolic link or false otherwise.

=head2 is_opened

Alias to L</opened>

=head2 is_part_of

Provided with a directory path or a L<Module::Generic::File> object representing a directory and this returns true if the current element is part of the provided directory path, or false otherwise.

It returns undef and set an exception object if an error occurred.

=head2 is_relative

Returns true if the current element path is relative or false otherwise.

=head2 is_rootdir

Returns true if the current element represents the system root directory, such as C</> under Linux system or, for example, C<C:\\> under windows or false otherwise.

=head2 iterator

Assuming the current element is a directory, this method takes a code reference as a callback whicih will be called for every element found inside the directory.

It takes a list or an hash reference of optional parameters:

=over 4

=item I<recurse>

If true, this method will traverse the directories within recursively.

=item I<follow_link>

If true, the symbolic link will be resolved and followed.

=back

The returned value from the callback is ignored.

=head2 join

Takes a list or an array reference of path fragments and this returns a new L<Module::Generic::File> object.

It does not use nor affect the current object used and it can actually be called as a class method. For example:

    my $f = Module::Generic::File->join( qw( this is here.txt ) );
    # Returning a file object for /this/is/here.txt or maybe on Windows C:\\this\is\here.txt
    my $f = Module::Generic::File->join( [qw( this is here.txt )] ); # works too
    my $f2 = $f->join( [qw( new path please )] ); # works using an existing object
    # Returns: /new/path/please

=head2 last_accessed

This is a shortcut to L<Module::Generic::Finfo/atime>

=head2 last_modified

This is a shortcut to L<Module::Generic::Finfo/mtime>

=head2 length

This returns the size of the element as a L<Module::Generic::Number> object.

if the element does not yet exist, L<Module::Generic::Number> object representing the value 0 is returned.

This uses L<Module::Generic::Finfo/size>

=head2 line

Provided with a callback as a subroutine reference or anonymous subroutine, and this will call the callback passing it each line of the file.

If the callback returns C<undef>, this will terminate the browsing of each line, unless the option I<auto_next> is set. See below.

It takes some optional arguments as follow:

=over 4

=item I<chomp> boolean

If true, each line will be L<perlfunc/chomp>'ed before being passed to the callback.

=item I<auto_next> boolean

If true, this will ignore the return value from the callback and will move on to the next line.

=back

=head2 lines

Assuming this is a regular file , this methods returns its content as an array object (L<Module::Generic::Array>) of lines.

If a directory object is called, or the element does not exist or the file element is not readable, this still returns the array object, but empty.

If an error occurred, C<undef> is returned and an exception is set.

This method takes an optional hash or hash reference of parameters, which is passed to the L</open> method when opening the file.

Also the additional following parameters are recognised:

=over 4

=item I<chomp>

    # will perform a regular chomp
    my $array = $f->lines( chomp => 1 );
    # will do a chomp after setting locally $/ to \r\n
    my $array = $f->lines( chomp => 'windows' );
    # will do a chomp (not a regular expression) for both unix and window system types
    my $array = $f->lines( chomp => 'unix|windows' );
    my $array = $f->lines( chomp => qr/[\r]/ );
    my $array = $f->lines({ chomp => 1 });
    my $array = $f->lines({ chomp => windows });
    my $array = $f->lines({ chomp => 'unix|windows' });
    my $array = $f->lines({ chomp => qr/[\r]/ });

This can be either just a string, a true value or a regular expression, for example using L<perlfunc/qr>

If a regular expression is provided, it will be used to weed out end of line carriage returns (multiple times) that will be captured using this regular expression you provide explicitly.

Otherwise, if you merely provide a true value, such as C<1>, then, by default, this will use L<perlfunc/chomp> and remove the trailing new line based on the value of C<$/>.

If the value of I<chomp> is C<windows> or C<macos> (i.e. MacOS v9, the old one) or C<unix>, then this will set a local value of C<$/> to the corresponding line feed and carriage return sequence, typically C<\r\n> for Windows and C<\r> for MacOS and C<\n> for unix and then call L<perlfunc/chomp>. This is very fast, but will remove only the specific sequence. This means if you have a line such as:

    Double whammy\r

But you call L</lines> as:

    my $lines = $f->lines( chomp => 'windows' );

It will not work, because Windows sequence is C<\r\n>, so here you would need to use C<mac> instead.

Also the following line:

    Double whammy\n\n

Then, you are on a Linux system and call:

    my $lines = $f->lines( chomp => 1 );

This will return:

    Double whammy\n

Because L<perlfunc/chomp> only remove one sequence. If you want to remove all occurrences, you need to specify your regular expression.

    my $lines = $f->lines( chomp => qr/[\r\n]/ );

And this will be applied on each line for multiple occurrences, but note that on large file, it will be slow.

Alternatively you can provide more than one os by separating them with a pipe (C<|>), such as:

    my $lines = $f->lines( chomp => 'unix|windows' );

Supported os names are: aix, amigaos, beos, darwin, dos, freebsd, linux, netbsd, openbsd, mac, macos, macosx, mswin32, os390, os400, riscos, solaris, sunos, symbian, unix, vms, windows, and win32

=back

=head2 load

Assuming this element is an existing file, this will load its content and return it as a regular string.

If the C<binmode> used on the file is C<:unix>, then this will call L<perlfunc/read> to load the file content, otherwise it localises the input record separator C<$/> and read the entire content in one go. See L<perlvar/$INPUT_RECORD_SEPARATOR>

If this method is called on a directory object, it will return undef.

=head2 load_json

This will load the file data, which is assumed to be json in utf8, then decode it using L<JSON> and return the resulting perl data.

This requires the L<JSON> module to be installed or it will set an L<error|Module::Generic/error> and return undef.

If an eror occurs during decoding, this will set an L<error|Module::Generic/error> and return undef.

You can provide the following options to change the way C<JSON> will decode the data:

=over 4

=item * C<boolean_values>

See L<JSON/boolean_values>

=item * C<filter_json_object>

See L<JSON/filter_json_object>

=item * C<filter_json_single_key_object>

See L<JSON/filter_json_single_key_object>

=item * C<decode_prefix>

See L<JSON/decode_prefix>

=back

=head2 load_perl

This will load perl's data structure from file using L<perlfunc/do> and return the resulting perl data.

It sets an L<error|Module::Generic/error> and returns C<undef> if an error occurred.

=head2 load_utf8

This does the same as L</load>, but ensure the binmode used is C<:utf8> before proceeding.

=head2 lock

This method locks the file.

It takes either a numeric argument representing the flag bitwise, or a list or hash reference of optional parameters, such as:

=over 4

=item I<exclusive>

This will add the bit of C<Fcntl::LOCK_EX>

=item I<shared>

This will add the bit of C<Fcntl::LOCK_SH>

=item I<non_blocking> or I<nb>

This will add the bit of C<Fcntl::LOCK_NB>

=item I<unlock>

This will add the bit of C<Fcntl::LOCK_UN>

=item I<timeout>

Takes an integer used to set an alarm for the lock. If a lock cannot be obtained before the timeout, an error is returned.

=back

This returns the current object upon success or undef and set an exception object if an error occurred.

=head2 locked

Returns true if the file is locked. More specifically, this returns the value of the flags originally used to lock the file.

=head2 mkdir

Creates the directory represented by the file object. This will fail if the parent directory does not exist, so this does not create a path. For that check L</makepath>

It returns true upon success and C<undef> upon failure. The error, if any, can be retrieved with L<error|Module::Generic/error>

=head2 makepath

This is an alias to L</mkpath>

=head2 max_recursion

Sets or gets the maximum recursion limit.

=head2 mkpath

This takes an optional code reference that is used as a callback.

It will create the path corresponding to the element, or to the list of path fragments provided as optional arguments.

For each path fragments, this will call the callback and provide it with an hash reference containing the following keys:

=over 4

=item I<dir>

The current path fragment as a regular string

=item I<parent>

The current parent full path as a string

=item I<path>

The current full path as a regular string

=item I<volume>

On Windows, this would contain the volume name as a string.

=back

The return value of the callback is ignored and any fatal exception occurring during the callback will be trapped, an error object set, and C<undef> returned.

For example:

    my $f = Module::Generic::File->new( "/my/directory/file.txt" );
    # Assuming the directories in this example do not exist at all
    $f->mkpath(sub
    {
        my $ref = shift( @_ );
        # $ref->{dir} would contain 'my'
        # $ref->{path} would contain '/my'
        # $ref->{parent} would contain '/'
        # $ref->{volume} would be empty
    });

It returns an array object (L<Module::Generic::Array>) of all the path fragments.

If an error occurred, this returns undef and set an exception object.

=head2 mmap

    use Module::Generic::File qw( tempfile );
    my $file = tempfile({ unlink => 1 });
    $file->mmap( my $var, 10240, '+<' );
    # or
    $file->mmap( my $var, 10240 );
    # or; the size will be derived from the size of the variable $var content
    $file->mmap( my $var );
    # then:
    $var = "Hello there";
    $var =~ s/Hello/Good bye/;

With fork:

    use Module::Generic::File qw( tempfile );
    use POSIX ();
    use Storable::Improved ();
    
    my $file = tempfile({ unlink => 1 });
    $file->mmap( my $result, 10240, '+<' );
    # Block signal for fork
    my $sigset = POSIX::SigSet->new( POSIX::SIGINT );
    POSIX::sigprocmask( POSIX::SIG_BLOCK, $sigset ) || 
        die( "Cannot block SIGINT for fork: $!\n" );
    my $pid = fork();
    # Parent
    if( $pid )
    {
        POSIX::sigprocmask( POSIX::SIG_UNBLOCK, $sigset ) || 
            die( "Cannot unblock SIGINT for fork: $!\n" );
        if( kill( 0 => $pid ) || $!{EPERM} )
        {
            # Blocking wait; use POSIX::WNOHANG for non-blocking wait
            waitpid( $pid, 0 );
            print( "Exit value: ", ( $? >> 8 ), "\n" );
            print( "Signal: ", ( $? & 127 ), "\n" );
            print( "Has core dump? ", ( $? & 128 ), "\n" );
        }
        else
        {
            print( "Child $pid already gone\n" );
        }
        my $object = Storable::Improved::thaw( $result );
    }
    elsif( $pid == 0 )
    {
        # Do some work
        my $object = My::Package->new;
        $result = Storable::Improved::freeze( $object );
    }
    else
    {
        if( $! == POSIX::EAGAIN() )
        {
            die( "fork cannot allocate sufficient memory to copy the parent's page tables and allocate a task structure for the child.\n" );
        }
        elsif( $! == POSIX::ENOMEM() )
        {
            die( "fork failed to allocate the necessary kernel structures because memory is tight.\n" );
        }
        else
        {
            die( "Unable to fork a new process: $!\n" );
        }
    }

Provided with some option parameters and this will create a mmap. Mmap are powerful in that they can be used and shared among processes including fork, I<but excluding threads>. Of course, it you want to share objects or other less simple structures, you need to use serialisers like L<Storable::Improved> or L<Sereal>.

If the file is not opened yet, this will open it using the mode specified, or C<+<> by default. If the file is already opened, an error will be returned that the file cannot be opened by C<mmap> because it is already opened.

If your perl version is greater or equal to v5.16.0, then it will use perl native L<PerlIO|PerlIO/:mmap>, otherwise if you have L<File::Map> installed, it will use it as a substitute.

You can force this method to use L<File::Map> by either setting the global package variable C<$MMAP_USE_FILE_MAP> to true, or the object property L</use_file_map> to true.

If L<File::Map> is used, you can call L</unmap> to terminate the tie, but you should not need to do it since L<File::Map> does it automatically for you. This is not necessary if you are using perl's native L<mmap|PerlIO/:mmap>

The options parameters are:

=over 4

=item 1. I<variable>

A variable that will be tied to the file object.

=item 2. I<size>

The maximum size of the variable allocated in the mmap'ed file. If this not provided, then the size will be derived from the size of the variable, or if the variable is not defined or empty, it will use the package global variable C<$DEFAULT_MMAP_SIZE>, which is set to 10Kb (10240 bytes) by default.

For those with a perl version lower than C<5.16.0>, be careful that if you use more than the size allocated, this will raise an error with L<File::Map>. With L<PerlIO> there is no such restriction.

=item 3. I<mode>

The mode in which to mmap open the file. Possible modes are the same as with L<open|perlfunc/open>, however, C<mmap> will not work if you chose a mode like: >, +>, >> or +>>, thus if you want to mmap the file in read only, use < and if you want read-write, use +<. You can also use letters, such as C<r> for read-only and C<r+> for read-write.

The mode can be accompanied by a PerlIO layer like C<:raw>, which is the default, or C<:encoding(utf-8)>, but note that while L<PerlIO> mmap, if your perl version is greater or equal to C<v5.16.0>, will work fine with utf-8, L<File::Map> warns of possibly unknown results when using utf-8 encoder. So if your perl version is equal or greater than C<5.16.0> you are safe, but otherwise, be careful if all works as you expect. Of course, if you use serialisers like L<Storable::Improved> or L<Sereal>, then you should not use an encoding, or at least use C<:raw>, which, again, is the default for L<File::Map>

=back

See also L<BSD documentation for mmap|https://man.openbsd.org/mmap>

=head2 mode

This is a shortcut to L<Module::Generic::Finfo/mode>

=head2 move

This behaves exactly like L</copy> except it moves the element instead of copying it.

Note that you can use C<mv> as a method shortcut instead.

=head2 mtime

This is a shortcut to L<Module::Generic::Finfo/mtime>

=head2 mv

Shorthand for L</move>

=head2 nlink

This is a shortcut to L<Module::Generic::Finfo/nlink>

=head2 open

This takes an optional mode or defaults to E<lt>

Other valid mode can be >, +>, >>, +<, w, w+, r+, a, a+, < and r or an integer representing a bitwise value such as O_APPEND, O_ASYNC, O_CREAT, O_DEFER, O_EXCL, O_NDELAY, O_NONBLOCK, O_SYNC, O_TRUNC, O_RDONLY, O_WRONLY, O_RDWR. For example: C<O_WRONLY|O_APPEND> For that see L<Fcntl>

Provided with an optional list or hash reference of parameters and this will open the underlying element.

Possible options are:

=over 4

=item I<autoflush>

Takes a boolean value

=item I<binmode>

The binmode value, with or without the semi colon before, such as C<utf8> or C<binary>

=item I<lock>

If true, this will set a lock based on the mode in which to open the file.

For example, opening the file in write or append mode, will lead to an exclusive lock while opening the file in read mode will lead to a shared lock.

=item I<truncate>

If true, this will truncate the file after opening it.

=back

=head2 open_bin

This opens the file using binmode value of C<:raw>

=head2 open_utf8

This opens the file using binmode value of C<:utf8>

=head2 opened

Returns the current element file handle if it is opened or a smart null value using L<Module::Generic/new_null>

L<Module::Generic/new_null> will return a sensitive null based on the caller's expectations. Thus if the caller expects an hash reference, L<Module::Generic/new_null> would return an empty hash reference.

=head2 parent

Returns the parent element of the current object.

=head2 print

Calls L<perlfunc/print> on the file handle and pass it whatever arguments is provided.

=head2 printf

Calls L<perlfunc/printf> on the file handle and pass it whatever arguments is provided.

=head2 printflush

This is a thin wrapper around L<IO::Handle> method of the same name.

"Turns on autoflush, print ARGS and then restores the autoflush status of the C<IO::Handle> object. Returns the return value from print."

=head2 println

Calls L<perlfunc/say> on the file handle and pass it whatever arguments is provided.

=head2 rdev

This is a shortcut to L<Module::Generic::Finfo/rdev>

=head2 read

If the element is a directory, this will call L<IO::Dir/read> and return the value received.

If it is called in list context, then this will return an array of all the directory elements, otherwise, this will return one directory element.

If the option C<as_object> is provided and set to a true value, that element will be returned as an L<Module::Generic::File> object.

If this is called in list context and the option C<exclude_invisible> is provided and set to a true value, the array of directory elements returned will exclude any element that starts with a dot.

If the element is a regular file, then it takes the same arguments as L<perlfunc/read>, meaning:

    $io->read( $buff, $size, $offset );
    # or
    $io->read( $buff, $size );
    # or
    $io->read( $buff );

If an error occurred, this returns undef and set an exception object.

=head2 readdir

This is an alias to L</read>, but can only be called on a directory, or it will return an error.

=head2 readlink

This calls L<perlfunc/readlink> and returns a new L<Module::Generic::File> object, but this does nothing and merely return the current object if the current operating system is one of Win32, VMS, RISC OS, or if the underlying file does not actually exist or of course if the element is actually not a symbolic link.

If an error occurred, this returns undef and set an exception object.

=head2 realpath

Provided with a path, or using by default the value returned by L</filename> and this will attempt to load L<Cwd> and use C<Cwd::realpath>

Upon success, it returns a new L<Module::Generic::File> object based on the value returned by C<Cwd::realpath>, and upon error, it sets an error object, and returns C<undef> in scalar context or an empty list in list context.

=head2 relative

Provided a base directory or using L</base_dir> by default and this returns a relative path representation of the current element, as a new L<Module::Generic::File> object.

=head2 rename

This is an alias for L</move>

=head2 remove

This is an alias for L</delete>

=head2 resolve

Provided with a path and a list or hash reference of optional parameters and this will attempt at resolving the file path.

It returns a new L<Module::Generic::File> object or undef and sets an exception object if an error occurred.

The parameter supported are:

=over 4

=item I<glob>

A boolean, which, if true, will use L<perlfunc/glob> to resolve any meta characters.

If glob is turned on and the glob results into an empty string, implying nothing was found, then this will set an L<error|Module::Generic/error> with code C<404> and return C<undef>.

If no I<glob> parameter is provided, this reverts to the I<globbing> property of the object set upon instantiation.

See L</glob> for more information and L</new> for the I<globbing> object property.

=item I<recurse>

If true, this will have resolve perform recursively.

=back

=head2 resolved

Returns true if the file object has been resolved or false otherwise.

=head2 rewind

This will call L<perlfunc/rewind> on the file handle.

=head2 rewinddir

This will call L<IO::Dir/rewinddir> on the directory file handle.

=head2 rmdir

Removes the directory represented by ths object. It silently ignores and return the current object if it is called ona a file object.

If the directory is not empty, this will set an error and return undef.

If all goes well, it returns the value returned by L<perlfunc/rmdir>

=head2 root_dir

This returns an object representation of the system root directory.

=head2 rootdir

This is an alias for L</root_dir>

This is also a class function that can be imported.

=head2 say

This will call L<perlfunc/say> on the file handle.

=head2 seek

This will call L<perlfunc/seek> on the file handle.

=head2 size

Provided with an optional list or hash reference of parameters and this returns the size of the underlying element.

Option parameters are:

=over 4

=item I<follow_link>

If true, links will be followed in calculating the size of a directory. This defaults to false.

=back

Besides the above parameters, you can use the same parameters than the ones used in L<File::Find>, namely: bydepth, dangling_symlinks, follow, follow_fast, follow_skip, no_chdir, postprocess, preprocess, untaint, untaint_pattern and untaint_skip.

For more information see L<File::Find/%options>

This method returns a new L<Module::Generic::Number> object representing the total size, or undef and set an exception object if an error occurred.

=head2 slurp

This is an alias for L</load> It is there, because the name as a method is somewhat popular.

=head2 slurp_utf8

This is an alias for L</load_utf8>

=head2 spew

This is an alias for L</unload>

=head2 spew_utf8

This is an alias for L</unload_utf8>

=head2 split

This does the reverse of L</join> and will return an array object (L<Module::Generic::Array>) representing the path fragments of the underlying object file or directory. For example:

    # $f is /some/where/in/time.txt
    my $frags = $f->split;
    # Returns ['', 'some', 'where', 'in', 'time.txt']

It can take an optional hash or hash reference of parameters. The only one currently supported is I<remove_leading_sep>, which, if true, will skip the first entry of the array:

    my $frags = $f->split( remove_leading_sep => 1 );
    # Returns ['some', 'where', 'in', 'time.txt']

=head2 spurt

This is an alias for L</unload>

=head2 spurt_utf8

This is an alias for L</unload_utf8>

=head2 stat

Returns the value from L</finfo>

=head2 stderr

This returns a filehandle object referencing C<STDERR>. It takes an optional hash or hash reference of following options:

=over 4

=item I<autoflush>

This takes a boolean value. If true, auto flushing will be enabled on this filehandle, otherwise, if false, it will be disabled.

=item I<binmode>

This takes the same value as you would provide to L<perlfunc/binmode>

=back

You can import this function into your namespace, such as:

    use Module::Generic::File qw( stderr );
    my $io = stderr;
    # etc...

Or you can also call it from another C<Module::Generic::File> object:

    use Module::Generic::File qw( file );
    my $f = file( $some_file_name );
    my $err = $f->stderr;

=head2 stdin

This returns a filehandle object referencing C<STDIN>. It takes an optional hash or hash reference of following options:

=over 4

=item I<autoflush>

This takes a boolean value. If true, auto flushing will be enabled on this filehandle, otherwise, if false, it will be disabled.

=item I<binmode>

This takes the same value as you would provide to L<perlfunc/binmode>

=back

You can import this function into your namespace, such as:

    use Module::Generic::File qw( stdin );
    my $io = stdin;
    # etc...

Or you can also call it from another C<Module::Generic::File> object:

    use Module::Generic::File qw( file );
    my $f = file( $some_file_name );
    my $in = $f->stdin;

=head2 stdout

This returns a filehandle object referencing C<STDOUT>. It takes an optional hash or hash reference of following options:

=over 4

=item I<autoflush>

This takes a boolean value. If true, auto flushing will be enabled on this filehandle, otherwise, if false, it will be disabled.

=item I<binmode>

This takes the same value as you would provide to L<perlfunc/binmode>

=back

You can import this function into your namespace, such as:

    use Module::Generic::File qw( stdout );
    my $io = stdout;
    # etc...

Or you can also call it from another C<Module::Generic::File> object:

    use Module::Generic::File qw( file );
    my $f = file( $some_file_name );
    my $out = $f->stdout;

=head2 symlink

Provided with a file path or an L<Module::Generic::File> object, and this will call L<perlfunc/symlink> to create a symbolic link.

On the following operating system not supported by perl, this will merely return the current object itself: Win32 and RISC OS

This returns the current object upon success and undef and sets an exception object if an error occurred.

=head2 sync

This is a thin wrapper around L<IO::Handle> method of the same name.

"L</sync> synchronizes a file's in-memory state  with  that  on the physical medium. L</sync> does not operate at the perlio api level, but operates on the file descriptor (similar to L<perlfunc/sysread>, L<perlfunc/sysseek> and L<perlfunc/systell>). This means that any data held at the L<perlio|PerlIO> api level will not be synchronized. To synchronize data that is buffered at the perlio api level you must use the flush method. L</sync> is not implemented on all platforms. Returns C<0 but true> on success, C<undef> on error, C<undef> for an invalid handle. See fsync(3c)."

=head2 sysread

This is a thin wrapper around L<IO::Handle> method of the same name.

=head2 sysseek

This is a thin wrapper around L<IO::Handle> method of the same name.

=head2 syswrite

This is a thin wrapper around L<IO::Handle> method of the same name.

=head2 tell

Calls L<perlfunc/tell> on the current element file handle, passing it whatever information was provided.

=head2 tmpdir

This method returns a temporary directory object.

It takes an optional list or hash reference of parameters:

=over 4

=item I<cleanup>

Takes a boolean value.

If true, this will enable the auto-remove feature of the directory object. See L</auto_remove>

See also I<unlink>

=item I<dir>

Takes a string representing an existing directory.

If provided, this will instruct this method to create the temporary directory below this directory.

=item I<tmpdir>

Takes a boolean value.

If true, the temporary directory will be created below the system wide temporary directory. This system temporary directory is taken from L<File::Spec/tmpdir>

=item I<unlink>

Takes a boolean value.

If true, this will enable the auto-remove feature of the directory object. See L</auto_remove>

See also I<cleanup>

=back

Upon success, this returns a new L<Module::Generic::File> object representing the new temporary directory, or if an error occurred, it returns undedf and sets an exception object.

=head2 tmpnam

This is an alias for L</tmpname>

=head2 tmpname

This returns the basename of a new temporary directory object.

=head2 touch

This method mirrors the command line utility of the same name and is to be used for a file object.

It creates the file with no content if it does not already exist. If the file exists, it merely update its modification time.

It returns the current object upon success, or undef and sets an exception object if an error occurred.

=head2 touchpath

This is a variation from L</touch> in that it will create the path leading to the underlying file object, and then L</touch> the file to create it.

It returns the current object upon success, or undef and sets an exception object if an error occurred.

=head2 truncate

This will call L</truncate> on the file handle of the underlying file object.

=head2 type

Returns the type of element this object represents. It can be either C<file> or C<directory>.

If there is no value set, this will try to guess it.

=head2 uid

This is a shortcut to L<Module::Generic::Finfo/uid>

=head2 ungetc

This is a thin wrapper around L<IO::Handle> method of the same name.

"Pushes a character with the given ordinal value back onto the given handle's input stream. Only one character of pushback per handle is guaranteed."

=head2 unlink

This will attempt to remove the underlying file.

It will return undef and set an exception object if this method is called on a directory object.

It returns the current object upon success, or undef and sets an exception object if an error occurred.

=head2 unload

Provided with some data in the first parameter, and a list or hash reference of optional parameters and this will add this data to the underlying file element.

The available options are:

=over 4

=item C<append>

If true and assuming the file is not already opened, the file will be opened using >> otherwise > will be used.

=item C<lock>

If true, L</unload> will perform a lock after opening the file and unlock it before closing it.

=back

Other options are the same as the ones used in L</open>

It returns the current object upon success, or undef and sets an exception object if an error occurred.

=head2 unload_json

Provided some perl data and an optional hash or hash reference of options and this will encode those data and save it as utf8 data to the file.

If the L<JSON> module is not installed or an error occurs during JSON encoding, this sets an L<error|Module::Generic/error> and returns undef.

The L<JSON> object provided by L<Module::Generic/new_json> already has the following options enabled: C<allow_nonref>, C<allow_blessed>, C<convert_blessed>, C<allow_tags> and C<relaxed>

Supported options are as follows, including any of the L<JSON> supported options:

=over 4

=item C<allow_blessed>

Boolean. When enabled, this will not return an error when it encounters a blessed reference that L<JSON> cannot convert otherwise. Instead, a JSON C<null> value is encoded instead of the object.

=item C<allow_nonref>

Boolean. When enabled, this will convert a non-reference into its corresponding string, number or null L<JSON> value. Default is enabled.

=item C<allow_tags>

Boolean. When enabled, upon encountering a blessed object, this will check for the availability of the C<FREEZE> method on the object's class. If found, it will be used to serialise the object into a nonstandard tagged L<JSON> value (that L<JSON> decoders cannot decode). 

=item C<allow_unknown>

Boolean. When enabled, this will not return an error when L<JSON> encounters values it cannot represent in JSON (for example, filehandles) but instead will encode a L<JSON> "null" value.

=item C<ascii>

Boolean. When enabled, will not generate characters outside the code range 0..127 (which is ASCII).

=item C<canonical> or C<ordered>

Boolean value. If true, the JSON data will be ordered. Note that it will be slower, especially on a large set of data.

=item C<convert_blessed>

Boolean. When enabled, upon encountering a blessed object, L<JSON> will check for the availability of the C<TO_JSON> method on the object's class. If found, it will be called in scalar context and the resulting scalar will be encoded instead of the object.

=item C<indent>

Boolean. When enabled, this will use a multiline format as output, putting every array member or object/hash key-value pair into its own line, indenting them properly.

=item C<latin1>

Boolean. When enabled, this will encode the resulting L<JSON> text as latin1 (or iso-8859-1),

=item C<max_depth>

Integer. This sets the maximum nesting level (default 512) accepted while encoding or decoding. When the limit is reached, this will return an error.

=item C<pretty>

Boolean value. If true, the JSON data will be generated in a human readable format. Note that this will take considerably more space.

=item C<space_after>

Boolean. When enabled, this will add an extra optional space after the ":" separating keys from values.

=item C<space_before>

Boolean. When enabled, this will add an extra optional space before the ":" separating keys from values.

=item C<utf8>

Boolean. This option is ignored, because the JSON data are saved to file using UTF-8 and double encoding would produce mojibake.

=back

=head2 unload_perl

Just like L</unload>, this takes some perl data structure (most likely an hash or an array), and some options passed as a list or as an hash reference and will open the file using C<:utf8> for L<perlfunc/binmode> and save the perl data structure to it using either L<Data::Dump> or a callback code if one is provided.

If no callback option is specified and L<Data::Dump> is not installed, this will return an error.

The following options are supported:

=over 4

=item C<callback>

A code reference. This is a callback code that will be called with the data to format, and the returned value will be saved to file. If a fatal error occurs during the callback, it will be trapped and this method will return C<undef> in scalar context or an empty list in list context after having set an L<error object|Module::Generic/error>

=item C<indent>

Integer. This is the number of spaces to use as indentation of lines. By default, L<Data::Dump> uses 2 spaces.

=item C<max_binary_size>

Integer. This is the size threshold of binary data above which it will be converted into base64.

=item C<max_width>

Integer. This is the line width threshold after which a new line will be inserted by L<Data::Dump>. The default is 60.

=back

=head2 unload_utf8

Just like L</unload>, this takes some data and some options passed as a list or as an hash reference and will open the file using C<:utf8> for L<perlfunc/binmode> and save the data to it.

=head2 unlock

This will unlock the underlying file if it was locked.

It returns the current object upon success, or undef and sets an exception object if an error occurred.

=head2 unmap

    $file->unmap( $var ) || die( $file->error );

Untie the previously tied variable to the file object. See L</mmap>

This is useful only if you are using L<File::Map>, which happens if your perl version is lower than C<5.16.0> or if you have set the global package variable C<MMAP_USE_FILE_MAP> to a true value, or if you have set the file object property L</use_file_map> to a true value.

=head2 uri

Returns a L<URI> file object, such as C<file:///Documents/Some/File.pdf>

=head2 use_file_map

Set or get the boolean value for using L<File::Map> in the L</mmap> method. By default, the value is taken from the package global variable C<$MMAP_USE_FILE_MAP>, and also by default if your perl version is greater or equal to C<v5.16.0>, then L</mmap> will use L<PerlIO/:mmap>. By setting this to true, you can force L/mmap> to use L<File::Map> rather than L<PerlIO/:mmap>

It returns the current file object upon success, or C<undef> and sets an L<error|Module::Generic/error> object upon failure.

=head2 utime

Provided with an optional access time and modification time as unix timestamp value, i.e. 10 digits representing the number of seconds elapsed since epoch, and this will change the access and modification time of the underline file or directory. For example:

    $f->utime( time(), time() );
    # is same, on most system, as:
    $f->utime;

Quoting L<perlfunc/utime>, "if the first two elements of the list are C<undef>, the utime(2) syscall from your C library is called with a null second argument. On most systems, this will set the file's access and modification times to the current time"

It returns the value returned by the core C<utime> function, which is true if the file was changed, and false otherwise.

=head2 volume

Sets or gets the volume of the underlying file or directory. This is only applicable under windows.

=head2 write

Provided with some data and this will add them to the underlying file element.

It will merely return the current object if this is a directory element, and it will return undef and set an exception object if the file is not opened.

It returns the current object upon success, or undef and sets an exception object if an error occurred.

For example:

    $f->open;
    $f->write( $data );
    $f->write( @list_of_data );
    # or
    $f->open->write( $data );

=head1 CLASS FUNCTIONS

=head2 cwd

Returns the current working directory by calling L<URI::file/cwd>

=head2 file

Takes a string, an optional hash reference of parameters and returns an L<Module::Generic::File> object.

It can be called the following ways:

    file( $file_obj );
    file( $file_obj, $options_hash_ref );
    file( $file_obj, %options );

    $obj->file( $file_obj );
    $obj->file( $file_obj, $options_hash_ref );
    $obj->file( $file_obj, %options );

    $obj->file( '/some/file' );
    $obj->file( '/some/file', $options_hash_ref );
    $obj->file( '/some/file', %options );
    $obj->file( $stringifyable_object );
    $obj->file( $stringifyable_object, $options_hash_ref );
    $obj->file( $stringifyable_object, %options );

    file( "/some/file.txt" );
    file( "./my/directory" );

=head2 rmtree

This takes a path, or an L<Module::Generic::File> object and some optional parameters as a list or as an hash reference and removes the underlying path, whether it contains elements within or not. So this is a recursive removal of all element within the given directory path. Thus, it must be called on a directory object.

It takes the following optional parameters:

=over 4

=item I<dry_run>

If true, this will only pretend to remove the files recursively. This is useful for testing without actually removing anything.

=item I<keep_root>

If true, then L</rmtree> will keep the directory and remove all of its content. If false, it will also remove the directory itself on top of its content. Defaults to false.

=item I<max_files>

Set the maximum numberof file beyond which this function will refuse to perform.

This is useful, if you know you expect only a certain number of files within a directory and you do not want the program to hang, or possibly you do not want it to removethe directory because too many files within would be a sign of an error, etc.

=back

You can also pass other parameters such as the one used by L<File::Find>, namely: bydepth, dangling_symlinks, follow, follow_fast, follow_skip, no_chdir, postprocess, preprocess, untaint, untaint_pattern and untaint_skip

See L<File::Find/%options> for more information.

Example of usage:

    $obj->rmtree( $some_dir_path );
    $obj->rmtree( $some_dir_path, $options_hashref );
    Module::Generic::File->rmtree( $some_dir_path );
    Module::Generic::File->rmtree( $some_dir_path, $options_hashref );
    rmtree( $some_dir_path );
    rmtree( $some_dir_path, $options_hashref );
    file( $some_dir_path )->rmtree;

Upon success it returns the current object. If it was called as a class function, an object is created, and it will be returned upon success too.

It returns undef and set an exception object if this is called on a file object.

=head2 rootdir

This returns an object representation of the system root directory.

=head2 sys_tmpdir

Returns a new L<Module::Generic::File> object representing the path to the system temporary directory as returned by L<File::Spec/tmpdir>

=head2 tempdir

Returns a new L<Module::Generic::File> object representing a unique temporary directory.

=head2 tempfile

Returns a new L<Module::Generic::File> object representing a unique temporary file.

It takes the following optional parameters:

=over 4

=item I<cleanup>

If true, this will enable the auto-remove option of the object. See L</auto_remove>

See also I<unlink> which is an alias.

=item I<dir>

A directory path to be used to create the temporary file within.

This parameter takes precedence over I<tmpdir>

=item I<mode>

This is the mode used to open this temporary file. It is used as arguement to L</open>

=item I<open>

If true, the temporary file will be opened. It defaults to false.

=item I<suffix> or I<extension>

A suffix to add to the temporary file including leading dot, such as C<.txt>. You can also specify the extension without any leading dot, such as C<txt>

=item I<tmpdir>

The path or object of a directory within which to create the temporary file.

See also I<dir>

=item I<unlink>

If true, this will enable the auto-remove option of the object. See L</auto_remove>

See also I<cleanup> which is an alias.

=back

=head1 EXCEPTION

This module does not C<croak> or die (at least not intentionally) as a design under the belief that it is up to the main code of the script to control the flow and any interruptions.

When an error occurrs, the methods under this package will return undef and set an L<Module::Generic::Exception> object that can be retrieved using the inherited L<Module::Generic/error> method.

For example:

    my $f = Module::Generic::File->new( "/my/file.txt" );
    $f->open || die( $f->error );

However, L<Module::Generic/error> used to return undef, is smart and knows in a granular way (thanks to L<Want>) the context of the caller. Thus, if the method is chained, L<Module::Generic/error> will instead return a L<Module::Generic::Null> object to allow the chaining to continue and avoid the perl error that would have otherwise occurred: "method called on an undefined value"

=head1 OVERLOADING

Objects of this package are overloaded and their stringification will call L</filename>

=head1 SERIALISATION

=for Pod::Coverage FREEZE

=for Pod::Coverage STORABLE_freeze

=for Pod::Coverage STORABLE_thaw

=for Pod::Coverage THAW

=for Pod::Coverage TO_JSON

Serialisation by L<CBOR|CBOR::XS>, L<Sereal> and L<Storable::Improved> (or the legacy L<Storable>) is supported by this package. To that effect, the following subroutines are implemented: C<FREEZE>, C<THAW>, C<STORABLE_freeze> and C<STORABLE_thaw>

=head1 VIRTUALISATION

This module has this unique feature that enables you to work with files in different operating system context. For example, assuming your environment is a unix flavoured operating system, you could still do this:

    use Module::Generic::File qw( file );
    my $f = file( q{C:\Documents\Newsletters\Summer2018.pdf}, os => 'win32' );
    $f->parent; # C:\Documents\Newsletters

Then, switch to old Mac format:

    my $f2 = $f->as( 'mac' );
    say $f2; # Documents:Newsletters:Summer2018.pdf

Those files manipulation under different os, of course, have limitation since you cannot use real filesystem related method like C<open>, C<print>, etc, on, say a win32 based file object in a Unix environment, as it would not work.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::Finfo>, L<Module::Generic>, L<Module::Generic::Exception>, L<Module::Generic::Number>, L<Module::Generic::Scalar>, L<Module::Generic::Array>, L<Module::Generic::Null>, L<Module::Generic::Boolean>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
