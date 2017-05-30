use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN {
    $pkg = "Plack::Middleware::Signposting::JSON";
    use_ok $pkg;
}
require_ok $pkg;

done_testing;
