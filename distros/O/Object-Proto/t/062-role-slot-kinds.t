use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Scalar::Util qw(isweak);
use Object::Proto;

our @log;
package RK;
our $count = 0;
sub on_t { push @main::log, "rt:$_[1]" }
sub _build_b { 'built-b' }
sub _helper { 'not copied' }
sub up { uc $_[0] }
sub describe { 'from role' }
package RC;
sub describe { 'from class' }
package main;

Object::Proto::role('RK', 'p', 'c:clearer', 'd:predicate', 'r:reader(get_r)', 'w:writer(set_w)',
    'a:arg(aa)', 't:Str:trigger(on_t)', 'q:required', 'l:lazy:default(3)', 'k:weak', 'b:lazy:builder(_build_b)',
    'rt:trigger(on_t)', 'rc:coerce(RK::up)', 'rr:readonly');
Object::Proto::define('RC', 'own');
Object::Proto::with('RC', 'RK');

my $rc = RC->new(q => 1, aa => 5, t => 'x');
is($rc->p(2), 2, 'a plain role slot');
is($rc->a, 5, 'a role slot with an init arg');
is_deeply(\@log, ['rt:x'], 'a role slot trigger fires');
$rc->c(1);
$rc->clear_c;
ok(!defined $rc->c, 'a role slot clearer');
ok(!$rc->has_d, 'a role slot predicate');
$rc->r('rv');
is($rc->get_r, 'rv', 'a role slot reader');
$rc->set_w('wv');
is($rc->w, 'wv', 'a role slot writer');
is($rc->l, 3, 'a lazy role slot default');
my $ref = [];
$rc->k($ref);
ok(isweak($rc->[Object::Proto::slot_info('RC', 'k')->{index}]), 'a weak role slot');
is($rc->b, 'built-b', 'a lazy builder from the role');
is($rc->rc('abc'), 'ABC', 'a role slot with only a coercion');
eval { $rc->rr(1) };
like($@, qr/Cannot modify readonly slot 'rr'/, 'a role slot with only readonly');
$rc->rt(2);
is_deeply(\@log, ['rt:x', 'rt:2'], 'a role slot with only a trigger');
eval { RC->new(aa => 1) };
like($@, qr/Required slot 'q' not provided/, 'a required role slot');
is($rc->describe, 'from class', 'a method the class already has is not replaced by the role');
is($RK::count, 0, 'a variable in the role package is left alone');
ok(!RC->can('_helper'), 'a sub of the role whose name starts with an underscore is not copied');

eval { Object::Proto::role('RK') };
like($@, qr/Role 'RK' already defined/, 'a role cannot be defined twice');
eval { Object::Proto::requires('Nope', 'm') };
like($@, qr/Role 'Nope' not defined/, 'requires wants a defined role');
eval { Object::Proto::with('Nope', 'RK') };
like($@, qr/Class 'Nope' not defined with Object::Proto::define/, 'with wants a defined class');

Object::Proto::define('RL', 'own');
Object::Proto::with('RL', 'LoadedRole');
my $rl = RL->new;
is($rl->loaded, 1, 'a role not yet defined is loaded as a module');
is($rl->from_module, 'yes', 'with its methods');
Object::Proto::define('RM', 'own');
eval { Object::Proto::with('RM', 'NotARole') };
like($@, qr/Role 'NotARole' not defined/, 'a module that loads without defining the role is an error');
eval { Object::Proto::with('RM', 'No::Such::Module::Here') };
like($@, qr/Can't locate No\/Such\/Module\/Here\.pm/, 'and a module that does not load');

ok(!Object::Proto::does('Nope', 'RK'), 'does on an undefined class is false');

done_testing;
