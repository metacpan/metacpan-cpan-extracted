package POE::Component::Server::HTTPServer::ParameterParseHandler;
use strict;
use HTTP::Status;
use MIME::Types;
use URI::Escape qw(uri_unescape);
use POE::Component::Server::HTTPServer::Handler;
use base 'POE::Component::Server::HTTPServer::Handler';

#
# problems to fix:
#   multi-valued params
#   mutlipart form data
#   the hash copying at the end of the POST handling could be more efficient
#
sub handle {
  my $self = shift;
  my $context = shift;
  my $req = $context->{request};
  # technically, for POST requests we could ignore (uri-)query params
  # might as well grab them, though
  my %p = $req->uri->query_form;
  $context->{param} = \%p;
  if ( $req->method eq 'POST' ) {
    if ( $req->content_type ne 'application/x-www-form-urlencoded' ) {
      print "XXX Don't know how to handle POST content encoding: ",
	$req->content_type, "\n";
    } else {
      my $querydata = $req->content;
      # following mapmap stolen from URI::_query
      my %bodyp =  map { s/\+/ /g; uri_unescape($_) }
	map { /=/ ? split(/=/, $_, 2) : ($_ => '')} split(/&/, $querydata);
      foreach my $k (keys %bodyp) {
	$context->{param}->{$k} = $bodyp{$k};
      }
    }
  }
  return H_CONT;
}

1;
__END__

=pod

=head1 NAME

POE::Component::Server::HTTPServer::ParameterParseHandler - Parse request parameters into context

=head1 SYNOPSIS

    use POE::Component::Server::HTTPServer::Handler;

    $server->handlers([ '/act/' => new_handler('ParameterParseHandler'),
                        '/act/' => \&action_handler,
                      ]);

    sub action_handler {
      my $context = shift;
      print "The 'foo' parameter is: ", $context->{param}->{foo}, "\n";
    }

=head1 DESCRIPTION

ParameterParseHandler parses the request URI and body (for POST
requests), and stores CGI parameters in the context.  Parameters are
stored as a hashref (name => value) in C<$context-E<gt>{param}>.

Stack this handler before handlers which need to process request
parameters.

=head1 TODO

Multivalued parameters are currently not currently supported.

Multipart submissions are currently not supported.

=head1 AUTHOR

Greg Fast <gdf@speakeasy.net>

=head1 COPYRIGHT

Copyright 2003 Greg Fast.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

