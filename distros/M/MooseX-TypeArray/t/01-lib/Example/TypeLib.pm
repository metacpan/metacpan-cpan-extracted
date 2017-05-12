use strict;
use warnings;

package Example::TypeLib;

use Moose::Util::TypeConstraints;
use MooseX::TypeArray;

subtype 'Natural', as 'Int', where { $_ > 0 }, message { "This number ( $_ ) is not bigger than 0" };

subtype 'BiggerThanTen', as 'Int', where { $_ > 10 }, message { "This number ( $_ ) is not bigger than ten!" };

typearray 'NaturalAndBiggerThanTen' => [ 'Natural', 'BiggerThanTen' ];

no Moose::Util::TypeConstraints;
no MooseX::TypeArray;

1;

