# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
package   Module::Build::Debian::Self;
use base 'Module::Build';

use strict;
use warnings;
use version; our $VERSION = qv('1.0.0');

use FindBin qw($Bin);
use lib        $Bin;

BEGIN {
   eval 'use Module::Build::Debian';
}

1;

__END__

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
