use strict;
use warnings;
use Test::More;

BEGIN {
    require Object::Proto;
    Object::Proto::define('ErrorTestClass', 'name:Str', 'age:Int');
}

use Object::Proto;

# --- Passing non-objects to utility functions ---

# lock on non-object
eval { Object::Proto::lock("not an object") };
like($@, qr/object|blessed|reference/i, 'lock rejects plain string');

eval { Object::Proto::lock(42) };
like($@, qr/object|blessed|reference/i, 'lock rejects number');

eval { Object::Proto::lock(undef) };
like($@, qr/object|blessed|reference/i, 'lock rejects undef');

# unlock on non-object
eval { Object::Proto::unlock("not an object") };
like($@, qr/object|blessed|reference/i, 'unlock rejects plain string');

# freeze on non-object
eval { Object::Proto::freeze("not an object") };
like($@, qr/object|blessed|reference/i, 'freeze rejects plain string');

eval { Object::Proto::freeze([1,2,3]) };
like($@, qr/object|blessed|reference/i, 'freeze rejects unblessed array ref');

# is_frozen on non-object
eval { Object::Proto::is_frozen("not an object") };
like($@, qr/object|blessed|reference/i, 'is_frozen rejects plain string');

# is_locked on non-object
eval { Object::Proto::is_locked("not an object") };
like($@, qr/object|blessed|reference/i, 'is_locked rejects plain string');

# set_prototype on non-object
eval { Object::Proto::set_prototype("not an object", bless([], 'ErrorTestClass')) };
like($@, qr/object|blessed|reference/i, 'set_prototype rejects plain string as first arg');

# prototype on non-object
eval { Object::Proto::prototype("not an object") };
like($@, qr/object|blessed|reference/i, 'prototype rejects plain string');

# clone accepts non-objects: scalars return as-is, refs are deep copied
my $s = Object::Proto::clone("not an object");
is($s, "not an object", 'clone returns plain string as-is');

my $u = Object::Proto::clone(undef);
ok(!defined $u, 'clone returns undef as-is');

done_testing;
