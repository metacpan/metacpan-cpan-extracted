# This is copied from the POD in Callback.pm. It'd be cool to parse the POD and
# generate this.. someday maybe.

package Foo;

use Moose::Role;

use MooseX::Role::Callback;
included(sub {
    my ($meta, $user) = @_;
    print "Foo applied to " . $user->name . "\n";
});

package Bar;

use Moose;
with 'Foo'; # Prints "Foo applied to Bar"
