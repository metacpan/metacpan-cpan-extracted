package Paubox_Email_SDK::Message;

use strict;
use warnings;

our $VERSION = '1.2';

# constructor
sub new {

    # the package name 'Message' is in the default array @_
  	# shift will take package name 'message' and assign it to variable 'class'
    my $class = shift;
    
    my $self = bless {
        'from' => '',
        'replyTo' => '',
        'to' => [],
        'cc' => [],
        'bcc' => [],
        'subject' => '',
        'allowNonTLS' => '' || 0,
        'forceSecureNotification' => '',
        'text_content' => '',
        'html_content' => '',
        'attachments' => [], 
    @_ }, $class;

    # returning object from constructor
    return $self;
}

1;