package SMS::Send::KR::Aligo;
# ABSTRACT: An SMS::Send driver for the smartsms.aligo.in SMS service

use utf8;
use strict;
use warnings;

our $VERSION = '0.005';

use parent qw( SMS::Send::Driver );

use HTTP::Tiny;
use JSON;

our $URL     = "https://apis.aligo.in";
our $AGENT   = "SMS-Send-KR-Aligo/" . $SMS::Send::KR::Aligo::VERSION;
our $TIMEOUT = 3;
our $TYPE    = "SMS";
our $DELAY   = 0;

sub new {
    my $class  = shift;
    my %params = (
        _url     => $SMS::Send::KR::Aligo::URL,
        _agent   => $SMS::Send::KR::Aligo::AGENT,
        _timeout => $SMS::Send::KR::Aligo::TIMEOUT,
        _from    => q{},
        _type    => $SMS::Send::KR::Aligo::TYPE,
        _delay   => $SMS::Send::KR::Aligo::DELAY,
        _id      => q{},
        _api_key => q{},
        @_,
    );

    die "$class->new: _id is needed\n"      unless $params{_id};
    die "$class->new: _api_key is needed\n" unless $params{_api_key};
    die "$class->new: _from is needed\n"    unless $params{_from};
    die "$class->new: _type is invalid\n"
        unless $params{_type} && $params{_type} =~ m/^(SMS|LMS)$/i;

    my $self = bless \%params, $class;
    return $self;
}

sub send_sms {
    my $self   = shift;
    my %params = (
        _from    => $self->{_from},
        _type    => $self->{_type} || "SMS",
        _delay   => $self->{_delay} || 0,
        _subject => $self->{_subject},
        _epoch   => q{},
        @_,
    );

    my $text    = $params{text};
    my $to      = $params{to};
    my $from    = $params{_from};
    my $type    = $params{_type};
    my $delay   = $params{_delay};
    my $subject = $params{_subject};
    my $epoch   = $params{_epoch};

    my %ret = (
        success => 0,
        reason  => q{},
        detail  => +{},
    );

    $ret{reason} = "text is needed", return \%ret unless $text;
    $ret{reason} = "to is needed",   return \%ret unless $to;
    $ret{reason} = "_type is invalid", return \%ret
        unless $type && $type =~ m/^(SMS|LMS)$/i;

    my $http = HTTP::Tiny->new(
        agent   => $self->{_agent},
        timeout => $self->{_timeout},
    ) or $ret{reason} = "cannot generate HTTP::Tiny object", return \%ret;
    my $url = sprintf "%s/send/", $self->{_url};

    #
    # delay / send_time: reserve SMS
    #
    my $send_time_dt;
    if ($delay) {
        $send_time_dt = DateTime->now( time_zone => "Asia/Seoul" )->add( seconds => $delay );
    }
    if ($epoch) {
        $send_time_dt = DateTime->from_epoch(
            time_zone => "Asia/Seoul",
            epoch     => $epoch,
        );
    }

    #
    # subject
    #
    undef $subject if $type =~ m/SMS/i;

    my %form = (
        key      => $self->{_api_key},
        user_id  => $self->{_id},
        receiver => $to,
        sender   => $from,
        title    => $subject,
        msg      => $text,
        msg_type => uc($type),
    );
    if ($send_time_dt) {
        $form{rdate} = $send_time_dt->ymd(q{});
        $form{rtime} = $send_time_dt->strftime("%H%M");
    }
    $form{$_} or delete $form{$_} for keys %form;

    my $res = $http->post_form( $url, \%form );
    $ret{reason} = "cannot get valid response for POST request";
    if ( $res && $res->{success} ) {
        $ret{detail} = decode_json( $res->{content} );
        if ( $ret{detail}{result_code} >= 0 ) {
            $ret{success} = 1;
            $ret{reason}  = q{};
        }
        else {
            $ret{reason} = $ret{detail}{message};
        }
    }
    else {
        $ret{detail} = $res;
        $ret{reason} = "unknown error";
    }

    return \%ret;
}

1;

#
# This file is part of SMS-Send-KR-Aligo
#
# This software is copyright (c) 2021 by Keedi Kim.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::KR::Aligo - An SMS::Send driver for the smartsms.aligo.in SMS service

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use SMS::Send;

    # create the sender object
    my $sender = SMS::Send->new("KR::Aligo",
        _id      => "keedi",
        _api_key => "XXXXXXXX",
        _from    => "01025116893",
    );

    # send a message
    my $sent = $sender->send_sms(
        text  => "You message may use up to 90 chars and must be utf8",
        to    => "01012345678",
    );

    unless ( $sent->{success} ) {
        warn "failed to send sms: $sent->{reason}\n";

        # if you want to know detail more, check $sent->{detail}
        use Data::Dumper;
        warn Dumper $sent->{detail};
    }

    # Of course you can send LMS
    my $sender = SMS::Send->new("KR::Aligo",
        _id      => "keedi",
        _api_key => "XXXXXXXX",
        _type    => "lms",
        _from    => "01025116893",
    );

    # You can override _from or _type

    #
    # send a message
    #
    my $sent = $sender->send_sms(
        text     => "You LMS message may use up to 2000 chars and must be utf8",
        to       => "01025116893",
        _from    => "02114",             # you can override $self->_from
        _type    => "LMS",               # you can override $self->_type
        _subject => "This is a subject", # subject is optional & up to 40 chars
    );

=head1 DESCRIPTION

SMS::Send driver for sending SMS messages with the L<Aligo SMS service|https://smartsms.aligo.in/admin/api/spec.html>.

=head1 ATTRIBUTES

=head2 _url

DO NOT change this value except for testing purpose.
Default is C<"https://apis.aligo.in">.

=head2 _agent

The agent value is sent as the "User-Agent" header in the HTTP requests.
Default is C<"SMS-Send-KR-Aligo/#.###">.

=head2 _timeout

HTTP request timeout seconds.
Default is C<3>.

=head2 _id

B<Required>.
Aligo API id for REST API.

=head2 _api_key

B<Required>.
Aligo API key for REST API.

=head2 _from

B<Required>.
Source number to send sms.

=head2 _type

Type of sms.
Currently C<SMS> and C<LMS> are supported.
Default is C<"SMS">.

=head2 _delay

Delay second between sending sms.
Default is C<0>.

=head1 METHODS

=head2 new

This constructor should not be called directly. See L<SMS::Send> for details.

Available L<attributes|/ATTRIBUTES> are:

=over 4

=item *

C<_url>

=item *

C<_agent>

=item *

C<_timeout>

=item *

C<_from>

=item *

C<_type>

=item *

C<_delay>

=item *

C<_id>

=item *

C<_api_key>

=back

=head2 send_sms

This method should not be called directly. See L<SMS::Send> for details.

Available parameters are:

=over 4

=item *

C<text>: SMS: 0 ~ 90 Byte, LMS/MMS: 1 ~ 2000 Byte

=item *

C<to>: Number of the receiver

=item *

C<_from>: B<[OPTIONAL]> Registered number of the sender. Use this parameter to override the initial attribute value.

=item *

C<_type>: B<[OPTIONAL]> C<SMS>, C<LMS>, C<MMS>. Use this parameter to override the initial attribute value.

=item *

C<_delay>: B<[OPTIONAL]> Delay second between sending sms. Default is C<0>.

=item *

C<_subject>: B<[OPTIONAL]> 1 ~ 44 Byte only for LMS/MMS. Default is to use the first part of the C<text> as a subject.

=item *

C<_epoch>: B<[OPTIONAL]> Reservation scheduling to send sms. Based on Asia/Seoul time zone. Default is to send sms from the fly.

=back

=head1 SEE ALSO

=over 4

=item *

L<SMS::Send>

=item *

L<SMS::Send::Driver>

=item *

L<Aligo REST API|https://smartsms.aligo.in/admin/api/spec.html>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/keedi/p5-SMS-Send-KR-Aligo/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/keedi/p5-SMS-Send-KR-Aligo>

  git clone https://github.com/keedi/p5-SMS-Send-KR-Aligo.git

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
