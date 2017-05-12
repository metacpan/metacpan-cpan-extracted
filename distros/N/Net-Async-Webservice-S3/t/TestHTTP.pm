package TestHTTP;

use strict;
use warnings;

use Future;
use Scalar::Util qw( blessed );

sub new
{
   my $class = shift;
   bless { @_ }, $class
}

sub do_request
{
   my $self = shift;
   my %args = @_;

   defined $self->{pending} and !$self->{concurrent} and
      die "Already have a pending request";

   my $pending = $self->{pending} = TestHTTP::Pending->new(
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

   push @{ $self->{next} }, $pending if $self->{concurrent};

   return $pending->response;
}

sub next_pending
{
   my $self = shift;
   return shift @{ $self->{next} };
}

sub pending_request
{
   my $self = shift;
   my $pending = $self->{pending} or return;

   if( $pending->content ) {
      $pending->_pull_content( $pending->content );
      undef $pending->content;
   }

   shift @{ $self->{next} } if $self->{next};
   return $pending->request;
}

sub pending_request_plus_content
{
   my $self = shift;
   my $pending = $self->{pending} or return;

   return $pending->request, $pending->request_content;
}

sub respond
{
   my $self = shift;
   my ( $response ) = @_;

   my $pending = delete $self->{pending};
   $pending->respond( $response );
}

sub respond_header
{
   my $self = shift;
   $self->{pending}->respond_header( @_ );
}

sub respond_more
{
   my $self = shift;
   $self->{pending}->respond_more( @_ );
}

sub respond_done
{
   my $self = shift;

   my $pending = delete $self->{pending};

   $pending->respond_done;
}

sub fail
{
   my $self = shift;

   my $pending = delete $self->{pending};

   $pending->fail( @_ );
}

package TestHTTP::Pending;

sub new
{
   my $class = shift;
   my %args = @_;
   bless [
      $args{request},
      $args{content},
      $args{on_write},
      $args{on_header},
      undef,            # on_chunk
      Future->new,      # response
   ], $class;
}

sub request         { shift->[0] }
sub content:lvalue  { shift->[1] }
sub on_write        { shift->[2] }
sub on_header       { shift->[3] }
sub on_chunk:lvalue { shift->[4] }
sub response        { shift->[5] }

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

sub respond
{
   my $self = shift;
   my ( $response ) = @_;

   if( $self->on_header ) {
      my $header = $response->clone;
      $header->content("");

      $self->respond_header( $header );
      $self->respond_more( $response->content );
      $self->respond_done;
   }
   else {
      $self->response->done( $response );
   }
}

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

0x55AA;
