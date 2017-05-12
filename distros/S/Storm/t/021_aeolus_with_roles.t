use Test::More 'no_plan';

package Foo::Role;
use Storm::Role;

has 'foo' => (
    is => 'rw',
    isa => 'Str',
);



package Bazzle;
use Storm::Object;
storm_table( 'Bazzle' );

with 'Foo::Role';

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'bar' => ( is => 'rw' );



package main;
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->start_fresh;
$storm->aeolus->install_class_table( 'Bazzle' );

my %tables = map { $_ => 1 } $storm->source->tables;
ok $tables{ 'Bazzle' }, 'Bazzle table installed';


