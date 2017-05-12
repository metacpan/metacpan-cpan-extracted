#!perl -T
use Test::More tests => 3;

# does the Signals::XSIG module compile and load without incident?

BEGIN {
  use_ok('Signals::XSIG') || print "Bail out!\n";
}
ok(defined &Signals::XSIG::_resolve_signal, "_resolve_signal");
ok(!defined &Signals::XSIG::bogus_function, "!bogus_function");

diag('Testing Signals::XSIG '
     . "$Signals::XSIG::VERSION, Perl $], $^X");


__END__

Signals::XSIG test plans:

Do we need to do some special tests for $SIG{ALRM} ?
Those seem to cause special problems on freebsd .
