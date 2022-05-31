package Some::Package;

use Signals::XSIG;
use lib '.';
use t::SignalHandlerTest;
use Test::More tests => 14;
use Data::Dumper;
use Config;
use strict;
use warnings;

# when we set %SIG directly, are the installed signal handlers
# reflected in %XSIG?
#
#    %SIG = (signal1 => handler1, signal2 => handler2, ...)

ok(tied %SIG, "\%SIG is tied");

# enable debugging to diagnose possible intermittent failure
local $Signals::XSIG::XDEBUG = 1;
local $Data::Dumper::Indent = 1;
local $Data::Dumper::Sortkeys = 1;

my ($s1,$s2) = appropriate_signals();
@SIG{ ($s1,$s2) } = ('IGNORE','DEFAULT');
ok($SIG{$s1} eq 'IGNORE', '@SIG{} array slice assignment ok');
ok($SIG{$s2} eq 'DEFAULT', '... assignment ok');
ok($XSIG{$s1}[0] eq 'IGNORE', 'assign to @SIG{} changes %XSIG');
ok($XSIG{$s2}[0] eq 'DEFAULT', '... changes %XSIG');
ok(tied %SIG, '%SIG is still tied');

# clearing %SIG here sometimes causes a BUS error
# (8d9e39ce-406b-11e7-a074-e1beba07c9dd) and sometimes
# it doesn't (3ad3d3ba-404e-11e7-a074-e1beba07c9dd)

if ($] < 5.011) { diag "clearing %SIG" }
%SIG = ();
if ($] < 5.011) { diag "cleared %SIG" }

# intermittent, independent failures in next two tests, freebsd and linux
# and SIGSEGV on v5.8.9
if (!ok(!defined($SIG{$s1}), "SIG$s1(1) handler undef after %SIG cleared")) {
    if ($] == 5.008009) { diag "defined(\$SIG{\$s1:$s1}) test failed" }
    $ENV{XDEBUG} || diag Signals::XSIG::XLOG_DUMP();
}
if (!ok(!defined($SIG{$s2}), "SIG$s2(2) handler undef after %SIG cleared")) {
    if ($] == 5.008009) { diag "defined(\$SIG{\$s2:$s2}) test failed" }
    $ENV{XDEBUG} || diag Signals::XSIG::XLOG_DUMP();
}


diag "checking tied %SIG" if $] == 5.008009;
ok(tied %SIG, '%SIG is still tied');
$ENV{XDEBUG} && diag Signals::XSIG::XLOG_DUMP();
diag "checked tied %SIG" if $] == 5.008009;

if ($Config{PERL_VERSION} != 8) {
    %SIG = ($s1 => 'foo', $s2 => *foo);
    ok($SIG{$s1} eq 'main::foo', 'assign SIG entry to string is qualified');
    ok($SIG{$s2} eq *Some::Package::foo, 'glob assign to SIG entry');
    ok($XSIG{$s1}[0] eq 'main::foo', 'assign to %SIG affects %XSIG');
} else { # assign typeglob to tied hash element not ok in 5.8
    diag "reassigning \%SIG";
    %SIG = ($s1 => 'foo', $s2 => \&foo);
    diag "reassignment ok";
    ok($SIG{$s1} eq 'main::foo', 'scalar assign to %SIG is qualified');
    diag "\$SIG{\$s1:$s1} fetched";
    ok($SIG{$s2} eq \&Some::Package::foo, 'function assigned to %SIG ok');
    ok($XSIG{$s1}[0] eq 'main::foo', 'scalar assign to %SIG affects %XSIG');
}
ok($XSIG{$s2}[0] eq $SIG{$s2}, 'scalar assign to %SIG affects %XSIG');
ok(tied %SIG, '%SIG is still tied');
