use lib '../lib lib';

use String::SQLColumnName qw/fix_ordinal fix_number fix_names/;

$\ = "\n"; $, = "\t";


# $String::SQLColumnName::camelize++;

while (<>) {
    chop;
    print $_, fix_name($_);
}
