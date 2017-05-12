#!/usr/bin/perl

package RT::Extension::PushoverNotify::PushoverNotification;

use strict;
use warnings;
use 5.10.1;

use base 'RT::Record';

=head1 NAME

  RT::Extension::PushoverNotify::PushoverNotification - Notification record

=head1 DESCRIPTION

An RT record that keeps track of a notification we sent to a user via Pushover.
Built on top of RT::Record and in turn DBIx::SearchBuilder::Record .

=head1 Methods

=head2 UserId

RT::User identifier for the user this notification was sent to, if any.

=head2 UserToken

Pushover API token the notification was sent to.

=head2 Priority

Priority the request was sent with, per pushover API.

=head2 RequestId

Request ID returned by Pushover for this notification.

=head2 ReceiptId

If acknowledgement was requested, the Pushover receipt ID for the request. Can
be checked for acknowledgements later.

=head2 AcknowledgedAt

UNIX timestamp the user acknowledged the request at, or NULL if not acknowledged.

=head2 SetAcknowledgedAt

Set the acknowledgement time after doing an API request or receiving a
callback. The record must be saved for this to take effect.

=cut

sub Table { 'PushoverNotifications' };

sub Schema {
    return {
        UserId => { TYPE => 'integer' },
        UserToken => { TYPE => 'text' },
        Priority => { TYPE => 'integer' },
        RequestId => { TYPE => 'text' },
        ReceiptId => { TYPE => 'text' },
        AcknowledgedAt => { TYPE => 'timestamp' },
        TicketId => { TYPE => 'integer' },
        TransactionId => { TYPE => 'integer' },
        SentAt => { TYPE => 'timestamp' },
    };
}

sub _CoreAccessible {
    return {
        UserId => { read => 1, auto => 1 },
        UserToken => { read => 1, auto => 1 },
        Priority => { read => 1, auto => 1 },
        RequestId => { read => 1, auto => 1 },
        ReceiptId => { read => 1, auto => 1 },
        AcknowledgedAt => { read => 1, write => 1, auto => 1, type => 'datetime', sql_type => 11, is_numeric => 0 },
        TicketId => { read => 1, auto => 1 },
        TransactionId => { read => 1, auto => 1 },
        SentAt => { read => 1, auto => 1, type => 'datetime', sql_type => 11, is_numeric => 0 },
    };
}

1;
