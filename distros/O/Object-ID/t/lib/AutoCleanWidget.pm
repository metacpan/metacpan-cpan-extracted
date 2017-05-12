package AutoCleanWidget;

# A test module for t/autoclean.t to demonstrate a class which
# uses namespace::autoclean.

use strict;
use warnings;

use namespace::autoclean;

use Object::ID;

sub new { bless {}, $_[0] }

1;
