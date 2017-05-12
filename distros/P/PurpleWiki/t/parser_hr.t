# parser_hr.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 34 };

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

### tree_hr.txt -- hard rules

my $config = new PurpleWiki::Config($configdir);
my $wikiContent = &readFile('t/txt/tree_hr.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);
my $section = $wiki->root->children->[0];

# Wiki content.  ( tests)
ok(scalar @{$wiki->root->children} == 4);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 2);

ok($wiki->root->children->[0]->children->[0]->type eq 'h');
ok($wiki->root->children->[0]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[0]->content->[0]->content 
    eq 'Section 1');

ok($wiki->root->children->[0]->children->[1]->type eq 'p');
ok($wiki->root->children->[0]->children->[1]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[0]->content 
    eq 'Howdie doody!');

ok($wiki->root->children->[1]->type eq 'section');
ok(scalar @{$wiki->root->children->[1]->children} == 1);

ok($wiki->root->children->[1]->children->[0]->type eq 'p');
ok($wiki->root->children->[1]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[1]->children->[0]->content->[0]->content 
    eq 'This is section 2, but there is no header.');

ok($wiki->root->children->[2]->type eq 'section');
ok(scalar @{$wiki->root->children->[2]->children} == 2);

ok($wiki->root->children->[2]->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[2]->children->[0]->children} == 2);

ok($wiki->root->children->[2]->children->[0]->children->[0]->type eq 'h');
ok($wiki->root->children->[2]->children->[0]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[2]->children->[0]->children->[0]->content->[0]->content
    eq 'Section 3.1');

ok($wiki->root->children->[2]->children->[0]->children->[1]->type eq 'p');
ok($wiki->root->children->[2]->children->[0]->children->[1]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[2]->children->[0]->children->[1]->content->[0]->content
    eq 'This is section 3.1, not 2.1.');

ok($wiki->root->children->[2]->children->[1]->type eq 'section');
ok(scalar @{$wiki->root->children->[2]->children->[1]->children} == 1);

ok($wiki->root->children->[2]->children->[1]->children->[0]->type eq 'p');
ok($wiki->root->children->[2]->children->[1]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[2]->children->[1]->children->[0]->content->[0]->content
    eq 'This is section 3.2.');

ok($wiki->root->children->[3]->type eq 'section');
ok(scalar @{$wiki->root->children->[3]->children} == 1);

ok($wiki->root->children->[3]->children->[0]->type eq 'h');
ok($wiki->root->children->[3]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[3]->children->[0]->content->[0]->content 
    eq 'Section 4');
