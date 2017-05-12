package Net::Signalet::script;
use strict;
use warnings;

use Carp ();
use Getopt::Long qw(:config no_ignore_case pass_through);
use Term::ANSIColor;

use Net::Signalet::Server;
use Net::Signalet::Client;

sub new {
    my $class = shift;

    my $self = bless {
        argv    => [],
        verbose => undef,
        server  => undef,
        client  => undef,
        daddr   => undef,
        saddr   => undef,
        port    => undef,
    }, $class;
    return $self;
}

sub parse_options {
    my $self = shift;

    local @ARGV = @{$self->{argv}};
    push @ARGV, @_;
    Getopt::Long::Configure("bundling");
    Getopt::Long::GetOptions(
        'h|help'      => sub { $self->{action} = 'show_help' },
        'v|verbose'   => sub { $self->{verbose} = 1 },
        's|server'    => sub { $self->{server} = 1 },
        'c|client=s'  => sub { $self->{client} = 1; $self->{daddr} = $_[1] },
        'p|port=i'    => \$self->{port},
        'b|bind=s'    => \$self->{saddr},
        'V|version'   => sub { $self->{action} = 'show_version' },
    );

    $self->{argv} = \@ARGV;
}

sub show_version {
    print "signalet (Net::Signalet) version $Net::Signalet::VERSION\n";
    return 1;
}

sub show_help {
    my $self = shift;

    if ($_[0]) {
        die <<USAGE;
Usage: signalet [options] Target command

Try `signalet --help` for more options.
USAGE
    }

    print <<HELP;
Usage: signalet [options] command

Options:
  -v,--verbose              Turns on detailed output
  -s,--server               Server mode
  -c,--client <ipaddr>      Client mode
  -p,--port n               Set server port to listen on/connect to to n (default 14550)
  -b,--bind                 Bind local address

Commands:
  -V,--version              Displays software version

HELP

    return 1;
}

sub do {
    my $self = shift;

    if (my $action = $self->{action}) {
        $self->$action() and return 1;
    }

    if (!$self->{server} && !$self->{client} or
        $self->{server} && $self->{client})
    {
        $self->show_help(1);
    }

    if ($self->{server}) {
        print "signalet server: running...\n";

        my $server = Net::Signalet::Server->new(
            saddr => $self->{saddr} || '127.0.0.1',
            port  => $self->{sport},
            reuse => 1,
        );
        print "signalet server: connected\n";

        my $msg = $server->recv;
        if ($msg ne "START") {
            Carp::croak "Not START $msg";
        }
        print "signalet server: client started\n";
        $server->send("START_COMP");

        print "signalet server: kick child process\n";

        print color 'yellow';
        $server->run(command => $self->{argv});
        print color 'reset';

        $msg = $server->recv;
        if ($msg ne "FINISH") {
            Carp::croak "Not FINISH: $msg";
        }
        print "signalet server: finish\n";

        $server->term_worker;


        $server->close;
    }
    elsif ($self->{client}) {
        my $client = Net::Signalet::Client->new(
            daddr => $self->{daddr},
            saddr => $self->{saddr},
            port  => $self->{sport},
        );
        print "signalet client: connected\n";

        $client->send("START");
        my $msg = $client->recv;
        if ($msg ne "START_COMP") {
            Carp::croak "Not START_COMP: $msg";
        }
        print "signalet client: server started\n";

        print color 'yellow';
        $client->run(command => $self->{argv});
        print color 'reset';

        $client->send("FINISH");
        print "signalet client: finish\n";

        $client->close;
    }
}

1;
