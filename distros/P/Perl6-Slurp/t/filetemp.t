use Test::More;

plan tests => 1;

$SIG{__WARN__} = sub { die @_ };

use Perl6::Slurp 'slurp';
use File::Temp;
my $fh = File::Temp->new;

my $str = slurp $fh;

is $str, q{} => 'Works with File::Temp';
