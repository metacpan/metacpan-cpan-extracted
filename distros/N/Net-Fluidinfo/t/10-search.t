use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use Test::More;
use Net::Fluidinfo;
use Net::Fluidinfo::Object;
use Net::Fluidinfo::Tag;
use Net::Fluidinfo::TestUtils;

my $fin = Net::Fluidinfo->_new_for_net_fluidinfo_test_suite;

my $description = random_description;
my $name = random_name;
my $path = $fin->username . "/$name";

my $tag = Net::Fluidinfo::Tag->new(
    fin         => $fin,
    description => $description,
    indexed     => 1,
    path        => $path
);
ok $tag->create;

my @object_ids = ();
for (my $i = -3; $i <= 3; ++$i){
  my $object = Net::Fluidinfo::Object->new(fin => $fin);
  ok $object->create;
  ok $object->tag($tag, integer => $i);
  push @object_ids, $object->id;
}

my @ids;

tolerate_delay {
    @ids = Net::Fluidinfo::Object->search($fin, "has $path");
    @ids == @object_ids;
};

@ids = Net::Fluidinfo::Object->search($fin, "has $path");
ok_sets_cmp \@ids, \@object_ids;

@ids = Net::Fluidinfo::Object->search($fin, "$path > -3 OR $path < 3");
ok_sets_cmp \@ids, \@object_ids;

@ids = Net::Fluidinfo::Object->search($fin, "$path > 0");
ok_sets_cmp \@ids, [ @object_ids[4 .. $#object_ids] ];

@ids = Net::Fluidinfo::Object->search($fin, "$path = 0");
ok_sets_cmp \@ids, [ $object_ids[3] ];

@ids = Net::Fluidinfo::Object->search($fin, "$path > 3");
ok_sets_cmp \@ids, [];

@ids = Net::Fluidinfo::Object->search($fin, "$path < -3");
ok_sets_cmp \@ids, [];

done_testing;
