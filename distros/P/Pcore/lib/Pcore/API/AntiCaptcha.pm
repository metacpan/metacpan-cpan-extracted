package Pcore::API::AntiCaptcha;

use Pcore -class, -const, -res;
use Pcore::API::AntiCaptcha::Result;
use Pcore::Util::Data qw[to_b64 to_json from_json];
use Pcore::Util::Scalar qw[weaken is_plain_scalarref];

with qw[Pcore::API::AntiCaptcha::Role];

has api_key     => ( required => 1 );
has api_soft_id => ();                  # AppCenter Application ID used for comission earnings

has _signal  => sub { Coro::Signal->new };
has _threads => ();

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

const our $ANTICAPTCHA_QUEUE_IMAGE_EN         => 1;     # standart ImageToText, English language
const our $ANTICAPTCHA_QUEUE_IMAGE_RU         => 2;     # standart ImageToText, Russian language
const our $ANTICAPTCHA_QUEUE_NOCAPTCHA_PROXY  => 5;     # Recaptcha NoCaptcha tasks
const our $ANTICAPTCHA_QUEUE_NOCAPTCHA        => 6;     # Recaptcha Proxyless task
const our $ANTICAPTCHA_QUEUE_FUNCAPTCHA_PROXY => 7;     # Funcaptcha
const our $ANTICAPTCHA_QUEUE_FUNCAPTCHA       => 10;    # Funcaptcha Proxyless

sub DESTROY ($self) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {

        # finish threads
        $self->{_signal}->broadcast;

        # finish tasks
        for my $cb ( values delete( $self->{_queue} )->%* ) {
            $cb->( res 500 );
        }
    }

    return;
}

sub new_image_captcha ( $self, $image, %args ) {
    return Pcore::API::AntiCaptcha::Result->new( {
        %args,
        type  => $args{is_russian}         ? $ANTICAPTCHA_QUEUE_IMAGE_RU : $ANTICAPTCHA_QUEUE_IMAGE_EN,
        image => is_plain_scalarref $image ? $image                      : \$image,
        api   => $self,
    } );
}

sub new_nocaptcha ( $self, %args ) {
    return Pcore::API::AntiCaptcha::Result->new( {
        %args,
        type => $ANTICAPTCHA_QUEUE_NOCAPTCHA,
        api  => $self,
    } );
}

sub resolve ( $self, $captcha, $cb = undef ) {
    weaken $captcha if defined wantarray;

    my $cv = defined wantarray ? P->cv : undef;

    my $on_finish = sub ( $status, $result = undef, $data = undef ) {
        return if !defined $captcha;

        $captcha->{is_finished} = 1;

        $captcha->set_status($status);

        if ( defined $result ) {
            $captcha->{is_resolved} = 1;

            $captcha->{result} = $result;
        }

        $captcha->{data} = $data;

        $captcha = $cb->($captcha) if defined $cb;

        $cv->($captcha) if defined $cv;

        return $captcha;
    };

    my $task;

    if ( $captcha->{type} == $ANTICAPTCHA_QUEUE_IMAGE_EN || $captcha->{type} == $ANTICAPTCHA_QUEUE_IMAGE_RU ) {
        $task = {
            languagePool => $captcha->{type} == $ANTICAPTCHA_QUEUE_IMAGE_EN ? 'en' : 'ru',
            task         => {
                type      => 'ImageToTextTask',
                body      => to_b64( $captcha->{image}->$*, $EMPTY ),
                phrase    => $captcha->{phrase} ? \1 : \0,
                case      => $captcha->{case_sensitive} ? \1 : \0,
                numeric   => $captcha->{numeric},
                math      => $captcha->{math} ? \1 : \0,
                minLength => $captcha->{min_length},
                maxLength => $captcha->{max_length},
            },
        };
    }
    elsif ( $captcha->{type} == $ANTICAPTCHA_QUEUE_NOCAPTCHA ) {
        $task = {
            task => {
                type       => 'NoCaptchaTaskProxyless',
                websiteURL => $captcha->{website_url},
                websiteKey => $captcha->{website_key},
            },
        };
    }
    else {
        return $on_finish->( [ 400, 'Invalid captcha type' ] );
    }

    $task->{clientKey} = $self->{api_key};
    $task->{softId}    = $self->{api_soft_id};

    $task = to_json $task;

  REPEAT:
    my $res = P->http->post( 'https://api.anti-captcha.com/createTask', data => $task );

    # HTTP error
    return $on_finish->( [ $res->{status}, $res->{reason} ] ) if !$res;

    my $data = eval { from_json $res->{data}->$* };

    # error
    if ( $data->{errorId} ) {

        # no slot available
        if ( $data->{errorId} == 2 ) {
            goto REPEAT;
        }

        # error
        else {
            return $on_finish->( [ 500, $STATUS_REASON->{ $data->{errorId} }->[1] ] );
        }
    }

    # accepted
    $captcha->{id} = $data->{taskId};

    $self->{_queue}->{ $captcha->{id} } = $on_finish;

    if ( !$self->{_threads} ) {
        $self->_run_resolver_thread;
    }
    elsif ( $self->{_signal}->awaited ) {
        $self->{_signal}->send;
    }

    return defined $cv ? $cv->recv : ();
}

sub report_invalid ( $self, $captcha ) {
    my $res = P->http->post(
        'https://api.anti-captcha.com/reportIncorrectImageCaptcha',
        data => to_json {    #
            clientKey => $self->{api_key},
            taskId    => $captcha->{id},
        }
    );

    if ($res) {
        my $data = from_json $res->{data}->$*;

        # OK
        if ( !$data->{errorId} ) {
            $captcha->{is_reported} = 1;

            $res = res 200, $data->{balance};
        }

        # ERROR
        else {
            $res = res [ 500, $STATUS_REASON->{ $data->{errorId} }->[1] ];
        }
    }

    return $res;
}

sub get_balance ( $self ) {
    my $res = P->http->post(
        'https://api.anti-captcha.com/getBalance',
        data => to_json {    #
            clientKey => $self->{api_key},
        }
    );

    if ($res) {
        my $data = from_json $res->{data}->$*;

        # OK
        if ( !$data->{errorId} ) {
            $res = res 200, $data->{balance};
        }

        # ERROR
        else {
            $res = res [ 500, $STATUS_REASON->{ $data->{errorId} }->[1] ];
        }
    }

    return $res;
}

sub get_queue_stats ( $self, $queue_id ) {
    my $res = P->http->post(
        'https://api.anti-captcha.com/getQueueStats',
        data => to_json {
            clientKey => $self->{api_key},
            queueId   => $queue_id,
        }
    );

    if ($res) {
        my $data = from_json $res->{data}->$*;

        # OK
        if ( !$data->{errorId} ) {
            $res = res 200, $data;
        }

        # ERROR
        else {
            $res = res [ 500, $STATUS_REASON->{ $data->{errorId} }->[1] ];
        }
    }

    return $res;
}

sub _run_resolver_thread ($self) {
    weaken $self;

    $self->{_threads} = 1;

    Coro::async_pool {
        while () {
            return if !defined $self;

            Coro::AnyEvent::sleep 3;

            if ( $self->{_queue}->%* ) {
                my $cv = P->cv->begin;

                for my $id ( keys $self->{_queue}->%* ) {
                    $cv->begin;

                    P->http->post(
                        'https://api.anti-captcha.com/getTaskResult',
                        data => to_json( {
                            clientKey => $self->{api_key},
                            taskId    => $id,
                        } ),
                        sub ($res) {
                            if ($res) {
                                my $data = from_json $res->{data}->$*;

                                # task finished
                                if ( $data->{errorId} || $data->{status} eq 'ready' ) {

                                    # captcha is present in the queue
                                    if ( my $cb = delete $self->{_queue}->{$id} ) {

                                        # error
                                        if ( $data->{errorId} ) {
                                            $cb->( [ 500, $STATUS_REASON->{ $data->{errorId} }->[1] ] );
                                        }

                                        # resolved
                                        elsif ( $data->{status} eq 'ready' ) {
                                            $cb->(
                                                200,
                                                $data->{solution}->{text} // $data->{solution}->{gRecaptchaResponse},
                                                {   cost        => $data->{cost},
                                                    ip          => $data->{ip},
                                                    create_time => $data->{createTime},
                                                    end_time    => $data->{endTime},
                                                    solve_count => $data->{solveCount},
                                                }
                                            );
                                        }
                                    }
                                }
                            }

                            $cv->end;

                            return;
                        }
                    );
                }

                $cv->end->recv;

                next if defined $self && $self->{_queue}->%*;
            }

            $self->{_signal}->wait;
        }

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
## |    3 | 84                   | Subroutines::ProhibitExcessComplexity - Subroutine "resolve" with high complexity score (22)                   |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 293, 296             | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::AntiCaptcha

=head1 SYNOPSIS

    use Pcore::API::AntiCaptcha;

    my $image = P->file->read_bin('captcha.png');

    my $api = Pcore::API::AntiCaptcha->new( api_key => '...' );

    my $captcha = $api->new_image_captcha($image);

    say dump $captcha->resolve;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
