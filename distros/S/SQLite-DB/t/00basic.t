use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use SQLite::DB;
$loaded++;

unlink("foo", "output/foo");

