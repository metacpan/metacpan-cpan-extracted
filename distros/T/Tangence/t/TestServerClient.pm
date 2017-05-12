package t::TestServerClient;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw( make_serverclient );

use Scalar::Util qw( weaken );

sub make_serverclient
{
   my ( $registry ) = @_;

   my $server = TestServer->new();
   my $client = TestClient->new();

   $server->registry( $registry );

   weaken( $server->{client} = $client );
   weaken( $client->{server} = $server );

   $client->tangence_connected();

   return ( $server, $client );
}

package TestServer;
use base qw( Tangence::Server );

sub new
{
   return bless {}, shift;
}

sub tangence_write
{
   my $self = shift;
   my ( $message ) = @_;
   $self->{client}->tangence_readfrom( $message );
   length($message) == 0 or die "Client failed to read all Server wrote";
}

package TestClient;
use base qw( Tangence::Client );

sub new
{
   my $self = bless {}, shift;
   $self->identity( "testscript" );
   $self->on_error( sub { die "Test failed early - $_[0]" } );
   return $self;
}

sub tangence_write
{
   my $self = shift;
   my ( $message ) = @_;
   $self->{server}->tangence_readfrom( $message );
   length($message) == 0 or die "Server failed to read all Client wrote";
}
