package Number::Phone::JP::Table::Upt;

use strict;
use warnings;
require Number::Phone::JP::Table::Fmc;

our $VERSION = '0.20190507';

no warnings 'once';
our %TEL_TABLE = %Number::Phone::JP::Table::Fmc::TEL_TABLE;

1;
__END__
