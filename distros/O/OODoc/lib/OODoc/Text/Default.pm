# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package OODoc::Text::Default;
use vars '$VERSION';
$VERSION = '2.01';

use base 'OODoc::Text';

use strict;
use warnings;

use Log::Report    'oodoc';


sub init($)
{   my ($self, $args) = @_;
    $args->{type}    ||= 'Default';
    $args->{container} = delete $args->{subroutine} or panic;

    $self->SUPER::init($args)
        or return;

    $self->{OTD_value} = delete $args->{value};
    defined $self->{OTD_value} or panic;

    $self;
}

#-------------------------------------------


sub subroutine() { shift->container }


sub value() { shift->{OTD_value} }

1;
