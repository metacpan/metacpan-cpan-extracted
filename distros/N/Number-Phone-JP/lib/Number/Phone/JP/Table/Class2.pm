package Number::Phone::JP::Table::Class2;

use strict;
use warnings;

our $VERSION = '0.20170703';

# Table last modified: 2017-07-03
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    '09120'  => '\d+', # ブラステル
    '09121'  => '\d+', # ブラステル
    '09130'  => '\d+', # NTTドコモ
    '09155'  => '\d+', # NTT-ME
    '09156'  => '\d+', # NTT-ME
    '09181'  => '\d+', # 関西コムネット
    '09191'  => '\d+', # NTTぷらら
    '09192'  => '\d+', # NTTぷらら
);

1;
__END__
