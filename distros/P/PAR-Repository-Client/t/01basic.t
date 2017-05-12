use strict;
use warnings;
use Test::More tests => 1;
use File::Temp ();
BEGIN { $ENV{PAR_TEMP} = File::Temp::tempdir( CLEANUP => 1 ); }
BEGIN { use_ok('PAR::Repository::Client') };

