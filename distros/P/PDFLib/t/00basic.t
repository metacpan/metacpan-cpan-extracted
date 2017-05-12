use Test;
BEGIN { plan tests => 2 }
END { ok($loaded); }
$loaded = 0;
use PDFLib;
$loaded = 1;
ok(1);

