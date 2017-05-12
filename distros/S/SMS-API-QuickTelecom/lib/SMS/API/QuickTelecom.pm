package SMS::API::QuickTelecom;

use 5.006;
use strict;
use warnings;
use Carp qw( croak ) ;
use LWP::UserAgent;
use POSIX qw(strftime);

=head1 NAME

SMS::API::QuickTelecom - QuickTelecom SMS service on qtelecom.ru

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

my @fields = qw(
    user pass host path ssl test
    CLIENTADR comment HTTP_ACCEPT_LANGUAGE sender );

sub _set {
    my $self = shift;
    my $k = shift;
    $self->{$k} = shift;
}

sub _get {
    my $self = shift;
    $self->{shift()};
}

sub _get_post_request {
    my $class = shift;
    my %arg = @_;

    my $post = {
            user => $class->{user},
            pass => $class->{pass},
            gzip => $class->{gzip} || '',
    };
    map { $post->{$_}=$arg{$_} } keys %arg;

    my $url = 'http'.($class->{ssl} ? 's':'').'://'.$class->{host}.':'.($class->{port} ? $class->{port} : ($class->{ssl} ? 443 : 80)).($class->{path}||'').'/';

    my $ua = LWP::UserAgent->new( agent => 'Mozilla/5.0 (X11; Linux i586; rv:41.0) Gecko/20120101 Firefox/41.0' );

    my $res = $ua->post( $url, $post, 'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8', );

    if ($res->is_success) {
        $res = $res->content;
    } else {
        $res = '<?xml version="1.0" encoding="UTF-8"?><output><RECEIVER AGT_ID="';
        $res .= $class->{user};
        $res .= '" DATE_REPORT="';
        $res .= (strftime "%d.%m.%Y %T", localtime);
        $res .= '"><xml_result res="';
        $res .= $res->code();
        $res .= '" description="';
        $res .= $res->message();
        $res .= '"/></output>';
    }

    $res;
}

=head1 SYNOPSIS

    use SMS::API::QuickTelecom;

    my $qtsms = SMS::API::QuickTelecom->new(
        user => 'account-login',
        pass => 'account-password',
    );

    $qtsms->send_sms(message=>'Test-SMS', target=>'+799912345678');

    print "Balance-XML:\n".$qtsms->balance();


=head2 Overview

A quick perl port of few classes from official PHP QTSMS.class for SMS sending.

Default settings are set to use HTTPS for communication.

=head1 METHODS

=cut

=head2 B<< SMS::API::QuickTelecom->new(%options) >>

Instantiate and initialise object with the following options:

=over 4

=item C<< user => $account_name >>

Account username you receive during your registration. Mandatory.

=item C<< pass => $password >>

Account password you receive during your registration. Mandatory.

=item C<< host => $hostname // 'go.qtelecom.ru' >>

Optional.

Host name to perform POST/GET requests to. When using SSL (by default) it's default to L<go.qtelecom.ru>.

If you are willing to use insecure communication via plain HTTP then host must be set to L<service.qtelecom.ru> and C<ssl>=0.

=item C<< path => $path // '/public/http' >>

Optional.

Path on server to perform requests. Default is C</public/http>.

=item C<< ssl => $ssl // '1' >>

Optional.

Flag to use SSL, default is C<1> (on). Optional.

=item C<< gzip => $gzip // 'none' >>

Optional.

Flag to enable|disable gzip-encoding of data, possible values are: C<none> or C<on>, default is C<none>.

Optional

=item C<< comment => $comment // '' >>

Optional.

Connection description.

=item C<< HTTP_ACCEPT_LANGUAGE => $lang // 'en' >>

Optional.

Langage to use for the returned data content.

=item C<< CLIENTADR => $ip // '127.0.0.1' >>

Optional.

IP-address of the sender.  If not specified will be set to C<127.0.0.1> internally.

=item C<< sender => $sender // default >>

Optional.

Name of the sender, registered in system on L<https://go.qtelecom.ru>.

If not specified default setting from system will be used.

=back

=cut

sub new {
    my $class = shift;
    my $self = {
        'version' => $VERSION,
        'path'    => '/public/http',
        'host'    => 'go.qtelecom.ru',
        'ssl'     => 1,
        'gzip'    => 'none',
    };
    my %arg   = @_;

    bless $self, $class;

    foreach my $field (@fields) {
        $self->_set($field, $arg{$field}) if exists $arg{$field};
    }

    foreach my $field (qw/ user pass /) {
        croak "new() $field is mandatory" unless defined $self->_get($field);
    }

    $self;
}

=head2 balance

Returns an XML describing account balance and overdraft in the national currency.

Takes no parameters.

=cut

sub balance {
    shift->_get_post_request( action => 'balance' );
}

=head2 send_sms

Sends a text SMS to one or more recipients.

Return XML with report.

=over 4

=item C<< message => $message  >>

Mandatory.

Message text to send. Enconding must be ASCII or UTF-8. Internally module is using UTF-8 encoding.

=item C<< target => $recipients  >>

Mandatory.

List of recipients to send message, comma delimited if there are more than one recipient:

  "+70010001212, 80009990000"

Mutualy exclusive with C<phl_codename>

=item C<< phl_codename => $phl_codename // ''  >>

Mutualy exclusive with C<target>, one or other is mandatory.

Codename of a recipient via contact-list created on L<https://go.qtelecom.ru>.

=item C<< sender => $sender // ''  >>

Optional.

Sender's nickname, one of the registered on L<https://go.qtelecom.ru>.

=item C<< period => $period // ''  >>

Optional.

Time-to-Live for a message, units are second. Message will be discarded if system fails to deliver message over this period of time.

  Caution: this service may not work for some routes, like a CDMA phones.

=item C<< time_period => $time_period // ''  >>

Optional.

Timeperiod during which message shall be delivered to the recipients (like 10:00-21:00).
Use of this option allows to skip delivery of messages during night hours.
For this service to work correctly you may specify L<time_local> timezone.

=item C<< time_local => $time_local // ''  >>

Optional.

Selection of time zone for C<time_period> option:
  1 - means C<time_period> is local time for the recipient,
  0 - means C<time_period> was specified according to the sender settings.

=item C<< autotrimtext => $autotrimtext // ''  >>

Optional.

Automatically trim leading and trailign spaces from a message.

=back

=cut

sub send_sms {
    my $class = shift;
    my %arg = @_;

    $arg{action}='post_sms';
    $arg{sms_type}='';

    $arg{post_id}=(strftime '%s', localtime).'td'.$$ unless $arg{post_id};
    $arg{CLIENTADR}='127.0.0.1' unless $arg{CLIENTADR};
    $arg{HTTP_ACCEPT_LANGUAGE}='en-us;q=0.5,en;q=0.5' unless $arg{HTTP_ACCEPT_LANGUAGE};

    $class->_get_post_request( %arg );
}

=head2 status

    my $status_xml = $qtsms->status( sms_id => '359900000000000080' );

Returns an XML describing status of operation.

There are three ways to get a status: by C<sms_id>, or by C<sms_group_id> or by pair C<date_from> and C<date_to>.

=over 4

=item C<< sms_id => $sms_id >>

ID of the sms, taken from the tag C<ID> in responce of sending SMS.

=item C<< sms_group_id => $sms_group_id >>

ID of a group of sent messages, taken from tag C<SMS_GROUP_ID> in responce of sendin one SMS or group of SMS.

=item C<< date_from => $date_from, date_to => $date_to >>

Get status of all the messages sent during the timeframe given by C<date_from> and C<date_to>.

Format of the date is C<dd.mm.yyyy hh:ii:ss>.

Period must start in less than 4 days before the current date.

=back

=cut

sub status {
    my $class = shift;
    my %arg = @_;

    my %d = ( action => 'status' );
    foreach my $d (qw/ sms_id sms_group_id date_from date_to /) {
        $d{$d} = $arg{$d} if $arg{$d};
    }

    if (defined $d{'date_from'}) {
        croak "date_from and date_to fields both must be defined" unless defined $d{'date_to'};
        do { croak "wrong format: $_" unless $d{$_} =~ /^\d\d\.\d\d\.\d{4}\s\d\d:\d\d:\d\d$/; } foreach (qw/ date_from date_to/);
    } else {
        croak "sms_id or sms_group_id field is mandatory" unless defined $d{sms_id} or defined $d{sms_group_id};
    }

    croak "use sms_id or sms_group_id or date_from/date_to to select data"
        if (defined $d{sms_id} and (defined $d{sms_group_id} or defined $d{date_from}));
    croak "use sms_id or sms_group_id or date_from/date_to to select data"
        if (defined $d{sms_group_id} and (defined $d{sms_id} or defined $d{date_from}));

    $class->_get_post_request( %d );
}

=head1 AUTHOR

Pasichnichenko Konstantin, C<< <pasichnichenko.k at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-api-quicktelecom at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-API-QuickTelecom>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::API::QuickTelecom


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-API-QuickTelecom>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-API-QuickTelecom>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-API-QuickTelecom>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-API-QuickTelecom/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Pasichnichenko Konstantin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of SMS::API::QuickTelecom
