#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2024 -- leonerd@leonerd.org.uk

package Net::Prometheus::_FutureIO 0.14;

use v5.14;
use warnings;

use Future::IO 0.11;
use Future::Utils qw( repeat );

# TODO: Consider if we want to use Future::AsyncAwait to make this all a lot neater

my %running_clients;

sub start
{
   my $pkg = shift;
   my ( $prometheus, $listensock ) = @_;

   Future::IO->HAVE_MULTIPLE_FILEHANDLES or
      die "Net::Prometheus::_FutureIO requires a Future::IO implementation that supports multiple filehandles\n";

   return ( repeat {
      return Future::IO->accept( $listensock )->then( sub {
         my ( $clientsock ) = @_;
         my $fileno = $clientsock->fileno;

         my $f = $pkg->serve( $prometheus, $clientsock );
         $running_clients{$fileno} = $f;

         $f->on_done( sub {
            delete $running_clients{$fileno};
         });
         $f->on_fail( sub {
            warn "Net::Prometheus builtin HTTP server failed for [$fileno]: $_[0]";
            delete $running_clients{$fileno};
         });

         return Future->done;
      });
   } while => sub { !$_[0]->failure } )->on_fail( sub {
      warn "Net::Prometheus builtin HTTP server crashed: $_[0]";
   });
}

my %HTTP_CODES = (
   200 => "OK",
   400 => "Bad Request",
   405 => "Method Not Allowed",
);

sub serve
{
   my $pkg = shift;
   my ( $prometheus, $fh ) = @_;

   my $buf = "";
   my $f = repeat {
      Future::IO->sysread( $fh, 8192 )->then( sub {
         $buf .= $_[0];
         Future->done;
      } );
   } until => sub { $_[0]->failure or $buf =~ m/\x0d\x0a\x0d\x0a/ };

   # Parse request and generate a response code
   $f = $f->then( sub {
      my ( $req ) = $buf =~ m/^(.*\x0d\x0a\x0d\x0a)/s;
      ( my ( $firstline, $headers ) = split m/\x0d\x0a/, $req, 2 ) == 2 or
         return Future->done( 400 );

      my ( $method, $path, $proto ) = split m/\s+/, $firstline;

      return Future->done( 400 ) unless $proto =~ m(^HTTP/1\.[01]$);

      return Future->done( 200 ) if $method eq "GET";
      return Future->done( 200, 1 ) if $method eq "HEAD";
      return Future->done( 405 );
   });

   # Render an actual response and send it
   $f = $f->then( sub {
      my ( $code, $is_head ) = @_;

      my $body = "";
      $body .= $prometheus->render if $code == 200;

      my $response = "HTTP/1.0 $code $HTTP_CODES{$code}\n";
      $response .= "Content-Type: text/plain\n";
      $response .= sprintf "Content-Length: %d\n", length $body;
      $response .= "\n";

      $response =~ s/\n/\x0d\x0a/g;

      $response .= $body unless $is_head;

      return Future::IO->syswrite( $fh, $response );
   });

   return $f;
}

0x55AA;
