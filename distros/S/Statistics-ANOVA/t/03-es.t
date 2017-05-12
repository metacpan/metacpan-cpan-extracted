use strict;
use warnings;
use Test::More tests => 2;
use constant EPS     => 1e-9;

BEGIN { use_ok('Statistics::ANOVA') }

my @d1 = ( 9, 7, 8, 9, 8, 9, 9, 10, 9, 9 );
my @d2 = ( 9, 6, 7, 8, 7, 9, 8, 8, 8, 7 );
my $anova = Statistics::ANOVA->new();    
$anova->load({d1 => \@d1, d2 => \@d2});
my $ss_w;
eval {$ss_w = $anova->ss_w(name => [qw/d1 d2/], independent => 0);};
ok( !$@, $@ );
# not ok:
$anova->load(d1 => \@d1, d2 => \@d2);
#while (my($key, $val) = each %{$anova->{_DATA}}) {
#    diag("self $key = $val\n");
#}
#$ss_w = $anova->ss_w(name => [qw/d1 d2/], independent => 0); #