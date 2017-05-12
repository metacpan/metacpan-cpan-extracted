# -*- perl -*-

# t/002_constructor.t - test the syntax for building a formatter

use Test::More tests => 2;
use String::Sprintf;

my $formatter = String::Sprintf->formatter ();
isa_ok ($formatter, 'String::Sprintf');
$formatter = String::Sprintf->formatter(
  D => sub {
    return "dummy";
  }
);
isa_ok ($formatter, 'String::Sprintf');
