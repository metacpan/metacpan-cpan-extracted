package POE::Component::Server::HTTPServer::TemplateHandler;
use strict;
use HTTP::Status;
use HTML::Template;
use HTML::Template::HashWrapper;
use POE::Component::Server::HTTPServer::Handler;
use base 'POE::Component::Server::HTTPServer::StaticHandler';

sub handle_plainfile {
  my $self = shift;
  my $filepath = shift;
  my $context = shift;

  unless ( -f $filepath && -r _ ) {
    $context->{error_message} = "No such resource";
    return H_CONT;
  }

  my $ctx_assn = HTML::Template::HashWrapper->new($context);
  my $templ = 
    HTML::Template->new( filename => $filepath,
			 die_on_bad_params => 0,
			 # cache => 1,
			 associate => $ctx_assn,
			 global_vars => 0,
		       );
  $context->{response}->code( RC_OK );
  $context->{response}->content( $templ->output );
  return H_FINAL;
}

1;
__END__

=pod

=head1 NAME

POE::Component::Server::HTTPServer::TemplateHandler - serve templated files

=head1 SYNOPSIS

  use POE::Component::Server::HTTPServer;
  my $server = POE::Component::Server::HTTPServer->new();
  $server->handlers([
                      '/tmpl' => MySetupHandler->new(),
                      '/tmpl' => new_handler('TemplateHandler', './tmpl'),
		    ]);

=head1 DESCIPTION

TemplateHandler resolves requests to files in the file system, then
interprets them as L<HTML::Template> templates.  The context is used
for setting parameters for the template.

This is written primarily as an example of extending StaticHandler,
and is not particularly robust.

=head1 SEE ALSO

L<POE::Component::Server::HTTPServer>,
L<POE::Component::Server::HTTPServer::StaticHandler>,
L<HTML::Template>

=head1 AUTHOR

Greg Fast <gdf@speakeasy.net>

=head1 COPYRIGHT

Copyright 2003 Greg Fast.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
