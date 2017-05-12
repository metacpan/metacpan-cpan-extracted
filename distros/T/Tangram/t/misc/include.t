#!/usr/bin/perl -w

use strict;

use Test::More tests => 3;

use vars qw($died);
BEGIN { $SIG{__WARN__} = sub { $died++ };

	use_ok(Tangram => qw(2.10_01), ":no_compat");
    }
is($died, undef, "didn't get a warning with a non-numeric version");

is($INC{"Tangram/Compat.pm"}, undef, "didn't use Tangram::Compat");
