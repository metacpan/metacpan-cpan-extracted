package Serengeti::Notifications;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    DOCUMENT_CHANGED_NOTIFICATION
    NEW_SESSION_NOTIFICATION
    SESSION_EVENT_NOTIFICATION
);

our @EXPORT_OK = @EXPORT;

our %EXPORT = ( all => [@EXPORT] );

use constant DOCUMENT_CHANGED_NOTIFICATION  => "DocumentChangedNotification";
use constant NEW_SESSION_NOTIFICATION       => "NewSessionNotification";
use constant SESSION_EVENT_NOTIFICATION     => "SessionEventNotification";
1;
__END__
