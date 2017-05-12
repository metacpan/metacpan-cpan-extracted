#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Data::Dump qw/ddx/;
#use Devel::LeakGuard::Object qw/leakguard/;
use Test::Memory::Cycle;
#use Devel::Cycle;

BEGIN {
    # can we use fake dbic schema?
    use Test::DBIC;

    eval 'require DBD::SQLite';
    if ($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 20;
    }
    use_ok( 'MooseX::Storage::DBIC' );
}

my $schema;

###
# resultset #1
package MXSD::RS1;
use base 'DBIx::Class';
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
use Carp qw/croak cluck carp/;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("rs1");
__PACKAGE__->add_columns(
  "id" => { data_type => "integer" },
);
__PACKAGE__->belongs_to("rs2" => "MXSD::RS2", { rs1id => "id" });

with 'MooseX::Storage::DBIC';
sub schema { $schema }
__PACKAGE__->serializable(qw/ id rs2 foo attr /);

has 'attr' => ( is => 'rw', isa => 'Str', default => 'default' );

# sub BUILD { $main::rs1_count++; warn " + build rs1     \tcount=$main::rs1_count\n" }
# sub DEMOLISH { $main::rs1_count--; warn " - demolish rs1 \tcount=$main::rs1_count\n" }

1;

# resultset #2
package MXSD::RS2;
use base 'DBIx::Class';
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
use Carp qw/croak cluck carp/;
extends 'DBIx::Class::Core';
__PACKAGE__->table("rs2");
__PACKAGE__->add_columns(
  "id" => { data_type => "integer" },
  "rs1id" => { data_type => "integer" },
);
__PACKAGE__->has_many("rs1" => "MXSD::RS1", {});

with 'MooseX::Storage::DBIC';
sub schema { $schema }
__PACKAGE__->serializable(qw/ id rs1id baz bleh attr /);

has 'attr' => ( is => 'rw', isa => 'Str', default => 'default2' );

# sub BUILD { $main::rs2_count++; warn " + build rs2     \tcount=$main::rs2_count\n" }
# sub DEMOLISH { $main::rs2_count--; warn " - demolish rs2 \tcount=$main::rs2_count\n" }

1;


package MXSD::NonResult;
use Moose;

with 'MooseX::Storage::DBIC';
sub schema { $schema }
__PACKAGE__->serializable(qw/ myrow /);
1;

###

package main;

use Scalar::Util qw/blessed/;

my $rs1_count = 0;
my $rs2_count = 0;
run_tests();

sub run_tests {
    $schema = Test::DBIC->init_schema(
        existing_namespace => 'MXSD',
        sqlt_deploy => 1,
        'sample_data' => [
            RS1 => [
                ['id'],
                [1],
                [2],
            ],
            RS2 => [
                ['id', 'rs1id'],
                [3, 1],
                [4, 999],
            ],
        ],
    );

    my @rs1s = $schema->resultset('RS1')->all;
    my @rs2s = $schema->resultset('RS2')->all;
    $rs1_count = 2;
    $rs2_count = 2;

    {
        my $rs1 = shift @rs1s; # first rows
        my $rs2 = shift @rs2s;
        test_serialize_rels($rs1, $rs2);
    }

    # test serializing different set of rows
    {
        my $rs1 = shift @rs1s; # second rows
        my $rs2 = shift @rs2s;

        $rs2->{bleh} = [ 1, { xyz => [ 789, 'a' ] }, 3, 4 ];
        $rs1->{foo} = 42;
        $rs1->attr('moof');
        $rs2->{baz} = $rs1;
        $rs2->{not_serialized} = 123;
        my $packed = $rs2->pack;
        my $unpacked = MXSD::RS2->unpack($packed);
        is($unpacked->{baz} && $unpacked->{baz}->attr, $rs1->attr, "Got serialized rel attr");
        is($unpacked->{not_serialized}, undef, "Skipped non-serialized field");
        is_deeply($unpacked->{bleh}, $rs2->{bleh}, "Deserialized complex fields");
        is($unpacked->{baz} && $unpacked->{baz}->id, $rs1->id, "Deserialized row buried in hashref");
        is($unpacked->{baz}{foo}, $rs1->{foo}, "Deserialized field in row");

        memory_cycle_ok($packed, "Serialized object does not contain circular refs");
        memory_cycle_ok($unpacked, "Deserialized object does not contain circular refs");
        # is($rs1_count, 1, "No leaked DBIC objects");
        # is($rs2_count, 1, "No leaked DBIC objects");   
        # TODO: force default attributes to be set if they aren't lazily-loaded
        #is($unpacked->attr, $rs2->attr, "Got serialized default attr");
    }
    
    @rs1s = ();
    @rs2s = ();
    # is($rs1_count, 0, "No leaked DBIC objects");
    # is($rs2_count, 0, "No leaked DBIC objects");
}

sub test_serialize_rels {
    my ($rs1, $rs2) = @_;

    # test serialization of first rs1 row, which is related to rs2
    $rs1->attr('quux');
    $rs1->{foo} = 456;
    $rs1->rs2->{baz} = { a => [ 1, 2, 3, 4 ] };
    $rs1->rs2->{rs1id} = $rs1->id;

    # serialize
    my $packed = $rs1->pack;

    # do it again to make sure cyclic checking is reset
    $rs1->pack;

    # deserialize (twice for good measure)
    MXSD::RS1->unpack($packed);
    my $unpacked = MXSD::RS1->unpack($packed);
    #find_cycle($unpacked->rs2);

    # got expected results from deserialization?
    is($unpacked->attr, $rs1->attr, "Deserialized attribute");
    is($unpacked->id, $rs1->id, "Deserialized column");
    is($unpacked->rs2->rs1id, $rs2->rs1id, "Deserialized rel column");
    is($unpacked->rs2->id, $rs2->id, "Deserialized rel column");
    is($unpacked->{foo}, 456, "Deserialized field");
    # ddx($unpacked->rs2);
    is_deeply($unpacked->rs2->{baz}, $rs1->rs2->{baz}, "Deserialized rel field");

    memory_cycle_ok($packed, "Serialized object does not contain circular refs");
    memory_cycle_ok($unpacked, "Deserialized object does not contain circular refs");

    # try nesting a row inside a plain ol' hashref
    my $to_pack = MXSD::NonResult->new;
    $to_pack->{myrow} = $rs2;
    $packed = $to_pack->pack;
    $unpacked = MXSD::NonResult->unpack($packed);
    memory_cycle_ok($unpacked, "Deserialized freestanding DBIC row object does not contain circular refs");
    is($unpacked->{myrow}->id, $rs2->id, "Deserialized row inside non-DBIC packed object");

    memory_cycle_ok($packed, "Serialized object does not contain circular refs");
    memory_cycle_ok($unpacked, "Deserialized object does not contain circular refs");
}
