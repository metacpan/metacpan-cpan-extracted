#Test the Kwalitee of the distribution

use strict;
use warnings;
use Test::More;

#do evaluation
eval { require Test::Kwalitee; Test::Kwalitee->import() };
