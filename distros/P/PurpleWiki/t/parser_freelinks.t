# parser_freelinks.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 17 };

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

### tree_freelinks.txt -- Free links.

my $config = new PurpleWiki::Config($configdir);
my $wikiContent = &readFile('t/txt/tree_freelinks.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);

# Wiki content.  ( tests)
ok(scalar @{$wiki->root->children} == 1);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 4);
ok($wiki->root->children->[0]->children->[0]->type eq 'p');
ok($wiki->root->children->[0]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[0]->content->[0]->content
    eq '2003');
ok($wiki->root->children->[0]->children->[0]->content->[1]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[0]->content->[1]->content
    eq 'OnlineTools');

ok($wiki->root->children->[0]->children->[1]->type eq 'p');
ok($wiki->root->children->[0]->children->[1]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[1]->content->[0]->content
    eq 'OnlineTools2003');

ok($wiki->root->children->[0]->children->[2]->type eq 'p');
ok($wiki->root->children->[0]->children->[2]->content->[0]->type
    eq 'freelink');
ok($wiki->root->children->[0]->children->[2]->content->[0]->content
    eq '2003Conference');

ok($wiki->root->children->[0]->children->[3]->type eq 'p');
ok($wiki->root->children->[0]->children->[3]->content->[0]->type
    eq 'freelink');
ok($wiki->root->children->[0]->children->[3]->content->[0]->content
    eq '2003OnlineTools');
