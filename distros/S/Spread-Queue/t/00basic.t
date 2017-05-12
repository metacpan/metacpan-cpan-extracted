use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use Spread::Queue::Manager;
$loaded++;
