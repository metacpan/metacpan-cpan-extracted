use strict;
use Test::More tests => 7;

BEGIN { use_ok('PerlIO::unicodeeol'); }

binmode STDOUT, "utf8";

# Test without utf-8
{
    binmode DATA, ':raw:unicodeeol';
    is <DATA>, "Line 1\n", "Line 1 - matched";
    is <DATA>, "Line 2\n", "Line 2 - matched";
    is <DATA>, "Line 3\n", "Line 3 - matched";
    is <DATA>, "Line 4\xc2\x85Line 5\xc2\x86\n", "Line 4+5 - matched";
    is <DATA>, "Line 6\xe2\x80\xa8Line 7\xe2\x80\xa9Line 8\xe2\x81\n", "Line 6+7+8 - matched";
    is <DATA>, "Line 9\xe2\x80\xaa\n", "Line 9 - matched";
    close DATA;
}

__DATA__
Line 1
Line 2
Line 3Line 4Line 5
Line 6 Line 7 Line 8�
Line 9‪
