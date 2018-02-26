use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..21\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my @fileparse = '';

eval {
    @fileparse = fileparse("/foo/bar/baz");
};

ok(($fileparse[0] eq 'baz'),       qq{(fileparse("/foo/bar/baz"))[0] $^X @{[__FILE__]}});
ok(($fileparse[1] eq '/foo/bar/'), qq{(fileparse("/foo/bar/baz"))[1] $^X @{[__FILE__]}});
ok((defined($fileparse[2]) or ($fileparse[2] eq '')), qq{(fileparse("/foo/bar/baz"))[2] $^X @{[__FILE__]}});

if ($^O =~ m{\A (?:MSWin32|NetWare|symbian|dos) \z}oxms) {
    eval {
        @fileparse = fileparse('C:\foo\bar\baz');
    };

    ok(($fileparse[0] eq 'baz'),          qq{(fileparse('C:\\foo\\bar\\baz'))[0] $^X @{[__FILE__]}});
    ok(($fileparse[1] eq 'C:\foo\bar\\'), qq{(fileparse('C:\\foo\\bar\\baz'))[1] $^X @{[__FILE__]}});
    ok((defined($fileparse[2]) or ($fileparse[2] eq '')), qq{(fileparse('C:\\foo\\bar\\baz'))[2] $^X @{[__FILE__]}});
}
else {
    ok(1, qq{SKIP $^X @{[__FILE__]}});
    ok(1, qq{SKIP $^X @{[__FILE__]}});
    ok(1, qq{SKIP $^X @{[__FILE__]}});
}

eval {
    @fileparse = fileparse('/foo/bar/baz/');
};

ok(($fileparse[0] eq ''),              qq{(fileparse('/foo/bar/baz/'))[0] $^X @{[__FILE__]}});
ok(($fileparse[1] eq '/foo/bar/baz/'), qq{(fileparse('/foo/bar/baz/'))[1] $^X @{[__FILE__]}});
ok((defined($fileparse[2]) or ($fileparse[2] eq '')), qq{(fileparse('/foo/bar/baz/'))[2] $^X @{[__FILE__]}});

eval {
    @fileparse = fileparse('/usr/local/bin/perl.pl');
};

ok(($fileparse[0] eq 'perl.pl'),         qq{(fileparse('/usr/local/bin/perl.pl'))[0] $^X @{[__FILE__]}});
ok(($fileparse[1] eq '/usr/local/bin/'), qq{(fileparse('/usr/local/bin/perl.pl'))[1] $^X @{[__FILE__]}});
ok(((not defined($fileparse[2])) or ($fileparse[2] eq '')), qq{(fileparse('/usr/local/bin/perl.pl'))[2] $^X @{[__FILE__]}});

eval {
    @fileparse = fileparse('/usr/local/bin/perl.pl','.pl');
};

ok(($fileparse[0] eq 'perl'),            qq{(fileparse('/usr/local/bin/perl.pl','.pl'))[0] $^X @{[__FILE__]}});
ok(($fileparse[1] eq '/usr/local/bin/'), qq{(fileparse('/usr/local/bin/perl.pl','.pl'))[1] $^X @{[__FILE__]}});
ok(($fileparse[2] eq '.pl'),             qq{(fileparse('/usr/local/bin/perl.pl','.pl'))[2] $^X @{[__FILE__]}});

eval {
    @fileparse = fileparse('/usr/local/bin/perl.pl','.txt');
};

ok(($fileparse[0] eq 'perl.pl'),         qq{(fileparse('/usr/local/bin/perl.pl','.txt'))[0] $^X @{[__FILE__]}});
ok(($fileparse[1] eq '/usr/local/bin/'), qq{(fileparse('/usr/local/bin/perl.pl','.txt'))[1] $^X @{[__FILE__]}});
ok(($fileparse[2] eq ''),                qq{(fileparse('/usr/local/bin/perl.pl','.txt'))[2] $^X @{[__FILE__]}});

eval {
    @fileparse = fileparse('/usr/lo c al/bin/pe rl.p l','.p l');
};

ok(($fileparse[0] eq 'pe rl'),             qq{(fileparse('/usr/lo c al/bin/pe rl.p l','.p l'))[0] $^X @{[__FILE__]}});
ok(($fileparse[1] eq '/usr/lo c al/bin/'), qq{(fileparse('/usr/lo c al/bin/pe rl.p l','.p l'))[1] $^X @{[__FILE__]}});
ok(($fileparse[2] eq '.p l'),              qq{(fileparse('/usr/lo c al/bin/pe rl.p l','.p l'))[2] $^X @{[__FILE__]}});

__END__
