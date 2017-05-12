# parser07.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 74 };

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

### tree_test11.txt -- Definition lists

my $config = new PurpleWiki::Config($configdir);
my $wikiContent = &readFile('t/txt/tree_test11.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);

# Wiki content.  ( tests)
ok(scalar @{$wiki->root->children} == 1);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 1);

ok($wiki->root->children->[0]->children->[0]->type eq 'dl');

ok($wiki->root->children->[0]->children->[0]->children->[0]->type
    eq 'dt');
ok($wiki->root->children->[0]->children->[0]->children->[0]->content->[0]->
    type eq 'wikiword');
ok($wiki->root->children->[0]->children->[0]->children->[0]->content->[0]->
    content eq 'Collab:HomePage');
ok($wiki->root->children->[0]->children->[0]->children->[1]->type
    eq 'dd');
ok($wiki->root->children->[0]->children->[0]->children->[1]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[1]->content->[0]->
    content eq 'Start here');

ok($wiki->root->children->[0]->children->[0]->children->[2]->type
    eq 'dt');
ok($wiki->root->children->[0]->children->[0]->children->[2]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[2]->content->[0]->
    content eq 'Hello ');
ok($wiki->root->children->[0]->children->[0]->children->[2]->content->[1]->
    type eq 'wikiword');
ok($wiki->root->children->[0]->children->[0]->children->[2]->content->[1]->
    content eq 'Collab:HomePage');
ok($wiki->root->children->[0]->children->[0]->children->[2]->content->[2]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[2]->content->[2]->
    content eq ' there');
ok($wiki->root->children->[0]->children->[0]->children->[3]->type
    eq 'dd');
ok($wiki->root->children->[0]->children->[0]->children->[3]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[3]->content->[0]->
    content eq 'Start here');

ok($wiki->root->children->[0]->children->[0]->children->[4]->type
    eq 'dt');
ok($wiki->root->children->[0]->children->[0]->children->[4]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[4]->content->[0]->
    content eq 'Eekim');
ok($wiki->root->children->[0]->children->[0]->children->[5]->type
    eq 'dd');
ok($wiki->root->children->[0]->children->[0]->children->[5]->content->[0]->
    type eq 'wikiword');
ok($wiki->root->children->[0]->children->[0]->children->[5]->content->[0]->
    content eq 'HomePage');
ok($wiki->root->children->[0]->children->[0]->children->[5]->content->[1]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[5]->content->[1]->
    content eq ':Not');
ok($wiki->root->children->[0]->children->[0]->children->[5]->content->[2]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[5]->content->[2]->
    content eq ' starting here');

ok($wiki->root->children->[0]->children->[0]->children->[6]->type
    eq 'dt');
ok($wiki->root->children->[0]->children->[0]->children->[6]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[6]->content->[0]->
    content eq 'Hello Eekim');
ok($wiki->root->children->[0]->children->[0]->children->[7]->type
    eq 'dd');
ok($wiki->root->children->[0]->children->[0]->children->[7]->content->[0]->
    type eq 'wikiword');
ok($wiki->root->children->[0]->children->[0]->children->[7]->content->[0]->
    content eq 'HomePage');
ok($wiki->root->children->[0]->children->[0]->children->[7]->content->[1]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[7]->content->[1]->
    content eq ' there:Not starting here');

ok($wiki->root->children->[0]->children->[0]->children->[8]->type
    eq 'dt');
ok($wiki->root->children->[0]->children->[0]->children->[8]->content->[0]->
    type eq 'url');
ok($wiki->root->children->[0]->children->[0]->children->[8]->content->[0]->
    content eq 'http://www.blueoxen.org:80/');
ok($wiki->root->children->[0]->children->[0]->children->[8]->content->[0]->
    href eq 'http://www.blueoxen.org:80/');
ok($wiki->root->children->[0]->children->[0]->children->[9]->type
    eq 'dd');
ok($wiki->root->children->[0]->children->[0]->children->[9]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[9]->content->[0]->
    content eq 'Blue Oxen Associates');

ok($wiki->root->children->[0]->children->[0]->children->[10]->type
    eq 'dt');
ok($wiki->root->children->[0]->children->[0]->children->[10]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[10]->content->[0]->
    content eq 'Hello ');
ok($wiki->root->children->[0]->children->[0]->children->[10]->content->[1]->
    type eq 'url');
ok($wiki->root->children->[0]->children->[0]->children->[10]->content->[1]->
    content eq 'http://www.blueoxen.org:80/');
ok($wiki->root->children->[0]->children->[0]->children->[10]->content->[1]->
    href eq 'http://www.blueoxen.org:80/');
ok($wiki->root->children->[0]->children->[0]->children->[10]->content->[2]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[10]->content->[2]->
    content eq ' there');
ok($wiki->root->children->[0]->children->[0]->children->[11]->type
    eq 'dd');
ok($wiki->root->children->[0]->children->[0]->children->[11]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[11]->content->[0]->
    content eq 'Blue Oxen Associates');

ok($wiki->root->children->[0]->children->[0]->children->[12]->type
    eq 'dt');
ok($wiki->root->children->[0]->children->[0]->children->[12]->content->[0]->
    type eq 'link');
ok($wiki->root->children->[0]->children->[0]->children->[12]->content->[0]->
    content eq 'Blue Oxen Associates');
ok($wiki->root->children->[0]->children->[0]->children->[12]->content->[0]->
    href eq 'http://www.blueoxen.org:80/');
ok($wiki->root->children->[0]->children->[0]->children->[13]->type
    eq 'dd');
ok($wiki->root->children->[0]->children->[0]->children->[13]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[13]->content->[0]->
    content eq 'Another link');

ok($wiki->root->children->[0]->children->[0]->children->[14]->type
    eq 'dt');
ok($wiki->root->children->[0]->children->[0]->children->[14]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[14]->content->[0]->
    content eq 'Hello ');
ok($wiki->root->children->[0]->children->[0]->children->[14]->content->[1]->
    type eq 'link');
ok($wiki->root->children->[0]->children->[0]->children->[14]->content->[1]->
    content eq 'Blue Oxen Associates');
ok($wiki->root->children->[0]->children->[0]->children->[14]->content->[1]->
    href eq 'http://www.blueoxen.org:80/');
ok($wiki->root->children->[0]->children->[0]->children->[14]->content->[2]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[14]->content->[2]->
    content eq ' there');
ok($wiki->root->children->[0]->children->[0]->children->[15]->type
    eq 'dd');
ok($wiki->root->children->[0]->children->[0]->children->[15]->content->[0]->
    type eq 'text');
ok($wiki->root->children->[0]->children->[0]->children->[15]->content->[0]->
    content eq 'Another link');
