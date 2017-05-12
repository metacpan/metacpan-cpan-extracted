package Some::Package;

use Signals::XSIG;
use t::SignalHandlerTest;
use Test::More tests => 14;
use Config;
use strict;
use warnings;

# when we set %SIG directly, are the installed signal handlers
# reflected in %XSIG?

ok(tied %SIG, "\%SIG is tied");

my ($s1,$s2) = appropriate_signals();
@SIG{ ($s1,$s2) } = ('IGNORE','DEFAULT');
ok($SIG{$s1} eq 'IGNORE');
ok($SIG{$s2} eq 'DEFAULT');
ok($XSIG{$s1}[0] eq 'IGNORE');
ok($XSIG{$s2}[0] eq 'DEFAULT');
ok(tied %SIG);

%SIG = ();
ok(!defined $SIG{$s1}, "SIG$s1(1) handler undef after %SIG cleared")
    or diag "Defined handlers: @{[grep defined $SIG{$_},keys %SIG]}";
ok(!defined $SIG{$s2}, "SIG$s2(2) handler undef after %SIG cleared")
    or diag "Defined handlers: @{[grep defined $SIG{$_},keys %SIG]}";

ok(tied %SIG);

if ($Config{PERL_VERSION} != 8) {
  %SIG = ($s1 => 'foo', $s2 => *foo);
  ok($SIG{$s1} eq 'main::foo');
  ok($SIG{$s2} eq *Some::Package::foo);
  ok($XSIG{$s1}[0] eq 'main::foo');
} else { # assign typeglob to tied hash element not ok in 5.8
  %SIG = ($s1 => 'foo', $s2 => \&foo);
  ok($SIG{$s1} eq 'main::foo');
  ok($SIG{$s2} eq \&Some::Package::foo);
  ok($XSIG{$s1}[0] eq 'main::foo');
}
ok($XSIG{$s2}[0] eq $SIG{$s2});
ok(tied %SIG);
