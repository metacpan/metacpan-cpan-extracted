package Pcore::WebDriver v0.9.7;

use Pcore -dist, -const, -class, -result,
  -export => {
    WD_LOCATOR => [qw[$WD_SEL_CLASS_NAME $WD_SEL_CSS $WD_SEL_ID $WD_SEL_NAME $WD_SEL_LINK_TEXT $WD_SEL_LINK_TEXT_PART $WD_SEL_TAG $WD_SEL_XPATH]],
    WD_KEY     => [qw[$WD_KEY]],
    CONST      => [qw[:WD_LOCATOR :WD_KEY]],
  };
use Pcore::Util::Scalar qw[is_plain_coderef];
require Pcore::WebDriver::Session;

has host         => ( is => 'ro', isa => Str,         required => 1 );
has port         => ( is => 'ro', isa => PositiveInt, required => 1 );
has is_chrome    => ( is => 'ro', isa => Bool,        required => 1 );
has is_phantomjs => ( is => 'ro', isa => Bool,        required => 1 );

has _proc => ( is => 'ro', isa => InstanceOf ['Pcore::Util:PM::Proc'], init_arg => undef );    # webdriver proc handle

const our $WD_SEL_CLASS_NAME     => 'class name';
const our $WD_SEL_CSS            => 'css selector';
const our $WD_SEL_ID             => 'id';
const our $WD_SEL_NAME           => 'name';
const our $WD_SEL_LINK_TEXT      => 'link text';
const our $WD_SEL_LINK_TEXT_PART => 'partial link text';
const our $WD_SEL_TAG            => 'tag name';
const our $WD_SEL_XPATH          => 'xpath';

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

                            P->file->chmod( 'rwxr-xr-x', $ENV->share->get('/bin/webdriver/chromedriver-linux-x64') );
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

    # term process group
    kill '-TERM', $self->{_proc}->{pid} if $self->{_proc};    ## no critic qw[InputOutput::RequireCheckedSyscalls]

    return;
}

around new => sub ( $orig, $self, $driver, @args ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    my %args = (
        host => '127.0.0.1',
        port => undef,
        bin  => undef,
        xvfb => undef,         # chrome only
        args => undef,
        @args,
    );

    $args{host} ||= '127.0.0.1';

    $args{port} ||= ( P->sys->get_free_port( $args{host} ) // die q[Error get free port] );

    $self = bless {
        host         => $args{host},
        port         => $args{port},
        is_chrome    => $driver eq 'chrome' ? 1 : 0,
        is_phantomjs => $driver eq 'phantomjs' ? 1 : 0,
        xvfb         => $driver eq 'chrome' && $args{xvfb} && !$MSWIN ? 1 : 0,
      },
      __PACKAGE__;

    my $cmd_method = "_get_${driver}_cmd";

    P->pm->run_proc(
        $self->$cmd_method( \%args ),
        win32_create_no_window => 1,
        on_ready               => sub ($proc) {
            $self->{_proc} = $proc;

            if ( $self->{xvfb} ) {
                sleep 5;
            }
            else {
                sleep 1;
            }

            $cb->($self) if $cb;

            $blocking_cv->($self) if $blocking_cv;

            return;
        },
    );

    return $blocking_cv ? $blocking_cv->recv : ();
};

sub _get_chrome_cmd ( $self, $args ) {
    $args->{bin} = $ENV->share->get( $MSWIN ? '/bin/webdriver/chromedriver.exe' : '/bin/webdriver/chromedriver-linux-x64' ) if !$args->{bin};

    my $cmd = [    #
        $self->{xvfb} ? ( 'xvfb-run', '-d', '--server-args="-screen 0 1280x720x8"' ) : (),
        qq["$args->{bin}"],
        "--port=$args->{port}",
        '--silent',
        defined $args->{args} ? $args->{args}->@* : (),
    ];

    return join q[ ], $cmd->@*;
}

sub _get_phantomjs_cmd ( $self, $args ) {
    $args->{bin} = $ENV->share->get( $MSWIN ? '/bin/webdriver/phantomjs.exe' : '/bin/webdriver/phantomjs-linux-x64/bin/phantomjs' );

    my $cmd = [    #
        qq["$args->{bin}"],
        "--webdriver=$args->{host}:$args->{port}",
        '--webdriver-loglevel=NONE',
        '--debug=no',
        '--ignore-ssl-errors=yes',
        '--web-security=no',
        defined $args->{args} ? $args->{args}->@* : (),
    ];

    return join q[ ], $cmd->@*;
}

sub new_session ( $self, @args ) {
    my $wds = bless { wdh => $self }, 'Pcore::WebDriver::Session';

    $wds->new(@args);

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 115, 154             | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 247                  | * Private subroutine/method '_get_chrome_cmd' declared but not used                                            |
## |      | 261                  | * Private subroutine/method '_get_phantomjs_cmd' declared but not used                                         |
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
