#-*-perl-*-
use Test; plan tests => 12;
use ObjStore ':ADV';
use lib "./t";
use test;

my $undef = undef;

&open_db;
begin 'update', sub {
    my $john = $db->root('John');
    my $john_copy = $db->root('John');

    $john->{a} = [];
    $john->{h} = {};

    ok $john;
    ok !$john, '';
    ok $john == $undef, '';
    ok $john != $undef;
    ok $john == $john_copy;
    ok "$john" eq "$john_copy";

    my $mem = sprintf "%s=%s(0x%x)", ref($john), reftype($john), 0+$john;
    ok "$john", $mem;
    my $v = 10;
    $v += $john;
    ok $v, 10+$john;

    my @fun = grep(ref, values %$john);
    ok(@fun > 2);
    my ($a,$b) = @fun;
    ok($a != $b);
    ok("$a" ne "$b");
};
die if $@;
