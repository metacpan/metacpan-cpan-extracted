##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/File.pm
## Version v0.1.2
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/05/20
## Modified 2021/06/26
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
    use parent qw( Module::Generic );
    use Data::UUID ();
    use Fcntl qw( :DEFAULT :flock );
    use File::Copy ();
    use File::Glob ();
    use File::Spec ();
    use IO::Dir ();
    use IO::File ();
    use Module::Generic::Finfo;
    use Nice::Try;
    use Scalar::Util ();
    use URI::file ();
    use Want;
    our @EXPORT_OK = qw( cwd file rootdir sys_tmpdir tempfile tempdir );
    our %EXPORT_TAGS = %Fcntl::EXPORT_TAGS;
    # Export Fcntl O_* constants for convenience
    our @EXPORT = grep( /^O_/, keys( %Fcntl:: ) );
    use overload (
        q{""}    => sub    { $_[0]->filename },
        bool     => sub () { 1 },
        fallback => 1,
    );
    our $VERSION = 'v0.1.2';
    ## https://en.wikipedia.org/wiki/Path_(computing)
    ## perlport
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
    ## Extended Binary Coded Decimal Interchange Code
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
    our $DIR_SEP = $OS2SEP->{ lc( $^O ) };
    our $MODE_BITS = {};
};

INIT
{
    # Credits: David Golden for code borrowed from Path::Tiny;
    $MODE_BITS = 
    {
    om => 0007,
    gm => 0070,
    um => 0700,
    };
    my $m = 0;
    $MODE_BITS->{ $_ } = ( 1 << $m++ ) for( qw( ox ow or gx gw gr ux uw ur ) );
};

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
    $self->{autoflush}      = 1;
    # Activated when this is a file or directory created by us, such as a temporary file
    $self->{auto_remove}    = 0;
    $self->{file}           = ( $file // '' );
    $self->{base_dir}       = '' unless( CORE::length( $self->{base_dir} ) );
    $self->{base_file}      = '';
    # Should we collapse dots? In most of the cases, it is ok, but there might be
    # symbolic links in the path that could complicate things and even create recursion
    $self->{collapse}       = 1;
    $self->{max_recursion}  = 12;
    $self->{resolved}       = 0;
    # directory or file. This is instrumental in playing with paths before applying them to
    # the filesystem
    $self->{type}           = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{_handle}        = '';
    # Pervious location prior to chdir, so we can revert to it when necessary
    $self->{_prev_cwd}      = '';
    $self->{changed}        = '';
    $self->{opened}         = '';
    $file = $self->{file} || return( $self->error( "No file was provided." ) );
    $self->message( 3, "File provided is '$file' and auto-remove is set to $self->{auto_remove}." );
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
                my( $vol, $dirs, $element ) = File::Spec->splitpath( $self->{base_file} );
                $base_dir = File::Spec->catpath( $vol, $dirs );
            }
        }
        # Otherwise, use the current directory
        else
        {
            $base_dir = URI->new( URI::file->cwd )->file( $^O );
        }
        $self->{base_dir} = $base_dir;
    }
    $file = $self->filename( $file ) || return( $self->pass_error );
    $self->{_orig} = [CORE::caller(1)];
    return( $self );
}

sub abs
{
    my $self = shift( @_ );
    my $path = shift( @_ );
    return( $self ) if( !defined( $path ) || !CORE::length( $path ) );
    my $file = $self->filepath;
    my $new = File::Spec->file_name_is_absolute( $path ) ? $path : URI::file->new( $path )->abs( $file )->file( $^O );
    return( $self->new( $new ) );
}

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
        try
        {
            if( $opened )
            {
                return( $self->error( "I do not have the permissions to append to this opened file \"${file}\"." ) ) if( !$self->can_append );
                $io = $opened;
                # It's not that I cannot get the position in file I am writing to, but rather
                # that later, I need to seek, and thus read from the file
                if( $self->can_read )
                {
                    $pos = $io->tell;
                }
                $io->seek(0, 2);
            }
            else
            {
                $io = $self->open( $opts->{mode}, @_ ) || return( $self->pass_error );
            }
            $io->print( ref( $data ) ? $$data : $data ) ||
                return( $self->error( "Unable to write ", length( ref( $data ) ? $$data : $data ), " bytes of data to file \"${file}\": $!" ) );
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
        catch( $e )
        {
            return( $self->error( "An unexpected error occured while trying to append ", length( ref( $data ) ? $$data : $data ), " bytes of data to file \"${file}\": $e" ) );
        }
    }
    return( $self );
}

sub auto_remove { return( shift->_set_get_boolean( 'auto_remove', @_ ) ); }

sub autoflush { return( shift->_set_get_boolean( 'autoflush', @_ ) ); }

sub base_dir { return( shift->_make_abs( 'base_dir', @_ ) ); }

sub base_file { return( shift->_make_abs( 'base_file', @_ ) ); }

sub baseinfo
{
    my $self = shift( @_ );
    my $exts = $self->_get_args_as_array( @_ );
    my $path = $self->filename;
    if( -d( $path ) || substr( $path, -CORE::length( $DIR_SEP ), CORE::length( $DIR_SEP ) ) eq $DIR_SEP )
    {
        while( substr( $path, -CORE::length( $DIR_SEP ), CORE::length( $DIR_SEP ) ) eq $DIR_SEP )
        {
            substr( $path, -CORE::length( $DIR_SEP ), CORE::length( $DIR_SEP ), '' );
        }
        return( '' ) if( !CORE::length( $path ) );
        # my @dirs = File::Spec->splitdir( $path );
        my( $vol, $parent, $me ) = File::Spec->splitpath( $path );
        my $parent_path = File::Spec->catpath( $vol, $parent );
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
        my( $vol, $parent, $file ) = File::Spec->splitpath( $path );
        my $suff;
        foreach my $ext ( @$exts )
        {
            $ext = ref( $ext ) eq 'Regexp' ? $ext : qr/$ext$/i;
            if( $file =~ s/$ext// )
            {
                $suff = $ext;
                last;
            }
        }
        if( want( 'LIST' ) )
        {
            my $parent_path = File::Spec->catpath( $vol, $parent );
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

sub can_append
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    my $io = $self->opened;
    try
    {
        if( $self->is_dir )
        {
            return( -e( $file ) && -w( $file ) );
        }
        else
        {
            # File is not opened so we do not know if the file handle is writable
            return(0) if( !$io );
            my $flags = $io->fcntl( F_GETFL, 0 );
            return( $flags & ( O_APPEND | O_RDWR ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while trying to check if we can append to ", ( $self->is_dir ? 'directory' : 'file handle for ' ), " \"${file}\": $e" ) );
    }
}

sub can_read
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    try
    {
        if( $self->is_dir )
        {
            return( $self->finfo->can_read );
        }
        else
        {
            my $opened = $self->opened;
            $self->message( 4, "Is file '$file' opened? '$opened'" );
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
            my $flags = $io->fcntl( F_GETFL, 0 );
            $self->message( 4, "Flags are: $flags and O_RDONLY is '", O_RDONLY, "' and O_RDWR is '", O_RDWR, "'." );
            my $v = ( $flags & ( O_RDONLY | & O_RDWR ) );
            $v++ unless( $flags & O_ACCMODE );
            $io->close unless( $opened );
            return( $v );
        }
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while trying to check if we can read from ", ( $self->is_dir ? 'directory' : 'file handle for ' ), " \"${file}\": $e" ) );
    }
}

sub can_write
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    my $io = $self->opened;
    try
    {
        if( $self->is_dir )
        {
            return( -e( $file ) && -w( $file ) );
        }
        else
        {
            # File is not opened so we do not know if the file handle is writable
            return(0) if( !$io );
            my $flags = $io->fcntl( F_GETFL, 0 );
            return( $flags & ( O_APPEND | & O_WRONLY | O_CREAT | & O_RDWR ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while trying to check if we can write to ", ( $self->is_dir ? 'directory' : 'file handle for ' ), " \"${file}\": $e" ) );
    }
}

sub canonpath
{
    my $self = shift( @_ );
    my $os   = shift( @_ ) || $^O;
    return( URI::file->new( $self->filename )->file( $os ) );
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
    return(0) if( !$time && !-e( $file ) );
    return( $time != [CORE::stat( $file)]->[9] );
}

sub chdir
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    $self->message( 3, "Attempting to go to directory \"${file}\"." );
    $self->message( 3, "Does the directory \"${file}\" exist? ", ( -d( $file ) ? 'yes' : 'no' ), " and is this a directory ? ", ( $self->is_dir ? 'yes' : 'no' ) );
    $self->message( 4, "Returning error because we are not a directory." ) if( !$self->is_dir );
    return( $self->error( "File \"${file}\" is not a directory, so you cannot use chdir." ) ) if( !$self->is_dir );
    my $curr = $self->cwd;
    $self->message( 4, "Current directory is '$curr', chdir to $file" );
    CORE::chdir( $file ) || return( $self->error( "Cannot chdir to directory \"${file}\": $!" ) );
    $self->_prev_cwd( $curr );
    $self->message( 3, "Ok, cwd is now '", $curr );
    return( $self );
}

sub child
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    return( $self->error( "No child was provided for our filename \"", $self->filename, "\"." ) ) if( !defined( $file ) || !CORE::length( $file ) );
    my $new;
    my $path = $self->filename;
    my( $vol, $dir, $this ) = File::Spec->splitpath( $path );
    if( -d( $path ) || substr( $path, -CORE::length( $DIR_SEP ), CORE::length( $DIR_SEP ) ) eq $DIR_SEP )
    {
        while( substr( $path, -CORE::length( $DIR_SEP ), CORE::length( $DIR_SEP ) ) eq $DIR_SEP )
        {
            substr( $path, -CORE::length( $DIR_SEP ), CORE::length( $DIR_SEP ), '' );
        }
    }
    $new = File::Spec->catpath( $vol, $path, $file );
    return( $self->new( $new ) );
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
    $self->message( 3, "Setting file mode '$mode' to file \"$file\"." );
    $self->message( 3, "Does the directory \"${file}\" exist? ", ( -d( $file ) ? 'yes' : 'no' ) );
    CORE::chmod( $mode, $file ) || return( $self->error( "An error occurred while changing mode for file \"$file\" to $mode: $!" ) );
    $self->message( 3, "Resetting file info." );
    $self->finfo->reset;
    return( $self );
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

## RFC 3986 section 5.2.4
## This is aimed for web URI initially, but is also used for filesystems in a simple way
sub collapse_dots
{
    my $self = shift( @_ );
    my $path = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    ## To avoid warnings
    $opts->{separator} //= '';
    ## A path separator is provided when dealing with filesystem and not web URI
    ## We use this to know what to return and how to behave
    my $sep  = CORE::length( $opts->{separator} ) ? $opts->{separator} : '/';
    return( '' ) if( !CORE::length( $path ) );
    my $u = $opts->{separator} ? URI::file->new( $path ) : URI->new( $path );
    unless( CORE::index( "$u", '.' ) != -1 || CORE::index( "$u", '..' ) != -1 )
    {
        $self->message( 3, "Nothing to collapse for '$u' (", ( $opts->{separator} ? $u->file( $^O ) : 'same' ), ")." );
        return( $u );
    }
    my( @callinfo ) = caller;
    $self->message( 4, "URI based on '$path' is '$u' (", overload::StrVal( $u ), ") and separator to be used is '$sep' and uri path is '", $u->path, "' called from $callinfo[0] in file $callinfo[1] at line $callinfo[2]." );
    $path = $opts->{separator} ? $u->file( $^O ) : $u->path;
    my @new = ();
    my $len = CORE::length( $path );
    
    ## "If the input buffer begins with a prefix of "../" or "./", then remove that prefix from the input buffer"
    if( substr( $path, 0, 2 ) eq ".${sep}" )
    {
        substr( $path, 0, 2 ) = '';
        ## $self->message( 3, "Removed './'. Path is now '", substr( $path, 0 ), "'." );
    }
    elsif( substr( $path, 0, 3 ) eq "..${sep}" )
    {
        substr( $path, 0, 3 ) = '';
    }
    ## "if the input buffer begins with a prefix of "/./" or "/.", where "." is a complete path segment, then replace that prefix with "/" in the input buffer"
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
    
    ## -1 is used to ensure trailing blank entries do not get removed
    my @segments = split( "\Q$sep\E", $path, -1 );
    $self->message( 3, "Found ", scalar( @segments ), " segments: ", sub{ $self->dump( \@segments ) } );
    for( my $i = 0; $i < scalar( @segments ); $i++ )
    {
        my $segment = $segments[$i];
        ## "if the input buffer begins with a prefix of "/../" or "/..", where ".." is a complete path segment, then replace that prefix with "/" in the input buffer and remove the last segment and its preceding "/" (if any) from the output buffer"
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
    ## Finally, the output buffer is returned as the result of remove_dot_segments.
    my $new_path = join( $sep, @new );
    # substr( $new_path, 0, 0 ) = $sep unless( substr( $new_path, 0, 1 ) eq '/' );
    substr( $new_path, 0, 0 ) = $sep unless( File::Spec->file_name_is_absolute( $new_path ) );
    $self->message( 4, "Adding back new path '$new_path' to uri '$u'." );
    if( $opts->{separator} )
    {
        $u = URI::file->new( $new_path );
    }
    else
    {
        $u->path( $new_path );
    }
    $self->message( 4, "Returning uri '$u' (", ( $opts->{separator} ? $u->file( $^O ) : 'same' ), ")." );
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
        $this = $self->new( "$this" ) || return( $self->pass_error );
    }
    my $file = $self->filepath;
    my $kid  = $this->filepath;
    return( CORE::index( $kid, "${file}${DIR_SEP}" ) == 0 ? $self->true : $self->false );
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
    try
    {
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
                $self->message( 3, "Opening directory \"$file\"." );
                # $io = $self->open( $opts ) || return( $self->pass_error );
                $io = $self->open( $opts ) || do
                {
                    $self->message( 3, "Passing error from open: ", $self->error );
                    return( $self->pass_error );
                };
                $self->message( 3, "Directory is now opened with io '$io'" );
            }
            my $vol = $self->volume;
            $a = $self->new_array( [ map( File::Spec->catpath( $vol, $file, $_ ), grep{ !/^\.{1,2}$/ } $io->read ) ] );
            # Put it back where it was
            $io->seek( $pos ) if( defined( $pos ) );
        }
        else
        {
            if( $opened )
            {
                $io = $opened;
                # Prevent error of reading on a non-readable file handle
                return( $a ) if( !$self->can_read );
                $pos = $io->tell;
                $io->seek(0,0) || return( $self->error( "Unable to position ourself at the top of the file \"${file}\": $!" ) );
            }
            else
            {
                $self->open( '<', $opts ) || return( $self->pass_error );
            }
            $a = $self->new_array( [ $io->getlines ] );
            $io->seek( $pos, Fcntl::SEEK_SET ) if( defined( $pos ) );
        }
        $io->close unless( $opened );
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error has occurred while trying to get the content for \"${file}\": $e" ) );
    }
    return( $a );
}

sub copy { return( shift->_move_or_copy( copy => @_ ) ); }

sub cp { return( shift->copy( @_ ) ); }

sub cwd { return( __PACKAGE__->new( ( substr( URI::file->cwd, 0, 7 ) eq 'file://' ? URI->new( URI::file->cwd )  : URI::file->new( URI::file->cwd ) )->file( $^O ) ) ); }

sub delete
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    try
    {
        if( $self->is_dir )
        {
            CORE::rmdir( $file ) || return( $self->error( "Unable to remove directory \"${file}\": $!" ) );
        }
        else
        {
            CORE::unlink( $file ) || return( $self->error( "Unable to remove file \"${file}\": $!" ) );
        }
        $self->code( 410 ); # Gone
        $self->finfo->reset;
        return( $self );
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error has occurred while trying to remove ", ( $self->is_dir ? 'directory' : 'file' ), " \"${file}\": $e" ) );
    }
}

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
    try
    {
        my $d = Digest->new( $opts->{algo} ) ||
            return( $self->error( "Unable to instantiate an Digest object: $!" ) );
        $d->addfile( $fh );
        if( $opts->{format} eq 'binary' )
        {
            return( $d->digest );
        }
        elsif( $opts->{format} eq 'hex' || $opts->{format} eq 'hexdigest' )
        {
            return( $d->hexdigest );
        }
        elsif( $opts->{format} eq 'base64' || 
               $opts->{format} eq 'b64' || 
               $opts->{format} eq 'base64digest' ||
               $opts->{format} eq 'b64digest' )
        {
            return( $d->base64digest );
        }
        else
        {
            return( $self->error( "Unknown format \"$opts->{format}\" provided to get the digest (cryptographic hash) of \"${file}\"." ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error occurred while trying to get the digest with algorithm \"$opts->{algo}\" for file \"${file}\": $e" ) );
    }
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
            try
            {
                $io = $opened;
                $io->seek(0,0);
                $io->truncate( $io->tell );
            }
            catch( $e )
            {
                return( $self->error( "Unable to seek and truncate file \"${file}\": $e" ) );
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

sub exists { return( shift->finfo->exists ); }

sub extension
{
    my $self = shift( @_ );
    return( '' ) if( $self->is_dir );
    my $file = $self->filepath;
    my $ext = ( $file =~ /\.(\w+)$/ )[0] || '';
    return( $self->new_scalar( $ext ) );
}

sub file
{
    if( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( __PACKAGE__ ) )
    {
        # print( STDERR "Argument starting from offset 1, are: '", join( "', '", @_[1..$#_] ), "' and do we have an even number of parameters? ", ( !( ( scalar( @_ ) - 1 ) % 2 ) ? 'yes' : 'no' ), "\n" );
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
            return( $_[0]->error( "Unknown set of parameters: '", join( "', '", @_ ), "'." ) );
        }
    }
    else
    {
        # print( STDERR "file(): [type 2] Calling new with ", __PACKAGE__, " and '", join( "', '", @_ ), "'\n" );
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
        $base_dir .= $DIR_SEP unless( substr( $base_dir, -CORE::length( $DIR_SEP ), CORE::length( $DIR_SEP ) ) eq $DIR_SEP );
        $self->message( 3, "New file path provided is: '$newfile' and base directory is '$base_dir' and directory separator is '$DIR_SEP'" );
        # Resolve the path if there is any link
        my $already_resolved = $self->resolved;
        my $resolved;
        if( !$already_resolved && ( $resolved = $self->resolve( $newfile ) ) )
        {
            $self->message( 3, "File '$newfile' resolved to '$resolved'." );
            $newfile = $resolved;
            $self->resolved(1);
        }
        
        # If we provide a string for the abs() method it works on Unix, but not on Windows
        # By providing an object, we make it work
        unless( File::Spec->file_name_is_absolute( $newfile ) )
        {
            $newfile = URI::file->new( $newfile )->abs( URI::file->new( $base_dir ) )->file( $^O );
            $self->message( 3, "Made file provided absolute => $newfile" );
        }
        $self->message( 3, "Getting the new file real path: '$newfile'" );
        if( $self->collapse )
        {
            $self->{filename} = $self->collapse_dots( $newfile, { separator => $DIR_SEP })->file( $^O );
            $self->message( 3, "Filename after dot collapsing is: '$self->{filename}'" );
        }
        else
        {
            $self->{filename} = URI::file->new( $newfile )->file( $^O );
        }
        
        # It potentially does not exist
        my $finfo = $self->finfo( $newfile );
        $self->message( 3, "finfo is '", overload::StrVal( $finfo ), "'." );
        if( !$finfo->exists )
        {
            $self->code(404);
        }
        else
        {
            $self->code(200);
        }
        ## Force to create new Apache2::SSI::URI object
    }
    # $self->message( 3, "Returning filename '$self->{filename}'" );
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
        local $_ = $self->new( $File::Find::name ) || return( $self->pass_error );
        $cb->( $_ );
    };
    
    try
    {
        File::Find::find( $p, $dir );
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error has occurred in File::Find::find(): $!" ) );
    }
    return( $self );
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
        $self->message( 3, "Initiating finfo object using filename '$newfile'." );
        return( $self->error( "No file path set. This should not happen." ) ) if( !$newfile );
    }
    
    if( defined( $newfile ) )
    {
        $self->{finfo} = Module::Generic::Finfo->new( $newfile, debug => $self->debug );
        $self->message( 3, "finfo object is now '", overload::StrVal( $self->{finfo} ), "'" );
        $self->message( 3, "Error occurred: ", Module::Generic::Finfo->error ) if( !$self->{finfo} );
        return( $self->pass_error( Module::Generic::Finfo->error ) ) if( !$self->{finfo} );
    }
    # $self->message( 3, "Returning finfo object '", overload::StrVal( $self->{finfo} ), "' for file '$self->{finfo}'." );
    return( $self->{finfo} );
}

# Get the flags in effect after the file was opened
sub flags
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    my $io = $self->opened;
    return(0) if( $self->is_dir || !$io || lc( $^O ) eq 'win32' || lc( $^O ) eq 'mswin32' );
    try
    {
        # force numeric context
        my $flags = ( 0 + $io->fcntl( F_GETFL, 0 ) );
        return( $flags );
    }
    catch( $e )
    {
        warnings::warn( "An error occurred while trying to get flags for opened file \"${file}\": $e\n" ) if( warnings::enabled() );
        return(0);
    }
}

sub flatten
{
    my $self = shift( @_ );
    my $path = $self->resolved ? $self : $self->resolve( @_ );
    return( $self->pass_error ) if( !defined( $path ) );
    return( $self->new( $self->collapse_dots( "$path", { separator => $DIR_SEP } )->file( $^O ) ) );
}

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

sub is_absolute { return( File::Spec->file_name_is_absolute( shift->filepath ) ); }

sub is_dir { return( shift->finfo->is_dir ); }

sub is_empty
{
    my $self = shift( @_ );
    if( $self->is_dir )
    {
        return( $self->content->length == 0 );
    }
    else
    {
        return( $self->finfo->size == 0 );
    }
}

sub is_file { return( shift->finfo->is_file ); }

sub is_link { return( shift->finfo->is_link ); }

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
        $this = $self->new( "$this" ) || return( $self->pass_error );
    }
    my $file = $self->filepath;
    return( $self->error( "Directory provided \"${this}\" to check if our file \"${file}\" is part of its file path is actually not a directory." ) ) if( !$this->is_dir );
    my $parent = $this->filepath;
    # $self->message( 3, "Checking if directory '$parent' is part of our file path '$file' starting from offset 0." );
    return( CORE::index( $file, "${parent}${DIR_SEP}" ) == 0 ? $self->true : $self->false );
}

sub is_relative { return( !File::Spec->file_name_is_absolute( shift->filepath ) ); }

sub is_rootdir { return( shift->filepath eq File::Spec->rootdir ); }

sub iterator
{
    my $self = shift( @_ );
    my $cb   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "No code reference was provided as a callback for each element found." ) ) if( ref( $cb ) ne 'CODE' );
    return( $self ) if( !$self->is_dir );
    my $seen = {};
    local $crawl = sub
    {
        my $dir = shift( @_ );
        return if( !$dir->finfo->can_read );
        my $vol = $dir->volume;
        my $io = $dir->open || return( $self->pass_error );
        while( my $elem = $io->read )
        {
            next if( $elem eq '.' || $elem eq '..' );
            my $e = $self->new( File::Spec->catpath( $vol, "$dir", $elem ) ) || next;
            try
            {
                if( $e->is_link && $opts->{follow_link} )
                {
                    # Links are resolved and resulting file path made absolute
                    my $rv = $e->readlink;
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
            catch( $e )
            {
                return( $self->error( "An unexpected error occurred while crawling \"$dir\": $e" ) );
            }
        }
        $io->close;
    };
    $crawl->( $self );
    return( $self );
}

sub length
{
    my $self = shift( @_ );
    return( $self->new_number(0) ) if( !$self->exists );
    $self->finfo->reset;
    return( $self->finfo->size );
}

sub lines
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
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
    
    try
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
    }
    catch( $e )
    {
        return( $self->error( "Unable to read file \"${file}\": $e" ) );
    }
    
    $a = $self->new_array( \@lines );
    return( $a );
}

sub load
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $file = $self->filename;
    return if( $self->is_dir );
    $opts->{binmode} //= '';
    my $binmode = $opts->{binmode};
    $binmode =~ s/^\://g;
    try
    {
        my $fh = $self->opened;
        unless( $fh )
        {
            $fh = IO::File->new( "<$file" ) ||
            return( $self->error( "Unable to open file \"$file\" in read mode: $!" ) );
        }
        $fh->binmode( ":${binmode}" ) if( CORE::length( $binmode ) );
        my $size;
        if( $binmode eq ':unix' && ( $size = -s( $fh ) ) )
        {
            my $buf;
            $fh->read( $buf, $size );
            return( $buf );
        }
        else
        {
            local $/;
            return( scalar( <$fh> ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "An error occured while trying to open and read file \"$file\": $e" ) );
    }
}

sub load_utf8
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return if( $self->is_dir );
    $opts->{binmode} = 'utf8';
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
        if( $opts->{exclusive} || $opts->{mode} eq 'exclusive' )
        {
            $flags |= LOCK_EX;
        }
        elsif( $opts->{shared} || $opts->{mode} eq 'shared' )
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
    my $io = $self->opened || return( $self->error( "File is not opened yet. You must open the file \"${file}\" first to unlock semaphore." ) );
    # perlport: "(VMS, RISC OS, VOS) Not implemented"
    return(1) if( $^O =~ /^(vms|riscos|vos)$/i );
    # $type = LOCK_EX if( !defined( $type ) );
    return( $self->unlock ) if( ( $flags & LOCK_UN ) );
    # already locked
    return(1) if( $self->locked & $flags );
    $opts->{timeout} = 0 if( !defined( $opts->{timeout} ) || $opts->{timeout} !~ /^\d+$/ );
    # If the lock is different, release it first
    $self->unlock if( $self->locked );
    try
    {
        local $SIG{ALRM} = sub{ die( "timeout" ); };
        alarm( $opts->{timeout} );
        my $rc = $io->flock( $flags ) || return( $self->error( "Unable to set a lock on file \"$file\": $!" ) );
        alarm( 0 );
        if( $rc )
        {
            $self->locked( $flags );
        }
        else
        {
            return( $self->error( "Failed to set a lock on file \"$file\": $!" ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Unable to set a lock on file \"${file}\": $e" ) );
    }
    return( $self );
}

sub locked { return( shift->_set_get_scalar( 'locked', @_ ) ); }

sub max_recursion { return( shift->_set_get_number( 'max_recursion', @_ ) ); }

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
    
    local $process = sub
    {
        my $path = shift( @_ );
        $path = $path->filepath if( $self->_is_object( $path ) && $path->isa( 'Module::Generic::File' ) );
        $self->message( 3, "Processing file path '$path'" );
        my $params = {};
        $params = shift( @_ ) if( @_ && ref( $_[0] ) eq 'HASH' );
        $params->{recurse} //= 0;
        return( $self->error( "Too many recursion. Exceeded the threshold of $max_recursion" ) ) if( $max_recursion > 0 && $params->{recurse} >= $max_recursion );
        # my( $vol, $dirs, $fname ) = File::Spec->splitpath( $path );
        # my @fragments = File::Spec->splitdir( $dirs );
        my $vol = [File::Spec->splitpath( $path )]->[0];
        my @fragments = File::Spec->splitdir( $path );
        my $curr = $self->new_array;
        my $parent_path  = '';
        foreach my $dir ( @fragments )
        {
            # $parent_path = $curr->length ? File::Spec->catpath( $vol, File::Spec->catdir( @$curr ) ) : '';
            $parent_path = $curr->length ? File::Spec->catdir( @$curr ) : '';
            my $current_path = File::Spec->catpath( $vol, File::Spec->catdir( @$curr, $dir ) );
            if( !-e( $current_path ) )
            {
                CORE::mkdir( $current_path ) || return( $self->error( "Unable to create directory \"$current_path\" ", ( CORE::length( $parent_path ) ? "under $parent_path" : "at filesystem root" ), ": $!" ) );
                local $_ = $current_path;
                try
                {
                    $cb->({
                        dir    => $dir,
                        path   => $current_path,
                        parent => $parent_path,
                        volume => $vol,
                    }) || return;
                }
                catch( $e )
                {
                    return( $self->error( "Callback raised an exception on fragment \"$dir\" for path \"current_path\": $e" ) );
                }
            }
            # See readlink in perlport
            elsif( $^O !~ /^(mswin32|win32|vms|riscos)$/i && -l( $current_path ) )
            {
                try
                {
                    my $actual = CORE::readlink( $current_path ) || return( $self->error( "Unable to read the symbolic link \"$current_path\": $!" ) );
                    $self->message( 3, "Path \"$current_path\" points to a link which resolves to \"$actual\"." );
                    my $before = URI::file->new( $current_path )->file( $^O );
                    my $after  = URI::file->new( $actual )->abs( $before )->file( $^O );
                    $params->{recurse}++;
                    return( $process->( $after, $params ) );
                }
                catch( $e )
                {
                    return( $self->error( "An unexpected error occurred while trying to resolve the symbolic link \"$current_path\": $e" ) );
                }
            }
            elsif( !-d( $current_path ) )
            {
                return( $self->error( "Found a non-directory element \"$current_path\" ", ( CORE::length( $parent_path ) ? "under $parent_path" : "at filesystem root" ), ": $!" ) );
            }
            $curr->push( $dir );
        }
        return( File::Spec->catpath( $vol, File::Spec->catdir( @$curr ) ) );
    };
    
    my $new = $self->new_array;
    foreach my $path ( @args )
    {
        my $actual = $process->( $path ) || return( $self->pass_error );
        my $o = $self->new( $actual, { resolved => 1 });
        $new->push( $o );
    }
    return( $new );
}

sub move { return( shift->_move_or_copy( move => @_ ) ); }

sub mv { return( shift->move( @_ ) ); }

sub open
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{autoflush} //= $self->autoflush;
    my $file = $self->filename;
    return( $self->error( ( $self->is_dir ? 'Directory' : 'File' ), " \"${file}\" is already opened. You need to close it first to re-open it." ) ) if( $self->opened );
    # return( $self->error( ( $self->is_dir ? 'Directory' : 'File' ), " \"${file}\" does not exist." ) ) if( !$self->exists && !CORE::length( $_[0] ) );
    try
    {
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
            $self->message( 3, "Opening file \"$file\" with mode '$mode'." );
            $io = IO::File->new( $file, $mode, @_ ) || return( $self->error( "Unable to open file \"$file\": $!" ) );
            if( CORE::exists( $opts->{binmode} ) )
            {
                if( !defined( $opts->{binmode} ) || !CORE::length( $opts->{binmode} ) )
                {
                    $io->binmode || return( $self->error( "Unable to set binmode to binary for file \"$file\": $!" ) );
                }
                else
                {
                    $self->message( 3, "Setting binmode to '$opts->{binmode}'." );
                    $opts->{binmode} =~ s/^\://g;
                    $io->binmode( ":$opts->{binmode}" ) || return( $self->error( "Unable to set binmode to \"$opts->{binmode}\" for file \"$file\": $!" ) );
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
    catch( $e )
    {
        return( $self->error( "An unexpected error has occured while trying to open file \"${file}\": $e" ) );
    }
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
        $self->message( 3, "fileno for $fh is: ", CORE::fileno( $fh ) );
        $self->message( 3, "Is file opened ? ", ( !$self->is_dir && $fh->opened ) ? 'yes' : 'no' );
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

sub parent
{
    my $self = shift( @_ );
    # No need to compute this twice, send what we have cached
    return( $self->{parent} ) if( $self->{parent} );
    # I deliberately did not do split( '/', $path, -1 ) so that if there is a trailing '/', it will not be counted
    # 2021-03-27: Was working well, but only on Unix systems...
    # my @segments = split( '/', $self->filename, -1 );
    my( $vol, $parent, $file ) = File::Spec->splitpath( $self->filename );
    $vol //= '';
    $file //= '';
    $self->message( 3, "Filename is '", $self->filename, "', volume is '$vol', parent '$parent' and file is '$file'." );
    my @segments = File::Spec->splitpath( File::Spec->catfile( $parent, $file ) );
    # $self->message( 3, "Path segments are: ", sub{ $self->dump( \@segments )} );
    pop( @segments );
    return( $self ) if( !scalar( @segments ) );
    $self->message( 3, "Creating new object with document uri '", $vol . File::Spec->catdir( @segments ), "'." );
    # return( $self->new( join( '/', @segments ), ( $r ? ( apache_request => $r ) : () ) ) );
    # return( $self->new( $vol . File::Spec->catdir( @segments ) ) );
    $self->{parent} = $self->new( File::Spec->catpath( $vol, File::Spec->catdir( @segments ) ) );
    return( $self->{parent} );
}

sub print { return( shift->_filehandle_method( 'print', 'file', @_ ) ); }

sub printf { return( shift->_filehandle_method( 'printf', 'file', @_ ) ); }

sub println { return( shift->_filehandle_method( 'say', 'file', @_ ) ); }

sub read
{
    my $self = $_[0];
    return( __PACKAGE__->error( "read() must be called by an object." ) ) if( !( Scalar::Util::blessed( $self ) && $self->isa( 'Module::Generic::File' ) ) );
    my $file = $self->filepath;
    my $io = $self->opened;
    return( $self->error( ( $self->is_dir ? 'Directory' : 'File' ), " \"${file}\" is not opened." ) ) if( !$io );
    try
    {
        if( $self->is_dir )
        {
            return( $io->read );
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
    catch( $e )
    {
        return( $self->error( "An unexpected error has occurred while trying to read from ", ( $self->is_dir ? 'directory' : 'file' ), " \"${file}\": $e" ) );
    }
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
    return( $self->new( $rv, { base_dir => $self->parent } ) );
}

sub relative
{
    my $self = shift( @_ );
    return( File::Spec->abs2rel( $self->filepath, $self->base_dir ) );
}

sub rmdir
{
    my $self = shift( @_ );
    return( $self ) if( !$self->is_dir );
    try
    {
        my $dir = $self->filename;
        CORE::rmdir( $dir ) ||
            return( $self->error( "Unable to remove directory \"$dir\": $e. Is it empty?" ) );
        return( $self );
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while trying to remove the directory \"$dir\": $e" ) );
    }
}

sub remove { return( shift->delete( @_ ) ); }

sub resolve
{
    my $self = shift( @_ );
    my $path = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{recurse} //= 0;
    my $max_recursion = $self->max_recursion;
    return( $self->error( "Too many recursion. Exceeded the threshold of $max_recursion" ) ) if( $max_recursion > 0 && $opts->{recurse} >= $max_recursion );
    $path = File::Glob::bsd_glob( $path );
    $self->message( 3, "Possibly expanded file path now is '$path'." );
    my( $vol, $dirs, $fname ) = File::Spec->splitpath( $path );
    my @fragments = File::Spec->splitdir( $dirs );
    $self->message( 3, "Fragments are: ", sub{ $self->dump( \@fragments ) });
    my $curr = $self->new_array;
    my $parent_path  = '';
    foreach my $dir ( @fragments )
    {
        my $current_path = File::Spec->catdir( @$curr, $dir );
        $self->message( 3, "Current path now is: '$current_path'." );
        # Stop right here. There is a missing path, thus we cannot resolve
        if( !-e( $current_path ) )
        {
            # Return false, but not undef, which we use for errors
            return( '' );
        }
        elsif( $^O !~ /^(mswin32|win32|vms|riscos)$/i && -l( $current_path ) )
        {
            try
            {
                my $actual = CORE::readlink( $current_path );
                $self->message( 3, "Path \"$current_path\" points to a link which resolves to \"$actual\"." );
                my $before = URI::file->new( $current_path );
                my $after  = URI::file->new( $actual )->abs( $before )->file( $^O );
                $opts->{recurse}++;
                unless( File::Spec->file_name_is_absolute( $after ) )
                {
                    $after = $self->resolve( $after, $opts );
                    $self->message( 3, "Resolved symbolic link value to '$after'." );
                }
                my @new = File::Spec->splitdir( $after );
                $self->message( 3, "Updated fragments are: ", sub{ $self->dump( \@new ) });
                $curr = $self->new_array( \@new );
                next;
            }
            catch( $e )
            {
                return( $self->error( "An unexpected error occurred while trying to resolve the symbolic link \"$current_path\": $e" ) );
            }
        }
        $curr->push( $dir );
    }
    $self->message( 3, "Returning ", sub{ File::Spec->catpath( $vol, File::Spec->catdir( @$curr ), $fname ) });
    return( $self->new( File::Spec->catpath( $vol, File::Spec->catdir( @$curr ), $fname ), { resolved => 1 }) );
}

sub resolved { return( shift->_set_get_boolean( 'resolved', @_ ) ); }

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
    $self->message( 3, "Removing directory \"$dir\"." );
    return( $self->error( "Can only call rmtree on a directory." ) ) if( !$self->is_dir );
    my $opts = $self->_get_args_as_hash( @_ );
    $self->message( 3, "Options are: ", sub{ $self->dump( $opts ) });
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
    
    try
    {
        File::Find::find( $p, $dir );
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error has occurred while trying to scan directory \"$dir\": $e" ) );
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
    
    $self->messagef( 3, "%d files found to remove and %d directory.", $files->length, $dirs_to_remove->length );
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
                $self->message( 4, "${prefix} File \"${f}\" eithe does not exist or is not writable." );
                $error_files->push( $f );
            }
            else
            {
                $self->message( 4, "${prefix} Would remove file \"${f}\"" );
            }
        }
        else
        {
            try
            {
                $self->message( 4, "${prefix} Actually removing file \"${f}\"" );
                unlink( $f ) || do
                {
                    $self->message( 4, "${prefix} Unable to remove file \"${f}\": $!" );
                    $error_files->push( $f );
                };
            }
            catch( $e )
            {
                $error_files->push( $f );
                warnings::warn( "An error occurred while trying to remove file \"$f\": $e\n" ) if( warnings::enabled() );
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
        local $go_there = sub
        {
            my $where = shift( @_ );
            try
            {
                CORE::chdir; # Switch to HOME, or LOGDIR. See chdir in perlfunc
            }
            catch( $e )
            {
                warnings::warn( "Unable to chdir to ", ( defined( $prev_cwd ) ? "\"${prev_cwd}\"" : 'default system location (if any)' ), ": $e\n" ) if( warnings::enabled() );
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
                $self->message( 4, "${prefix} Would remove directory \"${d}\"" );
            }
        }
        else
        {
            try
            {
                $self->message( 4, "${prefix} Actually removing directory \"${d}\"" );
                CORE::rmdir( $d ) || do
                {
                    $self->message( 4, "${prefix} Unable to remove directory \"${d}\": $!" );
                    $error_files->push( $d );
                };
            }
            catch( $e )
            {
                $error_files->push( $d );
                warnings::warn( "An error occurred while trying to remove directory \"$d\": $e\n" ) if( warnings::enabled() );
            }
        }
        # Return true
        return(1);
    });
    $self->messagef( 3, "${prefix} %d files and directories removed and %d issues found.", ( $total - $error_files->length ), $error_files->length );
    unless( $opts->{keep_root} )
    {
        CORE::rmdir( $dir ) || do
        {
            warnings::warn( "Unable to remove the directory \"$dir\": $!\n" ) if( warnings::enabled() );
        };
    }
    $self->message( 4, "Files with issues:" );
    $error_files->foreach(sub
    {
        $self->message( 4, $_ );
    });
    return( $self );
}

sub rewind { return( shift->_filehandle_method( 'rewind', 'directory', @_ ) ); }

sub rewinddir { return( shift->rewind( @_ ) ); }

sub root_dir { return( shift->new( File::Spec->rootdir ) ); }

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
        
        try
        {
            File::Find::find( $p, $file );
        }
        catch( $e )
        {
            return( $self->error( "An unexpected error has occurred while calling File::Find::find() to compte recursively all files size in directory \"${file}\": $e" ) );
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

sub stat { return( shift->finfo ); }

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
        $this = $self->new( "$this" ) || return( $self->pass_error );
    }
    
    return( $self->error( "There is already a file at \"${this}\"." ) ) if( $this->exists );
    my $file = $self->filepath;
    my $dest = $this->filepath;
    try
    {
        symlink( $file, $dest ) || return( $self->error( "Unable to create link from \"${file}\" to \"${dest}\": $!" ) );
        return( $self );
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error has occurred while trying to create a symbolic link from \"${file}\" to \"${dest}\": $e" ) );
    }
}

sub sys_tmpdir { return( __PACKAGE__->new( File::Spec->tmpdir ) ); }

sub tell { return( shift->_filehandle_method( 'tell', 'file|directory', @_ ) ); }

sub tempdir { return( &_function2method( \@_ )->tmpdir( @_ ) ); }

sub tempfile
{
    my $self = &_function2method( \@_ ) || __PACKAGE__;
    # print( STDERR __PACKAGE__, "::tempfile: \$self is '$self' and args are '", join( "', '", @_ ), "'\n" );
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
    $fname .= $opts->{suffix} if( CORE::defined( $opts->{suffix} ) && CORE::length( $opts->{suffix} ) && $opts->{suffix} =~ /^\.[\w\-]+$/ );
    $self->message( 3, "Filename generated is '$fname'" );
    my $dir;
    my $sys_tmpdir = File::Spec->tmpdir;
    my $base_vol = [File::Spec->splitpath( $sys_tmpdir )]->[0];
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
        $base_vol = [File::Spec->splitpath( $dir )]->[0];
    }
    elsif( $opts->{tmpdir} )
    {
        # $dir = File::Spec->catpath( $base_vol, $sys_tmpdir, $uuid->create_str );
        $dir = $self->tmpdir(
            cleanup => $opts->{auto_remove},
            tmpdir  => 1,
        );
        return( $self->error( "Found an existing directory with the name just generated: \"$dir\". This should never happen." ) ) if( -e( $dir ) );
        mkdir( $dir ) || return( $self->error( "Unable to create temporary directory \"$dir\": $!" ) );
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
    ( $base_vol, $parent, $me ) = File::Spec->splitpath( $dir );
    $dir = File::Spec->catdir( $parent, $me );
    CORE::delete( @$opts{ qw( tmpdir tempdir ) } );
    my $new = $self->new( File::Spec->catpath( $base_vol, $dir, $fname ), %$opts ) || return( $self->pass_error );
    # $self->message( 3, "So far dir is '$dir' with path '$new'" );
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
    my $sys_tmpdir = File::Spec->tmpdir;
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
    
    unless( defined( $dir ) )
    {
        $parent = $sys_tmpdir;
    }
    
    # Necessary contortion to accomodate systems like Windows that use 'volume'
    my( $vol, $basedir, $fname ) = File::Spec->splitpath( $parent );
    my $dir  = File::Spec->catpath( $vol, File::Spec->catdir( $basedir, $fname ), $uuid->create_str );
    return( $self->error( "Found an existing directory with the name just generated: \"${dir}\". This should never happen." ) ) if( -e( $dir ) );
    mkdir( $dir ) || return( $self->error( "Unable to create temporary directory \"$dir\": $!" ) );
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
        $self->message( 3, "File '$file' does not exist yet, open it and close it." );
        my $io = $self->open( '>' ) || return( $self->pass_error );
        $self->message( 3, "Closing file '$file'." );
        $io->close;
        $self->message( 3, "File descriptor is now '", CORE::fileno( $io ), "'." );
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

sub unlink
{
    my $self = shift( @_ );
    return( $self->error( "Cannot call unlink on a directory." ) ) if( $self->is_dir );
    my $file = $self->filepath;
    # Would only remove the most recent version on VMS
    CORE::unlink( $file ) || return( $self->error( "Unable to remove file \"${file}\": $e" ) );
    return( $self );
}

sub unload
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    return( $self ) if( ( ref( $data ) eq 'SCALAR' && !CORE::length( $$data ) ) || ( !ref( $data ) && !CORE::length( $data ) ) );
    return( $self->error( "I was expecting either a string or a scalar reference, but instead I got '$data'." ) ) if( ref( $data ) && ref( $data ) ne 'SCALAR' );
    return( $self ) if( $self->is_dir );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{append} //= 0;
    my $file = $self->filepath;
    my $io;
    if( !( $io = $self->opened ) )
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
    $io->print( ref( $data ) ? $$data : $data ) || return( $self->error( "Unable to print ", CORE::length( ref( $data ) ? $$data : $data ), " bytes of data to file \"${file}\": $!" ) );
    return( $self );
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
    ## $self->message( 3, "Removing lock for semaphore id \"$semid\" and locked value '$self->{locked}'." );
    my $flags = $self->locked | LOCK_UN;
    $flags ^= LOCK_NB if( $flags & LOCK_NB );
    try
    {
        my $rc = $io->flock( $flags ) || return( $self->error( "Unable to remove the lock from file \"${file}\": $!" ) );
        if( $rc )
        {
            $self->locked( 0 );
        }
        else
        {
            return( $self->error( "Failed to remove the lock from file \"${file}\": $!" ) );
        }
        return( $self );
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error has occurred while trying to unlock file \"${file}\": $e" ) );
    }
}

sub volume
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $vol = shift( @_ );
        my $fpath = $self->filepath;
        my( $old_vol, $dir, $fname ) = File::Spec->splitpath( $fpath );
        $self->filename( File::Spec->catpath( $vol, $dir, $fname ) );
        return( $old_vol );
    }
    return( [File::Spec->splitpath( $self->filepath )]->[0] );
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
    try
    {
        return( $self->error( "File \"${file}\" is not opened with write permission." ) ) if( !$self->can_write );
        # Nothing to write was provided
        return( $self ) if( !scalar( @_ ) );
        $io->print( @_ ) || return( $self->error( "Unable to print data to file \"${file}\": $!" ) );
        return( $self );
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error has occurred while trying to write to file \"${file}\": $e" ) );
    }
}

sub DESTROY
{
    my $self = shift( @_ );
    my $file = $self->filepath;
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
        my @info = caller();
        my $sub = [caller(1)]->[3];
        $self->message( 3, "Removing file '", $self->filepath, "' that was created in file $orig->[1], at line $orig->[2]. Called from file $info[1] at line $info[2] in sub $sub" );
        if( $self->is_dir )
        {
            $self->rmtree;
        }
        else
        {
            $self->delete;
        }
    }
#     else
#     {
#         my @info = caller();
#         $self->debug(3);
#         $self->message( 3, "File '", $self->filepath, "' is NOT going to be removed. Created in file $orig->[1], at line $orig->[2]. Called from file $info[1] at line $info[2]" );
#     }
};

sub FREEZE { return( shift->filepath ) }

sub THAW { return( shift->new( @_ ) ); }

sub TO_JSON { return( shift->filepath ); }

sub _filehandle_method
{
    my $self = shift( @_ );
    # e.g. print, printf, seek, tell, rewinddir, close, etc
    my $what = shift( @_ );
    # 'file' or 'directory'
    my $for  = shift( @_ );
    my $file = $self->filepath;
    my $type = $self->is_dir ? 'directory' : 'file';
    try
    {
        my $ok = [CORE::split( /\|/, $for )];
        $self->message( 3, "You cannot call \"${what}\" on a ${type}. You can only call this on ${for}" ) if( !scalar( CORE::grep( $_ eq $type, @$ok ) ) );
        return( $self->error( "You cannot call \"${what}\" on a ${type}. You can only call this on ${for}" ) ) if( !scalar( CORE::grep( $_ eq $type, @$ok ) ) );
        my $opened = $self->opened || 
            return( $self->error( ucfirst( $type ), " \"${file}\" is not opened yet." ) );
        $self->message( 3, "File handle is '$opened'. Calling method '$what' with arguments: '", CORE::join( "', '", @_ ), "'." );
        return( $opened->$what( @_ ) );
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error occurred while trying to call ${what} on ${type} \"${file}\": $e" ) );
    }
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
        if( substr( $caller[3], rindex( $caller[3], '::' ) + 2 ) eq 'file' && 
            ref( $caller[0] ) eq ref( $ref->[0] ) )
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
        $self->message( 3, "Setting $field to '$this'." );
        if( Scalar::Util::blessed( $this ) && $this->isa( 'URI::file' ) )
        {
            $this = URI->new_abs( $this )->file( $^O );
        }
        elsif( !File::Spec->file_name_is_absolute( "$this" ) )
        {
            $this = URI::file->new_abs( "$this" )->file( $^O );
        }
        $self->message( 3, "$field is now '$this'" );
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
    try
    {
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
                
                    my( $vol, $path, $name ) = File::Spec->splitpath( "$dest" );
                    $new_path = $dest = File::Spec->catpath( $vol, File::Spec->catdir( $path, $name ), $base );
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
                    return( $self->error( "Unable to copy file \"${file}\" to \"${dest}\"." ) );
                }
            }
        
            my $code = File::Copy->can( $what ) ||
            return( $self->error( "Super weird. Could not find method '$what' in File::Copy!" ) );
        
            $code->( $file, $dest ) || 
                return( $self->error( "Unable to $what file \"${file}\" to \"${dest}\": $!" ) );
        }
    
        # If the destination was a directory, we formulate the new file path.
        # It would have been nice if File::Copy::move returned the new file path
        # Note that we do so even if the destination directory does not exist.
        # It would then be only virtual
        if( -d( "$dest" ) || ( $dest->isa( 'Module::Generic::File' ) && $dest->type eq 'directory' ) )
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
                    # XXX Maybe use child() method instead?
                    $base = $self->basename;
                    my( $vol, $path, $fname ) = File::Spec->splitpath( $dest->filepath );
                    $dest = File::Spec->catpath( $vol, File::Spec->catdir( $path, $fname ), $base );
                }
                # A regular string or an overloaded object
                elsif( !ref( $dest ) || overload::Method( $dest, '""' ) )
                {
                    # We get the directory portion of the path.
                    $base = $self->basename;
                    my( $vol, $path, $fname ) = File::Spec->splitpath( "$dest" );
                    $dest = File::Spec->catpath( $vol, File::Spec->catdir( $path, $fname ), $base );
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
        elsif( Scalar::Util::reftype( $dest ) eq 'GLOB' )
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
    catch( $e )
    {
        return( $self->error( "An unexpected error occurred while trying to $what file \"${file}\" to \"${dest}\": $!" ) );
    }
}

sub _prev_cwd { return( shift->_set_get_scalar( '_prev_cwd', @_ ) ); }

# XXX IO::File class modification
{
    package
        IO::File;
    
    sub flock { CORE::flock( shift( @_ ), shift( @_ ) ); }
}

1;

# XXX POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::File - File Object Abstraction Class

=head1 SYNOPSIS

    use Module::Generic::File qw( cwd file rootdir tempfile tempdir sys_tmpdir );
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

=head1 VERSION

    v0.1.2

=head1 DESCRIPTION

This packages serves to resolve files whether inside Apache scope with mod_perl or outside, providing a unified api.

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

Sets the base directory for this file.

=item I<base_file>

Sets the base file for this file, i.e. the reference file frm which the base directory will be derived, if not already specified.

=item I<collapse>

Enables or disables the collapsing of dots in the file path.

This will attempt to resolve and remove the dots to provide an absolute file path without dots. For example:

C</../a/b/../c/./d.html> would become C</a/c/d.html>

=item I<max_recursion>

Sets the maximum recursion allowed. Defaults to 12.

Its value is used in L</mkpath> and L</resolve>

=item I<resolved>

A boolean flag which states whether this file has been resolved already or not.

=item I<type>

The type of file this is. Either a file or a directory.

=back

=head2 abs

If no argument is provided, this return the current object, since the underlying file is already changed into absolute file path.

If a file path is provided, then it will change it into an absolute one and return a new L<Module::Generic::File> object.

=head2 append

Provided with some data as its first argument, and assuming the underlying file is a file and not a directory, this will open it if it is not already opened and append the data provided.

If the file was already opened, whatever position you were in the file, will be restored after having appended the data.

It returns the curent file object upon success for chaining or undef and sets an error object if an error occurred.

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

This methods accepts as an optional parameter a list or an array reference of possible extensions.

=head2 basename

This returns the file base name as a L<Module::Generic::Scalar> object.

You can provide optionally a list or array reference of possible extensions.

=head2 binmode

Sets or get the file binmode.

=head2 can_append

Returns true if the file or directory are writable, and data can be added to it. False otherwise.

If an error occurred, undef will be returned an an exception will be set.

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

=head2 cwd

Returns a new L<Module::Generic::File> object representing the current working directory.

=head2 delete

This will attempt to remove the underlying directory or file and returns the current object upon success or undef and set the exception object if an error occurred.

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

=head2 exists

Returns true if the underlying directory or file exists, false otherwise.

This uses L<Module::Generic::Finfo/exists>

=head2 extension

Returns the current file extension as a L<Module::Generic::Scalar> object if it is a regular file, or an empty string if it is a directory.

Extension is simply defined with the regular expression C<\.(\w+)$>

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

Assuming the current object represents an existing directory, this takes one parameter which must be a code reference. This is used as a callback with the module L<File::Find/find>

It returns whatever L<File::Find/find> returns or undef and sets an exception object if an error occurred.

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

=head2 is_absolute

Returns true if the element is an absolute path or false otherwise.

=head2 is_dir

Returns true if the element is a directory or false otherwise.

=head2 is_empty

Returns true if the element is empty or false otherwise.

If the element is a directory C<empty> means there is no file or directory within.

If the element is a regular file, C<empty> means it is zero byte big.

=head2 is_file

Returns true if the element is regular file or false otherwise.

=head2 is_link

Returns true if the element is symbolic link or false otherwise.

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

=head2 length

This returns the size of the element as a L<Module::Generic::Number> object.

if the element does not yet exist, L<Module::Generic::Number> object representing the value 0 is returned.

This uses L<Module::Generic::Finfo/size>

=head2 lines

Assuming this is a regular file , this methods returns its content as an array object (L<Module::Generic::Array>) of lines.

If a directory object is called, or the element does not exist or the file element is not readable, this still returns the array object, but empty.

If an error occurred, C<undef> is returned and an exception is set.

=head2 load

Assuming this element is an existing file, this will load its content and return it as a regular string.

If the C<binmode> used on the file is C<:unix>, then this will call L<perlfunc/read> to load the file content, otherwise it localises the input record separator C<$/> and read the entire content in one go. See L<perlvar/$INPUT_RECORD_SEPARATOR>

If this method is called on a directory object, it will return undef.

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

=head2 max_recursion

Sets or gets the maximum recursion limit.

=head2 mkpath

This takes a code reference that is used as a callback.

It will create the path corresponding to the element, or to the list of path fragments provided as optional arguments.

For each path fragments, this will call the callback and provided it with an hash reference containing the following keys:

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

=head2 move

This behaves exactly like L</copy> except it moves the element instead of copying it.

Note that you can use C<mv> as a method shortcut instead.

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

=head2 println

Calls L<perlfunc/say> on the file handle and pass it whatever arguments is provided.

=head2 read

If the element is a directory, this will call L<IO::Dir/read> and return the value received.

If the element is a regular file, then it takes the same arguments as L<perlfunc/read>, meaning:

    $io->read( $buff, $size, $offset );
    # or
    $io->read( $buff, $size );
    # or
    $io->read( $buff );

If an error occurred, this returns undef and set an exception object.

=head2 readlink

This calls L<perlfunc/readlink> and returns a new L<Module::Generic::File> object, but this does nothing and merely return the current object if the current operating system is one of Win32, VMS, RISC OS, or if the underlying file does not actually exist or of course if the element is actually not a symbolic link.

If an error occurred, this returns undef and set an exception object.

=head2 relative

Returns a relative path representation of the current element.

=head2 remove

This is an alias for L</delete>

=head2 resolve

Provided with a path and a list or hash reference of optional parameters and this will attempt at resolving the file path.

It returns a new L<Module::Generic::File> object or undef and sets an exception object if an error occurred.

The only parameter supported is:

=over 4

=item I<recurse>

If true, this will have resolve perform recursively.

=back

=head2 resolved

Returns true if the file object has been resolved or false otherwise.

=head2 rewind

This will call L<perlfunc/rewind> on the file handle.

=head2 rewinddir

This will call L<IO::Dir/rewinddir> on the directory file handle.

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

=head2 stat

Returns the value from L</finfo>

=head2 symlink

Provided with a file path or an L<Module::Generic::File> object, and this will call L<perlfunc/symlink> to create a symbolic link.

On the following operating system not supported by perl, this will merely return the current object itself: Win32 and RISC OS

This returns the current object upon success and undef and sets an exception object if an error occurred.

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

=head2 unlink

This will attempt to remove the underlying file.

It will return undef and set an exception object if this method is called on a directory object.

It returns the current object upon success, or undef and sets an exception object if an error occurred.

=head2 unload

Provided with some data in the first parameter, and a list or hash reference of optional parameters and this will add this data to the underlying file element.

The available options are:

=over 4

=item I<append>

If true and assuming the file is not already opened, the file will be opened using >> otherwise > will be used.

=back

Other options are the same as the ones used in L</open>

It returns the current object upon success, or undef and sets an exception object if an error occurred.

=head2 unload_utf8

Just like L</unload>, this takes some data and some options passed as a list or as an hash reference and will open the file using C<:utf8> for L<perlfunc/binmode>

=head2 unlock

This will unlock the underlying file if it was locked.

It returns the current object upon success, or undef and sets an exception object if an error occurred.

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

=item I<suffix>

A suffix to add to the temporary file including leading dot, such as C<.txt>

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

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::Finfo>, L<Module::Generic>, L<Module::Generic::Exception>, L<Module::Generic::Number>, L<Module::Generic::Scalar>, L<Module::Generic::Array>, L<Module::Generic::Null>, L<Module::Generic::Boolean>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
