#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2017 -- leonerd@leonerd.org.uk

package Net::Async::Tangence::Client::via::sshunix;

use strict;
use warnings;

our $VERSION = '0.15';

# A tiny program we can run remotely to connect STDIN/STDOUT to a UNIX socket
# given as $ARGV[0]
use constant _NC_MICRO => <<'EOPERL';
use Socket qw( AF_UNIX SOCK_STREAM pack_sockaddr_un );
use IO::Handle;
socket(my $socket, AF_UNIX, SOCK_STREAM, 0) or die "socket(AF_UNIX): $!\n";
connect($socket, pack_sockaddr_un($ARGV[0])) or die "connect $ARGV[0]: $!\n";
my $fd = fileno($socket);
$socket->blocking(0); $socket->autoflush(1);
STDIN->blocking(0); STDOUT->autoflush(1);
my $rin = "";
vec($rin, 0, 1) = 1;
vec($rin, $fd, 1) = 1;
print "READY";
while(1) {
   select(my $rout = $rin, undef, undef, undef);
   if(vec($rout, 0, 1)) {
      sysread STDIN, my $buffer, 8192 or last;
      print $socket $buffer;
   }
   if(vec($rout, $fd, 1)) {
      sysread $socket, my $buffer, 8192 or last;
      print $buffer;
   }
}
EOPERL

sub connect
{
   my $client = shift;
   my ( $uri ) = @_;

   my $host = $uri->authority;
   my $path = $uri->path;
   # Path will start with a leading /; we need to trim that
   $path =~ s{^/}{};

   return $client->connect_exec(
      # Tell the remote perl we're going to send it a program on STDIN
      [ 'ssh', $host, 'perl', '-', $path ]
   )->then( sub {
      $client->write( _NC_MICRO . "\n__END__\n" );
      my $f = $client->new_future;

      $client->configure( on_read => sub {
         my ( $self, $buffref, $eof ) = @_;
         return 0 unless $$buffref =~ s/READY//;
         $self->configure( on_read => undef );
         $f->done;
         return 0;
      } );

      return $f;
   });
}

0x55AA;
