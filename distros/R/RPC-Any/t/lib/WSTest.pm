package WSTest;
use strict;
use Scalar::Util qw(tainted);

use constant RETURN_ARRAY => [1, 2, 3];
use constant RETURN_STRUCT => {
    1 => 'One',
    2 => 'Two',
    3 => 'Three',
};
use constant UNICODE_STRING => "\x{100}\x{101}\x{102}";

sub hello  { return 'Hello!'; }
sub array  { return RETURN_ARRAY; }
sub struct { return RETURN_STRUCT; }
sub return_this { return $_[1]; }
sub die_this    { shift; die shift; }
sub is_tainted  { shift; return tainted(shift) ? 1 : 0; }
sub always_utf8 { return UNICODE_STRING; }
sub _private    { return 1; }

sub exception_this {
    shift;
    die RPC::Any::Exception::WSTest->new(message => shift);
}
sub return_utf8 {
    my ($class, $value) = @_;
    my $is_utf8 = utf8::is_utf8($value) ? 1 : 0;
    return { $is_utf8 => $value };
}
    
sub type_this {
    my ($self, $type, $value) = @_;
    return $self->type($type, $value);
}

package RPC::Any::Exception::WSTest;
use Moose;
extends 'RPC::Any::Exception';
has '+code' => (default => 99);
__PACKAGE__->meta->make_immutable;

1;