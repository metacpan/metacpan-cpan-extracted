#!perl -w
### TODO: Fix the log file path so it works on non-unix platforms!!!
use strict;
use warnings;
use Test::More tests => 2;

my $out;
use Term::Emit qw/:all/, {-fh      => \$out,
                    -width   => 50};

my $logfnam = $^O eq "MSWin32"
    ? "C:\\50-fd-test-$$.tmp"
    : "/tmp/50-fd-test-$$.tmp";
open (LOG, ">$logfnam")
  or die "*** Could not create log file: $!\n";

{ emit "This goes to the string at level 0";
  { emit "And this to the string at level 1";
    { emit *LOG, "The log file at level 0";
      { emit "To string at level 2";
        { emit *LOG, "to log file at level 1";
        }
      }
    }
  }
}
close LOG;

is($out, "This goes to the string at level 0...\n".
         "  And this to the string at level 1...\n".
         "    To string at level 2.................. [DONE]\n".
         "  And this to the string at level 1....... [DONE]\n".
         "This goes to the string at level 0........ [DONE]\n",  "String output check");

my $log;
open (RLOG, $logfnam)
    or die "*** Could not read back the log file: $!\n";
while (<RLOG>) {$log .= $_}
close RLOG;
unlink $logfnam;
is($log, "The log file at level 0...\n".
         "  to log file at level 1.................. [DONE]\n".
         "The log file at level 0................... [DONE]\n",  "Log file output check");
