use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..12\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my $basename = '';

eval {
    $basename = basename('/usr/loソal/bin/perl.pl');
};

ok(($basename eq 'perl.pl'), qq{basename('/usr/loソal/bin/perl.pl') $^X @{[__FILE__]}});

if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
    eval {
        $basename = basename('/usr/loソal/bin/perl.pl','.pl');
    };

    ok(($basename eq 'perl'), qq{basename('/usr/loソal/bin/perl.pl','.pl') $^X @{[__FILE__]}});
}
else {
    ok(1, qq{SKIP basename('/usr/loソal/bin/perl.pl','.pl') $^X @{[__FILE__]}});
}

eval {
    $basename = basename('/usr/loソal/bin/perl.pl','.txt');
};

ok(($basename eq 'perl.pl'), qq{basename('/usr/loソal/bin/perl.pl','.txt') $^X @{[__FILE__]}});

if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
    eval {
        $basename = basename('/usr/lo ソ al/bin/pe rl.p l','.p l');
    };

    ok(($basename eq 'pe rl'), qq{basename('/usr/lo ソ al/bin/pe rl.p l','.p l') $^X @{[__FILE__]}});
}
else {
    ok(1, qq{SKIP basename('/usr/lo ソ al/bin/pe rl.p l','.p l') $^X @{[__FILE__]}});
}

eval {
    $basename = basename('/usr/loソal/bin/pソrl.pl');
};

ok(($basename eq 'pソrl.pl'), qq{basename('/usr/loソal/bin/pソrl.pl') $^X @{[__FILE__]}});

if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
    eval {
        $basename = basename('/usr/loソal/bin/pソrl.pl','.pl');
    };

    ok(($basename eq 'pソrl'), qq{basename('/usr/loソal/bin/pソrl.pl','.pl') $^X @{[__FILE__]}});
}
else {
    ok(1, qq{SKIP basename('/usr/loソal/bin/pソrl.pl','.pl') $^X @{[__FILE__]}});
}

eval {
    $basename = basename('/usr/loソal/bin/pソrl.pl','.txt');
};

ok(($basename eq 'pソrl.pl'), qq{basename('/usr/loソal/bin/pソrl.pl','.txt') $^X @{[__FILE__]}});

if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
    eval {
        $basename = basename('/usr/lo ソ al/bin/pソ rl.p l','.p l');
    };

    ok(($basename eq 'pソ rl'), qq{basename('/usr/lo ソ al/bin/pソ rl.p l','.p l') $^X @{[__FILE__]}});
}
else {
    ok(1, qq{SKIP basename('/usr/lo ソ al/bin/pソ rl.p l','.p l') $^X @{[__FILE__]}});
}

eval {
    $basename = basename('/usr/loソal/bin/pソrl.pソ');
};

ok(($basename eq 'pソrl.pソ'), qq{basename('/usr/loソal/bin/pソrl.pソ') $^X @{[__FILE__]}});

if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
    eval {
        $basename = basename('/usr/loソal/bin/pソrl.pソ','.pソ');
    };

    ok(($basename eq 'pソrl'), qq{basename('/usr/loソal/bin/pソrl.pソ','.pソ') $^X @{[__FILE__]}});
}
else {
    ok(1, qq{SKIP basename('/usr/loソal/bin/pソrl.pソ','.pソ') $^X @{[__FILE__]}});
}

eval {
    $basename = basename('/usr/loソal/bin/pソrl.pソ','.txソ');
};

ok(($basename eq 'pソrl.pソ'), qq{basename('/usr/loソal/bin/pソrl.pソ','.txソ') $^X @{[__FILE__]}});

if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
    eval {
        $basename = basename('/usr/lo ソ al/bin/pソ rl.p ソ','.p ソ');
    };

    ok(($basename eq 'pソ rl'), qq{basename('/usr/lo ソ al/bin/pソ rl.p ソ','.p ソ') $^X @{[__FILE__]}});
}
else {
    ok(1, qq{SKIP basename('/usr/lo ソ al/bin/pソ rl.p ソ','.p ソ') $^X @{[__FILE__]}});
}

__END__
