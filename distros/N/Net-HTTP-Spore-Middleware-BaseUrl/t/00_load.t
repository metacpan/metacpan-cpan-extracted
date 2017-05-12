use Test::More tests => 1;

my $ok;
END { BAIL_OUT "Could not load all modules" unless $ok }

use Net::HTTP::Spore::Middleware::BaseUrl;

ok 1, 'All modules loaded successfully';
$ok = 1;
