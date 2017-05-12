use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use Proc::Fork::Control;
$loaded++;
