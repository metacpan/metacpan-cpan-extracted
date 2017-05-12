
use t::locale_hack;
use Test;
use Statistics::Basic qw(:all);

plan tests => 8;

$SIG{__WARN__} = sub { die " FATAL WARNING: $_[0] " };

my $v1 = vector(1,2,3,undef,4);
ok("$v1", "[1, 2, 3, _, 4]");

my $v2 = vector(1,2,3,4, undef);
ok("$v2", "[1, 2, 3, 4, _]");

my $v3 = computed($v1);
my $v4 = computed($v2);

ok("$v3", "[1, 2, 3, _, 4]");
ok("$v4", "[1, 2, 3, 4, _]");

$v3->set_filter(sub {
    my @v = $v2->query;
    map {$_[$_]} grep { defined $v[$_] and defined $_[$_] } 0 .. $#_;
});

$v4->set_filter(sub {
    my @v = $v1->query;
    map {$_[$_]} grep { defined $v[$_] and defined $_[$_] } 0 .. $#_;
});

ok("$v3", "[1, 2, 3]");
ok("$v4", "[1, 2, 3]");

my ($v5, $v6) = handle_missing_values($v1, $v2);

ok("$v5", "$v3");
ok("$v6", "$v4");
