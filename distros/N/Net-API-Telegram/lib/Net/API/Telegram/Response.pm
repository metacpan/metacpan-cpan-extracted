# -*- perl -*-
##----------------------------------------------------------------------------
## Telegram API - ~/lib/Net/API/Telegram/Response.pm
## Version 0.2
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2019/06/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::Response;
BEGIN
{
	use strict;
	use HTTP::Status ();
	use IO::File;
    our( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
    our( $VERBOSE, $DEBUG );
    @ISA         = qw( Module::Generic );
    @EXPORT      = qw( );
    %EXPORT_TAGS = ();
    @EXPORT_OK   = qw( );
    $VERSION     = '0.2';
	use Devel::Confess;
};

{
	## https://core.telegram.org/bots/api
	$DEBUG = 3;
	$VERBOSE = 0;
}

sub init
{
	my $self = shift( @_ );
	my $resp = shift( @_ ) || return( $self->error( "No server response was provided." ) );
	return( $self->error( "Object provided ($resp) is not a HTTP::Response object." ) ) if( !UNIVERSAL::isa( $resp, 'HTTP::Response' ) );
	$self->{ 'data' }  = '';
	$self->SUPER::init( @_ );
	if( !$self->{ 'data' } )
	{
		$self->{ 'data' } = $self->data2json( $resp->decoded_content ) || 
		return( $self->error( "Unable to parse the json data received from server: ", $self->error ) );
	}
	$self->{ 'resp' } = $resp;
	return( $self );
}

sub data2json
{
	my $self = shift( @_ );
	my $data = shift( @_ );
	my $unescape = shift( @_ );
	return( $self->error( "No data provided to decode into json." ) ) if( !length( $data ) );
	if( $unescape )
	{
		$data =~ s/\\\\r\\\\n/\n/gs;
		$data =~ s/^\"|\"$//gs;
		$data =~ s/\"\[|\]\"//gs;
	}
	my $json;
	eval
	{
		local $SIG{ '__WARN__' } = sub{ };
		local $SIG{ '__DIE__' } = sub{ };
		$json = $self->{ 'json' }->decode( $data );
	};
	if( $@ )
	{
		my $fh = File::Temp->new( SUFFIX => '.js' );
		my $file = $fh->filename;
		my $io = IO::File->new( ">$file" ) || return( $self->error( "Unable to write to file $file: $!" ) );
		$io->binmode( ":utf8" );
		$io->autoflush( 1 );
		$io->print( $data ) || return( $self->error( "Unable to write data to json file $file: $!" ) );
		$io->close;
		chmod( 0666, $file );
		return( $self->error( sprintf( "An error occured while attempting to parse %d bytes of data into json: $@\nFailed raw data was saved in file $file", length( $data ) ) ) );
	}
	return( $json );
}

1;

__END__
