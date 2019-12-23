use v5.18;
use warnings;

use File::Slurp 'read_file', 'write_file';
use Test2::V0;
use NewsExtractor;

use constant TEST_FULL => $ENV{TEST_FULL} // 0;

skip_all 'Live tests: set env TEST_LIVE=1 to actually run tests.' unless $ENV{TEST_LIVE};

my (@fails, @success);
for (["urls-success", \&subtest], ["urls-fails", \&todo]) {
    my $fn = 't/data/' . $_->[0];
    my $cb = $_->[1];
    my @urls = read_file($fn, chomp => 1 );

    unless (TEST_FULL) {
        @urls = map { $urls[rand($#urls)] } 1..10
    }

    for my $url (@urls) {
        my ($error, $x) = NewsExtractor->new(url => $url)->download;

        if ($error) {
            fail "Download failed: $url";
            diag $error->message;
            push @fails, $url;
        } else {
            $cb->(
                "Extract: $url" => sub {
                    my $article = $x->parse;
                    if ($article) {
                        push @success, $url;
                        pass "parse";
                        ok $article->headline, "headline";
                        ok $article->article_body, "article_body";
                    } else {
                        push @fails, $url;
                        fail "parse";
                    }
                });
        }
    }
}

if (TEST_FULL) {
    write_file('t/data/urls-success', join("\n", @success));
    write_file('t/data/urls-fails', join("\n", @fails));
}

done_testing;
