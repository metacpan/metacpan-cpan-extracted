# Copyrights 2001-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
package I;
use vars '$VERSION';
$VERSION = '0.21';


use Object::Realize::Later
    realize       => sub { bless {}, 'Another::Class' },
    becomes       => 'Another::Class',
    source_module => 'J';

sub new { bless {}, shift }

1;
