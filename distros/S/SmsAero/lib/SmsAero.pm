package SmsAero;

use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use Email::Valid;
use Time::Piece;
use Log::Log4perl qw(:easy);
use MIME::Base64;

our $VERSION = '3.1.0';

use constant {
    GATE_URLS => [
        '@gate.smsaero.ru/v2/',
        '@gate.smsaero.org/v2/',
        '@gate.smsaero.net/v2/'
    ],
    SIGNATURE => 'Sms Aero'
};

{
    package SmsAeroException;
    use base qw(Exception::Class::Base);
}

{
    package SmsAeroConnectionException;
    use base qw(SmsAeroException);
}

{
    package SmsAeroNoMoneyException;
    use base qw(SmsAeroException);
}

my $logger = Log::Log4perl->get_logger();

sub new {
    my ($class, %args) = @_;

    my $self = {
        _email => $args{email},
        _api_key => $args{api_key},
        _signature => $args{signature} || SIGNATURE,
        _timeout => $args{timeout} || 15,
        _allow_phone_validation => defined $args{allow_phone_validation} ? $args{allow_phone_validation} : 1,
        _gate => $args{url_gate},
        _test_mode => $args{test_mode} || 0,
        _ua => LWP::UserAgent->new(
            timeout => $args{timeout} || 15,
            agent => 'SAPerlClient/3.0.0'
        )
    };

    bless $self, $class;

    $self->_init_validate();
    $self->_check_and_format_user_gate();

    return $self;
}

sub _init_validate {
    my ($self) = @_;

    unless (Email::Valid->address($self->{_email})) {
        die "Invalid email address";
    }

    unless ($self->{_api_key} && length($self->{_api_key}) >= 16 && length($self->{_api_key}) <= 32) {
        die "API key length must be between 16 and 32 characters";
    }

    unless ($self->{_signature} && length($self->{_signature}) >= 2) {
        die "Signature length must be at least 2 characters";
    }

    unless ($self->{_timeout} > 2) {
        die "Timeout must be greater than 2";
    }
}

sub _check_and_format_user_gate {
    my ($self) = @_;

    return unless $self->{_gate};

    my $gate = $self->{_gate};

    $gate = '@' . $gate unless $gate =~ /^@/;

    $gate .= '/v2/' unless $gate =~ /\/v2\/$/;

    $self->{_gate} = $gate;
}

sub _request {
    my ($self, $selector, $data, $page) = @_;

    foreach my $gate (@{$self->_get_gate_urls()}) {
        my $url = $self->_build_url('https', $selector, $gate, $page);

        $logger->debug("Sending request to $url with data ", encode_json($data));

        my $req = HTTP::Request->new(
            'POST',
            $url,
            [
                'Content-Type' => 'application/json',
                'Authorization' => 'Basic ' . encode_base64($self->{_email} . ':' . $self->{_api_key})
            ],
            encode_json($data || {})
        );

        my $res = $self->{_ua}->request($req);

        if ($res->is_success) {
            my $content = decode_json($res->content);
            $logger->debug("Received response: ", encode_json($content));

            return $self->_check_response($content);
        }

        $logger->debug("Request failed: " . $res->status_line);
    }

    die SmsAeroConnectionException->new("Failed to connect to any gateway");
}

sub _get_gate_urls {
    my ($self) = @_;
    return $self->{_gate} ? [$self->{_gate}] : GATE_URLS;
}

sub _build_url {
    my ($self, $proto, $selector, $gate, $page) = @_;

    $gate =~ s/^@//;

    my $url = sprintf("%s://%s%s",
        $proto,
        $gate,
        $selector
    );

    $url .= "?page=$page" if $page;
    return $url;
}

sub _check_response {
    my ($self, $content) = @_;

    if ($content->{result} && $content->{result} eq 'no credits') {
        die SmsAeroNoMoneyException->new($content->{result});
    }
    if ($content->{result} && $content->{result} eq 'reject') {
        die SmsAeroException->new($content->{reason});
    }
    unless ($content->{success}) {
        die SmsAeroException->new($content->{message} || "Unknown error");
    }

    return $content->{data};
}

sub _validate_phone_number {
    my ($self, $number) = @_;

    return unless $self->{_allow_phone_validation};

    my @numbers = ref $number eq 'ARRAY' ? @$number : ($number);
    foreach my $num (@numbers) {
        unless ($num =~ /^\d{7,15}$/) {
            die "Invalid phone number length";
        }

        unless ($num =~ /^[1-9]\d{6,14}$/) {
            die "Invalid phone number format";
        }
    }
}

sub enable_test_mode {
    my ($self) = @_;
    $self->{_test_mode} = 1;
}

sub disable_test_mode {
    my ($self) = @_;
    $self->{_test_mode} = 0;
}

sub is_test_mode_active {
    my ($self) = @_;
    return $self->{_test_mode};
}

sub is_authorized {
    my ($self) = @_;
    return $self->_request('auth') ? 0 : 1;
}

sub send_sms {
    my ($self, %args) = @_;

    $self->_validate_phone_number($args{number});
    die "Text must be between 2 and 640 characters"
        unless length($args{text}) >= 2 && length($args{text}) <= 640;

    my $data = {
        text => $args{text},
        sign => $args{sign} || $self->{_signature}
    };

    if (ref $args{number} eq 'ARRAY') {
        $data->{numbers} = $args{number};
    } else {
        $data->{number} = $args{number};
    }

    if ($args{date_to_send}) {
        if (ref $args{date_to_send} eq 'Time::Piece') {
            $data->{dateSend} = $args{date_to_send}->epoch;
        } else {
            die "date_to_send must be a Time::Piece object";
        }
    }

    $data->{callbackUrl} = $args{callback_url} if $args{callback_url};

    return $self->_request(
        $self->{_test_mode} ? 'sms/testsend' : 'sms/send',
        $data
    );
}

sub sms_status {
    my ($self, $sms_id) = @_;

    return $self->_request(
        $self->{_test_mode} ? 'sms/teststatus' : 'sms/status',
        { id => int($sms_id) }
    );
}

sub send_telegram {
    my ($self, %args) = @_;

    $self->_validate_phone_number($args{number});
    die "Code must be a 4 to 8 digit integer"
        unless defined $args{code} && $args{code} =~ /^\d{4,8}$/;

    my $data = {
        code => int($args{code}),
    };

    if (ref $args{number} eq 'ARRAY') {
        $data->{numbers} = $args{number};
    } else {
        $data->{number} = $args{number};
    }

    $data->{sign} = $args{sign} if defined $args{sign};
    $data->{text} = $args{text} if defined $args{text};

    return $self->_request(
        'telegram/send',
        $data
    );
}

sub telegram_status {
    my ($self, $telegram_id) = @_;

    return $self->_request(
        'telegram/status',
        { id => int($telegram_id) }
    );
}

sub sms_list {
    my ($self, %args) = @_;

    my $data = {};
    if ($args{number}) {
        if (ref $args{number} eq 'ARRAY') {
            $data->{numbers} = $args{number};
        } else {
            $data->{number} = $args{number};
        }
    }
    $data->{text} = $args{text} if $args{text};

    return $self->_request(
        $self->{_test_mode} ? 'sms/testlist' : 'sms/list',
        $data,
        $args{page}
    );
}

sub balance {
    my ($self) = @_;
    return $self->_request('balance');
}

sub balance_add {
    my ($self, $amount, $card_id) = @_;
    return $self->_request('balance/add', {
        sum => $amount + 0,
        cardId => int($card_id)
    });
}

sub cards {
    my ($self) = @_;
    return $self->_request('cards');
}

sub tariffs {
    my ($self) = @_;
    return $self->_request('tariffs');
}

sub sign_list {
    my ($self, $page) = @_;
    return $self->_request('sign/list', undef, $page);
}

sub group_add {
    my ($self, $name) = @_;
    return $self->_request('group/add', { name => $name });
}

sub group_delete {
    my ($self, $group_id) = @_;
    return $self->_request('group/delete', { id => int($group_id) }) ? 0 : 1;
}

sub group_delete_all {
    my ($self) = @_;
    return $self->_request('group/delete-all') ? 0 : 1;
}

sub group_list {
    my ($self, $page) = @_;
    return $self->_request('group/list', undef, $page);
}

sub contact_add {
    my ($self, %args) = @_;

    my $data = {
        number => $args{number},
        groupId => $args{group_id} && int($args{group_id}),
        birthday => $args{birthday},
        sex => $args{sex},
        lname => $args{last_name},
        fname => $args{first_name},
        sname => $args{surname},
        param1 => $args{param1},
        param2 => $args{param2},
        param3 => $args{param3}
    };

    return $self->_request('contact/add', $data);
}

sub contact_delete {
    my ($self, $contact_id) = @_;
    return $self->_request('contact/delete', { id => int($contact_id) }) ? 0 : 1;
}

sub contact_delete_all {
    my ($self) = @_;
    return $self->_request('contact/delete-all') ? 0 : 1;
}

sub contact_list {
    my ($self, %args) = @_;

    my $data = {
        number => $args{number},
        groupId => $args{group_id} && int($args{group_id}),
        birthday => $args{birthday},
        sex => $args{sex},
        operator => $args{operator},
        lname => $args{last_name},
        fname => $args{first_name},
        sname => $args{surname}
    };

    return $self->_request('contact/list', $data, $args{page});
}

sub blacklist_add {
    my ($self, $number) = @_;

    my $data = ref $number eq 'ARRAY' ?
        { numbers => $number } :
        { number => $number };

    return $self->_request('blacklist/add', $data);
}

sub blacklist_list {
    my ($self, %args) = @_;

    my $data;
    if ($args{number}) {
        $data = ref $args{number} eq 'ARRAY' ?
            { numbers => $args{number} } :
            { number => $args{number} };
    }

    return $self->_request('blacklist/list', $data, $args{page});
}

sub blacklist_delete {
    my ($self, $blacklist_id) = @_;
    return $self->_request('blacklist/delete', { id => int($blacklist_id) }) ? 0 : 1;
}

sub hlr_check {
    my ($self, $number) = @_;

    my $data = ref $number eq 'ARRAY' ?
        { numbers => $number } :
        { number => $number };

    return $self->_request('hlr/check', $data);
}

sub hlr_status {
    my ($self, $hlr_id) = @_;
    return $self->_request('hlr/status', { id => int($hlr_id) });
}

sub number_operator {
    my ($self, $number) = @_;

    my $data = ref $number eq 'ARRAY' ?
        { numbers => $number } :
        { number => $number };

    return $self->_request('number/operator', $data);
}

sub viber_send {
    my ($self, %args) = @_;

    my $data = {
        sign => $args{sign},
        channel => $args{channel},
        text => $args{text},
        imageSource => $args{image_source},
        textButton => $args{text_button},
        linkButton => $args{link_button},
        dateSend => $args{date_send},
        signSms => $args{sign_sms},
        channelSms => $args{channel_sms},
        textSms => $args{text_sms},
        priceSms => $args{price_sms}
    };

    if ($args{number}) {
        if (ref $args{number} eq 'ARRAY') {
            $data->{numbers} = $args{number};
        } else {
            $data->{number} = $args{number};
        }
    }
    $data->{groupId} = int($args{group_id}) if $args{group_id};

    return $self->_request('viber/send', $data);
}

sub viber_sign_list {
    my ($self) = @_;
    return $self->_request('viber/sign/list');
}

sub viber_list {
    my ($self, $page) = @_;
    return $self->_request('viber/list', undef, $page);
}

sub viber_statistics {
    my ($self, $sending_id, $page) = @_;
    return $self->_request('viber/statistic',
        { sendingId => int($sending_id) },
        $page
    );
}

1;
