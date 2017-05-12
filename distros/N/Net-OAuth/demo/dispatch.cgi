#!/usr/bin/perl
use strict;
use warnings;
use lib qw(
	.
	Net-OAuth/lib
	/home/kg23/local/share/perl/5.10
	/home/kg23/local/share/perl/5.10.0
	/home/kg23/local/lib/perl/5.10
	/home/kg23/local/lib/perl/5.10.0
	);

use Plack::Util;
use Plack::Loader;
my $app = Plack::Util::load_psgi("app.psgi");
Plack::Loader->auto->run($app);
