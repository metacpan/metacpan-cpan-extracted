package t::Util;

use strict;
use warnings;
use Test::More;
use Perl::PrereqScanner::NotQuiteLite;
use Perl::PrereqScanner::NotQuiteLite::App;
use Exporter qw/import/;
use File::Temp qw/tempdir/;
use File::Basename qw/dirname/;
use File::Path qw/mkpath rmtree/;
use if -d ".git", "Test::FailWarnings";

our @EXPORT = qw/
  test todo_test used test_app test_file test_cpanfile
/;
our $EVAL;
our $PARSERS;

sub todo_test {
  SKIP: {
    local $TODO = "FIXME";
    test(@_);
  }
}

sub test {
  my ($description, $string, $expected_requires, $expected_suggests, $expected_recommends, $expected_noes) = @_;
  subtest $description => sub {
    my $scanner = Perl::PrereqScanner::NotQuiteLite->new(
      parsers => $PARSERS || [qw/:bundled/],
      suggests => $expected_suggests ? 1 : 0,
    );
    ok my $context = $scanner->scan_string($string);
    if ($expected_requires) {
      my $requires = $context->requires;
      my $requires_hash = $requires ? $requires->as_string_hash : {};
      is_deeply $requires_hash => $expected_requires, "requires ok";
      note explain $requires_hash;
    }
    if ($expected_suggests) {
      my $suggests = $context->suggests;
      my $suggests_hash = $suggests ? $suggests->as_string_hash : {};
      is_deeply $suggests_hash => $expected_suggests, "suggests ok";
      note explain $suggests_hash;
    }
    if ($expected_recommends) {
      my $recommends = $context->recommends;
      my $recommends_hash = $recommends ? $recommends->as_string_hash : {};
      is_deeply $recommends_hash => $expected_recommends, "recommends ok";
      note explain $recommends_hash;
    }
    if ($expected_noes) {
      my $noes = $context->noes;
      my $noes_hash = $noes ? $noes->as_string_hash : {};
      is_deeply $noes_hash => $expected_noes, "noes ok";
      note explain $noes_hash;
    }
    if ($EVAL) {
      eval "no strict; $string";
      ok !$@, "no eval error";
      note $@ if $@;
    }
    ok !@{$context->{errors} || []}, 'no errors' or note explain $context->{errors};
  };
}

sub used { return {map {$_ => 0} @_} }

sub test_app {
  my ($description, $setup, $args, $expected) = @_;
  note $description;

  my $tmpdir = tempdir(
    'PerlPrereqScannerNQLite_XXXX',
    CLEANUP => 1,
    TMPDIR => 1,
  );
  $setup->($tmpdir);

  my $prereqs = Perl::PrereqScanner::NotQuiteLite::App->new(
    parsers => [':bundled'],
    base_dir => $tmpdir,
    recommends => 1,
    suggests => 1,
    %{$args || {}},
  )->run->as_string_hash;

  for my $phase (sort keys %$expected) {
    for my $type (sort keys %{$expected->{$phase}}) {
      is_deeply $prereqs->{$phase}{$type} => $expected->{$phase}{$type}, "$phase $type ok";
    }
  }
  note explain $prereqs;

  rmtree($tmpdir);
}

sub test_file {
  my ($file, $body) = @_;
  my $dir = dirname($file);
  mkpath($dir) unless -d $dir;
  open my $fh, '>', $file or die "$file: $!";
  print $fh $body;
}

sub test_cpanfile {
  my ($description, $setup, $args, $expected) = @_;
  note $description;

  my $tmpdir = tempdir(
    'PerlPrereqScannerNQLite_XXXX',
    CLEANUP => 1,
    TMPDIR => 1,
  );
  $setup->($tmpdir);

  my $prereqs = Perl::PrereqScanner::NotQuiteLite::App->new(
    parsers => [':bundled'],
    base_dir => $tmpdir,
    recommends => 1,
    suggests => 1,
    save_cpanfile => 1,
    %{$args || {}},
  )->run;

  my $file = "$tmpdir/cpanfile";
  if (ok -f $file, "cpanfile exists") {
    my $got = do { open my $fh, '<', $file; local $/; <$fh> };
    is $got => $expected;
  }

  rmtree($tmpdir);
}

1;
