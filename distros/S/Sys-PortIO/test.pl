# ========================================================================
# test.pl - minimal regression tests for this library
# Andrew Ho (andrew@tellme.com)
#
# Copyright (C) 2005 by Andrew Ho.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.6.0 or,
# at your option, any later version of Perl 5 you may have available.
#
# $Id: test.pl,v 1.1 2005/02/26 05:19:30 andrew Exp $
# ========================================================================

require 5.006;
use warnings;
use strict;

if($ENV{SUBTEST}) {
    require Test;
    Test::plan(tests => 1);
    my $retval = eval { require Sys::PortIO };
    Test::ok($retval && !$@);
} else {
    require Test::Harness;
    $ENV{SUBTEST} = 1;
    Test::Harness::runtests($0);
}

exit 0;


# ========================================================================
__END__
