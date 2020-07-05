use strict;
use warnings;

package OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Logger;
use OPCUA::Open62541 qw(:ACCESSLEVELMASK :NODEIDTYPE :STATUSCODE :TYPES :VALUERANK);
use Carp 'croak';
use Errno 'EINTR';
use Net::EmptyPort qw(empty_port);
use POSIX qw(SIGTERM SIGALRM SIGKILL SIGUSR1 SIGUSR2 SIG_BLOCK SIG_UNBLOCK);

use Test::More;

sub planning {
    # number of pass(), ok() and is() calls in this code
    return OPCUA::Open62541::Test::Logger::planning() + 15;
}

sub planning_nofork {
    # some test want to avoid fork and to not call run() and stop()
    return OPCUA::Open62541::Test::Logger::planning() + 7;
}

sub new {
    my $class = shift;
    my $self = { @_ };
    $self->{timeout} //= 10;
    $self->{logfile} //= "server.log";

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
    ok($self->{log}->file($self->{logfile}), "server: log file");

    return $self;
}

sub setup_complex_objects {
    my OPCUA::Open62541::Test::Server $self = shift;
    my $namespace = shift // 1;
    my $server = $self->{server};

    # SOME_OBJECT_0
    #    |
    #    | HasTypeDefinition
    #    |
    #    +-> SOME_OBJECT_TYPE
    #        |
    #        | HasComponent
    #        |
    #        +-> SOME_VARIABLE_0
    #            |
    #            | HasTypeDefinition
    #            |
    #            +-> SOME_VARIABLE_TYPE

    my %nodes;
    $nodes{some_variable_type} = {
	nodeId => {
	    NodeId_namespaceIndex	=> $namespace,
	    NodeId_identifierType	=> NODEIDTYPE_STRING,
	    NodeId_identifier		=> "SOME_VARIABLE_TYPE",
	},
	parentNodeId => {
	    NodeId_namespaceIndex	=> 0,
	    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
	    NodeId_identifier		=>
		OPCUA::Open62541::NS0ID_BASEDATAVARIABLETYPE,
	},
	referenceTypeId => {
	    NodeId_namespaceIndex	=> 0,
	    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
	    NodeId_identifier		=> OPCUA::Open62541::NS0ID_HASSUBTYPE,
	},
	browseName => {
	    QualifiedName_namespaceIndex	=> $namespace,
	    QualifiedName_name			=> "SVT",
	},
	typeDefinition => {
	    NodeId_namespaceIndex	=> 0,
	    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
	    NodeId_identifier		=> 0,
	},
	attributes => {
	    VariableTypeAttributes_dataType	=> TYPES_INT32,
	    VariableTypeAttributes_displayName => {
		LocalizedText_text	=> 'Some Variable Type'
	    },
	    VariableTypeAttributes_description => {
		LocalizedText_text	=> 'This defines some variable type'
	    },
	    VariableTypeAttributes_valueRank	=> VALUERANK_SCALAR,
	},
    };
    $nodes{some_object_type} = {
	nodeId => {
	    NodeId_namespaceIndex	=> $namespace,
	    NodeId_identifierType	=> NODEIDTYPE_STRING,
	    NodeId_identifier		=> "SOME_OBJECT_TYPE",
	},
	parentNodeId => {
	    NodeId_namespaceIndex	=> 0,
	    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
	    NodeId_identifier		=>
		OPCUA::Open62541::NS0ID_BASEOBJECTTYPE,
	},
	referenceTypeId => {
	    NodeId_namespaceIndex	=> 0,
	    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
	    NodeId_identifier		=> OPCUA::Open62541::NS0ID_HASSUBTYPE,
	},
	browseName => {
	    QualifiedName_namespaceIndex	=> $namespace,
	    QualifiedName_name			=> "SOT",
	},
	attributes => {
	    ObjectTypeAttributes_displayName => {
		LocalizedText_text	=> 'Some Object Type'
	    },
	    ObjectTypeAttributes_description => {
		LocalizedText_text	=> 'This defines some object type'
	    },
	},
    };
    $nodes{some_variable_0} = {
	nodeId => {
	    NodeId_namespaceIndex	=> $namespace,
	    NodeId_identifierType	=> NODEIDTYPE_STRING,
	    NodeId_identifier		=> "SOME_VARIABLE_0",
	},
	parentNodeId			=> $nodes{some_object_type}{nodeId},
	referenceTypeId => {
	    NodeId_namespaceIndex	=> 0,
	    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
	    NodeId_identifier		=> OPCUA::Open62541::NS0ID_HASCOMPONENT,
	},
	browseName => {
	    QualifiedName_namespaceIndex	=> $namespace,
	    QualifiedName_name			=> "SV0",
	},
	typeDefinition => {
	    NodeId_namespaceIndex	=> $namespace,
	    NodeId_identifierType	=> NODEIDTYPE_STRING,
	    NodeId_identifier		=> "SOME_VARIABLE_TYPE",
	},
	attributes => {
	    VariableAttributes_dataType	=> TYPES_INT32,
	    VariableAttributes_description => {
		LocalizedText_text	=> 'This defines some variable'
	    },
	    VariableAttributes_displayName => {
		LocalizedText_text	=> 'Some Variable 0'
	    },
	    VariableAttributes_value => {
		Variant_type		=> TYPES_INT32,
		Variant_scalar		=> 42,
	    },
	    VariableAttributes_valueRank	=> VALUERANK_SCALAR,
	    VariableAttributes_accessLevel	=>
		ACCESSLEVELMASK_READ | ACCESSLEVELMASK_WRITE,
	},
    };
    $nodes{some_object_0} = {
	nodeId => {
	    NodeId_namespaceIndex	=> $namespace,
	    NodeId_identifierType	=> NODEIDTYPE_STRING,
	    NodeId_identifier		=> "SOME_OBJECT_0",
	},
	parentNodeId => {
	    NodeId_namespaceIndex	=> 0,
	    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
	    NodeId_identifier		=>
		OPCUA::Open62541::NS0ID_OBJECTSFOLDER,
	},
	referenceTypeId => {
	    NodeId_namespaceIndex	=> 0,
	    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
	    NodeId_identifier		=> OPCUA::Open62541::NS0ID_ORGANIZES,
	},
	browseName => {
	    QualifiedName_namespaceIndex	=> $namespace,
	    QualifiedName_name			=> "SO0",
	},
	typeDefinition => {
	    NodeId_namespaceIndex	=> $namespace,
	    NodeId_identifierType	=> NODEIDTYPE_STRING,
	    NodeId_identifier		=> "SOME_OBJECT_TYPE",
	},
	attributes => {
	    ObjectAttributes_description => {
		LocalizedText_text	=> 'This defines some object'
	    },
	    ObjectAttributes_displayName => {
		LocalizedText_text	=> 'Some Object 0'
	    },
	},
    };

    is($server->addVariableTypeNode(
	$nodes{some_variable_type}{nodeId},
	$nodes{some_variable_type}{parentNodeId},
	$nodes{some_variable_type}{referenceTypeId},
	$nodes{some_variable_type}{browseName},
	$nodes{some_variable_type}{typeDefinition},
	$nodes{some_variable_type}{attributes},
	"node context",
	undef
    ), STATUSCODE_GOOD, "add some_variable_type node");

    is($server->addObjectTypeNode(
	$nodes{some_object_type}{nodeId},
	$nodes{some_object_type}{parentNodeId},
	$nodes{some_object_type}{referenceTypeId},
	$nodes{some_object_type}{browseName},
	$nodes{some_object_type}{attributes},
	"node context",
	undef
    ), STATUSCODE_GOOD, "add some_object_type node");

    is($server->addVariableNode(
	$nodes{some_variable_0}{nodeId},
	$nodes{some_variable_0}{parentNodeId},
	$nodes{some_variable_0}{referenceTypeId},
	$nodes{some_variable_0}{browseName},
	$nodes{some_variable_0}{typeDefinition},
	$nodes{some_variable_0}{attributes},
	"node context",
	undef
    ), STATUSCODE_GOOD, "add some_variable_0 node");

    is($server->addObjectNode(
	$nodes{some_object_0}{nodeId},
	$nodes{some_object_0}{parentNodeId},
	$nodes{some_object_0}{referenceTypeId},
	$nodes{some_object_0}{browseName},
	$nodes{some_object_0}{typeDefinition},
	$nodes{some_object_0}{attributes},
	"node context",
	undef
    ), STATUSCODE_GOOD, "add some_object_0 node");

    return %nodes;
}

sub delete_complex_objects {
    my OPCUA::Open62541::Test::Server $self = shift;
    my $server = $self->{server};
    my %nodes = @_;

    foreach my $node (reverse qw(
	some_variable_type some_object_type some_variable_0 some_object_0
    )) {
	next unless $nodes{$node};
	is($server->deleteNode($nodes{$node}{nodeId}, 1),
	    STATUSCODE_GOOD, "delete $node node");
    }
}

sub run {
    my OPCUA::Open62541::Test::Server $self = shift;

    my $sigset = POSIX::SigSet->new(SIGTERM, SIGUSR1, SIGUSR2);
    ok(POSIX::sigprocmask(SIG_BLOCK, $sigset, undef), "server: sigblock")
	or diag "sigprocmask failed: $!";

    $self->{pid} = fork();
    if (defined($self->{pid})) {
	if ($self->{pid} == 0) {
	    $self->child();
	    POSIX::_exit(0);
	}
	pass("fork server");
    } else {
	fail("fork server") or diag "fork failed: $!";
    }

    $sigset = POSIX::SigSet->new(SIGTERM);
    ok(POSIX::sigprocmask(SIG_UNBLOCK, $sigset, undef), "server: sig unblock")
	or diag "sigprocmask failed: $!";

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
    $SIG{ALRM} = sub { note("SIGALRM received"); $running = 0; };
    $SIG{TERM} = sub { note("SIGTERM received"); $running = 0; };
    $SIG{USR1} = sub { note("SIGUSR1 received"); };
    $SIG{USR2} = sub { note("SIGUSR2 received"); };

    my $sigset = POSIX::SigSet->new(SIGTERM);
    POSIX::sigprocmask(SIG_UNBLOCK, $sigset, undef)
	or die "sigprocmask failed: $!";

    my $parent_pid = getppid()
	or die "getppid failed: $!";

    defined(alarm($self->{timeout}))
	or die "alarm failed: $!";

    # run server and stop after ten seconds or due to kill
    note("going to startup server");
    my $status_code;
    $status_code = $self->{server}->run_startup()
	or croak "server run_startup failed: $status_code";
    while ($running) {
	# for signal handling we have to return to Perl regulary
	if ($self->{singlestep}) {
	    $sigset = POSIX::SigSet->new(SIGUSR2);  # do not step on SIGUSR2
	    !POSIX::sigsuspend($sigset) && $!{EINTR}
		or die "sigsuspend failed: $!";
	    $self->{log}->{fh}->print("server: singlestep\n");
	    $self->{log}->{fh}->flush();

	    kill(SIGUSR1, $parent_pid)
		or die "kill parent failed: $!";
	}

	if ($self->{actions}) {
	    $sigset = POSIX::SigSet->new();
	    POSIX::sigpending($sigset)
		or die "sigpending failed: $!";
	    if ($sigset->ismember(SIGUSR2)) {
		$sigset = POSIX::SigSet->new(SIGUSR1);  # do not clear SIGUSR1
		!POSIX::sigsuspend($sigset) && $!{EINTR}
		    or die "sigsuspend failed: $!";

		my $action = shift @{$self->{actions}}
		    or croak "no more actions to execute";
		$action->($self);

		kill(SIGUSR2, $parent_pid)
		    or die "kill parent failed: $!";
	    }
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

    defined(alarm($self->{timeout}))
	or die "alarm failed: $!";

    my $signalled = kill(SIGUSR1, $self->{pid});
    unless ($self->{stepped}) {
	is($signalled, 1, "server: signaled first step")
	    or diag "kill failed: $!";
    }

    local $SIG{USR1} = sub {};
    my $sigset = POSIX::SigSet->new(SIGUSR2);  # not not wait for USR2
    my $received = !POSIX::sigsuspend($sigset) && $!{EINTR};
    unless ($self->{stepped}) {
	ok($received, "server: did first step")
	    or diag "sigsuspend failed: $!";
	$self->{stepped} = 1;
    }

    defined(alarm(0))
	or die "alarm failed: $!";
}

sub next_action {
    my OPCUA::Open62541::Test::Server $self = shift;

    defined(alarm($self->{timeout}))
	or die "alarm failed: $!";

    my $signalled = kill(SIGUSR2, $self->{pid});
    is($signalled, 1, "server: signaled next action");

    local $SIG{USR2} = sub {};
    my $sigset = POSIX::SigSet->new(SIGUSR1);  # not not wait for USR1
    my $received = !POSIX::sigsuspend($sigset) && $!{EINTR};
    ok($received, "server: did next action")
	or diag "sigsuspend failed: $!";

    defined(alarm(0))
	or die "alarm failed: $!";
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

=item OPCUA::Open62541::Test::Server::planning_nofork

Similar to planning, but to used for non-foring tests that do not
call run() and stop().

=back

=head2 METHODS

=over 4

=item $server = OPCUA::Open62541::Test::Server->new(%args);

Create a new test server instance.

=over 8

=item $args{actions}

Array of CODE refs with predefined actions that can be executed during runtime.
The CODE refs will get called with the Server object of the child process as an
argument.

=item $args{logfile}

Logs to the specified file instead of "server.log" in the current
directory.

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

=item %nodes = $server->setup_complex_objects($namespace)

Adds the following nodes in the given namespace to the server:

 some_object_0
 | HasTypeDefinition
 some_object_type
 | HasComponent
 some_variable_0
 | HasTypeDefinition
 some_variable_type

The namespace defaults to 1 if it is not passed as an argument.

Returns the definitions for each node as a hash ref with the above names as hash
keys.
Each definition has the hashes used to add the node (nodeId, parentNodeId,
referenceTypeId, browseName, attributes and the typeDefinition depending on the
node class).

=item $server->delete_complex_objects(%nodes)

Delete the nodes that were added with setup_complex_objects().

=item $server->step()

Will let the server continue and call run_iterate() if started
with singlestep.

=item $server->run()

Startup the open62541 server as a background process.
The function will return immediately.

=item $server->next_action()

Will execute the next predefined action in the server.
The child process with the server will die if no more actions are
defined.

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
