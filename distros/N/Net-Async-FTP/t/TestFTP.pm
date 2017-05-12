package t::TestFTP;

use strict;

use Exporter 'import';
our @EXPORT = qw(
   accept_dataconn
);

use IO::Async::Test;
use IO::Socket::INET;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

sub accept_dataconn
{
   my ( $clientsock ) = @_;

   my $dataconn_srv = IO::Socket::INET->new(
      Type      => SOCK_STREAM,
      LocalHost => "127.0.0.1",
      Listen    => 1
   ) or die "Cannot create server socket - $!";

   $dataconn_srv->blocking(0);

   my $portHI = int( $dataconn_srv->sockport / 256 );
   my $portLO = $dataconn_srv->sockport % 256;

   $clientsock->syswrite( "227 Entering Passive Mode (127,0,0,1,$portHI,$portLO).$CRLF" );

   my $dataconn;
   wait_for { $dataconn = $dataconn_srv->accept };

   return $dataconn;
}
