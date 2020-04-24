use strict;
use warnings;

package OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::Logger;
use OPCUA::Open62541 qw(STATUSCODE_GOOD STATUSCODE_BADCONNECTIONCLOSED
    :CLIENTSTATE);
use Carp 'croak';
use Time::HiRes qw(sleep);

use Test::More;

sub planning {
    # number of ok() and is() calls in this code
    return OPCUA::Open62541::Test::Logger::planning() + 11;
}

sub new {
    my $class = shift;
    my $self = { @_ };
    $self->{port}
	or croak "no port given";
    $self->{timeout} ||= 10;
    $self->{logfile} //= "client.log";

    ok($self->{client} = OPCUA::Open62541::Client->new(), "client: new");
    ok($self->{config} = $self->{client}->getConfig(), "client: get config");

    return bless($self, $class);
}

sub url {
    my OPCUA::Open62541::Test::Client $self = shift;
    $self->{url} = shift if @_;
    return $self->{url};
}

sub start {
    my OPCUA::Open62541::Test::Client $self = shift;

    is($self->{config}->setDefault(), "Good", "client: set default config");
    $self->{url} = "opc.tcp://localhost";
    $self->{url} .= ":$self->{port}" if $self->{port};

    ok($self->{logger} = $self->{config}->getLogger(), "client: get logger");
    ok($self->{log} = OPCUA::Open62541::Test::Logger->new(
	logger => $self->{logger},
	ident => "OPC UA client",
    ), "client: test logger");
    ok($self->{log}->file($self->{logfile}), "client: log file");

    return $self;
}

sub run {
    my OPCUA::Open62541::Test::Client $self = shift;

    note("going to connect client to url $self->{url}");
    is($self->{client}->connect($self->{url}), STATUSCODE_GOOD,
	"client: connect");
    is($self->{client}->getState(), CLIENTSTATE_SESSION,
	"client: state session");
    # check client did connect(2)
    ok($self->{log}->loggrep(qr/TCP connection established/, 5),
	"client: log grep connected");

    return $self;
}

sub iterate {
    my OPCUA::Open62541::Test::Client $self = shift;

    my ($end, $ident) = @_;
    my $i;
    # loop should not take longer than 5 seconds
    for ($i = 50; $i > 0; $i--) {
	my $sc = $self->{client}->run_iterate(0);
	if (!defined($end) && $sc == STATUSCODE_BADCONNECTIONCLOSED) {
	    # iterate until disconnected
	    pass "client: $ident iterate" if $ident;
	    last;
	}
	if ($sc != STATUSCODE_GOOD) {
	    fail "client: $ident iterate" or diag "run_iterate failed: $sc"
		if $ident;
	    last;
	}
	if (ref($end) eq 'ARRAY' && @$end == 0 or
	    ref($end) eq 'HASH' && keys %$end == 0 or
	    ref($end) eq 'CODE' && $end->() or
	    ref($end) eq 'SCALAR' && $$end) {
	    pass "client: $ident iterate" if $ident;
	    last;
	}
	note "client: $ident iteration $i" if $ident;
	sleep .1;
    }
    if ($i == 0) {
	fail "client: $ident iterate" or diag "loop timeout" if $ident;
    }
}

sub stop {
    my OPCUA::Open62541::Test::Client $self = shift;

    note("going to disconnect client");
    is($self->{client}->disconnect(), STATUSCODE_GOOD, "client: disconnect");
    is($self->{client}->getState, CLIENTSTATE_DISCONNECTED,
	"client: state disconnected");

    return $self;
}

1;

__END__

=pod

=head1 NAME

OPCUA::Open62541::Test::Client - run open62541 client for testing

=head1 SYNOPSIS

  use OPCUA::Open62541::Test::Client;
  use Test::More tests => OPCUA::Open62541::Test::Client::planning();

  my $client = OPCUA::Open62541::Test::Client->new();

=head1 DESCRIPTION

In a module test start and run an open62541 OPC UA client that
connects to a server.
The client is considered part of the test and will write to the TAP
stream.

=over 4

=item OPCUA::Open62541::Test::Client::planning

Return the number of tests results that running one client will
create.
Add this to your number of planned tests.

=back

=head2 METHODS

=over 4

=item $client = OPCUA::Open62541::Test::Client->new(%args);

Create a new test client instance.

=over 8

=item $args{port}

Required port number of the server.

=item $args{logfile}

Logs to the specified file instead of "client.log" in the current
directory.

=item $args{timeout}

Maximum time the client will run during iterate.
Defaults to 10 seconds.

=back

=item $client->url($url)

Optionally set the url.
Returns the url created from localhost and port.
Must be called after start() for that.

=item $client->start()

Configure the client.

=item $client->run()

Connect the client to the open62541 server.

=item $client->iterate(\$end, $ident)

Run the iterate function of the client for up to 5 seconds.
This has to be done to complete asynchronous calls.
The scalar reference to $end is used to finish the iteration loop
successfully when set to true in a callback.
Otherwise the loop terminates with failure if the status of client
run_iterate() is not good or after calling it 50 times.
If $ident is set, it is used to identify a passed or failed test.
This one test is not included in planning().

If $end is undef, the iteration will continue until the client has
disconnected.
If $end is an array or hash reference, the iteration will continue
until the array or hash is empty.
If $end is a code reference, the iteration will continue until the
function call returns true.

=item $client->stop()

Disconnect the client from the open62541 server.

=back

=head1 SEE ALSO

OPCUA::Open62541,
OPCUA::Open62541::Test::Server,
OPCUA::Open62541::Test::Logger

=head1 AUTHORS

Alexander Bluhm E<lt>bluhm@genua.deE<gt>,

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020 Alexander Bluhm

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.

=cut
