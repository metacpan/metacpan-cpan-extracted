#!perl -w
# --------------------------------------------------------------------
# The aim of this test is to start a syslog server (TCP or UDP) using 
# the one available in POE, make Sys::Syslog connect to it by manually 
# select the corresponding mechanism, send some messages and, inside 
# the POE syslog server, check that these message are correctly crafted. 
# --------------------------------------------------------------------
use strict;

my $port;
BEGIN {
    # override getservbyname()
    *CORE::GLOBAL::getservbyname = sub ($$) {
        my @v = CORE::getservbyname($_[0], $_[1]);

        if (@v) {
            $v[2] = $port;
        } else {
            @v = ($_[0], "", $port, $_[1]);
        }

        return wantarray ? @v : $port
    }
}

use File::Spec;
use Test::More;
use Socket;
use Sys::Syslog qw(:standard :extended :macros);


# check than POE is available
plan skip_all => "POE is not available" unless eval "use POE; 1";

# check than POE::Component::Server::Syslog is available and recent enough
plan skip_all => "POE::Component::Server::Syslog is not available"
    unless eval "use POE::Component::Server::Syslog; 1";
plan skip_all => "POE::Component::Server::Syslog is too old"
    if POE::Component::Server::Syslog->VERSION < 1.14;

plan tests => 1;

   $port    = 5140;
my $proto   = "tcp";

my $ident   = "pocosyslog";
my $text    = "Close the world, txEn eht nepO.";


$SIG{ALRM} = sub {
    ok( 0, "test took too much time to execute" );
    exit
};
alarm 30;

my $pid = fork();

if ($pid) {
    # parent: setup a syslog server
    POE::Component::Server::Syslog->spawn(
        Alias       => 'syslog',
        Type        => $proto, 
        BindAddress => '127.0.0.1',
        BindPort    => $port,
        InputState  => \&client_input,
        ErrorState  => \&client_error,
    );

    $SIG{CHLD} = sub { wait() };
    POE::Kernel->sig_child($pid);

    POE::Kernel->run;
}
else {
    # child: send a message to the syslog server setup in the parent
    sleep 2;
    openlog($ident, "ndelay,pid", "local0");
    setlogsock($proto);
    syslog(info => $text);
    closelog();
    exit
}

sub client_input {
    my $message = $_[&ARG0];
    delete $message->{'time'};  # too hazardous to test

    is_deeply(
        $message,
        {
            host     => scalar gethostbyaddr(inet_aton('127.0.0.1'), AF_INET),
            pri      => &LOG_LOCAL0 + &LOG_INFO,
            facility => &LOG_LOCAL0 >> 3,
            severity => &LOG_INFO,
            msg      => "$ident\[$pid]: $text\n\0",
        },
        "checking syslog message"
    );

    POE::Kernel->post(syslog => "shutdown");
    POE::Kernel->stop;
}

sub client_error {
    my $message = $_[&ARG0];

    require Data::Dumper;
    $Data::Dumper::Indent   = 0;    $Data::Dumper::Indent   = 0;
    $Data::Dumper::Sortkeys = 1;    $Data::Dumper::Sortkeys = 1;
    fail "checking syslog message";
    diag "[client_error] message = ", Data::Dumper::Dumper($message);

    POE::Kernel->post(syslog => "shutdown");
    POE::Kernel->stop;
}

