package Sentry::SDK;
use Mojo::Base -base, -signatures;

use version 0.77;
use Mojo::Util 'dumper';
use Sentry::Client;
use Sentry::Hub;

our $VERSION = version->declare('0.10.3');

sub _call_on_hub ($method, @args) {
  my $hub = Sentry::Hub->get_current_hub();

  if (my $cb = $hub->can($method)) {
    return $cb->($hub, @args);
  }

  die
    "No hub defined or $method was not found on the hub, please open a bug report.";
}

sub _init_and_bind ($options) {
  my $hub    = Sentry::Hub->get_current_hub();
  my $client = Sentry::Client->new(_options => $options);
  $hub->bind_client($client);
}

sub init ($package, $options = {}) {
  $options->{default_integrations} //= [];
  $options->{dsn}                  //= $ENV{SENTRY_DSN};
  $options->{traces_sample_rate}   //= $ENV{SENTRY_TRACES_SAMPLE_RATE};
  $options->{release}              //= $ENV{SENTRY_RELEASE};
  $options->{environment}          //= $ENV{SENTRY_ENVIRONMENT};
  $options->{_metadata}            //= {};
  $options->{_metadata}{sdk}
    = { name => 'sentry.perl', packages => [], version => 'fixme' };

  _init_and_bind($options);
}

sub capture_message ($self, $message, $capture_context = undef) {
  my $level = ref($capture_context) ? undef : $capture_context;

  _call_on_hub(
    'capture_message',
    $message, $level,
    {
      originalException => $message,
      capture_context   => ref($capture_context) ? $capture_context : undef,
    }
  );
}

sub capture_event ($package, $event) {
  _call_on_hub('capture_exception', $event);
}

sub capture_exception ($package, $exception, $capture_context = undef) {
  _call_on_hub('capture_exception', $exception, $capture_context);
}

sub configure_scope ($package, $cb) {
  Sentry::Hub->get_current_hub()->configure_scope($cb);
}

sub add_breadcrumb ($package, $crumb) {
  Sentry::Hub->get_current_hub()->add_breadcrumb($crumb);
}

sub start_transaction ($package, $context, $custom_sampling_context = undef) {
  return _call_on_hub('start_transaction', $context, $custom_sampling_context);
}

1;

__END__

=encoding utf-8

=head1 NAME

Sentry::SDK - sentry.io integration

=head1 SYNOPSIS

  use Sentry::SDK;

=head1 DESCRIPTION

=head1 AUTHOR

Philipp Busse E<lt>pmb@heise.deE<gt>

=head1 COPYRIGHT

Copyright 2021- Philipp Busse

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
