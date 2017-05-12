use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
	use_ok("Object::Capsule");
}

our $widgetstring = "It's a widget!";

package Widget;
	sub new  { my $class = shift; bless { @_ } => $class }
	sub size { (shift)->{size} }
	sub grow { ++(shift)->{size} }
	sub wane { --(shift)->{size} }

	sub encapsulate { "!" }

	use overload
		'""' => sub { $widgetstring },
		'0+' => sub { $_[0]->{size} },
		fallback => 1
	;
package main;

my $widget  = new Widget size => 10;
my $capsule = encapsulate($widget);

isa_ok($widget, 'Widget');

isa_ok($capsule,  'Object::Capsule');
isa_ok($$capsule, 'Widget');

cmp_ok($capsule->size, '==', 10, "size method goes through capsule");
cmp_ok($capsule->grow, '==', 11, "grow method goes through capsule");
cmp_ok($capsule->grow, '==', 12, "grow method again");
cmp_ok($capsule->wane, '==', 11, "wane method");
cmp_ok($capsule->size, '==', 11, "doublecheck");
cmp_ok($capsule->wane, '==', 10, "final checkup");

cmp_ok($widget,  '==',               10, "widget == 10");
cmp_ok($widget,  'eq',  "$widgetstring", "widget eq the right thing");

cmp_ok($capsule, '==',               10, "capsule == 10");
cmp_ok($capsule, 'eq',  "$widgetstring", "capsule eq the right thing");
cmp_ok($capsule, 'eq',          $widget, "capsule eq the widget");
cmp_ok("$capsule", 'eq',      "$widget", '"capsule" eq the "widget"');

is($capsule->encapsulate, '!',   "encapsulate passes through on object");

