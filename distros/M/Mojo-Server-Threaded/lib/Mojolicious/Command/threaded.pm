package Mojolicious::Command::threaded;
use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Server::Threaded;

our $VERSION = $Mojo::Server::Threaded::VERSION;

has description =>
  'Start application with threaded HTTP and WebSocket server';
has usage => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

  my $threaded = Mojo::Server::Threaded->new(app => $self->app);
  GetOptionsFromArray \@args,
    'a|accepts=i'            => sub { $threaded->accepts($_[1]) },
    'b|backlog=i'            => sub { $threaded->backlog($_[1]) },
    'c|clients=i'            => sub { $threaded->max_clients($_[1]) },
    'C|command=s'            => \my $command,
    'G|graceful-timeout=i'   => sub { $threaded->graceful_timeout($_[1]) },
    'I|heartbeat-interval=i' => sub { $threaded->heartbeat_interval($_[1]) },
    'H|heartbeat-timeout=i'  => sub { $threaded->heartbeat_timeout($_[1]) },
    'i|inactivity-timeout=i' => sub { $threaded->inactivity_timeout($_[1]) },
    'l|listen=s'   => \my @listen,
    'M|manage-interval'      => sub { $threaded->manage_interval($_[1]) },
    'P|pid-file=s' => sub { $threaded->pid_file($_[1]) },
    'p|proxy'      => sub { $threaded->reverse_proxy(1) },
    'r|requests=i' => sub { $threaded->max_requests($_[1]) },
    'w|workers=i'  => sub { $threaded->workers($_[1]) };

  $threaded->send_command($command) && return if $command;
  $threaded->listen(\@listen) if @listen;
  $threaded->run unless $command;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::threaded - threaded command

=head1 SYNOPSIS

  Usage: APPLICATION threaded [OPTIONS]

    ./myapp.pl threaded
    ./myapp.pl threaded -m production -l http://*:8080
    ./myapp.pl threaded -l http://127.0.0.1:8080 -l https://[::]:8081
    ./myapp.pl threaded -l 'https://*:443?cert=./server.crt&key=./server.key'

  Options:
    -a, --accepts <number>               Number of connections for workers to
                                         accept, defaults to 10000
    -b, --backlog <size>                 Listen backlog size, defaults to
                                         SOMAXCONN
    -C, --command "<command>"            Send command to running server
    -c, --clients <number>               Maximum number of concurrent
                                         connections, defaults to 1000
    -G, --graceful-timeout <seconds>     Graceful timeout, defaults to 20.
    -I, --heartbeat-interval <seconds>   Heartbeat interval, defaults to 5
    -H, --heartbeat-timeout <seconds>    Heartbeat timeout, defaults to 20
    -h, --help                           Show this summary of available options
        --home <path>                    Path to home directory of your
                                         application, defaults to the value of
                                         MOJO_HOME or auto-detection
    -i, --inactivity-timeout <seconds>   Inactivity timeout, defaults to the
                                         value of MOJO_INACTIVITY_TIMEOUT or 15
    -l, --listen <location>              One or more locations you want to
                                         listen on, defaults to the value of
                                         MOJO_LISTEN or "http://*:3000"
    -M  --manage-interval                Chack interval for the management port,
                                         defaults to 0.1
    -m, --mode <name>                    Operating mode for your application,
                                         defaults to the value of
                                         MOJO_MODE/PLACK_ENV or "development"
    -P, --pid-file <path>                Path to process id file, defaults to
                                         "threaded.pid" in a temporary diretory
    -p, --proxy                          Activate reverse proxy support,
                                         defaults to the value of
                                         MOJO_REVERSE_PROXY
    -r, --requests <number>              Maximum number of requests per
                                         keep-alive connection, defaults to 100
    -w, --workers <number>               Number of workers, defaults to 4

=head1 DESCRIPTION

L<Mojolicious::Command::threaded> starts applications with the
L<Mojo::Server::Threaded> backend.

See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are
available by default.

=head1 ATTRIBUTES

L<Mojolicious::Command::threaded> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $threaded->description;
  $threaded        = $threaded->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $threaded->usage;
  $threaded  = $threaded->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::threaded> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $threaded->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut