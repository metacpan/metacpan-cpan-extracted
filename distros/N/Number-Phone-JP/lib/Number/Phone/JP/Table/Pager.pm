package Number::Phone::JP::Table::Pager;

use strict;
use warnings;

our $VERSION = '0.20170601';

# Table last modified: 2017-06-01
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    20 => '(?:4(?:9[29]|6\d)\d{5})',
);

1;
__END__
