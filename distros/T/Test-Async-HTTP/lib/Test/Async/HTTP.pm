#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Test::Async::HTTP;

use strict;
use warnings;

our $VERSION = '0.02';

use HTTP::Request;

=head1 NAME

C<Test::Async::HTTP> - unit test code that uses C<Net::Async::HTTP>

=head1 DESCRIPTION

This module implements a mock version of L<Net::Async::HTTP> suitable for unit
tests that virtualises the actual HTTP request/response cycle, allowing the
unit test script to inspect the requests made and provide responses to them.

=cut

# TODO: Move these into a class within the package

sub new
{
   my $class = shift;
   bless { @_ }, $class
}

=head1 METHODS

=cut

=head2 $f = $http->do_request( %args )

Implements the actual L<Net::Async::HTTP> request API.

The following arguments are handled specially:

=over 4

=item * timeout

The value of a C<timeout> argument is captured as an extra header on the
request object called C<X-NaHTTP-Timeout>.

=item * stall_timeout

=item * expect_continue

=item * SSL

These arguments are entirely ignored.

=back

=cut

# The main Net::Async::HTTP method
sub do_request
{
   my $self = shift;
   my %args = @_;

   if( !exists $args{request} ) {
      my $request = $args{request} = HTTP::Request->new(
         delete $args{method}, delete $args{uri}
      );
      $request->content( delete $args{content} ) if exists $args{content};
   }

   my $pending = Test::Async::HTTP::Pending->new(
      request   => delete $args{request},
      content   => delete $args{request_body},
      on_write  => ( $args{on_body_write} ? do {
            my $on_body_write = delete $args{on_body_write};
            my $written = 0;
            sub { $on_body_write->( $written += $_[0] ) }
         } : undef ),
      on_header => delete $args{on_header},
   );

   if( my $timeout = delete $args{timeout} ) {
      # Cheat - easier for the unit tests to find it here
      $pending->request->header( "X-NaHTTP-Timeout" => $timeout );
   }

   delete $args{expect_continue};
   delete $args{SSL};

   delete $args{stall_timeout};

   die "TODO: more args: " . join( ", ", keys %args ) if keys %args;

   push @{ $self->{next} }, $pending;

   return $pending->response;
}

=head2 $response = $http->GET( $uri, %args )->get

=head2 $response = $http->HEAD( $uri, %args )->get

=head2 $response = $http->PUT( $uri, $content, %args )->get

=head2 $response = $http->POST( $uri, $content, %args )->get

Convenient wrappers for using the C<GET>, C<HEAD>, C<PUT> or C<POST> methods
with a C<URI> object and few if any other arguments, returning a C<Future>.

Remember that C<POST> with non-form data (as indicated by a plain scalar
instead of an C<ARRAY> reference of form data name/value pairs) needs a
C<content_type> key in C<%args>.

=cut

sub GET
{
   my $self = shift;
   my ( $uri, @args ) = @_;
   return $self->do_request( method => "GET", uri => $uri, @args );
}

sub HEAD
{
   my $self = shift;
   my ( $uri, @args ) = @_;
   return $self->do_request( method => "HEAD", uri => $uri, @args );
}

sub PUT
{
   my $self = shift;
   my ( $uri, $content, @args ) = @_;
   return $self->do_request( method => "PUT", uri => $uri, content => $content, @args );
}

sub POST
{
   my $self = shift;
   my ( $uri, $content, @args ) = @_;
   return $self->do_request( method => "POST", uri => $uri, content => $content, @args );
}

=head2 $p = $http->next_pending

Returns the next pending request wrapper object if one is outstanding (due to
an earlier call to C<do_request>), or C<undef>.

=cut

sub next_pending
{
   my $self = shift;
   my $pending = shift @{ $self->{next} } or return;

   if( defined $pending->content ) {
      $pending->_pull_content( $pending->content );
      undef $pending->content;
   }

   return $pending;
}

package Test::Async::HTTP::Pending;

=head1 PENDING REQUEST OBJECTS

Objects returned by C<next_pending> respond to the following methods:

=cut

use Future;

sub new
{
   my $class = shift;
   my %args = @_;
   bless [
      $args{request},
      $args{content},
      $args{on_write},
      $args{on_header},
      Future->new,      # response
   ], $class;
}

=head2 $request = $p->request

Returns the L<HTTP::Request> object underlying this pending request.

=cut

sub request        { shift->[0] }
sub content:lvalue { shift->[1] }
sub on_write       { shift->[2] }
sub on_header      { shift->[3] }
sub response       { shift->[4] }

sub on_chunk:lvalue { shift->[5] }

sub _pull_content
{
   my $self = shift;
   my ( $content ) = @_;

   if( !ref $content ) {
      $self->request->add_content( $content );
      $self->on_write->( length $content ) if $self->on_write;
   }
   elsif( ref $content eq "CODE" ) {
      while( defined( my $chunk = $content->() ) ) {
         $self->_pull_content( $chunk );
      }
   }
   elsif( blessed $content and $content->isa( "Future" ) ) {
      $content->on_done( sub {
         my ( $chunk ) = @_;
         $self->_pull_content( $chunk );
      });
   }
   else {
      die "TODO: Not sure how to handle $content";
   }
}

=head2 $p->respond( $resp )

Makes the request complete with the given L<HTTP::Response> response. This
response is given to the Future that had been returned by the C<do_request>
method.

=cut

sub respond
{
   my $self = shift;
   my ( $response ) = @_;

   if( $self->on_header ) {
      # Ugh - maybe there's a more efficient way
      my $header = $response->clone;
      $header->content("");

      my $on_chunk = $self->on_header->( $header );
      $on_chunk->( $response->content );
      $self->response->done( $on_chunk->() );
   }
   else {
      $self->response->done( $response );
   }
}

=head2 $p->respond_header( $header )

=head2 $p->respond_more( $data )

=head2 $p->respond_done

Alternative to the single C<respond> method, to allow an equivalent of chunked
encoding response. C<respond_header> responds with the header and initial
content, followed by multiple calls to C<respond_more> to provide more body
content, until a final C<respond_done> call finishes the request.

=cut

sub respond_header
{
   my $self = shift;
   my ( $header ) = @_;

   $self->on_chunk = $self->on_header->( $header );
}

sub respond_more
{
   my $self = shift;
   my ( $chunk ) = @_;

   $self->on_chunk->( $chunk );
}

sub respond_done
{
   my $self = shift;

   $self->response->done( $self->on_chunk->() );
}

sub fail
{
   my $self = shift;

   $self->response->fail( @_ );
}


=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
