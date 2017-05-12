package POE::XS::Loop::Poll;
use strict;
use vars qw(@ISA $VERSION);
BEGIN {
  unless (defined &POE::Kernel::TRACE_CALLS) {
    # we ignore TRACE_DEFAULT, since it's not really standard POE and it's
    # noisy
    *POE::Kernel::TRACE_CALLS = sub () { 0 };
  }
  $VERSION = '1.000';
  eval {
    # try XSLoader first, DynaLoader has annoying baggage
    require XSLoader;
    XSLoader::load('POE::XS::Loop::Poll' => $VERSION);
    1;
  } or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    bootstrap POE::XS::Loop::Poll $VERSION;
  }
}

require POE::Loop::PerlSignals;

if ((POE::Kernel::TRACE_FILES() || POE::Kernel::TRACE_EVENTS()) 
    && !tracing_enabled()) {
  print POE::Kernel::TRACE_FILE "<xx> ", __PACKAGE__, " was built without tracing enabled, build with perl Makefile.PL --trace to enable tracing\n";
}

# everything else is XS
1;

__END__

=head1 NAME

POE::XS::Loop::Poll - an XS implementation of POE::Loop, using poll(2).

=head1 SYNOPSIS

  use POE::Kernel { loop => 'POE::XS::Loop::Poll' };

=head1 DESCRIPTION

This class is an implementation of the abstract POE::Loop interface
written in C using the poll(2) system call.

Signals are left to POE::Loop::PerlSignals.

=head1 SEE ALSO

POE, POE::Kernel, POE::Loop.

=head1 BUGS

Relies upon small fd numbers, but then a lot of code does.

Will fail badly if your code uses POE from more than one Perl thread.

poll() on OS X doesn't support ptys, hence POE::XS::Loop::Poll won't
work with ptys on OS X.

If you see an error:

  POE::XS::Loop::Poll hasn't been initialized correctly

then the loop hasn't been loaded correctly, in POE <= 1.287 the
following:

  # this doesn't work
  use POE qw(XS::Loop::Poll);

will not load the loop correctly, you will need to do:

  use POE::Kernel { loop => 'POE::XS::Loop::Poll' };
  use POE;

=head1 LICENSE

POE::XS::Loop::Poll is licensed under the same terms as Perl itself.

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=cut

=for poe_tests

sub skip_tests {
  $ENV{POE_EVENT_LOOP} = "POE::XS::Loop::Poll";
  $ENV{POE_LOOP_USES_POLL} = 1;
  return;
}

=cut
