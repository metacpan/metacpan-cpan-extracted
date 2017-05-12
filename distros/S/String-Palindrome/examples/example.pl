use warnings;
use strict;

use String::Palindrome qw/ is_palindrome /;
use Data::Dumper;


my @non_palindromes = qw/
    test
    bad
/;

my @palindromes = qw/
    baddab
    blaaaaalb
    123b321
/;

my @palindrome_array     = qw/ a b c c b a /;
my @non_palindrome_array = qw/ a b c d b a /;


for  my $str  (@non_palindromes, @palindromes) {
    printf("%s is%s a palindrome\n", $str, is_palindrome($str) ? '' : ' not');
}


for  my $ref  (\@palindrome_array, \@non_palindrome_array) {
    printf("The following array_ref is%s a palindrome\n\t%s\n", is_palindrome($ref) ? '' : ' not', Dumper($ref));
    printf("The following array is%s a palindrome\n\t%s\n", is_palindrome(@$ref) ? '' : ' not', Dumper($ref));
}
