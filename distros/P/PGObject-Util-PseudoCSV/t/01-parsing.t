use Test::More tests => 20;

use PGObject::Util::PseudoCSV;

# plain forms
my $simpletuple = '(a,b,",")';
my $simplearray = '{a,b,","}';

# nulls
my $nulltuple = '(a,b,",",NULL)';
my $nullarray = '{a,b,",",NULL}';

# nested tests
my $nestedtuple = '(a,b,",","(1,a)")';
my $nestedarray = '{{a,b},{1,a}}';
my $tuplewitharray = '(a,b,",","{1,a}")';
my $arrayoftuples = '{"(a,b)","(1,a)"}';

# Newline tests
my $newlinetuple = qq|(a,b,",\n")|;
my $newlinearray = qq|{a,b,",\n"}|;

my $valarray;
my $hashref;

# Simple tuple tests to array
ok ($valarray = pseudocsv_parse($simpletuple, 'test'), 
      'Parse success, simple tuple');
is_deeply($valarray, ['a', 'b', ','], 'Parse correct, simple tuple');

# Simple array parse
ok ($valarray = pseudocsv_parse($simplearray, 'test'), 
      'Parse success, simple array');
is_deeply($valarray, ['a', 'b', ','], 'Parse correct, simple array');

# Null tuple
ok ($valarray = pseudocsv_parse($nulltuple, 'test'), 
      'Parse success, simple tuple');
is_deeply($valarray, ['a', 'b', ',', undef], 'Parse correct, simple tuple');

ok($hashref = pcsv2hash($nulltuple, 'a', 'b', 'c', 'd'), 'parsed null tuple to hashref');

is_deeply($hashref, {a => 'a', b => 'b', c => ',', d => undef }, 
      'hashref correct from null tuple');

# Null array
ok ($valarray = pseudocsv_parse($nullarray, 'test'), 
      'Parse success, simple array');
is_deeply($valarray, ['a', 'b', ',', undef], 'Parse correct, simple array');

# Nested tuple
ok ($valarray = pseudocsv_parse($nestedtuple, 'test'),
      'Parse success, nested tuple');
is_deeply($valarray, ['a', 'b', ',', '(1,a)'], 'Parse correct, simple array');

# Tuple with array
ok ($valarray = pseudocsv_parse($tuplewitharray, 'test'),
      'Parse success, tuple with array member');
is_deeply($valarray, ['a', 'b', ',', [1, 'a']], 'Parse correct, tuple with array');

# Array of tuples
ok ($valarray = pseudocsv_parse($arrayoftuples, 'test'),
      'Parse success, tuple with array of tuples');
is_deeply($valarray, ['(a,b)','(1,a)'], 'Parse correct, array of tuples');

# New line tuple
ok ($valarray = pseudocsv_parse($newlinetuple, 'test'),
      'Parse success, tuple with array of tuples');
is_deeply($valarray, ['a', 'b', ",\n"], 'Parse correct, array of tuples');

# New line array
ok ($valarray = pseudocsv_parse($newlinearray, 'test'),
      'Parse success, tuple with array of tuples');
is_deeply($valarray, ['a', 'b', ",\n"], 'Parse correct, array of tuples');

