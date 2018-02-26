use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..14\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

$SIG{__WARN__} = sub {};
$SIG{__DIE__}  = sub {};

my $rmtree = 0;

mkdir('ソ',0777)     if not -d 'ソ';
mkdir('ソ/b',0777)   if not -d 'ソ/b';
mkdir('ソ/b/c',0777) if not -d 'ソ/b/c';
ok((1 or -d 'ソ'), qq{SKIP -d 'ソ' $^X @{[__FILE__]}});
ok((-d 'ソ/b'  ),  qq{-d 'ソ/b' $^X @{[__FILE__]}});
ok((-d 'ソ/b/c'),  qq{-d 'ソ/b/c' $^X @{[__FILE__]}});

eval {
    $rmtree = rmtree('ソ');
};

ok(($rmtree >=  1  ), qq{rmtree('ソ') $^X @{[__FILE__]}});
ok((not -e 'ソ/b/c'), qq{not -e 'ソ/b/c' $^X @{[__FILE__]}});
ok((not -e 'ソ/b'  ), qq{not -e 'ソ/b' $^X @{[__FILE__]}});
ok((not -e 'ソ'    ), qq{not -e 'ソ' $^X @{[__FILE__]}});

mkdir('ソ ソ',0777)         if not -d 'ソ ソ';
mkdir('ソ ソ/b b',0777)     if not -d 'ソ ソ/b b';
mkdir('ソ ソ/b b/c c',0777) if not -d 'ソ ソ/b b/c c';
ok((1 or -d 'ソ ソ'   ), qq{SKIP -d 'ソ ソ' $^X @{[__FILE__]}});
ok((-d 'ソ ソ/b b'    ), qq{-d 'ソ ソ/b b' $^X @{[__FILE__]}});
ok((-d 'ソ ソ/b b/c c'), qq{-d 'ソ ソ/b b/c c' $^X @{[__FILE__]}});

eval {
    $rmtree = rmtree('ソ ソ');
};

ok(($rmtree >= 1          ), qq{rmtree('ソ ソ') $^X @{[__FILE__]}});
ok((not -e 'ソ ソ/b b/c c'), qq{not -e 'ソ ソ/b b/c c' $^X @{[__FILE__]}});
ok((not -e 'ソ ソ/b b'    ), qq{not -e 'ソ ソ/b b' $^X @{[__FILE__]}});
ok((not -e 'ソ ソ'        ), qq{not -e 'ソ ソ' $^X @{[__FILE__]}});

__END__
