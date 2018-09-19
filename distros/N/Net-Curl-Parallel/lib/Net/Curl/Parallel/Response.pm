package Net::Curl::Parallel::Response;

use strictures 2;
use Moo;
use HTTP::Response;
use HTTP::Parser::XS qw(parse_http_response HEADERS_AS_HASHREF);

has completed => (is => 'rw');
has status    => (is => 'ro');
has headers   => (is => 'ro', default => sub{{}});
has error     => (is => 'ro');
has raw_body  => (is => 'ro');
has raw_head  => (is => 'ro');
has fh_body   => (is => 'ro');
has fh_head   => (is => 'ro');

sub BUILD {
  my $self = shift;
  $self->{completed} = 0;
  $self->{raw_body} = '';
  $self->{raw_head} = '';
  open $self->{fh_body}, '>', \$self->{raw_body};
  open $self->{fh_head}, '>', \$self->{raw_head};
}

sub content { goto \&raw_body } # alias to mimic HTTP::Response
sub failed  { !!$_[0]->error }

sub complete {
  my $self = shift;

  return $self->fail('incomplete message')
    unless $self->raw_head;

  my ($ret, $min, $status, $msg, $hdrs)
    = parse_http_response($self->raw_head, HEADERS_AS_HASHREF);

  $self->{status} = $status;

  # parse_http_response() will always return a hashref in the headers.
  # But, good coding says guard against randomness.
  # uncoverable condition right
  $self->{headers} = $hdrs // {};

  $self->close_handles;
  $self->completed(1);

  return 1;
}

sub fail {
  my ($self, $msg) = @_;
  $self->{error} = $msg;

  if ($self->{error} =~ /timeout|timed out/gi) {
    $self->{status} = 408;
  } else {
    $self->{status} = 400;
  }

  $self->close_handles;
  $self->completed(1);

  return;
}

sub close_handles {
  my $self = shift;

  close $self->fh_head;
  undef $self->{fh_head};

  close $self->fh_body;
  undef $self->{fh_body};
}

sub as_http_response {
  my $self = shift;
  return unless $self->completed;
  my $res = HTTP::Response->new($self->status);
  $res->header($_, $self->headers->{$_}) foreach keys %{$self->headers};
  $res->content($self->raw_body);
  return $res;
}

1;

=head1 NAME

Net::Curl::Parallel::Response

=head1 DESCRIPTION

An HTTP response returned by L<Net::Curl::Parallel>.

=head1 METHODS

=head2 status

Returns the HTTP response status code.

=head2 failed

Returns true when the request generated an error.

=head2 error

Returns the error message string.

=head2 content

Returns the HTTP response body content string.

=head2 as_http_response

Returns the response as an L<HTTP::Response> instance.

=cut
