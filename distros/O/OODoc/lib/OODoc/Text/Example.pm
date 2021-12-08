# Copyrights 2003-2021 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of perl distribution OODoc.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package OODoc::Text::Example;
use vars '$VERSION';
$VERSION = '2.02';

use base 'OODoc::Text';

use strict;
use warnings;

use Log::Report    'oodoc';


sub init($)
{   my ($self, $args) = @_;
    $args->{type}    ||= 'Example';
    $args->{container} = delete $args->{container} or panic;

    $self->SUPER::init($args)
        or return;

    $self;
}

#-------------------------------------------

1;
