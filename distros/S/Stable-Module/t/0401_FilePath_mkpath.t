use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..14\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my $mkpath = 0;

rmdir('a/b/c') if -d 'a/b/c';
rmdir('a/b')   if -d 'a/b';
rmdir('a')     if -d 'a';
ok((not -d 'a'    ), qq{not -d 'a' $^X @{[__FILE__]}});
ok((not -d 'a/b'  ), qq{not -d 'a/b' $^X @{[__FILE__]}});
ok((not -d 'a/b/c'), qq{not -d 'a/b/c' $^X @{[__FILE__]}});

eval {
    $mkpath = mkpath('a/b/c');
};

ok(($mkpath >= 1), qq{mkpath('a/b/c') $^X @{[__FILE__]}});
ok((-d 'a'      ), qq{-d 'a' $^X @{[__FILE__]}});
ok((-d 'a/b'    ), qq{-d 'a/b' $^X @{[__FILE__]}});
ok((-d 'a/b/c'  ), qq{-d 'a/b/c' $^X @{[__FILE__]}});

rmdir('a a/b b/c c') if -d 'a a/b b/c c';
rmdir('a a/b b')     if -d 'a a/b b';
rmdir('a a')         if -d 'a a';
ok((not -d 'a a'        ), qq{not -d 'a a' $^X @{[__FILE__]}});
ok((not -d 'a a/b b'    ), qq{not -d 'a a/b b' $^X @{[__FILE__]}});
ok((not -d 'a a/b b/c c'), qq{not -d 'a a/b b/c c' $^X @{[__FILE__]}});

eval {
    $mkpath = mkpath('a a/b b/c c');
};

ok(($mkpath >= 1),     qq{mkpath('a a/b b/c c') $^X @{[__FILE__]}});
ok((-d 'a a'        ), qq{-d 'a a' $^X @{[__FILE__]}});
ok((-d 'a a/b b'    ), qq{-d 'a a/b b' $^X @{[__FILE__]}});
ok((-d 'a a/b b/c c'), qq{-d 'a a/b b/c c' $^X @{[__FILE__]}});

rmtree('a');
rmtree('a a');

__END__
