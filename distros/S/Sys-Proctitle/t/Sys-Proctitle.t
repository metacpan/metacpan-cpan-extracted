# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sys-Proctitle.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

sub cmdline {
  open my $f, "/proc/$$/cmdline";
  local $/;
  my $rc=<$f>;
  $rc=~s/\0+$//;
  $rc=~s/\0/ /g;
  return $rc;
}

sub procname {
  local $/="\n";
  open my $f, "/proc/$$/status";
  while( defined(my $l=readline $f) ) {
    return $1 if $l=~/^Name:\s*(.*)/;
  }
  return
}

use Test::More tests => 12;
BEGIN { use_ok('Sys::Proctitle') };

my $origcmdline=cmdline;
my $origprocname=procname;

Sys::Proctitle::setproctitle("klaus\0otto");
cmp_ok cmdline, 'eq', 'klaus otto', 'set (cmdline)';
SKIP: {
  skip "kernel too old for prctl(PR_SET_NAME)", 1
    unless Sys::Proctitle::kernel_support;
  cmp_ok procname, 'eq', 'klaus', 'set (procname)';
}

Sys::Proctitle::setproctitle;
cmp_ok cmdline, 'eq', $origcmdline, 'unset (cmdline)';
SKIP: {
  skip "kernel too old for prctl(PR_SET_NAME)", 1
    unless Sys::Proctitle::kernel_support;
  cmp_ok procname, 'eq', $origprocname, 'unset (procname)';
}

Sys::Proctitle::setproctitle("klaus", "otto");
cmp_ok cmdline, 'eq', 'klaus otto', 'list';
SKIP: {
  skip "kernel too old for prctl(PR_SET_NAME)", 1
    unless Sys::Proctitle::kernel_support;
  cmp_ok procname, 'eq', 'klaus', 'set/list (procname)';
}

my $rc=Sys::Proctitle::getproctitle;
my $xrc=$rc; $xrc=~s/\0/!/g;
like $rc, qr/klaus\0otto\0+$/, 'get';

Sys::Proctitle::setproctitle;
cmp_ok cmdline, 'eq', $origcmdline, 'unset again';

Sys::Proctitle::setproctitle($rc);
cmp_ok cmdline, 'eq', 'klaus otto', 'value got via getproctitle() restored';

{
  my $proctitle=Sys::Proctitle->new( qw/object interface/ );
  cmp_ok cmdline, 'eq', 'object interface', 'object interface';
}

cmp_ok cmdline, 'eq', 'klaus otto', 'object destroyed';

## Local Variables: ##
## mode: cperl ##
## End: ##
