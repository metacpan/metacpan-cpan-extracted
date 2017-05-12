package d;
use lib '.';
use f;
require g if 1;
use h qw(also test
        multiline
        imports
);
1;
