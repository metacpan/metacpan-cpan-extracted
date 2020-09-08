use 5.00503;
use strict;
BEGIN { $|=1; print "1..9\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl7::Handy;

close(STDERR);

my $rc = 0;

eval { $rc = open(FILE,"$0"); };
ok($@, q{open(FILE,"$0")});
if ($rc) {
    close(FILE);
}

eval { $rc = open(FILE,"< $0"); };
ok($@, q{open(FILE,"< $0")});
if ($rc) {
    close(FILE);
}

eval { $rc = open(FILE,"> $0.wr"); };
ok($@, q{open(FILE,"> $0.wr")});
if ($rc) {
    close(FILE);
}

eval { $rc = open(FILE,">> $0.wr"); };
ok($@, q{open(FILE,">> $0.wr")});
if ($rc) {
    close(FILE);
}

eval { $rc = open(FILE,"+< $0.wr"); };
ok($@, q{open(FILE,"+< $0.wr")});
if ($rc) {
    close(FILE);
}

eval { $rc = open(FILE,"+> $0.wr"); };
ok($@, q{open(FILE,"+> $0.wr")});
if ($rc) {
    close(FILE);
}

eval { $rc = open(FILE,"+>> $0.wr"); };
ok($@, q{open(FILE,"+>> $0.wr")});
if ($rc) {
    close(FILE);
}

eval { $rc = open(FILE,qq{| $^X -e "1"}); };
ok($@, q{open(FILE,qq{| $^X -e "1"}});
if ($rc) {
    close(FILE);
}

eval { $rc = open(FILE,qq{$^X -e "1" |}); };
ok($@, q{open(FILE,qq{$^X -e "1" |}});
if ($rc) {
    close(FILE);
}

END {
    unlink("$0.wr");
}

__END__
