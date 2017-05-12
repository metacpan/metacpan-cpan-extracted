#!/usr/local/bin/perl

# most useless test ever, thanks Mr. Sergeant :P

use File::Basename;

chdir ( dirname ( $0 ) );

use lib qw(lib ../lib);

use Test::More tests => 1;

require_ok ( "Pod::XML" );
