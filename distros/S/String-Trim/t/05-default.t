use strict;
use warnings;
use Test::More 0.88;
use String::Trim;

my $trimmed;
my $untrimmed;
my $tests = 0;
while(<DATA>) {
    $untrimmed .= $_;
    trim;
    $trimmed .= $_;
    unlike($_, qr{^\s|\s$}, "trimmed line $tests OK");
    $tests++;
}
isnt($trimmed, $untrimmed, 'trim has some effect');
$tests++;
is($trimmed, 'onetwothreefour', 'trims $_ ok');
$tests++;

done_testing($tests);


__DATA__
 one
two   

three 
 four