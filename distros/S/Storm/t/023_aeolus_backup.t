use Test::More tests => 1;


package Bazzle;
use Storm::Object;
storm_table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'foo' => ( is => 'rw' );
has 'bar' => ( is => 'rw' );
has 'baz' => ( is => 'rw' );

many_to_many 'bizzles' => (
    foreign_class => 'Bizzle',
    junction_table => 'BizzleBazzles',
    local_match => 'bazzle',
    foreign_match => 'bizzle',
    
);

package Bizzle;
use Storm::Object;
storm_table( 'Bizzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'foo' => ( is => 'rw' );
has 'bar' => ( is => 'rw' );
has 'baz' => ( is => 'rw' );

many_to_many 'bazzles' => (
    foreign_class => 'Bazzle',
    junction_table => 'BizzleBazzles',
    local_match => 'bizzle',
    foreign_match => 'bazzle',
);

package Buzzle;
use Storm::Object;
storm_table( 'Buzzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'bizzle' => ( is => 'rw', isa => 'Bizzle' );


package Foo::Model;
use Storm::Model;

register 'Bazzle';
register 'Bizzle';
register 'Buzzle';





## begin package main


package main;
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->start_fresh;
$storm->aeolus->install_model( 'Foo::Model' );


# install test objects
for my $a ( qw/a b c d e/ ) {
    my $o = Bazzle->new( foo => $a . 1, bar => $a . 2, baz => $a . 3 );
    $storm->insert( $o );
}


# start testing
unlink 'backup.cbk' if -e 'backup.cbk';

open my $fh, '>', 'backup.cbk' or die "Could not open file for writing";
flock $fh, 2;
$storm->aeolus->backup_class( 'Bazzle', $fh );
close $fh;

ok -e 'backup.cbk', 'created backup file';

unlink 'backup.cbk';

























