use strict;
use warnings;

use Test::More tests => 22;

BEGIN { use_ok('OAuth::Lite::Problems') };
require_ok('OAuth::Lite::Problems');

for my $name (@OAuth::Lite::Problems::EXPORT_OK) {
    my $problem = OAuth::Lite::Problems->$name();
    ok(OAuth::Lite::Problems->match($problem));
}

ok(!OAuth::Lite::Problems->match(q{}));
ok(!OAuth::Lite::Problems->match(q{no_problem}));
