use strict;
use Test::More tests => 10;

BEGIN { use_ok('PerlIO::unicodeeol'); }

binmode STDOUT, "utf8";

# Test with utf-8
{
    binmode DATA, ':raw:utf8:unicodeeol';
    is <DATA>, "Line 1\n", "Line 1 - matched";
    is <DATA>, "Line 2\n", "Line 2 - matched";
    is <DATA>, "Line 3\n", "Line 3 - matched";
    is <DATA>, "Line 4\n", "Line 4 - matched";
    is <DATA>, "Line 5\x{86}\n", "Line 5 - matched";
    is <DATA>, "Line 6\n", "Line 6 - matched";
    is <DATA>, "Line 7\n", "Line 7 - matched";
    {
        my $badstring = <DATA>;
        utf8::encode($badstring);
        is $badstring, "Line 8\xe2\x81\n", "Line 8 - matched";
    }
    is <DATA>, "Line 9\x{202a}\n", "Line 9 - matched";
    close DATA;
}

__DATA__
Line 1
Line 2
Line 3Line 4Line 5
Line 6 Line 7 Line 8�
Line 9‪
