package POE::Component::Server::HTTPServer::NotFoundHandler;
use strict;
use HTTP::Status;
use POE::Component::Server::HTTPServer::Handler qw( H_CONT H_FINAL );
use base 'POE::Component::Server::HTTPServer::Handler';

our $Instance;

sub new {
  my $class = shift;
  $Instance = bless {}, $class
    unless defined($Instance);
  return $Instance;
}

sub handle {
  my $self = shift;
  my $context = shift;
  $context->{response}->code( RC_NOT_FOUND );
  my $message = "";
  if ( defined($context->{error_message}) ) {
    $message = ":<BR>$context->{error_message}\n";
  }
  $context->{response}->content("<HTML><BODY>Not Found$message</BODY></HTML>");
  return H_FINAL;
}

1;
__END__

=pod

=head1 NAME

POE::Component::Server::HTTPServer::NotFoundHandler - Generate 404 Responses

=head1 SYNOPSIS

    use POE::Component::Server::HTTPServer;

    my $server = POE::Component::Server::HTTPServer->new();
    $server->handlers( [
        '/reallyprivate' => new_handler( 'NotFoundHandler' ),
    ] );

=head1 DESCRIPTION

NotFoundHandler generates and returns C<404 Not Found> responses.
This handler is, by default, set as the backstop handler that
HTTPServer will invoke on a request if none of the other handlers have
returned H_FINAL.

If the C<error_message> context attribute is defined, it will be
included in the content of the reponse (use with caution).

NotFoundHandler is implemented as a singleton.

=head1 SEE ALSO

L<POE::Component::Server::HTTPServer>

=head1 AUTHOR

Greg Fast <gdf@speakeasy.net>

=head1 COPYRIGHT

Copyright 2003 Greg Fast.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

