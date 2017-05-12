use lib '../lib lib';

$\ = "\n"; $, = "\t";

use String::SQLColumnName qw/fix_ordinal fix_number fix_names/;

while (<>) {
    chop;
    print $_;
    print fix_names($_);
}
