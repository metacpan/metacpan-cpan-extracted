use strict;
use warnings;
use Test::More;
use Scalar::Util qw(isweak);
use Object::Proto;

BEGIN { Object::Proto::register_type('Pos', sub { defined $_[0] && !ref $_[0] && $_[0] > 0 }) }

package FA;
BEGIN {
    Object::Proto::define('FA', 'plain', 'other', 'typed:Int', 'ro:Int:readonly', 'req:Int:required',
        'co:Int:coerce(FA::half)', 'trg:Int:trigger(_trg)', 'wk:weak', 'pr:Int:private', 'fl:Str:trigger(_fl)', 'ps:Pos');
}
our @log;
sub half { int($_[0] / 2) }
sub _trg { push @log, "trg:$_[1]" }
sub _fl  { push @log, "fl:$_[1]" }

sub get_plain { plain($_[0]) }
sub set_plain { plain($_[0], $_[1]) }
sub get_other { other($_[0]) }
sub get_typed { typed($_[0]) }
sub set_typed_var { typed($_[0], $_[1]) }
sub set_typed_const { typed($_[0], 5) }
sub set_typed_bad_const { typed($_[0], 'abc') }
sub set_ro { ro($_[0], $_[1]) }
sub set_req { req($_[0], $_[1]) }
sub set_co { co($_[0], $_[1]) }
sub set_trg { trg($_[0], $_[1]) }
sub set_wk { wk($_[0], $_[1]) }
sub get_pr { pr($_[0]) }
sub set_pr { pr($_[0], $_[1]) }
sub set_fl_const { fl($_[0], 'x') }
sub set_ps { ps($_[0], $_[1]) }

package main;

my $o = FA->new(req => 1, plain => 'p');
is(FA::get_plain($o), 'p', 'a function-style getter on an untyped slot');
is(FA::set_plain($o, 'q'), 'q', 'and the setter returns the value');
is($o->plain, 'q', 'which the method reads back');
ok(!defined FA::get_other($o), 'an undef slot with no prototype reads undef');

my $proto = FA->new(req => 1, other => 'from proto');
$o->set_prototype($proto);
is(FA::get_other($o), 'from proto', 'and through the prototype chain when there is one');

is(FA::get_typed($o), undef, 'a typed slot starts undef');
is(FA::set_typed_const($o), 5, 'a constant that passes its type is set without a runtime check');
is($o->typed, 5, 'and lands in the slot');
is(FA::set_typed_var($o, 7), 7, 'a variable goes through the typed setter');
eval { FA::set_typed_var($o, 'abc') };
like($@, qr/Type constraint failed for 'typed': expected Int/, 'which rejects a bad value');
eval { FA::set_typed_bad_const($o) };
like($@, qr/Type constraint failed for 'typed': expected Int/, 'a constant that fails its type is rejected at runtime');
eval { FA::set_ps($o, -1) };
like($@, qr/Type constraint failed for 'ps': expected Pos/, 'and a registered type is named when it fails');
is(FA::set_ps($o, 3), 3, 'and passes a good value');
eval { FA::set_ro($o, 1) };
like($@, qr/Cannot modify readonly slot 'ro'/, 'readonly through the typed setter');
my $undef;
eval { FA::set_req($o, $undef) };
like($@, qr/Cannot set required slot 'req' to undef/, 'required through the typed setter');
is(FA::set_req($o, 2), 2, 'which takes a defined value');
is(FA::set_co($o, 8), 4, 'coercion through the typed setter');
is(FA::set_trg($o, 3), 3, 'a trigger slot through the typed setter');
is_deeply(\@FA::log, ['trg:3'], 'fires the trigger');
is(FA::set_fl_const($o), 'x', 'a constant on a trigger slot still goes through the typed setter');
is_deeply(\@FA::log, ['trg:3', 'fl:x'], 'so the trigger fires');
my $ref = [];
FA::set_wk($o, $ref);
my $idx = Object::Proto::slot_info('FA', 'wk')->{index};
ok(isweak($o->[$idx]), 'a weak slot through the typed setter stores a weak reference');
is(FA::set_wk($o, 'plain'), 'plain', 'and a plain value');
is(FA::set_pr($o, 4), 4, 'a private slot is set from its own package');
is(FA::get_pr($o), 4, 'and read');
eval { FA::pr($o) };
like($@, qr/cannot call private attribute pr on FA from main/, 'but not from outside');

eval { FA::get_plain(42) };
like($@, qr/Not an object/, 'the untyped getter wants an object');
eval { FA::set_plain(42, 1) };
like($@, qr/Not an object/, 'so does the untyped setter');
eval { FA::set_typed_var(42, 1) };
like($@, qr/Not an object/, 'and the typed setter');
eval { FA->can('plain')->(42) };
like($@, qr/Not an object/, 'and the untyped accessor called as a code reference');
eval { FA->can('typed')->(42) };
like($@, qr/Not an object/, 'and the typed one');

my $f = FA->new(req => 1);
Object::Proto::freeze($f);
eval { FA::set_plain($f, 1) };
like($@, qr/Cannot modify frozen object/, 'a frozen object refuses the untyped setter');
eval { FA::set_typed_var($f, 1) };
like($@, qr/Cannot modify frozen object/, 'and the typed setter');
eval { $f->plain(1) };
like($@, qr/Cannot modify frozen object/, 'and the untyped method');

my $short = FA->new(req => 1, plain => 'gone');
$#$short = 0;
ok(!defined FA::get_plain($short), 'an object whose array was truncated reads undef');
is(FA::set_plain($short, 'back'), 'back', 'and grows again on set');
is($short->plain, 'back', 'and holds the value');
my $short2 = FA->new(req => 1);
$#$short2 = 0;
is(FA::set_typed_var($short2, 3), 3, 'the typed setter too');
is($short2->typed, 3, 'and holds the value');
my $holes = FA->new(req => 1);
$#$holes = 0;
$#$holes = 30;
is(FA::set_plain($holes, 'h'), 'h', 'an array regrown with empty slots is written');
is($holes->plain, 'h', 'and read');
my $holes2 = FA->new(req => 1);
$#$holes2 = 0;
$#$holes2 = 30;
is(FA::set_typed_var($holes2, 9), 9, 'by the typed setter too');
is($holes2->typed, 9, 'and read');

done_testing;
