package PXP::ExtensionPoint;

=pod

=head1 NAME

  PXP::ExtensionPoint - ExtensionPoint model class (used only in the
  internal registry)

=head1 SYNOPSIS


=head1 DESCRIPTION

An extension point is defined by a C<Plugin> to allow other plugins to
extend its fonctionnalities. An extension point is a slot that
extensions can plug into.

This class is used only in the internal registry to store definitions
of C<ExtensionPoint>s. Plugin developers MUST NOT use this class.

PXP::ExtensionPointInterface is a helper module providing the
mandatory interface for objects implementing a new C<ExtensionPoint>.

=cut

use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->init(@_);
}

sub init {
  my $self = shift;
  my $plugin = shift;
  $self->plugin($plugin);
  return ($plugin && ref($plugin) && $plugin->isa('PXP::Plugin')) ? $self : undef;
}

=pod "

=over 4

=item I<name>, I<id>, I<version>

Basic accessors for plugin properties.

=cut "

sub name {
  my $self = shift;
  if (@_) {
    $self->{name} = shift;
    return $self;
  } else {
    return $self->{name};
  }
}

sub id {
  my $self = shift;
  if (@_) {
    $self->{id} = shift;
    return $self;
  } else {
    return $self->{id};
  }
}

sub version {
  my $self = shift;
  if (@_) {
    $self->{version} = shift;
    return $self;
  } else {
    return $self->{version};
  }
}

sub plugin {
  my $self = shift;
  if (@_) {
    $self->{'plugin'} = shift;
    return $self;
  } else {
    return $self->{'plugin'};
  }
}

sub class {
  my $self = shift;
  if (@_) {
    $self->{class} = shift;
    return $self;
  } else {
    return $self->{class};
  }
}

=pod "

=item I<object>

The I<object> accessor returns the object associated with the
extension point, i.e. the _real_ extension point, not the
administrative structure maintained by the registry to track the
extension point hierarchy.

=cut "

sub object {
  my $self = shift;
  if (@_) {
    $self->{object} = shift;
    return $self;
  } else {
    return $self->{object};
  }
}

=pod "

=item I<register>

The I<register> method is called by the PluginRegistry when loading
new C<Extension>s into an C<ExtensionPoint>.  Internally, calls the
actual 'register' method of the real object implementing the
C<ExtensionPoint>.

Return 'undef' if the extension is invalid or if no object has been
mapped with the extension point.

Return the extension itself if it has been successfully added to the
internal registry.

=cut "

sub register {
  my $self = shift;
  my $extension = shift;

  return $self->{object}->register($extension);
}

1;

=pod "

=head1 SEE ALSO

C<PXP::Plugin>, C<PXP::PluginRegistry>

See the article on eclipse.org describing the plugin architecture :
http://www.eclipse.org/articles/Article-Plug-in-architecture/plugin_architecture.html

=cut "
