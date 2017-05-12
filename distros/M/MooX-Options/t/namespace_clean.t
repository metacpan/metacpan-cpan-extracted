#!perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use t::Test;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

use_ok 'TestNamespaceClean';

ok TestNamespaceClean->new, 'TestNamespaceClean is a package';

{
    local @ARGV = ( '--foo', '12' );
    my $i = TestNamespaceClean->new_with_options;
    is $i->foo, 12, 'value save properly';
}

done_testing;

