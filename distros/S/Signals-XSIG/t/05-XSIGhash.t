package Some::Package;

use Signals::XSIG;
use t::SignalHandlerTest;
use Test::More tests => 19;
use Config;
use strict;
use warnings;

# are signal handlers registered correctly when we
# set %XSIG directly?

sub oof { 42 } ;

my ($s1,$s2) = appropriate_signals();

ok(tied %XSIG, '%XSIG tied');
ok(tied @{$XSIG{$s1}} && tied @{$XSIG{$s2}},
  "\@{\$XSIG{sig}} tied for valid sigs $s1,$s2");

@XSIG{($s1,$s2,"bogus")} = (['foo'],['bar',undef,\&oof],['arbitrary']);

ok($XSIG{$s1}[0] eq 'main::foo', 
   'element assignment from @XSIG{@KEYS}=@VALUES style initializer');
ok($XSIG{$s2}[0] eq 'main::bar', 'element assignment from initializer');
ok($XSIG{$s2}[2] eq \&oof, 'element assignment from initializer');
ok($XSIG{"bogus"}[0] eq 'arbitrary', 'bogus key in initializer list ok');
ok(tied @{$XSIG{$s1}} && tied @{$XSIG{$s2}},
   "\@{\$XSIG{sig}} still tied for $s1,$s2 after assignment");
ok(!defined($XSIG{$s2}[1]), 'assignment of 2nd sighandler to undef respected');
ok(defined($XSIG{'bogus'}) && !tied @{$XSIG{'bogus'}},
   '@{$XSIG{key}} not tied for non-signal key');


if ($Config{PERL_VERSION} != 8) {
  %XSIG = ($s1 => [undef,undef,'qwert'],
	   $s2 => [\&oof, \&oof, *oof],
	   'bogus' => 'arbitrary');
  ok($XSIG{$s2}[2] eq *Some::Package::oof,
     'glob element qualified in %XSIG=... assignment');
} else {
  %XSIG = ($s1 => [undef,undef,'qwert'],
	   $s2 => [\&oof, \&oof, undef],
	   'bogus' => 'arbitrary');
  ok(1, '# 5.8: can\'t test assignment with glob in initializer');
}

ok(!defined $XSIG{$s1}[0] && !defined $XSIG{$s1}[1] 
   && defined $XSIG{$s1}[2],
   'elements initialized in %XSIG=... assignment');
ok($XSIG{$s1}[2] eq 'main::qwert', 
   'element qualified in %XSIG=... assignment');
ok($XSIG{$s2}[0] eq $XSIG{$s2}[1] && $XSIG{$s2}[0] eq \&oof,
   'code ref element initialized in %XSIG=... assignment');
ok($XSIG{'bogus'} eq 'arbitrary',
   'unrecognized key initialized in %XSIG=... assignment');
ok(tied @{$XSIG{$s1}} && tied @{$XSIG{$s2}},
   '@{$XSIG{sig}} still tied after %XSIG=(key-value list) style assignment');

ok(ref $XSIG{'bogus'} ne 'ARRAY',
   'non-signame %XSIG element not cast to array');


($s1,$s2) = alias_pair();

%XSIG = ();
ok(exists $XSIG{$s1} && exists $XSIG{$s2},
   '%XSIG still has elements after clear');
ok(!exists $XSIG{'bogus'},
   '%XSIG does not have non-signame elements after clear');
ok(tied @{$XSIG{$s1}} && @{$XSIG{$s2}},
   '%XSIG elements still tied after clear');

