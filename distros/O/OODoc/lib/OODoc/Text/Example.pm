# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package OODoc::Text::Example;
use vars '$VERSION';
$VERSION = '2.01';

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
