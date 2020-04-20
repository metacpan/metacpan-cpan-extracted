use strict;
use warnings;

package OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Logger;
use OPCUA::Open62541 'STATUSCODE_GOOD';
use Carp 'croak';
use Errno 'EINTR';
use Net::EmptyPort qw(empty_port);
use POSIX qw(SIGTERM SIGALRM SIGKILL SIGUSR1 SIG_BLOCK);

use Test::More;

sub planning {
    # number of ok() and is() calls in this code
    return OPCUA::Open62541::Test::Logger::planning() + 14;
}

sub new {
    my $class = shift;
    my $self = { @_ };
    $self->{timeout} //= 10;

    ok($self->{server} = OPCUA::Open62541::Server->new(), "server: new");
    ok($self->{config} = $self->{server}->getConfig(), "server: get config");

    return bless($self, $class);
}

sub DESTROY {
    local($., $@, $!, $^E, $?);
    my OPCUA::Open62541::Test::Server $self = shift;
    if ($self->{pid}) {
	diag "running server destroyed, please call server stop()";
	kill(SIGKILL, $self->{pid});
	waitpid($self->{pid}, 0);
    }
}

sub port {
    my OPCUA::Open62541::Test::Server $self = shift;
    $self->{port} = shift if @_;
    return $self->{port};
}

sub start {
    my OPCUA::Open62541::Test::Server $self = shift;

    ok($self->{port} ||= empty_port(), "server: empty port");
    note("going to configure server on port $self->{port}");
    is($self->{config}->setMinimal($self->{port}, ""), STATUSCODE_GOOD,
	"server: set minimal config");

    ok($self->{logger} = $self->{config}->getLogger(), "server: get logger");
    ok($self->{log} = OPCUA::Open62541::Test::Logger->new(
	logger => $self->{logger},
	ident => "OPC UA server",
    ), "server: test logger");
    ok($self->{log}->file("server.log"), "server: log file");

    return $self;
}

sub run {
    my OPCUA::Open62541::Test::Server $self = shift;

    my $sigset = POSIX::SigSet->new(SIGUSR1);
    ok(POSIX::sigprocmask(SIG_BLOCK, $sigset, undef), "server: sigprocmask");

    $self->{pid} = fork();
    if (defined($self->{pid})) {
	if ($self->{pid} == 0) {
	    $self->child();
	    POSIX::_exit(0);
	}
	pass("fork server");
    } else {
	fail("fork server") or diag "Fork failed: $!";
    }

    ok($self->{log}->pid($self->{pid}), "server: log set pid");

    # wait until server did bind(2) the port
    ok($self->{log}->loggrep(qr/TCP network layer listening on /, 10),
	"server: log grep listening");
    return $self;
}

sub child {
    my OPCUA::Open62541::Test::Server $self = shift;

    local %SIG;
    my $running = 1;
    $SIG{ALRM} = $SIG{TERM} = sub { $running = 0; };
    $SIG{USR1} = sub { note("SIGUSR1 received"); };

    defined(alarm($self->{timeout}))
	or croak "alarm failed: $!";

    # run server and stop after ten seconds or due to kill
    note("going to startup server");
    my $status_code;
    $status_code = $self->{server}->run_startup()
	or croak "server run_startup failed: $status_code";
    while ($running) {
	# for signal handling we have to return to Perl regulary
	if ($self->{singlestep}) {
	    my $sigset= POSIX::SigSet->new();
	    !POSIX::sigsuspend($sigset) && $!{EINTR}
		or croak("sigsuspend failed: $!");
	    $self->{log}->{fh}->print("server: singlestep\n");
	    $self->{log}->{fh}->flush();
	}
	$self->{server}->run_iterate(1);
    }
    $self->{server}->run_shutdown()
	or croak "server run_shutdown failed: $status_code";
}

sub stop {
    my OPCUA::Open62541::Test::Server $self = shift;

    note("going to shutdown server");
    ok(kill(SIGTERM, $self->{pid}), "server: kill server");
    is(waitpid($self->{pid}, 0), $self->{pid}, "server: waitpid");
    is($?, 0, "server: finished");
    delete $self->{pid};
    return $self;
}

sub step {
    my OPCUA::Open62541::Test::Server $self = shift;

    my $signalled = kill(SIGUSR1, $self->{pid});
    unless ($self->{stepped}) {
	is($signalled, 1, "server: first step");
	$self->{stepped} = 1;
    }
}

1;

__END__

=pod

=head1 NAME

OPCUA::Open62541::Test::Server - run open62541 server for testing

=head1 SYNOPSIS

  use OPCUA::Open62541::Test::Server;
  use Test::More tests => OPCUA::Open62541::Test::Server::planning();

  my $server = OPCUA::Open62541::Test::Server->new();

=head1 DESCRIPTION

In a module test start and run an open62541 OPC UA server in the
background that can be connected by a client.
The server is considered part of the test and will write to the TAP
stream.

=over 4

=item OPCUA::Open62541::Test::Server::planning

Return the number of tests results that running one server will
create.
Add this to your number of planned tests.

=back

=head2 METHODS

=over 4

=item $server = OPCUA::Open62541::Test::Server->new(%args);

Create a new test server instance.

=over 8

=item $args{timeout}

Maximum time the server will run before shutting down itself.
Defaults to 10 seconds.
Can be turned off with 0, but this should not be used in automatic
tests to avoid dangling processes.

=item $args{singlestep}

If set, we pause before calling run_iterate().
To iterate, the test has to call step() to signal the server to continue.

=back

=item DESTROY

Will reap the server process if it is still running.
Better call stop() to shutdown the server and check its exit code.

=item $server->port($port)

Optionally set the port number.
If port is not given, returns the dynamically chosen port number
of the server.
Must be called after start() for that.

=item $server->start()

Configure the server.

=item $server->step()

Will let the server continue and call run_iterate() if started
with singlestep.

=item $server->run()

Startup the open62541 server as a background process.
The function will return immediately.

=item $server->stop()

Stop the background server and check its exit code.

=back

=head1 SEE ALSO

OPCUA::Open62541,
OPCUA::Open62541::Test::Client,
OPCUA::Open62541::Test::Logger

=head1 AUTHORS

Alexander Bluhm E<lt>bluhm@genua.deE<gt>,

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020 Alexander Bluhm

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.

=cut
