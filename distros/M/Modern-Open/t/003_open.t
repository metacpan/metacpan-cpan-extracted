use 5.00503;
use strict;
use Test::Simply tests => 9;
use Modern::Open;

my $rc = 0;

$rc = open(my $fh1,"$0");
ok($rc, q{open(my $fh1,"$0")});
if ($rc) {
    close($fh1);
}

$rc = open(my $fh2,"< $0");
ok($rc, q{open(my $fh2,"< $0")});
if ($rc) {
    close($fh2);
}

$rc = open(my $fh3,"> $0.wr");
ok($rc, q{open(my $fh3,"> $0.wr")});
if ($rc) {
    close($fh3);
}

$rc = open(my $fh4,">> $0.wr");
ok($rc, q{open(my $fh4,">> $0.wr")});
if ($rc) {
    close($fh4);
}

$rc = open(my $fh5,"+< $0.wr");
ok($rc, q{open(my $fh5,"+< $0.wr")});
if ($rc) {
    close($fh5);
}

$rc = open(my $fh6,"+> $0.wr");
ok($rc, q{open(my $fh6,"+> $0.wr")});
if ($rc) {
    close($fh6);
}

$rc = open(my $fh7,"+>> $0.wr");
ok($rc, q{open(my $fh7,"+>> $0.wr")});
if ($rc) {
    close($fh7);
}

$rc = open(my $fh8,qq{| $^X -e "1"});
ok($rc, q{open(my $fh8,qq{| $^X -e "1"}});
if ($rc) {
    close($fh8);
}

$rc = open(my $fh9,qq{$^X -e "1" |});
ok($rc, q{open(my $fh9,qq{$^X -e "1" |}});
if ($rc) {
    close($fh9);
}

END {
    unlink("$0.wr");
}

__END__
