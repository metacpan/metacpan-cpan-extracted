use warnings FATAL => 'all';
use strict;

use Test::More tests => 4;

use Quote::Code;

sub context {
    !defined wantarray ? 'void' :
    wantarray ? 'list' :
    'scalar'
}

is +(context)[0], 'list';
is +(qc'{context}')[0], 'scalar';
is +(qc'{context}{context}')[0], 'scalarscalar';
is +(qc'A{context}B{() = ('X', 'Y')}')[0], 'AscalarB2';
