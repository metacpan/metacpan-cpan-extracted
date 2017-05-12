use strict;
use warnings;
use Script::Carp -stop, -ignore_eval;
use IO::Scalar;
my $err = '';

{
  local *STDERR;
  tie *STDERR, "IO::Scalar", \$err;
  close STDIN;
  eval {
    die;
  };
}
my $msg = "Died  at t/02-stop.t line 12\nHit Enter to exit:";
my $ng = 0;
$err =~s{(line \d+)\.}{$1}g;
print (($err eq $msg) ? "ok 1\n" : ($ng = "not ok 1\n"));
if ($ng) {
  if ($err =~ s{^(.)}{# $1}mg) {
    print STDERR "# got:\n";
    print STDERR $err, "\n";
  } else {
    print STDERR "# got: nothing\n";
  }
  if ($msg =~ s{^(.)}{# $1}mg) {
    print STDERR "# expected:\n";
    print STDERR $msg, "\n";
  }
}
print "1..1\n";
