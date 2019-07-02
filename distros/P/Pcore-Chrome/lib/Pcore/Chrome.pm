package Pcore::Chrome v0.5.0;

use Pcore -dist, -class, -res, -const;
use Pcore::Chrome::Tab;
use Pcore::Util::Scalar qw[is_plain_coderef];
use Pcore::Util::Data qw[from_json];

has bin           => ();
has host          => '127.0.0.1';
has port          => 9222;
has user_data_dir => sub { P->file1->tempdir };
has useragent     => ();

has _proc => ();

# https://chromedevtools.github.io/devtools-protocol/tot/

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

    $self->{host} ||= '127.0.0.1';

    $self->{port} ||= ( P->net->get_free_port( $args{host} ) or die q[Error get free port] );

    my $cmd = [
        qq["$args{bin}"],

        "--remote-debugging-address=$self->{host}",
        "--remote-debugging-port=$self->{port}",

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
        'about:blank',

        # redirect STDERR under linux
        !$MSWIN ? '2>/dev/null' : (),
    ];

    $self->{_proc} = P->sys->run_proc( join( $SPACE, $cmd->@* ), win32_create_no_window => 1 );

    my $time = time + ( $args{timeout} // $CONNECT_TIMEOUT );

    while () {
        Coro::AnyEvent::sleep($CHECK_PORT_TIMEOUT);

        last if P->net->check_port( $self->{host}, $self->{port}, $CHECK_PORT_TIMEOUT );

        die qq[Unable to connect to the goocle chrome on $self->{host}:$self->{port}] if time > $time;
    }

    return $self;
};

sub tabs ( $self ) {
    return P->http->get(
        "http://$self->{host}:$self->{port}/json",
        sub ($res) {
            say dump $res;

            my $tabs = from_json $res->{data};

            for my $tab ( $tabs->@* ) {
                $tab = bless { chrome => $self, id => $tab->{id} }, 'Pcore::Chrome::Tab';
            }

            return res 200, $tabs;
        }
    );
}

sub new_tab ( $self, $url = undef ) {
    return P->http->get(
        "http://$self->{host}:$self->{port}/json/new?" . ( $url // 'about:blank' ),
        sub ($res) {
            my $data = from_json $res->{data};

            my $tab = bless { chrome => $self, id => $data->{id} }, 'Pcore::Chrome::Tab';

            return $tab;
        }
    );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 79                   | CodeLayout::ProhibitQuotedWordLists - List of quoted literal words                                             |
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
