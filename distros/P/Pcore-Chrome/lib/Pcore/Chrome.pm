package Pcore::Chrome v0.2.3;

use Pcore -dist, -const, -class;
use Pcore::Chrome::Tab;
use Pcore::Util::Scalar qw[is_plain_coderef];
use Pcore::Util::Data qw[from_json];
use Pcore::WebSocket;

has host => ( is => 'ro', isa => Str, default => '127.0.0.1' );
has port => ( is => 'ro', isa => Int, default => 9222 );

has user_data_dir => ( is => 'ro', init_arg => undef );
has _proc => ( is => 'ro', isa => InstanceOf ['Pcore::Util:PM::Proc'], init_arg => undef );

const our $DEFAULT_USERAGENT => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.101 Safari/537.36';

# https://chromedevtools.github.io/devtools-protocol/tot/

sub DEMOLISH ( $self, $global ) {

    # term process group
    kill '-TERM', $self->{_proc}->{pid} if $self->{_proc};    ## no critic qw[InputOutput::RequireCheckedSyscalls]

    return;
}

sub run ( $self, @args ) {
    my $rouse_cb = defined wantarray ? Coro::rouse_cb : ();

    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    my %args = @args;

    $args{bin} ||= $MSWIN ? "$ENV{'ProgramFiles(x86)'}/Google/Chrome/Application/chrome.exe" : '/usr/bin/google-chrome';

    $args{host} ||= '127.0.0.1';

    $args{port} ||= ( P->sys->get_free_port( $args{host} ) // die q[Error get free port] );

    my $useragent = !exists $args{useragent} ? $DEFAULT_USERAGENT : $args{useragent};

    $self->{user_data_dir} = $args{user_data_dir} // P->file->tempdir;

    my $cmd = [
        qq["$args{bin}"],

        "--remote-debugging-address=$args{host}",
        "--remote-debugging-port=$args{port}",

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
        defined $useragent ? qq[--user-agent="$useragent"] : (),

        # headless mode
        $args{headless} || !$MSWIN ? ( '--headless', '--disable-gpu' ) : (),

        # user args
        $args{args} ? $args{args}->@* : (),

        # open "about:blank" by default
        'about:blank',

        # redirect STDERR under linux
        !$MSWIN ? '2>/dev/null' : (),
    ];

    P->pm->run_proc(
        join( q[ ], $cmd->@* ),
        win32_create_no_window => 1,
        on_ready               => sub ($proc) {
            $self->{_proc} = $proc;

            $self->{host} = $args{host};
            $self->{port} = $args{port};

            # wait for chrome
            $proc->{timer} = AE::timer $args{timeout} // 3, 0, sub {
                delete $proc->{timer};

                $rouse_cb ? $cb ? $rouse_cb->( $cb->($self) ) : $rouse_cb->($self) : $cb ? $cb->($self) : ();

                return;
            };

            return;
        },
    );

    return $rouse_cb ? Coro::rouse_wait $rouse_cb : ();
}

sub get_tabs ( $self, $cb ) {
    P->http->get(
        "http://$self->{host}:$self->{port}/json",
        on_finish => sub ($res) {
            my $tabs = from_json $res->{body};

            for my $tab ( $tabs->@* ) {
                $tab = bless { chrome => $self, id => $tab->{id} }, 'Pcore::Chrome::Tab';
            }

            $cb->( $self, $tabs );

            return;
        }
    );

    return;
}

sub new_tab ( $self, @args ) {
    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    my $url = $args[0] ? "?$args[0]" : q[?about:blank];

    P->http->get(
        "http://$self->{host}:$self->{port}/json/new$url",
        on_finish => sub ($res) {
            my $data = from_json $res->{body};

            my $tab = bless { chrome => $self, id => $data->{id} }, 'Pcore::Chrome::Tab';

            $cb->( $self, $tab );

            return;
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
## |    2 | 83                   | CodeLayout::ProhibitQuotedWordLists - List of quoted literal words                                             |
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

    my $chrome = Pcore::Chrome->new->run(
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
