use 5.00503;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { $|=1; print "1..12\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}
use Stable::Module;

my @fileparse = '';

eval {
    @fileparse = fileparse('/usr/loソal/bin/perl.pl');
};

ok(($fileparse[0] eq 'perl.pl'),          qq{(fileparse('/usr/loソal/bin/perl.pl'))[0] $^X @{[__FILE__]}});
ok(($fileparse[1] eq '/usr/loソal/bin/'), qq{(fileparse('/usr/loソal/bin/perl.pl'))[1] $^X @{[__FILE__]}});
ok(((not defined($fileparse[2])) or ($fileparse[2] eq '')), qq{(fileparse('/usr/loソal/bin/perl.pl'))[2] $^X @{[__FILE__]}});

eval {
    @fileparse = fileparse('/usr/loソal/bin/perl.pl','.pl');
};

ok(($fileparse[0] eq 'perl'),             qq{(fileparse('/usr/loソal/bin/perl.pl','.pl'))[0] $^X @{[__FILE__]}});
ok(($fileparse[1] eq '/usr/loソal/bin/'), qq{(fileparse('/usr/loソal/bin/perl.pl','.pl'))[1] $^X @{[__FILE__]}});
ok(($fileparse[2] eq '.pl'),              qq{(fileparse('/usr/loソal/bin/perl.pl','.pl'))[2] $^X @{[__FILE__]}});

eval {
    @fileparse = fileparse('/usr/loソal/bin/perl.pl','.txt');
};

ok(($fileparse[0] eq 'perl.pl'),          qq{(fileparse('/usr/loソal/bin/perl.pl','.txt'))[0] $^X @{[__FILE__]}});
ok(($fileparse[1] eq '/usr/loソal/bin/'), qq{(fileparse('/usr/loソal/bin/perl.pl','.txt'))[1] $^X @{[__FILE__]}});
ok(($fileparse[2] eq ''),                 qq{(fileparse('/usr/loソal/bin/perl.pl','.txt'))[2] $^X @{[__FILE__]}});

eval {
    @fileparse = fileparse('/usr/lo ソ al/bin/pソ rl.p l','.p l');
};

ok(($fileparse[0] eq 'pソ rl'),             qq{(fileparse('/usr/lo ソ al/bin/pソ rl.p l','.p l'))[0] $^X @{[__FILE__]}});
ok(($fileparse[1] eq '/usr/lo ソ al/bin/'), qq{(fileparse('/usr/lo ソ al/bin/pソ rl.p l','.p l'))[1] $^X @{[__FILE__]}});
ok(($fileparse[2] eq '.p l'),               qq{(fileparse('/usr/lo ソ al/bin/pソ rl.p l','.p l'))[2] $^X @{[__FILE__]}});

__END__
