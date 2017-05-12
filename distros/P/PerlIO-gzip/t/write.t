#!perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use warnings;
use Test::More tests => 260;
use File::Compare; # This is standard in all distributions that have layers.
use Config;
use PerlIO::gzip;

chdir 't' if -d 't';

#########################

undef $/;

my $sh;
if (-s $Config{sh}) {
  open FOO, "<", $Config{sh} or die $!;
  binmode FOO;

  $sh = <FOO>;
  die "Can't slurp $Config{sh}: $!" unless defined $sh;
  die sprintf ("Slurped %d, but disk file $Config{sh} is %d bytes",
	       length $sh, -s $Config{sh})
    unless length $sh == -s $Config{sh};
  close FOO or die "Close failed: $!";
}

foreach my $buffering ('', ':unix', ':stdio', ':perlio') {
  ok ((open FOO, ">$buffering:gzip", 'foo'), "open foo as >$buffering:gzip");
  ok (close (FOO), 'close it straight away');
  is (-s 'foo', 20, 'empty gzip file should be 20 bytes')
    or printf "# it's %d bytes\n", -s 'foo';

  ok ((open FOO, ">$buffering:gzip", 'foo'), "open foo as >$buffering:gzip");
  my $message = "ok 68\n";
  ok ((print FOO $message), 'print to it')
    or print "# \$! is $!\n";
  ok (close (FOO), 'close it');
  ok ((open FOO, "<$buffering:gzip", 'foo'), 'open foo for reading');
  is (<FOO>, $message, 'check we get same thing back');
  ok (eof (FOO), 'should be end of file');
  ok (close (FOO), 'close it');

  unlink 'foo' or die "unlink 'foo' failed: $!";

  # autopop writes should work
  ok ((open FOO, ">$buffering:gzip(autopop)", 'foo'),
      "open foo as >$buffering:gzip(autopop)");
  $message = "ok 45\n";
  ok ((print FOO $message), 'print to it')
    or print "# \$! is $!\n";
  ok (close (FOO), 'close it');
  ok ((open FOO, "<", 'foo'), "open foo for reading [just '<']");
  is (<FOO>, $message, 'check we get same thing back');
  ok (eof (FOO), 'should be end of file');
  ok (close (FOO), 'close it');

  unlink 'foo' or die "unlink 'foo' failed: $!";

 SKIP: {
    skip "Your configured shell, '$Config{sh}', is missing or size 0",7
      unless defined $sh;
    ok ((open GZ, ">$buffering:gzip", 'foo'),
        sprintf "open >$buffering:gzip [about to write %d bytes]", length $sh);
    ok ((print GZ $sh), "print contents of $Config{sh}")
      or print "# \$! is $!\n";
    ok ((close GZ), 'close it');
    ok ((open GZ, "<$buffering:gzip", 'foo'), "open <$buffering:gzip");
    ok (compare (\*GZ, $Config{sh}) == 0,
        "compare compressed copy with '$Config{sh}'");
    ok (eof (FOO), 'should be end of file');
    ok ((close GZ), 'close it');
    unlink 'foo' or die "unlink 'foo' failed: $!";
  }


  ok ((open FOO, ">$buffering:gzip(lazy)", "empty"),
      "open empty as >$buffering:gzip(lazy)");
  ok ((close FOO), 'close it');
  ok (-z "empty", "check it is zero length")
    or printf "# -s empty is %d\n", -s "empty";

  unlink "empty" or die "unlink 'empty' failed: $!";

  ok ((open GZ, ">$buffering:gzip(lazy)", 'foo'),
      "open foo as >$buffering:gzip(lazy)");
  $message = "ok 87\n";
  my $message2 = "ok 88";
  ok ((print GZ $message), 'print to it')
        or print "# \$! is $!\n";
  {
    local $\ = "\n";
    ok ((print GZ $message2), 'print to it with $\ set')
      or print "# \$! is $!\n";
  }
  ok ((close GZ), 'close it');
  ok ((open FOO, "<$buffering:gzip", 'foo'), 'open foo for reading');
  {
    local $/ = "\n";
    is (<FOO>, $message, 'check we get message back');
    is (<FOO>, "$message2\n", 'check we get message2 back');
  }
  ok (eof (FOO), 'should be end of file');
  ok (close (FOO), 'close it');

  unlink 'foo' or die "unlink 'foo' failed: $!";

  ok ((open FOO, ">$buffering:gzip(none)", 'foo'),
      "open foo as >$buffering:gzip(none)");
  $message = "ok 95\n";
  ok ((print FOO $message), 'print to it')
    or print "# \$! is $!\n";
  ok (close (FOO), 'close it');
  ok (!(open FOO, "<$buffering:gzip", "foo"),
      "no header, so open <$buffering:gzip should fail");
  ok ((open FOO, "<$buffering:gzip(none)", 'foo'), 'open foo for reading');
  is (<FOO>, $message, 'check we get same thing back');
  ok (eof (FOO), 'should be end of file');
  ok (close (FOO), 'close it');

  unlink 'foo' or die "unlink 'foo' failed: $!";

  while (-f "empty") {
    # VMS is going to have several of these, isn't it?
    unlink "empty" or die $!;
  }

  # Read/writes don't work
  ok (!(open FOO, "+<$buffering:gzip", "empty"),
      "open +<$buffering:gzip should fail, as read/write unsupported");
  ok (!-e 'empty', "check file empty was not created")
    or printf "# file empty has size %d\n", -s 'empty';
  if (-f "empty") {
    unlink "empty" or die $!;
  }

  ok (!(open FOO, "+>$buffering:gzip", "empty"),
      "open +>$buffering:gzip should fail, as read/write unsupported");
  TODO: {
    local $TODO = "read/write open still creates file";
    ok (!-e 'empty', "check file empty was not created")
      or printf "# file empty has size %d\n", -s 'empty';
    if (-f "empty") {
      unlink "empty" or die $!;
    }
  }

  # Touch empty so that +< successfuly opens an existing file
  open FOO, ">empty" or die "Can't open 'empty': $!";
  close FOO or die "Can't close 'empty': $!";

  ok ((open FOO, "+<$buffering", "empty"), "open +<$buffering");
  ok (!(binmode FOO, ":gzip"), "binmode ':gzip' should fail on read/write");
  ok (close (FOO), 'close it');
  unlink "empty" or die $!;

  ok ((open FOO, "+>$buffering", "empty"), "open +>$buffering");
  ok (!(binmode FOO, ":gzip"), "binmode ':gzip' should fail on read/write");
  ok (close (FOO), 'close it');
  unlink "empty" or die $!;

  ok ((open FOO, ">$buffering", 'foo'), "open foo as >$buffering");
  $message = "uncompressed\n";
  ok ((print FOO $message), 'print to it')
    or print "# \$! is $!\n";
  ok ((binmode FOO, ":gzip(none)"), "binmode ':gzip(none)'");
  $message2 = "compressed\n";
  ok ((print FOO $message2), 'print to it')
    or print "# \$! is $!\n";
  ok (close (FOO), 'close it');

  ok ((open FOO, "<$buffering", 'foo'), "open foo as <$buffering");
  {
    local $/ = "\n";
    is (<FOO>, $message, 'check we get uncompressed message');
    ok ((binmode FOO, ":gzip(none)"), "binmode ':gzip(none)'");
    is (<FOO>, $message2, 'check we get compressed message');
  }
  ok (eof (FOO), 'should be end of file');
  ok (close (FOO), 'close it');

  unlink 'foo' or die "unlink 'foo' failed: $!";
}
