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

my ($object, $description, $name, $path, $tag, $type, $value);

## creates an object with about
$object = Net::Fluidinfo::Object->new(fin => $fin, about => random_about);
ok $object->create;

$description = random_description;
$name = random_name;
$path = $fin->username . "/$name";

## create a tag
$tag = Net::Fluidinfo::Tag->new(
    fin         => $fin,
    description => $description,
    indexed     => 1,
    path        => $path
);
ok $tag->create;

ok $object->tag($tag);
ok $object->is_tag_path_present($tag->path);
$value = $object->value($tag);
ok !defined $value;
($type, $value) = $object->value($tag);
ok $type eq 'null';
ok !defined $value;

ok $object->tag($tag, undef);
ok $object->is_tag_path_present($tag->path);
$value = $object->value($tag);
ok !defined $value;
($type, $value) = $object->value($tag);
ok $type eq 'null';
ok !defined $value;

ok $object->tag($tag, boolean => 1);
$value = $object->value($tag);
ok $value;
($type, $value) = $object->value($tag);
ok $type eq 'boolean';
ok $value;

ok $object->tag($tag, boolean => "this is true in boolean context");
$value = $object->value($tag);
ok $value;
($type, $value) = $object->value($tag);
ok $type eq 'boolean';
ok $value;

ok $object->tag($tag, boolean => 0);
$value = $object->value($tag);
ok !$value;
($type, $value) = $object->value($tag);
ok $type eq 'boolean';
ok !$value;

ok $object->tag($tag, boolean => 0.0);
$value = $object->value($tag);
ok !$value;
($type, $value) = $object->value($tag);
ok $type eq 'boolean';
ok !$value;

ok $object->tag($tag, boolean => undef);
$value = $object->value($tag);
ok !$value;
($type, $value) = $object->value($tag);
ok $type eq 'boolean';
ok !$value;

ok $object->tag($tag, boolean => "");
$value = $object->value($tag);
ok !$value;
($type, $value) = $object->value($tag);
ok $type eq 'boolean';
ok !$value;

ok $object->tag($tag, boolean => "0");
$value = $object->value($tag);
ok !$value;
($type, $value) = $object->value($tag);
ok $type eq 'boolean';
ok !$value;

ok $object->tag($tag, integer => 0);
$value = $object->value($tag);
ok $value == 0;
($type, $value) = $object->value($tag);
ok $type eq 'integer';
ok $value == 0;

ok $object->tag($tag, integer => 7);
$value = $object->value($tag);
ok $value == 7;
($type, $value) = $object->value($tag);
ok $type eq 'integer';
ok $value == 7;

ok $object->tag($tag, integer => -1);
$value = $object->value($tag);
ok $value == -1;
($type, $value) = $object->value($tag);
ok $type eq 'integer';
ok $value == -1;

ok $object->tag($tag, integer => "35foo");
$value = $object->value($tag);
ok $value == 35;
($type, $value) = $object->value($tag);
ok $type eq 'integer';
ok $value == 35;

ok $object->tag($tag, integer => "foo");
$value = $object->value($tag);
ok $value == 0;
($type, $value) = $object->value($tag);
ok $type eq 'integer';
ok $value == 0;

ok $object->tag($tag, integer => -3.14);
$value = $object->value($tag);
ok $value == -3;
($type, $value) = $object->value($tag);
ok $type eq 'integer';
ok $value == -3;

ok $object->tag($tag, float => 0);
$value = $object->value($tag);
ok $value == 0;
($type, $value) = $object->value($tag);
ok $type eq 'float';
ok $value == 0;

ok $object->tag($tag, float => 0.5);
$value = $object->value($tag);
ok $value == 0.5;
($type, $value) = $object->value($tag);
ok $type eq 'float';
ok $value == 0.5;

ok $object->tag($tag, float => -0.5);
$value = $object->value($tag);
ok $value == -0.5;
($type, $value) = $object->value($tag);
ok $type eq 'float';
ok $value == -0.5;

ok $object->tag($tag, float => 1e9);
$value = $object->value($tag);
ok $value == 1e9;
($type, $value) = $object->value($tag);
ok $type eq 'float';
ok $value == 1e9;

ok $object->tag($tag, float => "");
$value = $object->value($tag);
ok $value == 0;
($type, $value) = $object->value($tag);
ok $type eq 'float';
ok $value == 0;

ok $object->tag($tag, float => '-2.5');
$value = $object->value($tag);
ok $value == -2.5;
($type, $value) = $object->value($tag);
ok $type eq 'float';
ok $value == -2.5;

ok $object->tag($tag, string => "this is a string");
$value = $object->value($tag);
ok $value eq "this is a string";
($type, $value) = $object->value($tag);
ok $type eq 'string';
ok $value eq "this is a string";

ok $object->tag($tag, string => "newlines \n\n\n newlines");
$value = $object->value($tag);
ok $value eq "newlines \n\n\n newlines";
($type, $value) = $object->value($tag);
ok $type eq 'string';
ok $value eq "newlines \n\n\n newlines";

ok $object->tag($tag, string => "");
$value = $object->value($tag);
ok $value eq "";
($type, $value) = $object->value($tag);
ok $type eq 'string';
ok $value eq "";

ok $object->tag($tag, string => undef);
$value = $object->value($tag);
ok $value eq "";
($type, $value) = $object->value($tag);
ok $type eq 'string';
ok $value eq "";

ok $object->tag($tag, string => 97);
$value = $object->value($tag);
ok $value eq "97";
($type, $value) = $object->value($tag);
ok $type eq 'string';
ok $value eq "97";

ok $object->tag($tag, string => -2.7183);
$value = $object->value($tag);
ok $value eq "-2.7183";
($type, $value) = $object->value($tag);
ok $type eq 'string';
ok $value eq "-2.7183";

ok $object->tag($tag, []);
$value = $object->value($tag);
ok_sets_cmp $value, [];
($type, $value) = $object->value($tag);
ok $type eq 'list_of_strings';
ok_sets_cmp $value, [];

ok $object->tag($tag, ['foo', 'bar']);
$value = $object->value($tag);
ok_sets_cmp $value, ['foo', 'bar'];
($type, $value) = $object->value($tag);
ok $type eq 'list_of_strings';
ok_sets_cmp $value, ['foo', 'bar'];

ok $object->tag($tag, list_of_strings => [0, 1]);
$value = $object->value($tag);
ok_sets_cmp $value, [0, 1];
($type, $value) = $object->value($tag);
ok $type eq 'list_of_strings';
ok_sets_cmp $value, [0, 1];

ok $object->tag($tag, 'text/plain' => 'this is plain text');
$value = $object->value($tag);
ok $value eq 'this is plain text';
($type, $value) = $object->value($tag);
ok $type eq 'text/plain';
ok $value eq 'this is plain text';

ok $object->tag($tag, 'application/json' => '{}');
$value = $object->value($tag);
ok $value eq '{}';
($type, $value) = $object->value($tag);
ok $type eq 'application/json';
ok $value eq '{}';

ok_dies { $object->tag($tag, 0) };
ok_dies { $object->tag($tag, 7) };
ok_dies { $object->tag($tag, 3.2) };
ok_dies { $object->tag($tag, "foo bar") };

# tests delegation in HasObject
foreach my $res ($fin->user, $tag->namespace, $tag) {
    ok $res->tag($tag, integer => 0);
    ok $res->object->value($tag) == 0;
    ok $res->value($tag) == 0;
}

# has_tag
ok(Net::Fluidinfo::Object->has_tag($fin, $object->id, $tag));

# untag
$path = $tag->path;
my $n = @{$object->tag_paths};
ok $object->untag($tag);
ok @{$object->tag_paths} == $n - 1;
ok !$object->is_tag_path_present($path);

$object = Net::Fluidinfo::Object->get_by_id($fin, $object->id);
ok !$object->is_tag_path_present($path);

# has_tag
ok(!Net::Fluidinfo::Object->has_tag($fin, $object->id, $tag));

ok $tag->delete;

done_testing;
