package Tak::ModuleLoader;

use Tak::ModuleLoader::Hook;
use Moo;

with 'Tak::Role::Service';

has module_sender => (is => 'ro', required => 1);

has inc_hook => (is => 'lazy');

sub _build_inc_hook {
  my ($self) = @_;
  Tak::ModuleLoader::Hook->new(sender => $self->module_sender);
}

sub handle_enable {
  my ($self) = @_;
  push @INC, $self->inc_hook;
  return 'enabled';
}

sub handle_disable {
  my ($self) = @_;
  my $hook = $self->inc_hook;
  @INC = grep $_ ne $hook, @INC;
  return 'disabled';
}

sub DEMOLISH {
  my ($self) = @_;
  $self->handle_disable;
}

1;
