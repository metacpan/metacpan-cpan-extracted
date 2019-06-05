package Number::Phone::JP::Table::United;

use strict;
use warnings;

our $VERSION = '0.20190521';

# Table last modified: 2019-05-21
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    570 => '(?:(?:5(?:7[0-2]|50)|9(?:[19]9|43)|88[128]|[23]00|0\d{2}|666|783)\d{3})',
);

1;
__END__
