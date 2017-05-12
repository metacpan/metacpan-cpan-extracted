package Net::RRP::Codec;

=head1 NAME

Net::RRP::Codec - codec class for serialization/deserialization of Net::RRP::Request/Response

=head1 SYNOPSIS

 use Net::RRP::RRP::Codec;
 my $codec = new Net::RRP::Codec();

=head1 DESCRIPTION

Net::RRP::Codec - codec class for serialization/deserialization of Net::RRP::Request/Response

=cut

use strict;

use Error qw(:try);

use Net::RRP::Exception;
use Net::RRP::Exception::InvalidCommandName;
use Net::RRP::Exception::InvalidResponseFormat;
$Net::RRP::Codec::VERSION = (split " ", '# 	$Id: Codec.pm,v 1.12 2000/09/30 16:04:41 mkul Exp $	')[3];

use constant CRLF => "\r\n";

=head2 new

Constructor of this class.

Example:

 use Net::RRP::RRP::Codec;
 my $codec = new Net::RRP::Codec();

=cut

sub new
{
    my $class = shift;
    bless {}, $class;
}

=head2 decodeRequest

This method get the buffer with unparsed rrp request && decode it and return Net::RRP::Request object.
The real return object is a instance of Net::RRP::Request::$requestName class. This method dynamic loads 
required class ( package ). Next, we a parse the Entity part of RRP request and construct the instance of
Net::RRP::Entity::$entityName class ( with dynamic loading of this class ) and add entity attributes to 
this object. After this, parser process the rrp request options and add it's to request object. When all 
done, method return a constructed rrp request object. This method say throw() at any errors.

Example:

 my $request = $codec->decodeRequest ( $buffer );

=cut

#'

use constant NAME_SUBSCRIBE => { 'nameserver' => 'NameServer' };

sub decodeRequest
{
    my ( $this, $buffer ) = @_;
    my @lines = split CRLF, $buffer;

    my $requestName = lc ( shift @lines );
    $requestName = NAME_SUBSCRIBE->{$requestName} if NAME_SUBSCRIBE->{$requestName};
    my $requestPackageName = 'Net::RRP::Request::' . ucfirst ( $requestName );
    eval "use $requestPackageName";
    throw Net::RRP::Exception::InvalidCommandName ( $buffer ) if $@;
    my $request = $requestPackageName->new();

    my $entity;

    if ( ( $lines[0] ne '.' ) && ( $lines[0] !~ m/^\-/ ) )
    {
	my $entityLine = shift @lines;
	$entityLine =~ /^EntityName:(.*)/i || throw Net::RRP::Exception::InvalidEntityValue ( $buffer );
	my $entityName = lc ( $1 );
	$entityName = NAME_SUBSCRIBE->{$entityName} if NAME_SUBSCRIBE->{$entityName};
	my $entityPackageName = 'Net::RRP::Entity::' . ucfirst ( $entityName );
	eval "use $entityPackageName";
	throw Net::RRP::Exception::InvalidEntityValue ( $buffer ) if $@;
	$entity = $entityPackageName->new ();
	$request->setEntity ( $entity );
    }

    my ( $index, $line ) = 0;

    while ( ( ( $line = $lines [ $index++ ] ) =~ m/^[^-]/ ) && ( $line ne '.' ) )
    {
	$line =~ m/:/ || throw Net::RRP::Exception::InvalidAttributeValueSyntax ( $buffer );
	my $old = eval { $entity->getAttribute ( $` ); };
	if ( $old )
	{
	    $old = [ $old ] unless ref ( $old );
	    push @$old, $';
	}
	else 
	{
	    $old = $';
	}
	$entity->setAttribute ( $` => $old );
    }

    $index--;

    while  ( ( ( $line = $lines [ $index++ ] ) =~ m/^-/ ) && ( $line ne '.' ) )
    {
	$line =~ m/-(.*?):(.*)/ || throw Net::RRP::Exception::InvalidCommandOption ( $buffer );
	$request->setOption ( $1 => $2 );
    }

    $index--;

    throw Net::RRP::Exception::InvalidCommandSequence ( $buffer ) if ( $lines [ $index ] ne '.' || $#lines > $index );

    $request;
}

=head2

This method encode the rrp request to buffer for send it's to any stream.

Example:

 my $buffer = $codec->encodeRequest ( $request );

=cut

#'

sub encodeRequest
{
    my ( $this, $request ) = @_;
    my $buffer = lc ( $request->getName ) . CRLF;
    my $entity = undef;

    try
    {
	$entity = $request->getEntity;
    }
    catch Net::RRP::Exception with
    {
	my $exception = shift;
	$exception->throw unless $exception->isa ( 'Net::RRP::Exception::MissingRequiredEntity' );
    };

    if ( $entity )
    {
	$buffer .= 'EntityName:' . $entity->getName . CRLF;
	if ( my $attributes = $entity->getAttributes )
	{
	    $buffer .= join ( CRLF, map { my $key = $_;
				      my $value = $attributes->{$key};
				      map { "$key:$_" } @{ ( ref $value ? $value : [ $value ] ) } } keys %$attributes ) . CRLF
					  if ( %$attributes );
	}
    }
    my $options   = $request->getOptions;
    $buffer .= join ( CRLF, map { "-$_:" . $options->{$_} } keys %$options ) . CRLF if ( ( $options ) and ( %$options ) );
    $buffer .= '.' . CRLF;
    $buffer;
}

=head2 decodeResponse

This method constructs the instance of Net::RRP::Response::n$NNN class from input buffer,
where the $NNN is a response number ( the Net::RRP::Response::n$NNN loads dynamic ). This 
method say throw() at any errors;

Example:
my $response = $codec->decodeResponse ( $buffer );

=cut

sub decodeResponse
{
    my ( $this, $buffer ) = @_;

    my @lines = split CRLF, $buffer;

    my $responseHeader = shift @lines;
    $responseHeader =~ /^(\d+) (.+)/ || throw Net::RRP::Exception::InvalidResponseFormat ( $buffer );

    my $responsePackageName = 'Net::RRP::Response::n' . $1;
    eval "use $responsePackageName";
    throw Net::RRP::Exception::InvalidCommandSequence ( $buffer ) if $@;

    my $response = $responsePackageName->new();
    $response->setDescription ( $2 );

    my $index = 0;
    my $line;

    while ( ( $line = $lines [ $index++ ] ) && ( $line ne '.' ) )
    {
	$line =~ m/:/ || throw Net::RRP::Exception::InvalidAttributeValueSyntax ( $buffer );
	my $result = eval { $response->getAttribute ( $` ) };
	if ( $result )
	{
	    $result = [ $result ] unless ref ( $result );
	    push @$result, $';
	}
	else
	{
	    $result = $';
	}
	$response->setAttribute ( $` => $result );
    }

    $index--;

    throw Net::RRP::Exception::InvalidResponseFormat ( $buffer ) if ( ( ! $line ) || ( $line ne '.' ) || ( $#lines > $index ) );

    $response;
}

=head2 encodeResponse

This method get the instance of Net::RRP::Response child class and encodes it's to rrp format.

Example:

 my $buffer = $codec->encodeResponse ( $response );

=cut

sub encodeResponse
{
    my ( $this, $response ) = @_;
    my $buffer = $response->getCode . ' ' . $response->getDescription . CRLF;
    if ( my $attributes = $response->getAttributes )
    {
	$buffer .= join ( CRLF, map { my $key = $_;
				      my $value = $attributes->{$key};
				      map { "$key:$_" } @{ ( ref $value ? $value : [ $value ] ) } } keys %$attributes ) . CRLF
					  if ( %$attributes );
	#$buffer .= join ( CRLF, map { "$_:" . $attributes->{$_} } keys %$attributes ) . CRLF if ( scalar ( %$attributes ) );
    }
    $buffer .= '.' . CRLF;
    $buffer;
}

1;

=head1 AUTHOR AND COPYRIGHT

 Net::RRP::Codec (C) Michael Kulakov, Zenon N.S.P. 2000
                     125124, 19, 1-st Jamskogo polja st,
                     Moscow, Russian Federation

                     mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

L<Net::RRP::Request(3)>, L<Net::RRP::Response(3)>, L<Net::RRP::Entity(3)>, RFC 2832

=cut

__END__

