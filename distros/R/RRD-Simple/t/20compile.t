# $Id: 20compile.t 965 2007-03-01 19:11:23Z nicolaw $

chdir('t') if -d 't';

BEGIN {
	use Test::More;
	eval "use RRDs";
	plan skip_all => "RRDs.pm *MUST* be installed!" if $@;
	plan tests => 2 if !$@;
}

use lib qw(./lib ../lib);
use_ok('RRD::Simple');
require_ok('RRD::Simple');

1;

