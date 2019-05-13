package t::scan::Util;

use strict;
use warnings;
use Test::More;
use Perl::PrereqScanner::NotQuiteLite;
use Exporter qw/import/;
use if (-d ".git" and !$ENV{PERL_PSNQL_DEBUG}), "Test::FailWarnings";

our @EXPORT = (@Test::More::EXPORT, qw/test todo_test test_with_error/);

sub todo_test {
  SKIP: {
    local $TODO = "FIXME";
    test(@_);
  }
}

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
