use t::locale_hack;
use strict;
use Test;
use Statistics::Basic qw(:all toler=0.05);

plan tests => 2;

my $warning = 0;
$SIG{__WARN__} = sub { warn "\n\e[1;33mWARNING DETECTED: @_\e[m\n"; $warning ++ };

# perl -e 'print "    ", rand($_), "\n" for 1 .. 10'
my @rand = (qw(
    0.728712105731578
    0.352966697601858
    2.89744693355025
    0.100965906294533
    2.6368492231135
    5.30772892749511
    4.98230531045954
    2.73849156345449
    2.27253176264066
    0.349800238043372
));

my $v1 = vector(1 .. 10);
my $v2 = computed($v1)->set_filter(sub {
    map {$_ + 0.5 * (shift @rand)} @_
});

my $corr = cor( $v1, $v2 );

ok( $corr == 1  ) or warn "\n\$corr=$corr\n";
ok( $warning, 0 );
