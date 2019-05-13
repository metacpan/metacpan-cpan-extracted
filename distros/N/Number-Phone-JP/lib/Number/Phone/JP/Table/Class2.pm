package Number::Phone::JP::Table::Class2;

use strict;
use warnings;

our $VERSION = '0.20190507';

# Table last modified: 2019-05-07
our %TEL_TABLE = (
    # Pref => q<Assoc-Pref-Regex>,
    '09120'  => '\d+', # ブラステル
    '09121'  => '\d+', # ブラステル
    '09130'  => '\d+', # NTTドコモ
    '09181'  => '\d+', # 関西コムネット
    '09192'  => '\d+', # フリービット
);

1;
__END__
