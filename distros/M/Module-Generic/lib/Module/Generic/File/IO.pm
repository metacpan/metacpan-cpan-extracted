##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/File/IO.pm
## Version v0.1.3
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/04/26
## Modified 2022/11/12
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::File::IO;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use Fcntl;
    use IO::File ();
    use parent qw( Module::Generic IO::File );
    use vars qw( $VERSION @EXPORT $THAW_REOPENS_FILE );
    # use Nice::Try;
    use Scalar::Util ();
    use Want;
    our @EXPORT = grep( /^(?:O_|F_GETFL|F_SETFL)/, @Fcntl::EXPORT );
    push( @EXPORT, @{$Fcntl::EXPORT_TAGS{flock}}, @{$Fcntl::EXPORT_TAGS{seek}} );
    our @EXPORT_OK = qw( wraphandle );
    our $THAW_REOPENS_FILE = 1;
    our $VERSION = 'v0.1.3';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $class = ( ref( $this ) || $this );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $args = [@_];
    my $self;
    # try-catch
    local $@;
    eval
    {
        $self = $class->IO::File::new( @_ );
    };
    if( $@ )
    {
        return( $this->error( "Error trying to open file \"", $_[0], "\" with arguments: '", join( "', '", @_[1..$#_] ), "': $@" ) );
    }
    $self or return( $this->error( "Unable to open file \"", $_[0], "\" with arguments: '", join( "', '", @_[1..$#_] ), "': $!" ) );

    if( exists( $opts->{fileno} ) &&
        defined( $opts->{fileno} ) &&
        length( $opts->{fileno} ) )
    {
        my $fileno = CORE::delete( $opts->{fileno} );
        # > +<, etc and r, w, r+
        my $mode = 'r';
        $mode = CORE::delete( $opts->{mode} ) if( exists( $opts->{mode} ) && defined( $opts->{mode} ) && length( $opts->{mode} ) );
        my $rv;
        # try-catch
        local $@;
        eval
        {
            $rv = $self->fdopen( $fileno, $mode );
        };
        if( $@ )
        {
            return( $this->error( "Error trying to open file \"", $_[0], "\" with arguments: '", join( "', '", @_[1..$#_] ), "': $@" ) );
        }
        $rv or return( $this->error( "Unable to fdopen using file descriptor ${fileno} and mode ${mode}: $!" ) );
    }
    
    *$self = { args => $args };
    if( Want::want( 'OBJECT' ) )
    {
        return( $self->init( $opts ) );
    }
    my $new = $self->init( @_ );
    if( !defined( $new ) )
    {
        # If we are called on an object, we hand it the error so the caller can check it using the object:
        # my $new = $old->new || die( $old->error );
        if( $self->_is_object( $this ) && $this->can( 'pass_error' ) )
        {
            return( $this->pass_error( $self->error ) );
        }
        else
        {
            return( $self->pass_error );
        }
    };
    return( $new );
}

sub init
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    *$self->{_init_strict_use_sub} = 1;
    $self->Module::Generic::init( $opts ) || return( $self->pass_error );
    return( $self );
}

sub args
{
    my $self = shift( @_ );
    return( *$self->{args} );
}

# This class does not convert to an HASH
sub as_hash { return( $_[0] ); }

sub autoflush { return( shift->_filehandle_method( 'autoflush', @_ ) ); }

sub binmode { return( shift->_filehandle_method( 'binmode', @_ ) ); }

sub blocking { return( shift->_filehandle_method( 'blocking', @_ ) ); }

sub can_read
{
    my $self = shift( @_ );
    my $dummy = 0;
    my $flags = $self->fcntl( F_GETFL, $dummy );
    return( $self->error( $! ) ) if( !defined( $flags ) );
    return(1) if( ( $flags & O_RDWR ) );
    return(1) if( ( $flags & O_RDONLY ) == O_RDONLY );
    # or, extracting the mode from the bits
    # return(1) if( !( $flags & O_ACCMODE ) );
    return(0);
}

sub can_write
{
    my $self = shift( @_ );
    my $dummy = 0;
    my $flags = $self->fcntl( F_GETFL, $dummy );
    return( $self->error( $! ) ) if( !defined( $flags ) );
    return( $flags & ( O_APPEND | O_WRONLY | O_CREAT | O_RDWR ) );
}

sub close { return( shift->_filehandle_method( 'close', @_ ) ); }

# sub constant { return( shift->_filehandle_method( 'constant', @_ ) ); }

sub eof { return( shift->_filehandle_method( 'eof', @_ ) ); }

# sub fcntl { return( shift->_filehandle_method( 'fcntl', @_ ) ); }
sub fcntl
{
    my $self = shift( @_ );
    return( $self->error( 'usage: $io->fcntl( OP, VALUE );' ) ) if( scalar( @_ ) != 2 );
    my( $op, $value ) = @_;
    my $rv;
    # try-catch
    local $@;
    eval
    {
        $rv = CORE::fcntl( *$self, $op, $value );
    };
    if( $@ )
    {
        return( $self->error( "An unexpected error occurred while trying to call fcntl with function '$op' and value '$value': $@" ) );
    }
    return( $rv );
}

sub fdopen { return( shift->_filehandle_method( 'fdopen', @_ ) ); }

sub fileno { return( shift->_filehandle_method( 'fileno', @_ ) ); }

sub flags
{
    my $self = shift( @_ );
    my $dummy;
    # return( $self->fcntl( F_GETFL, $dummy ) );
    return( CORE::fcntl( *$self, F_GETFL, $dummy ) );
}

sub flush { return( shift->_filehandle_method( 'flush', @_ ) ); }

sub format_formfeed { return( shift->_filehandle_method( 'format_formfeed', @_ ) ); }

sub format_line_break_characters { return( shift->_filehandle_method( 'format_line_break_characters', @_ ) ); }

sub format_lines_left { return( shift->_filehandle_method( 'format_lines_left', @_ ) ); }

sub format_lines_per_page { return( shift->_filehandle_method( 'format_lines_per_page', @_ ) ); }

sub format_name { return( shift->_filehandle_method( 'format_name', @_ ) ); }

sub format_page_number { return( shift->_filehandle_method( 'format_page_number', @_ ) ); }

sub format_top_name { return( shift->_filehandle_method( 'format_top_name', @_ ) ); }

sub format_write { return( shift->_filehandle_method( 'format_write', @_ ) ); }

sub formline { return( shift->_filehandle_method( 'formline', @_ ) ); }

sub getc { return( shift->_filehandle_method( 'getc', @_ ) ); }

sub getline { return( shift->_filehandle_method( 'getline', @_ ) ); }

sub getlines { return( shift->_filehandle_method( 'getlines', @_ ) ); }

sub getpos { return( shift->_filehandle_method( 'getpos', @_ ) ); }

sub input_line_number { return( shift->_filehandle_method( 'input_line_number', @_ ) ); }

sub input_record_separator { return( shift->_filehandle_method( 'input_record_separator', @_ ) ); }

sub ioctl { return( shift->_filehandle_method( 'ioctl', @_ ) ); }

sub new_from_fd { return( shift->_filehandle_method( 'new_from_fd', @_ ) ); }

sub new_tmpfile { return( shift->_filehandle_method( 'new_tmpfile', @_ ) ); }

sub opened { return( shift->_filehandle_method( 'opened', @_ ) ); }

sub output_field_separator { return( shift->_filehandle_method( 'output_field_separator', @_ ) ); }

sub output_record_separator { return( shift->_filehandle_method( 'output_record_separator', @_ ) ); }

sub print { return( shift->_filehandle_method( 'print', @_ ) ); }

sub printf { return( shift->_filehandle_method( 'printf', @_ ) ); }

sub printflush { return( shift->_filehandle_method( 'printflush', @_ ) ); }

sub read { return( shift->_filehandle_method( 'read', @_ ) ); }

sub say { return( shift->_filehandle_method( 'say', @_ ) ); }

sub seek { return( shift->_filehandle_method( 'seek', @_ ) ); }

sub setpos { return( shift->_filehandle_method( 'setpos', @_ ) ); }

sub stat { return( shift->_filehandle_method( 'stat', @_ ) ); }

sub sync { return( shift->_filehandle_method( 'sync', @_ ) ); }

sub sysread { return( shift->_filehandle_method( 'sysread', @_ ) ); }

sub sysseek { return( shift->_filehandle_method( 'sysseek', @_ ) ); }

sub syswrite { return( shift->_filehandle_method( 'syswrite', @_ ) ); }

sub tell { return( shift->_filehandle_method( 'tell', @_ ) ); }

sub truncate { return( shift->_filehandle_method( 'truncate', @_ ) ); }

sub ungetc { return( shift->_filehandle_method( 'ungetc', @_ ) ); }

sub untaint { return( shift->_filehandle_method( 'untaint', @_ ) ); }

sub wraphandle
{
    my( $this, $mode ) = @_;
    my $fileno;
    if( Scalar::Util::blessed( $this ) &&
        $this->can( 'fileno' ) )
    {
        $fileno = $this->fileno;
    }
    else
    {
        $fileno = CORE::fileno( $this );
    }
    
    if( !defined( $fileno ) )
    {
        warn( "Cannot get a file descriptor from the filehandle (${this}) provided.\n" );
        return;
    }
    my $io = Module::Generic::File::IO->new( { 'fileno' => $fileno } ) || do
    {
        warn( Module::Generic::File::IO->error );
        return;
    };
    return( $io );
}

sub write { return( shift->_filehandle_method( 'write', @_ ) ); }

sub _filehandle_method
{
    my $self = shift( @_ );
    # e.g. print, printf, seek, tell, rewinddir, close, etc
    my $what = shift( @_ );
    my @rv = ();
    my $ref = IO::File->can( $what ) ||
        return( $self->error( "Method '$what' is unsupported." ) );
    no warnings 'uninitialized';
    if( wantarray() )
    {
        local $@;
        eval
        {
            @rv = $self->$ref( @_ );
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error occurred while trying to call ${what} in list context: $@" ) );
        }
    }
    else
    {
        local $@;
        eval
        {
            $rv[0] = $self->$ref( @_ );
        };
        if( $@ )
        {
            return( $self->error( "An unexpected error occurred while trying to call ${what}: $@" ) );
        }
    }

    return( $self->error({ skip_frames => 1, message => "Error with $what: $!" }) ) if( CORE::length( $! ) && ( !scalar( @rv ) || !CORE::defined( $rv[0] ) ) );
    $self->clear_error;
    return if( ( wantarray() && !scalar( @rv ) ) || ( !wantarray() && !defined( $rv[0] ) ) );
    return( wantarray() ? @rv : $rv[0] );
}

sub DESTROY
{
    # NOTE: Storable creates a dummy object as a SCALAR instead of GLOB, so we need to check.
    shift->close if( ( Scalar::Util::reftype( $_[0] ) // '' ) eq 'GLOB' );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self ) || $self;
    my $args = $self->args;
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \@$args] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    CORE::return( $class, \@$args )
}

# NOTE: There cannot be a STORABLE_freeze subroutine, or else Storable would trigger an error "Unexpected object type (8) in store_hook()". So Storable must do it by itself, which means it will die or if $Storable::forgive_me is set to a true value, it will instead create a SCALAR instance of this class containing a string like "You lost GLOB(0x5616db45e4e8)"
# sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }
# 
# sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

# NOTE: STORABLE_freeze_pre_processing called by Storable::Improved
sub STORABLE_freeze_pre_processing
{
    my $self = CORE::shift( @_ );
    my $class = CORE::ref( $self ) || $self;
    my $args = $self->args;
    # We change the glob object into a regular hash-based one to be Storable-friendly
    my $this = CORE::bless( { args => $args, class => $class } => $class );
    CORE::return( $this );
}

sub STORABLE_thaw_post_processing
{
    my $self = CORE::shift( @_ );
    my $args = ( CORE::exists( $self->{args} ) && CORE::ref( $self->{args} ) eq 'ARRAY' )
        ? $self->{args}
        : [];
    my $class = ( CORE::exists( $self->{class} ) && CORE::defined( $self->{class} ) && CORE::length( $self->{class} ) ) 
        ? $self->{class}
        : ( CORE::ref( $self ) || $self );
    # We restore our glob object. Geez that was hard. Not.
    my $obj = $THAW_REOPENS_FILE ? $class->new( @$args ) : $class->new;
    return( $obj );
}

# NOTE: THAW is called by Sereal and CBOR
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    $ref = ( CORE::scalar( @$ref ) && CORE::ref( $ref->[0] ) eq 'ARRAY' ) ? $ref->[0] : [];
    my $new;
    if( $THAW_REOPENS_FILE && CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' )
    {
        $new = $class->new( @$ref );
    }
    else
    {
        $new = $class->new;
    }
    CORE::return( $new );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::File::IO - File IO Object Wrapper

=head1 SYNOPSIS

    use Module::Generic::File::IO;
    my $io = Module::Generic::File::IO->new || 
        die( Module::Generic::File::IO->error, "\n" );
    my $io = Module::Generic::File::IO->new( fileno => $fileno ) || 
        die( Module::Generic::File::IO->error, "\n" );

    use Module::Generic::File::IO qw( wraphandle );
    my $io = wraphandle( $fh );
    my $io = wraphandle( $fh, '>' );

=head1 VERSION

    v0.1.3

=head1 DESCRIPTION

This is a thin wrapper that inherits from L<IO::File> with the purpose of providing a uniform api in conformity with standard api call throughout the L<Module::Generic> modules family and to ensure call to any L<IO::File> will never die, but instead set an L<error|Module::Generic/error> and return C<undef>

Supported methods are rigorously the same as L<IO::File> and L<IO::Handle> on top of all the standard ones from L<Module::Generic>

The IO methods are listed below for convenience, but make sure to check the L<IO::File> documentation for more information.

=head1 CONSTRUCTOR

=head2 new

This instantiates a new L<Module::Generic::File::IO> object and returns it.

It optionally takes the following parameters:

=over 4

=item C<fileno>

A file descriptor. When this is provided, the newly created object will perform a L</fdopen> on the file descriptor provided.

=item C<mode>

A mode which will be used along with C<fileno> to fdopen the file descriptor. Possible values can be C<< < >>, C<< +< >>, C<< >+ >>, C<< +> >>, etc and C<r>, C<r+>, C<w>, C<w+>. C<a> and C<a+>

=back

=head1 FUNCTIONS

=head2 wraphandle

    my $io = Module::Generic::File::IO::wraphandle( $fh, '>' );
    # or
    use Module::Generic::File::IO qw( wraphandle );
    my $io = wraphandle( $fh, '>' );

Provided with a filehandle and an optional mode and this will return a newly created L<Module::Generic::File::IO>

By default, the mode will be '<'

=head1 METHODS

=head2 args

Returns an array reference containing the original arguments passed during object instantiation.

=head2 autoflush

See L<IO::Handle/autoflush> for details

=head2 binmode

See L<IO::File/binmode> for details

=head2 blocking

See L<IO::Handle/blocking> for details

=head2 can_read

Returns true if one can read from this filehandle, or false otherwise.

=head2 can_write

Returns true if one can write from this filehandle, or false otherwise.

=head2 close

See L<IO::Handle/close> for details

=head2 eof

See L<IO::Handle/eof> for details

=head2 fcntl

See L<IO::Handle/fcntl> for details

=head2 fdopen

See L<IO::Handle/fdopen> for details

=head2 fileno

See L<IO::Handle/fileno> for details

=head2 flags

Returns the filehandle flags value using L<perlfunc/fcntl>

=head2 flush

See L<IO::Handle/flush> for details

=head2 format_formfeed

See L<IO::Handle/format_formfeed> for details

=head2 format_line_break_characters

See L<IO::Handle/format_line_break_characters> for details

=head2 format_lines_left

See L<IO::Handle/format_lines_left> for details

=head2 format_lines_per_page

See L<IO::Handle/format_lines_per_page> for details

=head2 format_name

See L<IO::Handle/format_name> for details

=head2 format_page_number

See L<IO::Handle/format_page_number> for details

=head2 format_top_name

See L<IO::Handle/format_top_name> for details

=head2 format_write

See L<IO::Handle/format_write> for details

=head2 formline

See L<IO::Handle/formline> for details

=head2 getc

See L<IO::Handle/getc> for details

=head2 getline

See L<IO::Handle/getline> for details

=head2 getlines

See L<IO::Handle/getlines> for details

=head2 getpos

See L<IO::Seekable/getpos> for details

=head2 input_line_number

See L<IO::Handle/input_line_number> for details

=head2 input_record_separator

See L<IO::Handle/input_record_separator> for details

=head2 ioctl

See L<IO::Handle/ioctl> for details

=head2 new_from_fd

See L<IO::Handle/new_from_fd> for details

=head2 new_tmpfile

See L<IO::File/new_tmpfile> for details

=head2 opened

See L<IO::Handle/opened> for details

=head2 output_field_separator

See L<IO::Handle/output_field_separator> for details

=head2 output_record_separator

See L<IO::Handle/output_record_separator> for details

=head2 print

See L<IO::Handle/print> for details

=head2 printf

See L<IO::Handle/printf> for details

=head2 printflush

See L<IO::Handle/printflush> for details

=head2 read

See L<IO::Handle/read> for details

=head2 say

See L<IO::Handle/say> for details

=head2 seek

See L<IO::Seekable/seek> for details

=head2 setpos

See L<IO::Seekable/setpos> for details

=head2 stat

See L<IO::Handle/stat> for details

=head2 sync

See L<IO::Handle/sync> for details

=head2 sysread

See L<IO::Handle/sysread> for details

=head2 sysseek

See L<IO::Seekable/sysseek> for details

=head2 syswrite

See L<IO::Handle/syswrite> for details

=head2 tell

See L<IO::Seekable/tell> for details

=head2 truncate

See L<IO::Handle/truncate> for details

=head2 ungetc

See L<IO::Handle/ungetc> for details

=head2 untaint

See L<IO::Handle/untaint> for details

=head2 write

See L<IO::Handle/write> for details

=head1 CONSTANTS

L<Module::Generic::File::IO> automatically exports the following constants taken from L<Fcntl>:

=over 4

=item C<O_*>

=item C<F_GETFL>

=item C<F_SETFL>

=item C<LOCK_SH>

=item C<LOCK_EX>

=item C<LOCK_NB>

=item C<LOCK_UN>

=back

See also the manual page for C<fcntl> for more detail about those constants.

=head1 SERIALISATION

=for Pod::Coverage FREEZE

=for Pod::Coverage STORABLE_freeze

=for Pod::Coverage STORABLE_freeze_pre_processing

=for Pod::Coverage STORABLE_thaw_post_processing

=for Pod::Coverage STORABLE_thaw

=for Pod::Coverage THAW

=for Pod::Coverage TO_JSON

Serialisation by L<CBOR|CBOR::XS>, L<Sereal> and L<Storable::Improved> (or the legacy L<Storable>) is supported by this package. To that effect, the following subroutines are implemented: C<FREEZE>, C<THAW>

For C<STORABLE_freeze> and C<STORABLE_thaw>, they are not implemented, because as of version C<3.26> Storable raises an exception without giving any chance to the IO module to return an object representing the deserialised data. So, instead of using L<Storable>, use instead the drop-in replacement L<Storable::Improved>, which addresses and mitigate those issues.

If you use L<Storable::Improved>, then serialisation and deserialisation will work seamlessly.

Failure to do use L<Storable::Improved>, and L<Storable> would instead return the L<Module::Generic::File::IO> as a C<SCALAR> object rather than a glob.

Note that by default C<$THAW_REOPENS_FILE> is set to a true value, and this will have deserialisation recreate an object somewhat equivalent to the original one.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<IO::Handle>, L<IO::File>, L<IO::Seekable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022-2024 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
