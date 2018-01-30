# Copyrights 2001-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

use strict;
use warnings;

package C;
use vars '$VERSION';
$VERSION = '0.21';

use overload '""' => sub { ref(shift) };

sub new() { bless {}, shift }
sub c()   { 'c' }

1;
