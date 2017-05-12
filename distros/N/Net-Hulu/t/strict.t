#make sure all code has use strict and use warnings turned on.
use Test::Strict tests => 9;
use strict;
use warnings;

#check all scripts for use warnings;
warnings_ok( 'lib/Net/Hulu.pm' );
warnings_ok( 'Makefile.PL' );
warnings_ok( 't/Net-Hulu.t' );
warnings_ok( 't/strict.t' );
warnings_ok( 't/critic.t' );
#warnings_ok( 't/distribution.t' );
warnings_ok( 't/pod.t' );
warnings_ok( 't/pod-coverage.t' );
warnings_ok( 't/kwalitee.t' );
warnings_ok( 't/0-signature.t' );
#all_perl_files_ok();	# Syntax ok and use strict
