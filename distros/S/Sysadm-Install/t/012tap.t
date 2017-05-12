#####################################
# Tests for Sysadm::Install
#####################################

use Test::More tests => 5;

use Sysadm::Install qw(:all);
use File::Temp qw( tempfile );

SKIP: {
  skip "echo not supported on Win32", 5 if $^O eq "MSWin32";
  my($stdout, $stderr, $rc) = tap "echo", "'";
  is($stdout, "'\n", "single quoted tap");

  ($stdout, $stderr, $rc) = tap { raise_error => 1 }, "echo";
  is($rc, 0, "tap and raise");

  ($stdout, $stderr, $rc) = tap { stdout_limit => 10 }, "echo",
      "12345678910111211314"
      ;
  is($stdout, "(21)[12[snip=17]4.]", "limited stdout");

    # tap needs to work if PATH is not set
  my $ls = bin_find( "ls" );
  $ENV{ PATH } = "";
  ($stdout, $stderr, $rc) = tap $ls, "/";
  is($rc, 0, "cmd ok");

  # Capture STDERR to a temporary file and a filehandle to read from it
  my( $fh, $tmpfile ) = tempfile();
  open STDERR, ">$tmpfile";
  select STDERR; $| = 1; #needed on win32
  open IN, "<$tmpfile" or die "Cannot open $tmpfile";
  sub readstderr { return join("", <IN>); }

  eval {
      tap { raise_error => 1 }, "ls", "/gobbelgobbel987gobbel";
  };
  ok length $@ > 10, "raise_error prints error message"
}
