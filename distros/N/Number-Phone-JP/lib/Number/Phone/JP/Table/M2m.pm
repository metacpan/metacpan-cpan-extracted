package Number::Phone::JP::Table::M2m;

use strict;
use warnings;

our $VERSION = '0.20190204';

# Table last modified: 2019-02-04
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    20 => '(?:(?:2(?:[0-24-689]\d|3[0-6]|7[0-3])|3(?:3[0-5]|[0-2]\d)|1\d{2})\d{5})',
);

1;
__END__
