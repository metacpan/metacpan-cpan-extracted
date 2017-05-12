use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

my $warning = 0;
$SIG{__WARN__} = sub { $warning++ };

plugin PPI => bad_key => 1;

ok $warning, 'bad key raises a warning';

done_testing;

