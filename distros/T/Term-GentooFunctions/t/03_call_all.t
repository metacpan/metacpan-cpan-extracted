
use Test;
use Term::GentooFunctions qw(:all);

plan tests => 1;

my $r = eval {
    ebegin "test";
    eindent;
        ebegin "test";
        einfo "test";
        ewarn "test";
        eend 1;
    eoutdent;
    eend 1;
};
ok($r);
