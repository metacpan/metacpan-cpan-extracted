use strict;
use warnings;
use Test::More;
use SNMP::Extension::PassPersist;


plan tests => 1;

my $ext = SNMP::Extension::PassPersist->new;
eval { $ext->add_oid_tree({ 0 => [ 'counter', 1 ]}) };
is( $@, "", "add_oid_tree()" );

