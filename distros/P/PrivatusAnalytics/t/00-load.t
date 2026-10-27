use strict;
use warnings;
use Test::More;

use_ok('PrivatusAnalytics');
use_ok('PrivatusAnalytics::Attributes');
use_ok('PrivatusAnalytics::PageProps');

SKIP: {
    skip 'Mojolicious is not installed', 1 unless eval { require Mojolicious; 1 };
    use_ok('Mojolicious::Plugin::PrivatusAnalytics');
}
SKIP: {
    skip 'Dancer2 is not installed', 1 unless eval { require Dancer2; 1 };
    use_ok('Dancer2::Plugin::PrivatusAnalytics');
}
SKIP: {
    skip 'Plack is not installed', 1 unless eval { require Plack; 1 };
    use_ok('Plack::Middleware::PrivatusAnalytics');
}

is( PrivatusAnalytics->VERSION, '1.0.0', 'version' );

done_testing;
