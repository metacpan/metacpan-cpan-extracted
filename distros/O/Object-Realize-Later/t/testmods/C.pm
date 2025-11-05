
use strict;
use warnings;

package C;
use overload '""' => sub { ref(shift) };

sub new() { bless {}, shift }
sub c()   { 'c' }

1;
