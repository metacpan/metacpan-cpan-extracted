# -*- perl -*-

# t/005_results.t - test the end result after formatting

use Test::More tests => 6;
use String::Sprintf;

my $formatter = String::Sprintf->formatter(
  F => sub {
    my($width, $value, $values, $letter) = @_;
    my $s = sprintf "%${width}f", $value;
    $s =~ s/\.?0*$//;
    return $s;
  }
);

isa_ok ($formatter, 'String::Sprintf');

is($formatter->sprintf('(%0.3f)', 12.25), '(12.250)', 'fallback');
is($formatter->sprintf('(%0.3f)', 12.4999), '(12.500)', 'fallback 2');
is($formatter->sprintf('(%0.3F)', 12.4999), '(12.5)', 'custom');
is($formatter->sprintf('(%0.3F)', 9.9999), '(10)', 'custom 2');
is($formatter->sprintf('(%0.3f, %0.3F)', 11.9999, 11.9999), '(12.000, 12)', 'mixed');
