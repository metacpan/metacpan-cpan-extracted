package RPC::Lite::Transport;

=pod

=head1 NAME

RPC::Lite::Transport -- Transport base class.

=head1 DESCRIPTION

RPC::Lite::Transport is the base for implementing transport layers
for RPC::Lite.

=cut

sub new
{
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self;
}

=pod

=over 4

=item ReadData( [$timeout] )

Attempts to read data from the stream within the
(optional) timeout period. 

=cut

sub ReadData() { die( "Unimplemented virtual function!" ) }

=pod

=item WriteData( $data )

Writes $data to the stream.  Returns the number of bytes written
or undef if there was an error.

=cut

sub WriteData() { die( "Unimplemented virtual function!" ) }

=pod

=item Connect()

Connects to the server specified on transport layer construction.
Returns a boolean indicating success or failure.

=cut

sub Connect() { die( "Unimplemented virtual function!" ) }

=pod

=item Disconnect()

Severs the connection with the server.  Returns a boolean indicating
success or failure.

=cut

sub Disconnect() { die( "Unimplemented virtual function!" ) }

=pod

=item Listen()

Begin listening for incoming connections.  

=cut

sub Listen() { die( "Unimplemented virtual function!" ) }

=pod

=item GetNewConnection()

Checks for a new incoming connection and returns an RPC::Lite::Transport
object of the proper type if there is one, undef otherwise.

=cut

sub GetNewConnection() { die( "Unimplemented virtual function!" ) }

=pod

=back

=back

=head1 SUPPORTED TRANSPORT LAYERS

=over 4

=item TCP

=back


=cut

1;
