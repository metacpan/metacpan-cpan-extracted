use strict;
use warnings;
use Test::More tests => 60;

BEGIN {
    use_ok('Net::SinaWeibo::OAuth');
    use_ok('Net::SinaWeibo');
}
foreach my $m (keys %Net::SinaWeibo::SINA_API) {
    ok(Net::SinaWeibo->can($m),"compile api:$m");
}