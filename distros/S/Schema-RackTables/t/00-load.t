#!perl -wT
use strict;
use warnings;
use Test::More;


plan tests => 5;

my $module = "Schema::RackTables";
my @class_methods   = qw< new list_versions >;
my @object_methods  = qw< version schema schema_version >;

use_ok $module;
can_ok $module, @class_methods;

my $object = eval { $module->new };
is $@, "", "\$object = $module->new";
isa_ok $object, $module, '$object';
can_ok $object, @class_methods;

