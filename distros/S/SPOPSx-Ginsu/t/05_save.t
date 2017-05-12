#!/usr/bin/perl -w

BEGIN {
	use lib qw( t );
}

use strict;
use Test::More tests => 11;

use my_dbi_conf;
use test_config;
test_config->recreate_tables;

package MyObject;

use strict;
use vars qw (@ISA $CONF $TABLE_DEF);
BEGIN {
    @ISA    = qw/MyBaseObject/;
    $CONF   = {
        MyObject_Alias => {
            class => __PACKAGE__,
            base_table      =>  'T_MyObject',
            isa             =>  \@ISA,
            field           =>  [ qw/id color val/ ],
            id_field        =>  'id',
            skip_undef      =>  [ qw/color val/ ],
            as_string_order =>  [ qw/id class color val/ ],
            no_security     =>  1,
        },
    };
    $TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS T_MyObject (
    id  int(11) PRIMARY KEY,
    color char(10),
    val   tinyint,
    UNIQUE key color (color, val)
)
SQL
}
 
__PACKAGE__->config_and_init;

package main;

my ($h, $s);

##-----  initial save with single inheritance  -----
my $t = 'save obj (insert) w/single inheritance';
ok( $h = Helicopter->new( {	name			=> 'Whirly Bird',
							owner			=> 25,
							ceiling			=> 7500,
							lift_capacity	=> 800
						} ), $t . ', create obj' );
ok( my $hid = $h->save->id, $t . ', id defined after save');

## check that we can get back the same thing
ok( $h->compare(Helicopter->fetch($h->id)), $t . ', fetch & compare' );

##-----  initial save with multiple inheritance  -----
$t = 'save obj (insert) w/multiple inheritance';
ok( $s = Seaplane->new( {	name			=> 'PuddleJumper',
							owner			=> 20,
							ceiling			=> 9000,
							wingspan		=> 36,
							min_depth		=> 2.5,
							anchor			=> Anchor->new({weight => 25}),
							max_wave_height	=> 2
						} ), $t . ', create obj' );

ok( my $sid = $s->save->id, $t . ', id defined after save' );

## check that we can get back the same thing
ok( $s->compare(Seaplane->fetch($s->id)), $t . ', fetch & compare' );

##-----  update save with single inheritance  -----
$t = 'save obj (update) w/single inheritance';
$h->{ceiling} = 10000;
$h->save;
ok( $h->compare(Helicopter->fetch($h->id)), $t );

##-----  update save with multiple inheritance  -----
$t = 'save obj (update) w/multiple inheritance';
$s->{min_depth} = 3.5;
$s->save;
ok( $s->compare(Seaplane->fetch($s->id)), $t );

##-----  explicit is_add save with single inheritance  -----
$t = 'save obj (explicit is_add) w/single inheritance';
my $h2 = Helicopter->fetch($h->id);
$h2->remove;
$h->save( {is_add => 1} );
ok( $h->compare(Helicopter->fetch($h->id)), $t);

##-----  explicit is_add save with multiple inheritance  -----
$t = 'save obj (explicit is_add) w/multiple inheritance';
my $s2 = Seaplane->fetch($s->id);
$s2->remove;
$s->{anchor} = undef;
$s->save( {is_add => 1} );
ok( $s->compare(Seaplane->fetch($s->id)), $t );

##-- check whether failed save removes rows from parent tables.

MyObject->create_table;
my $obj = eval { MyObject->new({color => 'red', val => 1})->save };
eval { MyObject->new({color => 'red', val => 1})->save };

my $my_obj_count = MyObject->fetch_count({
							where => 'id >= ?',
							value => [ $obj->id ]
							});
my $ginsu_my_obj_count = MyBaseObject->fetch_count({
							where => 'class = ? and id >= ?',
							value => [ 'MyObject', $obj->id ]
							});

is ($my_obj_count == 1, $ginsu_my_obj_count,
					'failed save removed rows from parent table also');
$obj->remove;
MyObject->drop_table;

1;
