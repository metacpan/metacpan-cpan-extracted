use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use POE::Component::Logger;
$loaded++;
