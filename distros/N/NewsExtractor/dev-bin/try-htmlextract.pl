use v5.28;
use warnings;
use FindBin;
use lib $FindBin::Bin. "/../lib";

use JSON;
use File::Slurp qw(read_file);
use Encode qw(encode);
use Getopt::Long qw< GetOptions >;
use Mojo::DOM;

use NewsExtractor;
use NewsExtractor::GenericExtractor;

my %opts;
GetOptions(
    \%opts,
    "file=s",
);
my $json = JSON->new->pretty->canonical->utf8->allow_blessed->convert_blessed;

if ($opts{file}) {
    my $html = read_file( $opts{file} );
    utf8::decode($html);

    my $dom = Mojo::DOM->new($html);
    my $x = NewsExtractor::GenericExtractor->new( dom => $dom );

    print $json->encode({
        file => $opts{file},
        extracted => {
            site_name => $x->site_name(),
            headline => $x->headline(),
            dateline => $x->dateline(),
            journalist => $x->journalist(),
            content_text => $x->content_text(),
        }
    });


} else {
    my @urls;

    if (! -t STDIN) {
        @urls = map { chomp; $_ } <STDIN>;
    } else {
        @urls = @ARGV;
    }
    @urls or die "No URLs to process";

    for my $url (@urls) {
        my $x = NewsExtractor->new( url => $url );
        my ($err, $y) = $x->download;

        if ($err) {
            print $json->encode({
                url => $url,
                DownloadFailure => { message => $err->message, debug => $err->debug }});
        } else {
            my $article;

            ($err, $article) = $y->parse;

            if ($article) {
                print $json->encode({ url => $url, Article => $article });
            } else {
                print $json->encode({ url => $url, NoArticle => { message => $err->message, debug => $err->debug }});
            }
        }
    }
}
