package Pcore::Chrome v0.15.0;

use Pcore -dist, -class, -res, -const;
use Pcore::Chrome::Tab;
use Pcore::Util::Scalar qw[weaken];
use Pcore::Util::Data qw[from_json];

has bin => ();

has listen        => '//127.0.0.1';
has pac_listen    => '//127.0.0.1';
has user_data_dir => sub { P->file1->tempdir };
has useragent     => ();

has _proc       => ();
has _pac_server => ();
has _pac_func   => ();

# https://chromedevtools.github.io/devtools-protocol/tot/
# https://peter.sh/experiments/chromium-command-line-switches/

const our $CHECK_PORT_TIMEOUT => 0.1;
const our $CONNECT_TIMEOUT    => 10;

sub DESTROY ( $self ) {

    # term process group
    kill '-TERM', $self->{_proc}->{pid} if defined $self->{_proc};    ## no critic qw[InputOutput::RequireCheckedSyscalls]

    return;
}

around new => sub ( $orig, $self, %args ) {
    $args{bin} ||= $MSWIN ? "$ENV{'ProgramFiles(x86)'}/Google/Chrome/Application/chrome.exe" : '/usr/bin/google-chrome';

    my $user_args = delete $args{args};

    $self = $self->$orig(%args);

    $self->{listen}     = P->net->parse_listen( $self->{listen} );
    $self->{pac_listen} = P->net->parse_listen( $self->{pac_listen} );

    $self->_build_pac_func( $args{proxy} );

    $self->_run_pac_server;

    my $cmd = [
        qq["$args{bin}"],

        "--remote-debugging-address=$self->{listen}->{host}",
        "--remote-debugging-port=$self->{listen}->{port}",

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
        '--no-default-browser-check',
        '--no-first-run',
        '--disable-infobars',
        '--disable-popup-blocking',
        '--disable-default-apps',
        '--disable-web-security',
        '--allow-running-insecure-content',

        qq[--proxy-pac-url="http://$self->{pac_listen}->{host_port}/"],

        # logging
        # '--disable-logging',
        # '--log-level=0',

        # set user profile dir
        qq[--user-data-dir="$self->{user_data_dir}"],

        # required for run under docker
        '--no-sandbox',

        # user agent
        defined $self->{useragent} ? qq[--user-agent="$self->{useragent}"] : (),

        # headless mode
        $args{headless} || !$MSWIN ? ( '--headless', '--disable-gpu' ) : (),

        # user args
        $user_args ? $user_args->@* : (),

        # open "about:blank" by default
        # 'about:blank',

        # redirect STDERR under linux
        !$MSWIN ? '2>/dev/null' : (),
    ];

    $self->{_proc} = P->sys->run_proc( join( $SPACE, $cmd->@* ) );

    my $time = time + ( $args{timeout} // $CONNECT_TIMEOUT );

    while () {
        Coro::sleep($CHECK_PORT_TIMEOUT);

        last if P->net->check_port( $self->{listen}->{host}, $self->{listen}->{port}, $CHECK_PORT_TIMEOUT );

        die qq[Unable to connect to the google chrome on $self->{listen}->{host_port}] if time > $time;
    }

    return $self;
};

sub tabs ( $self ) {
    my $res = P->http->get("http://$self->{listen}->{host_port}/json");

    my $tabs = from_json $res->{data};

    for my $tab ( $tabs->@* ) {
        $tab = bless { chrome => $self, id => $tab->{id} }, 'Pcore::Chrome::Tab';
    }

    return res 200, $tabs;
}

sub new_tab ( $self, $url = undef ) {
    my $res = P->http->get( "http://$self->{listen}->{host_port}/json/new?" . ( $url // 'about:blank' ) );

    my $data = from_json $res->{data};

    my $tab = bless { chrome => $self, id => $data->{id} }, 'Pcore::Chrome::Tab';

    return $tab;
}

sub set_pac_func ( $self, $js ) {
    $self->{_pac_func} = $js;

    $self->reload_pac;

    return;
}

sub set_proxy ( $self, $proxy ) {
    $self->_build_pac_func($proxy);

    $self->reload_pac;

    return;
}

sub reload_pac ($self) {
    my $tab = $self->new_tab('about:blank');

    my $res = $tab->navigate_to('chrome://net-internals/#proxy');

    $tab->('Runtime.enable');

    $res = $tab->( 'Runtime.evaluate', { expression => q[document.getElementById("proxy-view-reload-settings").click()] } );

    return;
}

sub _build_pac_func ( $self, $proxy ) {
    my $pac_proxy;

    if ( !$proxy ) {
        $pac_proxy = 'DIRECT';
    }
    else {
        my $uri = P->uri($proxy);

        if ( !$uri ) {
            $pac_proxy = 'DIRECT';
        }
        elsif ( $uri->{scheme} eq 'socks' ) {
            $pac_proxy = "SOCKS $uri->{host_port}";
        }
        else {
            $pac_proxy = "PROXY $uri->{host_port}";
        }
    }

    $self->{_pac_func} = <<"JS";
function FindProxyForURL ( url, host ) {
    return "$pac_proxy";
}
JS

    return;
}

sub _run_pac_server ($self) {
    require Pcore::HTTP::Server;

    weaken $self;

    $self->{_pac_server} = Pcore::HTTP::Server->new(
        listen     => $self->{pac_listen},
        on_request => sub ($req) {
            return 200, [ 'Content-Type' => 'application/x-ns-proxy-autoconfig' ], $self->{_pac_func} || $EMPTY;
        }
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
## |    2 | 89                   | CodeLayout::ProhibitQuotedWordLists - List of quoted literal words                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 101                  | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Chrome

=head1 SYNOPSIS

    use Pcore::Chrome;

    my $chrome = Pcore::Chrome->new(
        host      => '127.0.0.1',     # chrome --remote-debugging-address
        port      => 9222,            # chrome --remote-debugging-port
        bin       => undef,           # chrome binary path
        timeout   => 3,               # chrome startup timeout
        headless  => 1,               # run chrome in headless mode
        useragent => undef,           # redefine User-Agent
    );

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by zdm.

=cut
