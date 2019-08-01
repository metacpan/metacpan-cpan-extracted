use v5.28;
use strict;

use Encode qw(encode);
use Mojo::UserAgent;
use YAML::Dumper;
use Getopt::Long qw< GetOptions >;

use NewsExtractor;

my %opts;
GetOptions(
    \%opts,
);
my $url = shift @ARGV or die;

my $dumper = YAML::Dumper->new;
$dumper->indent_width(4);

my $x = NewsExtractor->new( url => $url );
my ($err, $y) = $x->download;

if ($err) {
    print "Download Failed\n";
    print $dumper->dump({ message => $err->message, debug => $err->debug });

} else {
    ($err, my $article) = $y->parse;

    if ($article) {
        print encode( "utf8" => $dumper->dump({ %$article }) );
    } else {
        print "No Article\n";
        print $dumper->dump({ message => $err->message, debug => $err->debug });
    }
}
