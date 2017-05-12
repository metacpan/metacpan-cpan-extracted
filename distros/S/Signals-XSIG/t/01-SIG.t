use Signals::XSIG;
use Test::More tests => 88;
use t::SignalHandlerTest;
use Config;
use strict;
use warnings;

# when we set $SIG{signal}, is the registered signal handler
# reflected in $XSIG{signal}?

my $sig = appropriate_signals();

sub ok_sig_is {
  no warnings 'uninitialized';
  my ($sig, $is) = @_;
  my $display_is 
    = defined($is) ? ref($is) ? ref($is)." ref" : "'$is'" : "<undef>";
  my $display_sig
    = defined($sig) ? ref($sig) ? ref($sig)." ref" : "'$sig'" : "<undef>";
  ok($SIG{$sig} eq $is  &&  defined($SIG{$sig})==defined($is),
     "\$SIG{$sig} assignment to $display_is ok")
    or diag("\$SIG{sig} was $SIG{$sig}, expected $display_is");
  ok($XSIG{$sig}[0] eq $is, "ok for \$XSIG{$sig} => $display_is, too");
}

ok(tied %SIG);

sub foo { 42 }

################### valid signal name ###############

foreach my $func ('DEFAULT', 'IGNORE', '', undef, 'qualified::name',
		  *qualified::glob, \&foo) {

 SKIP:{ 
    if ($Config{PERL_VERSION} == 8 && defined($func) 
	&& substr($func,0,1) eq '*') {
      skip '5.8: $tiedHash{$key} = *glob assignment not allowed', 2;
    } elsif ($Config{PERL_VERSION} == 8 && !defined($func)) {
      # in 5.8 assignment to undef becomes assignment to ''
      delete $SIG{$sig};
    } else {
      $SIG{$sig} = $func;
    }
    ok_sig_is($sig, $func);
  }
}

$SIG{$sig} = 'unqualified_name';
ok_sig_is($sig, 'main::unqualified_name');

SKIP: {
  if ($Config{PERL_VERSION} == 8) {
    skip '5.8: $tiedHash{$key} = *glob assignment not allowed', 2;
  }
  $SIG{$sig} = *unqualified_glob;
  ok_sig_is($sig, *main::unqualified_glob);
}

{
  package Some::Package;
  use Config;

  $SIG{$sig} = 'another_unqualified';
  main::ok_sig_is($sig, 'main::another_unqualified');

 SKIP: {
    if ($Config{PERL_VERSION} == 8) {
      Test::More::skip '5.8: $tiedHash{$key} = *glob assignment not allowed', 
	  2;
    }
    $SIG{$sig} = *another_unqualified;
    main::ok_sig_is($sig, *Some::Package::another_unqualified);
  }
}

$SIG{$sig} = sub { 19 };
ok(ref $SIG{$sig} eq 'CODE', '\%SIG CODE ref assignment');
ok(ref $XSIG{$sig}[0] eq 'CODE', '\%XSIG CODE ref assignment');
ok($SIG{$sig} eq $XSIG{$sig}[0], '\%SIG,\%XSIG equivalent');


# core dump somewhere soon after this line on Strawberry Perl 5.8.9, 5.10.1


SKIP: {
  if ($^O eq 'MSWin32' && $] < 5.012) {
    skip "can't test delete $SIG{$sig} on MSWin32 v<5.12", 2;
  }
  delete $SIG{$sig};
  ok_sig_is($sig, undef);
}


####################### alias signal name ######################

my $alias;
($sig,$alias) = alias_pair();

# diag("sig => $sig, alias => $alias");

foreach my $func ('DEFAULT', 'IGNORE', '', undef, 'qualified::name',
		  *qualified::glob, \&foo) {

  # assignment to alias or nominal signal name
  # should have the same effect
 SKIP: {
    no warnings 'uninitialized';
    if ($Config{PERL_VERSION} == 8 && defined($func) 
	&& substr($func,0,1) eq '*') {
      skip '5.8: $tiedHash{$key} = *glob assignment not allowed', 4;
    } else {
        my $mnem = rand() > 0.5 ? $sig : $alias;
        if ($Config{PERL_VERSION} == 8 && !defined($func)) {
            delete $SIG{$mnem};
        } else {
            $SIG{$mnem} = $func;
        }
    }
    ok_sig_is($alias, $func);
    ok_sig_is($sig, $func);
  }
}

$SIG{$alias} = 'unqualified_name';
ok_sig_is($sig, 'main::unqualified_name');
ok_sig_is($alias, 'main::unqualified_name');

SKIP: {
  if ($Config{PERL_VERSION} == 8) {
    skip '5.8: $tiedHash{$key} = *glob assignment not allowed', 4;
  }
  $SIG{$alias} = *unqualified_glob;
  ok_sig_is($sig, *main::unqualified_glob);
  ok_sig_is($alias, *main::unqualified_glob);
}

{
  package Some::Package;
  use Config;

  $SIG{$sig} = 'another_unqualified';
  main::ok_sig_is($sig, 'main::another_unqualified');
  main::ok_sig_is($alias, 'main::another_unqualified');

 SKIP: {
    if ($Config{PERL_VERSION} == 8) {
      Test::More::skip '5.8: $tiedHash{$key} = *glob assignment not allowed', 
	  4;
    }
    $SIG{$sig} = *another_unqualified;
    main::ok_sig_is($sig, *Some::Package::another_unqualified);
    main::ok_sig_is($alias, *Some::Package::another_unqualified);
  }

}

$SIG{$alias} = sub { 19 };
ok(ref $SIG{$sig} eq 'CODE');
ok(ref $XSIG{$sig}[0] eq 'CODE');
ok($SIG{$sig} eq $XSIG{$sig}[0]);
ok(ref $SIG{$alias} eq 'CODE');
ok(ref $XSIG{$alias}[0] eq 'CODE');
ok($SIG{$alias} eq $XSIG{$alias}[0]);
ok($SIG{$sig} eq $SIG{$alias});

SKIP: {
  if ($^O eq 'MSWin32' && $] < 5.12) {
    skip "Can't delete \$SIG{\$sig} on MSWin32 v<5.12", 4;
  }
  delete $SIG{$alias};
  ok_sig_is($sig, undef);
  ok_sig_is($alias, undef);
}

ok(tied %SIG);

#################### bogus signal ###############

no warnings 'signal';
$sig = 'xyz';

ok(!defined($SIG{$sig}));

$SIG{$sig} = 'IGNORE';
ok($SIG{$sig} eq 'IGNORE');

$SIG{$sig} = 'foo';
ok($SIG{$sig} eq 'foo',
   "unqualified assignment to bogus signal not qualified");

delete $SIG{$sig};
ok(!defined $SIG{$sig}, "\$SIG{$sig} not defined after delete");

