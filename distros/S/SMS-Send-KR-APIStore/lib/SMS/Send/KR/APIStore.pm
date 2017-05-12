package SMS::Send::KR::APIStore;
# ABSTRACT: An SMS::Send driver for the apistore.co.kr SMS service

use utf8;
use strict;
use warnings;

our $VERSION = '0.003';

use parent qw( SMS::Send::Driver );

use HTTP::Tiny;
use JSON;

our $URL     = "http://api.apistore.co.kr/ppurio/1";
our $AGENT   = 'SMS-Send-KR-APIStore/' . $SMS::Send::KR::APIStore::VERSION;
our $TIMEOUT = 3;
our $TYPE    = 'SMS';
our $DELAY   = 0;

our %ERROR_CODE = (
    '4100' => 'sms:전달',
    '4421' => 'sms:타임아웃',
    '4426' => 'sms:재시도한도초과',
    '4425' => 'sms:단말기호처리중',
    '4400' => 'sms:음영지역',
    '4401' => 'sms:단말기전원꺼짐',
    '4402' => 'sms:단말기메시지저장초과',
    '4410' => 'sms:잘못된번호',
    '4422' => 'sms:단말기일시정지',
    '4427' => 'sms:기타단말기문제',
    '4405' => 'sms:단말기 busy',
    '4423' => 'sms:단말기착신거부',
    '4412' => 'sms:착신거절',
    '4411' => 'sms:NPDB 에러',
    '4428' => 'sms:시스템에러',
    '4404' => 'sms:가입자위치정보없음',
    '4413' => 'sms:SMSC 형식오류',
    '4414' => 'sms:비가입자,결번,서비스정지',
    '4424' => 'sms:URL SMS 미지원폰',
    '4403' => 'sms:메시지삭제됨',
    '4430' => 'sms:스팸',
    '4431' => 'sms:발송제한 수신거부(스팸)',
    '4432' =>
        'sms:번호도용문자 차단서비스에 가입된 발신번호(개인)사용',
    '4433' =>
        'sms:번호도용문자 차단서비스에 가입된 발신번호(개인)사용',
    '4434' => 'sms:발신번호 사전 등록제에 의한 미등록 차단',
    '4435' => 'sms:KISA 에 스팸 신고된 발신번호 사용',
    '4436' => 'sms:발신번호 사전 등록제 번호규칙 위반',
    '4420' => 'sms:기타에러',

    '6600' => 'mms:전달',
    '6601' => 'mms:타임아웃',
    '6602' => 'mms:핸드폰호처리중',
    '6603' => 'mms:음영지역',
    '6604' => 'mms:전원이꺼져있음',
    '6605' => 'mms:메시지저장개수초과',
    '6606' => 'mms:잘못된번호',
    '6607' => 'mms:서비스일시정지',
    '6608' => 'mms:기타단말기문제',
    '6609' => 'mms:착신거절',
    '6610' => 'mms:기타에러',
    '6611' => 'mms:통신사의 SMC 형식오류',
    '6612' => 'mms:게이트웨이의형식오류',
    '6613' => 'mms:서비스불가단말기',
    '6614' => 'mms:핸드폰호불가상태',
    '6615' => 'mms:SMC 운영자에의해삭제',
    '6616' => 'mms:통신사의메시지큐초과',
    '6617' => 'mms:통신사의스팸처리',
    '6618' => 'mms:공정위의스팸처리',
    '6619' => 'mms:게이트웨이의스팸처리',
    '6620' => 'mms:발송건수초과',
    '6621' => 'mms:메시지의길이초과',
    '6622' => 'mms:잘못된번호형식',
    '6623' => 'mms:잘못된데이터형식',
    '6624' => 'mms:MMS 정보를찾을수없음',
    '6625' => 'mms:NPDB 에러',
    '6626' => 'mms:080 수신거부(SPAM)',
    '6627' => 'mms:발신제한 수신거부(SPAM)',
    '6628' =>
        'mms:번호도용문자 차단서비스에 가입된 발신번호(개인)사용',
    '6629' =>
        'mms:번호도용문자 차단서비스에 가입된 발신번호(개인)사용',
    '6630' => 'mms:서비스 불가 번호',
    '6631' => 'mms:발신번호 사전 등록제에 의한 미등록 차단',
    '6632' => 'mms:KISA 에 스팸 신고된 발신번호 사용',
    '6633' => 'mms:발신번호 사전 등록제 번호규칙 위반',
    '6670' => 'mms:이미지파일크기제한',

    '9903' => '선불사용자 사용금지',
    '9904' => 'Block time(날짜제한)',
    '9082' => '발송해제',
    '9083' => 'IP 차단',
    '9023' => 'Callback error',
    '9905' => 'Block time(요일제한)',
    '9010' => '아이디 틀림',
    '9011' => '비밀번호 틀림',
    '9012' => '중복접속량 많음',
    '9013' => '발송시간 지난 데이터',
    '9014' => '시간제한(리포트 수신대기 timeout)',
    '9020' => 'Wrong Data Format',
    '9021' => 'Wrong Data Format',
    '9022' => 'Wrong Data Format(cinfo가 특수 문자/공백을 포함)',
    '9080' => 'Deny User Ack',
    '9214' => 'Wrong Phone Num',
    '9311' => 'Fax File Not Found',
    '9908' => 'PHONE, FAX 선불사용자 제한기능',
    '9090' => '기타에러',

    '-1' => '잘못된 데이터 형식 발송오류',
);

sub new {
    my $class  = shift;
    my %params = (
        _url           => $SMS::Send::KR::APIStore::URL,
        _agent         => $SMS::Send::KR::APIStore::AGENT,
        _timeout       => $SMS::Send::KR::APIStore::TIMEOUT,
        _from          => q{},
        _type          => $SMS::Send::KR::APIStore::TYPE,
        _delay         => $SMS::Send::KR::APIStore::DELAY,
        _id            => q{},
        _api_store_key => q{},
        @_,
    );

    die "$class->new: _id is needed\n"            unless $params{_id};
    die "$class->new: _api_store_key is needed\n" unless $params{_api_store_key};
    die "$class->new: _from is needed\n"          unless $params{_from};
    die "$class->new: _type is invalid\n"
        unless $params{_type} && $params{_type} =~ m/^(SMS|LMS)$/i;

    my $self = bless \%params, $class;
    return $self;
}

sub send_sms {
    my $self   = shift;
    my %params = (
        _from    => $self->{_from},
        _type    => $self->{_type} || 'SMS',
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

    $ret{reason} = 'text is needed', return \%ret unless $text;
    $ret{reason} = 'to is needed',   return \%ret unless $to;
    $ret{reason} = '_type is invalid', return \%ret
        unless $type && $type =~ m/^(SMS|LMS)$/i;

    my $http = HTTP::Tiny->new(
        agent           => $self->{_agent},
        timeout         => $self->{_timeout},
        default_headers => { 'x-waple-authorization' => $self->{_api_store_key} },
    ) or $ret{reason} = 'cannot generate HTTP::Tiny object', return \%ret;
    my $url = sprintf '%s/message/%s/%s', $self->{_url}, lc($type), $self->{_id};

    #
    # delay / send_time: reserve SMS
    #
    my $send_time;
    if ($delay) {
        my $t = DateTime->now( time_zone => 'Asia/Seoul' )->add( seconds => $delay );
        $send_time = $t->ymd(q{}) . $t->hms(q{});
    }
    if ($epoch) {
        my $t = DateTime->from_epoch(
            time_zone => 'Asia/Seoul',
            epoch     => $epoch,
        );
        $send_time = $t->ymd(q{}) . $t->hms(q{});
    }

    #
    # subject
    #
    undef $subject if $type =~ m/SMS/i;

    my %form = (
        dest_phone => $to,
        send_phone => $from,
        subject    => $subject,
        msg_body   => $text,
        send_time  => $send_time,
    );
    $form{$_} or delete $form{$_} for keys %form;

    my $res = $http->post_form( $url, \%form );
    $ret{reason} = 'cannot get valid response for POST request';
    if ( $res && $res->{success} ) {
        $ret{detail} = decode_json( $res->{content} );
        $ret{success} = 1 if $ret{detail}{result_code} eq '200';

        $ret{reason} = 'unknown error';
        $ret{reason} = 'user error' if $ret{detail}{result_code} eq '100';
        $ret{reason} = 'ok' if $ret{detail}{result_code} eq '200';
        $ret{reason} = 'parameter error' if $ret{detail}{result_code} eq '300';
        $ret{reason} = 'etc error' if $ret{detail}{result_code} eq '400';
        $ret{reason} = 'prevent unregistered caller identification'
            if $ret{detail}{result_code} eq '500';
        $ret{reason} = 'not enough pre-payment charge' if $ret{detail}{result_code} eq '600';
    }
    else {
        $ret{detail} = $res;
        $ret{reason} = 'unknown error';
    }

    return \%ret;
}

sub report {
    my ( $self, $cmid_obj ) = @_;

    my %ret = (
        success     => 0,
        reason      => q{},
        cmid        => q{},
        call_status => q{},
        dest_phone  => q{},
        report_time => q{},
        umid        => q{},
    );

    $ret{reason} = 'cmid is needed', return \%ret unless defined $cmid_obj;

    my $cmid;
    if ( !ref($cmid_obj) ) {
        $cmid = $cmid_obj;
    }
    elsif ( ref($cmid_obj) eq 'HASH' ) {
        $cmid = $cmid_obj->{detail}{cmid};
    }
    else {
        $ret{reason} = 'invalid cmid';
        return \%ret;
    }
    $ret{cmid} = $cmid;

    my $http = HTTP::Tiny->new(
        agent           => $self->{_agent},
        timeout         => $self->{_timeout},
        default_headers => { 'x-waple-authorization' => $self->{_api_store_key} },
    ) or $ret{reason} = 'cannot generate HTTP::Tiny object', return \%ret;
    my $url = sprintf '%s/message/%s/%s', $self->{_url}, 'report', $self->{_id};

    my %form = ( cmid => $cmid );
    $form{$_} or delete $form{$_} for keys %form;
    my $params = $http->www_form_urlencode( \%form );

    my $res = $http->get("$url?$params");
    $ret{reason} = 'cannot get valid response for GET request';
    if ( $res && $res->{success} ) {
        my $detail = decode_json( $res->{content} );

        $ret{success}     = 1 if $detail->{call_status} =~ m/^(4100|6600)$/;
        $ret{reason}      = $ERROR_CODE{ $detail->{call_status} };
        $ret{call_status} = $detail->{call_status};
        $ret{dest_phone}  = $detail->{dest_phone};
        $ret{report_time} = $detail->{report_time};
        $ret{umid}        = $detail->{umid};
    }
    else {
        $ret{detail} = $res;
        $ret{reason} = 'unknown error';
    }

    return \%ret;
}

sub cid {
    my ( $self, $cid, $cid_desc ) = @_;

    if ($cid) {
        my %ret = (
            success => 0,
            reason  => q{},
        );

        my $http = HTTP::Tiny->new(
            agent           => $self->{_agent},
            timeout         => $self->{_timeout},
            default_headers => { 'x-waple-authorization' => $self->{_api_store_key} },
        ) or $ret{reason} = 'cannot generate HTTP::Tiny object', return \%ret;

        my $url = sprintf '%s/sendnumber/%s/%s', $self->{_url}, 'save', $self->{_id};

        my %form = (
            sendnumber => $cid,
            comment    => $cid_desc,
        );
        $form{$_} or delete $form{$_} for keys %form;

        my $res = $http->post_form( $url, \%form );
        $ret{reason} = 'cannot get valid response for POST request';

        if ( $res && $res->{success} ) {
            $ret{detail} = decode_json( $res->{content} );

            if ( $ret{detail}{result_code} eq '200' ) {
                $ret{success} = 1;
                $ret{reason}  = 'ok';
            }
            else {
                $ret{reason} = 'unknown error';
                $ret{reason} = 'user error' if $ret{detail}{result_code} eq '100';
                $ret{reason} = 'parameter error' if $ret{detail}{result_code} eq '300';
                $ret{reason} = 'etc error' if $ret{detail}{result_code} eq '400';
                $ret{reason} = 'prevent unregistered caller identification'
                    if $ret{detail}{result_code} eq '500';
                $ret{reason} = 'not enough pre-payment charge' if $ret{detail}{result_code} eq '600';
            }
        }
        else {
            $ret{detail} = $res;
            $ret{reason} = 'unknown error';
        }

        return \%ret;
    }
    else {
        my %ret = (
            success     => 0,
            reason      => q{},
            number_list => q{},
        );

        my $http = HTTP::Tiny->new(
            agent           => $self->{_agent},
            timeout         => $self->{_timeout},
            default_headers => { 'x-waple-authorization' => $self->{_api_store_key} },
        ) or $ret{reason} = 'cannot generate HTTP::Tiny object', return \%ret;

        my $url = sprintf '%s/sendnumber/%s/%s', $self->{_url}, 'list', $self->{_id};

        my $res = $http->get($url);
        $ret{reason} = 'cannot get valid response for GET request';

        if ( $res && $res->{success} ) {
            $ret{detail} = decode_json( $res->{content} );

            if ( $ret{detail}{result_code} eq '200' ) {
                $ret{success}     = 1;
                $ret{reason}      = 'ok';
                $ret{number_list} = $ret{detail}{numberList} unless $cid;
            }
            else {
                $ret{reason} = 'unknown error';
                $ret{reason} = 'user error' if $ret{detail}{result_code} eq '100';
                $ret{reason} = 'parameter error' if $ret{detail}{result_code} eq '300';
                $ret{reason} = 'etc error' if $ret{detail}{result_code} eq '400';
                $ret{reason} = 'prevent unregistered caller identification'
                    if $ret{detail}{result_code} eq '500';
                $ret{reason} = 'not enough pre-payment charge' if $ret{detail}{result_code} eq '600';
            }
        }
        else {
            $ret{detail} = $res;
            $ret{reason} = 'unknown error';
        }

        return \%ret;
    }
}

1;

#
# This file is part of SMS-Send-KR-APIStore
#
# This software is copyright (c) 2017 by Keedi Kim.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::KR::APIStore - An SMS::Send driver for the apistore.co.kr SMS service

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use SMS::Send;

    # create the sender object
    my $sender = SMS::Send->new('KR::APIStore',
        _id            => 'keedi',
        _api_store_key => 'XXXXXXXX',
        _from          => '01025116893',
    );

    # send a message
    my $sent = $sender->send_sms(
        text  => 'You message may use up to 80 chars and must be utf8',
        to    => '01012345678',
    );

    unless ( $sent->{success} ) {
        warn "failed to send sms: $sent->{reason}\n";

        # if you want to know detail more, check $sent->{detail}
        use Data::Dumper;
        warn Dumper $sent->{detail};
    }

    # Of course you can send LMS
    my $sender = SMS::Send->new('KR::APIStore',
        _id            => 'keedi',
        _api_store_key => 'XXXXXXXX',
        _type          => 'lms',
        _from          => '01025116893',
    );

    # You can override _from or _type

    #
    # send a message
    #
    my $sent = $sender->send_sms(
        text     => 'You LMS message may use up to 2000 chars and must be utf8',
        to       => '01025116893',
        _from    => '02114',             # you can override $self->_from
        _type    => 'LMS',               # you can override $self->_type
        _subject => 'This is a subject', # subject is optional & up to 40 chars
    );

    #
    # check the result
    #
    my $result = $sender->report("20130314163439459");
    printf "success:     %s\n", $result->{success} ? 'success' : 'fail';
    printf "reason:      %s\n", $result->{reason};
    printf "call_status: %s\n", $result->{call_status};
    printf "dest_phone:  %s\n", $result->{dest_phone};
    printf "report_time: %s\n", $result->{report_time};
    printf "cmid:        %s\n", $result->{cmid};
    printf "umid:        %s\n", $result->{umid};

    # you can use cmid of the send_sms() result
    my $sent = $sender->send_sms( ... );
    my $result = $sender->report( $sent->{detail}{cmid} );

    # or you can use the send_sms() result itself
    my $sent = $sender->send_sms( ... );
    my $result = $sender->report($sent);

    #
    # set caller id
    #

    # set caller id only
    my $ret = $sender->cid( "0XXXXXXXXX" );

    # set caller id and its description
    my $ret = $sender->cid( "0XXXXXXXXX", "Office #201" );

    #
    # get caller id list
    #
    my $ret = $sender->cid;
    if ( $ret->{success} ) {
        my $cids = $ret->{number_list};
        my $idx = 0;
        for my $cid (@$cids) {
            say "$idx:";
            say "     client_id: " . $cid->{client_id};
            say "       comment: " . ( $cid->{comment} || q{} );
            say "    sendnumber: " . $cid->{sendnumber};
            ++$idx;
        }
    }
    else {
        say "failed to get cid info: $ret->{reason}"
    }

=head1 DESCRIPTION

SMS::Send driver for sending SMS messages with the L<APIStore SMS service|http://www.apistore.co.kr/api/apiView.do?service_seq=151>.
Current version of APIStore SMS service DOES NOT support HTTPS,
so you have to use this module at your own risk.

=head1 ATTRIBUTES

=head2 _url

DO NOT change this value except for testing purpose.
Default is C<"http://api.openapi.io/ppurio/1/message">.

=head2 _agent

The agent value is sent as the "User-Agent" header in the HTTP requests.
Default is C<"SMS-Send-KR-APIStore/#.###">.

=head2 _timeout

HTTP request timeout seconds.
Default is C<3>.

=head2 _id

B<Required>.
APIStore API id for REST API.

=head2 _api_store_key

B<Required>.
APIStore API key for REST API.

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

Available parameters are:

=over 4

=item *

_url

=item *

_agent

=item *

_timeout

=item *

_from

=item *

_type

=item *

_delay

=item *

_id

=item *

_api_store_key

=back

=head2 send_sms

This method should not be called directly. See L<SMS::Send> for details.

Available parameters are:

=over 4

=item *

text

=item *

to

=item *

_from

=item *

_type

=item *

_delay

=item *

_subject

=item *

_epoch

=back

=head2 report

This method checks the result of the request.

=head2 cid

This method gets/sets the caller id information.

=head1 SEE ALSO

=over 4

=item *

L<SMS::Send>

=item *

L<SMS::Send::Driver>

=item *

L<APIStore REST API|http://www.apistore.co.kr/api/apiView.do?service_seq=151>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/keedi/SMS-Send-KR-APIStore/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/keedi/SMS-Send-KR-APIStore>

  git clone https://github.com/keedi/SMS-Send-KR-APIStore.git

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Hyungsuk Hong

Hyungsuk Hong <aanoaa@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
