package SMS::Send::Wadja;
use warnings;
use strict;
use base 'SMS::Send::Driver';
use HTTP::Request::Common;
use LWP::UserAgent;

=head1 NAME

SMS::Send::Wadja - Non-regional L<SMS::Send> driver for the L<http://wadja.com>
free global SMS service, using their API.

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.01';


=head1 SYNOPSIS

    use SMS::Send;

    my $sender = SMS::Send->new('Wadja',
        _key      => 'my-wadja-API-key'
    );

    my $sent = $sender->send_sms(
        to        => '+40-722-123456',    # recipient
        text      => "Hello, world!",     # the text of the message to send
        _from     => 'me@mydomain.com',   # optional "from" address
    );

    # Did it send to Wadja OK?
    if ( $sent ) {
        print "Sent test message\n";
    } else {
        print "Test message failed\n";
    }

=head1 DESCRIPTION

SMS::Send::Wadja is an L<SMS::Send> driver for the L<http://wadja.com> free
global SMS service, using their API. To apply for an API key, sign up for an
account (it requires e-mail confirmation, but no phone number confirmation),
then request an API key from L<http://www.wadja.com/api/get-started.aspx>. In
theory, Wadja could also be screen scraped so that you could send text messages
via the web interface, without having to apply for an API key. However, applying
is free, and the Wadja site is JavaScript-heavy and slow, which is why I didn't
spend time implementing the screen scraping method.

I've seen Wadja deliver text messages successfully to the UK (Vodaphone),
Germany (T-Mobile (D1) and Vodafone), Philippines (Global Telecom),
Poland (Orange, Polkomtel), Romania (Orange), and Russia (BeeLine), but not to
the US (AT&T Wireless), despite the official coverage claim at
L<http://us.wadja.com/applications/compose/coverage.aspx>. However, Wadja
provides a delivery status function (which happens to be currently broken via
their API (see L<http://us.wadja.com/applications/forum/replies.aspx?id=643>)
but works via the web UI).

Wadja offers two types of APIs:

=over

=item * Free SMS API - free, limited to 3 messages per day and 90 characters per
message (the remaining characters will be used for ad delivery or Wadja branding)

=item * SMS Plus API - requires topping up credit (in EUR), and doesn't deliver
ads (thus you get the full 160 characters).

=back

This module has only been tested with the Free SMS API but will probably work
with the SMS Plus API as well.

=head1 METHODS

=head2 new

    # Create a new sender using this driver
    my $sender = SMS::Send->new('Wadja',
        _key    => 'your_wadja_API_key'            # required
        _ua     => $your_own_LWP_UserAgent_object  # useful if you want to pass proxy parameters
    );

=cut

sub new {
    my $class  = shift;
    my $opts = {
        _send_via => 'api',
        _api_sms_url => 'http://www.wadja.com/partners/sms/default.aspx',
        _api_delivery_url => 'http://www.wadja.com/partners/sms/dlr.aspx',
        @_
    };
    $opts->{_ua} ||= LWP::UserAgent->new(
        # on 2010-01-26, Wadja changed its API URL and started issuing a '301 Moved Permanently'
        # response to our 'POST' request. By default, LWP::UserAgent::requests_redirectable excluded 'POST'.
        requests_redirectable => ['GET', 'HEAD', 'POST']
    );
    return bless $opts, $class;
}

=head2 send_sms

This method is actually called by L<SMS::Send> when you call send_sms on it.

    my $sent = $sender->send_sms(
        text => 'Messages have a limit of 90 chars',
        to   => '+44-1234567890',
        _from => 'custom From string'  # works only in the SMS Plus API
    );

Unicode messages appear to be handled correctly and are still limited to 90
characters.

Returns a hashref with the following keys:

    price
    batchID - used for tracking the delivery status

=cut

sub send_sms {
    my $self   = shift;
    my %params = @_;
    my %wadja_response;

    my $unicode = $params{text} =~ /[\x{80}-\x{FFFF}]/? 'yes' : 'no';
    my $response = $self->{_ua}->request(POST $self->{_api_sms_url}, [
        key => $self->{_key},
        msg => $params{text},
        to => $params{to},
        from => $params{_from},
        # Unicode doesn't work in the Web UI: L<http://www.wadja.com/applications/forum/replies.aspx?id=640>
        # The UI failing prevents us from knowing what the real message length limit is.
        unicode => $unicode,
        send => 1,  # 0 for getting a price quote
    ]);

    if (defined $response and $response->is_success) {
        $self->{_raw_response} = $response->content;
        while ($self->{_raw_response} =~ / \[ (.*?) : \s* (.*?) \] /gx) {
            $wadja_response{$1} = $2;
        }
        $self->{_wadja_response} = \%wadja_response;

        if ($wadja_response{batchID}) {
            return \%wadja_response;
        } else {
            # request went through but message not accepted
            if ($wadja_response{ERROR}) {
                Carp::carp "SMS message not sent -- Wadja ERROR: $wadja_response{ERROR}";
            } elsif (%wadja_response) {
                # Wadja did not return a batchID, but there was no error. This indicates success, but is a bug.
                return \%wadja_response;
            } else {
                Carp::carp q{SMS message not sent -- Wadja returned '} . $self->{_raw_response} . q{'};
            }
            return 0;
        }
    } elsif (defined $response) {
        # failed LWP request, fatal
        Carp::croak 'Failed to issue HTTP request: ' . $response->status_line;
    } else {
        Carp::croak 'No HTTP request issued';
    }
}


=head2 delivery_status

    # Get the delivery status of the last message we sent
    my $status = $sender->delivery_status;

    # Get the delivery status for an arbitrary message we sent in the past,
    # based on an anonymous hashref with a 'batchID' key
    my $sent = $sender->send_sms(...);
    my $status = $sender->delivery_status($sent);
    
    # Or just pass a {batchID => nnn}
    my $batchID = 2180419;
    my $status = $sender->delivery_status({batchID => $batchID});

    if ($status->{error}) {
        print "Can't check delivery: ", $status->{error}, "\n";
    } else {
        print "Delivery status of " . $batchID . ": ", $status->{status}, ' at ', $status->{completed};
    }

If called with no parameters then the most recent message sent out is checked.
You can also provide an anoynmous hash with a batchID key set to the value of the
batchID returned by a previous L</send_sms> call.

Returns a hashref, of which the 'status' key indicates:

    DELIVRD Delivered to destination
    ACCEPTD Accepted by network operator
    EXPIRED Validity period has expired
    UNDELIV Message is undeliverable
    UNKNOWN Message is in unknown state
    REJECTD Message is in rejected state

=cut

sub _wadja2DateTime {
    my ($wadja_date) = @_;
    my ($yy, $mm, $dd, $hh, $min) = $wadja_date =~ /(\d{2})/g;
    return DateTime->new(
        year => $yy+2000,
        month => $mm,
        day => $dd,
        hour => $hh,
        minute => $min,
        time_zone => '+0100',  # neither UTC, nor Europe/Athens (unless Wadja's server doesn't follow DST)
    );
}

sub delivery_status {
    require DateTime;
    my $self           = shift;
    my $wadja_response = shift || $self->{_wadja_response}
        or Carp::croak 'No message available for checking delivery_status';
    my $batch_id = $wadja_response->{batchID}
        or Carp::croak 'No batch ID in the Wadja response';
    defined $self->{_ua}
        or Carp::croak 'UserAgent not initialized';

    my $request_URL = URI->new($self->{_api_delivery_url});
    $request_URL->query_form(
        key => $self->{_key},
        bid => $batch_id
    );
    my $response = $self->{_ua}->get($request_URL);

    if (defined $response and $response->is_success) {
        # A response may look like:
        # [40746057225: id:40012700460178067 sub:001 dlvrd:001 submit date:1001270046 done date:1001270046 stat:DELIVRD err:000 text:First 19 chars of t]
        # or, if no delivery information is available just yet, like:
        # [447536736704: ]

        my $content = $response->content or return {error => "No response"};
        
        my ($response_id, $id, $sub, $delivered, $submit_date, $done_date, $status, $error) = $content =~
            /(\d+): \s+ (?: id: (\S+) \s+ sub: (\S+) \s+ dlvrd: (\S+) \s+ submit\ date: (\S+) \s+ done\ date: (\S+) \s+ stat: (\S+) \s+ err: (\S+) )?/x;

        return {error => "Wadja error. Make sure the API key is the same as the one used for batchID $batch_id. Error message was: $content"}
            if not $response_id;
        return {error => "No delivery status available yet. Try again later"}
            if not $id;  # happens if you request delivery status right after sending the SMS

        $submit_date = _wadja2DateTime($submit_date);
        $done_date = _wadja2DateTime($done_date);
        $submit_date->set_time_zone('local');
        $done_date->set_time_zone('local');

        return {
            delivered => $delivered + 0,
            submitted => $submit_date,
            completed => $done_date,
            status => $status,
            error => $error + 0
        }
    }
    return;
}

=head1 BUGS AND LIMITATIONS

Wadja's API lets you send a text message to multiple recipients at once, by
delimiting the phone numbers with commas. However, SMS::Send strips commas from
the "to" parameter, which will obviously break things. I filed a bug against
SMS::Send at L<http://rt.cpan.org/Ticket/Display.html?id=45868>.

The official coverage claim is at L<http://us.wadja.com/applications/compose/coverage.aspx>
but beware that I could not send text messages successfully to AT&T Wireless in
the US despite what the coverage claims.

Please report any bugs or feature requests for this module to
C<bug-sms-send-wadja at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-Wadja>. For patches,
please send whole files, not diffs.

=head1 AUTHOR

Dan Dascalescu, L<http://dandascalescu.com>

=head1 ACKNOWLEDGEMENTS

Thanks to Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/> for writing
SMS::Send. The Wadja API is described at
L<http://www.wadja.com/api/docs/SMS_HTTP_API.pdf> (as of 2010-01-25, the base
URLs are wrong. s/sms/www/g.

Many thanks to my friends worldwide for assisting with QA.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-2010 Dan Dascalescu, L<http://dandascalescu.com>. All rights
reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # End of SMS::Send::Wadja
