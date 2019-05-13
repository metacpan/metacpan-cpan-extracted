package Number::Phone::JP::Table::Pager;

use strict;
use warnings;

our $VERSION = '0.20190507';

# Table last modified: 2019-05-07
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    20 => '(?:46\d{6})',
);

1;
__END__
