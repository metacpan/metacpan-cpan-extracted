package OpenTelemetry::Instrumentation::Mojo::UserAgent::TestSuiteInjection;
# ABSTRACT: Inject the Mojo::UserAgent instrumentation into a third party test suite

our $VERSION = '0.01';

use strict;
use warnings;

INIT {
    require OpenTelemetry::Instrumentation;
    OpenTelemetry::Instrumentation->import('Mojo::UserAgent');
}

1;

=encoding utf8

=head1 NAME

TestSuiteInjection - Run OpenTelemetry::Instrumentation::Mojo::UserAgent in existing test suites

=head1 DESCRIPTION

This is a utility module to inject instrumentation into Mojo::UserAgent instances in existing
test suites -like the stock Mojolicious test suite- to make sure we are not introducing
unintended regressions.

  $ git clone https://github.com/mojolicious/mojo.git
  $ cd mojo
  $ PERL5OPT=-MOpenTelemetry::Instrumentation::Mojo::UserAgent::TestSuiteInjection prove -l t/

The installation is deferred to INIT time, so that it happens after all compilation is done.
This is important because Mojo modules compile-time constants (eg. TLS and SOCKS support)
depend on the environment, and test scripts commonly tweak the environment for this in
BEGIN blocks, before they load any Mojo module themselves.

=head1 SEE ALSO

L<OpenTelemetry::Instrumentation::Mojo::UserAgent>, L<Mojolicious>

=cut