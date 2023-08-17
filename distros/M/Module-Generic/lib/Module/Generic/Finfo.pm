##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Finfo.pm
## Version v0.3.3
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/05/20
## Modified 2023/08/17
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Finfo;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $HAS_LOCAL_TZ $HAS_FILE_MMAGIC_XS );
    use File::Basename ();
    eval( "use File::MMagic::XS 0.09008" );
    our $HAS_FILE_MMAGIC_XS = $@ ? 0 : 1;
    use Module::Generic::Null;
    use Nice::Try;
    use Want;
    use overload (
        q{""}    => sub    { $_[0]->{filepath} },
        bool     => sub () { 1 },
        fallback => 1,
    );
    use constant {
        FINFO_DEV        => 0,
        FINFO_INODE      => 1,
        FINFO_MODE       => 2,
        FINFO_NLINK      => 3,
        FINFO_UID        => 4,
        FINFO_GID        => 5,
        FINFO_RDEV       => 6,
        FINFO_SIZE       => 7,
        FINFO_ATIME      => 8,
        FINFO_MTIME      => 9,
        FINFO_CTIME      => 10,
        FINFO_BLOCK_SIZE => 11,
        FINFO_BLOCKS     => 12,
        #  the file type is undetermined.
        FILETYPE_NOFILE => 0,
        # a file is a regular file.
        FILETYPE_REG => 1,
        # a file is a directory
        FILETYPE_DIR => 2,
        # a file is a character device
        FILETYPE_CHR => 3,
        # a file is a block device
        FILETYPE_BLK => 4,
        # a file is a FIFO or a pipe.
        FILETYPE_PIPE => 5,
        # a file is a symbolic link
        FILETYPE_LNK => 6,
        # a file is a [unix domain] socket.
        FILETYPE_SOCK => 7,
        # a file is of some other unknown type or the type cannot be determined.
        FILETYPE_UNKFILE => 127,
    };
    our %EXPORT_TAGS = ( all => [qw( FILETYPE_NOFILE FILETYPE_REG FILETYPE_DIR FILETYPE_CHR FILETYPE_BLK FILETYPE_PIPE FILETYPE_LNK FILETYPE_SOCK FILETYPE_UNKFILE )] );
    our @EXPORT_OK = qw( FILETYPE_NOFILE FILETYPE_REG FILETYPE_DIR FILETYPE_CHR FILETYPE_BLK FILETYPE_PIPE FILETYPE_LNK FILETYPE_SOCK FILETYPE_UNKFILE );
    our $VERSION = 'v0.3.3';
};

use strict;
no warnings 'redefine';

sub init
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No file provided to instantiate a ", ref( $self ), " object." ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{filepath} = $file;
    $self->{_data} = [CORE::stat( $file )];
    return( $self );
}

sub atime
{
    my $self = shift( @_ );
    my $t;
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    $t = $data->[ FINFO_ATIME ];
    return( $self->_datetime( $t ) );
}

sub blksize { return( shift->block_size( @_ ) ); }

sub block_size
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    return( $self->new_number( $data->[ FINFO_BLOCK_SIZE ] ) );
}

sub blocks
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    return( $self->new_number( $data->[ FINFO_BLOCKS ] ) );
}

sub can_read { return( -r( shift->filepath ) ); }

sub can_write { return( -w( shift->filepath ) ); }

sub can_exec { return( -x( shift->filepath ) ); }

sub can_execute { return( -x( shift->filepath ) ); }

sub csize { return( shift->size ); }

sub ctime
{
    my $self = shift( @_ );
    my $t;
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    $t = $data->[ FINFO_CTIME ];
    return( $self->_datetime( $t ) );
}

sub dev { return( shift->device( @_ ) ); }

sub device
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    return( $self->new_number( $data->[ FINFO_DEV ] ) );
}

sub exists { return( shift->filetype == FILETYPE_NOFILE ? 0 : 1 ); }

## Read-only
sub filepath { return( shift->_set_get_scalar( 'filepath' ) ); }

sub filetype
{
    my $self = shift( @_ );
    my $file = $self->{filepath};
    CORE::stat( $file );
    if( !-e( _ ) )
    {
        return( FILETYPE_NOFILE );
    }
    elsif( -f( _ ) )
    {
        return( FILETYPE_REG );
    }
    elsif( -d( _ ) )
    {
        return( FILETYPE_DIR );
    }
    elsif( -l( _ ) )
    {
        return( FILETYPE_LNK );
    }
    elsif( -p( _ ) )
    {
        return( FILETYPE_PIPE );
    }
    elsif( -S( _ ) )
    {
        return( FILETYPE_SOCK );
    }
    elsif( -b( _ ) )
    {
        return( FILETYPE_BLK );
    }
    elsif( -c( _ ) )
    {
        return( FILETYPE_CHR );
    }
    else
    {
        return( FILETYPE_UNKFILE );
    }
}

sub fname
{
    my $self = shift( @_ );
    return( $self->{filepath} );
}

sub gid
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    return( $self->new_number( $data->[ FINFO_GID ] ) );
}

sub group
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    # perlport: "getgrgid: (Win32, VMS, RISC OS) Not implemented."
    return( $self->gid ) if( $^O =~ /^(win32|vms|riscos)$/i );
    my $name = scalar( getgrgid( $data->[ FINFO_GID ] ) );
    return( $self->new_scalar( scalar( getgrgid( $data->[ FINFO_GID ] ) ) ) );
}

sub ino { return( shift->inode( @_ ) ); }

sub inode
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    return( $self->new_number( $data->[ FINFO_INODE ] ) );
}

sub is_block { return( shift->filetype == FILETYPE_BLK ); }

sub is_char { return( shift->filetype == FILETYPE_CHR ); }

sub is_dir { return( shift->filetype == FILETYPE_DIR ); }

sub is_file { return( shift->filetype == FILETYPE_REG ); }

sub is_link { return( shift->filetype == FILETYPE_LNK ); }

sub is_pipe { return( shift->filetype == FILETYPE_PIPE ); }

sub is_socket { return( shift->filetype == FILETYPE_SOCK ); }

sub mime_type
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    try
    {
        if( $HAS_FILE_MMAGIC_XS )
        {
            my $m = File::MMagic::XS->new;
            return( $self->new_scalar( $m->get_mime( $file ) ) );
        }
        else
        {
            require File::MMagic;
            my $m = File::MMagic->new;
            return( $self->new_scalar( $m->checktype_filename( $file ) ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while trying to get the mime type for file \"", $self->filepath, "\": $e" ) );
    }
}

sub mode
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    return( $self->new_number( $data->[ FINFO_MODE ] & 07777 ) );
}

sub mtime
{
    my $self = shift( @_ );
    my $t;
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    $t = $data->[ FINFO_MTIME ];
    return( $self->_datetime( $t ) );
}

sub name { return( File::Basename::basename( shift->fname ) ); }

sub nlink
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    return( $self->new_number( $data->[ FINFO_NLINK ] ) );
}

sub protection
{
    my $self = shift( @_ );
    my @stat = CORE::stat( $self->filepath );
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @stat ) );
    return( $self->new_number( hex( sprintf( '%04o', $stat[2] & 07777 ) ) ) );
}

sub rdev
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    return( $self->new_number( $data->[ FINFO_RDEV ] ) );
}

sub reset
{
    my $self = shift( @_ );
    my $file = $self->filepath;
    $self->{_data} = [CORE::stat( $file )];
    return( $self );
}

sub size
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    return( $self->new_number( $data->[ FINFO_SIZE ] ) );
}

sub stat
{
    my $self = shift( @_ );
    my $file = shift( @_ );
    my $p = scalar( @_ ) ? { @_ } : {};
    return( $self->new( $file, $p ) );
}

sub uid
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    return( $self->new_number( $data->[ FINFO_UID ] ) );
}

sub user
{
    my $self = shift( @_ );
    my $data = $self->{_data};
    return( want( 'OBJECT' ) ? Module::Generic::Null->new : '' ) if( !scalar( @$data ) );
    # perlport: "getpwuid: (Win32) Not implemented. (RISC OS) Not useful.
    return( $self->uid ) if( $^O =~ /^(win32|riscok)/i );
    return( $self->new_scalar( scalar( getpwuid( $data->[ FINFO_UID ] ) ) ) );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
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

sub TO_JSON { CORE::return( CORE::shift->filepath ); }

sub _datetime
{
    my $self = shift( @_ );
    my $t = shift( @_ );
    return( $self->error( "No epoch time was provided." ) ) if( !length( $t ) );
    return( $self->error( "Invalid epoch time provided \"$t\"." ) ) if( $t !~ /^\d+$/ );
    my $class = ref( $self ) || $self;
    try
    {
        require DateTime;
        require DateTime::Format::Strptime;
        require Module::Generic::DateTime;
        my $dt;
        if( !defined( $HAS_LOCAL_TZ ) )
        {
            try
            {
                $dt = DateTime->from_epoch( epoch => $t, time_zone => 'local' );
                $HAS_LOCAL_TZ = 1;
            }
            catch( $e )
            {
                $HAS_LOCAL_TZ = 0;
                warn( "Your system is missing key timezone components. ${class}::_datetime is reverting to UTC instead of local time zone.\n" );
                $dt = DateTime->from_epoch( epoch => $t, time_zone => 'UTC' );
            }
        }
        else
        {
            try
            {
                $dt = DateTime->from_epoch( epoch => $t, time_zone => ( $HAS_LOCAL_TZ ? 'local' : 'UTC' ) );
            }
            catch( $e )
            {
                warn( "Error trying to set a DateTime object using ", ( $HAS_LOCAL_TZ ? 'local' : 'UTC' ), " time zone\n" );
                $dt = DateTime->from_epoch( epoch => $t, time_zone => 'UTC' );
            }
        }
        
        my $fmt = DateTime::Format::Strptime->new(
            pattern => '%s',
        );
        $dt->set_formatter( $fmt );
        my $o = Module::Generic::DateTime->new( $dt ) ||
            return( $self->pass_error( Module::Generic::DateTime->error ) );
        return( $o );
    }
    catch( $e )
    {
        return( $self->error( "Unable to get the datetime object for \"$t\": $e" ) );
    }
}

# Credits: IPC::SysV <https://metacpan.org/release/JACKS/IPC_SysV>
sub mode_s2n
{
    my $mode = shift( @_ );

    # Just in case its a number already
    $mode =~ /^\d+$/ && return( $mode + 0 );

    $mode =~ /^([r\-])([w\-])\-([r\-])([w\-])\-([r\-])([w\-])\-$/ || return;

    my $n_mode = 0;
    $n_mode |= 00400 if( $1 eq 'r' );
    $n_mode |= 00200 if( $2 eq 'w' );
    $n_mode |= 00040 if( $3 eq 'r' );
    $n_mode |= 00020 if( $4 eq 'w' );
    $n_mode |= 00004 if( $5 eq 'r' );
    $n_mode |= 00002 if( $6 eq 'w' );
    return( $n_mode );
}

sub mode_n2s
{
    my $n_mode = shift( @_ );

    # Just in case its a string already
    $n_mode =~ /^[r\-][w\-]\-[r\-][w\-]\-[r\-][w\-]\-$/ && return( $n_mode );

    $n_mode =~ /^\d+$/ || return;

    my $mode = '';
    $mode .= ( $n_mode & 00400 ) ? 'r' : '-';
    $mode .= ( $n_mode & 00200 ) ? 'w' : '-';
    $mode .= '-';
    $mode .= ( $n_mode & 00040 ) ? 'r' : '-';
    $mode .= ( $n_mode & 00020 ) ? 'w' : '-';
    $mode .= '-';
    $mode .= ( $n_mode & 00004 ) ? 'r' : '-';
    $mode .= ( $n_mode & 00002 ) ? 'w' : '-';
    $mode .= '-';
    return( $mode );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::Finfo - File Info Object Class

=head1 SYNOPSIS

    use Module::Generic::Finfo qw( :all );
    my $finfo = Module::Generic::Finfo->new( '/some/file/path.html' );
    # Get access time as a DateTime object
    $finfo->atime;
    # Block site
    $finfo->blksize;
    # Number of blocks
    $finfo->blocks;
    if( $finfo->can_read )
    {
        # Do something
    }
    # Can also use
    $finfo->can_write;
    $finfo->can_exec;
    $finfo->csize;
    # Inode change time as a DateTime object
    $finfo->ctime;
    $finfo->dev;
    if( $finfo->exists )
    {
        # Do something
    }
    print "File path is: ", $finfo->filepath;
    if( $finfo->filetype == FILETYPE_NOFILE )
    {
        # File does not exist
    }
    # Same as $finfo->filepath
    print "File path is: ", $finfo->fname;
    print "File group id is: ", $finfo->gid;
    # Can also use $finfo->group which will yield the same result
    $finfo->ino;
    # or $finfo->inode;
    if( $finfo->is_block )
    {
        # Do something
    }
    elsif( $finfo->is_char )
    {
        # Do something else
    }
    elsif( $finfo->is_dir )
    {
        # It's a directory
    }
    elsif( $finfo->is_file )
    {
        # It's a regular file
    }
    elsif( $finfo->is_link )
    {
        # A file alias
    }
    elsif( $info->is_pipe )
    {
        # A Unix pipe !
    }
    elsif( $finfo->is_socket )
    {
        # It's a socket
    }
    elsif( ( $info->mode & 0100 ) )
    {
        # Can execute
    }
    $finfo->mtime->strftime( '%A %d %B %Y %H:%m:%S' );
    print "File base name is: ", $finfo->name;
    printf "File has %d links\n", $finfo->nlink;
    print "File permission in hexadecimal: ", $finfo->protection;
    $finfo->rdev;
    $finfo->size;
    my $new_object = $finfo->stat( '/some/other/file.txt' );
    # Get the user id
    $finfo->uid;
    # Or
    $finfo->user;

=head1 VERSION

    v0.3.3

=head1 DESCRIPTION

This class provides a file info object oriented api.

The other advantage is that even if a non-existing file is provided, an object is returned. Obviously many of this module's methods will return an empty value since the file does not actually exist.

=head1 METHODS

=head2 new

This instantiate an object that is used to access other key methods. It takes a file path.:

=head2 atime

Returns the file last access time as a L<Module::Generic::DateTime> object, which stringifies to its value in second since epoch. L<Module::Generic::DateTime> is just a thin wrapper around L<DateTime> to allow a L<DateTime> to be used in comparison with another non L<DateTime> value.

For example:

    if( $finfo->atime > time() + 86400 )
    {
        print( "You are traveling in the future\n" );
    }

=head2 blksize

Returns the preferred I/O size in bytes for interacting with the file.
You can also use C<block_size>.

=head2 block_size

Alias for L</blksize>

=head2 blocks

Returns the actual number of system-specific blocks allocated on disk (often, but not always, 512 bytes each).

=head2 can_read

Returns true if the the effective user can read the file.

=head2 can_write

Returns true if the the effective user can write to the file.

=head2 can_exec

Returns true if the the effective user can execute the file. Same as L</execute>

=head2 can_execute

Returns true if the the effective user can execute the file. Same as L</exec>

=head2 csize

Returns the total size of file, in bytes. Same as L</size>

=head2 ctime

Returns the file inode change time as a L<Module::Generic::DateTime> object, which stringifies to its value in second since epoch. L<Module::Generic::DateTime> is just a thin wrapper around L<DateTime> to allow a L<DateTime> to be used in comparison with another non L<DateTime> value.

=head2 dev

Returns the device number of filesystem. Same as L</dev>

=head2 device

Returns the device number of filesystem. Same as L</device>

=head2 exists

Returns true if the filetype is not L</FILETYPE_NOFILE>

=head2 filepath

Returns the file path as a string. Same as L</fname>

=head2 filetype

Returns the file type which is one of the L</CONSTANTS> below.

=head2 fname

Returns the file path as a string. Same as L</filepath>

=head2 gid

Returns the numeric group ID of file's owner. Same as L</group>

=head2 group

Returns the numeric group ID of file's owner. Same as L</gid>

=head2 ino

Alias for L</ino>

=head2 inode

Returns the inode number.

=head2 is_block

Returns true if this is a block file, false otherwise.

=head2 is_char

Returns true if this is a character file, false otherwise.

=head2 is_dir

Returns true if this is a directory, false otherwise.

=head2 is_file

Returns true if this is a regular file, false otherwise.

=head2 is_link

Returns true if this is a symbolic link, false otherwise.

=head2 is_pipe

Returns true if this is a pipe, false otherwise.

=head2 is_socket

Returns true if this is a socket, false otherwise.

=head2 mime_type

This guesses the file mime type and returns it as a L<scalar object|Module::Generic::Scalar>

If L<File::MMagic::XS> is installed, it will use it, otherwise, it will use L<File::MMagic>

=head2 mode

Returns the file mode. This is equivalent to the mode & 07777, ie without the file type bit.

So you could do something like:

    if( $finfo->mode & 0100 )
    {
        print( "Owner can execute\n" );
    }
    if( $finfo->mode & 0001 )
    {
        print( "Everyone can execute too!\n" );
    }

=head2 mode_n2s

Returns the file or directory mode as human readable string

=head2 mode_s2n

Takes a string and convert it into octal mode.

=head2 mtime

Returns the file last modify time as a L<Module::Generic::DateTime> object, which stringifies to its value in second since epoch. L<Module::Generic::DateTime> is just a wrapper around L<DateTime> to allow a L<DateTime> to be used in comparison with another non L<DateTime> value.

=head2 name

Returns the file base name. So if the file is C</home/john/www/some/file.html> this would return C<file.html>

Interesting to note that L<APR::Finfo/name> which is advertised as returning the file base name, actually returns just an empty string. With this module, this uses a workaround to provide the proper value. It use L<File::Basename/basename> on the value returned by L</fname>

=head2 nlink

Returns the number of (hard) links to the file.

=head2 protection

=head2 rdev

Returns the device identifier (special files only).

=head2 reset

Force L<Module::Generic::Finfo> to reload the filesystem information of the underlying file or directory

=head2 size

Returns the total size of file, in bytes. Same as L</csize>

=head2 stat

Provided with a file path and this returns a new L<Module::Generic::Finfo> object.

=head2 user

Returns the numeric user ID of file's owner. Same as L</uid>

=head2 uid

Returns the numeric user ID of file's owner. Same as L</user>

=head1 CONSTANTS

=head2 FILETYPE_NOFILE

File type constant to indicate the file does not exist.

=head2 FILETYPE_REG

Regular file

=head2 FILETYPE_DIR

The element is a directory

=head2 FILETYPE_CHR

The element is a character block

=head2 FILETYPE_BLK

A block device

=head2 FILETYPE_PIPE

The file is a FIFO or a pipe

=head2 FILETYPE_LNK

The file is a symbolic link

=head2 FILETYPE_SOCK

The file is a (unix domain) socket

=head2 FILETYPE_UNKFILE

The file is of some other unknown type or the type cannot be determined

=head1 SERIALISATION

=for Pod::Coverage FREEZE

=for Pod::Coverage STORABLE_freeze

=for Pod::Coverage STORABLE_thaw

=for Pod::Coverage THAW

=for Pod::Coverage TO_JSON

Serialisation by L<CBOR|CBOR::XS>, L<Sereal> and L<Storable::Improved> (or the legacy L<Storable>) is supported by this package. To that effect, the following subroutines are implemented: C<FREEZE>, C<THAW>, C<STORABLE_freeze> and C<STORABLE_thaw>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

L<https://gitlab.com/jackdeguest/Module-Generic>

=head1 SEE ALSO

L<Module::Generic::File>, L<Module::Generic>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
