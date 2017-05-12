package PlugAuth::Role::Plugin;

use strict;
use warnings;
use 5.010001;
use Role::Tiny;

# ABSTRACT: Role for PlugAuth plugins
our $VERSION = '0.35'; # VERSION


sub init { }


my $config;

sub global_config
{
  $config;
}


sub plugin_config
{
  shift->{plugin_config};
}


my $app;

sub app
{
  $app;
}

sub new
{
  my($class, $global_config, $plugin_config, $theapp) = @_;
  $app = $theapp;
  $config = $global_config;
  my $self = bless {
    plugin_config => $plugin_config,
  }, $class;
  $self->init;
  $self;
}

# undocumented, may go away.
sub _self_auth_plugin
{
  my($class, $new_value) = @_;
  
  state $plugin;
  
  $plugin = $new_value if defined $new_value;
  
  return $plugin;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Role::Plugin - Role for PlugAuth plugins

=head1 VERSION

version 0.35

=head1 SYNOPSIS

 package PlugAuth::Plugin::MyPlugin;
 
 use Role::Tiny::With;
 
 with 'PlugAuth::Role::Plugin';
 
 sub init {
   my($self) = @_;
   # called immediately after plugin is
   # created.
 }
 
 1;

=head1 DESCRIPTION

Use this role when writing PlugAuth plugins.

=head1 OPTIONAL ABSTRACT METHODS

You may define these methods in your plugin.

=head2 $plugin-E<gt>init

This method is called after the object is created.

=head1 METHODS

=head2 $plugin-E<gt>global_config

Get the global PlugAuth configuration (an instance of
L<Clustericious::Config>).

=head2 $plugin-E<gt>plugin_config

Get the plugin specific configuration.  This
method may be called as either an instance or
class method.

=head2 $plugin-E<gt>app

Returns the L<PlugAuth> instance for the running PlugAuth server.

=head1 SEE ALSO

L<PlugAuth>,
L<PlugAuth::Guide::Plugin>

=cut

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
