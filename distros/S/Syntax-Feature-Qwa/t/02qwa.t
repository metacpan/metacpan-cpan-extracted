use Test::More tests => 1;
use Syntax::Feature::Qwa;

my $arr = qwa/Foo Bar Baz/;

is_deeply($arr, [qw/Foo Bar Baz/]);