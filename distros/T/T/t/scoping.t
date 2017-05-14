use T2 Basic => [qw/ok done_testing/];
use T2 Compare => [qw/like/];
use T2 -no_scope => 1, '+strict';

t2->ok(
    eval '$xyz = 1' || 0,
    "'strict' did not have it's scoped effect",
);

use T2 '+strict';

t2->like(
    eval '$abc = "oops"' || $@,
    qr/"\$abc" requires explicit package name/,
    "'strict' imported into scope by request",
);

t2->done_testing;
