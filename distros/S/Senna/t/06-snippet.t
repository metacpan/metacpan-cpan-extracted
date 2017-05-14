#!perl
use strict;
use File::Temp;

my $HAS_ENCODE;

BEGIN
{
    $HAS_ENCODE = eval { require Encode };
    require Test::More;
    Test::More->import(tests => 22 - ($HAS_ENCODE ? 0 : 8));
}

BEGIN
{
    use_ok("Senna::Constants", "SEN_ENC_EUCJP");
    use_ok("Senna::Snippet");
}

my $WIDTH = 100;
my $MAX_RESULTS = 8;

my $text = <<EOM;
snippet(KWIC)を作成するためのAPI。

sen_snip *sen_snip_open(sen_encoding encoding, int flags, size_t width, unsigned int max_results,
                        const char *defaultopentag, const char *defaultclosetag,
                        sen_snip_mapping *mapping);

新たなsen_snipインスタンスを生成します。
encodingには、sen_enc_default, sen_enc_none, sen_enc_euc_jp, sen_enc_utf8, sen_enc_sjis のいずれかを指定します。
flagsには、SEN_SNIP_NORMALIZE(正規化して検索を行う)が指定できます。
widthは、snippetの幅をバイト長で指定します。eucやsjisの場合にはその半分、utf-8の場合にはその1/3の長さの日本語が格納できるでしょう。
max_resultsは、snippetの個数を指定します。
defaultopentagは、snippet中の検索単語の前につける文字列を指定します。
defaultclosetagは、snippet中の検索単語の後につける文字列を指定します。
mappingは、(現在は)NULLか-1を指定してください。-1を指定すると、HTMLのメタ文字列をエンコードしたsnippetを出力します。
defaultopentag,defaultclosetagの指す内容は、sen_snip_closeを呼ぶまで変更しないでください。
EOM

my $snip = Senna::Snippet->new(
    encoding    => SEN_ENC_EUCJP,
    width       => $WIDTH,
    max_results => $MAX_RESULTS,
);

$snip->add_cond(keyword => "sen");

my @r = $snip->exec(string => $text);
ok(scalar(@r) < $MAX_RESULTS, "results is less than $MAX_RESULTS");

foreach my $r (@r) {
    if ($HAS_ENCODE) {
        $r = Encode::decode('euc-jp', $r);
        ok(length($r) <= $WIDTH, "string size < $WIDTH");
    }
    like($r, qr|{sen}|, "sen is properly enclosed in {}");
}

$snip = Senna::Snippet->new(
    encoding    => SEN_ENC_EUCJP,
    width       => $WIDTH,
    max_results => $MAX_RESULTS,
);

$snip->add_cond(keyword => "snippet", open_tag => "<b>", close_tag => "</b>");

@r = $snip->exec(string => $text);
ok(scalar(@r) < $MAX_RESULTS, "results is less than $MAX_RESULTS");

foreach my $r (@r) {
    if ($HAS_ENCODE) {
        $r = Encode::decode('euc-jp', $r);
        ok(length($r) <= $WIDTH, "string size < $WIDTH");
    }
    like($r, qr|<b>snippet</b>|, "snippet is properly enclosed in {}");
}

1;