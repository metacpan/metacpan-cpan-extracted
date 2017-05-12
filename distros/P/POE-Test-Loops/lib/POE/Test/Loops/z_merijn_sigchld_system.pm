#!/usr/bin/perl -w
# vim: ts=2 sw=2 expandtab filetype=perl


# System shouldn't fail in this case.

use strict;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

BEGIN {
  package
  POE::Kernel;
  use constant TRACE_DEFAULT => exists($INC{'Devel/Cover.pm'});
}

use POE;

use constant TESTS => 4;
use Test::More tests => TESTS;

my $command = "/bin/true";

SKIP: {
  my @commands = grep { -x } qw(/bin/true /usr/bin/true);
  skip( "Couldn't find a 'true' to run under system()", TESTS ) unless (
    @commands
  );

  my $command = shift @commands;
  diag( "Using '$command' as our thing to run under system()" );

  my $caught_child = 0;

  POE::Session->create(
    inline_states => {
      _start => sub {
        my $sig_chld;

        $sig_chld = $SIG{CHLD};
        $sig_chld = "(undef)" unless defined $sig_chld;
        $! = undef;

        is(
          system( $command ), 0,
          "System returns properly chld($sig_chld) err($!)"
        );

        # system() may return -1 when $SIG{CHLD} is in effect.
        # https://rt.perl.org/rt3/Ticket/Display.html?id=105700
        #
        # The machinations to avoid this in POE would incur an ongoing
        # performance penalty for everyone:
        #
        # 1. Save the contents of $SIG{CHLD}.
        #
        # 2. Set $SIG{CHLD} = 'DEFAULT' before dispatching every
        # event, unless it's already 'DEFAULT'.
        #
        # 3. If $SIG{CHLD} is deliberately to 'DEFAULT' as a result of
        # actions inside a callback, set a flag indicating that the
        # value saved in step #1 should not be restored.
        #
        # 4. At the end of every event, restore $SIG{CHLD} to the
        # saved value, unless the flag not to restore it is set.
        #
        # Less convenient but much more optimal is for application and
        # module developers to localize $SIG{CHLD} = 'DEFAULT' before
        # calling system() or causing a module to call system().

        $_[KERNEL]->sig( 'CHLD', 'chld' );
        $sig_chld = $SIG{CHLD};
        $sig_chld = "(undef)" unless defined $sig_chld;
        $! = undef;

        is(
          system( $command ), 0,
          "System returns properly chld($sig_chld) err($!)"
        );

        # Turn off the handler, and try again.

        $_[KERNEL]->sig( 'CHLD' );
        $sig_chld = $SIG{CHLD};
        $sig_chld = "(undef)" unless defined $sig_chld;
        $! = undef;

        is(
          system( $command ), 0,
          "System returns properly chld($sig_chld) err($!)"
        );
      },
      chld => sub {
        diag( "Caught child" );
        $caught_child++;
      },
      _stop => sub { }, # Pacify assertions.
    }
  );

  is( $caught_child, 0, "no child procs caught" );
}

POE::Kernel->run();

1;
