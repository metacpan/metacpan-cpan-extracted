package Net::SMS::SMSPilot;
# coding: UTF-8

use strict;
use warnings;
use utf8;

our $VERSION = '0.05';

use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use Encode;

#use Data::Dumper;

# ==============================================================================

use constant SMSPILOT_API_URI => 'smspilot.ru/api.php';

# ==============================================================================
# Constructor
sub new($%) {
    my ($class, %config) = @_;
    %config = () if !(%config);

    if (! $config{apikey}) {
        return undef;
    }
    else {
        my $self = +{};
        $self = bless $self, ref($class) || $class;

        $self->_init(\%config);
        return $self;
    }
}
# ------------------------------------------------------------------------------
# Set up initial (passed from caller or default) values
sub _init
{
    my $self = shift;
    my ($config) = @_;

    $self->{secure}  = 1;
    $self->{charset} = 'utf8';
    $self->{sender}  = 'SMSPilot.Ru';

    for (qw(ua apikey charset secure on_error)) {
        $self->{$_} = $config->{$_} if exists $config->{$_};
    }

    $self->set_sender($config->{sender}) if exists $config->{sender};

    $self->{uri}     = 'http'.($self->{secure}?'s':'').'://'.SMSPILOT_API_URI;
    $self->{_errmsg} = '';

}
# ------------------------------------------------------------------------------
sub _throw_error {
    my ($self, $msg) = @_;

    $self->{_errmsg} = $msg;
    if ($self->{on_error}) {
        # Fire callback
        &{$self->{on_error}}($msg);
    }
}
# ------------------------------------------------------------------------------
sub error {
    my $self = shift;
    return $self->{_errmsg} || '';
}
# ------------------------------------------------------------------------------
# Our User-Agent
sub _ua {
    my $self = shift;

    if (! defined($self->{ua})) {
        $self->{ua} = LWP::UserAgent->new(
            agent       => ref($self) . '/' . $VERSION,
            timeout     => 30
        );
        $self->{ua}->env_proxy;
    }

    return $self->{ua};
}
# ------------------------------------------------------------------------------
# Make request to API
sub _query($;%){
    my ($self, %data) = @_;
    my $r = undef;

    if (! $self->{apikey}) {
        $self->_throw_error('APIKEY is not defined');
    }
    else {

        $data{apikey} = $self->{apikey};
        (%data) = map {decode($self->{charset},$_)} (%data);
        my $uri = $self->{uri};
        my $response = $self->_ua->request(POST $uri,
                       Content      => [%data]
                       );

        if ($response->is_success) {
            my $cont = encode($self->{charset},$response->content);
            $r={};
            ($r->{header},$r->{content})=split(/\r?\n/,$cont,2);
            if ($r->{header}=~/^ERROR=(\d+):\s*(.*)$/) {
                $r->{error}=1;
                $r->{error_code}=$1;
                $r->{error_message}=$2;
                $r->{success}=0;
            } else {
                $r->{success}=1;
                $r->{error}=0;
                $r->{error_code}='';
                $r->{error_message}='';
                if ($r->{header}=~/^SUCCESS=(.*)$/) {
                    $r->{success_message}=$1
                } else {
                    $r->{success_message} = 'OK';
                    $r->{content}         = $cont;
                    $r->{header}          = '';
                }
            }
            if ($r->{error}) {
                $self->_throw_error('API error: '.$r->{error_code}.' '.$r->{error_message});
            }
        }
        else {
            $self->_throw_error('Request failed: ' . $response->status_line);
        }
    }

    return $r;
}
# ==============================================================================
#
sub send($$$){
    my ($self,$to,$msg) = @_;
    $to = join(',',@$to) if ref($to) eq 'ARRAY';
    my $report = undef;
    my $r = $self->_query(
        to   => $to,
        send => $msg,
        from => $self->{sender},
        );

    if (defined($r) && $r->{success}) {
        foreach (split(/\r?\n/,$r->{content})) {
            my ($id,$phone,$zone,$status) = split /,/;

            if ( $r->{success_message}=~/SMS\s+SENT\s+(\d+)\/(\d+)/ ) {
                ($self->{cost},$self->{balance})=($1,$2)
            } else {
                ($self->{cost},$self->{balance})=(undef,undef)
            }

            push(@$report,{
                           id     => $id,
                           phone  => $phone,
                           zone   => $zone,
                           status => $status,
                           });
        }
    }

    return wantarray?@$report:$report;
}
# ==============================================================================
#
sub set_sender($$){
    my ($self,$sender) = @_;
    if ($sender=~/^[A-Za-z\.\-\d]{3,11}$/ && $sender!~/^\d{3,9}$/) {
        $self->{sender} = $sender
    }elsif ($sender=~/^\+?\d{10,16}$/) {
        $sender=~s/^\+//;
        $self->{sender} = $sender;
    } else {
        $sender = undef;
        $self->_throw_error('The sender can contain text in Latin script, numer'.
                            'als, symbols "-" and "." length of 3-11 characters'.
                            ' long or the number length of 10-16 numbers in int'.
                            'ernational format, "+" sign is not considered.');
    }
    return $sender;
}
# ==============================================================================
#
sub balance($;$){
    my ($self,$type) = @_;
    my $balance = undef;
    $type = 'sms' if ! defined($type);
    my $r=$self->_query(
                        balance => $type,
                        );
    if (defined($r) && $r->{success}) {
        $balance=$r->{content}
    }
    return $balance;
}

# ==============================================================================
#
sub apikey_info($){
    my ($self) = @_;
    my $info = undef;
    my $r=$self->_query();
    if (defined($r) && $r->{success}) {
        foreach (split(/\r?\n/,$r->{content})) {
            my ($n,$v) = split(/=/,$_,2);
            $info->{$n} = $v;
        }
        $info->{history}=[split(/\|/,$info->{history})];
    }
    return wantarray?%$info:$info;
}
# ==============================================================================
#
sub check($$){
    my ($self,$id) = @_;
    $id = join(',',@$id) if ref($id) eq 'ARRAY';
    my $report = undef;
    my $r = $self->_query(
        check   => $id,
        );

    if (defined($r) && $r->{success}) {
        foreach (split(/\r?\n/,$r->{content})) {
            my ($id,$phone,$zone,$status) = split /,/;
            push(@$report,{
                           id     => $id,
                           phone  => $phone,
                           zone   => $zone,
                           status => $status,
                           });
        }
    }

    return wantarray?@$report:$report;
}
# ==============================================================================
1;
__END__

=head1 NAME

Net::SMS::SMSPilot - Send SMS to mobile phones, using smspilot.ru

=head1 SYNOPSIS

    use Net::SMS::SMSPilot;

    my $sms = Net::SMS::SMSPilot->new(
        apikey      => 'GJ67....KI5R',
        charset     => 'cp1251',
        sender      => 'internet',
        on_error    => sub { die shift }
    );

    # send one sms
    $sms->send('79876543210', 'SMS text messages');

    # change the sender
    $sms->set_sender('example.com');

    # mass sending of sms
    $sms->send( [
                 79876543210,
                 70123456789,
                ], 'SMS text messages');

=head1 DESCRIPTION

The C<Net::SMS::SMSPilot> module allows you to use
SMSPilot geteway (L<http://smspilot.ru>) via simple interface.

=head2 APIKEY

For using service, you need an apikey. You can purchase a key
 on the page L<http://smspilot.ru/apikey.php>.


=head1 USAGE

Interaction with SMSPilot.ru API executes by methods of the C<Net::SMS::SMSPilot>
 object.

The object provides methods for:

=over

=item * Retrieving information about the API key

=item * Retrieving information about the status of sent SMS

=item * Sending a single SMS and mass

=item * Change of Sender ID

=item * Check balance

=back

=head2 Constructor

=over

=item C<Net::SMS::SMSPilot-E<gt>new(%options)>

This method constructs a new C<Net::SMS::SMSPilot> object and returns it.
Key/value pair arguments may be provided to set up the initial state.

    apikey            The authorization key to access the API. (required)
    sender            Sender ID. Default value: 'SMSPilot.Ru'. (optional)
    charset           The encoding of characters. Default value: 'utf8'. (optional)
    secure            SSL connection: 1 - on; 0 - off. Default value: 1. (optional)
    ua                Your own LWP::UserAgent object. (optional)
    on_error          The callback to invoke error processing. (optional)

If C<apikey> absent, an object will not be created and C<undef> returned.
If C<ua> is not defined, it will be created internally. Example:

    my $sms = Net::SMS::SMSPilot->new(
        apikey      => 'GJ67....KI5R'
    );

=back

=head2 Errors processing

All methods returns C<undef> when an error is detected. Afterwards, method
C<error> returns a message describing last ocurred error.

=over

=item C<error>

Returns last error.

    my $stat = $sms->send('internet', 'My message');
    if (! defined($stat)) {
        warn($sms->error);
    }

=item Callback function

Additionally, you can define a callback function in the constructor's option C<on_error>.
This function will be fired when an error will be occurred.

    my $sms = Net::SMS::SMSPilot->new(
        apikey      => 'GJ67....KI5R',
        on_error    => sub {
            my ($err) = @_;
            log(time, $err) and die $err;
        }
    );

=back

=head2 APIKEY Info Fileds

Data, returned by C<apikey_info> method, consist of following fields:

    apikey                    Key value
    email                     E-mail key owner
    date                      Date/time of creation of a key
    history                   History key in the form of arrayref
    status                    Key status: 0 = new, 1 = waiting for activation,
                              2 = active, 3 = ran out of SMS, 4 = spam.

    sms_total                 Paid sms
    sms_sent                  Sent sms

    amount                    Amount of last payment
    currency                  Currency of the last payment
    date_paid                 Date/time of payment
    balance                   Current balance (in credit)

    date_access               Date/time of last request
    last_ip                   IP address of the last query
    allow_ip                  List of allowed IP addresses

=head2 Status of sent SMS Fileds

Data, returned by C<send()> and C<check()> methods, data represents a reference
 to an array of hashes.
 Hash consist of the following fields:

    id                        SMS ID (used to check the status of SMS)
    phone                     Phone number to sent SMS
    zone                      Zone for price (Example: 1 = Russia)
    status                    SMS status:
                               -2 = server did not receive this message (ID
                               not found);
                               -1 = message is not delivered (the subscriber's
                               phone is turned off, the operator is not
                               supported);
                               0 = new message;
                               1 = in the queue at the mobile operator;
                               2 = message is successfully delivered.

=head2 SMS sending

=over

=item C<send($to_one, $message)>

=item C<send(\@to_many,$message)>

Returns a reference to an array of hashes, with status of sent SMS ( See
"L</"Status of sent SMS Fileds">" ). For sending SMS to one recipient using
a scalar variable (C<$to_one>). For the mass sending of SMS using an
arrayref (C<\@to_many>). Example:

    $sms->send(79876543210, 'Hello world!'); # One recipient
    $sms->send([
                79876543210,
                70123456789,
               ], 'Hello world!'); # Mass sending

After executing this method will be available the additional fields of the object:

    $sms->{cost};    # the cost of sending (in credits)
    $sms->{balance}; # balance (in credit)

=back

=head2 Change SMS sender

=item C<set_sender($sender)>

The $sender can contain text in Latin script, numerals, symbols "-" and "."
length of 3-11 characters long or the number length of 10-16 numbers in
international format, "+" sign is not considered. If you can not change the
sender, it returns an undef. Example:

    $sms->set_sender('example.com');
    # or
    $sms->set_sender(89876543210);

=back

=head2 Check SMS

=over

=item C<check($id)>

=item C<check(\@ids)>

Returns a reference to an array of hashes, with status of sent SMS ( See
"L</"Status of sent SMS Fileds">" ). For check SMS to one recipient using
a scalar variable (C<$id>). For the mass check of SMS using an arrayref
(C<\@ids>). Example:

    $status1=$sms->check(12345); # Check of one SMS
    $status2=$sms->send([
                12345,
                54321,
               ]); # Check of mass SMS

=back

=head2 Information about the APIKEY

=over

=item C<apikey_info>

Returns a hash or a hashref (depending on how you invoke), with info about
the APIKEY. See "L</"APIKEY Info Fileds">". Example:

    %hash=$sms->apikey_info;
    print $hash{email}; # print e-mail the owner
    # or
    $hashref=$sms->apikey_info;
    print $hashref->{email}; # print e-mail the owner

=back

=head2 Check the current balance

=over

=item C<balance>

=item C<balance($currency)>

Returns the current balance in the currency, where C<$currency> could be the
following:

=over 4

   'sms' - in credit (default)
   'wmr' - in RUB webmoney [http://webmoney.ru]
   'rur' - in RUB Yandex.Money [http://money.yandex.ru]

=back

=back

=head1 SEE ALSO

SMSPilot API Reference in Russian, looking at L<http://www.smspilot.ru/apikey.php>

This documentation in Russian, looking at L<http://www.smspilot.ru/software.php>


=head1 COPYRIGHT

Copyright (c) 2011 Daniil Putilin. All rights reserved.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.


=head1 AUTHOR

Daniil Putilin <dadis@cpan.org>

=cut
