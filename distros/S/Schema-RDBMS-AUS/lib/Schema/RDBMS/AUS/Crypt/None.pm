#!perl

package Schema::RDBMS::AUS::Crypt::None;

use strict;
use warnings;

return 1;

sub crypt {
    return $_[1];
}
