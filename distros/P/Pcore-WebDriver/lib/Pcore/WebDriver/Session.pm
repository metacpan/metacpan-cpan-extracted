package Pcore::WebDriver::Session;

use Pcore -const, -class, -result;
use Pcore::WebDriver qw[:CONST];
use Pcore::Util::Data qw[to_json from_json from_b64];
use Pcore::Util::Scalar qw[is_plain_coderef];
use Pcore::WebDriver::Window;
use Pcore::WebDriver::Element;

has wdh => ( is => 'ro', isa => InstanceOf ['Pcore::WebDriver'], required => 1 );
has is_chrome    => ( is => 'ro', isa => Bool, required => 1 );
has is_phantomjs => ( is => 'ro', isa => Bool, required => 1 );

has id => ( is => 'ro', isa => Str, init_arg => undef );

has _cmd_queue  => ( is => 'ro', isa => ArrayRef, init_arg => undef );
has _is_waiting => ( is => 'ro', isa => Bool,     init_arg => undef );

const our $DEFAULT_USERAGENT => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.101 Safari/537.36';

# https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol
our $CMD;
const $CMD => {
    status => sub ( $self, $cb ) {
        return [ 'GET', '/status', undef, $cb, 1 ];
    },
    sessions => sub ( $self, $cb ) {
        return [ 'GET', '/sessions', undef, $cb, 1 ];
    },

    set_page_load_timeout => sub ( $self, $ms, $cb = undef ) {
        return [ 'POST', "/session/$self->{id}/timeouts", { type => 'page load', ms => $ms }, $cb, 0 ];
    },
    set_implicit_wait_timeout => sub ( $self, $ms, $cb = undef ) {
        return [ 'POST', "/session/$self->{id}/timeouts", { type => 'implicit', ms => $ms }, $cb, 0 ];
    },
    set_script_wait_timeout => sub ( $self, $ms, $cb = undef ) {
        return [ 'POST', "/session/$self->{id}/timeouts", { type => 'script', ms => $ms }, $cb, 0 ];
    },

    get => sub ( $self, $url, $cb = undef ) {
        return [ 'POST', "/session/$self->{id}/url", { url => $url }, $cb, 0 ];
    },
    get_new_win => sub ( $self, $url, $cb = undef ) {
        return $CMD->{exec}->(
            $self,
            url => $url,
            'window.open(args.url)',
            sub ( $wds, $stat, $data ) {
                if ( !$stat ) {
                    $cb->( $wds, $stat, undef );
                }
                else {
                    $wds->unshift_cmd(
                        'get_wins',
                        sub ( $wds, $stat, $wins ) {
                            if ( !$stat ) {
                                $cb->( $wds, $stat, undef );
                            }
                            else {
                                $cb->( $wds, $stat, $wins->[-1] );
                            }

                            return;
                        }
                    );
                }

                return;
            }
        );
    },
    get_current_url => sub ( $self, $cb ) {
        return [ 'GET', "/session/$self->{id}/url", undef, $cb, 1 ];
    },
    get_title => sub ( $self, $cb ) {
        return [ 'GET', "/session/$self->{id}/title", undef, $cb, 1 ];
    },

    get_src => sub ( $self, $cb ) {
        return [ 'GET', "/session/$self->{id}/source", undef, $cb, 1 ];
    },

    exec => sub ( $self, @args ) {
        my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

        my $func = pop @args;

        my $js = <<"JS";
            var func = function (args) {
                $func
            };

            func(arguments[0]);
JS

        return [ 'POST', "/session/$self->{id}/execute", { script => $js, args => [ {@args} ] }, $cb, 1 ];
    },
    exec_async => sub ( $self, @args ) {
        my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

        my $func = pop @args;

        my $js = <<"JS";
            var cb = arguments[arguments.length - 1];

            var func = function (cb, args) {
                $func
            };

            func(cb, arguments[0]);
JS

        return [ 'POST', "/session/$self->{id}/execute_async", { script => $js, args => [ {@args} ] }, $cb, 1 ];
    },

    get_win => sub ( $self, $cb ) {
        return [
            'GET',
            "/session/$self->{id}/window_handle",
            undef,
            sub ( $wds, $stat, $data ) {
                my $win;

                if ($stat) {
                    $win = bless { wds => $wds, id => $data }, 'Pcore::WebDriver::Window';
                }

                $cb->( $wds, $stat, $win );

                return;
            },
            1
        ];
    },
    get_wins => sub ( $self, $cb ) {
        return [
            'GET',
            "/session/$self->{id}/window_handles",
            undef,
            sub ( $wds, $stat, $data ) {
                my $wins;

                if ($stat) {
                    for my $win ( $data->@* ) {
                        push $wins->@*, bless { wds => $wds, id => $win }, 'Pcore::WebDriver::Window';
                    }
                }

                $cb->( $wds, $stat, $wins );

                return;
            },
            1
        ];
    },
    close_win => sub ( $self, $cb = undef ) {
        return [ 'DELETE', "/session/$self->{id}/window", undef, $cb, 0 ];
    },
    switch_win => sub ( $self, $win, $cb = undef ) {
        return [ 'POST', "/session/$self->{id}/window", { name => $win }, $cb, 0 ];
    },

    get_active_el => sub ( $self, $cb ) {
        return [
            'POST',
            "/session/$self->{id}/element/active",
            undef,
            sub ( $wds, $stat, $data ) {
                my $el;

                if ($stat) {
                    $el = bless {
                        wds => $wds,
                        id  => $data->{ELEMENT},
                      },
                      'Pcore::WebDriver::Element';
                }

                $cb->( $wds, $stat, $el );

                return;
            },
            1
        ];
    },

    find_el => sub ( $self, $locator, $selector, $cb ) {
        return [
            'POST',
            "/session/$self->{id}/element",
            {   using => $locator,
                value => $selector,
            },
            sub ( $wds, $stat, $data ) {
                my $el;

                if ($stat) {
                    $el = bless {
                        wds => $wds,
                        id  => $data->{ELEMENT},
                      },
                      'Pcore::WebDriver::Element';
                }

                $cb->( $wds, $stat, $el );

                return;
            },
            1
        ];
    },
    find_el_by_class_name => sub ( $self, $selector, $cb ) {
        return $CMD->{find_el}->( $self, $WD_SEL_CLASS_NAME, $selector, $cb );
    },
    find_el_by_css => sub ( $self, $selector, $cb ) {
        return $CMD->{find_el}->( $self, $WD_SEL_CSS, $selector, $cb );
    },
    find_el_by_id => sub ( $self, $selector, $cb ) {
        return $CMD->{find_el}->( $self, $WD_SEL_ID, $selector, $cb );
    },
    find_el_by_name => sub ( $self, $selector, $cb ) {
        return $CMD->{find_el}->( $self, $WD_SEL_NAME, $selector, $cb );
    },
    find_el_by_link_text => sub ( $self, $selector, $cb ) {
        return $CMD->{find_el}->( $self, $WD_SEL_LINK_TEXT, $selector, $cb );
    },
    find_el_by_link_text_part => sub ( $self, $selector, $cb ) {
        return $CMD->{find_el}->( $self, $WD_SEL_LINK_TEXT_PART, $selector, $cb );
    },
    find_el_by_tag => sub ( $self, $selector, $cb ) {
        return $CMD->{find_el}->( $self, $WD_SEL_TAG, $selector, $cb );
    },
    find_el_by_xpath => sub ( $self, $selector, $cb ) {
        return $CMD->{find_el}->( $self, $WD_SEL_XPATH, $selector, $cb );
    },

    find_els => sub ( $self, $locator, $selector, $cb ) {
        return [
            'POST',
            "/session/$self->{id}/elements",
            {   using => $locator,
                value => $selector,
            },
            sub ( $wds, $stat, $data ) {
                my $els;

                if ($stat) {
                    for my $el ( $data->@* ) {
                        push $els->@*,
                          bless {
                            wds => $wds,
                            id  => $el->{ELEMENT},
                          },
                          'Pcore::WebDriver::Element';
                    }
                }

                $cb->( $wds, $stat, $els );

                return;
            },
            1
        ];
    },
    find_els_by_class_name => sub ( $self, $selector, $cb ) {
        return $CMD->{find_els}->( $self, $WD_SEL_CLASS_NAME, $selector, $cb );
    },
    find_els_by_css => sub ( $self, $selector, $cb ) {
        return $CMD->{find_els}->( $self, $WD_SEL_CSS, $selector, $cb );
    },
    find_els_by_id => sub ( $self, $selector, $cb ) {
        return $CMD->{find_els}->( $self, $WD_SEL_ID, $selector, $cb );
    },
    find_els_by_name => sub ( $self, $selector, $cb ) {
        return $CMD->{find_els}->( $self, $WD_SEL_NAME, $selector, $cb );
    },
    find_els_by_link_text => sub ( $self, $selector, $cb ) {
        return $CMD->{find_els}->( $self, $WD_SEL_LINK_TEXT, $selector, $cb );
    },
    find_els_by_link_text_part => sub ( $self, $selector, $cb ) {
        return $CMD->{find_els}->( $self, $WD_SEL_LINK_TEXT_PART, $selector, $cb );
    },
    find_els_by_tag => sub ( $self, $selector, $cb ) {
        return $CMD->{find_els}->( $self, $WD_SEL_TAG, $selector, $cb );
    },
    find_els_by_xpath => sub ( $self, $selector, $cb ) {
        return $CMD->{find_els}->( $self, $WD_SEL_XPATH, $selector, $cb );
    },
};

# install methods
for my $method ( keys $CMD->%* ) {
    no strict qw[refs];

    *$method = sub {
        my ( $self, @args ) = @_;

        $self->push_cmd( $method, @args );

        return;
    };
}

# TODO remove chrome scoped_dir, not removed under windows
sub DEMOLISH ( $self, $global ) {
    if ( !$global && $self->{id} ) {
        P->http->request(
            method  => 'DELETE',
            url     => "http://$self->{wdh}->{host}:$self->{wdh}->{port}/session/$self->{id}",
            timeout => 0,
        );
    }

    # unlink chrome scoped_dir
    P->file->rmtree( $self->{_chrome_scoped_dir} ) if $self->{_chrome_scoped_dir};

    return;
}

# https://github.com/SeleniumHQ/selenium/wiki/DesiredCapabilities
#
# https://sites.google.com/a/chromium.org/chromedriver/capabilities
#
# http://phantomjs.org/api/webpage/property/settings.html
# https://github.com/detro/ghostdriver
# phantomjs.page.customHeaders.HEADER = VALUE - Add extra HTTP Headers when loading a URL (see reference)
# phantomjs.page.whitelist - an array of regex expressions of urls to accept. eg. ['my-awesome-website.com']
# phantomjs.page.blacklist - array of regex expressions of urls to ignore. The blacklist overrides the whitelist. eg. ['google.com', 'github.com']
# unhandledPromptBehavior - set to dismiss to automatically dismiss all user prompts or set to accept to automatically accept all user prompts
# loggingPrefs - ghostdriver has two logs browser and har. The logs default to "OFF". follow the DesiredCapabilities documentation to enable the logs.
sub _get_desired_caps ( $self, $args ) {

    # common options
    my $caps = {

        # javascriptEnabled => $self->{disable_javascript} ? \0 : \1,
        # acceptSslCerts  => \1,
        # takesScreenshot => \1,
        # handlesAlerts   => \1,
    };

    my $useragent = !exists $args->{useragent} ? $DEFAULT_USERAGENT : $args->{useragent};

    # chrome options
    if ( $self->{wdh}->{is_chrome} ) {
        $caps->{chromeOptions} = {
            args => [    #

                # https://bugs.chromium.org/p/chromium/issues/detail?id=721739
                # NOTE headless chrome ignoring --ignore-certificate-errors
                $args->{proxy} ? ( "--proxy-server=$args->{proxy}", '--ignore-certificate-errors', '--allow-insecure-localhost' ) : (),

                # https://bugs.chromium.org/p/chromedriver/issues/detail?id=878
                # NOTE remote debuggind not works with chromedriver
                # '--remote-debugging-address=192.168.175.10',
                # '--remote-debugging-port=9222',

                '--disable-background-networking',
                '--disable-client-side-phishing-detection',
                '--disable-component-update',
                '--disable-hang-monitor',
                '--disable-prompt-on-repost',
                '--disable-sync',
                '--disable-web-resources',

                '--start-maximized',
                '--window-size=1280x720',

                '--disable-default-apps',
                '--no-first-run',
                '--disable-infobars',
                '--disable-popup-blocking',
                '--disable-default-apps',
                '--disable-web-security',
                '--allow-running-insecure-content',

                # logging
                # '--disable-logging',
                # '--log-level=0',

                # set user profile dir
                qq[--user-data-dir=$ENV->{TEMP_DIR}chrome-wds-@{[P->uuid->str]}],

                # required for run under docker
                '--no-sandbox',

                # user agent
                defined $useragent ? qq[--user-agent=$useragent] : (),

                # headless mode
                ( $args->{headless} || !$MSWIN ) && !$self->{wdh}->{xvfb} ? ( '--headless', '--disable-gpu' ) : (),

                # user args
                $args->{args} ? $args->{args}->@* : (),

                # open "about:blank" by default
                'about:blank',
            ],
            binary => $args->{bin} // q[],
            prefs => {

                #         ( $self->disable_images ? ( 'profile.default_content_setting_values.images' => 2 ) : () ),
                #         ( $self->enable_notifications ? () : ( 'profile.default_content_setting_values.notifications' => 2 ) ),
                #         ( $self->enable_flash         ? () : ( 'profile.default_content_setting_values.plugins'       => 2 ) ),
            }
        };
    }

    # phantomjs options
    elsif ( $self->{wdh}->{is_phantomjs} ) {
        if ( $args->{proxy} ) {
            $caps->{proxy} = {
                proxyType => 'manual',
                httpProxy => $args->{proxy},
                sslProxy  => $args->{proxy},
            };
        }

        $caps->{'phantomjs.page.settings.userAgent'} = $useragent if defined $useragent;
    }

    return { desiredCapabilities => $caps };
}

around new => sub ( $orig, $self, @args ) {
    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    P->http->request(
        method    => 'POST',
        url       => "http://$self->{wdh}->{host}:$self->{wdh}->{port}/session",
        timeout   => 0,
        body      => to_json( $self->_get_desired_caps( {@args} ) ),
        on_finish => sub ($res) {
            if ( !$res ) {
                $cb->( undef, result 500 );
            }
            else {
                my $data = from_json $res->body;

                if ( $data->{status} ) {
                    $cb->( undef, result [ 500, $data->{value}->{message} ] );
                }
                else {
                    my $wds = bless {
                        wdh                => $self->{wdh},
                        is_chrome          => $self->{wdh}->{is_chrome} ? 1 : 0,
                        is_phantomjs       => $self->{wdh}->{is_phantomjs} ? 1 : 0,
                        id                 => $data->{sessionId},
                        _chrome_scoped_dir => $data->{value}->{chrome}->{userDataDir},
                      },
                      __PACKAGE__;

                    $cb->( $wds, result 200 );
                }
            }

            return;
        },
    );

    return;
};

sub push_cmd ( $self, $cmd, @args ) {
    $self->_push_cmd( $CMD->{$cmd}->( $self, @args ) );

    return;
}

sub unshift_cmd ( $self, $cmd, @args ) {
    $self->_unshift_cmd( $CMD->{$cmd}->( $self, @args ) );

    return;
}

sub _push_cmd ( $self, $cmd ) {
    push $self->{_cmd_queue}->@*, $cmd;

    $self->_send_cmd if !$self->{_is_waiting};

    return;
}

sub _unshift_cmd ( $self, $cmd ) {
    unshift $self->{_cmd_queue}->@*, $cmd;

    $self->_send_cmd if !$self->{_is_waiting};

    return;
}

sub _send_cmd ( $self ) {
    return if $self->{_is_waiting};

    my $cmd = shift $self->{_cmd_queue}->@*;

    return if !$cmd;

    $self->{_is_waiting} = 1;

    P->http->request(
        method  => $cmd->[0],
        url     => "http://$self->{wdh}->{host}:$self->{wdh}->{port}$cmd->[1]",
        timeout => 0,
        ( $cmd->[2] ? ( body => to_json $cmd->[2] ) : () ),
        on_finish => sub ($res) {
            my ( $api_res, $value );

            if ( !$res ) {
                if ( $res->{headers}->{CONTENT_TYPE} =~ /json/sm ) {
                    my $data = from_json $res->body;

                    $api_res = result [ $res->{status}, $data->{value}->{message} ];
                }
                else {
                    $api_res = result [ $res->{status}, $res->body->$* ];
                }
            }
            else {
                my $data = from_json $res->body;

                if ( $data->{status} ) {
                    $api_res = result [ 500, $data->{value}->{message} ];
                }
                else {
                    $api_res = result 200;

                    $value = $data->{value};
                }
            }

            $cmd->[3]->( $self, $api_res, $cmd->[4] ? $value : () ) if $cmd->[3];

            $self->{_is_waiting} = 0;

            AE::postpone { $self->_send_cmd };

            return;
        },
    );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1                    | Modules::ProhibitExcessMainComplexity - Main code has high complexity score (22)                               |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 392                  | CodeLayout::ProhibitQuotedWordLists - List of quoted literal words                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebDriver::Session

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
