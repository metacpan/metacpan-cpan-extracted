
use t::locale_hack;
use Test;
use Statistics::Basic qw(:all debug);

plan tests => 1;

$SIG{__WARN__} = sub {
    ok(1) if $_[0] =~ m/recalc_needed Statistics::Basic::Mean/;
};

my $mean = mean(1,2,3);
