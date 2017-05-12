# -*-perl-*-

# $Id: 70_import_object.t,v 1.2 2004/06/02 00:31:18 lachoy Exp $

use strict;
use lib qw( t/ );
use Test::More tests => 20;

do "t/config.pl";

use_ok( 'SPOPS::Import::Object' );

my $SPOPS_CLASS = 'ImportObjectTest';
my @FIELDS = qw/ mime_type extensions description image_source /;

my %config = (
    test => {
        class    => $SPOPS_CLASS,
        isa      => [ 'SPOPS::Loopback' ],
        field    => \@FIELDS,
        id_field => 'mime_type',
    },
);

require SPOPS::Initialize;
SPOPS::Initialize->process({ config => \%config });

my $content = [
   { spops_class => $SPOPS_CLASS,
     field_order => \@FIELDS, },
   [ 'application/mac-binhex40', 'hqx', 'Macintosh BinHex archive', '/images/icons/binhex.gif' ],
   [ 'application/msword', 'doc', 'Microsoft Word Document', '/images/icons/quill.gif' ],
];

{
    my $importer = SPOPS::Import->new( 'object' );
    is( ref( $importer ), 'SPOPS::Import::Object',
        'Importer returned from factory correct type' );
    eval { $importer->assign_raw_data( $content ) };
    ok( ! $@, 'Assigned raw data ok' ) || diag( "Error: $@" );

    is( $importer->object_class, $SPOPS_CLASS,
        'Pulled object class from assigned data' );
    is_deeply( $importer->fields, \@FIELDS,
               'Pulled field list from assigned data' );
    is_deeply( $importer->data, [ $content->[1], $content->[2] ],
               'Pulled raw records from assigned data' );

    my $status = eval { $importer->run() };
    ok( ! $@, 'Ran run() ok' ) || diag( "Error: $@" );
    is( scalar @{ $status }, 2,
        'Correct number of status entries' );
    ok( $status->[0][0] && $status->[1][0],
        'Both status entries evaluate to true' );
    my $rec_one_ext = $SPOPS_CLASS->peek( 'application/mac-binhex40', 'extensions' );
    is( $rec_one_ext, 'hqx', 'Correct field value for first record' );
    my $rec_two_ext = $SPOPS_CLASS->peek( 'application/msword', 'extensions' );
    is( $rec_two_ext, 'doc', 'Correct field value for second record' );
}

{
    my @copy_content = @{ $content };
    my %copy_meta    = %{ $content->[0] };
    delete $copy_meta{field_order};
    $copy_content[0] = \%copy_meta;
    my $importer = SPOPS::Import->new( 'object' );
    eval { $importer->assign_raw_data( \@copy_content ) };
    ok( ! $@, 'Assigned raw data with no fields ok' ) || diag( "Error: $@" );
    eval { $importer->run() };
    my $error = $@;
    is( ref( $error ), 'SPOPS::Exception',
        'Exception thrown given bad data assigned' );
    is( $error->message, 'Cannot run without fields defined',
        'Correct message in exception' );
}

{
    my @copy_content = @{ $content };
    my %copy_meta    = %{ $content->[0] };
    delete $copy_meta{spops_class};
    $copy_content[0] = \%copy_meta;
    my $importer = SPOPS::Import->new( 'object' );
    eval { $importer->assign_raw_data( \@copy_content ) };
    ok( ! $@, 'Assigned raw data with no spops_class ok' ) || diag( "Error: $@" );
    eval { $importer->run() };
    my $error = $@;
    is( ref( $error ), 'SPOPS::Exception',
        'Exception thrown given bad data assigned' );
    is( $error->message, 'Cannot run without object class defined',
        'Correct message in exception' );
}

{
    my $importer = SPOPS::Import->new( 'object' );
    eval { $importer->assign_raw_data( [ $content->[0] ] ) };
    ok( ! $@, 'Assigned raw data with no data ok' ) || diag( "Error: $@" );
    eval { $importer->run() };
    my $error = $@;
    is( ref( $error ), 'SPOPS::Exception',
        'Exception thrown given bad data assigned' );
    is( $error->message, 'Cannot run without data defined',
        'Correct message in exception' );
}
