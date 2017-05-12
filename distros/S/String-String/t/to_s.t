
use strict;
use Test::More tests => 6;
use UNIVERSAL::to_s;

my $ref;

# list and scalar context.
is(scalar abc->to_s(undef, 123) => 'abc123', 'string/undef/integer (scalar)');
is_deeply([abc->to_s(undef, 123)] => ["abc", '', '123'], 'string/undef/integer (list)');

# an object.
$ref = bless{}, 'Obj';
is(ref($ref->to_s) => '', '$ref->to_s is not reference');
like($ref->to_s => qr/^Obj=HASH\(0x\w+\)$/, '$ref->to_s');

# stringy object.
{
	package Str;
	use overload qw("") => sub{ shift->{str} };
}
$ref = bless{str=>"test"},"Str";
is(ref($ref->to_s) => '', 'stringy object, $ref->to_s is not reference');
is($ref->to_s, "test", 'stringy object, $ref->to_s');

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
