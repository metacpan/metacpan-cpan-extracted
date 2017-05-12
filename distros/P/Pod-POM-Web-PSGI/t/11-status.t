use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Plack::Test; 1 }
       or plan skip_all => 'Skip test due to missing Plack::Test';
    eval { require HTTP::Request::Common; 1 }
       or plan skip_all => 'skip test due to missing HTTP::Request::Common';
    Plack::Test->import;
    HTTP::Request::Common->import;
}

plan tests => 2;

use lib 'lib';
my $app = require Pod::POM::Web::PSGI;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    is $res->code, 200;
    like $res->content, qr/<html/i;
};
