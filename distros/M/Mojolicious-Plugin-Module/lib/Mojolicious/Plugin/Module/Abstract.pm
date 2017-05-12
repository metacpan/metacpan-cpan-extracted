package Mojolicious::Plugin::Module::Abstract;
use Mojo::Base -base;
use Mojo::Util 'decamelize';
use YAML;
use Hash::Merge::Simple qw/merge/;

has 'routes';
has 'config' => sub { {} };

sub init {
  my ($self, $app, $path) = @_;
  $self->init_config($app, $path);
  $self->init_routes($app);
  $self->init_templates($app);
  $self->init_helpers($app);
  $self->startup($app);
}

sub init_routes {}

sub init_helpers {}

sub startup {}

sub init_templates {
  my ($self, $app) = @_;
  my $pkg = decamelize ref $self;
  $pkg =~ s/-/\//;
  
  return if !-d $self->config->{path}.'/templates/'.$pkg;
  my $paths = $app->renderer->paths;
  unshift @$paths, $self->config->{path}.'/templates/'.$pkg;
  $app->renderer->paths($paths);
}

sub init_config {
  my ($self, $app, $path) = @_;
  my $pkg = decamelize ref $self;
  $pkg =~ s/-/\//;
  my $fh;
  
  open($fh, "./config/$pkg.yaml") and do {
    local $/;
    my ($data) = Load(<$fh>);
    $self->config($data);
    close $fh;
  };
  $self->config({ %{$self->config}, path => $path });
  
  open($fh, $self->config->{path}.'/config/module.yaml') and do {
    local $/;
    my ($data) = Load(<$fh>);
    close $fh;
    $self->config(merge $data, $self->config);
  };
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::Module::Abstract - Abstract class for modules.

=head1 OVERVIEW

Abstract class for modules provides methods to init some aspects of modules such as routes,
templates, configs, etc. Use it to define your modules.

=head2 Methods

=head3 init($self, $app, $path)

Initialize module.

=over

=item $app

Current mojolicious application object.

=item $path

Path to this module in filesystem.

=back

=head3 init_templates($self, $app)

Add templates paths to mojolicious renderer.

=over

=item $app

Current mojolicious application object.

=back

=head3 init_config($self, $app, $path)

Looks for C<./config/module.conf> config in YAML format an load it. Also trying to load local
config for this module from application C<config/vendor/module_name.yaml>(YAML too). Configs will
be merged.

You can get module's config this way:

  $app->module->get('module_name')->config->{some_config_key}

Or directly from module object.

=over

=item $app

Current mojolicious application object.

=item $path

Path to this module in filesystem. Will be in C<config->{path}>.

=back

=head3 init_routes($self, $app)

Override this method in your module and define routes.

=head3 init_helpers($self, $app)

Override this method in your module and define helpers.

=head3 startup($self, $app)

Override this method in your module if module needs some more initialization code.

=head1 SEE ALSO

L<Mojolicious::Plugin::Module>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
