package Pcore::API::anticaptcha;

use Pcore -class, -const, -res;
use Pcore::Util::Data qw[to_b64 to_json from_json];
use Pcore::Util::Scalar qw[is_plain_scalarref];
use Pcore::API::anticaptcha::Captcha;

has api_key     => ( required => 1 );
has api_soft_id => ();                  # AppCenter Application ID used for comission earnings

const our $DEFAULT_TIMEOUT                    => 5;
const our $ANTICAPTCHA_QUEUE_IMAGE_EN         => 1;     # standart ImageToText, English language
const our $ANTICAPTCHA_QUEUE_IMAGE_RU         => 2;     # standart ImageToText, Russian language
const our $ANTICAPTCHA_QUEUE_NOCAPTCHA_PROXY  => 5;     # Recaptcha NoCaptcha tasks
const our $ANTICAPTCHA_QUEUE_NOCAPTCHA        => 6;     # Recaptcha Proxyless task
const our $ANTICAPTCHA_QUEUE_FUNCAPTCHA_PROXY => 7;     # Funcaptcha
const our $ANTICAPTCHA_QUEUE_FUNCAPTCHA       => 10;    # Funcaptcha Proxyless

# https://anticaptcha.atlassian.net/wiki/spaces/API/pages/5079075/Errors
const our $STATUS_REASON => {
    1  => [ 'ERROR_KEY_DOES_NOT_EXIST',                   'Account authorization key not found in the system' ],
    2  => [ 'ERROR_NO_SLOT_AVAILABLE',                    'No idle captcha workers are available at the moment, please try a bit later or try increasing your maximum bid here' ],
    3  => [ 'ERROR_ZERO_CAPTCHA_FILESIZE',                'The size of the captcha you are uploading is less than 100 bytes.' ],
    4  => [ 'ERROR_TOO_BIG_CAPTCHA_FILESIZE',             'The size of the captcha you are uploading is more than 500,000 bytes.' ],
    10 => [ 'ERROR_ZERO_BALANCE',                         'Account has zeo or negative balance' ],
    11 => [ 'ERROR_IP_NOT_ALLOWED',                       'Request with current account key is not allowed from your IP. Please refer to IP list section located here' ],
    12 => [ 'ERROR_CAPTCHA_UNSOLVABLE',                   'Captcha could not be solved by 5 different workers' ],
    13 => [ 'ERROR_BAD_DUPLICATES',                       '100% recognition feature did not work due to lack of amount of guess attempts' ],
    14 => [ 'ERROR_NO_SUCH_METHOD',                       'Request to API made with method which does not exist' ],
    15 => [ 'ERROR_IMAGE_TYPE_NOT_SUPPORTED',             'Could not determine captcha file type by its exif header or image type is not supported. The only allowed formats are JPG, GIF, PNG' ],
    16 => [ 'ERROR_NO_SUCH_CAPCHA_ID',                    'Captcha you are requesting does not exist in your current captchas list or has been expired. Captchas are removed from API after 5 minutes after upload.' ],
    20 => [ 'ERROR_EMPTY_COMMENT',                        '"comment" property is required for this request' ],
    21 => [ 'ERROR_IP_BLOCKED',                           'Your IP is blocked due to API inproper use. Check the reason at https://anti-captcha.com/panel/tools/ipsearch' ],
    22 => [ 'ERROR_TASK_ABSENT',                          'Task property is empty or not set in createTask method. Please refer to API v2 documentation.' ],
    23 => [ 'ERROR_TASK_NOT_SUPPORTED',                   'Task type is not supported or inproperly printed. Please check \"type\" parameter in task object.' ],
    24 => [ 'ERROR_INCORRECT_SESSION_DATA',               'Some of the required values for successive user emulation are missing.' ],
    25 => [ 'ERROR_PROXY_CONNECT_REFUSED',                'Could not connect to proxy related to the task, connection refused' ],
    26 => [ 'ERROR_PROXY_CONNECT_TIMEOUT',                'Could not connect to proxy related to the task, connection timeout' ],
    27 => [ 'ERROR_PROXY_READ_TIMEOUT',                   'Connection to proxy for task has timed out' ],
    28 => [ 'ERROR_PROXY_BANNED',                         'Proxy IP is banned by target service' ],
    29 => [ 'ERROR_PROXY_TRANSPARENT',                    'Task denied at proxy checking state. Proxy must be non-transparent to hide our server IP.' ],
    30 => [ 'ERROR_RECAPTCHA_TIMEOUT',                    'Recaptcha task timeout, probably due to slow proxy server or Google server' ],
    31 => [ 'ERROR_RECAPTCHA_INVALID_SITEKEY',            'Recaptcha server reported that site key is invalid' ],
    32 => [ 'ERROR_RECAPTCHA_INVALID_DOMAIN',             'Recaptcha server reported that domain for this site key is invalid' ],
    33 => [ 'ERROR_RECAPTCHA_OLD_BROWSER',                'Recaptcha server reported that browser user-agent is not compatible with their javascript' ],
    34 => [ 'ERROR_TOKEN_EXPIRED',                        'Captcha provider server reported that additional variable token has been expired. Please try again with new token.' ],
    35 => [ 'ERROR_PROXY_HAS_NO_IMAGE_SUPPORT',           'Proxy does not support transfer of image data from Google servers' ],
    36 => [ 'ERROR_PROXY_INCOMPATIBLE_HTTP_VERSION',      'Proxy does not support long GET requests with length about 2000 bytes and does not support SSL connections' ],
    37 => [ 'ERROR_FACTORY_SERVER_API_CONNECTION_FAILED', 'Could not connect to Factory Server API within 5 seconds' ],
    38 => [ 'ERROR_FACTORY_SERVER_BAD_JSON',              'Incorrect Factory Server JSON response, something is broken' ],
    39 => [ 'ERROR_FACTORY_SERVER_ERRORID_MISSING',       'Factory Server API did not send any errorId' ],
    40 => [ 'ERROR_FACTORY_SERVER_ERRORID_NOT_ZERO',      'Factory Server API reported errorId != 0, check this error' ],
    41 => [ 'ERROR_FACTORY_MISSING_PROPERTY',             'Some of the required property values are missing in Factory form specifications. Customer must send all required values.' ],
    42 => [ 'ERROR_FACTORY_PROPERTY_INCORRECT_FORMAT',    'Expected other type of property value in Factory form structure. Customer must send specified value type.' ],
    43 => [ 'ERROR_FACTORY_ACCESS_DENIED',                'Factory control belong to another account, check your account key.' ],
    44 => [ 'ERROR_FACTORY_SERVER_OPERATION_FAILED',      'Factory Server general error code' ],
    45 => [ 'ERROR_FACTORY_PLATFORM_OPERATION_FAILED',    'Factory Platform general error code.' ],
    46 => [ 'ERROR_FACTORY_PROTOCOL_BROKEN',              'Factory task lifetime protocol broken during task workflow.' ],
    47 => [ 'ERROR_FACTORY_TASK_NOT_FOUND',               'Task not found or not available for this operation' ],
    48 => [ 'ERROR_FACTORY_IS_SANDBOXED',                 'Factory is sandboxed, creating tasks is possible only by Factory owner. Switch it to production mode to make it available for other customers.' ],
    49 => [ 'ERROR_PROXY_NOT_AUTHORISED',                 'Proxy login and password are incorrect' ],
    50 => [ 'ERROR_FUNCAPTCHA_NOT_ALLOWED',               'Customer did not enable Funcaptcha Proxyless tasks in Customers Area - API Settings. All customers must read terms, pass mini test and sign/accept the form before being able to use this feature.' ],
    51 => [ 'ERROR_INVISIBLE_RECAPTCHA',                  q[Recaptcha was attempted to be solved as usual one, instead of invisible mode. Basically you don't need to do anything when this error occurs, just continue sending tasks with this domain. Our system will self-learn to solve recaptchas from this sitekey in invisible mode.] ],
    52 => [ 'ERROR_FAILED_LOADING_WIDGET',                'Could not load captcha provider widget in worker browser. Please try sending new task.' ],
};

sub new_image_captcha ( $self, $image, %args ) {
    return Pcore::API::anticaptcha::Captcha->new( {
        api    => $self,
        params => {
            %args,
            type  => $args{is_russian}         ? $ANTICAPTCHA_QUEUE_IMAGE_RU : $ANTICAPTCHA_QUEUE_IMAGE_EN,
            image => is_plain_scalarref $image ? $image                      : \$image,
        }
    } );
}

sub new_nocaptcha ( $self, %args ) {
    return Pcore::API::anticaptcha::Captcha->new( {
        api    => $self,
        params => { %args, type => $ANTICAPTCHA_QUEUE_NOCAPTCHA, },
    } );
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

# PRIVATE METHODS
sub solve ( $self, $captcha ) {
    my $task;

    if ( $captcha->{params}->{type} == $ANTICAPTCHA_QUEUE_IMAGE_EN || $captcha->{params}->{type} == $ANTICAPTCHA_QUEUE_IMAGE_RU ) {
        $task = {
            languagePool => $captcha->{params}->{type} == $ANTICAPTCHA_QUEUE_IMAGE_EN ? 'en' : 'ru',
            task         => {
                type      => 'ImageToTextTask',
                body      => to_b64( $captcha->{params}->{image}->$*, $EMPTY ),
                phrase    => $captcha->{params}->{phrase} ? \1 : \0,
                case      => $captcha->{params}->{case_sensitive} ? \1 : \0,
                numeric   => $captcha->{params}->{numeric},
                math      => $captcha->{params}->{math} ? \1 : \0,
                minLength => $captcha->{params}->{min_length},
                maxLength => $captcha->{params}->{max_length},
            },
        };
    }
    elsif ( $captcha->{params}->{type} == $ANTICAPTCHA_QUEUE_NOCAPTCHA ) {
        $task = {
            task => {
                type       => 'NoCaptchaTaskProxyless',
                websiteURL => $captcha->{params}->{website_url},
                websiteKey => $captcha->{params}->{website_key},
            },
        };
    }
    else {
        die 'Invalid captcha type';
    }

    $task->{clientKey} = $self->{api_key};
    $task->{softId}    = $self->{api_soft_id};

    $task = to_json $task;

  REPEAT_CREATE_TASK:
    my $res = P->http->post( 'https://api.anti-captcha.com/createTask', data => $task );

    # HTTP error
    return res $res if !$res;

    my $data = from_json $res->{data}->$*;

    # error
    if ( $data->{errorId} ) {

        # no slot available
        if ( $data->{errorId} == 2 ) {
            goto REPEAT_CREATE_TASK;
        }

        # error
        else {
            return res [ 500, $STATUS_REASON->{ $data->{errorId} }->[1] ];
        }
    }

    # task created
    $captcha->{params}->{id} = $data->{taskId};

    $task = to_json {
        clientKey => $self->{api_key},
        taskId    => $captcha->{params}->{id},
    };

  REPEAT_GET_RESULT:
    Coro::sleep $DEFAULT_TIMEOUT;

    $res = P->http->post( 'https://api.anti-captcha.com/getTaskResult', data => $task );

    # HTTP error
    return res $res if !$res;

    $data = from_json $res->{data}->$*;

    # error
    if ( $data->{errorId} ) {
        return res [ 500, $STATUS_REASON->{ $data->{errorId} }->[1] ];
    }

    # resolved
    elsif ( $data->{status} eq 'ready' ) {
        return res 200, $data->{solution}->{text} // $data->{solution}->{gRecaptchaResponse},
          solution => {
            cost        => $data->{cost},
            ip          => $data->{ip},
            create_time => $data->{createTime},
            end_time    => $data->{endTime},
            solve_count => $data->{solveCount},
          };
    }

    # not resolved
    goto REPEAT_GET_RESULT;
}

sub report ( $self, $captcha ) {
    my $res = P->http->post(
        'https://api.anti-captcha.com/reportIncorrectImageCaptcha',
        data => to_json {    #
            clientKey => $self->{api_key},
            taskId    => $captcha->{params}->{id},
        }
    );

    # HTTP error
    return res $res if !$res;

    my $data = from_json $res->{data}->$*;

    # error
    return res [ 500, $STATUS_REASON->{ $data->{errorId} }->[1] ] if $data->{errorId};

    # reported
    return res 200, $data->{balance};
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::anticaptcha

=head1 SYNOPSIS

    my $api = Pcore::API::anticaptcha1->new( api_key => '...' );

    my $captcha = $api->new_image_captcha($image);

    $captcha->solve;

    # solved
    if ($captcha) {

        # verify captcha

        if (!$is_ok) {
            $captcha->report;
        }
    }

    # not solved
    else {

        # get new captcha
    }

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
