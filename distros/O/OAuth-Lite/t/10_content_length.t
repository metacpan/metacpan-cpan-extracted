use strict;
use warnings;
use utf8;
use Test::More;

use OAuth::Lite::Consumer;

# length(udnef) returns undef after perl 5.12+.

my $c = OAuth::Lite::Consumer->new(
    key          => 'kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
    secret       => 'ssssssssssssssss',
);
my $req = $c->gen_oauth_request(
    params => {
        oauth_callback => "oob",
    },
    realm => "",
    url   => "http://localhost/",
);
is($req->method, 'POST');
is($req->content_length, 0);

done_testing;

