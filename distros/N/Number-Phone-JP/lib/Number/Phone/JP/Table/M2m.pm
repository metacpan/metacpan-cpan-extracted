package Number::Phone::JP::Table::M2m;

use strict;
use warnings;

our $VERSION = '0.20190521';

# Table last modified: 2019-05-21
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    20 => '(?:(?:3(?:[0-24-689]\d|3[0-5]|7[0-4])|5(?:3[0-6]|[0-2]\d)|[12]\d{2})\d{5})',
);

1;
__END__
