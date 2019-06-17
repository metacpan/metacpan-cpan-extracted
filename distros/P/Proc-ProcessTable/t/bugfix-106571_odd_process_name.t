use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
  if ($^O eq 'cygwin') {
    plan skip_all => 'Test irrelevant on cygwin';
  }

  use_ok('Proc::ProcessTable');
}

SKIP: {
  $0 = "PROC_PROCESSTABLE_TEST_CMD";
  sleep(1);

  my ($ps) = grep {/^$$\s+/} map { chomp; s/^\s*//; $_ } `ps xww`;
  skip 'Cannot set process name', 1
    unless ($ps && $ps =~ /PROC_PROCESSTABLE_TEST_CMD/);

  # From Joelle Maslak: Can't set a process name to a blank name on
  # OpenBSD, so this test is not relevant.  From reading perlvar, it
  # appears that this is likely true on other BSDs, so rather than
  # looking for the OpenBSD operating system, we see if the command line
  # starts with "perl:" as it does on OpenBSD (and presumably other
  # BSDs).  See OpenBSD's setproctitle(3) for information on what at
  # least OpenBSD allows:
  #   https://man.openbsd.org/setproctitle.3
  skip 'Likely *BSD system, can\'t blank process name', 1
    unless ($ps =~ /^perl: /);

  $SIG{CHLD} = 'IGNORE';

  my $pid = fork;
  die "cannot fork" unless defined $pid;

  if ($pid == 0) {
    #child
    $0 = '';
    sleep 10000;
  } else {
    #main
    sleep 1;
    my $t           = Proc::ProcessTable->new;
    my $cmnd_quoted = '';
    my ($p) = grep { $_->{pid} == $pid } @{ $t->table };
    is($p->{cmndline}, $cmnd_quoted, "odd process commandline bugfix ($cmnd_quoted)");
    kill 9, $pid;
  }
}
done_testing();

