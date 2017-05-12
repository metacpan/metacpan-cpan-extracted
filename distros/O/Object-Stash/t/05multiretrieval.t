use Test::More tests => 4;
use Object::Stash;

{
	package Local::TestClass;
	use Object::Stash;
	sub new {bless[@_],shift}
}

my $obj = Local::TestClass->new;
$obj->stash(foo=>1, bar=>2, baz=>3);

my @return = $obj->stash([qw/baz bar/]);
is($return[0], 3);
is($return[1], 2);

my $return = $obj->stash([qw/baz foo/]);
is($return->[0], 3);
is($return->[1], 1);
