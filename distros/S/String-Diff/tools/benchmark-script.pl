use strict;
use warnings;
use lib 'lib';
use String::Diff qw(diff);

my $old = join '', qw(ji ;hgiugsd ;hjlhseug gr;e:a guysag:f :ojigsy :dkaue:dii) x 16;
my $new = join '', qw(jifehiugg phrg:sgu :krhf:soi kfnjsyi :tjigsdhf gyrugs) x 16;
for (1..32) {
    diff($old, $new)
}

__END__

$ STRING_DIFF_PP=0 time perl tools/benchmark-script.pl 
        8.63 real         8.54 user         0.03 sys
$ STRING_DIFF_PP=1 time perl tools/benchmark-script.pl 
        8.56 real         8.49 user         0.02 sys
