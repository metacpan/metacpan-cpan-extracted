use strict;
use warnings;

use Test::More 0.88;

# ABSTRACT: Make sure not to fail if Log::Contextual is accidentally uninitialised

BEGIN {
    eval { require "Log/Contextual.pm"; 1 }
      or plan skip_all => "Log::Contexual required installed for this test";
}

use Module::Metadata;

my ( $ok, $error ) = do {
    local $@;
    my $rval = eval {
        package Module::Metadata; # Required because "default" applies to caller context
        # So this test is mimicing internal calls
        Module::Metadata::log_info { "something" };
        1;
    };
    ( $rval, $@ );
};

ok( $ok, "Log::Contextual being loaded didn't cause an explosion" )
  or note $error;

done_testing;
