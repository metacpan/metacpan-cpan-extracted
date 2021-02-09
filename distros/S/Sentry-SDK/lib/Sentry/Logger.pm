package Sentry::Logger;
use Mojo::Base -base, -signatures;

use Exporter qw(import);
use List::Util 'any';

our @EXPORT_OK = qw(logger);

has context         => 'Sentry';
has active_contexts => sub { [split(/,/, $ENV{DEBUG} // '')] };

sub _should_print ($self, $context) {
  return any { $context =~ $_ } $self->active_contexts->@*;
}

sub _print ($self, $message, $context, $error = 0) {
  return unless $self->_should_print($context);
  print { $error ? *STDOUT : *STDERR } qq{[$context] $message\n};
}

sub log ($self, $message, $context = $self->context) {
  $self->_print($message, $context);
}

sub warn ($self, $message, $context = $self->context) {
  $self->_print($message, $context, 1);
}

sub error ($self, $message, $context = $self->context) {
  $self->_print($message, $context, 1);
}

sub enable ($self) {
  $self->enabled(1);
}

my $Instance;

sub logger() {
  $Instance //= Sentry::Logger->new;
  return $Instance;
}

1;
