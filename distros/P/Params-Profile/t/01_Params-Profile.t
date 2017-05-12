use strict;
use warnings;
use Test::More 'no_plan';
use Data::Dumper;

BEGIN { chdir 't' if -d 't' }
BEGIN { use lib '../lib'    }


my $Class   = 'Params::Profile';
use_ok( $Class );
can_ok( $Class,         'get_profile' );
can_ok( $Class,         'register_profile' );
can_ok( $Class,         'verify_profiles' );
can_ok( $Class,         'clear_profiles' );
can_ok( $Class,         'get_profiles' );
can_ok( $Class,         'validate' );
