use 5.012;
use strict;
use warnings;
use Acme::MetaSyntactic;

foreach my $tang ( metaname('legopiratesofthecaribbean',1000) ) {
    my $len = length($tang);
    $len = 12 if $len > 12;
    my $chan = lc substr $tang, 0, $len;
    $chan =~ s!^mr_!!;
    $chan =~ s!_!!g;
    $chan = "#$chan";
    say $chan;
}
