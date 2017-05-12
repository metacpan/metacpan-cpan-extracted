use strict;
use warnings;
use Script::Carp -stop, -ignore_eval;
use Carp ();
use IO::Scalar;

my $err = '';

{
  local *STDERR;  close STDIN;
  tie *STDERR, "IO::Scalar", \$err;
  eval {
    Carp::croak "123456789";
  };
}
my $msg = "123456789 at t/03-croak.t line 13\n\teval {...} called at t/03-croak.t line 12\nHit Enter to exit:";
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
