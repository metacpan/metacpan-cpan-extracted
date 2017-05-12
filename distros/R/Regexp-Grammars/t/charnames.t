use Test::More 'no_plan';
use 5.010;

use charnames ':full';
use Regexp::Grammars;

my $grammar = qr{
    \N{LESS-THAN SIGN} a \N{GREATER-THAN SIGN}
}xms;

ok '<a>' =~ $grammar => '\N{NAMED} correctly interpolated'

