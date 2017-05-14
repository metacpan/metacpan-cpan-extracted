=head1 NAME

Net::RVP::Server - listening RVP server using the Event module

=head1 METHODS

=cut
package Net::RVP::Server;

use strict;
use base qw(Event::IO::Record);

use HTTP::Parser;
use HTTP::Status;


=head2 new ( named parameters )

IM notify server connection object.

=cut
sub new {
  my ($class,%param) = shift;
  my $self = $class->SUPER::new(@_);
  @{$self}{qw(rs_state rs_parser)} = ('','',undef);
  $self->IRS("\x0d?\x0a\x0d?\x0a");  # look for end of HTTP headers
  return $self;
}


=head2 init_event ( callback )

The callback should be a CODE ref which is called with an HTTP::Request and
should return an HTTP::Response object.  See also L<Event::IO::Server>.

=cut
sub init_event {
  my ($self,$cb) = @_;
  $self->{rs_sink} = $cb;
  $self->SUPER::init_event();
}


=head2 line_event ( line )

Received a line of input.

=cut
sub line_event {
  my ($self,$line) = @_;

  # parse HTTP header if we have it
  if($self->{rs_state} eq '') {
    $self->{rs_parser} = HTTP::Parser->new();
    $line .= "\x0d\x0a\x0d\x0a";
    $self->IRS('\z');
  }

  my $result = eval { $self->{rs_state} = $self->{rs_parser}->add($line); };
  if($@) {
    $self->write("$@\n");
    return $self->close();
  }

  if(0 == $result) {
    $result = $self->{rs_parser}->request();
    my $response = $self->{rs_sink}->($result);
    $response = HTTP::Response->new(RC_INTERNAL_SERVER_ERROR,$response)
     unless ref $response;

    my $http_ver = $result->header('X-HTTP-Version') || '1.1';
    $self->write("HTTP/$http_ver ".$response->code().' '.$response->message().
     "\x0d\x0a".$response->headers()->as_string("\x0d\x0a")."\x0d\x0a".
     $response->content());

    # close connection if < HTTP 1.1 or Connection: close requested
    if($http_ver < 1.1 or grep /\bclose\b/, $result->header('connection')) {
      $self->close();
    } else {
      $self->{rs_state} = '';  # ready for another request
      $self->IRS("\x0d?\x0a\x0d?\x0a");
    }
  }
}


=head1 AUTHOR

David Robins E<lt>dbrobins@davidrobins.netE<gt>.

=cut


1;
