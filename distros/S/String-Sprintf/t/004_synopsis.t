# -*- perl -*-

# t/004_sysopsis.t - test syntax and result for the synopsis

use Test::More tests => 2;

use String::Sprintf;
my $f = String::Sprintf->formatter(
  N => sub {
    my($width, $value, $values, $letter) = @_;
    return commify(sprintf "%${width}f", $value);
  }
);
isa_ok ($f, 'String::Sprintf');

my $out = $f->sprintf('(%10.2N, %10.2N)', 12345678.901, 87654.321);
sub commify {
    my $n = shift;
    $n =~ s/(\.\d+)|(?<=\d)(?=(?:\d\d\d)+\b)/$1 || ','/ge;
    return $n;
}

is ($out, '(12,345,678.90,   87,654.32)', 'synopsis');
