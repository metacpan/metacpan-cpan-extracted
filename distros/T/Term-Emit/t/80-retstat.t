#!perl -w
use strict;
use warnings;
use Test::More tests => 56;

use Term::Emit qw/:all/, {-bullets => 0,
                          -width   => 40};

my $stat = 345;
{ $stat = emit *STDOUT, "Ignore this"; emit_ok *STDOUT; }
is($stat, 1, "Output to STDOUT");

{ $stat = emit *STDERR, "Ignore this too"; emit_ok *STDERR; }
is($stat, 1, "Output to STDERR");

#Hmmm, how to test this.  fileno(*STDIN) is 0, which is the default base object.
#{ $stat = emit *STDIN, "This should fail" }
#is($stat, undef, "Output to STDIN should give error");

# We have our own copy of the severities here, instead of
#   using %Term::Emit::SEVLEV, so we'll know if those in Term::Emit.pm
#   ever get accidentally changed.
# And we also add some non-standard ones that should return 1.
my %sevlev = (EMERG => 15,
              ALERT => 13,
              CRIT  => 11, FAIL => 11, FATAL => 11,
              ERROR => 9,
              WARN  => 7,
              NOTE  => 6,
              INFO  => 5, OK => 5,
              DEBUG => 4,
              NOTRY => 3,
              UNK   => 2,
              OTHER => 1,
              NONE  => 1,
              YES   => 1,
              NO    => 0,
              Blah  => 1,
             );
my $out = undef;
Term::Emit::setopts -fh => \$out;
foreach my $k (keys %sevlev) {
    my $v = $sevlev{$k};
    { emit "Status for ".uc($k);
      $stat = emit_done uc($k); }
    is($stat, $v, "Status for ".uc($k));
    { emit "Status for ".lc($k);
      $stat = emit_done lc($k); }
    is($stat, $v, "Status for ".lc($k));
    { emit "Status for ".ucfirst($k);
      $stat = emit_done ucfirst($k); }
    is($stat, $v, "Status for ".ucfirst($k));
}
