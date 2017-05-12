package POE::Component::Server::HTTPServer::BasicAuthenHandler;
use strict;
use HTTP::Status;
use MIME::Base64 qw( decode_base64 );
use POE::Component::Server::HTTPServer::Handler qw( H_CONT H_FINAL );
use base 'POE::Component::Server::HTTPServer::Handler';

sub _init {
  my $self = shift;
  my $realm = shift;
  $self->{realm} = $realm;
}

sub handle {
  my $self = shift;
  my $context = shift;
  my $cred = $context->{request}->header('Authorization');
  if ( defined($cred) && $cred =~ /^Basic\s+(.*)$/ ) {
    my $unscrambled = decode_base64($1);
    if ( my($username,$password) = ( $unscrambled=~/^(.*?):(.*)/ ) ) {
      $context->{basic_username} = $username;
      $context->{basic_password} = $password;
      return H_CONT;
    }
  }
  # respond with basic auth challenge
  return $self->authen_challenge($context);
}

sub authen_challenge {
  my $self = shift;
  my $context = shift;
  my $realm = $self->{realm};
  $context->{response}->header('WWW-Authenticate', 
			       qq{Basic realm="$realm"});
  $context->{response}->code( RC_UNAUTHORIZED );
  $context->{response}->content( "<HTML><BODY>Unauthorized</BODY></HTML>\n" );
  return H_FINAL;
}

1;
__END__

=pod

=head1 NAME

POE::Component::Server::HTTPServer::BasicAuthenHandler - Basic HTTP Basic Authentication

=head1 SYNOPSIS

    use POE::Component::Server::HTTPServer;
    
    my $server = POE::Component::Server::HTTPServer->new();
    $server->handlers( [
        '/protected' => new_handler( 'BasicAuthenHandler', 'realm' ),
        '/protected' => MyAuthorizationHandler->new(),
        '/protected' => new_handler( 'StaticHandler', './secretdox' ),
    ] );

=head1 DESCRIPTION

BasicAuthenHandler performs the necessary processing on requests to
support HTTP Basic authentication.  If the user-agent making the
request supplies authentication information (via the
C<WWW-Authenticate> header), this handler extracts the supplied user
name and password and sets the context attributes C<basic_username>
and C<basic_password> respectively.  If no authentication is given,
the handler generates and returns an appropriate C<403 Unauthorized>
response.

Note that this handler performs authentication only, it does not
perform authorization.  You will need to supply logic to check the
user name and password for your own purposes.

=head1 SEE ALSO

L<POE::Component::Server::HTTPServer::Handler>

=head1 AUTHOR

Greg Fast <gdf@speakeasy.net>

=head1 COPYRIGHT

Copyright 2003 Greg Fast.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
