use lib 'lib';

$\ = "\n"; $, = "\t";

use String::SQLColumnName qw/fix_ordinal fix_number fix_names/;

print fix_ordinal('1st');

print fix_ordinal('2nd');

print fix_ordinal('3rd and 4th');

print fix_ordinal('4th');

print fix_ordinal('3th');

print fix_number('33ist');

print fix_number('44 wives');

print String::SQLColumnName::fix_chars('one : two');
