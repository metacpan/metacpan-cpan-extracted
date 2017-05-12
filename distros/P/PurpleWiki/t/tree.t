# tree.t

use strict;
use warnings;
use Test;

#BEGIN { plan tests => 28 };
BEGIN { plan tests => 25 };

use PurpleWiki::Tree;

#########################

# Create a tree with no metadata.  (8 tests)

my $tree = PurpleWiki::Tree->new;
ok(ref($tree->root) eq 'PurpleWiki::StructuralNode');
#ok(!defined $tree->lastNid);
ok(!defined $tree->title);
ok(!defined $tree->subtitle);
ok(!defined $tree->id);
ok(!defined $tree->date);
ok(!defined $tree->version);
ok(!defined $tree->authors);

# Test mutators.  (9 tests)

#$tree->lastNid(3);
$tree->title('Wiki Treatise');
$tree->subtitle('To Wiki, Or Not To Wiki');
$tree->id('0235');
$tree->date('December 29, 2002');
$tree->version('1.0');
$tree->authors([ ['Joe Schmoe'], ['Bob Marley', 'bob@marley.net'] ]);

#ok($tree->lastNid == 3);
ok($tree->title eq 'Wiki Treatise');
ok($tree->subtitle eq 'To Wiki, Or Not To Wiki');
ok($tree->id eq '0235');
ok($tree->date eq 'December 29, 2002');
ok($tree->version eq '1.0');
ok($tree->authors->[0]->[0] eq 'Joe Schmoe');
ok($tree->authors->[1]->[0] eq 'Bob Marley');
ok($tree->authors->[1]->[1] eq 'bob@marley.net');

# Try to give authors bad data.  (3 tests)

$tree->authors('Eugene Eric Kim');
ok($tree->authors->[0]->[0] eq 'Joe Schmoe');
ok($tree->authors->[1]->[0] eq 'Bob Marley');
ok($tree->authors->[1]->[1] eq 'bob@marley.net');

# Create a new tree with default metadata.  (8 tests)

$tree = PurpleWiki::Tree->new(
    lastNid => 52,
    title   => 'HeadlineNews',
    date    => 'December 29, 2002',
    authors => [ ['Chris Dent', 'cdent@blueoxen.org'] ] );

#ok($tree->lastNid == 52);
ok($tree->title eq 'HeadlineNews');
ok(!defined $tree->subtitle);
ok(!defined $tree->id);
ok($tree->date eq 'December 29, 2002');
ok(!defined $tree->version);
ok($tree->authors->[0]->[0] eq 'Chris Dent');
ok($tree->authors->[0]->[1] eq 'cdent@blueoxen.org');
