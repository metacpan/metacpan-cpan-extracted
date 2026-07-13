#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;
use feature "signatures";
use experimental "signatures";
use lib qw( lib t/lib );

use Cwd        qw( getcwd );
use File::Temp qw( tempdir );
use PPI        ();
use Test2::V0  qw( done_testing is ok skip_all subtest );

use Perl::Critic::Policy::CodeLayout::ProhibitLongLines ();

my $Long_line = 'my $var = "' . ("x" x 68) . '";';  # 81 chars

sub git_available () {
  open my $fh, "-|", "git", "--version" or return 0;
  my $out = do { local $/ = undef; <$fh> };
  close $fh or return 0;
  defined $out && $out =~ /git version/
}

sub setup_git_repo () {
  my $dir = tempdir(CLEANUP => 1);

  local $ENV{GIT_CONFIG_GLOBAL} = "/dev/null";
  local $ENV{GIT_CONFIG_SYSTEM} = "/dev/null";

  system("git", "-C", $dir, "init", "-q") == 0 or return;

  # Write .gitattributes
  open my $fh, ">", "$dir/.gitattributes" or die "open: $!";
  print $fh "ignore.t custom-line-length=ignore\n";
  print $fh "wide.t custom-line-length=200\n";
  print $fh "deep/nested.t custom-line-length=200\n";
  close $fh or die "close: $!";

  mkdir "$dir/deep" or die "mkdir: $!";

  $dir
}

sub write_perl_file ($dir, $name, $code) {
  my $path = "$dir/$name";
  open my $fh, ">", $path or die "open $path: $!";
  print $fh $code;
  close $fh or die "close $path: $!";
  $path
}

sub violations_for_file ($policy, $path) {
  my $doc = PPI::Document->new($path);
  $policy->violates($doc, $doc)
}

sub setup_git_shim ($dir, $output) {
  my $bin = "$dir/bin";
  my $log = "$dir/git.log";
  mkdir $bin or die "mkdir: $!";
  open my $fh, ">", "$bin/git" or die "open: $!";
  print $fh "#!/bin/sh\n", "echo run >> '$log'\n";
  print $fh length $output ? "printf '%s\\n' '$output'\n" : "exit 1\n";
  close $fh or die "close: $!";
  chmod 0755, "$bin/git" or die "chmod: $!";
  ($bin, $log)
}

sub require_git () {
  skip_all "git not available" unless git_available();
  my $dir = setup_git_repo();
  skip_all "could not initialise git repo" unless $dir;
  $dir
}

sub test_ignore_attribute () {
  my $dir = require_git();

  my $policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;
  my $path   = write_perl_file($dir, "ignore.t", "$Long_line\n");

  my @v = violations_for_file($policy, $path);
  is scalar @v, 0, "no violations when attribute is ignore";
}

sub test_numeric_attribute () {
  my $dir = require_git();

  my $policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;

  # 81-char line is fine under limit of 200
  my $path = write_perl_file($dir, "wide.t", "$Long_line\n");
  my @v    = violations_for_file($policy, $path);
  is scalar @v, 0, "81-char line within 200-char override";

  # A 201-char line should still violate
  my $very_long = "x" x 201;
  $path = write_perl_file($dir, "wide.t", "$very_long\n");
  @v    = violations_for_file($policy, $path);
  is scalar @v, 1, "201-char line exceeds 200-char override";
}

sub test_unspecified_attribute () {
  my $dir = require_git();

  my $policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;

  # normal.t has no gitattributes entry, so default 80 applies
  my $path = write_perl_file($dir, "normal.t", "$Long_line\n");
  my @v    = violations_for_file($policy, $path);
  is scalar @v, 1, "81-char line violates default 80-char limit";
}

sub test_no_filename () {
  # PPI::Document from string ref has no filename
  my $policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;
  my $doc    = PPI::Document->new(\$Long_line);
  my @v      = $policy->violates($doc, $doc);
  is scalar @v, 1, "string input (no filename) uses default limit";
}

sub test_feature_disabled () {
  my $dir = require_git();

  my $policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;
  $policy->{_gitattributes_line_length} = "";

  # ignore.t would be ignored if the feature were active
  my $path = write_perl_file($dir, "ignore.t", "$Long_line\n");
  my @v    = violations_for_file($policy, $path);
  is scalar @v, 1, "violations reported when feature is disabled";
}

sub test_get_gitattr_line_length () {
  my $dir = require_git();

  my $policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;

  # Need actual files for git check-attr
  write_perl_file($dir, "ignore.t", "1;\n");
  write_perl_file($dir, "wide.t",   "1;\n");
  write_perl_file($dir, "normal.t", "1;\n");

  is $policy->_get_gitattr_line_length("$dir/ignore.t"), "ignore",
    "ignore attribute";
  is $policy->_get_gitattr_line_length("$dir/wide.t"), 200, "numeric attribute";
  ok !defined $policy->_get_gitattr_line_length("$dir/normal.t"),
    "unspecified attribute returns undef";
  ok !defined $policy->_get_gitattr_line_length(undef),
    "undef filename returns undef";
  ok !defined $policy->_get_gitattr_line_length(""),
    "empty filename returns undef";
}

sub test_relative_path () {
  my $dir  = require_git();
  my $path = write_perl_file($dir, "deep/nested.t", "$Long_line\n");

  my $policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;
  is $policy->_get_gitattr_line_length($path), 200,
    "absolute path matches slash-containing pattern";

  my $orig = getcwd();
  chdir $dir or die "chdir $dir: $!";
  is $policy->_get_gitattr_line_length("deep/nested.t"), 200,
    "relative path matches slash-containing pattern";
  my @v = violations_for_file($policy, "deep/nested.t");
  is scalar @v, 0, "81-char line within 200-char override via relative path";
  chdir $orig or die "chdir $orig: $!";
}

sub test_no_spawn_without_attributes () {
  skip_all "shim needs /bin/sh" if $^O eq "MSWin32";
  my $dir = tempdir(CLEANUP => 1);
  mkdir "$dir/.git" or die "mkdir: $!";
  my ($bin, $log) = setup_git_shim($dir, "");
  local $ENV{PATH} = $bin;

  my $policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;
  my $path   = write_perl_file($dir, "a.t", "1;\n");
  ok !defined $policy->_get_gitattr_line_length($path), "no override";
  ok !-e $log,                                          "git never spawned";
}

sub test_lookup_cached_per_file () {
  skip_all "shim needs /bin/sh" if $^O eq "MSWin32";
  my $dir = tempdir(CLEANUP => 1);
  mkdir "$dir/.git" or die "mkdir: $!";
  write_perl_file($dir, ".gitattributes", "wide.t custom-line-length=200\n");
  my ($bin, $log) = setup_git_shim($dir, "wide.t: custom-line-length: 200");
  local $ENV{PATH} = $bin;

  my $policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;
  my $path   = write_perl_file($dir, "wide.t", "1;\n");
  is $policy->_get_gitattr_line_length($path), 200, "first lookup";
  is $policy->_get_gitattr_line_length($path), 200, "second lookup";
  my @runs = do { open my $fh, "<", $log or die "open: $!"; <$fh> };
  is scalar @runs, 1, "exactly one git spawn";
}

sub test_stderr_suppressed () {
  skip_all "git not available" unless git_available();
  my $dir = tempdir(CLEANUP => 1);
  write_perl_file($dir, ".gitattributes", "wide.t custom-line-length=200\n");
  my $path = write_perl_file($dir, "wide.t", "1;\n");

  my $policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new;
  open my $saved, ">&", \*STDERR          or die "dup: $!";
  open STDERR,    ">",  "$dir/stderr.txt" or die "redirect: $!";
  my $value = $policy->_get_gitattr_line_length($path);
  open STDERR, ">&", $saved or die "restore: $!";

  my $err = do {
    open my $fh, "<", "$dir/stderr.txt" or die "open: $!";
    local $/ = undef;
    <$fh>
  };
  is $err, "", "no stderr leakage";
  ok !defined $value, "no override outside a repository";
}

subtest "ignore attribute suppresses violations" => \&test_ignore_attribute;
subtest "numeric attribute overrides limit"      => \&test_numeric_attribute;
subtest "unspecified attribute uses default"    => \&test_unspecified_attribute;
subtest "no filename falls back to default"     => \&test_no_filename;
subtest "feature disabled when parameter empty" => \&test_feature_disabled;
subtest "_get_gitattr_line_length values"     => \&test_get_gitattr_line_length;
subtest "relative paths honour gitattributes" => \&test_relative_path;
subtest "no spawn when nothing can match" => \&test_no_spawn_without_attributes;
subtest "lookup cached per file"          => \&test_lookup_cached_per_file;
subtest "stderr suppressed on spawn"      => \&test_stderr_suppressed;

done_testing;
