use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

my $src = Ryu::Source->new;
my $f = $src->prefix('Value: ')->as_arrayref;
$src->emit($_) for 1..3;
$src->finish;
ok($f->is_ready, 'Future was completed') or die "something wrong";
my $rslt = $f->get;
cmp_deeply($rslt, [ map "Value: $_", 1..3 ], 'prefix operation was performed');
done_testing;

