use warnings FATAL => 'all';
use strict;

use Test::More tests => 9;

use Quote::Code ();

is eval('qc]1]'), undef;
like $@, qr/Number found where operator expected|\bsyntax error\b/;

{
    use Quote::Code;
    is qc]1], '1';
}

is eval('qc]1]'), undef;
like $@, qr/Number found where operator expected|\bsyntax error\b/;

use Quote::Code;
is qc]1], '1';

{
    no Quote::Code;
    is eval('qc]1]'), undef;
    like $@, qr/Number found where operator expected|\bsyntax error\b/;
}

is qc]1], '1';
