use 5.00503;
use strict;
use Test::Simply tests => 9;
use Modern::Open;

my $rc = 0;

$rc = open(FILE,"$0");
ok($rc, q{open(FILE,"$0")});
if ($rc) {
    close(FILE);
}

$rc = open(FILE,"< $0");
ok($rc, q{open(FILE,"< $0")});
if ($rc) {
    close(FILE);
}

$rc = open(FILE,"> $0.wr");
ok($rc, q{open(FILE,"> $0.wr")});
if ($rc) {
    close(FILE);
}

$rc = open(FILE,">> $0.wr");
ok($rc, q{open(FILE,">> $0.wr")});
if ($rc) {
    close(FILE);
}

$rc = open(FILE,"+< $0.wr");
ok($rc, q{open(FILE,"+< $0.wr")});
if ($rc) {
    close(FILE);
}

$rc = open(FILE,"+> $0.wr");
ok($rc, q{open(FILE,"+> $0.wr")});
if ($rc) {
    close(FILE);
}

$rc = open(FILE,"+>> $0.wr");
ok($rc, q{open(FILE,"+>> $0.wr")});
if ($rc) {
    close(FILE);
}

$rc = open(FILE,qq{| $^X -e "1"});
ok($rc, q{open(FILE,qq{| $^X -e "1"}});
if ($rc) {
    close(FILE);
}

$rc = open(FILE,qq{$^X -e "1" |});
ok($rc, q{open(FILE,qq{$^X -e "1" |}});
if ($rc) {
    close(FILE);
}

END {
    unlink("$0.wr");
}

__END__
