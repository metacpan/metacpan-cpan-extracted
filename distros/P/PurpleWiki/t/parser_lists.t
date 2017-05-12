# parser_lists.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 139 };

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

### tree_lists.txt -- funky list and indentation parsing

my $config = new PurpleWiki::Config($configfile);
my $wikiContent = &readFile('t/txt/tree_lists.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);

ok(scalar @{$wiki->root->children} == 1);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 9);

# Unordered list.  (Tests 4-30)

ok($wiki->root->children->[0]->children->[0]->type eq 'ul');
ok(scalar @{$wiki->root->children->[0]->children->[0]->children} == 2);
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[0]->
    content->[0]->content eq 'Lists are an excellent test.');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    content->[0]->content eq "Yessirreebob.\n  More of second item.");

ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->type eq 'ul');
ok(scalar @{$wiki->root->children->[0]->children->[0]->children->
    [1]->children->[0]->children} == 4);
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[0]->type eq 'li');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[0]->content->[0]->content eq
    'This is a sublist.');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[1]->type eq 'li');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[1]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[1]->content->[0]->content eq
    'This is item two of the sublist.');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[2]->type eq 'li');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[2]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[2]->content->[0]->content eq
    "Item three of the sublist\n   should be\none sentence.");

ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[2]->children->[0]->type eq 'ul');
ok(scalar @{$wiki->root->children->[0]->children->[0]->children->
    [1]->children->[0]->children->[2]->children->[0]->children} == 1);
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[2]->children->[0]->children->[0]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[2]->children->[0]->children->[0]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[2]->children->[0]->children->[0]->
    content->[0]->content eq 'This is a subsublist.');

ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[3]->type eq 'li');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[3]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[1]->
    children->[0]->children->[3]->content->[0]->content eq
    'This is item four of the sublist.');

# Ordered list.  (Tests 31-51)

ok($wiki->root->children->[0]->children->[1]->type eq 'ol');
ok(scalar @{$wiki->root->children->[0]->children->[1]->children} == 2);
ok($wiki->root->children->[0]->children->[1]->children->[0]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[1]->children->[0]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[0]->
    content->[0]->content eq 'How about numbered lists?');
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    content->[0]->content eq 'What about them?');

ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->type eq 'ol');
ok(scalar @{$wiki->root->children->[0]->children->[1]->children->
    [1]->children->[0]->children} == 2);
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->children->[0]->type eq 'li');
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->children->[0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->children->[0]->content->[0]->content eq
    'Will it parse correctly?');

ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->children->[0]->children->[0]->type eq 'ol');
ok(scalar @{$wiki->root->children->[0]->children->[1]->children->
    [1]->children->[0]->children->[0]->children->[0]->children} == 1);
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->children->[0]->children->[0]->children->[0]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->children->[0]->children->[0]->children->[0]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->children->[0]->children->[0]->children->[0]->
    content->[0]->content eq
    'I sure hope so.');

ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->children->[1]->type eq 'li');
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->children->[1]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[1]->
    children->[0]->children->[1]->content->[0]->content eq
    'Only one way to find out.');

# Mixed unordered and ordered.  (Tests 52-70)

ok($wiki->root->children->[0]->children->[2]->type eq 'ul');
ok(scalar @{$wiki->root->children->[0]->children->[2]->children} == 3);
ok($wiki->root->children->[0]->children->[2]->children->[0]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[2]->children->[0]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[2]->children->[0]->
    content->[0]->content eq 'Mixed list.');
ok($wiki->root->children->[0]->children->[2]->children->[1]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[2]->children->[1]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[2]->children->[1]->
    content->[0]->content eq "Second item.");

ok($wiki->root->children->[0]->children->[2]->children->[1]->
    children->[0]->type eq 'ol');
ok(scalar @{$wiki->root->children->[0]->children->[2]->children->
    [1]->children->[0]->children} == 2);
ok($wiki->root->children->[0]->children->[2]->children->[1]->
    children->[0]->children->[0]->type eq 'li');
ok($wiki->root->children->[0]->children->[2]->children->[1]->
    children->[0]->children->[0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[2]->children->[1]->
    children->[0]->children->[0]->content->[0]->content eq
    'Now do numbered list.');
ok($wiki->root->children->[0]->children->[2]->children->[1]->
    children->[0]->children->[1]->type eq 'li');
ok($wiki->root->children->[0]->children->[2]->children->[1]->
    children->[0]->children->[1]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[2]->children->[1]->
    children->[0]->children->[1]->content->[0]->content eq
    'Again.');

ok($wiki->root->children->[0]->children->[2]->children->[2]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[2]->children->[2]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[2]->children->[2]->
    content->[0]->content eq "Back to unordered list.");

# Mixed ordered and unordered.  (Tests 71-89)

ok($wiki->root->children->[0]->children->[3]->type eq 'ol');
ok(scalar @{$wiki->root->children->[0]->children->[3]->children} == 3);
ok($wiki->root->children->[0]->children->[3]->children->[0]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[3]->children->[0]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[3]->children->[0]->
    content->[0]->content eq 'Ordered list.');
ok($wiki->root->children->[0]->children->[3]->children->[1]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[3]->children->[1]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[3]->children->[1]->
    content->[0]->content eq "Number two.");

ok($wiki->root->children->[0]->children->[3]->children->[1]->
    children->[0]->type eq 'ul');
ok(scalar @{$wiki->root->children->[0]->children->[3]->children->
    [1]->children->[0]->children} == 2);
ok($wiki->root->children->[0]->children->[3]->children->[1]->
    children->[0]->children->[0]->type eq 'li');
ok($wiki->root->children->[0]->children->[3]->children->[1]->
    children->[0]->children->[0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[3]->children->[1]->
    children->[0]->children->[0]->content->[0]->content eq
    'Now do unordered.');
ok($wiki->root->children->[0]->children->[3]->children->[1]->
    children->[0]->children->[1]->type eq 'li');
ok($wiki->root->children->[0]->children->[3]->children->[1]->
    children->[0]->children->[1]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[3]->children->[1]->
    children->[0]->children->[1]->content->[0]->content eq
    'Again.');

ok($wiki->root->children->[0]->children->[3]->children->[2]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[3]->children->[2]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[3]->children->[2]->
    content->[0]->content eq "Number three.");

# Definition list.  (Tests 89-110)

ok($wiki->root->children->[0]->children->[4]->type eq 'dl');
ok(scalar @{$wiki->root->children->[0]->children->[4]->children} == 4);
ok($wiki->root->children->[0]->children->[4]->children->[0]->
    type eq 'dt');
ok($wiki->root->children->[0]->children->[4]->children->[0]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[4]->children->[0]->
    content->[0]->content eq 'definition lists');
ok($wiki->root->children->[0]->children->[4]->children->[1]->
    type eq 'dd');
ok($wiki->root->children->[0]->children->[4]->children->[1]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[4]->children->[1]->
    content->[0]->content eq "Will definition lists parse correctly?");
ok($wiki->root->children->[0]->children->[4]->children->[2]->
    type eq 'dt');
ok($wiki->root->children->[0]->children->[4]->children->[2]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[4]->children->[2]->
    content->[0]->content eq 'testing');
ok($wiki->root->children->[0]->children->[4]->children->[3]->
    type eq 'dd');
ok($wiki->root->children->[0]->children->[4]->children->[3]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[4]->children->[3]->
    content->[0]->content eq "This is a test.");

ok($wiki->root->children->[0]->children->[4]->children->[3]->
    children->[0]->type eq 'dl');
ok($wiki->root->children->[0]->children->[4]->children->[3]->
    children->[0]->children->[0]->type eq 'dt');
ok($wiki->root->children->[0]->children->[4]->children->[3]->
    children->[0]->children->[0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[4]->children->[3]->
    children->[0]->children->[0]->content->[0]->content eq
    'indented definition');
ok($wiki->root->children->[0]->children->[4]->children->[3]->
    children->[0]->children->[1]->type eq 'dd');
ok($wiki->root->children->[0]->children->[4]->children->[3]->
    children->[0]->children->[1]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[4]->children->[3]->
    children->[0]->children->[1]->content->[0]->content eq
    'This should be indented again.');

# Mixed paragraph and list.  (Tests 111-118)

ok($wiki->root->children->[0]->children->[5]->type eq 'p');
ok($wiki->root->children->[0]->children->[5]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[5]->content->[0]->
    content eq 'Okay, a mixed paragraph and list.');

ok($wiki->root->children->[0]->children->[6]->type eq 'ul');
ok(scalar @{$wiki->root->children->[0]->children->[6]->children} == 1);
ok($wiki->root->children->[0]->children->[6]->children->[0]->
    type eq 'li');
ok($wiki->root->children->[0]->children->[6]->children->[0]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[6]->children->[0]->
    content->[0]->content eq "This ought to work.\nDid it?");

# Indented text.  (Tests 119-136)

ok($wiki->root->children->[0]->children->[7]->type eq 'indent');
ok(scalar @{$wiki->root->children->[0]->children->[7]->children} == 2);
ok($wiki->root->children->[0]->children->[7]->children->[0]->
    type eq 'p');
ok($wiki->root->children->[0]->children->[7]->children->[0]->
    content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[7]->children->[0]->
    content->[0]->content eq 'Indented text.');

ok($wiki->root->children->[0]->children->[7]->children->[1]->
    type eq 'indent');
ok(scalar @{$wiki->root->children->[0]->children->[7]->children->
    [1]->children} == 3);
ok($wiki->root->children->[0]->children->[7]->children->[1]->
    children->[0]->type eq 'p');
ok($wiki->root->children->[0]->children->[7]->children->[1]->
    children->[0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[7]->children->[1]->
    children->[0]->content->[0]->content eq 'Double indented text.');
ok($wiki->root->children->[0]->children->[7]->children->[1]->
    children->[1]->type eq 'p');
ok($wiki->root->children->[0]->children->[7]->children->[1]->
    children->[1]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[7]->children->[1]->
    children->[1]->content->[0]->content eq
    "Another paragraph of double indented text.\n  Continuation.\nMore continuation.");

ok($wiki->root->children->[0]->children->[7]->children->[1]->
    children->[2]->type eq 'indent');
ok(scalar @{$wiki->root->children->[0]->children->[7]->children->
    [1]->children->[2]->children} == 1);
ok($wiki->root->children->[0]->children->[7]->children->[1]->
    children->[2]->children->[0]->type eq 'p');
ok($wiki->root->children->[0]->children->[7]->children->[1]->
    children->[2]->children->[0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[7]->children->[1]->
    children->[2]->children->[0]->content->[0]->content eq 'Triple indented text.');

# Finito!  (Tests 137-139)

ok($wiki->root->children->[0]->children->[8]->type eq 'p');
ok($wiki->root->children->[0]->children->[8]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[8]->content->[0]->
    content eq 'Text after indentation.');
