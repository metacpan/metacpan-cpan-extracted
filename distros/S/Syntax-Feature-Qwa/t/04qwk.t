use Test::More tests => 1;
use Syntax::Feature::Qwa;

my $arr = qwk/Foo Bar Baz/;

is_deeply($arr, +{ qw/Foo 1 Bar 2 Baz 3/ });