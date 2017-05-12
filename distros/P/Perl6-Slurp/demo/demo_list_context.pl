use strict;
use Perl6::Slurp;

for (slurp '/usr/share/dict/words') {
    next unless /([aeiou])\1.*([aeiou])\2/;
    print;
}
