#!perl -w
<>;
<> =~ /^#/ || die;
my @tab;
while (<>) {
    chomp;
    my $t = [split(/,/)];
    shift(@$t);  # index
    push(@tab, $t);
    #last if @tab > 5;
}

use PerlBench::Stats qw(calc_stats);
use PerlBench::Utils qw(sec_f);

use Data::Dump;
Data::Dump::dump(\@tab);

my %base;
my @expected = (0, 1.5, 2.0, 2.5);

for my $i (0 .. @{$tab[0]}-1) {
    print "Series ", $i + 1, "\n";
    my @t = map $_->[$i], @tab;
    my $h = calc_stats(\@t);
    #Data::Dump::dump($h);
    for my $m (qw(avg med min)) {
	printf "  $m %-9.5g", $h->{$m};
	if ($base{$m}) {
	    my $p = ($h->{$m} - $base{$m}) / $base{$m} * 100;
	    printf " %5.2f%%", $p;
	    printf " %6.1f%%", ($p - $expected[$i]) / $expected[$i] * 100;
	}
	else {
	    $base{$m} = $h->{$m};
	}
        print "\n";
    }
}
