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

our @EXPORT = qw/test todo_test used test_app test_file/;
our $EVAL;
our $PARSERS;

sub todo_test {
  SKIP: {
    local $TODO = "FIXME";
    test(@_);
  }
}

sub test {
  my ($description, $string, $expected_requires, $expected_suggests, $expected_recommends) = @_;
  subtest $description => sub {
    my $scanner = Perl::PrereqScanner::NotQuiteLite->new(
      parsers => $PARSERS || [qw/:bundled/],
      suggests => $expected_suggests ? 1 : 0,
    );
    ok my $context = $scanner->scan_string($string);
    my $requires = $context->requires;
    my $requires_hash = $requires ? $requires->as_string_hash : {};
    is_deeply $requires_hash => $expected_requires, "requires ok";
    note explain $requires_hash;
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
    if ($EVAL) {
      eval "no strict; $string";
      ok !$@, "no eval error";
      note $@ if $@;
    }
  };
}

sub used { return {map {$_ => 0} @_} }

sub test_app {
  my ($setup, $expected) = @_;
  my $tmpdir = tempdir(
    'PerlPrereqScannerNQLite_XXXX',
    CLEANUP => 1,
    TMPDIR => 1,
  );
  $setup->($tmpdir);

  my $suggests = 0;
  for my $phase (keys %$expected) {
    $suggests = 1 if $expected->{$phase}{suggests};
  }

  my $prereqs = Perl::PrereqScanner::NotQuiteLite::App->new(
    base_dir => $tmpdir,
    suggests => $suggests,
  )->run->as_string_hash;

  for my $phase (sort keys %$expected) {
    for my $type (sort keys %{$expected->{$phase}}) {
      for my $module (sort keys %{$expected->{$phase}{$type}}) {
        is $prereqs->{$phase}{$type}{$module} => $expected->{$phase}{$type}{$module}, "found $module as $phase $type";
      }
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

1;
