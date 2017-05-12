#!/usr/bin/perl -Tw
# -*- perl -*-

# t/003_simpletest.t - attempt to test simple functionality, but only
# if Mail::POP3Client is available; otherwise, skip these tests.

use Test::More tests => 7;

BEGIN {
  use_ok( 'Net::Server::POP3' ); # 1
  use_ok( 'Cwd' ) # 2
    or diag "Second-edition Camel says Cwd is core, but it's not installed?  (Net::Server::POP3 doesn't actually need Cwd; only the test uses it; but how old is your perl?)";
}

my $server = Net::Server::POP3->new();
isa_ok ($server, 'Net::Server::POP3'); # 3

my $continue = 0; {
  my ($originaldirectory) = cwd() =~ /(.*)/; # Should be safe to
                                             # change back to the
                                             # original directory,
                                             # or so one would hope.
  for my $i (@INC) {
    chdir $i;
    if (-e "POP3Client.pm" and $i =~ /Mail/) {
      # We have reason to believe we can use Mail::POP3Client
      push @$continue, $i;
    }
  }
  chdir $originaldirectory;
} # Throw out those stale lexicals; $continue is all we need:

# We've done 3 tests so far...

SKIP: {
  skip "Mail::POP3Client does not appear to be installed.  (This is okay; Net::Server::POP3 will work fine without it; we only wanted it for testing.)",
    4 unless $continue;
  use_ok('Mail::POP3Client')
    or skip "Skipping tests that rely on unavailable module Mail::POP3Client", 3;
  my $f = fork;
  skip "Cannot fork, what are we on, DOS?  Module _may_ still work, bug reports welcome.",
    3 unless defined $f;
  skip "Remaining tests not yet implemented.", 3;
}
