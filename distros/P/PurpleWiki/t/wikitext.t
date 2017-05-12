# wikitext.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 24 };

use IO::File;
use PurpleWiki::Parser::WikiText;
use PurpleWiki::Config;
my $configdir = 't';

sub readFile {
    my $fileName = shift;
    my $fileContent;

    my $fh = new IO::File $fileName;
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

#########################

my $config = new PurpleWiki::Config($configdir);
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my ($input, $output, $shouldBe, $wiki);

my @files = qw(tree_freelinks tree_hr tree_interlinks tree_lists tree_pre
               tree_mixedlists
               tree_test01 tree_test02 tree_test03
               tree_test04 tree_test05 tree_test06 tree_test07 tree_test08
               tree_test09 tree_test11 tree_test12
               hr1 hr2 hr3 hr4 hr5 hr6 hr7);

foreach my $filename (@files) {
    $input = &readFile("t/txt/$filename.txt");
    $shouldBe = &readFile("t/output/$filename.txt");
    $wiki = $wikiParser->parse($input);
    $output = $wiki->view('wikitext');
    ok($output eq $shouldBe);
}
