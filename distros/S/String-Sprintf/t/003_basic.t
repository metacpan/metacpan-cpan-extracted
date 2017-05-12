# -*- perl -*-

# t/003_basic.t - test the end result after basic formatting

use Test::More tests => 4;
use String::Sprintf;

my $formatter = String::Sprintf->formatter ();
isa_ok ($formatter, 'String::Sprintf');

is($formatter->sprintf('<%%%03X>', 42), '<%02A>', 'fallback');

$formatter = String::Sprintf->formatter(
  D => sub {
    return "dummy";
  }
);

isa_ok ($formatter, 'String::Sprintf');

is($formatter->sprintf('<%03D>', 42), '<dummy>', 'dummy');
