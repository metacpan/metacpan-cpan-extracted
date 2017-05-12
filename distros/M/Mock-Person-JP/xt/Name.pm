package xt::Name;

use strict;
use warnings;
use Exporter qw/import/;
our @EXPORT = qw/InMei InYomi/;
use Lingua::JA::KanjiTable;

sub InMei
{
    return <<"END";
+Lingua::JA::KanjiTable::InJoyoKanji
+Lingua::JA::KanjiTable::InJinmeiyoKanji
3005
3041\t3096
309D
309E
30A1\t30FA
30FC\t30FE
END
}

sub InYomi
{
    return <<"END";
3041\t3096
30FC
END
}

1;
