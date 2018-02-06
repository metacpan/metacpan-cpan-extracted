package Number::Phone::JP::Table::M2m;

use strict;
use warnings;

our $VERSION = '0.20180202';

# Table last modified: 2018-02-02
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    20 => '(?:(?:2(?:3[0-6]|[0-24-6]\d|7[0-3])|1(?:[0-35-9]\d|4[0-2]))\d{5})',
);

1;
__END__
