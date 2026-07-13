#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is skip_all subtest );
use feature      qw( signatures );
use experimental qw( signatures );

use Cwd        qw( abs_path );
use File::Temp qw( tempdir );

skip_all "the prepare-commit-msg hook needs a POSIX shell" if $^O eq "MSWin32";

my $Hook = abs_path("utils/prepare-commit-msg-hook");
my $Work = tempdir(CLEANUP => 1);
my $N    = 0;

sub run_hook ($bytes, @args) {
  $N++;
  my $msg = "$Work/msg$N.txt";
  open my $fh, ">:raw", $msg or die "Cannot write $msg: $!\n";
  print {$fh} $bytes;
  close $fh or die "Cannot close $msg: $!\n";

  delete local @ENV{qw( GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR )};
  my $args = join " ", map "\Q$_\E", $msg, @args;
  my $out  = qx(cd \Q$Work\E && $^X \Q$Hook\E $args 2>&1);
  my $exit = $? >> 8;

  open my $rd, "<:raw", $msg or die "Cannot read $msg: $!\n";
  my $content = do { local $/; <$rd> }
    // "";
  close $rd or die "Cannot close $msg: $!\n";
  ($content, $out, $exit)
}

subtest "A message with invalid UTF-8 passes through" => sub {
  my ($content, $out, $exit) = run_hook("Widget\xE9 tweak\n", "message");
  is $exit, 0, "the hook succeeds";
  is $content, "Widget\xE9 tweak\n\nTicket GH-XXXXX\n",
    "the invalid byte survives and the ticket line is appended";
};

subtest "Valid multibyte UTF-8 content is preserved byte for byte" => sub {
  my ($content, $out, $exit) = run_hook("Widget\xC3\xA9 tweak\n", "message");
  is $exit, 0, "the hook succeeds";
  is $content, "Widget\xC3\xA9 tweak\n\nTicket GH-XXXXX\n",
    "the UTF-8 bytes are unchanged";
};

done_testing
