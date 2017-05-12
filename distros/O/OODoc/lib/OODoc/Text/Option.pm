# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package OODoc::Text::Option;
use vars '$VERSION';
$VERSION = '2.01';

use base 'OODoc::Text';

use strict;
use warnings;

use Log::Report    'oodoc';


sub init($)
{   my ($self, $args) = @_;
    $args->{type}    ||= 'Option';
    $args->{container} = delete $args->{subroutine} or panic;

    $self->SUPER::init($args)
        or return;

    $self->{OTO_parameters} = delete $args->{parameters} or panic;

    $self;
}

#-------------------------------------------


sub subroutine() { shift->container }


sub parameters() { shift->{OTO_parameters} }

1;
