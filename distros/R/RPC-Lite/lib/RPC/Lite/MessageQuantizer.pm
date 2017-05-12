package RPC::Lite::MessageQuantizer;

use strict;

=pod

=head1 NAME

RPC::Lite::MessageQuantizer -- "Quantizes" messages to/from streams.

=head1 DESCRIPTION

RPC::Lite::MessageQuantizer packs and unpacks message to/from streams
that should be written using a transport layer.

=cut

sub new
{
  my $class = shift;
  my $self = {};
  
  bless $self, $class;
}

=pod

=over 4

=item C<Quantize( $stream )>

Retuns a hash ref with the following members:

=over 4

=item C<messages>

An array reference of the available messages.

=item C<remainder>

The remainder of the stream.

=back

Returns undef if unable to quantize.

=cut 

sub Quantize
{
  my $self = shift;
  my $stream = shift;

  my @messages;

  while( length( $stream ) )
  {
    my $messageLength = unpack( "N", $stream );
    
    # if we find an incomplete message, break
    if ( ( length( $stream ) - 4 ) < $messageLength )
    {
      last;
    }
    
    my ( undef, $message ) = unpack( "Na$messageLength", $stream );
    
    $stream = substr( $stream, $messageLength + 4 ); # +4 to eat off the 4 bytes that compose the number we unpacked

    push( @messages, $message );
  }
  
  return { 'messages' => \@messages, 'remainder' => $stream };
}

=pod

=item C<Pack( $message )>

Packs a message for writing to a transport stream.

Returns the packed message.

=cut

sub Pack
{
  my $self = shift;
  my $message = shift;
  
  my $messageLength = length( $message );
  
  # pack a length-prefixed message
  return pack( "Na$messageLength", $messageLength, $message );
}

=pod

=back

=cut


1;