# parser_mixedlists.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 17 };

use IO::File;
use PurpleWiki::Parser::WikiText;
use PurpleWiki::Config;
my $configfile = 't';

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

### mixed_list.txt -- mixed lists

my $config = new PurpleWiki::Config($configfile);
my $wikiContent = &readFile('t/txt/tree_mixedlists.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);

ok(scalar @{$wiki->root->children} == 1);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 1);

# Mixed list.  (Tests 4-17)

ok($wiki->root->children->[0]->children->[0]->type eq 'ul');
ok(scalar @{$wiki->root->children->[0]->children->[0]->children} == 1);
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    content->[0]->content eq 'u list 1');

ok(scalar @{$wiki->root->children->[0]->children->[0]->children->[0]->
    children} == 2);
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    children->[0]->type eq 'ul');
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    children->[0]->children->[0]->type eq 'li');
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    children->[0]->children->[0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    children->[0]->children->[0]->content->[0]->content eq 'sub u list');

ok($wiki->root->children->[0]->children->[0]->children->[0]->
    children->[1]->type eq 'ol');
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    children->[1]->children->[0]->type eq 'li');
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    children->[1]->children->[0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    children->[1]->children->[0]->content->[0]->content eq 'sub n list');

