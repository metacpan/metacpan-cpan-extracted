package Number::Phone::JP::Table::M2m;

use strict;
use warnings;

our $VERSION = '0.20190301';

# Table last modified: 2019-03-01
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    20 => '(?:(?:3(?:[0-24-6]\d|3[0-5]|7[0-2])|2(?:[0-689]\d|7[0-3])|1\d{2})\d{5})',
);

1;
__END__
