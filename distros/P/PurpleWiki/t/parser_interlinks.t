# parser06.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 93 };

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

### tree_interlinks.txt -- Granular WikiWord links

my $config = new PurpleWiki::Config($configdir);
my $wikiContent = &readFile('t/txt/tree_interlinks.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);

# Wiki content.  ( tests)
ok(scalar @{$wiki->root->children} == 1);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 24);
ok($wiki->root->children->[0]->children->[0]->type eq 'p');
ok($wiki->root->children->[0]->children->[0]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[0]->content->[0]->content
    eq 'WikiPage#123');

ok($wiki->root->children->[0]->children->[1]->type eq 'p');
ok($wiki->root->children->[0]->children->[1]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[1]->content->[0]->content
    eq 'WikiPage#ABC');

ok($wiki->root->children->[0]->children->[2]->type eq 'p');
ok($wiki->root->children->[0]->children->[2]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[2]->content->[0]->content
    eq 'WikiPage#A1');

ok($wiki->root->children->[0]->children->[3]->type eq 'p');
ok($wiki->root->children->[0]->children->[3]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[3]->content->[0]->content
    eq 'WikiPage#1A');

ok($wiki->root->children->[0]->children->[4]->type eq 'p');
ok($wiki->root->children->[0]->children->[4]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[4]->content->[0]->content
    eq 'WikiPage');
ok($wiki->root->children->[0]->children->[4]->content->[1]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[4]->content->[1]->content
    eq '#abc');

ok($wiki->root->children->[0]->children->[5]->type eq 'p');
ok($wiki->root->children->[0]->children->[5]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[5]->content->[0]->content
    eq 'Collab:WikiPage#123');

ok($wiki->root->children->[0]->children->[6]->type eq 'p');
ok($wiki->root->children->[0]->children->[6]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[6]->content->[0]->content
    eq 'Collab:WikiPage#ABC');

ok($wiki->root->children->[0]->children->[7]->type eq 'p');
ok($wiki->root->children->[0]->children->[7]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[7]->content->[0]->content
    eq 'Collab:WikiPage#A1');

ok($wiki->root->children->[0]->children->[8]->type eq 'p');
ok($wiki->root->children->[0]->children->[8]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[8]->content->[0]->content
    eq 'Collab:WikiPage#1A');

ok($wiki->root->children->[0]->children->[9]->type eq 'p');
ok($wiki->root->children->[0]->children->[9]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[9]->content->[0]->content
    eq 'Collab:WikiPage');
ok($wiki->root->children->[0]->children->[9]->content->[1]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[9]->content->[1]->content
    eq '#abc');

ok($wiki->root->children->[0]->children->[10]->type eq 'p');
ok($wiki->root->children->[0]->children->[10]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[10]->content->[0]->content
    eq 'Eekim:');
ok($wiki->root->children->[0]->children->[10]->content->[1]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[10]->content->[1]->content
    eq 'WikiPage#123');

ok($wiki->root->children->[0]->children->[11]->type eq 'p');
ok($wiki->root->children->[0]->children->[11]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[11]->content->[0]->content
    eq 'Eekim:');
ok($wiki->root->children->[0]->children->[11]->content->[1]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[11]->content->[1]->content
    eq 'WikiPage');
ok($wiki->root->children->[0]->children->[11]->content->[2]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[11]->content->[2]->content
    eq '#abc');

ok($wiki->root->children->[0]->children->[12]->type eq 'p');
ok($wiki->root->children->[0]->children->[12]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[12]->content->[0]->content
    eq 'WikiPage/Subpage#123');

ok($wiki->root->children->[0]->children->[13]->type eq 'p');
ok($wiki->root->children->[0]->children->[13]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[13]->content->[0]->content
    eq 'WikiPage/Subpage#ABC');

ok($wiki->root->children->[0]->children->[14]->type eq 'p');
ok($wiki->root->children->[0]->children->[14]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[14]->content->[0]->content
    eq 'WikiPage/Subpage#A1');

ok($wiki->root->children->[0]->children->[15]->type eq 'p');
ok($wiki->root->children->[0]->children->[15]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[15]->content->[0]->content
    eq 'WikiPage/Subpage#1A');

ok($wiki->root->children->[0]->children->[16]->type eq 'p');
ok($wiki->root->children->[0]->children->[16]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[16]->content->[0]->content
    eq 'WikiPage/Subpage');
ok($wiki->root->children->[0]->children->[16]->content->[1]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[16]->content->[1]->content
    eq '#abc');

ok($wiki->root->children->[0]->children->[17]->type eq 'p');
ok($wiki->root->children->[0]->children->[17]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[17]->content->[0]->content
    eq 'Collab:WikiPage/Subpage#123');

ok($wiki->root->children->[0]->children->[18]->type eq 'p');
ok($wiki->root->children->[0]->children->[18]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[18]->content->[0]->content
    eq 'Collab:WikiPage/Subpage#ABC');

ok($wiki->root->children->[0]->children->[19]->type eq 'p');
ok($wiki->root->children->[0]->children->[19]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[19]->content->[0]->content
    eq 'Collab:WikiPage/Subpage#A1');

ok($wiki->root->children->[0]->children->[20]->type eq 'p');
ok($wiki->root->children->[0]->children->[20]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[20]->content->[0]->content
    eq 'Collab:WikiPage/Subpage#1A');

ok($wiki->root->children->[0]->children->[21]->type eq 'p');
ok($wiki->root->children->[0]->children->[21]->content->[0]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[21]->content->[0]->content
    eq 'Collab:WikiPage/Subpage');
ok($wiki->root->children->[0]->children->[21]->content->[1]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[21]->content->[1]->content
    eq '#abc');

ok($wiki->root->children->[0]->children->[22]->type eq 'p');
ok($wiki->root->children->[0]->children->[22]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[22]->content->[0]->content
    eq 'Foo::');
ok($wiki->root->children->[0]->children->[22]->content->[1]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[22]->content->[1]->content
    eq 'BarBaz');

ok($wiki->root->children->[0]->children->[23]->type eq 'p');
ok($wiki->root->children->[0]->children->[23]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[23]->content->[0]->content
    eq 'Perplog::Weblog::');
ok($wiki->root->children->[0]->children->[23]->content->[1]->type
    eq 'wikiword');
ok($wiki->root->children->[0]->children->[23]->content->[1]->content
    eq 'LiveJournal');
