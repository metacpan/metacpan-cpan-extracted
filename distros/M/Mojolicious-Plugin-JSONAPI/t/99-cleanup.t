#! perl -w

use Test::Most;
use JSONAPI::Document;

my $j = JSONAPI::Document->new({
    api_url  => 'http://example.com',
    data_dir => 't/share',
});

$j->chi->clear();
ok(1);
done_testing;
