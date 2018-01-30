# Copyrights 2001-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
package C::D;
use vars '$VERSION';
$VERSION = '0.21';

use base 'C';

use Object::Realize::Later
  ( becomes            => 'A::B'
  , realize            => 'load'
  , warn_realization   => 1
  , warn_realize_again => 1
  );

sub load() { bless {}, 'A::B' }
sub c_d()  {'c_d'}

1;
