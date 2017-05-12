use strict;
use warnings;
use lib 'lib';

use Perl6::Str;
binmode STDOUT, ':encoding(UTF-8)';
use charnames qw(:full);

print "This script prints out UTF-8.\n";
print "If your console can't handle that, please edit this file to use\n";
print "the appropriate encoding. Note that it will only work for Unicode encodings\n\n";

my $s1 = "\N{LATIN SMALL LETTER A WITH DIAERESIS}";
my $s2 = "a\N{COMBINING DIAERESIS}";

# $s1 and $s2 are visually the same if printed
print "$s1, $s2\n";

# but in Perl 5, they behave quite differently:
printf "Lengths: %d, %d\n", length($s1), length($s2);
if ($s1 ne $s2) {
    print "Perl 5 thinks they are different\n";
}

$s1 = Perl6::Str->new($s1);
$s2 = Perl6::Str->new($s2);

# let's try again:
print "\nNow with Perl6::Str\n";
printf "Lengths: %d, %d\n", $s1->graphs, $s2->graphs;
if ($s1 eq $s2) {
    print "Perl6::Str says they're the same\n";
}
