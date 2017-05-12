# parser08.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 18 };

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

### tree_test12.txt -- transclusion

my $config = new PurpleWiki::Config($configdir);
my $wikiContent = &readFile('t/txt/tree_test12.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);
my $section = $wiki->root->children->[0];

my $firstP = $section->children->[0];
my $secondP = $section->children->[1];
my $thirdP = $section->children->[2];
my $fourthP = $section->children->[3];
my $fifthP = $section->children->[4];

ok($firstP->type eq 'p');
#print $firstP->type . "\n";
ok($firstP->content->[0]->type eq 'transclusion');
#print $firstP->content->[0]->type . "\n";
ok($firstP->content->[0]->content eq 'A3');
#print $firstP->content->[0]->content . "\n";

ok($secondP->type eq 'pre');
#print $secondP->type . "\n";
ok($secondP->content->[0]->type eq 'text');
#print $secondP->content->[0]->type . "\n";
ok($secondP->content->[1]->type eq 'transclusion');
#print $secondP->content->[1]->type . "\n";
ok($secondP->content->[1]->content eq 'A3');
#print $secondP->content->[1]->content . "\n";

ok($thirdP->type eq 'p');
#print $thirdP->type . "\n";
ok($thirdP->content->[0]->type eq 'text');
#print $thirdP->content->[0]->type . "\n";
ok($thirdP->content->[1]->type eq 'transclusion');
#print $thirdP->content->[1]->type . "\n";
ok($thirdP->content->[1]->content eq 'A3');
#print $thirdP->content->[1]->content . "\n";

ok($fourthP->type eq 'p');
#print $fourthP->type . "\n";
ok($fourthP->content->[0]->type eq 'transclusion');
#print $fourthP->content->[0]->type . "\n";
ok($fourthP->content->[1]->type eq 'text');
#print $fourthP->content->[1]->type . "\n";
ok($fourthP->content->[0]->content eq 'A3');
#print $fourthP->content->[0]->content . "\n";

ok($fifthP->type eq 'indent');
#print $fifthP->type . "\n";
my $indent = $fifthP->children->[0];
ok($indent->content->[0]->type eq 'transclusion');
#print $indent->content->[0]->type . "\n";
ok($indent->content->[0]->content eq 'A3');
#print $indent->content->[0]->content . "\n";
