package Mojolicious::Plugin::AutoRoute;
use Mojo::Base 'Mojolicious::Plugin';

use File::Find 'find';

our $VERSION = '0.22';

sub register {
  my ($self, $app, $conf) = @_;
  
  # Parent route
  my $r = $conf->{route} || $app->routes;
  
  # Template Base
  my $template_base_dirs = $app->renderer->paths;
  
  # Top directory
  my $top_dir = $conf->{top_dir} || 'auto';
  $top_dir =~ s#^/##;
  $top_dir =~ s#/$##;
  
  # Search templates
  my @templates;
  for my $template_base_dir (@$template_base_dirs) {
    $template_base_dir =~ s#/$##;
    my $template_dir = "$template_base_dir/$top_dir";
    
    if (-d $template_dir) {
      # Find templates
      find(sub {
        my $template_abs = $File::Find::name;
        my $template = $template_abs;
        $template =~ s/\Q$template_dir\///;
        
        if ($template =~ s/\.html\.ep$//) {
          push @templates, $template;
        }
      }, $template_dir);
    }
  }
  
  # Register routes
  for my $template (@templates) {
    my $route_path = $template eq 'index' ? '/' : $template;
    
    # Route
    $r->route("/$route_path")
      ->to(cb => sub { shift->render("/$top_dir/$template", 'mojo.maybe' => 1) });
  }
}

1;

=head1 NAME

Mojolicious::Plugin::AutoRoute - Mojolicious plugin to create routes automatically

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('AutoRoute');

  # Mojolicious::Lite
  plugin 'AutoRoute';

  # With option
  plugin 'AutoRoute', route => $r;

=head1 DESCRIPTION

L<Mojolicious::Plugin::AutoRoute> is a L<Mojolicious> plugin
to create routes automatically.

If you put templates into C<auto> directory,
the corresponding routes is created automatically.

For example:

  TEMPLATES                           ROUTES
  templates/auto/index.html.ep        # /
                /foo.html.ep          # /foo
                /foo/bar.html.ep      # /foo/bar
                /foo/bar/baz.html.ep  # /foo/bar/baz

I like PHP simplicity. All thing needed is that you put PHP files into some directory,
and write program. You don't need to create routes manually.

This plugin gives PHP simplicity to L<Mojolicious>.

=head1 EXAMPLE

  use Mojolicious::Lite;
  
  # AutoRoute
  plugin 'AutoRoute';
  
  # Custom routes
  get '/create/:id' => sub { shift->render_maybe('/create') };
  
  app->start;
  
  __DATA__
  
  @@ auto/index.html.ep
  /
  
  @@ auto/foo.html.ep
  /foo
  
  @@ auto/bar.html.ep
  /bar
  
  @@ auto/foo/bar/baz.html.ep
  /foo/bar/baz
  
  @@ auto/json.html.ep
  <%
    $self->render(json => {foo => 1});
    return;
  %>
  
  @@ create.html.ep
  /create/<%= $id %>

=head1 OPTIONS

=head2 route

  route => $route;

You can set parent route if you need.
This is L<Mojolicious::Routes> object.
Default is C<$app->routes>.

=head2 top_dir

  top_dir => 'myauto'

Top directory. default is C<auto>.

=head1 TIPS

If you want to create custom route, use C<render_maybe> method.

  # Mojolicious Lite
  any '/foo' => sub { shift->render_maybe('/foo') };

  # Mojolicious
  $r->any('/foo' => sub { shift->render_maybe('/foo') };

For backwrod comaptible, you can use C<template> function.

  use Mojolicious::Plugin::AutoRoute::Util 'template';
  
  # Mojolicious Lite
  any '/foo' => template '/foo';

  # Mojolicious
  $r->any('/foo' => template '/foo');

=head1 METHOD

=head2 register

  $plugin->register($app);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
