# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SVN-Dumpfilter.t'

#########################

use 5.008;
use Test::More tests => 60;
use strict;
use warnings;

use SVN::Dumpfile;
ok( 1, 'Module loading' );    # If we made it this far, we're ok.

#use Data::Dumper;
#open( LOG, ">/home/martin/log.txt" );

my $df;

$df = eval { new SVN::Dumpfile };
ok( defined $df, 'new() returns value' );
isa_ok( $df, 'SVN::Dumpfile', 'new() returns correct class' );
ok( defined $df->new(), '$object->new() returns value' );
isa_ok( $df->new(), 'SVN::Dumpfile', '$object->new() returns correct class' );

is( $df->read_node(), undef, " read_node() without defined fh" );
is( $df->write_node(), undef, " write_node() without defined node" );

# Call dump for coverage only
ok( eval { local *STDERR = *STDOUT; $df->dump } );

$df = eval { new SVN::Dumpfile('filename') };
ok( defined $df, 'new("filename") returns value' );
is( $df->{'file'}, 'filename',
    q"new('filename') sets hash key 'file' to 'filename')" );

$df = eval { new SVN::Dumpfile( file => 'filename' ) };
ok( defined $df, 'new(file => "filename") returns value' );
is( $df->{'file'}, 'filename',
    q"new( file => 'filename') sets hash key 'file' to 'filename'" );

$df = eval { new SVN::Dumpfile( { file => 'filename' } ) };
ok( defined $df, 'new( { file => "filename" } ) returns value' );
is( $df->{'file'}, 'filename',
    q"new( { file => 'filename' } ) sets hash key 'file' to 'filename'" );

$df = eval { new SVN::Dumpfile( [ file => 'filename' ] ) };
ok( defined $df, 'new( [ file => "filename" ] ) returns value' );
is( $df->{'file'}, 'filename',
    q"new( [ file => 'filename' ] ) sets hash key 'file' to 'filename'" );

my $scalar;
$df = eval { local $SIG{__WARN__} = sub {}; new SVN::Dumpfile( \$scalar ) };
is( $df, undef, 'eval { new(<other ref>) } returns undef.' );


$df = eval { new SVN::Dumpfile( file => "test", 'wrong' ) };
is( $df, undef, 'eval { new(<odd number of arguments>/ } returns undef.' );
like(
    $@,
    qr/^Final number of arguments not even/,
    'new(<odd number of arguments>) croaks with correct error'
);

$df = eval { new SVN::Dumpfile( version => 3, UUID => 'ABC' ) };
ok( defined $df, 'new( { version => 3, UUID => \'ABC\' } ) returns value' );
is( $df->{'SVN-fs-dump-format-version'}, 3,     '  and sets version to 3' );
is( $df->version,                        3,     '  version() works' );
is( $df->{'UUID'},                       'ABC', '  and sets UUID to \'ABC\'' );
is( $df->uuid,                           'ABC', 'uuid() works' );

is( $df->version(2),                     2, 'version(number) works' );
is( $df->{'SVN-fs-dump-format-version'}, 2, '  ^^^ dito' );
is( ( $df->version = 1 ), 1, 'version() = number works' );
is( $df->{'SVN-fs-dump-format-version'}, 1, '  ^^^ dito' );

is( $df->uuid('XYZ'), 'XYZ', 'uuid(\'new_UUID\') works' );
is( $df->{'UUID'},    'XYZ', '  ^^^ dito' );
is( $df->uuid = 'ERT', 'ERT', 'uuid = \'new_UUID\' works' );
is( $df->{'UUID'}, 'ERT', '  ^^^ dito' );

ok( $df->version_supported,      'version_supported() works' );
ok( $df->version_supported(1),   'version_supported(1) works' );
ok( $df->version_supported(2),   'version_supported(2) works' );
ok( $df->version_supported(3),   'version_supported(3) works' );
ok( !$df->version_supported(4),  'version_supported(4) works' );
ok( !$df->version_supported(-1), 'version_supported(-1) works' );
ok( !$df->version_supported(0),  'version_supported(0) works' );

my $class = 'SVN::Dumpfile';
ok( !$class->version_supported,     '$class->version_supported() works' );
ok( $class->version_supported(1),   '$class->version_supported(1) works' );
ok( $class->version_supported(2),   '$class->version_supported(2) works' );
ok( $class->version_supported(3),   '$class->version_supported(3) works' );
ok( !$class->version_supported(4),  '$class->version_supported(4) works' );
ok( !$class->version_supported(-1), '$class->version_supported(-1) works' );
ok( !$class->version_supported(0),  '$class->version_supported(0) works' );

my $df2 = new SVN::Dumpfile;
is( eval { local $SIG{__WARN__} = sub {}; $df2->create( \sub { } ) }, undef, "create() returns undef if called with wrong argument" );
is( eval { $df2->create( ) }, undef, "create() returns undef if called without fh and filename" );


$df = eval { new SVN::Dumpfile( version => 3, UUID => 'ABC' ) };
$df2 = $df->copy;
ok( $df2, '$df->copy returns value' );
isa_ok( $df2, 'SVN::Dumpfile', '  with correct class' );
is_deeply( $df, $df2, '  and is correct copy' );


my $outfh;
my $output;

open( $outfh, '>', \$output );
$df2 = $df2->create($outfh);
ok( $df2, '$obj->create(\*HANDLE) returns value' );
isa_ok( $df2, 'SVN::Dumpfile', '  with correct class' );
close($outfh);
like(
    $output,
    qr/\ASVN-fs-dump-format-version: 3\012\012UUID: ABC\012\012\Z/m,
    'Output to file is correct.'
);

open( $outfh, '>', \$output );
$df = SVN::Dumpfile->create($outfh);
ok( $df, '$class->create(\*HANDLE) returns value' );
isa_ok( $df, 'SVN::Dumpfile', '  with correct class' );
close($outfh);
like(
    $output,
    qr/\ASVN-fs-dump-format-version: 2\012\012UUID: ([^\012]+)\012\012\Z/m,
    'Output to file is correct.'
);


open( $outfh, '>', \$output );
$df = SVN::Dumpfile->new(version => 1)->create($outfh);
ok( $df, '$class->create(\*HANDLE) returns value' );
isa_ok( $df, 'SVN::Dumpfile', '  with correct class' );
close($outfh);
like(
    $output,
    qr/\ASVN-fs-dump-format-version: 1\012\012/,
    'Output to file is correct.'
);

1;
