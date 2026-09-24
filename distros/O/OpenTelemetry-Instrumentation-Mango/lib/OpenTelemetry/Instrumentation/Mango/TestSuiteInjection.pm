package OpenTelemetry::Instrumentation::Mango::TestSuiteInjection;
# ABSTRACT: Inject the Mango instrumentation into a third party test suite

our $VERSION = '0.01';

use strict;
use warnings;

INIT {
    require OpenTelemetry::Instrumentation;
    OpenTelemetry::Instrumentation->import('Mango');
}

1;

=encoding utf8

=head1 NAME

TestSuiteInjection - Run OpenTelemetry::Instrumentation::Mango in existing test suites

=head1 DESCRIPTION

This is a utility module to inject instrumentation into Mango instances in existing
test suites -like the stock Mojolicious test suite- to make sure we are not introducing
unintended regressions.

  $ git clone https://github.com/oliwer/mango.git
  $ cd mango
  $ PERL5OPT=-MOpenTelemetry::Instrumentation::Mango::TestSuiteInjection prove -l t/

=head1 SEE ALSO

L<OpenTelemetry::Instrumentation::Mango>, L<Mango>

=cut