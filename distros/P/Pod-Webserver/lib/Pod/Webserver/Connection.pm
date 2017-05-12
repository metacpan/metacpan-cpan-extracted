package Pod::Webserver::Connection;

use strict;
use warnings;

use Pod::Webserver::Request;

our $VERSION = '3.11';

# ------------------------------------------------

sub close {
  close $_[0]->{__fh};

} # End of close.

# ------------------------------------------------

sub get_request {
  my $self = shift;

  my $fh = $self->{__fh};

  my $line = <$fh>;
  if (!defined $line or !($line =~ m!^([A-Z]+)\s+(\S+)\s+HTTP/1\.\d+!)) {
    $self->send_error(400);
    return;
  }

  return Pod::Webserver::Request->new(method=>$1, url=>$2);

} # End of get_request.

# ------------------------------------------------

sub new {
  my ($class, $fh) = @_;

  return bless {__fh => $fh}, $class

} # End of new.

# ------------------------------------------------

sub send_error {
  my ($self, $status_code) = @_;

  my $message = "HTTP/1.0 $status_code HTTP error code $status_code\n" .
    "Date: " . Pod::Webserver::time2str(time) . "\n" . <<"EOM";
Content-Type: text/plain

Something went wrong, generating code $status_code.
EOM

  $message =~ s/\n/\15\12/gs;

  print {$self->{__fh}} $message;

} # End of send_error.

# ------------------------------------------------

sub send_response {
  my ($self, $response) = @_;

  my $message = "HTTP/1.0 200 OK\n"
    . "Date: " . Pod::Webserver::time2str(time) . "\n"
    . "Content-Type: $response->{content_type}\n";

  # This is destructive, but for our local purposes it doesn't matter
  while (my ($name, $value) = splice @{$response->{header}}, 0, 2) {
    $message .= "$name: $value\n";
  }

  $message .= "\n$response->{content}";

  $message =~ s/\n/\15\12/gs;

  print {$self->{__fh}} $message;

} # End of send_response.

# ------------------------------------------------

1;
