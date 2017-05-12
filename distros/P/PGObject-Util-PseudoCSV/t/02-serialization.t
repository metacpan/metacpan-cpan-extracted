use Test::More tests => 8;
use PGObject::Util::PseudoCSV;

my $proplist = ["test", '1', '3', undef, '44'];
my $nestedprops = ["test", '1', '3', ['1', '3', '4'], '44'];
my $nullstring = ["test", "null"];
my $testval;

ok ($testval = to_pseudocsv($proplist, 0), 'serialized successfully');
is $testval, '{test,1,3,NULL,44}', 'correct value for array serialization';

ok ($testval = to_pseudocsv($nestedprops, 1), 'serialized successfully');
is $testval, '(test,1,3,"{1,3,4}",44)', 'correct value for array serialization';

ok ($testval = to_pseudocsv($nullstring, 1), 'serialized successfully nulltest');
is $testval, '(test,"null")', 'correct value for array serialization';

ok ($testval = hash2pcsv({a => 1, b => 2, c => undef}, 'b', 'a', 'c'),
           'Serialized hashref');
is ($testval, '(2,1,NULL)', 'Correctly serialized hashref');
