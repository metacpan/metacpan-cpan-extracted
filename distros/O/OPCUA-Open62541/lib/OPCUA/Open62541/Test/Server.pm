package OPCUA::Open62541::Test::Server;

use strict;
use warnings;
use Net::EmptyPort qw(empty_port);
use OPCUA::Open62541 ':statuscode';
use POSIX qw(sigaction SIGTERM SIGALRM SIGKILL);
use Carp 'croak';

use Test::More;

sub planning {
    # number of ok() and is() calls in this code
    return 8;
}

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};
    $self->{timeout} = $args{timeout} || 10;

    ok($self->{server} = OPCUA::Open62541::Server->new(), "server new");
    ok($self->{config} = $self->{server}->getConfig(), "server get config");

    return bless($self, $class);
}

sub DESTROY {
    local($., $@, $!, $^E, $?);
    my $self = shift;
    if ($self->{pid}) {
	diag "running server destroyed, please call server stop()";
	kill(SIGKILL, $self->{pid});
	waitpid($self->{pid}, 0);
    }
}

sub port {
    my $self = shift;

    return $self->{port};
}

sub start {
    my $self = shift;

    ok($self->{port} = empty_port(), "empty port");
    note("going to configure server");
    is($self->{config}->setMinimal($self->{port}, ""), STATUSCODE_GOOD,
	"set minimal server config port $self->{port}");

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

    # XXX should way until server did bind(2) the port,
    # may grep for 'TCP network layer listening on' in server log
}

sub child {
    my $self = shift;

    my $running = 1;
    my $handler = sub {
	$running = 0;
    };

    # Perl signal handler only works between perl statements.
    # Use the real signal handler to interrupt the OPC UA server.
    # This is not signal safe, best effort is good enough for a test.
    my $sigact = POSIX::SigAction->new($handler)
	or croak "could not create POSIX::SigAction";
    sigaction(SIGTERM, $sigact)
	or croak "sigaction SIGTERM failed: $!";
    sigaction(SIGALRM, $sigact)
	or croak "sigaction SIGALRM failed: $!";
    defined(alarm($self->{timeout}))
	or croak "alarm failed: $!";

    # run server and stop after ten seconds or due to kill
    note("going to startup server");
    $self->{server}->run($running);
}

sub stop {
    my $self = shift;

    note("going to shutdown server");
    ok(kill(SIGTERM, $self->{pid}), "kill server");
    is(waitpid($self->{pid}, 0), $self->{pid}, "waitpid");
    is($?, 0, "server finished");

    delete $self->{pid};
}

1;

__END__

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

=back

=item DESTROY

Will reap the server process if it is still running.
Better call stop() to shutdown the server and check its exit code.

=item $server->port()

Returns the dynamically chosen port number of the server.
Must be called after start().

=item $server->start()

Startup the open62541 server as a background process.
The function will return immediately.

=item $server->stop()

Stop the background server and check its exit code.

=back

=head1 SEE ALSO

OPCUA::Open62541,
OPCUA::Open62541::Test::Client

=head1 AUTHORS

Alexander Bluhm E<lt>bluhm@genua.deE<gt>,

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020 Alexander Bluhm

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.

=cut
