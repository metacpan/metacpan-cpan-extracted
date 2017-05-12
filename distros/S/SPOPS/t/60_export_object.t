# -*-perl-*-

# $Id: 60_export_object.t,v 1.2 2004/02/26 02:02:29 lachoy Exp $

use strict;
use lib qw( t/ );
use Test::More tests => 15;

do "t/config.pl";

my $ALL =
q|$item = [
  { spops_class => 'ExportObjectTest',
    field_order => [ qw/ myname / ] },
  [q{foo}],
  [q{bar}],
  [q{baz}],
];
|;

my $SOME =
q|$item = [
  { spops_class => 'ExportObjectTest',
    field_order => [ qw/ myname / ] },
  [q{bar}],
];
|;

my $ALL_ID =
q|$item = [
  { spops_class => 'ExportObjectTest',
    field_order => [ qw/ myid myname / ] },
  [q{1}, q{foo}],
  [q{2}, q{bar}],
  [q{3}, q{baz}],
];
|;

my $SOME_ID =
q|$item = [
  { spops_class => 'ExportObjectTest',
    field_order => [ qw/ myid myname / ] },
  [q{2}, q{bar}],
];
|;

{
    my %config = (
      test => {
         class               => 'ExportObjectTest',
         isa                 => [ 'SPOPS::Loopback' ],
         field               => [ qw( myid myname ) ],
         id_field            => 'myid',
      },
    );

    # Create our test class using the loopback

    require_ok( 'SPOPS::Initialize' );

    my $class_init_list = eval { SPOPS::Initialize->process({
                                             config => \%config }) };
    ok( ! $@, "Initialize process run $@" );
    is( $class_init_list->[0], 'ExportObjectTest', 'Object class initialized' );

    eval {
        ExportObjectTest->new({ myid => 1, myname => 'foo' })->save();
        ExportObjectTest->new({ myid => 2, myname => 'bar' })->save();
        ExportObjectTest->new({ myid => 3, myname => 'baz' })->save();
    };
    diag( "Error creating loopback objects: $@" ) if ( $@ );
    ok( ! $@, "Objects to export created" );

    require_ok( 'SPOPS::Export' );

    my ( $exporter, $export_all_data, $export_some_data );
    eval { $exporter = SPOPS::Export->new(
                         'object', { object_class => 'ExportObjectTest' } ) };
    ok( ! $@, "Exporter created" );

    $export_all_data  = eval { $exporter->run };
    ok( ! $@, "Export all data (no ID)" );
    is( $export_all_data, $ALL, "Export all data matches (no ID)" );

    $exporter->where( "myname = 'bar'" );
    $export_some_data = eval { $exporter->run };
    ok( ! $@, "Export some data (no ID)" );
    is( $export_some_data, $SOME, "Export some data matches (no ID)" );

    my ( $exporter_id, $export_all_id_data, $export_some_id_data );
    eval { $exporter_id = SPOPS::Export->new(
                              'object', { object_class => 'ExportObjectTest',
                                          include_id   => 1 } ) };
    ok( ! $@, "Exporter including ID created" );

    $export_all_id_data = eval { $exporter_id->run };
    ok( ! $@, "Export all data (with ID)" );
    is( $export_all_id_data, $ALL_ID, "Export all data matches (with ID)" );

    $exporter_id->where( "myname = 'bar'" );
    $export_some_id_data = eval { $exporter_id->run };
    ok( ! $@, "Export some data (with ID)" );
    is( $export_some_id_data, $SOME_ID, "Export some data matches (with ID)" );
}

