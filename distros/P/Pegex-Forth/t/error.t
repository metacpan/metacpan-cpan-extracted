use lib -e 't' ? 't' : 'test';
use TestPegexForth;

test_err 'x3 4 .', "Undefined word: 'x3'", 'Undefined word';
test_err '2 0 /', "Division by zero", 'Division by zero';
test_err '.', "Stack underflow", 'Stack underflow';
