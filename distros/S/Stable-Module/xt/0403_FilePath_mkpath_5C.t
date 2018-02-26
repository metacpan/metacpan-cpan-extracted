use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..14\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my $mkpath = 0;

rmdir('ソ/b/c') if -d 'ソ/b/c';
rmdir('ソ/b')   if -d 'ソ/b';
rmdir('ソ')     if -d 'ソ';
ok((not -d 'ソ'   ),  qq{not -d 'ソース' $^X @{[__FILE__]}});
ok((not -d 'ソ/b'  ), qq{not -d 'ソース/b' $^X @{[__FILE__]}});
ok((not -d 'ソ/b/c'), qq{not -d 'ソース/b/c' $^X @{[__FILE__]}});

eval {
    $mkpath = mkpath('ソ/b/c');
};

ok(($mkpath >= 1),  qq{mkpath('ソ/b/c') $^X @{[__FILE__]}});
ok((1 or -d 'ソ'),  qq{SKIP -d 'ソ' $^X @{[__FILE__]}});
ok((-d 'ソ/b'    ), qq{-d 'ソ/b' $^X @{[__FILE__]}});
ok((-d 'ソ/b/c'  ), qq{-d 'ソ/b/c' $^X @{[__FILE__]}});

rmdir('ソ ソ/b b/c c') if -d 'ソ ソ/b b/c c';
rmdir('ソ ソ/b b')     if -d 'ソ ソ/b b';
rmdir('ソ ソ')         if -d 'ソ ソ';
ok((not -d 'ソ ソ'        ), qq{not -d 'ソ ソ' $^X @{[__FILE__]}});
ok((not -d 'ソ ソ/b b'    ), qq{not -d 'ソ ソ/b b' $^X @{[__FILE__]}});
ok((not -d 'ソ ソ/b b/c c'), qq{not -d 'ソ ソ/b b/c c' $^X @{[__FILE__]}});

eval {
    $mkpath = mkpath('ソ ソ/b b/c c');
};

ok(($mkpath >= 1),       qq{mkpath('ソ ソ/b b/c c') $^X @{[__FILE__]}});
ok((1 or -d 'ソ ソ'  ),  qq{SKIP -d 'ソ ソ' $^X @{[__FILE__]}});
ok((-d 'ソ ソ/b b'    ), qq{-d 'ソ ソ/b b' $^X @{[__FILE__]}});
ok((-d 'ソ ソ/b b/c c'), qq{-d 'ソ ソ/b b/c c' $^X @{[__FILE__]}});

__END__
