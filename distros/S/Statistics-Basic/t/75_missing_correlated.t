
use t::locale_hack;
use Test;
use Statistics::Basic qw(:all);

plan tests => 1;

$SIG{__WARN__} = sub { die " FATAL WARNING: $_[0] " };

my $v1 = vector(1 .. 5, undef, undef, 7);
my $v2 = vector(1 .. 4, undef, undef, 8, 7);
my @f = handle_missing($v1,$v2);

ok( correlation(@f), 1 );
