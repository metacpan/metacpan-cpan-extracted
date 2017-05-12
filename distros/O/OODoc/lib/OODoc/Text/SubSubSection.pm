# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package OODoc::Text::SubSubSection;
use vars '$VERSION';
$VERSION = '2.01';

use base 'OODoc::Text::Structure';

use strict;
use warnings;

use Log::Report    'oodoc';


sub init($)
{   my ($self, $args) = @_;
    $args->{type}      ||= 'Subsubsection';
    $args->{container} ||= delete $args->{subsection} or panic;
    $args->{level}     ||= 3;

    $self->SUPER::init($args)
        or return;

    $self;
}

sub findEntry($)
{  my ($self, $name) = @_;
   $self->name eq $name ? $self : ();
}

#--------------

sub subsection() { shift->container }


sub chapter() { shift->subsection->chapter }

sub path()
{   my $self = shift;
    $self->subsection->path . '/' . $self->name;
}

1;
