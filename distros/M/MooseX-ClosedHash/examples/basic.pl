use v5.14;

package Person {
	use MooseX::ClosedHash;
	has name => (is => "rw");
	has age  => (is => "rw");
	__PACKAGE__->meta->make_immutable;
}

my $bob = Person->new(name => "Bob", age => 42);

say $bob->name, " is ", $bob->age, " years old.";
say $bob->dump;
