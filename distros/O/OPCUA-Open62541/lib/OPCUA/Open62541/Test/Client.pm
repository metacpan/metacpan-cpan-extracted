use strict;
use warnings;

package OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::Logger;
use OPCUA::Open62541 qw(:STATUSCODE :SESSIONSTATE);
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
    $self->{timeout} ||= 10;
    $self->{logfile} //= "client.log";

    if (not $self->{url}) {
	$self->{host} ||= "localhost";
	$self->{url} = "opc.tcp://$self->{host}";
	$self->{url} .= ":$self->{port}" if $self->{port};
    }

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

    ok($self->{logger} = $self->{config}->getLogger(), "client: get logger");
    ok($self->{log} = OPCUA::Open62541::Test::Logger->new(
	logger => $self->{logger},
	ident => "OPC UA client",
    ), "client: test logger");
    ok($self->{log}->file($self->{logfile}), "client: log file");

    note("going to configure client");

    if ($self->{certificate} and $self->{privateKey}) {
	is(
	    $self->{config}->setDefaultEncryption(
		$self->{certificate}, $self->{privateKey},
		$self->{trustList}, $self->{revocationList},
	    ),
	    "Good",
	    "client: set default encryption config"
	);
    } else {
	is($self->{config}->setDefault(), "Good", "client: set default config");
    }

    return $self;
}

sub run {
    my OPCUA::Open62541::Test::Client $self = shift;

    note("going to connect client to url $self->{url}");
    is($self->{client}->connect($self->{url}), STATUSCODE_GOOD,
	"client: connect");
    my ($channel, $session, $connect) = $self->{client}->getState();
    is($session, SESSIONSTATE_ACTIVATED, "client: state session activated");
    # check client did connect(2)
    ok($self->{log}->loggrep(
	qr/TCP connection established|SessionState: Activated/, 5),
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
	if ($sc != STATUSCODE_GOOD) {
	    note "client: $ident not good: $sc" if $ident;
	}
	my $ec =
	    ref($end) eq 'ARRAY'  ? @$end == 0      :
	    ref($end) eq 'HASH'   ? keys %$end == 0 :
	    ref($end) eq 'CODE'   ? $end->(\$sc)    :
	    ref($end) eq 'SCALAR' ? $$end           :
	    undef;
	if ($sc != STATUSCODE_GOOD) {
	    fail "client: $ident iterate" or diag "run_iterate failed: $sc"
		if $ident;
	    last;
	}
	if ($ec) {
	    pass "client: $ident iterate" if $ident;
	    last;
	}
	note("client: $ident iteration $i") if $ident;
	sleep .1;
    }
    if ($i == 0) {
	fail "client: $ident iterate" or diag "loop timeout" if $ident;
    }
}

sub iterate_connect {
    my OPCUA::Open62541::Test::Client $self = shift;

    my $end = sub {
	my $sc = shift;
	# timeout happens if connection is not instant, try again
	# workaround for bug introduced in open62541 commit
	# ef4394b1144e845df93760b951ef0f6bef63d053
	if ($$sc == STATUSCODE_BADTIMEOUT) {
	    $$sc = STATUSCODE_GOOD;
	    return 0;
	}
	# iterate until session activated, this is bahavior of API 1.1
	my ($channel, $session, $connect) = $self->{client}->getState();
	if ($session == SESSIONSTATE_ACTIVATED) {
	    return 1;
	}
	return 0;
    };
    $self->iterate($end, @_);
}

sub iterate_disconnect {
    my OPCUA::Open62541::Test::Client $self = shift;

    my $end = sub {
	my $sc = shift;
	# iterate until session closed, this is bahavior of API 1.1
	my ($channel, $session, $connect) = $self->{client}->getState();
	if ($session == SESSIONSTATE_CLOSED) {
	    # BadDisconnect does not always happen, only if connect failed
	    if ($$sc == STATUSCODE_BADDISCONNECT) {
		$$sc = STATUSCODE_GOOD;
	    }
	    return 1;
	}
	return 0;
    };
    $self->iterate($end, @_);
}

sub stop {
    my OPCUA::Open62541::Test::Client $self = shift;

    note("going to disconnect client");
    is($self->{client}->disconnect(), STATUSCODE_GOOD, "client: disconnect");
    my ($channel, $session, $connect) = $self->{client}->getState();
    is($session, SESSIONSTATE_CLOSED, "client: state session closing");

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

=item $args{host}

Hostname or IP of the server. Defaults to localhost.

=item $args{port}

Optional port number of the server.

=item $args{url}

URL of the server. Overwrites host and port arguments.

=item $args{certificate}

Certificate in PEM or DER format for signing and encryption.
If the I<certificate> and I<privateKey> parameters are set, the client config
will be configured with the relevant security policies.

By default the client will match any security policy from the server.
Set the security mode with

  $client_config->setSecurityMode(MESSAGESECURITYMODE_SIGNANDENCRYPT).

=item $args{privateKey}

Private key in PEM or DER format that has to match the certificate.

=item $args{trustList}

Array reference with a list of trusted certificates in PEM or DER format.

=item $args{revocationList}

Array reference with a list of certificate revocation lists (CRL) in PEM or DER
format.

=item $args{logfile}

Logs to the specified file instead of "client.log" in the current
directory.

=item $args{timeout}

Maximum time the client will run during iterate.
Defaults to 10 seconds.

=back

=item $client->url($url)

Returns the URL of the server.
Can also set the URL by passing an argument.

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

=item $client->iterate_connect($ident)

Run iterate until connected and session is activated.

=item $client->iterate_disconnect($ident)

Run iterate until session or connection are closed.

=item $client->stop()

Disconnect the client from the open62541 server.

=back

=head1 SEE ALSO

OPCUA::Open62541,
OPCUA::Open62541::Test::Server,
OPCUA::Open62541::Test::Logger

=head1 AUTHORS

Alexander Bluhm E<lt>bluhm@genua.deE<gt>,
Anton Borowka

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020-2023 Alexander Bluhm

Copyright (c) 2020-2023 Anton Borowka

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.

=cut
