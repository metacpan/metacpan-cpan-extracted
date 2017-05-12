use Test::More;

if( ! $ENV{AUTHOR_TEST} ) {
    plan skip_all => 'Tests run for module author only.';
}
else {
    plan tests => 1;
}

package Foo::Bar;
use Storm::Object;
storm_table( 'FooBars' );

has 'id' => ( is => 'rw', isa => 'Str', traits => [qw( PrimaryKey )] );
has 'name' => ( is => 'rw' );

has 'baz' => (
    is => 'rw',
    isa => 'Foo::Baz',
    traits => [qw( ForeignKey )],
    on_update => 'cascade',
    on_delete => 'restrict',
);

package Foo::Baz;
use Storm::Object;
storm_table( 'FooBazes' );

has 'id' => ( is => 'rw', isa => 'Str', traits => [qw( PrimaryKey )] );
has 'name' => ( is => 'rw' );






package Foo::Model;
use Storm::Model;

register 'Foo::Bar';
register 'Foo::Baz';


package main;
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->start_fresh;
$storm->aeolus->install_model( 'Foo::Model' );
$storm->aeolus->install_foreign_keys_to_class_table( 'Foo::Bar' );

ok ! $@, 'no errors';