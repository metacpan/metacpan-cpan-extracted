use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..10\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my $move = 0;

open(FILE,'>ソース1.txt');
print FILE "\n";
close(FILE);

ok((    -e 'ソース1.txt'), qq{    -e 'ソース1.txt' $^X @{[__FILE__]}});
ok((not -e 'ソース2.txt'), qq{not -e 'ソース2.txt' $^X @{[__FILE__]}});

eval {
    $move = move('ソース1.txt','ソース2.txt');
};

ok($move, qq{move('ソース1.txt','ソース2.txt') $^X @{[__FILE__]}});
ok((not -e 'ソース1.txt'), qq{not -e 'ソース1.txt' $^X @{[__FILE__]}});
ok((    -e 'ソース2.txt'), qq{    -e 'ソース2.txt' $^X @{[__FILE__]}});

unlink('ソース1.txt');
unlink('ソース2.txt');

open(FILE,'>ソ ー ス1.txt');
print FILE "\n";
close(FILE);

ok((    -e 'ソ ー ス1.txt'), qq{    -e 'ソ ー ス1.txt' $^X @{[__FILE__]}});
ok((not -e 'ソ ー ス2.txt'), qq{not -e 'ソ ー ス2.txt' $^X @{[__FILE__]}});

eval {
    $move = move('ソ ー ス1.txt','ソ ー ス2.txt');
};

ok($move, qq{move('ソ ー ス1.txt','ソ ー ス2.txt') $^X @{[__FILE__]}});
ok((not -e 'ソ ー ス1.txt'), qq{not -e 'ソ ー ス1.txt' $^X @{[__FILE__]}});
ok((    -e 'ソ ー ス2.txt'), qq{    -e 'ソ ー ス2.txt' $^X @{[__FILE__]}});

unlink('ソ ー ス1.txt');
unlink('ソ ー ス2.txt');

__END__
