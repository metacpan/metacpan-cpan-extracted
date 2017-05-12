package SMS::Send::KR::CoolSMS;
# ABSTRACT: An SMS::Send driver for the coolsms.co.kr service
$SMS::Send::KR::CoolSMS::VERSION = '1.003';
use strict;
use warnings;
use parent qw( SMS::Send::Driver );

use DateTime;
use Digest::HMAC_MD5;
use HTTP::Tiny;
use JSON;
use String::Random;

our $URL     = "https://api.coolsms.co.kr/sms/1.1";
our $AGENT   = 'SMS-Send-KR-CoolSMS/' . $SMS::Send::KR::CoolSMS::VERSION;
our $TIMEOUT = 3;
our $TYPE    = 'SMS';
our $COUNTRY = 'KR';
our $DELAY   = 0;

#
# supported country code from coolsms HTTP API PDF document
# http://open.coolsms.co.kr/download/222303
#
my %country_code = (
    AR => { code => "AR", no => 54,  name => "Argentina" },
    AM => { code => "AM", no => 374, name => "Armenia" },
    AU => { code => "AU", no => 61,  name => "Australia" },
    AT => { code => "AT", no => 43,  name => "Austria" },
    BH => { code => "BH", no => 973, name => "Bahrain" },
    BD => { code => "BD", no => 880, name => "Bangladesh" },
    BE => { code => "BE", no => 32,  name => "Belgium" },
    BT => { code => "BT", no => 975, name => "Bhutan" },
    BO => { code => "BO", no => 591, name => "Bolivia" },
    BR => { code => "BR", no => 55,  name => "Brazil" },
    BN => { code => "BN", no => 673, name => "Brunei Darussalam" },
    BG => { code => "BG", no => 359, name => "Bulgaria" },
    KH => { code => "KH", no => 855, name => "Cambodia" },
    CM => { code => "CM", no => 237, name => "Cameroon" },
    CL => { code => "CL", no => 56,  name => "Chile" },
    CN => { code => "CN", no => 86,  name => "China" },
    CO => { code => "CO", no => 57,  name => "Colombia" },
    CU => { code => "CU", no => 53,  name => "Cuba" },
    DK => { code => "DK", no => 45,  name => "Denmark" },
    EG => { code => "EG", no => 20,  name => "Egypt" },
    ET => { code => "ET", no => 251, name => "Ethiopia" },
    FI => { code => "FI", no => 358, name => "Finland" },
    FR => { code => "FR", no => 33,  name => "France" },
    GA => { code => "GA", no => 241, name => "Gabon" },
    DE => { code => "DE", no => 49,  name => "Germany" },
    GH => { code => "GH", no => 233, name => "Ghana" },
    GR => { code => "GR", no => 30,  name => "Greece" },
    GL => { code => "GL", no => 299, name => "Greenland" },
    GY => { code => "GY", no => 592, name => "Guyana" },
    HK => { code => "HK", no => 852, name => "Hong Kong" },
    HU => { code => "HU", no => 36,  name => "Hungary" },
    IS => { code => "IS", no => 354, name => "Iceland" },
    IN => { code => "IN", no => 91,  name => "India" },
    IR => { code => "IR", no => 98,  name => "Iran" },
    IQ => { code => "IQ", no => 964, name => "Iraq" },
    IE => { code => "IE", no => 353, name => "Ireland" },
    IL => { code => "IL", no => 972, name => "Israel" },
    IT => { code => "IT", no => 39,  name => "Italy" },
    JP => { code => "JP", no => 81,  name => "Japan" },
    KZ => { code => "KZ", no => 7,   name => "Kazakhstan" },
    KE => { code => "KE", no => 254, name => "Kenya" },
    KR => { code => "KR", no => 82,  name => "Korea" },
    KW => { code => "KW", no => 965, name => "Kuwait" },
    LA => { code => "LA", no => 856, name => "Lao People's Democratic Republic" },
    LB => { code => "LB", no => 961, name => "Lebanon" },
    LY => { code => "LY", no => 218, name => "Libya" },
    LU => { code => "LU", no => 352, name => "Luxembourg" },
    MO => { code => "MO", no => 853, name => "Macao" },
    MG => { code => "MG", no => 261, name => "Madagascar" },
    MY => { code => "MY", no => 60,  name => "Malaysia" },
    MX => { code => "MX", no => 52,  name => "Mexico" },
    MC => { code => "MC", no => 377, name => "Monaco" },
    MN => { code => "MN", no => 976, name => "Mongolia" },
    MM => { code => "MM", no => 95,  name => "Myanmar" },
    NP => { code => "NP", no => 977, name => "Nepal" },
    NL => { code => "NL", no => 31,  name => "Netherlands" },
    NZ => { code => "NZ", no => 64,  name => "New Zealand" },
    NG => { code => "NG", no => 234, name => "Nigeria" },
    NO => { code => "NO", no => 47,  name => "Norway" },
    PK => { code => "PK", no => 92,  name => "Pakistan" },
    PY => { code => "PY", no => 595, name => "Paraguay" },
    PH => { code => "PH", no => 63,  name => "Philippines" },
    PL => { code => "PL", no => 48,  name => "Poland" },
    PT => { code => "PT", no => 351, name => "Portugal" },
    RO => { code => "RO", no => 40,  name => "Romania" },
    RU => { code => "RU", no => 7,   name => "Russian Federation" },
    SN => { code => "SN", no => 221, name => "Senegal" },
    SG => { code => "SG", no => 65,  name => "Singapore" },
    SK => { code => "SK", no => 42,  name => "Slovakia" },
    SI => { code => "SI", no => 386, name => "Slovenia" },
    ZA => { code => "ZA", no => 27,  name => "South Africa" },
    ES => { code => "ES", no => 34,  name => "Spain" },
    LK => { code => "LK", no => 94,  name => "Sri Lanka" },
    SZ => { code => "SZ", no => 268, name => "Swaziland" },
    SE => { code => "SE", no => 46,  name => "Sweden" },
    CH => { code => "CH", no => 41,  name => "Switzerland" },
    SY => { code => "SY", no => 963, name => "Syrian Arab Republic" },
    TW => { code => "TW", no => 886, name => "Taiwan" },
    TH => { code => "TH", no => 66,  name => "Thailand" },
    TR => { code => "TR", no => 90,  name => "Turkey" },
    AE => { code => "AE", no => 971, name => "United Arab Emirates" },
    GB => { code => "GB", no => 44,  name => "United Kingdom" },
    US => { code => "US", no => 1,   name => "United States" },
    UZ => { code => "UZ", no => 7,   name => "Uzbekistan" },
    VE => { code => "VE", no => 58,  name => "Venezuela" },
    VN => { code => "VN", no => 84,  name => "Viet Nam" },
);

# 7 => [ KZ / RU / UZ ]
my %country_no = map { $country_code{$_}{no} => $country_code{$_} } keys %country_code;

sub new {
    my $class  = shift;
    my %params = (
        _url        => $SMS::Send::KR::CoolSMS::URL,
        _agent      => $SMS::Send::KR::CoolSMS::AGENT,
        _timeout    => $SMS::Send::KR::CoolSMS::TIMEOUT,
        _api_key    => q{},
        _api_secret => q{},
        _from       => q{},
        _type       => $SMS::Send::KR::CoolSMS::TYPE,
        _country    => $SMS::Send::KR::CoolSMS::COUNTRY,
        _delay      => $SMS::Send::KR::CoolSMS::DELAY,
        @_,
    );

    die "$class->new: _api_key is needed\n"    unless $params{_api_key};
    die "$class->new: _api_secret is needed\n" unless $params{_api_secret};
    die "$class->new: _from is needed\n"       unless $params{_from};
    die "$class->new: _type is invalid\n"      unless $params{_type} && $params{_type} =~ m/^(SMS|LMS)$/i;

    my $self = bless \%params, $class;
    return $self;
}

sub _auth_params {
    my $self = shift;

    my $api_key    = $self->{_api_key};
    my $api_secret = $self->{_api_secret};

    my %auth_params = do {
        my $time       = time;
        my $salt       = String::Random::random_regex('\w{30}');
        my $signature  = Digest::HMAC_MD5::hmac_md5_hex( "$time$salt", $api_secret );

         (
            api_key   => $api_key,
            timestamp => $time,
            salt      => $salt,
            signature => $signature,
            algorithm => 'md5',
            encoding  => 'hex',
        );
    };

    return %auth_params;
}

sub balance {
    my $self = shift;

    my %ret = (
        success => 0,
        reason  => q{},
        detail  => +{},
    );

    my $http = HTTP::Tiny->new(
        agent       => $self->{_agent},
        timeout     => $self->{_timeout},
        SSL_options => { SSL_hostname => q{} }, # coolsms does not support SNI
    ) or $ret{reason} = 'cannot generate HTTP::Tiny object', return \%ret;
    my $url = $self->{_url} . "/balance";

    my $params = $http->www_form_urlencode(+{ $self->_auth_params });
    my $res = $http->get( "$url?$params" );
    $ret{reason} = 'cannot get valid response for GET request';
    if ( $res && $res->{success} ) {
        $ret{detail}  = decode_json( $res->{content} );
        $ret{reason}  = 'OK';
        $ret{success} = 1;
    }
    else {
        $ret{detail} = $res;
        $ret{reason} = $res->{reason};
    }

    return \%ret;
}

sub send_sms {
    my $self   = shift;
    my %params = (
        _from    => $self->{_from},
        _country => $self->{_country} || 'KR',
        _type    => $self->{_type}    || 'SMS',
        _delay   => $self->{_delay}   || 0,
        _subject => $self->{_subject},
        _epoch   => q{},
        @_,
    );

    my $text    = $params{text};
    my $to      = $params{to};
    my $from    = $params{_from};
    my $country = $params{_country};
    my $type    = $params{_type};
    my $delay   = $params{_delay};
    my $subject = $params{_subject};
    my $epoch   = $params{_epoch};

    my %ret = (
        success => 0,
        reason  => q{},
        detail  => +{},
    );

    $ret{reason} = 'text is needed',   return \%ret unless $text;
    $ret{reason} = 'to is needed',     return \%ret unless $to;
    $ret{reason} = '_type is invalid', return \%ret unless $type && $type =~ m/^(SMS|LMS)$/i;

    my $http = HTTP::Tiny->new(
        agent       => $self->{_agent},
        timeout     => $self->{_timeout},
        SSL_options => { SSL_hostname => q{} }, # coolsms does not support SNI
    ) or $ret{reason} = 'cannot generate HTTP::Tiny object', return \%ret;
    my $url = $self->{_url} . "/send";

    #
    # country & to: adjust country code and destination number
    #
    if ( $to =~ /^\+(\d{1})/ && $country_no{$1} ) {
        $country = $country_no{$1}{code};
        $to      =~ s/^\+\d{1}//;
    }
    elsif ( $to =~ /^\+(\d{2})/ && $country_no{$1} ) {
        $country = $country_no{$1}{code};
        $to      =~ s/^\+\d{2}//;
    }
    elsif ( $to =~ /^\+(\d{3})/ && $country_no{$1} ) {
        $country = $country_no{$1}{code};
        $to      =~ s/^\+\d{3}//;
    }

    #
    # datetime: reserve SMS
    #
    my $datetime;
    if ($epoch) {
        my $t = DateTime->from_epoch(
            time_zone => 'Asia/Seoul',
            epoch     => $epoch,
        );
        $datetime = $t->ymd(q{}) . $t->hms(q{});
    }

    #
    # subject
    #
    undef $subject if $type =~ m/SMS/i;

    my %form = (
        $self->_auth_params, # authentication
        to       => $to,
        from     => $from,
        text     => $text,
        type     => uc $type,
        #image
        #image_encoding
        #refname
        country  => $country,
        datetime => $datetime,
        subject  => $subject,
        charset  => 'utf8',
        #srk
        #mode
        #extension
        delay    => $delay,
    );
    $form{$_} or delete $form{$_} for keys %form;

    my $res = $http->post_form( $url, \%form );
    $ret{reason} = 'cannot get valid response for POST request';
    if ( $res && $res->{success} ) {
        $ret{detail} = decode_json( $res->{content} );
        $ret{reason}  = $ret{detail}{result_message};
        $ret{success} = 1 if $ret{detail}{result_code} eq '00';
    }
    else {
        $ret{detail} = $res;
        $ret{reason} = $res->{reason};
    }

    return \%ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::KR::CoolSMS - An SMS::Send driver for the coolsms.co.kr service

=head1 VERSION

version 1.003

=head1 SYNOPSIS

    use SMS::Send;

    # create the sender object
    my $sender = SMS::Send->new('KR::CoolSMS',
        _api_key    => 'XXXXXXXXXXXXXXXX',
        _api_secret => 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
        _from       => '01025116893',
    );

    # send a message
    my $sent = $sender->send_sms(
        text  => 'You message may use up to 88 chars and must be utf8',
        to    => '01012345678',
    );

    unless ( $sent->{success} ) {
        warn "failed to send sms: $sent->{reason}\n";

        # if you want to know detail more, check $sent->{detail}
        use Data::Dumper;
        warn Dumper $sent->{detail};
    }

    # Of course you can send LMS
    my $sender = SMS::Send->new('KR::CoolSMS',
        _api_key    => 'XXXXXXXXXXXXXXXX',
        _api_secret => 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
        _type       => 'lms',
        _from       => '01025116893',
    );

    # You can override _from or _type

    # send a message
    my $sent = $sender->send_sms(
        text     => 'You LMS message may use up to 2000 chars and must be utf8',
        to       => '01025116893',
        _from    => '02114',             # you can override $self->_from
        _type    => 'LMS',               # you can override $self->_type
        _subject => 'This is a subject', # subject is optional & up to 40 chars
    );

    # check the balance
    my $balance = $sender->balance;
    if ( $balance->{success} ) {
        printf "cash: \n", $banalce->{detail}{cash};
        printf "point: \n", $banalce->{detail}{point};
    }

=head1 DESCRIPTION

SMS::Send driver for sending SMS messages with the L<coolsms SMS service|http://api.coolsms.co.kr>.
You'll need L<IO::Socket::SSL> at least 1.84 version to use SSL support for HTTPS.

=head1 ATTRIBUTES

=head2 _url

DO NOT change this value except for testing purpose.
Default is C<"api.coolsms.co.kr/1/send">.

=head2 _agent

The agent value is sent as the "User-Agent" header in the HTTP requests.
Default is C<"SMS-Send-KR-CoolSMS/#.###">.

=head2 _timeout

HTTP request timeout seconds.
Default is C<3>.

=head2 _api_key

B<Required>.
coolsms API key for REST API.

=head2 _api_secret

B<Required>.
coolsms API secret for REST API.

=head2 _from

B<Required>.
Source number to send sms.

=head2 _type

Type of sms.
Currently C<SMS> and C<LMS> are supported.
Default is C<"SMS">.

=head2 _country

Country code to route the sms.
This is for destination number.
Default is C<"KR">.

=head2 _delay

Delay second between sending sms.
Default is C<0>.

=head1 METHODS

=head2 new

This constructor should not be called directly. See L<SMS::Send> for details.

=head2 send_sms

This constructor should not be called directly. See L<SMS::Send> for details.

Available parameters are:

=over 4

=item *

text

=item *

to

=item *

_from

=item *

_country

=item *

_type

=item *

_delay

=item *

_subject

=item *

_epoch

=back

=head2 balance

This method checks the balance.

=head1 SEE ALSO

=over 4

=item *

L<SMS::Send>

=item *

L<SMS::Send::Driver>

=item *

L<IO::Socket::SSL>

=item *

L<coolsms REST API|http://www.coolsms.co.kr/REST_API>

=back

=head1 AUTHOR

Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
