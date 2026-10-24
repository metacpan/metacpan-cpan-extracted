package Net::Async::MCP::JSONRPC;
# ABSTRACT: How the transports read the error of a JSON-RPC response

use strict;
use warnings;

use JSON::MaybeXS;


# The message alone cannot carry a code to switch on or an error->{data} to
# read, so the raw error object travels with it as the details of a failure in
# category "mcp". The message stays the first element, so a caller reading the
# failure in scalar context sees exactly what it saw before. Not every "error"
# is a JSON-RPC one: an MCP server answers a bad HTTP method with
# {error => 'Method not allowed'}, a gateway may invent its own shape and a
# foreign stdio server may write anything, so the shape is checked before it
# is read as an object.
sub error_failure {
  my ( $self, $response ) = @_;

  return () unless ref $response eq 'HASH';

  my $err = $response->{error};
  return () unless ref $err eq 'HASH' && defined $err->{code};

  return (
    'MCP error '.$err->{code}.': '.($err->{message} // '(no message)'),
    mcp => $err,
  );
}


sub error_text {
  my ( $self, $err ) = @_;

  return $err unless ref $err;
  return eval {
    JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1)->encode($err)
  } // 'unknown error';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::MCP::JSONRPC - How the transports read the error of a JSON-RPC response

=head1 VERSION

version 0.007

=head1 DESCRIPTION

The one place the transports - L<Net::Async::MCP::Transport::Stdio>,
L<Net::Async::MCP::Transport::HTTP> and
L<Net::Async::MCP::Transport::InProcess> - decide whether the C<error> of a
decoded response is a JSON-RPC error object or something else that only says
the request failed. What a server answers is foreign input, whether it came
off the wire or from a server object in process: a shape this client cannot
read as JSON-RPC must still fail the request, and must never be reached into as
if it were an object.

This is an internal helper of the distribution, not a public API. Both methods
are class methods.

=head2 error_failure

    my @failure = Net::Async::MCP::JSONRPC->error_failure($response);
    return Future->fail(@failure) if @failure;

Takes a decoded response and returns the arguments a L<Future> is failed with
when its C<error> is a JSON-RPC error object - a hash with a defined C<code>:
C<< ( "MCP error $code: $message", mcp => $error ) >>, the message reading
C<(no message)> where the server sent none. Returns the empty list for anything
else, a response that is no hash included.

=head2 error_text

    my $text = Net::Async::MCP::JSONRPC->error_text($response->{error});

The text an C<error> that L</error_failure> did not accept carries: a plain
value as it is, a structure as its JSON, and C<unknown error> where even that
cannot be had. A transport puts its own prefix before it.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-mcp/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
