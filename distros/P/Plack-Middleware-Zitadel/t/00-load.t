use strict;
use warnings;

use FindBin;
BEGIN {
    my $path = "$FindBin::Bin/../../p5-www-zitadel/lib";
    require lib if -d $path;
    lib->import($path) if -d $path;
}

use Test::More tests => 1;
use_ok('Plack::Middleware::Zitadel');
