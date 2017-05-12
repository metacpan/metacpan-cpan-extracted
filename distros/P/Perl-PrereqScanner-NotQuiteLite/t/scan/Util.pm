package t::scan::Util;

use strict;
use warnings;
use Test::More;
use Perl::PrereqScanner::NotQuiteLite;
use Exporter qw/import/;

our @EXPORT = (@Test::More::EXPORT, qw/test/);

sub test {
  my $string = shift;
  my $scanner = Perl::PrereqScanner::NotQuiteLite->new;
  my $c = $scanner->scan_string($string);
  ok !@{$c->{errors}} or note explain $c;
}

1;
