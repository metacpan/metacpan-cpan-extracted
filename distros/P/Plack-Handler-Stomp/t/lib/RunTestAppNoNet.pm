package RunTestAppNoNet;
use Moose::Role;
use Plack::Handler::Stomp::NoNetwork;
use BrokerTestApp;
use Test::More;
use Moose::Util 'apply_all_roles';
use File::Temp 'tempdir';
use Path::Class;
use Net::Stomp::Producer;

has producer => (
    is => 'ro',
    lazy_build => 1,
);

sub _build_producer {
    my ($self) = @_;
    my $stomp = Net::Stomp::Producer->new();
    apply_all_roles($stomp,'Net::Stomp::MooseHelpers::TraceOnly');
    $stomp->trace_basedir($self->trace_dir);

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
    if (!defined $pid) {
        die "Can't start server: $!";
    }
    elsif ($pid == 0) {
        $SIG{TERM}=sub{exit 0};
        my $runner = Plack::Handler::Stomp::NoNetwork->new({
            subscriptions => [
                { destination => '/queue/plack-handler-stomp-test' },
                { destination => '/topic/plack-handler-stomp-test-1',
                  path_info => '/topic/ch1', },
                { destination => '/topic/plack-handler-stomp-test-2',
                  path_info => '/topic/ch2', },
            ],
            trace_basedir => $trace_dir,
            trace => 1,
        });
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
    diag "waitpid for child";
    waitpid($child,0);
};

1;
