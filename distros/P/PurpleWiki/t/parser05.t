# parser05.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 36 };

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

### tree_test09.txt -- InterWikiLinks

my $config = new PurpleWiki::Config($configdir);
my $wikiContent = &readFile('t/txt/tree_test09.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);

# Wiki content.  ( tests)
ok(scalar @{$wiki->root->children} == 1);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 7);
ok($wiki->root->children->[0]->children->[0]->type eq 'p');
ok($wiki->root->children->[0]->children->[0]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[0]->content->[0]->content
    eq 'Collab:Home');

ok($wiki->root->children->[0]->children->[1]->type eq 'p');
ok($wiki->root->children->[0]->children->[1]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[1]->content->[0]->content
    eq 'Collab:Home/Test');

ok($wiki->root->children->[0]->children->[2]->type eq 'p');
ok($wiki->root->children->[0]->children->[2]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[2]->content->[0]->content
    eq 'Eekim:Home');

ok($wiki->root->children->[0]->children->[3]->type eq 'p');
ok($wiki->root->children->[0]->children->[3]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[3]->content->[0]->content
    eq 'Eekim:Home');
ok($wiki->root->children->[0]->children->[3]->content->[1]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[3]->content->[1]->content
    eq '/Test');

ok($wiki->root->children->[0]->children->[4]->type eq 'p');
ok($wiki->root->children->[0]->children->[4]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[4]->content->[0]->content
    eq 'EekimBlah');
ok($wiki->root->children->[0]->children->[4]->content->[1]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[4]->content->[1]->content
    eq ':Home');

ok($wiki->root->children->[0]->children->[5]->type eq 'p');
ok($wiki->root->children->[0]->children->[5]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[5]->content->[0]->content
    eq 'EekimBlah');
ok($wiki->root->children->[0]->children->[5]->content->[1]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[5]->content->[1]->content
    eq ':Home');
ok($wiki->root->children->[0]->children->[5]->content->[2]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[5]->content->[2]->content
    eq '/Test');

ok($wiki->root->children->[0]->children->[6]->type eq 'p');
ok($wiki->root->children->[0]->children->[6]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[6]->content->[0]->content
    eq 'EekimBlah');
ok($wiki->root->children->[0]->children->[6]->content->[1]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[6]->content->[1]->content
    eq ':');
ok($wiki->root->children->[0]->children->[6]->content->[2]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[6]->content->[2]->content
    eq 'HomePage');
