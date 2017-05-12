use Test::More tests => 18;
use Object::Stash;

{
	package Local::TestClass1;
	use Object::Stash;
	sub new {bless[@_],shift}
}

{
	package Local::TestClass2;
	use Object::Stash qw/data vital_data/;
	sub new {bless[@_],shift}
}

{
	package Local::TestClass3;
	use Object::Stash -package => 'Local::TestClass2', qw/trivial_data/;
	sub new {bless[@_],shift}
}

my ($o1, $o2, $o3) = map { "Local::TestClass$_"->new } 1..3;

ok(!Object::Stash->is_stash($o1->can('new')), 'Normal methods are not stashes');

ok($o1->can('stash'), 'Default name, creates method');
ok(Object::Stash->is_stash($o1->can('stash')), 'Default name, is stash');

ok(!$o2->can('stash'), 'Non-default name, does not create default method');
ok($o2->can('data'), 'Non-default name, creates method');
ok(Object::Stash->is_stash($o2->can('data')), 'Non-default name, is stash');
ok($o2->can('vital_data'), 'Multiple names, creates method');
ok(Object::Stash->is_stash($o2->can('vital_data')), 'Multiple names, is stash');

ok(!$o3->can('stash'), '-package argument, does not create default stash in caller');
ok(!$o3->can('trivial_data'), '-package argument, does not create named stash in caller');
ok($o2->can('trivial_data'), '-package argument, creates method in requested package');
ok(Object::Stash->is_stash($o2->can('trivial_data')), '-package argument, creates stash');

is(ref $o1->stash, 'HASH', 'stash is a hashref');

is_deeply($o2->vital_data(foo=>1,bar=>2), {foo=>1, bar=>2}, 'can set data by providing hash');
is_deeply($o2->trivial_data({foo=>1,baz=>2}), {foo=>1, baz=>2}, 'can set data by providing hashref');
ok(!exists $o2->vital_data->{baz}, "methods kept separate");

my $o2b = Local::TestClass2->new;
ok(!$o2b->vital_data->{foo},'objects kept separate');

ok(Object::Stash::is_stash($o1->can('stash')), 'is_stash can be called as a non-method');
