use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../";
use Test::More;
use t::scan::Util;

test(<<'END');
use MooseX::Declare;

class dongs
{
}

class mtfnpy extends dongs
{
}
END

done_testing;
