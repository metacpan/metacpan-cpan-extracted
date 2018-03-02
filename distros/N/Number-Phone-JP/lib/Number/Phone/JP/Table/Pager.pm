package Number::Phone::JP::Table::Pager;

use strict;
use warnings;

our $VERSION = '0.20180301';

# Table last modified: 2018-03-01
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    20 => '(?:46\d{6})',
);

1;
__END__
