use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..7\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my $basename = '';

eval {
    $basename = basename("/foo/bar");
};

ok(($basename eq 'bar'), qq{basename("/foo/bar") $^X @{[__FILE__]}});

eval {
    $basename = basename("/foo/bar/");
};

ok(($basename eq 'bar'), qq{basename("/foo/bar/") $^X @{[__FILE__]}});

eval {
    $basename  = basename("/foo/bar/baz.txt", ".txt");
};

ok(($basename eq 'baz'), qq{basename("/foo/bar/baz.txt", ".txt") $^X @{[__FILE__]}});

eval {
    $basename = basename('/usr/local/bin/perl.pl');
};

ok(($basename eq 'perl.pl'), qq{basename('/usr/local/bin/perl.pl') $^X @{[__FILE__]}});

if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
    eval {
        $basename = basename('/usr/local/bin/perl.pl','.pl');
    };

    ok(($basename eq 'perl'), qq{basename('/usr/local/bin/perl.pl','.pl') $^X @{[__FILE__]}});
}
else {
    ok(1, qq{SKIP basename('/usr/local/bin/perl.pl','.pl') $^X @{[__FILE__]}});
}

eval {
    $basename = basename('/usr/local/bin/perl.pl','.txt');
};

ok(($basename eq 'perl.pl'), qq{basename('/usr/local/bin/perl.pl','.txt') $^X @{[__FILE__]}});

if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
    eval {
        $basename = basename('/usr/lo c al/bin/pe rl.p l','.p l');
    };

    ok(($basename eq 'pe rl'), qq{basename('/usr/lo c al/bin/pe rl.p l','.p l') $^X @{[__FILE__]}});
}
else {
    ok(1, qq{SKIP basename('/usr/lo c al/bin/pe rl.p l','.p l') $^X @{[__FILE__]}});
}

__END__
