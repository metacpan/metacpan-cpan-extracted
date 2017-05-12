
use strict;
use Test::More tests => 11;
use String::String qw(string);

# simple values.
is(string(123) => '123', 'integer');
is(string("abc") => 'abc', 'string');
is(string(undef) => '', 'undef');

# list and scalar context.
is(scalar string(123, undef, "abc") => '123abc', 'integer/undef/string (scalar)');
is_deeply([string(123, undef, "abc")] => [123,'',"abc"], 'integer/undef/string (list)');

# reference.
my $ref = {};
like(string($ref)    => qr/^HASH\(0x\w+\)$/, "HASH");
is(ref(string($ref)) => '', "no longer HASH");

# object.
$ref = bless{}, 'Obj';
like(string($ref)    => qr/^Obj=HASH\(0x\w+\)$/, "object");
is(ref(string($ref)) => '', "no longer object");

# stringy object.
{
	package Str;
	use overload qw("") => sub{ shift->{str} };
}
$ref = bless{str=>"test"},"Str";
is(string($ref)      => "test", "stringy object");
is(ref(string($ref)) => '',     "no longer (stringy) object");

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
