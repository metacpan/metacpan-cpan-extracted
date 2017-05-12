package PXP::Extension;

use strict;
use warnings;

=pod

=head1 NAME

  PXP::Extension - Extension model class (used only in the internal registry)

=head1 SYNOPSIS


=head1 DESCRIPTION

An extension is a new processing element that can be added to the framework. An extension is typically bundled inside a C<Plugin> with other C<Extension>s.

This class is used only in the internal registry to store definitions of C<Extension>s. Plugin developers MUST NOT use this class.

There are no rules or specific interfaces enforced by the framework. However, specific extension points may mandate the use of a specific interface for their own extensions. This choice is left to designers of new extension points.

=cut


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

  # FIXME : wtf !?
  die "BLABLA".Data::Dumper::Dumper($self) unless ($plugin && ref($plugin) && $plugin->isa('PXP::Plugin'));
  return ($plugin && ref($plugin) && $plugin->isa('PXP::Plugin')) ? $self : undef;

  return $self;
}

=pod "

=over 4

=item I<name>, I<id>, I<version>

Basic accessors for extension properties.

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

sub point {
  my $self = shift;
  if (@_) {
    $self->{point} = shift;
    return $self;
  } else {
    return $self->{point};
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

sub node {
  my $self = shift;
  if (@_) {
    $self->{'node'} = shift;
    return $self;
  } else {
    return $self->{'node'};
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

1;

=pod "

=head1 SEE ALSO

C<PXP::Plugin>, C<PXP::PluginRegistry>

See the article on eclipse.org describing the plugin architecture : 
http://www.eclipse.org/articles/Article-Plug-in-architecture/plugin_architecture.html

=cut "

1;
