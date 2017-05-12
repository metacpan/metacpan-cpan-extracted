package Net::SMS::ASPSMS;

use warnings;
use strict;
use Carp;

use LWP::UserAgent;
use Net::SMS::ASPSMS::XML;
use XML::DOM;
use Encode qw(decode encode);

our $VERSION = '0.1.6';

use List::Util qw(shuffle);

my %actions = (
    send_random_logo               => 'SendRandomLogo',
    send_text_sms                  => 'SendTextSMS',
    send_picture_message           => 'SendPictureMessage',
    send_logo                      => 'SendLogo',
    send_group_logo                => 'SendGroupLogo',
    send_ringtone                  => 'SendRingtone',
    inquire_delivery_notifications => 'InquireDeliveryNotifications',
    show_credits                   => 'ShowCredits',
    send_vcard                     => 'SendVCard',
    send_binary_data               => 'SendBinaryData',
    send_wap_push_sms              => 'SendWAPPushSMS',
    send_originator_unlock_code    => 'SendOriginatorUnlockCode',
    unlock_originator              => 'UnlockOriginator',
    check_originator_authorization => 'CheckOriginatorAuthorization'
);

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->{xml} = new Net::SMS::ASPSMS::XML(@_);
    $self->{result} = {};
    return $self;
}

sub _send {
    my $self = shift;
    my $message = $self->{xml}->as_string;
    my @urls = shuffle (qw(xml1.aspsms.com:5061 xml1.aspsms.com:5098
                           xml2.aspsms.com:5061 xml2.aspsms.com:5098));
    my $ua = LWP::UserAgent->new (timeout => 10);
    foreach my $url (@urls) {
        my $req = HTTP::Request->new(POST => "http://$url/xmlsvr.asp");
        $req->content(encode("iso-8859-1", $message));
        my $res = $ua->request($req);
        if ($res->is_success) {
            $self->{status_line} = $res->status_line;
            $self->{result} = {};
            my $parser = new XML::DOM::Parser;
            my $doc = $parser->parse($res->content);
            my $node;
            foreach (qw(ErrorCode ErrorDescription CreditsUsed Credits
                ParserErrorCode ParserErrorDescription ParserErrorFilePos
                ParserErrorLine ParserErrorLinePos ParserErrorSrcText)) {
                if ($node = $doc->getElementsByTagName($_)->item(0)) {
                    $self->{result}->{$_} =
                        $node->getFirstChild->getNodeValue;
                }
            }
            my $dn = $doc->getElementsByTagName("DeliveryNotification")
                ->item(0);
            if ($dn) {
                $self->{result}->{DeliveryNotification} = {};
                foreach (qw(TransRefNumber DeliveryStatus SubmissionDate
                    NotificationDate ReasonCode)) {
                     if ($node = $dn->getElementsByTagName($_)->item(0)) {
                        $self->{result}->{DeliveryNotification}->{$_} =
                            $node->getFirstChild->getNodeValue;
                    }
                }
            }
            last
        }
    }
}

sub params {
    my $self = shift;
    $self->{xml}->initialize(@_);
}

sub result {
    my $self = shift;
    return $self->{result};
}

sub AUTOLOAD {
    my $self = shift or return undef;
    (my $method = our $AUTOLOAD) =~ s{.*::}{};
    return if $method eq 'DESTROY';

    if (exists $actions{$method}) {
        $self->{xml}->initialize(@_);
        $self->{xml}->action($actions{$method});
        $self->_send;
    }
}

1;
__END__

=head1 NAME

Net::SMS::ASPSMS - Interface to ASPSMS services


=head1 VERSION

This document describes Net::SMS::ASPSMS version 0.1.6


=head1 SYNOPSIS

    use Net::SMS::ASPSMS;

    my $sms = new Net::SMS::ASPSMS(
        userkey => "MyUserKey",
        password => "SecReT",
    );
    $sms->show_credits();
    printf "You still have %s units\n", $sms->result->{Credits};

    $sms->send_text_sms(
        Recipient_PhoneNumber => "+5150123456",
        Originator => "Myself",
        MessageData => "Hello World",
    );
    printf "Result: %s\n", $sms->result->{ErrorDescription};


=head1 DESCRIPTION

Net::SMS::ASPSMS provides an interface to the ASPSMS services.


=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. 
Please report problems to Jacques Supcik C<< <supcik@cpan.org> >>.
Patches are welcome.


=head1 AUTHOR

Jacques Supcik  C<< <supcik@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Jacques Supcik C<< <supcik@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

