package POE::Component::Client::REST::JSON;
use JSON;
use Moose;

our $VERSION = '0.05';

extends q(POE::Component::Client::REST);

sub cook_request {
  my $request = $_[0];
  if(my $content = $request->content) {
    $content = encode_json($content);
    $request->content_type('application/json');
    $request->content($content);
    $request->header('Content-Encoding' => 'UTF-8');
  };
  return $request;
};
has '+request_cooker' => (default => sub { \&cook_request });

sub cook_response {
  my $response = $_[0];
  return (decode_json($response->content), $response);
};
has '+response_cooker' => (default => sub { \&cook_response });

1;

__END__

=head1 NAME

POE::Component::Client::REST::JSON - Low-level interface for JSON REST calls

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

This is just a thin specialization of L<POE::Component::Client::REST> that
does some JSON encoding and decoding - see the methods for details.

=head1 METHODS

=over 4

=item cook_request

All requests get their content encoded into JSON and some appropriate headers
set.

=item cook_response

Responses are deserialized from JSON, and callbacks receive two arguments: the
deserialized structure and the L<HTTP::Response> object.

=back

=head1 AUTHOR

Paul Driver, C<< <frodwith at cpan.org> >>

=head1 BUGS

Probably.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul Driver

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
