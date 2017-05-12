#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

use Test::More;
use Plack::Middleware::ReverseProxyPath;

my $cmd = "perl -c -x -MPlack::Middleware::ReverseProxyPath "
        . $INC{"Plack/Middleware/ReverseProxyPath.pm"};
my $out = `$cmd`;
is( $?, 0, "SYNOPSIS compiles under -c -x")
    or diag "system perl -c -x SYNOPSIS failed: $?\n$!\n$cmd";

done_testing();
