use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..10\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my $move = 0;

open(FILE,'>move1.txt');
print FILE "\n";
close(FILE);

ok((    -e 'move1.txt'), qq{    -e 'move1.txt' $^X @{[__FILE__]}});
ok((not -e 'move2.txt'), qq{not -e 'move2.txt' $^X @{[__FILE__]}});

eval {
    $move = move('move1.txt','move2.txt');
};

ok($move, qq{move('move1.txt','move2.txt') $^X @{[__FILE__]}});
ok((not -e 'move1.txt'), qq{not -e 'move1.txt' $^X @{[__FILE__]}});
ok((    -e 'move2.txt'), qq{    -e 'move2.txt' $^X @{[__FILE__]}});

unlink('move1.txt');
unlink('move2.txt');

open(FILE,'>mo ve1.txt');
print FILE "\n";
close(FILE);

ok((    -e 'mo ve1.txt'), qq{    -e 'mo ve1.txt' $^X @{[__FILE__]}});
ok((not -e 'mo ve2.txt'), qq{not -e 'mo ve2.txt' $^X @{[__FILE__]}});

eval {
    $move = move('mo ve1.txt','mo ve2.txt');
};

ok($move, qq{move('mo ve1.txt','mo ve2.txt') $^X @{[__FILE__]}});
ok((not -e 'mo ve1.txt'), qq{not -e 'mo ve1.txt' $^X @{[__FILE__]}});
ok((    -e 'mo ve2.txt'), qq{    -e 'mo ve2.txt' $^X @{[__FILE__]}});

unlink('mo ve1.txt');
unlink('mo ve2.txt');

__END__
