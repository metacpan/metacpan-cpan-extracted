# $File: //depot/RT/osf/lib/RT/EmailParser_Local.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 9137 $ $DateTime: 2003/12/05 19:48:10 $

use strict;
no warnings 'redefine';

sub ParseTicketId {
    my $self = shift;

    my $Subject = shift;

    if ( $Subject =~ s/\[\Q$RT::rtname\E(?::\S+)?\s+\#(\d+)\s*\]//i ) {
        my $id = $1;
        $RT::Logger->debug("Found a ticket ID. It's $id");
        return ($id);
    }
    else {
        return (undef);
    }
}

1;
