# parser_pre.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 28 };

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

### tree_pre.txt -- preformatted text

my $config = new PurpleWiki::Config($configdir);
my $wikiContent = &readFile('t/txt/tree_pre.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);

# Wiki content.  ( tests)
ok(scalar @{$wiki->root->children} == 1);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 5);
ok($wiki->root->children->[0]->children->[0]->type eq 'pre');
ok($wiki->root->children->[0]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[0]->content->[0]->content
    eq "void helloWorld() {\n    printf(\"Hello, world!\\n\");\n\n}");

ok($wiki->root->children->[0]->children->[1]->type eq 'pre');
ok($wiki->root->children->[0]->children->[1]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[0]->content
    eq "  more preformatted content.\n pretty cool, eh?");

ok($wiki->root->children->[0]->children->[2]->type eq 'pre');
ok($wiki->root->children->[0]->children->[2]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[2]->content->[0]->content
    eq 'Yeah, pretty cool.');

ok($wiki->root->children->[0]->children->[3]->type eq 'p');
ok($wiki->root->children->[0]->children->[3]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[3]->content->[0]->content
    eq 'The function, ');
ok($wiki->root->children->[0]->children->[3]->content->[1]->type
    eq 'tt');
ok($wiki->root->children->[0]->children->[3]->content->[1]->children->[0]
    ->type eq 'text');
ok($wiki->root->children->[0]->children->[3]->content->[1]->children->[0]
    ->content eq 'helloWorld()');
ok($wiki->root->children->[0]->children->[3]->content->[2]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[3]->content->[2]->content
    eq ', tells the story.');

ok($wiki->root->children->[0]->children->[4]->type eq 'pre');
ok($wiki->root->children->[0]->children->[4]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[4]->content->[0]->content
    eq 'Okay, now for some real ');
ok($wiki->root->children->[0]->children->[4]->content->[1]->type
    eq 'tt');
ok($wiki->root->children->[0]->children->[4]->content->[1]->children->[0]
    ->type eq 'text');
ok($wiki->root->children->[0]->children->[4]->content->[1]->children->[0]
    ->content eq 'funkiness');
ok($wiki->root->children->[0]->children->[4]->content->[2]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[4]->content->[2]->content
    eq '!');
