#!perl

use v5.20;
use warnings;

BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use Test::More;

eval "use Test::CPAN::Changes";

plan skip_all => "Test::CPAN::Changes not installed" if $@;

use Plack::Middleware::Statsd;
changes_ok( { version => Plack::Middleware::Statsd->VERSION } );
