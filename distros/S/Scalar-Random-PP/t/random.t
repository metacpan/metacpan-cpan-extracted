use Test::More tests => 3;

use Scalar::Random::PP 'randomize';

pass 'Module loaded and import worked';
ok defined \&randomize, 'randomize was exported';

my $x;
randomize($x, 1000);

ok $x =~ /^\d+$/, 'randomize generated a number';
