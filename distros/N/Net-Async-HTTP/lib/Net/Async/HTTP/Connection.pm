#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2015 -- leonerd@leonerd.org.uk

package Net::Async::HTTP::Connection;

use strict;
use warnings;

our $VERSION = '0.41';

use Carp;

use base qw( IO::Async::Stream );
IO::Async::Stream->VERSION( '0.59' ); # ->write( ..., on_write )

use Net::Async::HTTP::StallTimer;

use HTTP::Response;

my $CRLF = "\x0d\x0a"; # More portable than \r\n

use Struct::Dumb;
struct Responder => [qw( on_read on_error stall_timer is_done )];

# Detect whether HTTP::Message properly trims whitespace in header values. If
# it doesn't, we have to deploy a workaround to fix them up.
#   https://rt.cpan.org/Ticket/Display.html?id=75224
use constant HTTP_MESSAGE_TRIMS_LWS => HTTP::Message->parse( "Name:   value  " )->header("Name") eq "value";

=head1 NAME

C<Net::Async::HTTP::Connection> - HTTP client protocol handler

=head1 DESCRIPTION

This class provides a connection to a single HTTP server, and is used
internally by L<Net::Async::HTTP>. It is not intended for general use.

=cut

sub _init
{
   my $self = shift;
   $self->SUPER::_init( @_ );

   $self->{requests_in_flight} = 0;
}

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( pipeline max_in_flight ready_queue decode_content )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   if( my $on_closed = $params{on_closed} ) {
      $params{on_closed} = sub {
         my $self = shift;

         $self->debug_printf( "CLOSED in-flight=$self->{requests_in_flight}" );

         $self->error_all( "Connection closed" );

         undef $self->{ready_queue};
         $on_closed->( $self );
      };
   }

   croak "max_in_flight parameter required, may be zero" unless defined $self->{max_in_flight};

   $self->SUPER::configure( %params );
}

sub should_pipeline
{
   my $self = shift;
   return $self->{pipeline} &&
          $self->{can_pipeline} &&
          ( !$self->{max_in_flight} || $self->{requests_in_flight} < $self->{max_in_flight} );
}

sub connect
{
   my $self = shift;
   my %args = @_;

   $self->debug_printf( "CONNECT $args{host}:$args{service}" );

   defined wantarray or die "VOID ->connect";

   $self->SUPER::connect(
      socktype => "stream",
      %args
   )->on_done( sub {
      $self->debug_printf( "CONNECTED" );
   });
}

sub ready
{
   my $self = shift;

   my $queue = $self->{ready_queue} or return;

   if( $self->should_pipeline ) {
      $self->debug_printf( "READY pipelined" );
      while( @$queue && $self->should_pipeline ) {
         my $ready = shift @$queue;
         my $f = $ready->future;
         next if $f->is_cancelled;

         $ready->connecting and $ready->connecting->cancel;

         $f->done( $self );
      }
   }
   elsif( @$queue and $self->is_idle ) {
      $self->debug_printf( "READY non-pipelined" );
      while( @$queue ) {
         my $ready = shift @$queue;
         my $f = $ready->future;
         next if $f->is_cancelled;

         $ready->connecting and $ready->connecting->cancel;

         $f->done( $self );
         last;
      }
   }
   else {
      $self->debug_printf( "READY cannot-run queue=%d idle=%s",
         scalar @$queue, $self->is_idle ? "Y" : "N");
   }
}

sub is_idle
{
   my $self = shift;
   return $self->{requests_in_flight} == 0;
}

sub on_read
{
   my $self = shift;
   my ( $buffref, $closed ) = @_;

   while( my $head = $self->{responder_queue}[0]) {
      shift @{ $self->{responder_queue} } and next if $head->is_done;

      $head->stall_timer->reset if $head->stall_timer;

      my $ret = $head->on_read->( $self, $buffref, $closed, $head );

      if( defined $ret ) {
         return $ret if !ref $ret;

         $head->on_read = $ret;
         return 1;
      }

      $head->is_done or die "ARGH: undef return without being marked done";

      shift @{ $self->{responder_queue} };
      return 1 if !$closed and length $$buffref;
      return;
   }

   # Reinvoked after switch back to baseline, but may be idle again
   return if $closed or !length $$buffref;

   $self->invoke_error( "Spurious on_read of connection while idle",
      http_connection => read => $$buffref );
   $$buffref = "";
}

sub on_write_eof
{
   my $self = shift;
   $self->error_all( "Connection closed", http => undef, undef );
}

sub error_all
{
   my $self = shift;

   while( my $head = shift @{ $self->{responder_queue} } ) {
      $head->on_error->( @_ ) unless $head->is_done;
   }
}

sub request
{
   my $self = shift;
   my %args = @_;

   my $on_header = $args{on_header} or croak "Expected 'on_header' as a CODE ref";

   my $req = $args{request};
   ref $req and $req->isa( "HTTP::Request" ) or croak "Expected 'request' as a HTTP::Request reference";

   $self->debug_printf( "REQUEST %s %s", $req->method, $req->uri );

   my $request_body = $args{request_body};
   my $expect_continue = !!$args{expect_continue};

   my $method = $req->method;

   if( $method eq "POST" or $method eq "PUT" or length $req->content ) {
      $req->init_header( "Content-Length", length $req->content );
   }

   if( $expect_continue ) {
      $req->init_header( "Expect", "100-continue" );
   }

   if( $self->{decode_content} ) {
      #$req->init_header( "Accept-Encoding", Net::Async::HTTP->can_decode )
      $req->init_header( "Accept-Encoding", "gzip" );
   }

   my $f = $self->loop->new_future
      ->set_label( "$method " . $req->uri );

   # TODO: Cancelling a request Future shouldn't necessarily close the socket
   # if we haven't even started writing the request yet. But we can't know
   # that currently.
   $f->on_cancel( sub {
      $self->debug_printf( "CLOSE on_cancel" );
      $self->close_now;
   });

   my $stall_timer;
   if( $args{stall_timeout} ) {
      $stall_timer = Net::Async::HTTP::StallTimer->new(
         delay => $args{stall_timeout},
         future => $f,
      );
      $self->add_child( $stall_timer );
      # Don't start it yet

      my $remove_timer = sub {
         $self->remove_child( $stall_timer ) if $stall_timer;
         undef $stall_timer;
      };

      $f->on_ready( $remove_timer );
   }

   my $on_body_write;
   if( $stall_timer or $args{on_body_write} ) {
      my $inner_on_body_write = $args{on_body_write};
      my $written = 0;
      $on_body_write = sub {
         $stall_timer->reset if $stall_timer;
         $inner_on_body_write->( $written += $_[1] ) if $inner_on_body_write;
      };
   }

   my $write_request_body = defined $request_body ? sub {
      my ( $self ) = @_;
      $self->write( $request_body,
         on_write => $on_body_write
      );
   } : undef;

   # Unless the request method is CONNECT, the URL is not allowed to contain
   # an authority; only path
   # Take a copy of the headers since we'll be hacking them up
   my $headers = $req->headers->clone;
   my $path;
   if( $method eq "CONNECT" ) {
      $path = $req->uri->as_string;
   }
   else {
      my $uri = $req->uri;
      $path = $uri->path_query;
      $path = "/$path" unless $path =~ m{^/};
      my $authority = $uri->authority;
      if( defined $authority and
          my ( $user, $pass, $host ) = $authority =~ m/^(.*?):(.*)@(.*)$/ ) {
         $headers->init_header( Host => $host );
         $headers->authorization_basic( $user, $pass );
      }
      else {
         $headers->init_header( Host => $authority );
      }
   }

   my $protocol = $req->protocol || "HTTP/1.1";
   my @headers = ( "$method $path $protocol" );
   $headers->scan( sub { push @headers, "$_[0]: $_[1]" } );

   $stall_timer->start if $stall_timer;
   $stall_timer->reason = "writing request" if $stall_timer;

   my $on_header_write = $stall_timer ? sub { $stall_timer->reset } : undef;

   $self->write( join( $CRLF, @headers ) .
                 $CRLF . $CRLF,
                 on_write => $on_header_write );

   $self->write( $req->content,
                 on_write => $on_body_write ) if length $req->content;
   $write_request_body->( $self ) if $write_request_body and !$expect_continue;

   $self->write( "", on_flush => sub {
      return unless $stall_timer; # test again in case it was cancelled in the meantime
      $stall_timer->reset;
      $stall_timer->reason = "waiting for response";
   }) if $stall_timer;

   $self->{requests_in_flight}++;

   push @{ $self->{responder_queue} }, Responder(
      $self->_mk_on_read_header(
         $req, $args{previous_response}, $expect_continue ? $write_request_body : undef, $on_header, $stall_timer, $f
      ),
      sub { $f->fail( @_ ) unless $f->is_ready; }, # on_error
      $stall_timer,
      0, # is_done
   );

   return $f;
}

sub _mk_on_read_header
{
   shift; # $self
   my ( $req, $previous_response, $write_request_body, $on_header, $stall_timer, $f ) = @_;

   sub {
      my ( $self, $buffref, $closed, $responder ) = @_;

      if( $stall_timer ) {
         $stall_timer->reason = "receiving response header";
         $stall_timer->reset;
      }

      if( length $$buffref >= 4 and $$buffref !~ m/^HTTP/ ) {
         $self->debug_printf( "ERROR fail" );
         $f->fail( "Did no receive HTTP response from server", http => undef, $req ) unless $f->is_cancelled;
         $self->close_now;
      }

      unless( $$buffref =~ s/^(.*?$CRLF$CRLF)//s ) {
         if( $closed ) {
            $self->debug_printf( "ERROR closed" );
            $f->fail( "Connection closed while awaiting header", http => undef, $req ) unless $f->is_cancelled;
            $self->close_now;
         }
         return 0;
      }

      my $header = HTTP::Response->parse( $1 );
      # HTTP::Response doesn't strip the \rs from this
      ( my $status_line = $header->status_line ) =~ s/\r$//;

      unless( HTTP_MESSAGE_TRIMS_LWS ) {
         my @headers;
         $header->scan( sub {
            my ( $name, $value ) = @_;
            s/^\s+//, s/\s+$// for $value;
            push @headers, $name => $value;
         } );
         $header->header( @headers ) if @headers;
      }

      my $protocol = $header->protocol;
      if( $protocol =~ m{^HTTP/1\.(\d+)$} and $1 >= 1 ) {
         $self->{can_pipeline} = 1;
      }

      if( $header->code =~ m/^1/ ) { # 1xx is not a final response
         $self->debug_printf( "HEADER [provisional] %s", $status_line );
         $write_request_body->( $self ) if $write_request_body;
         return 1;
      }

      $header->request( $req );
      $header->previous( $previous_response ) if $previous_response;

      $self->debug_printf( "HEADER %s", $status_line );

      my $on_body_chunk = $on_header->( $header );

      my $code = $header->code;

      my $content_encoding = $header->header( "Content-Encoding" );

      my $decoder;
      if( $content_encoding and
          $decoder = Net::Async::HTTP->can_decode( $content_encoding ) ) {
         $header->init_header( "X-Original-Content-Encoding" => $header->remove_header( "Content-Encoding" ) );
      }

      # can_pipeline is set for HTTP/1.1 or above; presume it can keep-alive if set
      my $connection_close = lc( $header->header( "Connection" ) || ( $self->{can_pipeline} ? "keep-alive" : "close" ) )
                              eq "close";

      if( $connection_close ) {
         $self->{max_in_flight} = 1;
      }
      elsif( defined( my $keep_alive = lc( $header->header("Keep-Alive") || "" ) ) ) {
         my ( $max ) = ( $keep_alive =~ m/max=(\d+)/ );
         $self->{max_in_flight} = $max if $max && $max < $self->{max_in_flight};
      }

      my $on_more = sub {
         my ( $chunk ) = @_;

         if( $decoder and not eval { $chunk = $decoder->( $chunk ); 1 } ) {
            $self->debug_printf( "ERROR decode failed" );
            $f->fail( "Decode error $@", http => undef, $req );
            $self->close;
            return undef;
         }

         $on_body_chunk->( $chunk );

         return 1;
      };
      my $on_done = sub {
         # TODO: IO::Async probably ought to do this. We need to fire the
         # on_closed event _before_ calling on_body_chunk, to clear the
         # connection cache in case another request comes - e.g. HEAD->GET
         $self->close if $connection_close;

         my $final;
         if( $decoder and not eval { $final = $decoder->(); 1 } ) {
            $self->debug_printf( "ERROR decode failed" );
            $f->fail( "Decode error $@", http => undef, $req );
            $self->close;
            return undef;
         }

         $on_body_chunk->( $final ) if defined $final and length $final;

         my $response = $on_body_chunk->();
         my $e = eval { $f->done( $response ) unless $f->is_cancelled; 1 } ? undef : $@;

         $self->{requests_in_flight}--;
         $self->debug_printf( "DONE remaining in-flight=$self->{requests_in_flight}" );
         $self->ready;

         if( defined $e ) {
            chomp $e;
            $self->invoke_error( $e, perl => );
            # This might not return, if it top-level croaks
         }

         return undef; # Finished
      };

      # RFC 2616 says "HEAD" does not have a body, nor do any 1xx codes, nor
      # 204 (No Content) nor 304 (Not Modified)
      if( $req->method eq "HEAD" or $code =~ m/^1..$/ or $code eq "204" or $code eq "304" ) {
         $self->debug_printf( "BODY done [none]" );
         $responder->is_done++;

         return $on_done->();
      }

      my $transfer_encoding = $header->header( "Transfer-Encoding" );
      my $content_length    = $header->content_length;

      if( defined $transfer_encoding and $transfer_encoding eq "chunked" ) {
         $self->debug_printf( "BODY chunks" );

         $stall_timer->reason = "receiving body chunks" if $stall_timer;
         return $self->_mk_on_read_chunked( $req, $on_more, $on_done, $f );
      }
      elsif( defined $content_length ) {
         $self->debug_printf( "BODY length $content_length" );

         if( $content_length == 0 ) {
            $self->debug_printf( "BODY done [length=0]" );
            $responder->is_done++;

            return $on_done->();
         }

         $stall_timer->reason = "receiving body" if $stall_timer;
         return $self->_mk_on_read_length( $content_length, $req, $on_more, $on_done, $f );
      }
      else {
         $self->debug_printf( "BODY until EOF" );

         $stall_timer->reason = "receiving body until EOF" if $stall_timer;
         return $self->_mk_on_read_until_eof( $req, $on_more, $on_done, $f );
      }
   };
}

sub _mk_on_read_chunked
{
   shift; # $self
   my ( $req, $on_more, $on_done, $f ) = @_;

   my $chunk_length;

   sub {
      my ( $self, $buffref, $closed, $responder ) = @_;

      if( !defined $chunk_length and $$buffref =~ s/^(.*?)$CRLF// ) {
         my $header = $1;

         # Chunk header
         unless( $header =~ s/^([A-Fa-f0-9]+).*// ) {
            $f->fail( "Corrupted chunk header", http => undef, $req ) unless $f->is_cancelled;
            $self->close_now;
            return 0;
         }

         $chunk_length = hex( $1 );
         return 1 if $chunk_length;

         return $self->_mk_on_read_chunk_trailer( $req, $on_more, $on_done, $f );
      }

      # Chunk is followed by a CRLF, which isn't counted in the length;
      if( defined $chunk_length and length( $$buffref ) >= $chunk_length + 2 ) {
         # Chunk body
         my $chunk = substr( $$buffref, 0, $chunk_length, "" );

         unless( $$buffref =~ s/^$CRLF// ) {
            $self->debug_printf( "ERROR chunk without CRLF" );
            $f->fail( "Chunk of size $chunk_length wasn't followed by CRLF", http => undef, $req ) unless $f->is_cancelled;
            $self->close;
         }

         undef $chunk_length;

         return $on_more->( $chunk );
      }

      if( $closed ) {
         $self->debug_printf( "ERROR closed" );
         $f->fail( "Connection closed while awaiting chunk", http => undef, $req ) unless $f->is_cancelled;
      }
      return 0;
   };
}

sub _mk_on_read_chunk_trailer
{
   shift; # $self
   my ( $req, $on_more, $on_done, $f ) = @_;

   my $trailer = "";

   sub {
      my ( $self, $buffref, $closed, $responder ) = @_;

      if( $closed ) {
         $self->debug_printf( "ERROR closed" );
         $f->fail( "Connection closed while awaiting chunk trailer", http => undef, $req ) unless $f->is_cancelled;
      }

      $$buffref =~ s/^(.*)$CRLF// or return 0;
      $trailer .= $1;

      return 1 if length $1;

      # TODO: Actually use the trailer

      $self->debug_printf( "BODY done [chunked]" );
      $responder->is_done++;

      return $on_done->();
   };
}

sub _mk_on_read_length
{
   shift; # $self
   my ( $content_length, $req, $on_more, $on_done, $f ) = @_;

   sub {
      my ( $self, $buffref, $closed, $responder ) = @_;

      # This will truncate it if the server provided too much
      my $content = substr( $$buffref, 0, $content_length, "" );
      $content_length -= length $content;

      return undef unless $on_more->( $content );

      if( $content_length == 0 ) {
         $self->debug_printf( "BODY done [length]" );
         $responder->is_done++;

         return $on_done->();
      }

      if( $closed ) {
         $self->debug_printf( "ERROR closed" );
         $f->fail( "Connection closed while awaiting body", http => undef, $req ) unless $f->is_cancelled;
      }
      return 0;
   };
}

sub _mk_on_read_until_eof
{
   shift; # $self
   my ( $req, $on_more, $on_done, $f ) = @_;

   sub {
      my ( $self, $buffref, $closed, $responder ) = @_;

      my $content = $$buffref;
      $$buffref = "";

      return undef unless $on_more->( $content );

      return 0 unless $closed;

      $self->debug_printf( "BODY done [eof]" );
      $responder->is_done++;
      return $on_done->();
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
