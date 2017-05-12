# parser03.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 33 };

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

### tree_test07.txt -- Inline node special cases.
### 
### Entire structural node is a special inline node (e.g. entire
### first paragraph is bold).  Nested inline nodes.

my $config = new PurpleWiki::Config($configdir);
my $wikiContent = &readFile('t/txt/tree_test07.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);

ok(scalar @{$wiki->root->children} == 1);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 2);
ok($wiki->root->children->[0]->children->[0]->type eq 'p');
ok($wiki->root->children->[0]->children->[0]->content->[0]->type
    eq 'b');
ok($wiki->root->children->[0]->children->[0]->content->[0]->children->
   [0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->content->[0]->children->
   [0]->content eq 'Bold paragraph.');

ok($wiki->root->children->[0]->children->[1]->type eq 'p');
ok($wiki->root->children->[0]->children->[1]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[0]->content
    eq 'Nested inline tags.  ');
ok($wiki->root->children->[0]->children->[1]->content->[1]->type
    eq 'b');
ok($wiki->root->children->[0]->children->[1]->content->[1]->children->
    [0]->type eq 'i');
ok($wiki->root->children->[0]->children->[1]->content->[1]->children->
    [0]->children->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[1]->children->
    [0]->children->[0]->content eq 'Bold and italics (using quotes).');
ok($wiki->root->children->[0]->children->[1]->content->[2]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[2]->content
    eq "\n");
ok($wiki->root->children->[0]->children->[1]->content->[3]->type
    eq 'b');
ok($wiki->root->children->[0]->children->[1]->content->[3]->children->
    [0]->type eq 'i');
ok($wiki->root->children->[0]->children->[1]->content->[3]->children->
    [0]->children->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[3]->children->
    [0]->children->[0]->content eq 'Bold and italics (tagged)');
ok($wiki->root->children->[0]->children->[1]->content->[4]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[4]->content
    eq '.  ');
ok($wiki->root->children->[0]->children->[1]->content->[5]->type
    eq 'i');
ok($wiki->root->children->[0]->children->[1]->content->[5]->children->
    [0]->type eq 'b');
ok($wiki->root->children->[0]->children->[1]->content->[5]->children->
    [0]->children->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[5]->children->
    [0]->children->[0]->content eq 'Italics and bold.');
ok($wiki->root->children->[0]->children->[1]->content->[6]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[6]->content
    eq "\n");
ok($wiki->root->children->[0]->children->[1]->content->[7]->type
    eq 'i');
ok($wiki->root->children->[0]->children->[1]->content->[7]->children->
    [0]->type eq 'wikiword');
ok($wiki->root->children->[0]->children->[1]->content->[7]->children->
    [0]->content eq 'ItalicsWikiWord');
ok($wiki->root->children->[0]->children->[1]->content->[7]->children->
    [1]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[7]->children->
    [1]->content eq '.');
