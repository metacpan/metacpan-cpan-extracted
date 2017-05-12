#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 39;
our $output;


use Scalar::Util qw(reftype blessed);
use Digest::MD5 qw(md5_hex);
use Data::Dumper;  # diags only


# setup the test
my ($xd, $svk) = build_test();
$svk->mkdir('-m' => 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
my ($copath, $corpath) = get_copath ('root');
$svk->checkout ('//', $copath);


# get a handle on it
my $depot = $xd->find_depot('');
my $repos = $depot->repos;
my $path = SVK::Path->real_new({ depot => $depot,
				 path => "/trunk",
				 revision => $repos->fs->youngest_rev });

# fetch the bit we want to test
my $root = $path->root;


# revision basics - committed revisions
ok($root->is_revision_root, "we're a revision root");
ok(!$root->is_txn_root, "we're not a transaction root");
my $youngest_rev = $root->revision_root_revision;
ok($youngest_rev, "we have a revision ($youngest_rev)");


# revision basics - file/dir lookup
ok($root->check_path("/trunk"), "/trunk checks out OK");
ok($root->is_dir("/trunk"), "//trunk is a directory");
ok(!$root->is_file("/trunk"), "/trunk is not a file");
ok($root->check_path("/trunk/me"), "/trunk/me exists");
ok(!$root->is_dir("/trunk/me"), "//trunk is not a directory");
ok($root->is_file("/trunk/me"), "/trunk is a file");


ok(!$root->check_path("/trunk/junk"), "/trunk/junk doesn't exist");


# reading directories
my $dir_entries = $root->dir_entries("/trunk");
is(reftype $dir_entries, "HASH", "dir_entries is a hash");
is(keys %$dir_entries, 5, "5 files in /trunk");
my $me = $dir_entries->{me};
is($me->name, "me", "meesa me");
is($me->kind, $SVN::Node::file, "meesa file");
my $A = $dir_entries->{A};
is($A->name, "A", "found A, correct name");
is($A->kind, $SVN::Node::dir, "A is a directory");


# reading files
my $eol = $SVK::Util::EOL;
my $expected = "first line in me${eol}2nd line in me - mod${eol}";
is($root->file_length("/trunk/me"), length($expected),
   "meesa right length");
is($root->file_md5_checksum("/trunk/me"),
   md5_hex($expected), "->file_md5_checksum");



# IO::Handle interface
my $contents = $root->file_contents("/trunk/me");
isa_ok($contents, "IO::Handle", "contents are IO::Handle objects");

{
local $/;
my $buffer = <$contents>;
is($buffer, $expected, "can get files out OK");

}
#show_tree($root, "/");


# file and directory properties
is_deeply($root->node_proplist("/trunk/me"), {}, "meesa no properties");
is_deeply($root->node_proplist("/trunk/A/be"),
  { 'svn:keywords' => 'Rev URL Revision FileRev' },
  "A/be (file) has props");
is($root->node_prop("/trunk/A/be", 'svn:keywords'),
   "Rev URL Revision FileRev",
   "we can fetch a prop");
my $pl = $root->node_proplist("/trunk/A/Q");
is_deeply($pl, { 'foo' => 'prop on A/Q' }, "A/Q (dir) has props");


# history-related commands; check behaviour of node_created_rev
is($root->node_created_rev("/trunk/B/S"), $youngest_rev,
   "node_created_rev(changed node)");
is($root->node_created_rev("/trunk/B"), $youngest_rev,
   "node_created_rev(parent of changed node)");
is($root->node_created_rev("/"), $youngest_rev,
   "node_created_rev(root node)");


# this node was not changed in this revision; it was made by the
# previous one.
my $trunk_C_R_rev = $root->node_created_rev("/trunk/C/R");
isnt($trunk_C_R_rev, $youngest_rev, "node_created_rev(unchanged node)");


# we don't check that the revision ids are integers, but we should
# still be able to compare them if one is a predecessor or successor
# of the other.
cmp_ok($trunk_C_R_rev, "<", $youngest_rev, "revisions have order");


# hmm will locale ruin our day with this sort()?
is_deeply([ sort keys %{ $root->paths_changed } ],
  [qw[ /trunk/A/P /trunk/B/S /trunk/B/fe
      /trunk/D /trunk/D/de /trunk/me ]],
  "paths_changed");


# svn's history->prev returns useless intermediate locations, so
# suppress duplicates in this test so we don't have to emulate this
# model-specific behaviour
my $history = $root->node_history("/trunk/B/S");
my @history;
do {
    my @location = $history->location;
    if ( !@history or
scalar(grep { $history[$#history][$_] ne $location[$_] }
(0,1)) ) {
push @history, \@location;
    }
} while ( $history = $history->prev(1) );


is_deeply(\@history,
  [ [ '/trunk/B/S', $youngest_rev, ],
    [ '/trunk/A',   $trunk_C_R_rev ],
  ],
  "we can fetch node history");


# for git we will probably need to store and parse special
# copied-from: fields in the commit message.
my @copied_from = $root->copied_from("/trunk/B/S");
is_deeply(\@copied_from,
  # odd, in the other order to the above...
  [ $trunk_C_R_rev, '/trunk/A' ],
  "->copied_from");


# revision properties.
my $rp = $root->fs->revision_proplist($youngest_rev);
is($rp->{'svn:log'}, "test init tree", "revprop - log");
is($rp->{'svn:author'}, "svk", "revprop - author");
like($rp->{"svn:date"}, qr/\d+-\d+-\d+T\d+:\d+:\d+\.\d+Z/,
     'revprop - date (in UTC)');


# changing revision properties ... do we need to?  I hope not...


# editing commands.


# first we make a memory allocation pool.  other back-ends can
# probably ignore this, or it can be factored into a common interface
# later.
my $pool = SVN::Pool->new;


# info_on($root->fs, "root->fs");


# first, get a 'transaction'
my $txn = $root->txn_root;

ok(!$txn->is_revision_root, "->txn_root is not a revision root");
ok($txn->is_txn_root, "->txn_root is a transaction root");


# show_tree($txn, "/");


$txn->delete("/trunk/A/Q");
ok(!$txn->check_path("/trunk/A/Q"),
   "deletes to open txn are effective");


#info_on($repos, "repository");
# info_on($txn->fs, "fs");
#info_on($_txn, "txn");
#system("find /tmp/svk* | sed 's/^/# /'");
$repos->fs_commit_txn($txn->txn); $txn->txn(undef);
#$txn->close_root;
#$_txn->commit;
#$txn->commit;
#$txn->txn_commit;


isnt($repos->fs->youngest_rev, $youngest_rev, "made a new revision");
# nope, this doesn't happen...
# ok($txn->is_revision_root, "TXN object got assigned a revision number");


# is there a shortcut to this?
#$root = SVK::Path->real_new({ depot => $depot,
#      path => "/trunk",
#      revision => $repos->fs->youngest_rev
#    })->root;


# the following SVK::Root methods (via ::_p_svn_fs_root_t) still need
# testing.


#   copy( from_root, from_path, to_root, to_path )
#   revision_link (from, to)
#   make_dir
#   make_file
#   change_node_prop


# what do these use?  SVN::Editor-style events or a
# Parse::SVNDiff-type stream?  or something else?
#   apply_textdelta
#   apply_text


# we didn't test this history function above, because there were no
# objects which had a copy then a change.


#  closest_copy


# ignored (in %_p_svn_fs_root_t::):
#   close_root
#   methods


# other objects we might need to emulate;
#  FS (_p_svn_fs_t):


#   begin_txn           - might be only one per-checkout
#   open_txn
#   list_transactions


#   revision_root       - should be easy enough...
#   youngest_rev


#   revision_proplist   - probably shove these in the commit message
#   revision_prop
#   change_rev_prop     - do we desperately need this?


#   get_uuid            - not needed for content-hashed repos...
#   set_uuid


#   get_lock            - not sure what to test here...
#   get_locks
#   generate_lock_token
#   lock
#   unlock


#   get_access          - only for remote repos...
#   set_access




sub show_tree {
    my $root = shift;
    my $start = shift;


    my @seen = ($start);


    while ( my $path = pop @seen ) {
my $pl = $root->node_proplist($path);
my $crev = $root->node_created_rev($path);
my $p = " ";
if ( keys %$pl ) {
    $p = "+";
}
if ( $root->is_dir( $path ) ) {
    diag "$crev d $p $path";
    push @seen, map { $path eq "/" ? "/$_" : "$path/$_" }
reverse sort keys %{ $root->dir_entries($path) };
}
else {
    diag "$crev f $p $path";
}
    }
}


sub show_isa {
    my $class = ref $_[0] || $_[0];
    require Class::ISA;

    diag "$class ISA : ".join(" ", Class::ISA::super_path($class));
}


sub info_on {
    no strict;


    my $what = shift;
    my $name = shift || "thingy";
    if ( ref($what) ) {
diag("$name is: ".Dumper($what));
if ( blessed($what) ) {
    diag "methods in ".ref($what).":";
    diag "  $_" for sort keys(%{ref($what)."::"});
#    show_isa($what);
}
    }
    else {
diag("$name is: ".Dumper($what));
    }
}
