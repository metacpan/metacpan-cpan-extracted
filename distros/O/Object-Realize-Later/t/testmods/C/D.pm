# Copyrights 2001-2014 by [Mark Overmeer <perl@overmeer.net>].
#  For other contributors see Changes.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
package C::D;
our $VERSION = '0.19';

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
