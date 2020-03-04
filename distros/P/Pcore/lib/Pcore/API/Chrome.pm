package Pcore::API::Chrome;

use Pcore -class, -res, -const;
use Pcore::API::Chrome::Tab;
use Pcore::Util::Scalar qw[weaken];
use Pcore::Util::Data qw[from_json];
use Pcore::API::Proxy;
use Pcore::API::Proxy::Server;

has bin => ();

has listen        => '//127.0.0.1';
has user_data_dir => sub { P->file1->tempdir };
has useragent     => ();
has proxy         => ();

has _proc         => ();
has _proxy_server => ();

# https://chromedevtools.github.io/devtools-protocol/tot/
# https://peter.sh/experiments/chromium-command-line-switches/

const our $CHECK_PORT_TIMEOUT => 0.1;
const our $CONNECT_TIMEOUT    => 10;

sub DESTROY ( $self ) {

    # term process group
    CORE::kill '-TERM', $self->{_proc}->{pid} if !$MSWIN && defined $self->{_proc};

    return;
}

around new => sub ( $orig, $self, %args ) {
    $args{bin} ||= $MSWIN ? "$ENV{'ProgramFiles(x86)'}/Google/Chrome/Application/chrome.exe" : '/usr/bin/google-chrome';

    my $user_args = delete $args{args};

    $self = $self->$orig(%args);

    $self->{listen} = P->net->parse_listen( $self->{listen} );

    if ( $self->{proxy} ) {
        $self->{_proxy_server} = Pcore::API::Proxy::Server->new;

        $self->set_proxy( $self->{proxy} );
    }

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
        '--disable-web-security',
        '--allow-running-insecure-content',

        # TODO socks currently may not work with http:80 requests
        # $self->{proxy} ? qq[--proxy-server="socks5://$self->{_proxy_server}->{listen}->{host_port}"] : (),
        $self->{proxy} ? qq[--proxy-server="$self->{_proxy_server}->{listen}->{host_port}"] : (),

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
        $tab = bless { chrome => $self, id => $tab->{id} }, 'Pcore::API::Chrome::Tab';
    }

    return res 200, $tabs;
}

sub new_tab ( $self, $url = undef ) {
    my $res = P->http->get( "http://$self->{listen}->{host_port}/json/new?" . ( $url // 'about:blank' ) );

    my $data = from_json $res->{data};

    my $tab = bless { chrome => $self, id => $data->{id} }, 'Pcore::API::Chrome::Tab';

    return $tab;
}

sub set_proxy ( $self, $proxy ) {
    $self->{proxy} = Pcore::API::Proxy->new($proxy);

    $self->{_proxy_server}->{proxy} = $self->{proxy};

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 92                   | CodeLayout::ProhibitQuotedWordLists - List of quoted literal words                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 104                  | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Chrome

=head1 SYNOPSIS

    use Pcore::API::Chrome;

    my $chrome = Pcore::API::Chrome->new(
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
