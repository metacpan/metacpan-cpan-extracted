use Test::More tests => 1;
use Syntax::Feature::Qwa;

no warnings; # deliberate odd number of hash elements!

my $arr = qwh/Foo Bar Baz/;

is_deeply($arr, +{ qw/Foo Bar Baz/ });