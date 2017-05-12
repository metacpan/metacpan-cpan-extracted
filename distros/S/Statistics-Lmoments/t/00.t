use strict;
use Statistics::Lmoments qw(:all);
use Test::More tests => 42;

# todo: recreate the tests in lmoments

my @x = (81,95,62,118,106,82,70,228,112,125,
	 120,142,80,83,46,109,61,81,93,97,76,
	 100,106,90,61,147,101,85,79,69,81,112,
	 85,87,41,94,82,90,62,69,115,80,51);

@x = sort {$a<=>$b} @x;

my @data;
while (<DATA>) {
    chomp;
    s/^\s+//;
    my @l = split /\s+/;
    push @data, \@l;
}

my $xmom;

#for ('lmr','lmu','pwm') {
for ('lmu') {
    $xmom = &Statistics::Lmoments::sam($_,\@x, 5);
    round2($xmom);
    my $l = shift @data;
    #print STDERR "@$xmom\n";
    ok(is_deeply($xmom, $l), "sam @$xmom, @$l");
}

foreach (@Statistics::Lmoments::distributions) {
    next if /^KAP/;
    my $l = shift @data;
    #print STDERR "$l->[0]\n";
    ok($_ eq $l->[0], "$_ $l->[0]");
    my $para = &Statistics::Lmoments::pel($_,$xmom);
    round2($para);
    $l = shift @data;
    #print STDERR "@$para\n";
    ok(is_deeply($para,$l), "$_ @$para, @$l");
    my $x = 100;
    my $F = &Statistics::Lmoments::cdf($_,$x,$para);
    $F = round2($F);
    $l = shift @data;
    #print STDERR "$F\n";
    ok($F == $l->[0], "cdf $F, $l->[0]");
}

sub round2 {
    my $list = shift;
    if (ref $list) {
        for (@$list) {
            $_ = sprintf("%.2f", $_);
        }
    } else {
        return sprintf("%.2f", $list);
    }
}

__DATA__
91.95 16.00 0.19 0.26 0.12
EXP
59.95 32.00
0.71
GAM
10.26 8.96
0.65
GEV
78.31 22.41 -0.03
0.68
GLO
87.04 15.07 -0.19
0.69
GNO
86.53 26.60 -0.39
0.68
GPA
54.17 51.43 0.36
0.66
GUM
78.63 23.08
0.67
NOR
91.95 28.36
0.61
PE3
91.95 29.55 1.15
0.67
WAK
37.43 241.12 6.16 15.73 0.25
0.72
