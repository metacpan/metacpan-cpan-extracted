###########################################
package OAuth::Cmdline::Mojo;
###########################################
use strict;
use warnings;
use Mojo::Base 'Mojolicious';

our $VERSION = '0.07'; # VERSION
# ABSTRACT: Run a standalone token collector

###########################################
sub startup {
###########################################
  my( $self ) = @_;

  my $renderer = $self->renderer();
  push @{$renderer->paths}, $self->template_path();

  $self->routes->get('/')->to('main#root');
  $self->routes->get('/callback')->to('main#callback');
}

###########################################
sub template_path {
###########################################
  my( $self ) = @_;

    # point renderer to where our .html.ep 
    # templates are installed
  my $dir = $INC{ 'OAuth/Cmdline.pm' };
  $dir =~ s/\.pm//;
  $dir .= "/templates";

  return $dir;
}

###########################################
package OAuth::Cmdline::Mojo::Main;
###########################################
use Mojo::Base 'Mojolicious::Controller';

###########################################
sub root {
###########################################
  my ( $self ) = @_;

  $self->stash->{ login_url } = $self->app->{ oauth }->full_login_uri();
  $self->stash->{ site }      = $self->app->{ oauth }->site();

  $self->render( "main" );
}

###########################################
sub callback {
###########################################
  my ( $self ) = @_;

  my $code = $self->param( "code" );

  $self->app->{ oauth }->tokens_collect( $code );
  
  $self->render( 
      text   => "Tokens saved in " . $self->app->{ oauth }->cache_file_path,
      layout => 'default' );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuth::Cmdline::Mojo - Run a standalone token collector

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use OAuth::Cmdline::Mojo;
    app->start();

=head1 DESCRIPTION

OAuth::Cmdline::Mojo starts a web server, to which you should
point your browser, in order to go through the OAuth rigamarole and
collect the tokens for later use in command line scripts.

=head1 AUTHOR

Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Mike Schilli.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
