##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/File/IO.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/04/26
## Modified 2022/04/26
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
    use vars qw( $VERSION @EXPORT );
    use Nice::Try;
    use Want;
    our @EXPORT = grep( /^(?:O_|F_GETFL|F_SETFL)/, @Fcntl::EXPORT );
    push( @EXPORT, @{$Fcntl::EXPORT_TAGS{flock}}, @{$Fcntl::EXPORT_TAGS{seek}} );
    our $VERSION = 'v0.1.0';
};

sub new
{
    my $this = shift( @_ );
    my $class = ( ref( $this ) || $this );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $self;
    try
    {
        $self = $class->IO::File::new( @_ ) ||
            return( $this->error( "Unable to open file \"", $_[0], "\" with arguments: '", join( "', '", @_[1..$#_] ), "': $!" ) );
    }
    catch( $e )
    {
        return( $this->error( "Error trying to open file \"", $_[0], "\" with arguments: '", join( "', '", @_[1..$#_] ), "': $e" ) );
    }
    *$self = {};
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
    try
    {
        return( CORE::fcntl( *$self, $op, $value ) );
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error occurred while trying to call fcntl with function '$op' and value '$value': $e" ) );
    }
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

sub write { return( shift->_filehandle_method( 'write', @_ ) ); }

sub _filehandle_method
{
    my $self = shift( @_ );
    # e.g. print, printf, seek, tell, rewinddir, close, etc
    my $what = shift( @_ );
    try
    {
        $self->message( 3, "Calling method '$what' with arguments: '", CORE::join( "', '", map( overload::StrVal( $_ ), @_ ) ), "'." );
        my @rv = ();
        my $ref = IO::File->can( $what ) ||
            return( $self->error( "Method '$what' is unsupported." ) );
        if( wantarray() )
        {
            @rv = $self->$ref( @_ );
        }
        else
        {
            $rv[0] = $self->$ref( @_ );
        }
        return( $self->error({ skip_frames => 1, message => "Error with $what: $!" }) ) if( CORE::length( $! ) && ( !scalar( @rv ) || !CORE::defined( $rv[0] ) ) );
        $self->clear_error;
        return if( ( wantarray() && !scalar( @rv ) ) || ( !wantarray() && !defined( $rv[0] ) ) );
        return( wantarray() ? @rv : $rv[0] );
    }
    catch( $e )
    {
        return( $self->error( "An unexpected error occurred while trying to call ${what}: $e" ) );
    }
}

sub DESTROY
{
    shift->close;
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::File::IO - File IO Object Wrapper

=head1 SYNOPSIS

    use Module::Generic::File::IO;
    my $io = Module::Generic::File::IO->new( '/some/file.txt' ) || 
        die( Module::Generic::File::IO->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a thin wrapper that inherits from L<IO::File> with the purpose of providing a uniform api in conformity with standard api call throughout the L<Module::Generic> modules family and to ensure call to any L<IO::File> will never die, but instead set an L<error|Module::Generic/error> and return C<undef>

Supported methods are rigorously the same as L<IO::File> and L<IO::Handle> on top of all the standard ones from L<Module::Generic>

The IO methods are listed below for convenience, but make sure to check the L<IO::File> documentation for more information.

=head1 METHODS

=head2 autoflush

See L<IO::Handle/autoflush> for details

=head2 binmode

See L<IO::File/binmode> for details

=head2 blocking

See L<IO::Handle/blocking> for details

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

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<IO::Handle>, L<IO::File>, L<IO::Seekable>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
