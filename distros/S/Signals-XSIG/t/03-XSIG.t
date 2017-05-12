package PackageOne;
use Signals::XSIG qw(untied %XSIG);
use t::SignalHandlerTest;
use Test::More tests => 58;
use Config;
use strict;
use warnings;

# are signal handlers registered correctly when we 
# set $XSIG{signal}[index] directly?

my $sig = appropriate_signals();

my $t = $XSIG{$sig};
ok(tied @{$XSIG{$sig}});

sub foo { 42 }

################### valid signal name ###############

foreach my $func ('DEFAULT', 'IGNORE', '', undef, 'qualified::name',
		  *qualified::glob, \&foo) {

 SKIP: {
    no warnings 'uninitialized';
    if ($Config{PERL_VERSION} == 8 && defined($func)
	&& substr($func,0,1) eq '*') {
      skip '5.8: assign *glob to tied hash not ok', 2;
    }
    $XSIG{$sig}[0] = $func;
    ok($XSIG{$sig}[0] eq $func, "\$XSIG{$sig}[0] assign from $func ok");
    ok($SIG{$sig} eq $XSIG{$sig}[0], 
       '$SIG{sig}/$XSIG{sig}[0] equivalent for ' . $func);
  }

}

$XSIG{$sig}[-10] = 'unqualified_name';
ok($XSIG{$sig}[-10] eq 'main::unqualified_name',
   'unqualfied funcname assignment');

SKIP: {
  if ($Config{PERL_VERSION} == 8) {
    skip '5.8: assignment to tied hash elem from *glob not ok', 1;
  }
  $XSIG{$sig}[23] = *unqualified_glob;
  ok($XSIG{$sig}[23] eq *PackageOne::unqualified_glob,
     'assignment from *glob');
}

untied {
  ok($SIG{$sig} eq \&Signals::XSIG::__shadow_signal_handler,
     'untied $SIG{sig} points to Signals::XSIG shadow signal handler');
};

{
  package Package::Two;
  use Signals::XSIG;
  use Config;

  $XSIG{$sig}[-10] = 'another_unqualified';
  PackageOne::ok($XSIG{$sig}[-10] eq 'main::another_unqualified',
		'assign to unqualified func name');

 SKIP: {
    if ($Config{PERL_VERSION} == 8) {
      Test::More::skip '5.8: assign *glob to tied hash not ok', 1;
    }
    $XSIG{$sig}[0] = *another_unqualified;
    PackageOne::ok($XSIG{$sig}[0] eq *Package::Two::another_unqualified,
        'assignment from *glob in separate package');
  }

}

$XSIG{$sig}[44] = sub { 19 };
ok(ref $XSIG{$sig}[44] eq 'CODE', 'assignment to coderef');

delete $XSIG{$sig}[44];
ok(!defined($XSIG{$sig}[44]), 'delete removes $XSIG{sig} entry');

####################### alias signal name ######################

my $alias;
($sig,$alias) = alias_pair();

# diag("sig => $sig, alias => $alias\n");

foreach my $func ('DEFAULT', 'IGNORE', '', undef, 'qualified::name',
		  *qualified::glob, \&foo) {

 SKIP: {
    if ($Config{PERL_VERSION} == 8 && defined($func)
	&& substr($func,0,1) eq '*') {
      skip '5.8: assign *glob to tied hash not ok', 2;
    }

    # assignment to alias or nominal signal name
    # should have the same effect
    if (rand() > 0.5) {
      $XSIG{$alias}[13] = $func;
    } else {
      $XSIG{$sig}[13] = $func;
    }

    no warnings 'uninitialized';
    ok($XSIG{$sig}[13] eq $func, 'main signal handler installed');
    ok($XSIG{$alias}[13] eq $func, 'alias signal handler installed');
  }
}

$XSIG{$alias}[6] = 'unqualified_name';
ok($XSIG{$alias}[6] eq 'main::unqualified_name', 
   'assign unqualified name to alias');
ok($XSIG{$sig}[6] eq $XSIG{$alias}[6],
   'main signal handler matches alias signal handler');

SKIP: {
  if ($Config{PERL_VERSION} == 8) {
    skip '5.8: assign *glob to tied hash elem not ok', 2;
  }
  $XSIG{$alias}[8] = *unqualified_glob;
  ok($XSIG{$sig}[8] eq *PackageOne::unqualified_glob,
     'unqualified glob assignment to alias');
  ok($XSIG{$alias}[8] eq $XSIG{$sig}[8],
      'main signal handler matches alias signal handler');
}

{
  package Some::Package;
  use Signals::XSIG;
  use Config;

  $XSIG{$sig}[77] = 'another_unqualified';
  PackageOne::ok($XSIG{$sig}[77] eq 'main::another_unqualified',
                 'scalar assignment to $XSIG{main} is qualified to main');
  PackageOne::ok($XSIG{$alias}[77] eq $XSIG{$sig}[77],
                 '$XSIG{main} consistent with $XSIG{alias}');

 SKIP: {
    if ($Config{PERL_VERSION} == 8) {
      Test::More::skip '5.8: assign *glob to tied hash elem not ok', 2;
    }
    $XSIG{$alias}[93] = *another_unqualified;
    PackageOne::ok($XSIG{$alias}[93] eq *Some::Package::another_unqualified,
                   'glob assignment to $XSIG{alias} qualified in current package');
    PackageOne::ok($XSIG{$sig}[93] eq $XSIG{$alias}[93],
                   '$XSIG{main} consistent with $XSIG{alias}');
  }
}

$XSIG{$alias}[33] = sub { 19 };
ok(ref $XSIG{$sig}[33] eq 'CODE', 'coderef assignment to $XSIG{main}');
ok(ref $XSIG{$alias}[33] eq 'CODE', '... also assigned to $XSIG{alias}');

delete $XSIG{$alias}[33];
ok(!defined $XSIG{$alias}[33], 'delete remote $XSIG{alias} entry');
ok(!defined $XSIG{$sig}[33], '... and $XSIG{main} entry');

ok(tied @{$XSIG{$sig}}, '@{$XSIG{sig}} still tied');
ok(tied @{$XSIG{$alias}}, '@{$XSIG{alias}} still tied');

#################### bogus signal ###############

no warnings 'signal';
$sig = 'xyz';

ok(!tied $XSIG{$sig}, '$XSIG{bogus} not tied');
ok(!defined($XSIG{$sig}), '$XSIG{bogus} not initially defined');
ok(!defined $SIG{$sig}, '$SIG{bogus} not initially defined');

$XSIG{$sig}[0] = 'IGNORE';
ok($XSIG{$sig}[0] eq 'IGNORE', 'scalar assignment to bogus signal ok');
ok(!defined $SIG{$sig}, "assign to \$XSIG{bogus} does not affect \%SIG");

$XSIG{$sig}[11] = 'foo';
ok($XSIG{$sig}[11] eq 'foo',
   "unqualified assignment to bogus signal not qualified");

delete $XSIG{$sig}[11];
ok(!defined $XSIG{$sig}[11], "\$SIG{$sig} not defined after delete");
ok(!tied $XSIG{$sig}, '$XSIG{bogus} still not tied');

####################### bogus index #######################


