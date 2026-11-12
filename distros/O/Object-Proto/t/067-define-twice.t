use strict;
use warnings;
use Test::More;
use Hash::Util::FieldHash qw(fieldhash);
use Object::Proto;

Object::Proto::define('DT', 'a', 'r:reader(get_r):writer(set_r)', 't:Int');
my $first = DT->new(a => 1, r => 2, t => 3);
{
    no warnings 'redefine';
    Object::Proto::define('DT', 'a', 'r:reader(get_r):writer(set_r)', 't:Int');
}
my $second = DT->new(a => 4, r => 5, t => 6);
is($second->a, 4, 'a class defined twice keeps its plain accessor');
is($second->get_r, 5, 'and its reader');
is($second->set_r(7), 7, 'and its writer');
is($second->t, 6, 'and its typed accessor');
is($first->a, 1, 'an object of the first definition still reads');
is(scalar(my @p = Object::Proto::properties('DT')), 3, 'with no slot added');

# A redefinition with fewer slots than before keeps the slots it names where
# they were: its arrays must reach those indices (1.05 read and wrote past them)
Object::Proto::define('Shrinking', 'a', 'b', 'c:Int', 'd');
{
    no warnings 'redefine';
    Object::Proto::define('Shrinking', 'd');
}
is(Object::Proto::slot_info('Shrinking', 'd')->{index}, 4, 'a redefinition with fewer slots keeps a slot\'s index');
ok(Shrinking->can('d'), 'and its accessor');

my $o = DT->new(a => 1);
Object::Proto::freeze($o);
fieldhash my %h;
$h{$o} = 1;
ok(Object::Proto::is_frozen($o), 'the frozen flag is found behind magic another module added later');
eval { $o->a(2) };
like($@, qr/Cannot modify frozen object/, 'and still holds');

done_testing;
