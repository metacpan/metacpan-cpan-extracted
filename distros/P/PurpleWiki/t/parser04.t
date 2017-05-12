# parser04.t

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

### tree_test08.txt -- Document metadata.

my $config = new PurpleWiki::Config($configdir);
my $wikiContent = &readFile('t/txt/tree_test08.txt');
my $wikiParser = PurpleWiki::Parser::WikiText->new;
my $wiki = $wikiParser->parse($wikiContent);

# Metadata.  (8 tests)
ok($wiki->title eq 'Treatise on World Peace');
ok($wiki->subtitle eq 'The Solution');
ok($wiki->id eq 'boa-12345');
ok($wiki->date eq 'February 27, 2002');
ok($wiki->version eq '1.0');
ok($wiki->authors->[0]->[0] eq 'Joe Schmoe');
ok($wiki->authors->[0]->[1] eq 'joe@schmoe.net');
ok($wiki->authors->[1]->[0] eq 'Bob Marley');

# Wiki content.  (9 tests)
ok(scalar @{$wiki->root->children} == 1);
ok($wiki->root->children->[0]->type eq 'section');
ok(scalar @{$wiki->root->children->[0]->children} == 2);
ok($wiki->root->children->[0]->children->[0]->type eq 'h');
ok($wiki->root->children->[0]->children->[0]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[0]->content->[0]->content
    eq 'Introduction');

ok($wiki->root->children->[0]->children->[1]->type eq 'p');
ok($wiki->root->children->[0]->children->[1]->content->[0]->type
    eq 'text');
ok($wiki->root->children->[0]->children->[1]->content->[0]->content
   eq 'This is the introduction to our treatise on world peace.');
