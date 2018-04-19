package Pcore::API::AntiCaptcha;

use Pcore -class, -const, -res;
use Pcore::Captcha;
use Pcore::Util::Data qw[to_b64 to_json from_json];

has api_key => ( is => 'ro', isa => Str, required => 1 );

has soft_id => ( is => 'ro', isa => Maybe [Str] );    # AppCenter Application ID used for comission earnings
has resolver_timeout => ( is => 'ro', isa => PositiveInt, default => 1 );    # timeout in seconds

has _pool => ( is => 'lazy', isa => HashRef, default => sub { {} }, init_arg => undef );
has _timer => ( is => 'ro', isa => InstanceOf ['EV::Timer'], init_arg => undef );

# QUEUE ID
# 1 - standart ImageToText, English language
# 2 - standart ImageToText, Russian language
# 3 - square recaptcha images
# 4 - audio captcha
# 5 - Recaptcha NoCaptcha tasks
# 6 - Recaptcha Proxyless task

const our $STATUS_REASON => {
    1  => [ 'ERROR_KEY_DOES_NOT_EXIST',        'Account authorization key not found in the system' ],
    2  => [ 'ERROR_NO_SLOT_AVAILABLE',         'No idle captcha workers are available at the moment, please try a bit later or try increasing your maximum bid here' ],
    3  => [ 'ERROR_ZERO_CAPTCHA_FILESIZE',     'The size of the captcha you are uploading is less than 100 bytes.' ],
    4  => [ 'ERROR_TOO_BIG_CAPTCHA_FILESIZE',  'The size of the captcha you are uploading is more than 500,000 bytes.' ],
    10 => [ 'ERROR_ZERO_BALANCE',              'Account has zeo or negative balance' ],
    11 => [ 'ERROR_IP_NOT_ALLOWED',            'Request with current account key is not allowed from your IP. Please refer to IP list section located here' ],
    12 => [ 'ERROR_CAPTCHA_UNSOLVABLE',        'Captcha could not be solved by 5 different workers' ],
    13 => [ 'ERROR_BAD_DUPLICATES',            '100% recognition feature did not work due to lack of amount of guess attempts' ],
    14 => [ 'ERROR_NO_SUCH_METHOD',            'Request to API made with method which does not exist' ],
    15 => [ 'ERROR_IMAGE_TYPE_NOT_SUPPORTED',  'Could not determine captcha file type by its exif header or image type is not supported. The only allowed formats are JPG, GIF, PNG' ],
    16 => [ 'ERROR_NO_SUCH_CAPCHA_ID',         'Captcha you are requesting does not exist in your current captchas list or has been expired. Captchas are removed from API after 5 minutes after upload.' ],
    20 => [ 'ERROR_EMPTY_COMMENT',             '"comment" property is required for this request' ],
    21 => [ 'ERROR_IP_BLOCKED',                'Your IP is blocked due to API inproper use. Check the reason at https://anti-captcha.com/panel/tools/ipsearch' ],
    22 => [ 'ERROR_TASK_ABSENT',               'Task property is empty or not set in createTask method. Please refer to API v2 documentation.' ],
    23 => [ 'ERROR_TASK_NOT_SUPPORTED',        'Task type is not supported or inproperly printed. Please check \"type\" parameter in task object.' ],
    24 => [ 'ERROR_INCORRECT_SESSION_DATA',    'Some of the required values for successive user emulation are missing.' ],
    25 => [ 'ERROR_PROXY_CONNECT_REFUSED',     'Could not connect to proxy related to the task, connection refused' ],
    26 => [ 'ERROR_PROXY_CONNECT_TIMEOUT',     'Could not connect to proxy related to the task, connection timeout' ],
    27 => [ 'ERROR_PROXY_READ_TIMEOUT',        'Connection to proxy for task has timed out' ],
    28 => [ 'ERROR_PROXY_BANNED',              'Proxy IP is banned by target service' ],
    29 => [ 'ERROR_PROXY_TRANSPARENT',         'Task denied at proxy checking state. Proxy must be non-transparent to hide our server IP.' ],
    30 => [ 'ERROR_RECAPTCHA_TIMEOUT',         'Recaptcha task timeout, probably due to slow proxy server or Google server' ],
    31 => [ 'ERROR_RECAPTCHA_INVALID_SITEKEY', 'Recaptcha server reported that site key is invalid' ],
    32 => [ 'ERROR_RECAPTCHA_INVALID_DOMAIN',  'Recaptcha server reported that domain for this site key is invalid' ],
    33 => [ 'ERROR_RECAPTCHA_OLD_BROWSER',     'Recaptcha server reported that browser user-agent is not compatible with their javascript' ],
    34 => [ 'ERROR_RECAPTCHA_STOKEN_EXPIRED',  'Recaptcha server reported that stoken parameter has expired. Make your application grab it faster.' ],
};

sub resolve ( $self, @ ) {
    my $cb = pop;

    my $captcha = Pcore::Captcha->new( { splice @_, 1 } );

    my $body = {
        clientKey    => $self->api_key,
        softId       => $self->soft_id,
        languagePool => $captcha->{is_russian} ? 'rn' : 'en',
        task         => {
            type      => 'ImageToTextTask',
            body      => to_b64( $captcha->{image}->$*, q[] ),
            phrase    => $captcha->{phrase} ? \1 : \0,
            case      => $captcha->{case_sensitive} ? \1 : \0,
            numeric   => $captcha->{numeric},
            math      => $captcha->{math} ? \1 : \0,
            minLength => $captcha->{min_length},
            maxLength => $captcha->{max_length},
        },
    };

    $self->_resolve( $captcha, $body, $cb );

    return;
}

sub recaptcha ( $self, @ ) {
    my $cb = $_[-1];

    my %args = (
        website_url => undef,
        website_key => undef,
        user_agent  => undef,
        cookies     => undef,
        @_[ 1 .. $#_ - 1 ]
    );

    my $captcha = Pcore::Captcha->new( { image => \q[] } );

    my $body = {
        clientKey => $self->api_key,
        task      => {
            type       => 'NoCaptchaTaskProxyless',
            websiteURL => $args{website_url},
            websiteKey => $args{website_key},
            userAgent  => $args{user_agent},
            $args{cookies} ? ( cookies => $args{cookies} ) : (),
        },
    };

    $self->_resolve( $captcha, $body, $cb );

    return;
}

sub recaptcha_proxy ( $self, @ ) {
    my $cb = $_[-1];

    my %args = (
        website_url   => undef,
        website_key   => undef,
        proxy_type    => 'socks5',
        proxy_address => undef,
        proxy_port    => undef,
        user_agent    => undef,
        cookies       => undef,
        @_[ 1 .. $#_ - 1 ]
    );

    my $captcha = Pcore::Captcha->new( { image => \q[] } );

    my $body = {
        clientKey => $self->api_key,
        task      => {
            type         => 'NoCaptchaTask',
            websiteURL   => $args{website_url},
            websiteKey   => $args{website_key},
            proxyType    => $args{proxy_type},
            proxyAddress => $args{proxy_address},
            proxyPort    => $args{proxy_port},
            userAgent    => $args{user_agent},
            $args{cookies} ? ( cookies => $args{cookies} ) : (),
        },
    };

    $self->_resolve( $captcha, $body, $cb );

    return;
}

sub get_balance ( $self, $cb ) {
    P->http->post(
        'https://api.anti-captcha.com/getBalance',
        body => to_json( {    #
            clientKey => $self->api_key,
        } ),
        on_finish => sub ($res) {
            my $result;

            # HTTP ERROR
            if ( !$res ) {
                $result = res [ $res->{status}, $res->{reason} ];
            }
            else {
                my $data = from_json $res->{body}->$*;

                # OK
                if ( !$data->{errorId} ) {
                    $result = res 200, $data->{balance};
                }

                # ERROR
                else {
                    $result = res [ $data->{errorId}, $STATUS_REASON->{ $data->{errorId} }->[1] ];
                }
            }

            $cb->($result);

            return;
        }
    );

    return;
}

sub get_queue_stats ( $self, $queue_id, $cb ) {
    P->http->post(
        'https://api.anti-captcha.com/getQueueStats',
        body => to_json( {
            clientKey => $self->api_key,
            queueId   => $queue_id,
        } ),
        on_finish => sub ($res) {
            my $result;

            # HTTP ERROR
            if ( !$res ) {
                $result = res [ $res->{status}, $res->{reason} ];
            }
            else {
                my $data = from_json $res->{body}->$*;

                # OK
                if ( !$data->{errorId} ) {
                    $result = res 200, $data;
                }

                # ERROR
                else {
                    $result = res [ $data->{errorId}, $STATUS_REASON->{ $data->{errorId} }->[1] ];
                }
            }

            $cb->($result);

            return;
        }
    );

    return;
}

sub _resolve ( $self, $captcha, $body, $cb ) {
    P->http->post(
        'https://api.anti-captcha.com/createTask',
        body      => to_json($body),
        on_finish => sub ($res) {

            # HTTP ERROR
            if ( !$res ) {
                $captcha->set_status( $res->{status}, $res->{reason} );

                $cb->($captcha);
            }
            else {
                my $data = from_json $res->{body}->$*;

                # ACCEPTED
                if ( !$data->{errorId} ) {
                    $captcha->{anticaptcha_id} = $data->{taskId};

                    $self->_pool->{ $data->{taskId} } = [ $captcha, $cb ];

                    $self->_run_resolver;
                }

                # ERROR_NO_SLOT_AVAILABLE
                elsif ( $data->{errorId} == 2 ) {

                    # repeat request
                    $self->_resolve( $captcha, $body, $cb );
                }

                # ERROR
                else {
                    $captcha->set_status( $data->{errorId}, $STATUS_REASON->{ $data->{errorId} }->[1] );

                    $cb->($captcha);
                }
            }

            return;
        }
    );

    return;
}

sub _run_resolver ($self) {
    return if $self->_timer;

    return if !$self->_pool->%*;

    $self->{_timer} = AE::timer $self->{resolver_timeout}, 0, sub {
        undef $self->{_timer};

        my $cv = AE::cv sub {
            $self->_run_resolver;

            return;
        };

        $cv->begin;

        for my $id ( keys $self->_pool->%* ) {
            $cv->begin;

            P->http->post(
                'https://api.anti-captcha.com/getTaskResult',
                body => to_json( {
                    clientKey => $self->api_key,
                    taskId    => $id,
                } ),
                on_finish => sub ($res) {
                    if ($res) {
                        my $data = from_json $res->{body}->$*;

                        # ERROR
                        if ( $data->{errorId} ) {
                            my $task = delete $self->_pool->{$id};

                            $task->[0]->set_status( $data->{errorId}, $STATUS_REASON->{ $data->{errorId} }->[1] );

                            $task->[1]->( $task->[0] );
                        }

                        # RESOLVED
                        elsif ( $data->{status} eq 'ready' ) {
                            my $task = delete $self->_pool->{$id};

                            $task->[0]->set_status(200);

                            $task->[0]->@{qw[result cost ip create_time end_time solve_count]} = ( $data->{solution}->{text} // $data->{solution}->{gRecaptchaResponse}, $data->{cost}, $data->{ip}, $data->{createTime}, $data->{endTime}, $data->{solveCount} );

                            $task->[1]->( $task->[0] );
                        }
                    }

                    $cv->end;

                    return;
                }
            );
        }

        $cv->end;

        return;
    };

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 81, 110              | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::AntiCaptcha

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
