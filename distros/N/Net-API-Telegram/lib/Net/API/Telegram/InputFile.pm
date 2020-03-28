# -*- perl -*-
##----------------------------------------------------------------------------
## Telegram API - ~/lib/Net/API/Telegram/InputFile.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2019/10/31
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::InputFile;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
	use File::Basename;
	use File::Copy ();
	use Cwd ();
	use File::Type;
	use Scalar::Util;
    our( $VERSION ) = '0.1';
	use Devel::Confess;
};

sub init
{
	my $self = shift( @_ );
	my $init = shift( @_ );
	return( $self->error( sprintf( "Wrong number of parameters. I found %d, but am expecting an odd number.", scalar( @_ ) ) ) ) if( !( scalar( @_ ) % 2 ) );
	my $this = shift( @_ ) || return( $self->error( "No file content or file path was provided." ) );
	$self->SUPER::init( $init );
	$self->{content}	= '';
	$self->{file}		= '';
	$self->{filename}	= '';
	if( ref( $this ) eq 'SCALAR' )
	{
		$self->{content} = $$this;
	}
	elsif( Scalar::Util::blessed( $this ) )
	{
		return( $self->error( "Do not know what to do with this object \"", ref( $this ), "\". If an object is provided, it should be a Net::API::Telegram::InputFile object." ) ) if( !$this->isa( 'Net::API::Telegram::InputFile' ) );
		$self->{content} = $this->{content} if( $this->{content} );
		$self->{file} = $this->{file} if( $this->{file} );
		$self->{filename} = $this->{filenme} if( $this->{filename} );
		return( $self->error( "The object provided has no file name or file content." ) ) if( !$this->{file} && !length( $this->{content} ) );
	}
	else
	{
		$self->{file} = $this;
	}
	return( $self );
}

sub content
{
	my $self = shift( @_ );
	if( @_ )
	{
		$self->{content} = shift( @_ );
	}
	return( $self->{content} ) if( length( $self->{content} ) );
	if( $self->{file} )
	{
		my $ct = $self->_load_file( $self->{file} ) || return( $self->error( "Unable to load file \"$self->{file}\": $!" ) );
		$self->{content} = $ct;
		return( $ct );
	}
	return;
}

sub file
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $file = shift( @_ );
		return( $self->error( "File provided \"$file\" does not exist." ) ) if( !-e( $file ) );
		return( $self->error( "File provided \"$file\" is empty." ) ) if( !-z( $file ) );
		return( $self->error( "File provided \"$file\" is not a file." ) ) if( !-f( $file ) );
		return( $self->error( "File provided \"$file\" is not readable." ) ) if( !-r( $file ) );
		my( $dir, $base, $suffix ) = File::Basename::fileparse( $file, qr/\.[^\.]+$/ );
		$self->{filename} = "${base}${suffix}" if( !length( $self->{filename} ) );
		$self->{file} = $file;
	}
	return( $self->{file} );
}

sub filename { return( shift->_set_get( 'filename', @_ ) ); }

sub length
{
	my $self = shift( @_ );
	return( length( $self->{content} ) ) if( $self->{content} );
	return( -s( $self->{file} ) ) if( $self->{file} );
	return( 0 );
}

sub save_as
{
	my $self = shift( @_ );
	my $path = shift( @_ ) || return( $self->error( "No file path to save as was provided." ) );
	$path = Cwd::abs_path( $path );
	return( $self->error( "No file or file content set to save." ) ) if( !$self->{file} && !length( $self->{content} ) );
	my( $dir, $base, $suffix ) = File::Basename::fileparse( $path, qr/\.[^\.]+$/ );
	return( $self->error( "File directory \"$path\" does not exist." ) ) if( !-e( $dir ) );
	return( $self->error( "File directory \"$path\" exists, but it is not a directory." ) ) if( !-d( $dir ) );
	return( $self->error( "File directory \"$path\" is not accessible. Not enoug permission to enter it." ) ) if( !-x( $dir ) );
	if( $self->{content} )
	{
		my $fh = IO::File->new( ">$path" ) || return( $self->error( "Unable to open file \"$path\" in write mode: $!" ) );
		$fh->binmode;
		$fh->autoflush( 1 );
		$fh->print( $self->{content} ) || return( $self->error( sprintf( "Unable to write %d bytes of data into file \"$path\": $!", length( $self->{content} ) ) ) );
		$fh->close;
	}
	elsif( $self->{file} )
	{
		return( $self->error( "Source and target file \"$path\" are identical." ) ) if( $path eq $self->{file} );
		File::Copy::copy( $self->{file}, $path ) ||
		return( $self->error( "Unable to copy file \"$self->{file}\" to \"$path\": #!" ) );
	}
}

sub type
{
	my $self = shift( @_ );
	my $t = File::Type->new;
	if( $self->{content} )
	{
		return( $t->mime_type( $self->{content} ) );
	}
	elsif( $self->{file} )
	{
		return( $t->mime_type( $self->{file} ) );
	}
	else
	{
		## Return empty, not undef
		return( '' );
	}
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::InputFile - The contents of a file to be uploaded

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::InputFile->new( %data ) || 
	die( Net::API::Telegram::InputFile->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::InputFile> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#inputfile>

=head1 METHODS

=over 4

=item B<new>( {INIT HASH REF}, SCALAR REF | FILE PATH, %PARAMETERS )

B<new>() will create a new object for the package, pass any argument it might receive
to the special standard routine B<init> that I<must> exist. 
It takes one mandatory parameter which is either a scalar for raw data or a file path.

Then it returns what returns B<init>().

The valid parameters are as follow. Methods available here are also parameters to the B<new> method.

=over 8

=item * I<verbose>

=item * I<debug>

=back

=item B<content>( [ DATA ] )

Set or get the raw data for this object.

If no data was set, but a I<file> was set then this will read the file and return its content.

It returns the current content set.

=item B<file>( [ FILE PATH ] )

Set or get the file path of the file for this object.

This method will perform some basic sanitary checks on the accessibility of the given file path, and its permissions and return error if the file has problems.

It returns the current file set.

=item B<save_as>( FILE PATH )

Given a file path, this method will save the content of the file in this object to the specified file path.

Before doing so, this method will perform some sanity check on the parent directory to ensure the action can actually be done. It will return an error if problems were found.

=back

=head1 COPYRIGHT

Copyright (c) 2000-2019 DEGUEST Pte. Ltd.

=head1 CREDITS

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::Telegram>

=cut

