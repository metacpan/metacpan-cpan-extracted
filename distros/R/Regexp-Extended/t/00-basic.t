use Test;

BEGIN { plan tests => 1}
END   { ok(0) unless $loaded }

use Regexp::Extended qw(:all);

$loaded = 1;
ok(1);
