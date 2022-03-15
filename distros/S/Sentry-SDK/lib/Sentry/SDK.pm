package Sentry::SDK;
use Mojo::Base -base, -signatures;

use version 0.77;
use Mojo::Util 'dumper';
use Sentry::Client;
use Sentry::Hub;
use Sentry::Logger 'logger';

our $VERSION = version->declare('v1.0.17');

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
    = { name => 'sentry.perl', packages => [], version => $VERSION };

  logger->active_contexts(['.*']) if $options->{debug} // $ENV{SENTRY_DEBUG};

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
  _call_on_hub('capture_event', $event);
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

  Sentry::SDK->init({
    dsn => "https://examplePublicKey@o0.ingest.sentry.io/0",

    # Adjust this value in production
    traces_sample_rate => 1.0,
  });

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 init

  Sentry::SDK->init(\%options);

Initializes the Sentry SDK in your app. The following options are provided:

=head3 dsn

The DSN tells the SDK where to send the events. If this value is not provided, the SDK will try to read it from the C<SENTRY_DSN> environment variable. If that variable also does not exist, the SDK will just not send any events.

=head3 release

Sets the release. Defaults to the C<SENTRY_RELEASE> environment variable.

=head3 environment

Sets the environment. This string is freeform and not set by default. A release can be associated with more than one environment to separate them in the UI (think staging vs prod or similar).

By default the SDK will try to read this value from the C<SENTRY_ENVIRONMENT> environment variable.

=head3 traces_sample_rate

A number between 0 and 1, controlling the percentage chance a given transaction will be sent to Sentry. (0 represents 0% while 1 represents 100%.) Applies equally to all transactions created in the app. This must be defined to enable tracing.

=head3 integrations

  Sentry::SDK->init({
    integrations => [My::Integration->new],
  });

Enables your custom integration. Optional.

=head3 default_integrations

This can be used to disable integrations that are added by default. When set to a falsy value, no default integrations are added.

=head3 debug

Enables debug printing.

=head2 add_breadcrumb

  Sentry::SDK->add_breadcrumb({
    category => "auth",
    message => "Authenticated user " . user->{email},
    level => Sentry::Severity->Info,
  });

You can manually add breadcrumbs whenever something interesting happens. For example, you might manually record a breadcrumb if the user authenticates or another state change happens.

=head2 capture_exception

  eval {
    $app->run();
  };
  if ($@) {
    Sentry::SDK->capture_exception($@);
  }

You can pass an error object to capture_exception() to get it captured as event. It's possible to throw strings as errors.

=head2 capture_message

  Sentry::SDK->capture_message("Something went wrong");

Another common operation is to capture a bare message. A message is textual information that should be sent to Sentry. Typically messages are not emitted, but they can be useful for some teams.

=head2 capture_event

  Sentry::SDK->capture_event(\%data);

Captures a manually created event and sends it to Sentry.

=head2 configure_scope

  Sentry::SDK->configure_scope(sub ($scope) {
    $scope->set_tag(foo => "bar");
    $scope->set_user({id => 1, email => "john.doe@example.com"});
  });

When an event is captured and sent to Sentry, event data with extra information will be merged from the current scope. The C<configure_scope> function can be used to reconfigure the current scope. This for instance can be used to add custom tags or to inform sentry about the currently authenticated user. See L<Sentry::Hub::Scope> for further information.

=head2 start_transaction

  my $transaction = Sentry::SDK->start_transaction({
    name => 'MyScript',
    op => 'http.server',
  });

  Sentry::SDK->configure_scope(sub ($scope) {
    $scope->set_span($transaction);
  });

  # ...

  $transaction->set_http_status(200);
  $transaction->finish();

Is needed for recording tracing information. Transactions are usually handled by the respective framework integration. See L<Sentry::Tracing::Transaction>.

=head1 AUTHOR

Philipp Busse E<lt>pmb@heise.deE<gt>

=head1 COPYRIGHT

Copyright 2021- Philipp Busse

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
