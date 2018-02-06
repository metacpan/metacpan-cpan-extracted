package Number::Phone::JP::Table::United;

use strict;
use warnings;

our $VERSION = '0.20180202';

# Table last modified: 2018-02-02
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    570 => '(?:(?:5(?:7[0-2]|5[05])|1(?:11|20)|2(?:00|22)|3(?:00|33)|7(?:77|83)|88[128]|9[19]9|0\d{2}|666)\d{3})',
);

1;
__END__
