#!/usr/bin/perl

use Test::More tests => 6;

BEGIN { $ENV{PROFILE_LOG_CONFIG} = "t/profiler.conf";
    };

use Profile::Log;
is(PROFILE, 3, "script name auto-config");

{
  local($SIG{__WARN__}) = sub { };
  *PROFILE = sub { 2 };
}

if ( PROFILE < 3 ) {
    fail("optimiser didn't eliminate constant sub branches");
} else {
    pass("optimiser eliminated constant sub branches");
}

eval "package Component1; use Profile::Log;";
is($@, "", "used Profile::Log OK");

is(&Component1::PROFILE, 2, "Profile::Log auto-config (1)");

eval "package Component2; use Profile::Log;";
is($@, "", "used Profile::Log OK again");

is(&Component2::PROFILE, 1, "Profile::Log auto-config (2)");
