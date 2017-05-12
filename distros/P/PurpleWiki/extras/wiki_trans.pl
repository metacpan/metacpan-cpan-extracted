#!/usr/bin/perl

use IO::File;
use Getopt::Long;
use PurpleWiki::Config;

my $useMoinMoin = 0;
GetOptions('moinmoin' => \$useMoinMoin);

if (@ARGV < 1) {
  print "Usage: $0 [--moinmoin] config_dir wikifile.txt [output_driver]\n";
  exit;
}

($useMoinMoin) ? require PurpleWiki::Parser::MoinMoin :
    require PurpleWiki::Parser::WikiText;

my $config = PurpleWiki::Config->new($ARGV[0]);
my $wikiContent = &readFile($ARGV[1]);
my $wikiParser;
if ($useMoinMoin) {
    $wikiParser = PurpleWiki::Parser::MoinMoin->new;
}
else {
    $wikiParser = PurpleWiki::Parser::WikiText->new;
}
my $wiki = $wikiParser->parse($wikiContent, add_node_ids=>0);
$wiki->title($ARGV[1]) if (!$wiki->title);

if (@ARGV == 3) {
    print $wiki->view($ARGV[2]);
}
else {
    print $wiki->view('debug');
}

#$wiki->view('XHTML','collapse'=>[2]);

# fini

### functions

sub readFile {
    my $fileName = shift;
    my $fileContent;

    $fh = new IO::File $fileName;
    if (defined $fh) {
        local ($/);
        $fileContent = <$fh>;
        $fh->close;
        return $fileContent;
    }
    else {
        return;
    }
}
