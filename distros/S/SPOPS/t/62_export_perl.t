# -*-perl-*-

# $Id: 62_export_perl.t,v 1.3 2004/02/26 02:02:29 lachoy Exp $

use strict;
use lib qw( t/ );
use Test::More tests => 10;

do "t/config.pl";

my $ALL =
q|$VAR1 = [
          bless( {
                   'myname' => 'foo',
                   'myid' => 1
                 }, 'ExportObjectTest' ),
          bless( {
                   'myname' => 'bar',
                   'myid' => 2
                 }, 'ExportObjectTest' ),
          bless( {
                   'myname' => 'baz',
                   'myid' => 3
                 }, 'ExportObjectTest' )
        ];
|;

my $SOME =
q|$VAR1 = [
          bless( {
                   'myname' => 'bar',
                   'myid' => 2
                 }, 'ExportObjectTest' )
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
                         'perl', { object_class => 'ExportObjectTest' } ) };
    ok( ! $@, "Exporter created" );

    $export_all_data = eval { $exporter->run };
    ok( ! $@, "Export all data (no ID)" );
    my $ALL_STRUCT = eval_struct( $ALL );
    my $export_all_struct = eval_struct( $export_all_data );
    is_deeply( $export_all_struct, $ALL_STRUCT, "Export all data matches (no ID)" );

    $exporter->where( "myname = 'bar'" );
    $export_some_data = eval { $exporter->run };
    ok( ! $@, "Export some data (no ID)" );
    my $SOME_STRUCT = eval_struct( $SOME );
    my $export_some_struct = eval_struct( $export_some_data );
    is_deeply( $export_some_struct, $SOME_STRUCT, "Export some data matches (no ID)" );
}

sub eval_struct {
    my ( $data ) = @_;
    no strict 'vars';
    my $struct = eval $data;
    return $struct;
}
