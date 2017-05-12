# Copyrights 2001-2014 by [Mark Overmeer <perl@overmeer.net>].
#  For other contributors see Changes.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
package I;
our $VERSION = '0.19';


use Object::Realize::Later
    realize       => sub { bless {}, 'Another::Class' },
    becomes       => 'Another::Class',
    source_module => 'J';

sub new { bless {}, shift }

1;
