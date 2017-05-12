package Pcore::WebDriver v0.7.0;

use Pcore -dist, -const, -role, -result,
  -export => {
    WD_LOCATOR => [qw[$WD_CLASS_NAME $WD_CSS_SELECTOR $WD_ID $WD_NAME $WD_LINK_TEXT $WD_LINK_TEXT_PART $WD_TAG_NAME $WD_XPATH]],
    WD_KEY     => [qw[$WD_KEY]],
    CONST      => [qw[:WD_LOCATOR :WD_KEY]],
  };
use Pcore::Util::Data qw[to_json from_json from_b64];
require Pcore::WebDriver::WebElement;

with qw[Pcore::Util::Result::Status];

requires qw[get_cmd get_desired_capabilities];

has host => ( is => 'ro', isa => Str,         required => 1 );
has port => ( is => 'ro', isa => PositiveInt, required => 1 );

has desired_capabilities => ( is => 'ro', isa => Maybe [HashRef] );

has disable_javascript   => ( is => 'ro', isa => Bool, default => 0 );
has disable_images       => ( is => 'ro', isa => Bool, default => 0 );
has enable_flash         => ( is => 'ro', isa => Bool, default => 0 );
has enable_notifications => ( is => 'ro', isa => Bool, default => 0 );
has useragent            => ( is => 'ro', isa => Str );

has proxy_type => ( is => 'ro', isa => Enum [qw[direct manual]], default => 'direct' );
has http_proxy           => ( is => 'ro', isa => Str );    # '192.168.175.1:9070'
has ssl_proxy            => ( is => 'ro', isa => Str );    # '192.168.175.1:9070'
has socks_proxy          => ( is => 'ro', isa => Str );    # '192.168.175.1:9050'
has socks_proxy_username => ( is => 'ro', isa => Str );
has socks_proxy_password => ( is => 'ro', isa => Str );

has session_id => ( is => 'ro', isa => Str, init_arg => undef );
has _proc => ( is => 'ro', isa => InstanceOf ['Pcore::Util:PM::Proc'], init_arg => undef );    # proc handle

const our $WD_STATUS_REASON => {
    0  => [ 'Success',                    'The command executed successfully.' ],
    6  => [ 'NoSuchDriver',               'A session is either terminated or not started' ],
    7  => [ 'NoSuchElement',              'An element could not be located on the page using the given search parameters.' ],
    8  => [ 'NoSuchFrame',                'A request to switch to a frame could not be satisfied because the frame could not be found.' ],
    9  => [ 'UnknownCommand',             'The requested resource could not be found, or a request was received using an HTTP method that is not supported by the mapped resource.' ],
    10 => [ 'StaleElementReference',      'An element command failed because the referenced element is no longer attached to the DOM.' ],
    11 => [ 'ElementNotVisible',          'An element command could not be completed because the element is not visible on the page.' ],
    12 => [ 'InvalidElementState',        'An element command could not be completed because the element is in an invalid state (e.g. attempting to click a disabled element).' ],
    13 => [ 'UnknownError',               'An unknown server-side error occurred while processing the command.' ],
    15 => [ 'ElementIsNotSelectable',     'An attempt was made to select an element that cannot be selected.' ],
    17 => [ 'JavaScriptError',            'An error occurred while executing user supplied JavaScript.' ],
    19 => [ 'XPathLookupError',           'An error occurred while searching for an element by XPath.' ],
    21 => [ 'Timeout',                    'An operation did not complete before its timeout expired.' ],
    23 => [ 'NoSuchWindow',               'A request to switch to a different window could not be satisfied because the window could not be found.' ],
    24 => [ 'InvalidCookieDomain',        'An illegal attempt was made to set a cookie under a different domain than the current page.' ],
    25 => [ 'UnableToSetCookie',          q[A request to set a cookie's value could not be satisfied.] ],
    26 => [ 'UnexpectedAlertOpen',        'A modal dialog was open, blocking this operation' ],
    27 => [ 'NoAlertOpenError',           'An attempt was made to operate on a modal dialog when one was not open.' ],
    28 => [ 'ScriptTimeout',              'A script did not complete before its timeout expired.' ],
    29 => [ 'InvalidElementCoordinates',  'The coordinates provided to an interactions operation are invalid.' ],
    30 => [ 'IMENotAvailable',            'IME was not available.' ],
    31 => [ 'IMEEngineActivationFailed',  'An IME engine could not be started.' ],
    32 => [ 'InvalidSelector',            'Argument was an invalid selector (e.g. XPath/CSS).' ],
    33 => [ 'SessionNotCreatedException', 'A new session could not be created.' ],
    34 => [ 'MoveTargetOutOfBounds',      'Target provided for a move action is out of bounds.' ],
};

const our $WD_CLASS_NAME     => 'class name';
const our $WD_CSS_SELECTOR   => 'css selector';
const our $WD_ID             => 'id';
const our $WD_NAME           => 'name';
const our $WD_LINK_TEXT      => 'link text';
const our $WD_LINK_TEXT_PART => 'partial link text';
const our $WD_TAG_NAME       => 'tag name';
const our $WD_XPATH          => 'xpath';

const our $WD_KEY => {
    NULL         => "\N{U+E000}",
    CANCEL       => "\N{U+E001}",
    HELP         => "\N{U+E002}",
    BACKSPACE    => "\N{U+E003}",
    TAB          => "\N{U+E004}",
    CLEAR        => "\N{U+E005}",
    RETURN       => "\N{U+E006}",
    ENTER        => "\N{U+E007}",
    SHIFT        => "\N{U+E008}",
    CONTROL      => "\N{U+E009}",
    ALT          => "\N{U+E00A}",
    PAUSE        => "\N{U+E00B}",
    ESCAPE       => "\N{U+E00C}",
    SPACE        => "\N{U+E00D}",
    PAGE_UP      => "\N{U+E00E}",
    PAGE_DOWN    => "\N{U+E00f}",
    END          => "\N{U+E010}",
    HOME         => "\N{U+E011}",
    LEFT_ARROW   => "\N{U+E012}",
    UP_ARROW     => "\N{U+E013}",
    RIGHT_ARROW  => "\N{U+E014}",
    DOWN_ARROW   => "\N{U+E015}",
    INSERT       => "\N{U+E016}",
    DELETE       => "\N{U+E017}",
    SEMICOLON    => "\N{U+E018}",
    EQUALS       => "\N{U+E019}",
    NUMPAD_0     => "\N{U+E01A}",
    NUMPAD_1     => "\N{U+E01B}",
    NUMPAD_2     => "\N{U+E01C}",
    NUMPAD_3     => "\N{U+E01D}",
    NUMPAD_4     => "\N{U+E01E}",
    NUMPAD_5     => "\N{U+E01F}",
    NUMPAD_6     => "\N{U+E020}",
    NUMPAD_7     => "\N{U+E021}",
    NUMPAD_8     => "\N{U+E022}",
    NUMPAD_9     => "\N{U+E023}",
    MULTIPLY     => "\N{U+E024}",
    ADD          => "\N{U+E025}",
    SEPARATOR    => "\N{U+E026}",
    SUBTRACT     => "\N{U+E027}",
    DECIMAL      => "\N{U+E028}",
    DIVIDE       => "\N{U+E029}",
    F1           => "\N{U+E031}",
    F2           => "\N{U+E032}",
    F3           => "\N{U+E033}",
    F4           => "\N{U+E034}",
    F5           => "\N{U+E035}",
    F6           => "\N{U+E036}",
    F7           => "\N{U+E037}",
    F8           => "\N{U+E038}",
    F9           => "\N{U+E039}",
    F10          => "\N{U+E03A}",
    F11          => "\N{U+E03B}",
    F12          => "\N{U+E03C}",
    COMMAND_META => "\N{U+E03D}",
};

# https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol
# https://w3c.github.io/webdriver/webdriver-spec.html

sub update_all ( $self, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    my $success_all = 1;

    my $cv = AE::cv sub {
        $cb->($success_all) if $cb;

        $blocking_cv->($success_all) if $blocking_cv;

        return;
    };

    $cv->begin;

    # update PhantomJS
    {
        $cv->begin;

        my $url = "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-@{[$ENV->dist('Pcore-WebDriver')->cfg->{phantomjs_ver}]}-" . ( $MSWIN ? 'windows.zip' : 'linux-x86_64.tar.bz2' );

        P->http->get(
            $url,
            buf_size    => 1,
            on_progress => 1,
            on_finish   => sub ($res) {
                my $success = 0;

                if ( $res->status == 200 ) {
                    eval {
                        my $temp = P->file->tempfile;

                        if ($MSWIN) {
                            require IO::Uncompress::Unzip;

                            IO::Uncompress::Unzip::unzip( $res->body->path, $temp->path, Name => "phantomjs-@{[$ENV->dist('Pcore-WebDriver')->cfg->{phantomjs_ver}]}-windows/bin/phantomjs.exe", BinModeOut => 1 );

                            $ENV->share->store( 'bin/webdriver/phantomjs.exe', $temp->path, 'Pcore-WebDriver' );
                        }
                        else {
                            P->file->untar( $res->body->path, $ENV->share->get_storage( 'bin/', 'Pcore-WebDriver' ) . 'webdriver/phantomjs-linux-x64/', strip_component => 1 );
                        }
                    };

                    $success_all = 0 if $@;
                }

                $cv->end;

                return;
            }
        );
    }

    # update chromedriver
    {
        $cv->begin;

        my $url = "https://chromedriver.storage.googleapis.com/@{[$ENV->dist('Pcore-WebDriver')->cfg->{chromedriver_ver}]}/" . ( $MSWIN ? 'chromedriver_win32.zip' : 'chromedriver_linux64.zip' );

        P->http->get(
            $url,
            buf_size    => 1,
            on_progress => 1,
            on_finish   => sub ($res) {
                my $success = 0;

                if ( $res->status == 200 ) {
                    eval {
                        require IO::Uncompress::Unzip;

                        my $temp = P->file->tempfile;

                        IO::Uncompress::Unzip::unzip( $res->body->path, $temp->path, BinModeOut => 1 );

                        if ($MSWIN) {
                            $ENV->share->store( 'bin/webdriver/chromedriver.exe', $temp->path, 'Pcore-WebDriver' );
                        }
                        else {
                            $ENV->share->store( 'bin/webdriver/chromedriver-linux-x64', $temp->path, 'Pcore-WebDriver' );
                        }
                    };

                    $success_all = 0 if $@;
                }

                $cv->end;

                return;
            }
        );
    }

    # update geckodriver
    {
        $cv->begin;

        my $url = "https://github.com/mozilla/geckodriver/releases/download/v@{[$ENV->dist('Pcore-WebDriver')->cfg->{geckodriver_ver}]}/geckodriver-v@{[$ENV->dist('Pcore-WebDriver')->cfg->{geckodriver_ver}]}-" . ( $MSWIN ? 'win32.zip' : 'linux64.tar.gz' );

        P->http->get(
            $url,
            buf_size    => 1,
            on_progress => 1,
            on_finish   => sub ($res) {
                my $success = 0;

                if ( $res->status == 200 ) {
                    eval {
                        my $temp = P->file->tempfile;

                        if ($MSWIN) {
                            require IO::Uncompress::Unzip;

                            IO::Uncompress::Unzip::unzip( $res->body->path, $temp->path, BinModeOut => 1 );

                            $ENV->share->store( 'bin/webdriver/geckodriver.exe', $temp->path, 'Pcore-WebDriver' );
                        }
                        else {
                            P->file->untar( $res->body->path, $ENV->share->get_storage( 'bin/', 'Pcore-WebDriver' ) . 'webdriver/geckodriver-linux-x64', strip_component => 0 );
                        }
                    };

                    $success_all = 0 if $@;
                }

                $cv->end;

                return;
            }
        );
    }

    $cv->end;

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub DEMOLISH ( $self, $global ) {
    if ( !$global && $self->{session_id} ) {
        P->http->_request(
            method  => 'DELETE',
            url     => "http://$self->{host}:$self->{port}/session/$self->{session_id}",
            timeout => 0,
        );
    }

    return;
}

# TODO sleep
around new => sub ( $orig, $self, $args ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $args->{host} ||= '127.0.0.1';

    $args->{port} ||= ( P->sys->get_free_port( $args->{host} ) // die q[Error get free port] );

    $self = $self->$orig($args);

    P->pm->run_proc(
        $self->get_cmd,
        win32_create_no_window => 1,
        on_ready               => sub ($proc) {
            $self->{_proc} = $proc;

            # TODO
            sleep 1;

            $self->new_session(
                undef,
                sub ($session) {
                    $args->{on_ready}->($session) if $args->{on_ready};

                    $blocking_cv->($session) if $blocking_cv;

                    return;
                }
            );

            return;
        },
    );

    return $blocking_cv ? $blocking_cv->recv : ();
};

around get_desired_capabilities => sub ( $orig, $self, $desired_capabilities = undef ) {
    my $cap = P->hash->merge(
        $self->{desired_capabilities} // {},
        $desired_capabilities // {},
        {   javascriptEnabled => $self->disable_javascript ? \0 : \1,
            acceptSslCerts    => \1,
            takesScreenshot   => \1,
            handlesAlerts     => \1,
            proxy             => {
                proxyType     => $self->proxy_type,
                httpProxy     => $self->http_proxy,
                sslProxy      => $self->ssl_proxy,
                socksProxy    => $self->socks_proxy,
                socksUsername => $self->socks_proxy_username,
                socksPassword => $self->socks_proxy_password,
            },
        },
    );

    return $self->$orig($cap);
};

sub new_phantomjs ( $self, %args ) {
    return P->class->load('Pcore::WebDriver::PhantomJS')->new( \%args );
}

sub new_chrome ( $self, %args ) {
    return P->class->load('Pcore::WebDriver::Chrome')->new( \%args );
}

sub new_firefox ( $self, %args ) {
    return P->class->load('Pcore::WebDriver::Firefox')->new( \%args );
}

sub _send_command ( $self, $method, $path, $body, $cb = undef, $processing_cb = undef ) {
    my $blocking_cv = defined $cb ? undef : AE::cv;

    P->http->_request(
        method  => $method,
        url     => "http://$self->{host}:$self->{port}$path",
        timeout => 0,
        ( $body ? ( body => P->data->to_json($body) ) : () ),
        on_finish => sub ($http_res) {
            my $body = $http_res->has_body ? from_json( $http_res->body ) : {};

            my $res;

            if ( $body->{status} ) {
                $res = result [ $body->{status}, $WD_STATUS_REASON->{ $body->{status} }->[1] ];
            }
            else {
                $res = result [ $http_res->status, $http_res->reason ];
            }

            $res->{session_id} = $body->{sessionId};

            $res->{data} = $body->{value};

            if ($processing_cb) {
                $processing_cb->(
                    $res,
                    sub ($res) {
                        $cb->($res) if $cb;

                        $blocking_cv->send($res) if $blocking_cv;

                        return;
                    }
                );
            }
            else {
                $cb->($res) if $cb;

                $blocking_cv->send($res) if $blocking_cv;
            }

            return;
        },
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

# SESSIONS
sub new_session ( $self, $desired_capabilities = undef, $cb = undef ) {
    return $self->_send_command(
        'POST',
        '/session',
        { desiredCapabilities => $self->get_desired_capabilities($desired_capabilities) },
        $cb,
        sub ( $res, $cb ) {
            my $session;

            if ( $self->{session_id} ) {
                $session = bless { $self->%* }, ref $self;
            }
            else {
                $session = $self;
            }

            $session->set_status( [ $res->status, $res->reason ] );

            $session->{session_id} = $res->{session_id};

            $cb->($session);

            return;
        }
    );
}

sub status ( $self, $cb = undef ) {
    return $self->_send_command( 'GET', '/status', undef, $cb );
}

sub sessions ( $self, $cb = undef ) {
    return $self->_send_command( 'GET', '/sessions', undef, $cb );
}

sub set_page_load_timeout ( $self, $ms, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/timeouts", { type => 'page load', ms => $ms }, $cb );
}

sub set_implicit_wait_timeout ( $self, $ms, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/timeouts", { type => 'implicit', ms => $ms }, $cb );
}

sub set_script_timeout ( $self, $ms, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/timeouts", { type => 'script', ms => $ms }, $cb );
}

# NAVIGATION
sub get ( $self, $url, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/url", { url => $url }, $cb );
}

sub get_current_url ( $self, $cb = undef ) {
    return $self->_send_command( 'GET', "/session/$self->{session_id}/url", undef, $cb );
}

sub back ( $self, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/back", undef, $cb );
}

sub forward ( $self, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/forward", undef, $cb );
}

sub refresh ( $self, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/refresh", undef, $cb );
}

sub get_title ( $self, $cb = undef ) {
    return $self->_send_command( 'GET', "/session/$self->{session_id}/title", undef, $cb );
}

# COMMAND CONTEXTS
sub get_window_handle ( $self, $cb = undef ) {
    return $self->_send_command( 'GET', "/session/$self->{session_id}/window_handle", undef, $cb );
}

sub close_window ( $self, $cb = undef ) {
    return $self->_send_command( 'DELETE', "/session/$self->{session_id}/window", undef, $cb );
}

sub switch_to_window ( $self, $window, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/window", { name => $window }, $cb );
}

sub get_window_handles ( $self, $cb = undef ) {
    return $self->_send_command( 'GET', "/session/$self->{session_id}/window_handles", undef, $cb );
}

sub switch_to_frame ( $self, $frame, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/frame", { id => $frame }, $cb );
}

sub switch_to_parent_frame ( $self, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/frame/parent", undef, $cb );
}

# RESIZING AND POSITIONING WINDOWS
sub get_window_size ( $self, $window = undef, $cb = undef ) {
    $window //= 'current';

    return $self->_send_command( 'GET', "/session/$self->{session_id}/window/$window/size", undef, $cb );
}

sub set_window_size ( $self, $width, $height, $window = undef, $cb = undef ) {
    $window //= 'current';

    return $self->_send_command( 'POST', "/session/$self->{session_id}/window/$window/size", { width => $width, height => $height }, $cb );
}

sub get_window_position ( $self, $window = undef, $cb = undef ) {
    $window //= 'current';

    return $self->_send_command( 'GET', "/session/$self->{session_id}/window/$window/position", undef, $cb );
}

sub set_window_position ( $self, $x, $y, $window = undef, $cb = undef ) {
    $window //= 'current';

    return $self->_send_command( 'POST', "/session/$self->{session_id}/window/$window/position", { x => $x, y => $y }, $cb );
}

sub maximize_window ( $self, $window = undef, $cb = undef ) {
    $window //= 'current';

    return $self->_send_command( 'POST', "/session/$self->{session_id}/window/$window/maximize", undef, $cb );
}

sub fullscreen_window ( $self, $window = undef, $cb = undef ) {
    $window //= 'current';

    return $self->_send_command( 'POST', "/session/$self->{session_id}/window/$window/fullscreen", undef, $cb );
}

# ELEMENTS
sub get_active_element ( $self, $cb = undef ) {
    return $self->_send_command(
        'POST',
        "/session/$self->{session_id}/element/active",
        undef, $cb,
        sub ( $res, $cb ) {
            if ($res) {
                $res = bless {
                    webdriver => $self,
                    status    => $res->{status},
                    reason    => $res->{reason},
                    id        => $res->{data}->{ELEMENT},
                  },
                  'Pcore::WebDriver::WebElement';
            }

            $cb->($res);

            return;
        }
    );
}

# ELEMENT RETRIEVAL - FIND ELEMENT
sub find_element ( $self, $locator, $selector, $cb = undef ) {
    return $self->_send_command(
        'POST',
        "/session/$self->{session_id}/element",
        {   using => $locator,
            value => $selector,
        },
        $cb,
        sub ( $res, $cb ) {
            if ($res) {
                $res = bless {
                    webdriver => $self,
                    status    => $res->{status},
                    reason    => $res->{reason},
                    id        => $res->{data}->{ELEMENT},
                  },
                  'Pcore::WebDriver::WebElement';
            }

            $cb->($res);

            return;
        }
    );
}

sub find_element_by_class_name ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_CLASS_NAME, $selector, $cb );
}

sub find_element_by_css_selector ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_CSS_SELECTOR, $selector, $cb );
}

sub find_element_by_id ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_ID, $selector, $cb );
}

sub find_element_by_name ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_NAME, $selector, $cb );
}

sub find_element_by_link_text ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_LINK_TEXT, $selector, $cb );
}

sub find_element_by_link_text_part ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_LINK_TEXT_PART, $selector, $cb );
}

sub find_element_by_tag_name ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_TAG_NAME, $selector, $cb );
}

sub find_element_by_xpath ( $self, $selector, $cb = undef ) {
    return $self->find_element( $WD_XPATH, $selector, $cb );
}

# ELEMENT RETRIEVAL - FIND ELEMENTS
sub find_elements ( $self, $locator, $selector, $cb = undef ) {
    my $blocking_cv = defined $cb ? undef : AE::cv;

    $self->_send_command(
        'POST',
        "/session/$self->{session_id}/elements",
        {   using => $locator,
            value => $selector,
        },
        sub ($res) {
            if ($res) {
                my $elements = delete $res->{data};

                for my $el ( $elements->@* ) {
                    push $res->{data}->@*,
                      bless {
                        webdriver => $self,
                        status    => $res->{status},
                        reason    => $res->{reason},
                        id        => $el->{ELEMENT},
                      },
                      'Pcore::WebDriver::WebElement';
                }
            }

            $cb->($res) if $cb;

            $blocking_cv->send($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub find_elements_by_class_name ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_CLASS_NAME, $selector, $cb );
}

sub find_elements_by_css_selector ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_CSS_SELECTOR, $selector, $cb );
}

sub find_elements_by_id ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_ID, $selector, $cb );
}

sub find_elements_by_name ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_NAME, $selector, $cb );
}

sub find_elements_by_link_text ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_LINK_TEXT, $selector, $cb );
}

sub find_elements_by_link_text_part ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_LINK_TEXT_PART, $selector, $cb );
}

sub find_elements_by_tag_name ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_TAG_NAME, $selector, $cb );
}

sub find_elements_by_xpath ( $self, $selector, $cb = undef ) {
    return $self->find_elements( $WD_XPATH, $selector, $cb );
}

# DOCUMENT HANDLING
sub get_page_source ( $self, $cb = undef ) {
    return $self->_send_command( 'GET', "/session/$self->{session_id}/source", undef, $cb );
}

sub exec ( $self, $script, $args = undef, $cb = undef ) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    return $self->_send_command( 'POST', "/session/$self->{session_id}/execute", { script => $script, args => $args // [] }, $cb );
}

sub exec_async ( $self, $script, $args = undef, $cb = undef ) {
    return $self->_send_command( 'POST', "/session/$self->{session_id}/execute_async", { script => $script, args => $args // [] }, $cb );
}

# COOKIES
sub get_all_cookies ( $self, $cb = undef ) {
    ...;

    return;
}

sub get_named_cookie ( $self, $cb = undef ) {
    ...;

    return;
}

sub add_cookie ( $self, $cb = undef ) {
    ...;

    return;
}

sub delete_cookie ( $self, $cb = undef ) {
    ...;

    return;
}

sub delete_all_cookies ( $self, $cb = undef ) {
    ...;

    return;
}

# ACTIONS

# USER PROMPTS
sub dismiss_alert ( $self, $cb = undef ) {
    ...;

    return;
}

sub accept_alert ( $self, $cb = undef ) {
    ...;

    return;
}

sub get_alert_text ( $self, $cb = undef ) {
    ...;

    return;
}

sub send_alert_text ( $self, $cb = undef ) {
    ...;

    return;
}

# SCREEN CAPTURE
sub get_screenshot ( $self, $crop = undef, $cb = undef ) {
    my $blocking_cv = defined $cb ? undef : AE::cv;

    my $done = sub ($res) {
        $cb->($res) if $cb;

        $blocking_cv->($res) if $blocking_cv;

        return;
    };

    my $start = sub {
        $self->_send_command(
            'GET',
            "/session/$self->{session_id}/screenshot",
            undef, $done,
            sub ( $res, $cb ) {
                if ($res) {
                    $res->{data} = from_b64 $res->{data};

                    $res->{type} = 'png';

                    if ($crop) {
                        state $init = !!require Imager;

                        my $img = Imager->new;

                        $img->read( data => $res->{data}, type => 'png' );

                        my %params = (
                            left   => $crop->{left},
                            top    => $crop->{top},
                            width  => 0,
                            height => 0,
                        );

                        if ( $crop->{width} ) {
                            $params{width} = $crop->{width};
                        }
                        elsif ( $crop->{right} ) {
                            $params{width} = $crop->{right} - $crop->{left};
                        }
                        else {
                            $params{width} = $img->getwidth - $crop->{left};
                        }

                        if ( $crop->{height} ) {
                            $params{height} = $crop->{height};
                        }
                        elsif ( $crop->{bottom} ) {
                            $params{height} = $crop->{bottom} - $crop->{top};
                        }
                        else {
                            $params{height} = $img->getheight - $crop->{top};
                        }

                        my $cropped = $img->crop(%params);

                        $cropped->write( data => \$res->{data}, type => 'png' );

                        ( $res->{width}, $res->{height} ) = ( $cropped->getwidth, $cropped->getheight );
                    }
                }

                $cb->($res);

                return;
            }
        );

        return;
    };

    my $include_flash = 0;

    if ($include_flash) {
        $self->set_wmode(
            undef,
            sub ($wmode) {
                if ( !$wmode ) {
                    $done->($wmode);
                }
                else {
                    $start->();
                }

                return;
            }
        );
    }
    else {
        $start->();
    }

    return $blocking_cv ? $blocking_cv->recv : undef;
}

sub open_window ( $self, $args, $cb = undef ) {
    my $blocking_cv = defined $cb ? undef : AE::cv;

    my $win_args = {
        url        => undef,
        name       => '_blank',
        naked      => 0,          # disable all browser elements by default, each element visibility can be redefined individually
        width      => 100,
        height     => '100',
        left       => 0,
        location   => 1,
        menubar    => 1,
        resizable  => 1,
        scrollbars => 1,
        status     => 1,
        titlebar   => 1,
        toolbar    => 1,
        $args->%*,
    };

    my $url = delete $win_args->{url} // q[];

    my $name = delete $win_args->{name} // q[];

    if ( delete $win_args->{naked} ) {
        $win_args->@{qw[location menubar resizable scrollbars status titlebar toolbar]} = ( 0, 0, 0, 0, 0, 0, 0 );
    }

    my $params = join q[,], map {"$_=$win_args->{$_}"} keys $win_args->%*;

    $name = 'w' . int rand 99_999_999 if !$name || $name eq '_blank';

    my $done = sub ($res) {
        $cb->($res) if $cb;

        $blocking_cv->($res) if $blocking_cv;

        return;
    };

    $self->exec(
        'window.open(arguments[0], arguments[1], arguments[2])',
        [ $url, $name, $params ],
        sub ($res) {
            if ( !$res ) {
                $done->($res);
            }
            else {
                $self->switch_to_window(
                    $name,
                    sub ($res) {
                        if ( !$res ) {
                            $done->($res);
                        }
                        else {
                            $self->get_window_handle($done);
                        }

                        return;
                    }
                );
            }

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : undef;
}

sub set_wmode ( $self, $parent = undef, $cb = undef ) {
    my $js = <<'JS';
        var embeds = arguments[0] ? arguments[0].getElementsByTagName('embed') : document.getElementsByTagName('embed');

        for (i = 0; i < embeds.length; i++) {
            if (!embeds[i].getAttribute('wmode') || embeds[i].getAttribute('wmode').toLowerCase() == 'window'){
                var embed = embeds[i].cloneNode(true);
                embed.setAttribute('wmode', 'transparent');
                embeds[i].parentNode.replaceChild(embed, embeds[i]);
            }
        }
JS

    return $self->exec( $js, $parent, $cb );
}

# TODO
# не пост запросы можно открывать в новом окне и затем получать контент окна
# при этом не сможем получить http хедеры
# проверить - передается ли реферер при открытии нового окна со ссылкой и без
# проверить - можем ли мы указывать реферер в ajax запросах
# ajax запросы могут не работать для других доменов, в таком случае получение контента возможно только через открытие нового окна, или через механизм onevent для ифреймов
# iframe onevent предпочтительнее, т.к. могут быть доступны хедеры ответа
# - добавить функционал запрещения кеширования
# - проеврить подмену реферера в ajax
# - проверить сохраниение реферера для нового окна с передачей url при открытии и методом get
# - решить проблему кроссдоменных запросов
# sub _get_binary_data {
#     my $self = shift;
#     my $url  = shift;
#     my %args = (
#         post => undef,
#         @_
#     );
#
#     # TODO maybe encoding needed
#     if ( $args{post} ) {
#         $args{post} = join q[&], map { $_ . q[=] . P->data->to_uri( $args{post}->{$_} ) } keys %{ $args{post} };
#     }
#
#     $self->set_async_script_timeout(50_000);
#     my $js = <<'JS';
#         var url = arguments[0];
#         var options = arguments[1];
#         var callback = arguments[arguments.length-1];
#         var xhr = new XMLHttpRequest();
#         xhr.overrideMimeType('text/plain; charset=x-user-defined');
#         xhr.onreadystatechange = function(){
#             if(xhr.readyState == 4){
#                 var binStr = xhr.responseText;
#                 var byte = new Array();
#                 for (var i = 0, len = binStr.length; i < len; ++i) {
#                     var c = binStr.charCodeAt(i);
#                     byte[i] = c & 0xff;
#                 }
#                 callback({
#                     code:    xhr.status,
#                     headers: xhr.getAllResponseHeaders(),
#                     body:    byte
#                 });
#             }
#         }
#         if(options.post){
#             xhr.open('POST', url, true);
#             xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
#             xhr.send(options.post);
#         }
#         else{
#             xhr.open('GET', url, true);
#             xhr.send(null);
#         }
# JS
#     my $callback = 'return arguments[0];';
#     my $res = $self->execute_async_script( $js, $url, \%args, $callback );
#     return unless $res->{code};
#
#     my $body = q[];
#
#     for ( $res->{body}->@* ) {
#         $body .= chr;
#     }
#
#     my $r = HTTP::Response->parse( 'HTTP/1.0 ' . $res->{code} . q[ ] . $CRLF . $res->{headers} . $body );
#
#     return $r;
# }

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 164, 203, 242        | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 274, 358             | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 355                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 706, 712, 718, 724,  | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## |      | 730, 739, 745, 751,  |                                                                                                                |
## |      | 757                  |                                                                                                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebDriver - non-blocking WebDriver protocol implementation

=head1 SYNOPSIS

    use Pcore::WebDriver;

    my $cv = AE::cv;

    my $wd1 = Pcore::WebDriver->new_phantomjs;
    my $wd2 = Pcore::WebDriver->new_chrome;

    # manage several browsers simultaneously from the single process
    $wd1->get('https://www.google.com/', sub ($res) {
        die $res if !$res;

        $wd1->find_element_by_xpath(..., sub ($web_element) {
            return;
        });

        return;
    });

    # this is a non-blocking call
    $wd2->get('https://www.facebook.com/', sub ($res) {
        die $res if !$res;

        # also non-blocking
        $wd1->find_element_by_xpath(..., sub ($web_element) {
            return;
        });

        return;
    });

    # calls without defined callback, or called with defined return context (defined wantarray) - are blocking
    # blocking call:
    my $res = $wd1->find_element_by_id('id');

    # also blocking:
    $wd1->find_element_by_id('id');

    $cv->recv;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
