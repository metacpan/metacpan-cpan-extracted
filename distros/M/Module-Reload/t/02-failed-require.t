#! perl

#
# 02-failed-require.t
#
# If you require a file and the loading fails,
# then you end up with the path to the file
# as a key in %INC, but the value will be undef.
# That used to cause a bunch of warnings about
# uninitialised value from Module::Reload,
# but now doesn't.
#
# This test confirms that.

use strict;
use warnings;
use Test::More tests => 1;
use lib '.';
use Module::Reload;

our @warnings;

local $SIG{__WARN__} = sub {
    my $message = shift;
    push(@warnings, $message);
};

eval {
    require 't/lib/Broken.pm';
};

Module::Reload->check;

ok(int(@warnings) == 0, "Shouldn't be any warnings");
