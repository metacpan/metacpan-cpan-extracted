# $File: //depot/RT/osf/lib/RT/Action/SendEmail_Local.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 9374 $ $DateTime: 2003/12/21 23:34:48 $

use strict;
no warnings 'redefine';

sub SetSubjectToken {
    my $self = shift;
    my $QueueObj = $self->TicketObj->QueueObj;
    my $id = $self->TicketObj->id;
    my $tag = sprintf(
	"[%s:%s #%s]",
	$RT::rtname,
	( eval {$QueueObj->OriginObj->CustomFieldValue('UnixName')}
	    || $QueueObj->Name ),
	$id,
    );
    my $sub  = $self->TemplateObj->MIMEObj->head->get('Subject');
    unless ( $sub =~ /\[\Q$RT::rtname\E(?::\S+)?\s+#\Q$id\E\s*\]/ ) {
        $sub =~ s/(\r\n|\n|\s)/ /gi;
        chomp $sub;
        $self->TemplateObj->MIMEObj->head->replace( 'Subject', "$tag $sub" );
    }
}

1;
