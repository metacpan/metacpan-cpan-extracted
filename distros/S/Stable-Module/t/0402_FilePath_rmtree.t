use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..14\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

$SIG{__WARN__} = sub {};
$SIG{__DIE__}  = sub {};

my $rmtree = 0;

mkdir('x',0777)     if not -d 'x';
mkdir('x/y',0777)   if not -d 'x/y';
mkdir('x/y/z',0777) if not -d 'x/y/z';
ok((-d 'x'    ), qq{-d 'x' $^X @{[__FILE__]}});
ok((-d 'x/y'  ), qq{-d 'x/y' $^X @{[__FILE__]}});
ok((-d 'x/y/z'), qq{-d 'x/y/z' $^X @{[__FILE__]}});

eval {
    $rmtree = rmtree('x');
};

ok(($rmtree >= 1  ), qq{rmtree('x') $^X @{[__FILE__]}});
ok((not -e 'x/y/z'), qq{not -e 'x/y/z' $^X @{[__FILE__]}});
ok((not -e 'x/y'  ), qq{not -e 'x/y' $^X @{[__FILE__]}});
ok((not -e 'x'    ), qq{not -e 'x' $^X @{[__FILE__]}});

mkdir('x x',0777)         if not -d 'x x';
mkdir('x x/y y',0777)     if not -d 'x x/y y';
mkdir('x x/y y/z z',0777) if not -d 'x x/y y/z z';
ok((-d 'x x'        ), qq{-d 'x x' $^X @{[__FILE__]}});
ok((-d 'x x/y y'    ), qq{-d 'x x/y y' $^X @{[__FILE__]}});
ok((-d 'x x/y y/z z'), qq{-d 'x x/y y/z z' $^X @{[__FILE__]}});

eval {
    $rmtree = rmtree('x x');
};

ok(($rmtree >= 1        ), qq{rmtree('x x') $^X @{[__FILE__]}});
ok((not -e 'x x/y y/z z'), qq{not -e 'x x/y y/z z' $^X @{[__FILE__]}});
ok((not -e 'x x/y y'    ), qq{not -e 'x x/y y' $^X @{[__FILE__]}});
ok((not -e 'x x'        ), qq{not -e 'x x' $^X @{[__FILE__]}});

__END__
