use syntax qw/maybe dispatcher/;
use Data::Dumper;

my $foo = dispatcher {
	match(1);
};

print Dumper $foo;
