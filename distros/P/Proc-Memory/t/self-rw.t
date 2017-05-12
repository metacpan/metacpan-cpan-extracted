use Test::More;

BEGIN {
    use_ok 'Proc::Memory';
}

use Inline 	C => Config => #force_build => 1 =>
			enable => 'autowrap';
use Inline 'C';
use Sentinel;

my $proc = Proc::Memory->new($$);
isnt $proc, undef;

is var_get(), 3;
my $read = $proc->read(var_addr(), 4);
is var_get(), 3;

isnt $read, undef;
is length($read), 4;
is unpack('L', $read), 3;

var_set(5);
is var_get(), 5;
$read = $proc->read(var_addr(), 4);
is var_get(), 5;

isnt $read, undef;
is length($read), 4;
is unpack('L', $read), 5;

$proc->write(var_addr(), pack('L', 9));

is var_get(), 9;
$read = $proc->read(var_addr(), 4);
is var_get(), 9;

isnt $read, undef;
is length($read), 4;
is unpack('L', $read), 9;




done_testing;

__END__
__C__

volatile U32 var = 3;
void var_set(U32 val) {
    var = val;
}
U32 var_get() {
    return var;
}
long var_addr() {
    return (long)&var;
}

