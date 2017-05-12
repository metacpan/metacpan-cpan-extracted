use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::Fluidinfo;
use Net::Fluidinfo::TestUtils;

use_ok('Net::Fluidinfo::Namespace');

my $fin = Net::Fluidinfo->_new_for_net_fluidinfo_test_suite;

my ($ns, $ns2, $name, $path, $description, $parent, $tag, @namespace_names, @tag_names, @tags);

# fetches the root namespace of the test user
$ns = Net::Fluidinfo::Namespace->get($fin, $fin->username); 
ok $ns;
ok $ns->has_object_id;
ok $ns->object->id eq $ns->object_id;
ok !$ns->parent;
ok $ns->name eq $fin->username;
ok $ns->path eq $fin->username;
ok $ns->path_of_parent eq "";

# creates a child namespace via path
$name = random_name;
$path = $fin->username . "/$name";
$ns2 = Net::Fluidinfo::Namespace->new(fin => $fin, path => $path, description => random_description);
ok $ns2->create;
ok $ns2->has_object_id;
ok $ns2->name eq $name;
ok $ns2->parent;
ok $ns2->parent->name eq $fin->username;
ok $ns2->path_of_parent eq $fin->username;
ok $ns2->delete;

# creates a child namespace via parent namespace
$name = random_name;
$path = $fin->username . "/$name";
$ns2 = Net::Fluidinfo::Namespace->new(fin => $fin, parent => $ns, name => $name, description => random_description);
ok $ns2->create;
ok $ns2->has_object_id;
ok $ns2->name eq $name;
ok $ns2->parent;
ok $ns2->parent->name eq $fin->username;
ok $ns2->path_of_parent eq $fin->username;
ok $ns2->delete;

# creates and updates a child namespace via path
$name = random_name;
$path = $fin->username . "/$name";
$ns = Net::Fluidinfo::Namespace->new(fin => $fin, path => $path, description => random_description);
ok $ns->create;

$description = random_description;
$ns->description($description);
ok $ns->update;

$ns2 = Net::Fluidinfo::Namespace->get($fin, $ns->path, description => 1);
ok $ns2->object_id eq $ns->object_id;
ok $ns2->description eq $ns->description;

ok $ns->delete;

# tests namespace_names
$name = random_name;
$path = $fin->username . "/$name";
$parent = Net::Fluidinfo::Namespace->new(fin => $fin, path => $path, description => random_description);
ok $parent->create;

@namespace_names = (random_name, random_name, random_name);
foreach $name (@namespace_names) {
    $path = $fin->username . "/$name";
    $ns2  = Net::Fluidinfo::Namespace->new(fin => $fin, parent => $parent, name => $name, description => random_description);
    ok $ns2->create;
}

$parent = Net::Fluidinfo::Namespace->get($fin, $parent->path, description => 1, namespace_names => 1);
ok $parent;
ok_sets_cmp $parent->namespace_names, \@namespace_names;

# tests tag_names
@tags = ();
@tag_names = (random_name, random_name, random_name, random_name);
foreach $name (@tag_names) {
    $path = $fin->username . "/$name";
    $tag  = Net::Fluidinfo::Tag->new(fin => $fin, namespace => $parent, name => $name, description => random_description, indexed => 0);
    ok $tag->create;
    push @tags, $tag;
}

$parent = Net::Fluidinfo::Namespace->get($fin, $parent->path, description => 1, namespace_names => 1, tag_names => 1);
ok $parent;
ok_sets_cmp $parent->namespace_names, \@namespace_names;
ok_sets_cmp $parent->tag_names, \@tag_names;

ok $_->delete for @tags;

done_testing;

