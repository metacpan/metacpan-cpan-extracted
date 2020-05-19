use Test2::V0;
use v5.18;

use File::Slurp 'read_file', 'write_file';
use NewsExtractor;

skip_all 'Live tests: set env TEST_LIVE=1 to actually run tests.' unless $ENV{TEST_LIVE};

my $fn = 't/data/urls';
my @urls = read_file($fn, chomp => 1 );

while (@urls) {
    my ($url) = splice(@urls, rand(@urls), 1);

    my ($error, $x) = NewsExtractor->new(url => $url)->download;

    if ($error) {
        fail "Download failed: $url";
        diag $error->message;
    } else {
        subtest(
            "Extract: $url" => sub {
                my $article = $x->parse;
                if ($article) {
                    pass "parse";
                    ok($article->headline, "headline");
                    ok($article->article_body, "article_body");
                    ok($article->journalist, "journalist");
                    ok($article->dateline, "dateline");
                } else {
                    fail "parse";
                }
            });
    }
}

done_testing;
