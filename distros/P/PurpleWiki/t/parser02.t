# parser.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 9 };

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

### tree_test06.txt -- Single character headers.

my $config = new PurpleWiki::Config($configdir);
my $wikiContent = &readFile('t/txt/tree_test06.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);

ok(scalar @{$wiki->root->children} == 1);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 2);
ok($wiki->root->children->[0]->children->[0]->type eq 'h');
ok($wiki->root->children->[0]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[0]->content->[0]->content 
    eq 'A');
ok($wiki->root->children->[0]->children->[1]->type eq 'p');
ok($wiki->root->children->[0]->children->[1]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[0]->content
    eq 'Hello world.');
