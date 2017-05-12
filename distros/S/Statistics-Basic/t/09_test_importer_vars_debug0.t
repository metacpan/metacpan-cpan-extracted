
use t::locale_hack;
use Test;
use Statistics::Basic qw(:all debug=0);

plan tests => 1;

my $warn = 0;
$SIG{__WARN__} = sub {
    $warn++ if $_[0] =~ m/recalc_needed Statistics::Basic::Mean/;
};

my $mean = mean(1,2,3);

ok( $warn, 0 )
