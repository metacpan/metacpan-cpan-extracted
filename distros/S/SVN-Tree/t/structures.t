#!perl

use Test::Most;
use SVN::Core;
use SVN::Repos;
use File::Temp;

use SVN::Tree;

my $repos_dir = File::Temp->newdir();
my $repos     = SVN::Repos::create( "$repos_dir", (undef) x 4 );
my $fs        = $repos->fs;
my $svn_tree
    = SVN::Tree->new( root => $fs->revision_root( $fs->youngest_rev ) );

my $txn      = $fs->begin_txn( $fs->youngest_rev );
my $txn_root = $txn->root;
for my $project ( map {"proj$_"} ( 1 .. 3 ) ) {
    $txn_root->make_dir($project);
    for (qw(trunk branches tags)) { $txn_root->make_dir("$project/$_") }
}

$txn_root->make_dir('proj1/branches/bugfix');
$txn_root->make_file('proj1/branches/bugfix/hello.txt');
$txn->commit;

$svn_tree->root( $fs->revision_root( $fs->youngest_rev ) );
cmp_bag( [ map { $_->value->stringify } @{ $svn_tree->projects } ],
    [qw(proj1 proj2 proj3)], 'projects' );
cmp_bag(
    [ keys %{ $svn_tree->branches } ],
    [ map { $_->value->stringify } @{ $svn_tree->projects } ],
    'branches keys match project values',
);

cmp_bag(
    [   map     { $_->path->stringify }
            map { @{ $svn_tree->branches->{$_} } }
            keys %{ $svn_tree->branches },
    ],
    [ 'proj1/branches/bugfix', map {"proj$_/trunk"} ( 1 .. 3 ) ],
    'branch paths',
);

done_testing();
