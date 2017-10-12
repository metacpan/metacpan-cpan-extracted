package RunTestApp;
use Moose::Role;
use Net::Stomp;
use Alien::ActiveMQ;
use Plack::Handler::Stomp;
use BrokerTestApp;
use Test::More;
use Moose::Util 'apply_all_roles';
use File::Temp 'tempdir';
use Path::Class;

my $mq;

sub check_amq_broker {
    my ($stomp);

    eval {
        $stomp = Net::Stomp->new( { hostname => 'localhost', port => 61613 } );
    };
    if ($@) {

        unless (Alien::ActiveMQ->is_version_installed()) {
            plan 'skip_all' => 'No ActiveMQ server installed by Alien::ActiveMQ, try running the "install-activemq" command';
            exit;
        }

        $mq ||= Alien::ActiveMQ->run_server();

        eval {
            $stomp = Net::Stomp->new( { hostname => 'localhost', port => 61613 } );
        };
        if ($@) {
            plan 'skip_all' => 'No ActiveMQ server listening on 61613: ' . $@;
            exit;
        }
    }

    return $stomp;
}

has server_conn => (
    is => 'ro',
    lazy_build => 1,
);

sub _build_server_conn {
    my ($self) = @_;
    my $stomp = $self->check_amq_broker();

    return $stomp;
}

has child => (
    is => 'ro',
    lazy_build => 1,
);

has trace_dir => (
    is => 'ro',
    lazy_build => 1,
);
sub _build_trace_dir {
    return tempdir(CLEANUP => ( $ENV{TEST_VERBOSE} ? 0 : 1 ));
}

sub _build_child {
    my ($self) = @_;

    my $trace_dir = $self->trace_dir; # make sure we don't get two
                                      # values across the fork
    my $pid = fork();
    if ($pid == 0) {
        $SIG{TERM}=sub{exit 0};
        my $runner = Plack::Handler::Stomp->new({
            servers => [ { hostname => 'localhost', port => 61613 } ],
            subscriptions => [
                { destination => '/queue/plack-handler-stomp-test' },
                { destination => '/topic/plack-handler-stomp-test',
                  headers => {
                      selector => q{custom_header = '1' or JMSType = 'test_foo'},
                  },
                  path_info => '/topic/ch1', },
                { destination => '/topic/plack-handler-stomp-test',
                  headers => {
                      selector => q{custom_header = '2' or JMSType = 'test_bar'},
                  },
                  path_info => '/topic/ch2', },
            ],
        });
        apply_all_roles($runner,'Net::Stomp::MooseHelpers::TraceStomp');
        $runner->trace_basedir($trace_dir);
        $runner->trace(1);
        $runner->trace_types([])
            if $runner->can('trace_types');
        $runner->run(BrokerTestApp->get_app());

        sleep 2;
        exit 0;
    }
    else {
        diag "server started, waiting for spinup...";
        sleep 1 until dir($trace_dir)->children;
        return $pid;
    }
}

sub DEMOLISH {}
after DEMOLISH => sub {
    my ($self) = @_;

    return unless $self->has_child;

    my $child = $self->child;
    kill 'TERM',$child;
    diag "waitpid for child\n";
    waitpid($child,0);
};

has reply_to => ( is => 'rw' );

before 'run_test' => sub {
    my ($self) = @_;

    my $conn = $self->server_conn;

    my $frame = $conn->connect();
    ok($frame, 'connect to MQ server ok');

    my $reply_to = sprintf '%s:1', $frame->headers->{session};
    ok($frame->headers->{session}, 'got a session');
    ok(length $reply_to > 2, 'valid-looking reply_to queue');

    ok($conn->subscribe( {
        destination => '/temp-queue/reply'
    } ),
       'subscribe to temp queue');

    $self->reply_to($reply_to);
};

after 'run_test' => sub {
    my ($self) = @_;

    my $conn = $self->server_conn;

    $conn->disconnect;
    ok(!$conn->socket->connected, 'disconnected');
    $self->reply_to(undef);
};

1;
