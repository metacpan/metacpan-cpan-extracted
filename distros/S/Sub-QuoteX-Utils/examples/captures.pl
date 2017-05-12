use strict;
use warnings;

use Sub::Quote;

my $sound = 'woof';

my $emit = quote_sub( q{ print "$sound\n" }, { '$sound' => \$sound } );

&$emit; # woof

$sound = 'meow';

&$emit; # woof

