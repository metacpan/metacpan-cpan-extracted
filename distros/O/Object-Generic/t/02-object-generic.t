#!/usr/bin/perl
#
# $Id: 02-object-generic.t 403 2005-09-08 20:17:37Z mahoney $ 
#
use Test::More tests => 28;

use strict;
use warnings;
use Object::Generic;

my $g;
ok( (not Object::Generic->foo),		'undeclared method fails' );
ok( $g = Object::Generic->new( 
    color=>'red', size=>'large'),	'->new' );
ok( 'red' eq $g->color,			'->color accessor' );
ok( 'red' eq $g->get('color'),		'->get("color")' );
ok( 'red' eq $g->get_color,		'->get_color' );
ok( $g->color('blue'),			'->color("blue")' );
ok( 'blue' eq $g->color,		'.. and color is blue' );
ok( $g->set_name('Fred'),		'->set_name("Fred")' );
ok( 'Fred' eq $g->name,			'.. and name is Fred' );
ok( $g->set( name => 'Jane'),		'->set(name=>"Fred")' );
ok( 'Jane' eq $g->get_name ,		'.. and name is Jane' );
ok( $g->args( who => 'me' ),		'->args( who => "me")' );
ok( 'me' eq $g->who,			'.. and who is me' );
ok( defined $g->foo,			'defined g->foo' );
ok( (not $g->foo),			'not g->foo' );
ok( (not $g->this->that->those),	'not g->this->that->those' );

ok( $g->exists('color'),                '->exists(key) true when it does');
ok( ! $g->exists('foo'),                '->exists(key) false when not');
ok( scalar($g->keys()) == 4,            '->keys');

$g->remove('color');
ok( scalar($g->keys()) == 3,            '->remove(color) leaves one less ->key');

# test set_allowed_keys in an inherited class

{
  package myClass;
  our @ISA = qw( Object::Generic );
  myClass->set_allowed_keys('width', 'height', 'border');
  sub myMethod {
    my $self=shift;
    $self->args(@_);       # processes @args=(key=>value, key=>value, ...)
    # print $self->width;  # ... do whatever else
  }

}
my ($obj, $usa);
ok($obj = myClass->new(width=>5, height=>10), 	'inherited myClass->new');
$obj->country('usa');       # attempt to call set country to usa
ok( ! $obj->country,			'key not in is_allowed fails');
$obj->myMethod( width => 10 );  # attempt to call myMethod with width->10
ok( 10== $obj->width,                  '->myMethod calls ->args and sets key');
$obj->border('yes');            # attempt to se allowed key
ok( 'yes' eq $obj->border,              'key in is_allowed can be set');

# test changing set and get methods in an inherited class

{ package OtherSetGet;
  our @ISA = qw( Object::Generic );
  sub get {
    my $self = shift;
    my ($key) = @_;
    return $self->{ '__'.$key };
  }
  sub set {
    my $self = shift;
    my ($key, $value) = @_;
    $self->{ '__'.$key } = $value;
    return $value;
  }
}

$obj = OtherSetGet->new( age=>22, name=>'John' );
$obj->hair('black');
ok( 'black' eq $obj->hair, 'inherited get/set: works');
#print "hair is " . $obj->hair . "\n";
#print "obj keys: (" . join(",",keys(%$obj)) . ")\n";
my $count = 0;
for (keys %$obj){
  $count++ if m/^__/;
}
ok( $count==3,             'inherited get/set: internals look OK');

# test define_subs 
{ package Define_Stuff;
  our @ISA = qw( Object::Generic );
}
Define_Stuff->define_keys(qw( name age weight ));
my $ds = new Define_Stuff;
ok( $ds->can('set_name'), "define_keys('name') makes set_name");
$ds->age(32);
ok( $ds->age == 32,       "dfine_keys accessors look OK");
