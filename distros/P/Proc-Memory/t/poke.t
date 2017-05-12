use Test::More;

BEGIN {
    use_ok 'Proc::Memory';
}

use Inline 	C => Config => #force_build => 1 =>
			enable => 'autowrap';
use Inline 'C';
use Sentinel;

my $proc = Proc::Memory->new(pid => $$);
isnt $proc, undef;

is var_get(), 3;

$proc->poke(var_addr()) = pack('L', 9);
is var_get(), 9;

$proc->poke(var_addr(), 'L') = 2;
is var_get(), 2;

$proc->poke(var_addr(), 'C4')
              = [1,1, 1,1];
is var_get(), 0x0101_0101;

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


