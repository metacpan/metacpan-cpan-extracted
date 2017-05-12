package POE::XS::Loop::EPoll;
use strict;
use vars qw(@ISA $VERSION);
BEGIN {
  unless (defined &POE::Kernel::TRACE_CALLS) {
    # we ignore TRACE_DEFAULT, since it's not really standard POE and it's
    # noisy
    *POE::Kernel::TRACE_CALLS = sub () { 0 };
  }
  $VERSION = '1.003';
  require XSLoader;
  XSLoader::load('POE::XS::Loop::EPoll' => $VERSION);
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

POE::XS::Loop::EPoll - an XS implementation of POE::Loop, using Linux` epoll(2).

=head1 SYNOPSIS

  use POE::Kernel { loop => 'POE::XS::Loop::EPoll' };

=head1 DESCRIPTION

This class is an implementation of the abstract POE::Loop interface
written in C using the Linux epoll(2) family of system calls.

Signals are left to POE::Loop::PerlSignals.

The epoll_ctl() call returns an error when you attempt to poll regular
files, POE::XS::Loop::EPoll emulate's poll(2)'s behaviour with regular
files under Linux - ie. they're always readable/writeable.

If you see an error:

  POE::XS::Loop::EPoll hasn't been initialized correctly

then the loop hasn't been loaded correctly, in POE <= 1.287 the
following:

  # this doesn't work
  use POE qw(XS::Loop::EPoll);

will not load the loop correctly, you will need to do:

  use POE::Kernel { loop => 'POE::XS::Loop::EPoll' };
  use POE;

=head1 SEE ALSO

POE, POE::Loop, POE::XS::Loop::Poll.

=head1 BUGS

Relies upon small fd numbers, but then a lot of code does.

New bugs should be reported via request tracker, either mail to:

  bug-POE-XS-Loop-EPoll@rt.cpan.org

or using the form at:

  https://rt.cpan.org/Ticket/Create.html?Queue=POE-XS-Loop-EPoll

=head1 LICENSE

POE::XS::Loop::EPoll is licensed under the same terms as Perl itself.

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=cut

=for poe_tests

sub skip_tests {
  $ENV{POE_EVENT_LOOP} = 'POE::XS::Loop::EPoll';
  return;
}

=cut
