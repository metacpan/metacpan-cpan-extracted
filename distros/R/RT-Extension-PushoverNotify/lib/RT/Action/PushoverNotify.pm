package RT::Action::PushoverNotify;

use 5.10.1;
use strict;
use warnings;

use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use JSON;

use LWP::UserAgent; 
use LWP::Protocol::https;

use RT::Extension::PushoverNotify::PushoverNotification;

use base qw(RT::Action);

=pod

=head1 NAME

RT::Action::PushoverNotify - Send RT activity to a Pushover user or group

=head1 DESCRIPTION

Send RT activity information to Pushover for distribution to mobile clients.
The message is defined with an RT template.

The message receipients are controlled by setting the contents of the
array-ref-ref Recipients, which is a predefined variable in the template.  If
an entry is an RT::User then its PushoverUserKey custom field is looked up to
obtain the Pushover key to notify. Otherwise the result is assumed to be a
pushover key and notified as-is. Eg:

  push(@$$Recipients, @{$Ticket->QueueObj->AdminCc->UserMembersObj->ItemsArrayRef})

Headers in the template are parsed out to control additional request parameters:

- Priority: message priority as defined by Pushover API. -1 is low / do not
  disturb; 0 is normal, 1 is emergency (override silent hours), 2 is emergency
  that requires acknowledgement.

- Subject: message title

- Retry: Seconds between retry attempts (within 'expires' interval). Only applies
  for priority=2. Default 60. The API sets limits on these values and will fail
  requests - currently for retry values less than 30.

- Expire: Number of seconds after message delvery that message acknowledgement
  request expires. Only applies for priority=2. Default 300.

- URL: A link to include in the message

- URL-Title: Title to add to the message

- Device: The user's device name, if you want to send a message only to one
  particular device.

- Sound: The name of the Pushover notification sound to use; see https://pushover.net/api#sounds

The message time and the application API key are added to the request
automatically.

Limitations are documented in https://pushover.net/api#limits

=head1 USAGE

In RT_SiteConfig.pm add your application API token, which you can request at
http://pushover.com/ .

    Set($PushoverNotifyConfig, {
        api_token => 'lkhasdf87234lkhsfd123sdfASAFD1'
    });

Create a custom user field named PushoverUserKey. Apply it to all users, and
populate the field for the users who you want to receive notificatoins. You
can get your pushover key from http://pushover.com/.

Create the following table in your RT database:

    CREATE TABLE PushoverNotifications (id serial primary key, RequestId text, UserId text, TicketId integer, AcknowledgedAt timestamptz, ReceiptId text, UserToken text not null, Priority integer, SentAt timestamptz);

Create an entry in the scripactions table in the RT database for
RT::Action::PushoverNotify, or (only once) "make initdb" on this extension to
create the entry. Do not repeat this step as you will get duplicate entries.

Create a suitable Template as documented below and then create a scrip that
uses the template and action with a suitable condition to send notifications.

=head1 Exposed pages

  /NoAuth/Pushover/callback.html - Accepts acknowledgement callbacks from pushover.com

=head1 Database tables

  pushovernotifications - Keeps records of notifications sent and acknowledged

=head1 Example template

    Subject: New ticket #{$Ticket->Id}
    Priority: 2
    Retry: 30
    Expire: 120
    URL: http://mysite.zz/rt/Ticket/Display.html?id=1111
    URL-Title: Ticket 1111

    {
      # Recipients is a ref to an array ref
      push(@$$Recipients, 'u1321321123123123');
    }
    A new ticket has been filed in the queue {$Ticket->Queue->Name}.

The template argument is set to the scrip argument if any. @$$Recipients may
be set hard coded, based on the template argument, based on some other calls, etc.

=head1 Future work

* Set all options via a hash parameter, instead of using header-style parsing
* Provide an easier way to filter recipients based on a function for checking "on shift" status, etc.

=cut

sub Prepare {
    my $self = shift;
    # Sanity check the configuration
    my $cfg = RT->Config->Get('PushoverNotifyConfig');
    if (!defined($cfg)) {
        $RT::Logger->error('PushoverNotify called without $PushoverNotifyConfig in RT_SiteConfig.pm, aborting');
        return 0;

    }
    if (!defined($cfg->{'api_token'})) {
        $RT::Logger->error('$PushoverNotifyConfig->{connection} not defined in RT_SiteConfig.pm, aborting');
        return 0;
    }
    $cfg->{'endpoint'} //= 'https://api.pushover.net/1/messages.json';
    if (!defined($self->TemplateObj)) {
        die("Template must be specified for invocations of PushoverNotify");
    }
    $self->{'cfg'} = $cfg;

    eval {
        ($self->{'message'}, $self->{'recipients'}) = $self->get_message_from_template();
    };
    if ($@) {
        $RT::Logger->error("Unable to parse message template: $@");
    }

    $self->{'message'}->{'token'} = $cfg->{'api_token'};

    return 1;
}

sub store_if_defined {
    if (!defined($_[1])) {
        return 0;
    } else {
        $_[0] = $_[1];
        chomp($_[0]);
        return 1;
    }
}

sub store_int_if_defined {
    # If a header value looks like a number, store it in the passed lvalue,
    # which could be a hash key reference, scalar, etc. If the argument is
    # undef, no assignment is made. If the argument is defined but not a
    # number, logs a warning.
    # 
    # Arguments:  ( lvalue, inttext )
    #
    if (!defined($_[1])) {
        return 0;
    } elsif ($_[1] =~ /^\d+$/) {
        $_[0] = int($_[1]);
        return 1;
    } else {
        RT::Logger->warning('Unable to convert value ' . $_[1] . ' to number');
        return 0;
    }
}

sub get_message_from_template {
    my $self = shift;
    my $recips = [];
    my ($result, $message) = $self->TemplateObj->Parse(
            Argument       => $self->Argument,
            TicketObj      => $self->TicketObj,
            TransactionObj => $self->TransactionObj,
            UserObj        => $self->CurrentUser,
            Recipients     => \$recips,
    );
    if ( !$result ) {
        die("Failed to process template " . $self->TemplateObj->Id . " for "
            . " ticket=" . $self->TicketObj->Id . ": $message");
    }

    my $MIMEObj = $self->TemplateObj->MIMEObj;
    my %message;
    $message{'message'} = $MIMEObj->bodyhandle->as_string;
    if (!($message{'message'} =~ /\S/m)) {
        die("Template result for template " . $self->TemplateObj->Id . " is only whitespace, skipping message");
    }

    my $head = $MIMEObj->head;
    store_if_defined($message{'title'}, $head->get('Subject'));
    store_if_defined($message{'url'}, $head->get('URL'));
    store_if_defined($message{'url_title'}, $head->get('URL-Title'));
    store_if_defined($message{'sound'}, $head->get('Sound'));
    store_int_if_defined($message{'priority'}, $head->get('Priority'));
    store_int_if_defined($message{'retry'}, $head->get('Retry'));
    store_int_if_defined($message{'expire'}, $head->get('Expire'));
    store_if_defined($message{'device'}, $head->get('Device'));
    store_if_defined($message{'sound'}, $head->get('Sound'));

    if ($message{'priority'} == 2) {
        # Set the callback URL
        $message{'callback'} = $RT::WebURL . '/NoAuth/Pushover/callback.html';
    }

    $message{'timestamp'} = time();
    $RT::Logger->debug('Preparing Pushover message: ' . Dumper(\%message) );

    # Extract the message recipients, which should be pushover api tokens
    # or RT::User objects. Produce a map of tokens to (if known) RT user IDs.
    my %recipients = ();
    for my $recipient (@$recips) {
        if (ref($recipient) == 'RT::User') {
            my $k = $recipient->FirstCustomFieldValue('PushoverUserKey');
            $recipients{$k} = $recipient->Id if $k;
        } else {
            # Assume it's just an API token and thus has no known RT::User id associated
            $recipients{$recipient} = undef;
        }
    }

    # TODO: allow a default recipient list to be supplied here
    if (!scalar(%recipients)) {
        $RT::Logger->warning("No recipients supplied for Pushover notification or all RT::User objects had no PushoverUserKey");
    }

    return \%message, \%recipients;
}

sub Commit {
    my $self = shift;
    
    my $errors = 0;
    RT::Logger->debug("Receipients are: " . Dumper($self->{'recipients'}));

    while (my ($recipient, $recipient_uid) = each %{$self->{'recipients'}}) {
        eval {
            my $ua = LWP::UserAgent->new();
            $self->{'message'}->{'user'} = $recipient;
            my $response = $ua->post( $self->{'cfg'}->{'endpoint'}, $self->{'message'} );
            if ($response->is_success) {
                my(%r) = %{decode_json($response->decoded_content)};
                if (defined($r{'receipt'})) {
                    # TODO: Register a receipt callback URL in the notification
                    RT::Logger->info("Notification sent to $recipient with request ID $r{'request'}; receipt is $r{'receipt'}");
                } else {
                    RT::Logger->debug("Notification sent to $recipient with request ID $r{'request'}");
                }

                eval {
                    my $now = RT::Date->new( $RT::SystemUser );
                    $now->SetToNow;
                    my $notification = RT::Extension::PushoverNotify::PushoverNotification->new( $RT::Handle );
                    $notification->Create (
                        UserId => $recipient_uid,
                        TicketId => defined($self->TicketObj) ? $self->TicketObj->Id : undef,
                        UserToken => $recipient,
                        Priority => $self->{'message'}->{'priority'},
                        RequestId => $r{'request'},
                        ReceiptId => $r{'receipt'},
                        AcknowledgedAt => undef,
                        SentAt => $now->ISO,
                        TransactionId => defined($self->Transaction) ? $self->Transaction->Id : undef,
                    );
                };
                if ($@) {
                    RT::Logger->error("Failed to record notification in database: $@");
                }
            } else {
                if ($response->code == 429) {
                    RT::Logger->error("Pushover message quota reached! You need to buy messages at https://pushover.net/apps");   
                }
                $RT::Logger->debug("Pushover message failed: " . Dumper($self->{'message'}));
                die("Pushover notification failed with HTTP " . $response->code . ': ' . $response->message . '; response body: ' . $response->decoded_content());
            }
        };
        if ($@) {
            RT::Logger->error($@);
            $errors ++;
        }
    }
    if ($errors) {
        die("Some notifications failed; see the error log for details. There were $errors errors.");
    }
    return 1;
}

1;
