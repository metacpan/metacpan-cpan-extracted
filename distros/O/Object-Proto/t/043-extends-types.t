#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# === Extends with type constraints ===

Object::Proto::define('TypedBase',
    'count:Int:required',
    'label:Str:default(base)',
);

Object::Proto::define('TypedChild',
    extends => 'TypedBase',
    'score:Num:default(0.0)',
);

# Valid construction
my $obj = new TypedChild count => 10, score => 3.14;
is($obj->count, 10, 'inherited typed required property');
is($obj->label, 'base', 'inherited typed default');
ok($obj->score == 3.14, 'own typed property');

# Type checking on inherited property
eval { $obj->count('not_a_number') };
like($@, qr/Type constraint|type/i, 'type check on inherited property');

# Required inherited property
eval { new TypedChild score => 1.0 };
like($@, qr/required|missing/i, 'required inherited property enforced');

done_testing;
