#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is like ok skip_all subtest unlike );
use feature      qw( signatures );
use experimental qw( signatures );

use Cwd        qw( abs_path getcwd );
use File::Temp qw( tempdir );

use lib "utils/lib";
use GitHook qw( get_current_branch on_main ticket_re );

my $Ticket_re = ticket_re;

sub write_file ($path, $content) {
  open my $fh, ">", $path or die "Cannot write $path: $!\n";
  print {$fh} $content;
  close $fh or die "Cannot close $path: $!\n";
}

sub in_temp_dir ($code) {
  delete local @ENV{qw( GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR )};
  my $dir = tempdir(CLEANUP => 1);
  my $cwd = getcwd;
  chdir $dir or die "Cannot chdir $dir: $!\n";
  my @result = $code->();
  chdir $cwd or die "Cannot chdir $cwd: $!\n";
  @result
}

subtest "Ticket regex" => sub {
  like "GH-1234",       qr/^$Ticket_re$/, "typical ticket matches";
  like "ABCDEFGH-1",    qr/^$Ticket_re$/, "eight-letter project matches";
  unlike "A-1",         qr/^$Ticket_re$/, "one letter is not a project";
  unlike "ABCDEFGHI-1", qr/^$Ticket_re$/, "nine letters is too long";
  unlike "gh-123",      qr/^$Ticket_re$/, "lower case does not match";
};

subtest "Branch detection outside a repository" => sub {
  my ($branch, $main) = in_temp_dir(sub { (get_current_branch, on_main) });
  is $branch, "", "no branch outside a repository";
  ok !$main, "not on main";
};

subtest "A symlinked hook finds the shared library" => sub {
  skip_all "the hook runs only under a POSIX shell" if $^O eq "MSWin32";
  my $dir  = tempdir(CLEANUP => 1);
  my $link = "$dir/commit-msg";
  symlink abs_path("utils/commit-msg-hook"), $link
    or skip_all "symlinks not available";
  my $msg = "$dir/msg.txt";
  write_file($msg, "Improve the widget\n\nTicket GH-1234\n");
  delete local @ENV{qw( GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR )};
  my $out = qx(cd \Q$dir\E && \Q$link\E \Q$msg\E </dev/null 2>&1);
  is $? >> 8, 0,  "the hook runs and accepts a clean message";
  is $out,    "", "no output";
};

done_testing
