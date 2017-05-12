#!perl -w
use strict;
use POE::XS::Queue::Array;
use Config;

$^O eq 'MSWin32'
  or skip_all("You probably have a sane fork(), not testing");

$Config{useithreads} && $Config{useithreads} eq 'define'
  or skip_all("No ithreads to support pseudo-fork");

sub nok($$$);

print "1..2\n";

{
  my $q1 = POE::XS::Queue::Array->new;
  $q1->enqueue(100, 101);
  my $pid = fork;
  if (!$pid) {
    # child
    nok(1, !eval { $q1->isa("POE::XS::Queue::Array") },
	"queue object should be magically unblessed");
    exit;
  }
  wait();
  nok(2, eval {$q1->isa("POE::XS::Queue::Array") },
      "parent should still have an object");
}

# since we use fork, Test::More can't track test numbers, so we set them manually
sub nok ($$$) {
  my ($num, $ok, $msg) = @_;

  if ($ok) {
    print "ok $num # $msg\n";
  }
  else {
    print "not ok $num # $msg\n";
  }
  $ok;
}

sub skip_all {
  print "1..0 # $_[0]\n";
  exit;
}
