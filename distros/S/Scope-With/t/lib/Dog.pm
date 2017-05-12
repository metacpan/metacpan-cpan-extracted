package Dog;

use strict;
use warnings;

sub new      { bless {}, $_[0] }
sub bark     { 'woof!' }
sub wag_tail { '*wags tail*' }
sub yawn     { 'yawn!' }

1;
