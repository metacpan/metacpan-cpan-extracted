#!env perl

use v5.10;
use strict;
use warnings;

use File::Basename;
use File::Spec::Functions;
use Parse::USDA::NNDB;
use ORLite qw//;
use Log::Any::Adapter;

my $dir;
my $db_file;
my $usda = Parse::USDA::NNDB->new;

sub create_tables {
    my $sql_file = catfile( $dir, 'usda_sqlite.sql' );

    open my $fh, '<', $sql_file
      or die "Failed to open SQL file: $!";

    system "sqlite3 $db_file < $sql_file";
    if ( $? != 0 ) {
        die "system failed: $?";
    }

    return 1;
}

sub get_keys {
    my ( $table ) = @_;
    my $cols = $usda->get_columns_for( $table );
    if ( !defined $cols ) {
        die;
    }
    return $cols;
}

sub normalise_keys {
    my $item = shift;
    my %data = map { lc( $_ ) => $item->{$_} } keys %{$item};
    return \%data;
}

# from orlite
sub normalise_table_name {
    my $table = shift;
    if ( $table ne lc $table ) {
        $table =~ s/([a-z])([A-Z])/${1}_${2}/g;
        $table =~ s/_+/_/g;
    }
    $table = ucfirst lc $table;
    $table =~ s/_([a-z])/uc($1)/ge;

    return "NutDB::$table";
}

sub do_table {
    my $table = shift;

    say "### $table ###";

    $usda->open_file( $table );

    my $pkg = normalise_table_name( $table );

    NutDB->begin;
    while ( my $rd = $usda->get_line ) {
        my $data = normalise_keys( $rd );
        if ( $pkg->can( 'create' ) ) {
            my $n = $pkg->create( %{$data} );
        } else {
            die "$pkg has no create method - DID YOU MAKE ANOTHER TYPO!?";
        }
    }
    NutDB->commit;

    print "\n\n";
}

Log::Any::Adapter->set( 'ScreenColoredLevel', min_level => 'debug', );

$dir = dirname( $0 );
$db_file = catfile( $dir, 'usda_nut.sqlite' );

my $db = ORLite->import( {
        package => 'NutDB',
        file    => $db_file,
        create  => \&create_tables,
} );

my @tables = $usda->tables;

foreach my $table ( @tables ) {
    do_table( $table );
}
