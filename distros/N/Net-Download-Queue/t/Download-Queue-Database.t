#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

BEGIN { -d "t" and chdir("t"); }

use_ok("Net::Download::Queue");
ok(Net::Download::Queue->rebuildDatabase(), "rebuildDatabase");





__END__
