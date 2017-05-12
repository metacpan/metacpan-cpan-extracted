#!perl

use Test::Most;
use SVN::Core;
use SVN::Repos;
use File::Temp;

use SVN::Tree;

my $repos_dir = File::Temp->newdir();
my $repos     = SVN::Repos::create( "$repos_dir", (undef) x 4 );
my $fs        = $repos->fs;

my $svn_tree = new_ok(
    'SVN::Tree' => [ root => $fs->revision_root( $fs->youngest_rev ) ] );
is( $svn_tree->tree->path->stringify,     '/', 'empty repo tree' );
is( scalar @{ $svn_tree->projects },      0,   'no projects' );
is( scalar keys %{ $svn_tree->branches }, 0,   'no branches' );

my $txn      = $fs->begin_txn( $fs->youngest_rev );
my $txn_root = $txn->root;
for (qw(trunk branches tags)) { $txn_root->make_dir($_) }
my $txn_tree
    = new_ok( 'SVN::Tree' => [ root => $txn_root ], 'transaction tree' );
cmp_bag( [ map { $_->value->stringify } $txn_tree->tree->children ],
    [qw(trunk branches tags)], 'transaction children' );
is_deeply( [ map { $_->value->stringify } @{ $txn_tree->projects } ],
    ['/'], 'root project' );

$txn->commit;
lives_ok( sub { $svn_tree->root( $fs->revision_root( $fs->youngest_rev ) ) },
    'change root' );
cmp_bag( [ map { $_->value->stringify } $svn_tree->tree->children ],
    [qw(trunk branches tags)], 'added root children' );
is_deeply( [ map { $_->value->stringify } @{ $svn_tree->projects } ],
    ['/'], 'added root project' );

done_testing();
