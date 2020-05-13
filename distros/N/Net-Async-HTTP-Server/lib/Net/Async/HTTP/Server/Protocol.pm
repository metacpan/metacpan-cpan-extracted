#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2015 -- leonerd@leonerd.org.uk

package Net::Async::HTTP::Server::Protocol;

use strict;
use warnings;
use base qw( IO::Async::Stream );

our $VERSION = '0.13';

use Carp;
use Scalar::Util qw( weaken );

use HTTP::Request;

my $CRLF = "\x0d\x0a";

sub on_read
{
   my $self = shift;
   my ( $buffref, $eof ) = @_;

   return 0 if $eof;

   return 0 unless $$buffref =~ s/^(.*?$CRLF$CRLF)//s;
   my $header = $1;

   my $request = HTTP::Request->parse( $header );
   unless( $request and defined $request->protocol and $request->protocol =~ m/^HTTP/ ) {
      $self->close_now;
      return 0;
   }

   my $request_body_len = $request->content_length || 0;

   $self->debug_printf( "REQUEST %s %s", $request->method, $request->uri->path );

   return sub {
      my ( undef, $buffref, $eof ) = @_;

      return 0 unless length($$buffref) >= $request_body_len;

      $request->add_content( substr( $$buffref, 0, $request_body_len, "" ) );

      push @{ $self->{requests} }, my $req = $self->parent->make_request( $self, $request );
      weaken( $self->{requests}[-1] );

      $self->parent->_received_request( $req );

      return undef;
   };
}

sub on_closed
{
   my $self = shift;

   $_ and $_->_close for @{ $self->{requests} };
   undef @{ $self->{requests} };
}

sub _flush_requests
{
   my $self = shift;

   my $queue = $self->{requests};
   while( @$queue ) {
      my $req = $queue->[0];
      $req or shift @$queue, next;

      my $is_done = $req->_write_to_stream( $self );

      $is_done ? shift @$queue : return;
   }
}

0x55AA;
