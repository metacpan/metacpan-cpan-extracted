# $RCSfile: 0.load.t,v $
# $Author: swaj $
# $Revision: 1.1 $

use Test;
BEGIN { plan tests => 1 };
use Sdict;
print "# I'm testing Sdict version $Sdict::VERSION\n";
ok( $Sdict::VERSION ? 1 : 0 );
warn "(found module version $Sdict::VERSION) ...ok\n";

