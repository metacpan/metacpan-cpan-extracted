use lib 'lib';
use Test::More tests => 4;

package Foo;
use Mousse;

has 'this', is => 'rw';

package Foo::Bar;
use Mousse;

extends 'Foo';

has 'that', is => 'rw';

package main;

my $f = Foo->new(this => 'rocks');
my $fb = Foo::Bar->new(this => 'rules', that => 'thing');

ok $f->can('this'), 'Foo can this';
ok not($f->can('that')), "Foo can't that";
ok $fb->can('this'), 'Foo::Bar can this';
ok $fb->can('that'), 'Foo::Bar can that';

