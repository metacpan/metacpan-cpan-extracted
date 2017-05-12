use lib '../lib lib';

$\ = "\n"; $, = "\t";

use String::SQLColumnName qw/fix_ordinal fix_number fix_names/;


for (sort keys %String::SQLColumnName::rw) {
    print $_, String::SQLColumnName::fix_reserved(lc($_));
}
