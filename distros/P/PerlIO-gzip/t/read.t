#!perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use warnings;
use Test::More tests => 301;
use File::Compare; # This is standard in all distributions that have layers.
use File::Spec;
use Config;
use PerlIO::gzip;
ok(1, "Does it even load?"); # If we made it this far, we're ok.

chdir 't' if -d 't';

#########################

# Test numbers in file names reflect the original numbering in test.pl

# There were TODO tests but they've been hacked around.
# Currently the perl core can't unread onto :unix (and other non-fast buffered
# layers), then push another layer atop it, without losing the unread data.
# This shafts gzip() when the gzip file has embedded filenames or comments
# so it hacks round it by pushing the buffering layer just before the unread.
# Grrr.

my $perlgz = "perl.gz";
my $done_perlgz;
my $command = "gzip -c --fast $^X >$perlgz";
my $unread_bug = "Can't unread then push layer on :unix [core perlio bug]";
my $unread_stdio_bug
 = "Can't unread the push layer on :stdio [core perlio bug]";
# I think that the problem is that you can't specify "b" on the fopen()
my $win32_stdio_hairy = ":stdio is a bit hairy on Win32";
my $stdio = 'Not really a layer name';
$stdio = ':stdio' unless $Config{d_faststdio} and $Config{usefaststdio};

my $readme = File::Spec->catfile(File::Spec->updir(), "README");
END {if (-f $perlgz) {unlink $perlgz or die "Can't unlink $perlgz: $!"}}

foreach my $buffering ('', ':unix', ':stdio', ':perlio') {
  # default
  # check with no args
  # check with explict gzip header
  # check with lazy header check
  # both
  foreach my $layer ('', '()', '(gzip)', '(lazy)', '(gzip,lazy)') {
    local $/;
    ok (open (FOO, "<$buffering:gzip$layer", "ok3.gz"),
        "open ok3.gz with <$buffering:gzip$layer");
    is (<FOO>, "ok 3\n");
    ok (eof (FOO), 'should be end of file');
    ok (close (FOO), "close it again");
  }

  # This should open
  ok ((open FOO, "<$buffering", $readme), "README should open");

  # This should fail to open
  ok (!(open FOO, "<$buffering:gzip", $readme),
      "README should not open [core perlio bug fixed post 5.7.2 12827]");

  {
    local $/;
    # This file has an embedded filename. Being short it also checks get_more
    # (called by eat_nul) and the unread of the excess data.
    ok (open (FOO, "<$buffering:gzip", "ok17.gz"),
        "open ok17.gz with <$buffering:gzip");
  TODO: {
      # local $TODO = $unread_bug if $buffering eq ':unix';
      # local $TODO = $unread_stdio_bug if $buffering eq $stdio;
      is (<FOO>, "ok 17\n");
    }
    ok (eof (FOO), 'should be end of file');
  TODO: {
      # local $TODO = $unread_bug if $buffering eq ':unix';
      # local $TODO = $unread_stdio_bug if $buffering eq $stdio;
      ok (close (FOO), "close it"); # As TODO as the read
    }
    ok (open (FOO, "<$buffering:gzip(none)", "ok19"),
        "open ok19 with <$buffering:gzip(none)");
    is (<FOO>, "ok 19\n");
  }
  ok (open (FOO, "<$buffering", "ok21"), "open ok21 with <$buffering");
  is (<FOO>, "ok 21\n");
  ok (binmode (FOO, ":gzip"), "Ho ho ho. Switch to gunzip mid stream.");
  is (<FOO>, "ok 23\n");

  # Test auto mode
  foreach (['auto', 'ok19', "ok 19\n"],	      ['auto', 'ok3.gz', "ok 3\n"],
           ['lazy,auto', 'ok19', "ok 19\n"],  ['auto,lazy', 'ok3.gz', "ok 3\n"],
          ) {
    my ($args, $file, $contents) = @$_;
    local $/;
    ok (open (FOO, "<$buffering:gzip($args)", $file),
        "open $file with <$buffering:gzip($args)");
  TODO: {
      # local $TODO = $unread_bug if $buffering eq ':unix' and $file eq 'ok19';
      # local $TODO = $unread_stdio_bug
	# if $buffering eq $stdio and $file eq 'ok19';
      is (<FOO>, $contents);
    }
    ok (eof (FOO), 'should be end of file');
  TODO: {
      # local $TODO = $unread_bug if $buffering eq ':unix' and $file eq 'ok19';
      # local $TODO = $unread_stdio_bug
	# if $buffering eq $stdio and $file eq 'ok19';
      ok (close (FOO), "close it"); # As TODO as the read
    }
  }

  foreach my $args ('lazy', 'auto', 'auto,lazy') {
    # This should open
    # (auto will find no gzip header and assume deflate stream)
    # (lazy defers test)
    ok ((open FOO, "<$buffering:gzip($args)", $readme),
        "README should open in $args mode");

    # For lazy gzip header check is on first read it should fail here
    # For auto it's not (meant to be) a deflate stream it (hopefully) will go
    # wrong here
    my $line = <FOO>;
    ok (!defined $line, "but should fail on first read")
      or print "# got $_\n";
  }

  if (!defined $done_perlgz) {
    # Attempt this the first time only
    print "# Attempting to run '$command'\n";
    $done_perlgz = system $command;
  }
 SKIP: {
    skip "$command failed", 3 if $done_perlgz;
    ok ((open GZ, "<$buffering:gzip", "perl.gz"), "open perl.gz");
  TODO: {
      # local $TODO = $unread_bug if $buffering eq ':unix';
      local $TODO = $win32_stdio_hairy
	  if $buffering eq ':stdio' && $^O eq 'MSWin32';
      ok (compare ($^X, \*GZ) == 0, "compare with original $^X");
    }
    ok (eof (GZ), 'should be end of file');
  TODO: {
      # local $TODO = $unread_bug if $buffering eq ':unix';
      local $TODO = $win32_stdio_hairy
	  if $buffering eq ':stdio' && $^O eq 'MSWin32';
      ok ((close GZ), "close perl.gz");
    }
  }

  # OK. autopop mode. muhahahahaha

  ok ((open FOO, "<$buffering:gzip(autopop)", $readme),
      "open README with <$buffering:gzip(autopop)");
  ok (defined <FOO>, "read first line");
  like (<FOO>, qr/^======/, "check second line");

  {
    local $/;
    ok ((open FOO, "<$buffering:gzip(autopop)", "ok3.gz"),
        "open ok3.gz with <$buffering:gzip(autopop)");
    is (<FOO>, "ok 3\n");
  }

  # Verify that short files get an error on close
  # Verify that files with erroroneous lengths get an error on close
  # Verify that files with erroroneous crc get an error on close
  foreach (['', 'ok50.gz.short', "ok 50\n"],
           ['', 'ok54.gz.len', "ok 54\n"],
           ['', 'ok58.gz.crc', "ok 58\n"],
          ) {
    my ($layer, $file, $contents) = @$_;
    local $/;
    ok (open (FOO, "<$buffering:gzip$layer", $file),
        "open $file with <$buffering:gzip$layer");
  TODO: {
      # ok54.gz.len has an embedded filename.
      # local $TODO = $unread_bug
        # if $buffering eq ':unix' and $file eq 'ok54.gz.len';
      # local $TODO = $unread_stdio_bug
	# if $buffering eq $stdio and $file eq 'ok54.gz.len';
      is (<FOO>, $contents);
    }
    ok (eof (FOO), "should be end of file");
    ok (!(close FOO), "close should fail");
  }
}
