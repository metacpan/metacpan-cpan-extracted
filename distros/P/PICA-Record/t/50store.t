#!perl -Tw

use strict;

use Test::More qw(no_plan);

use PICA::Record;
use PICA::Store;
use IO::File;
use File::Temp qw(tempdir);
use Data::Dumper;

require "./t/teststore.pl";

if ( $ENV{PICASTORE_TEST} ) {
    my $webcat = PICA::Store->new( config => $ENV{PICASTORE_TEST} );
    teststore( $webcat );

    # create and update does not break UTF-8
    my $record = readpicarecord("t/files/minimal.pica");
    $record->remove('003@');
    my $record2 = PICA::Record->new( $record );
    my %result = $webcat->create( $record );
    my $ppn = $result{id};

    use utf8;
    $record->update('028A','d'=>'KÄRL','a'=>'MÖRX');
    %result = $webcat->update( $ppn, $record );
    $result{record}->remove('001.') if $result{record};
    is( $result{record}, $record, "update does not break UTF-8" );

    $record->update('028A','d'=>'X','a'=>'Y');
    $record->ppn( $ppn );
    %result = $webcat->update( $record );
    $result{record}->remove('001.') if $result{record};
    is( $record->ppn, $ppn, "PPN still there" );
    $record->ppn( undef );
    is( $result{record}, $record, "update with PPN in record" );


    %result = $webcat->delete($ppn);
    ok( $result{id}, "deleted $ppn" );

} else {
    diag("Set PICASTORE_TEST to enable additional tests of PICA::Store!");
    ok(1);
}

# create a configuration file and a SQLiteStore
my $dir = tempdir( UNLINK => 1 );
chdir $dir;

my $fh;
open $fh, ">pica.conf";
print $fh "SQLite=tmp.db\n";
close $fh;

my $store = PICA::Store->new( conf => undef );
isa_ok( $store, 'PICA::Store', 'created a new store via config file' );
my %result = $store->create( PICA::Record->new('021A $aShort Title') );
ok ( $result{id}, 'created a record' );


