package SomeThing;
use base 'Statistics::Frequency';
sub set {
  $_[0]->{stuff} = $_[1];
  $_[0]->_set_update_callback( sub { delete $_[0]->{stuff} } );
}
sub get {
  $_[0]->{stuff};
}

package main;

print "1..3\n";

my $thing = SomeThing->new;

$thing->set(42);
print $thing->get() == 42 ? "ok 1\n" : "not ok 1\n";

# Reading data should not invalidate our cached value.
$thing->frequency('foo');
print $thing->get() == 42 ? "ok 2\n" : "not ok 2\n";

# Modifying data should invalidate our cached value.
$thing->clear_data();
print defined $thing->get() ? "not ok 3\n" : "ok 3\n";
