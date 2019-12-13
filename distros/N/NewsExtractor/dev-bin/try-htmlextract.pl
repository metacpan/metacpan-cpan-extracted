use v5.28;
use warnings;

use Try::Tiny;
use JSON;
use Encode qw(encode);
use Getopt::Long qw< GetOptions >;

use NewsExtractor;

my %opts;
GetOptions(
    \%opts,
);

my @urls;

if (-p STDIN) {
    @urls = <STDIN>;
} else {
    @urls = @ARGV;
}
@urls or die "No URLs to process";

my $json = JSON->new->pretty->canonical->utf8->allow_blessed->convert_blessed;

for my $url (@urls) {
    my $x = NewsExtractor->new( url => $url );
    my ($err, $y) = $x->download;

    if ($err) {
        print $json->encode({
            url => $url,
            DownloadFailure => { message => $err->message, debug => $err->debug }});
    } else {
        my $article;

        try {
            ($err, $article) = $y->parse;
        } catch {
            $err = $_;
        };

        if ($article) {
            print $json->encode({ url => $url, Article => $article });
        } else {
            print $json->encode({ url => $url, NoArticle => { message => $err->message, debug => $err->debug }});
        }
    }
}
