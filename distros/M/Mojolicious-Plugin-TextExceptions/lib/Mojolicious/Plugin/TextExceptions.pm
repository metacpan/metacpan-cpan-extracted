package Mojolicious::Plugin::TextExceptions;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

sub register {
  my ($self, $app, $config) = @_;
  my $ua_re = $config->{ua_re} || qr{^(?:Mojolicious|curl|Wget)};

  $app->hook(
    before_render => sub {
      my ($c, $args) = @_;
      my $format = $c->stash('format') // 'html';

      return unless $format eq 'html';                  # Do not want to take over API responses
      return unless my $template = $args->{template};
      return unless $template eq 'exception';

      if ($c->req->headers->user_agent =~ $ua_re) {
        @$args{qw(text format)} = ($c->stash->{exception}, 'txt');
      }
    }
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::TextExceptions - Render exceptions as text in command line user agents

=head1 SYNOPSIS

  use Mojolicious::Lite;

  # Only enable this plugin when running tests
  plugin 'TextExceptions' if $ENV{HARNESS_ACTIVE};

  # Only enable this plugin when developing
  plugin 'TextExceptions' if app->mode eq 'development';

  # Always enabling the plugin can leak sensitive information
  # to the end user
  plugin 'TextExceptions';

  plugin 'TextExceptions', ua_re => qr{^LWP}; # Override the default regex for user agent

=head1 DESCRIPTION

This plugin looks for curl/wget/mojo user agent and renders exceptions as text instead of html.

=head1 METHODS

=head2 register

Sets up a before_render hook to look for text based user agents and render exceptions as text.

Currently supports Mojo::UserAgent, curl and wget

=head1 SEE ALSO

L<Mojolicious>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, Marcus Ramberg

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Marcus Ramberg <mramberg@cpan.org>

=head1 CONTRIBUTORS

Jan Henning Thorsen <jhthorsen@cpan.org>

=cut
