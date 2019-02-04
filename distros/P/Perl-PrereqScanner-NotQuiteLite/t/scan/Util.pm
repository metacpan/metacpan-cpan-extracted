package t::scan::Util;

use strict;
use warnings;
use Test::More;
use Perl::PrereqScanner::NotQuiteLite;
use Exporter qw/import/;
use if -d ".git", "Test::FailWarnings";

our @EXPORT = (@Test::More::EXPORT, qw/test test_with_error/);

sub test {
  my $string = shift;
  my $scanner = Perl::PrereqScanner::NotQuiteLite->new(
    parsers => [':bundled'],
  );
  my $c = $scanner->scan_string($string);
  ok !@{$c->{errors}} or note explain $c;
}

sub test_with_error {
  my $string = shift;
  my $scanner = Perl::PrereqScanner::NotQuiteLite->new(
    parsers => [':bundled'],
  );
  my $c = $scanner->scan_string($string);
  ok @{$c->{errors}};
}

1;
