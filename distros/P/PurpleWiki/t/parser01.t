# parser01.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 159 };

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

### tree_test01.txt

my $config = new PurpleWiki::Config($configfile);
my $wikiContent = &readFile('t/txt/tree_test01.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);
$wiki->title('Tree Test 1');

# Document.  (Tests 1-4)

ok($wiki->title eq 'Tree Test 1');
ok(ref $wiki->root eq 'PurpleWiki::StructuralNode');
ok($wiki->root->type eq 'document');
ok(scalar @{$wiki->root->children} == 2);

# Basic Wiki Test (Tests 5-9)

ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 2);
ok($wiki->root->children->[0]->children->[0]->type eq 'h');
ok($wiki->root->children->[0]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[0]->content->[0]->content 
    eq 'Basic Wiki Test');

# Introduction (Tests 10-37)

ok($wiki->root->children->[0]->children->[1]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children->[1]->children}
    == 13);
ok($wiki->root->children->[0]->children->[1]->children->[0]->type
    eq 'h');
ok($wiki->root->children->[0]->children->[1]->children->[0]->content->
    [0]->content eq 'Introduction');
ok($wiki->root->children->[0]->children->[1]->children->[1]->type
    eq 'p');
ok($wiki->root->children->[0]->children->[1]->children->[1]->content->
    [0]->content eq
    "This is a bare-bones, error-free example of a textual Wiki page.  The\nquestion is, will this parse correctly?");
ok($wiki->root->children->[0]->children->[1]->children->[2]->type
    eq 'pre');
ok($wiki->root->children->[0]->children->[1]->children->[2]->content->
    [0]->content eq "  Only time will tell.\n  And tell it will.");
ok($wiki->root->children->[0]->children->[1]->children->[3]->type
    eq 'p');
ok($wiki->root->children->[0]->children->[1]->children->[3]->content->
    [0]->content eq "This is a paragraph.");
ok($wiki->root->children->[0]->children->[1]->children->[4]->type
    eq 'p');
ok($wiki->root->children->[0]->children->[1]->children->[4]->content->
    [0]->content eq "This is another paragraph.");
ok($wiki->root->children->[0]->children->[1]->children->[5]->type
    eq 'p');
ok($wiki->root->children->[0]->children->[1]->children->[5]->content->
    [0]->content eq "How about mixed paragraphs and preformatting?");
ok($wiki->root->children->[0]->children->[1]->children->[6]->type
    eq 'pre');
ok($wiki->root->children->[0]->children->[1]->children->[6]->content->
    [0]->content eq "   This should be preformatted.\n But is it?");
ok($wiki->root->children->[0]->children->[1]->children->[7]->type
    eq 'p');
ok($wiki->root->children->[0]->children->[1]->children->[7]->content->
    [0]->content eq "You should know by now.");
ok($wiki->root->children->[0]->children->[1]->children->[8]->type
    eq 'p');
ok($wiki->root->children->[0]->children->[1]->children->[8]->content->
    [0]->content eq
    "What about <strong>HTML</strong> in paragraphs?  You should see the tags.");
ok($wiki->root->children->[0]->children->[1]->children->[9]->type
    eq 'p');
ok(scalar @{$wiki->root->children->[0]->children->[1]->children->[9]->
    content} == 3);
ok($wiki->root->children->[0]->children->[1]->children->[9]->content->
    [0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[9]->content->
    [0]->content eq "Does the nowiki tag work?  ");
ok($wiki->root->children->[0]->children->[1]->children->[9]->content->
    [1]->type eq 'nowiki');
ok($wiki->root->children->[0]->children->[1]->children->[9]->content->
    [1]->content eq "Well, that depends.  Do you see\n'''quotes''' or not?");
ok($wiki->root->children->[0]->children->[1]->children->[9]->content->
    [2]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[9]->content->
    [2]->content eq "  If so, then be happy!");

# Unordered list.  (Tests 38-44)

ok($wiki->root->children->[0]->children->[1]->children->[10]->type
    eq 'section');
ok($wiki->root->children->[0]->children->[1]->children->[10]->children->
    [0]->type eq 'h');
ok($wiki->root->children->[0]->children->[1]->children->[10]->children->
    [0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[10]->children->
    [0]->content->[0]->content eq 'Lists');
ok($wiki->root->children->[0]->children->[1]->children->[10]->children->
    [1]->type eq 'p');
ok($wiki->root->children->[0]->children->[1]->children->[10]->children->
    [1]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[10]->children->
    [1]->content->[0]->content eq 'Tests moved to tree_test14.txt.');

# Quote formatting.  (Tests 45-66)

ok($wiki->root->children->[0]->children->[1]->children->[11]->type
    eq 'section');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [0]->type eq 'h');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [0]->content->[0]->content eq 'Formatting');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->type eq 'p');
ok(scalar @{$wiki->root->children->[0]->children->[1]->children->
    [11]->children->[1]->content} == 7);
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[0]->content eq 'This is ');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[1]->type eq 'i');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[1]->children->[0]->content eq 'italics');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[2]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[2]->content eq '.  This is ');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[3]->type eq 'b');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[3]->children->[0]->content eq 'bold');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[4]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[4]->content eq '.  This is ');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[5]->type eq 'b');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[5]->children->[0]->type eq 'i');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[5]->children->[0]->children->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[5]->children->[0]->children->[0]->content eq
    "bold and\nitalic");
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[6]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [1]->content->[6]->content eq '.');

# HTML formatting.  (Tests 67-99)

ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->type eq 'p');
ok(scalar @{$wiki->root->children->[0]->children->[1]->children->
    [11]->children->[2]->content} == 12);
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[0]->type eq 'wikiword');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[0]->content eq 'UseModWiki');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[1]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[1]->content eq ' also supports HTML bold and italic tags.  This is ');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[2]->type eq 'i');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[2]->children->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[2]->children->[0]->content eq 'italics');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[3]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[3]->content eq '.  This is ');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[4]->type eq 'b');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[4]->children->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[4]->children->[0]->content eq 'bold');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[5]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[5]->content eq '.  This is ');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[6]->type eq 'b');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[6]->children->[0]->type eq 'i');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[6]->children->[0]->children->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[6]->children->[0]->children->[0]->content eq
    'bold and italic');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[7]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[7]->content eq '.  This is ');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[8]->type eq 'i');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[8]->children->[0]->type eq 'b');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[8]->children->[0]->children->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[8]->children->[0]->children->[0]->content eq
    'italic and bold');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[9]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[9]->content eq '.  This is ');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[10]->type eq 'tt');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[10]->children->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[10]->children->[0]->content eq 'monospace');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[11]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[11]->children->
    [2]->content->[11]->content eq '.');

# Links.  (Tests 100-151)

ok($wiki->root->children->[0]->children->[1]->children->[12]->type
    eq 'section');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [0]->type eq 'h');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [0]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [0]->content->[0]->content eq 'Links');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->type eq 'p');
ok(scalar @{$wiki->root->children->[0]->children->[1]->children->
    [12]->children->[1]->content} == 15);
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[0]->content eq 'How about a paragraph with some ');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[1]->type eq 'wikiword');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[1]->content eq 'WikiWords');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[2]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[2]->content eq '?  How about a ');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[3]->type eq 'freelink');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[3]->content eq "double\nbracketed free link");
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[4]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[4]->content eq '?  How about a link to ');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[5]->type eq 'link');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[5]->href eq 'http://www.eekim.com/');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[5]->content eq "my\nhomepage");
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[6]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[6]->content eq '.  What about the URL itself, like ');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[7]->type eq 'url');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[7]->href eq 'http://www.eekim.com/');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[7]->content eq "http://www.eekim.com/");
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[8]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[8]->content eq ".\nHow about not linking a ");
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[9]->type eq 'nowiki');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[9]->content eq "WikiWikiWord");
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[10]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[10]->content eq ". How about a\n");
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[11]->type eq 'wikiword');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[11]->content eq 'UseMod:InterWiki');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[12]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[12]->content eq " link?  Finally, how about separating a\n");
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[13]->type eq 'wikiword');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[13]->content eq 'WordFromNumbers');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[14]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [1]->content->[14]->content eq "123 using double quotes?");

ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->type eq 'p');
ok(scalar @{$wiki->root->children->[0]->children->[1]->children->
    [12]->children->[2]->content} == 5);
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[0]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[0]->content eq 'How about some funkier URLs like ');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[1]->type eq 'url');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[1]->href eq 'http://www.burningchrome.com:81/');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[1]->content eq "http://www.burningchrome.com:81/");
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[2]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[2]->content eq "?  Or,\n");
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[3]->type eq 'url');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[3]->href eq 'http://www.eekim.com/cgi-bin/dkr?version=2&date=20021225');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[3]->content eq "http://www.eekim.com/cgi-bin/dkr?version=2&date=20021225");
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[4]->type eq 'text');
ok($wiki->root->children->[0]->children->[1]->children->[12]->children->
    [2]->content->[4]->content eq '?');

# Conclusion.  (Tests 152-159)

ok($wiki->root->children->[1]->type eq 'section');
ok(scalar @{$wiki->root->children->[1]->children} == 2);
ok($wiki->root->children->[1]->children->[0]->type eq 'h');
ok($wiki->root->children->[1]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[1]->children->[0]->content->[0]->content 
    eq 'Conclusion');
ok($wiki->root->children->[1]->children->[1]->type eq 'p');
ok($wiki->root->children->[1]->children->[1]->content->[0]->type eq 
    'text');
ok($wiki->root->children->[1]->children->[1]->content->[0]->content eq
    "This concludes this test.  We now return you to your regular\nprogramming.");

### tree_test02.txt

