package Demo::Adapters::Mailer;
use strict;
use warnings;
use Demo::Logger;

# Accept a message for demonstration.
sub deliver {
    my ($recipient, $subject) = @_;
    return defined($recipient) && defined($subject);
}
1;
