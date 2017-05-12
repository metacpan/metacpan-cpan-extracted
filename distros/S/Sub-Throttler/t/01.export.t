use warnings;
use strict;
use Test::More;

use Sub::Throttler;

my @exports = qw(
);
my @not_exports = qw(
    throttle_it throttle_it_asap
    throttle_me throttle_me_asap done_cb
    throttle_flush throttle_add throttle_del
);

plan +(@exports + @not_exports)
    ? ( tests       => @exports + @not_exports                  )
    : ( skip_all    => q{This module doesn't export anything}   )
    ;

for my $export (@exports) {
    can_ok( __PACKAGE__, $export );
}

for my $not_export (@not_exports) {
    ok( ! __PACKAGE__->can($not_export) );
}
