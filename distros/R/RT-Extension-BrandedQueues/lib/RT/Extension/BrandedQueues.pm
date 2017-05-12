use warnings;
use strict;

no warnings qw/redefine/;

package RT::Extension::BrandedQueues;

our $VERSION = '0.1';

use RT::Interface::Email;
package RT::Interface::Email;
sub ParseTicketId {
    my $Subject = shift;
    my $id;

    my $test_name = $RT::EmailSubjectTagRegex || qr/\Q$RT::rtname\E/i;

    if ( $Subject =~ s/\[$test_name\s+\#(\d+)\s*\]//i ) {
        my $id = $1;
        $RT::Logger->debug("Found a ticket ID. It's $id");
        return ($id);
    }
    else {

        my $queues = RT::Queues->new($RT::SystemUser);
        $queues->UnLimit();
        while (my $queue = $queues->Next) {
                my $tag_attr = $queue->FirstAttribute('BrandedSubjectTag');
                next unless ($tag_attr);
                my $tag = $tag_attr->Content;
                next  unless ($tag); 
                my $test_name =qr/\Q$tag\E/i;
                if ( $Subject =~ s/\[$test_name\s+\#(\d+)\s*\]//i ) {
                        my $id = $1;
                        $RT::Logger->debug("Found a ticket ID. It's $id");
                        return ($id);
                }
        
        }
        # no tag for real.
        return (undef);
    }
}
use RT::EmailParser;
package RT::EmailParser;
# In 3.2, we used EmailParser's ParseTicketId;
sub ParseTicketId {
    my $self = shift;
    RT::Interface::Email::ParseTicketId(@_);
}

use RT::Queue;
package RT::Queue;

sub Tag {
        my $self = shift;
        my $tag_attr = $self->FirstAttribute('BrandedSubjectTag');
        return ($RT::rtname) unless ($tag_attr);
        my $tag = $tag_attr->Content || $RT::rtname; 
        return $tag;
}


use RT::Action::SendEmail;
package RT::Action::SendEmail;

sub SetSubjectToken {
    my $self = shift;
    my $tag  = "[".$self->TicketObj->QueueObj->Tag ." #" . $self->TicketObj->id . "]";
    my $sub  = $self->TemplateObj->MIMEObj->head->get('Subject');
    unless ( $sub =~ /\Q$tag\E/ ) {
        $sub =~ s/(\r\n|\n|\s)/ /gi;
        chomp $sub;
        $self->TemplateObj->MIMEObj->head->replace( 'Subject', "$tag $sub" );
    }
}


1;
