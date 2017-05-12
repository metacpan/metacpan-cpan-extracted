#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use FindBin;
use Data::Dumper;
use JSON::XS;
use lib "$FindBin::Bin/../lib";
use POE qw(
    Component::Client::Bayeux
    Component::DebugShell
);

## Collect args

my %opt = (
    host => '',
    port => 80,
    debug => 0,
    autojoin => 0,
);
GetOptions(
    'host=s' => \$opt{host},
    'port=s' => \$opt{port},
    'debug+' => \$opt{debug},
    'noshell+' => \$opt{noshell},
    'autojoin' => \$opt{autojoin},
);

## Create sessions

my $client = POE::Component::Client::Bayeux->spawn(
    Host => $opt{host},
    Port => $opt{port},
    Alias => 'client',
    Debug => $opt{debug},
    ErrorCallback => sub {
        my $message = shift;
        print STDERR "Error: $$message{error}\n";
    },
    ($opt{debug} ? (
        LogStdout => 0,
        LogFile => "/tmp/cli_client.$$.log",
    ) : ()),
);

POE::Session->create(
    inline_states => {
        _start => \&start,
        service => \&service,
        service_response => \&service_response,
        connected => \&connected,
    },
);

## Configure the DebugShell client commands

my $commands = &POE::Component::DebugShell::_raw_commands();
my $active_channel;
my $nick = 'CLI';

$commands->{quit} = {
    help => 'Quit',
    short_help => 'Quit',
    cmd => sub {
        exit;
    },
};

$commands->{publish} = {
    help => "Publish to a channel.  Args: ( \$channel, { ... } )",
    short_help => "Publish to a channel",
    cmd => sub {
        my %param = @_;
        my ($channel, @message) = @{ $param{args} };
        if (! @message) {
            print STDERR "Call with channel and message\n";
            return;
        }

        my $message;
        eval { $message = decode_json(join ' ', @message) };
        if ($@) {
            print STDERR "Failed to decode JSON data from input\n$@";
            return;
        }
        if (! $message) {
            print STDERR "Must pass a message to publish\n";
            return;
        }

        $active_channel = $channel;
        $poe_kernel->post('client', 'publish', $channel, $message);
    },
};

$commands->{say} = {
    help => "Say something in the active channel.  Args: ( something to say )",
    short_help => "Say something",
    cmd => sub {
        my %param = @_;
        my $message = join ' ', @{ $param{args} };

        if (! $active_channel) {
            print STDERR "No active channel!\n";
            return;
        }

        $poe_kernel->post('client', 'publish', $active_channel, {
            name => $nick,
            chat => $message,
        });
    },
};

my $subscribe_callback = sub {
    my ($message) = @_;

    if ($message->{channel} =~ m{^/service/}) {
        print sprintf "[%s] %s %s %s\n", $message->{channel},
            $message->{successful} ? 'successful' : 'unsuccessful',
            $message->{error} ? $message->{error} : '(no error)',
            $message->{data} ? encode_json($message->{data}) : '';
        return;
    }

    my $output = '';
    if (my $data = $message->{data}) {
        if ($data->{chat}) {
            $output = sprintf '%s: %s',
                $data->{name} || 'Anon', $data->{chat};
        }
        elsif ($data->{action}) {
            $output = sprintf '%s %s',
                $data->{name} || 'Anon', $data->{action};
        }
        elsif ($data->{queueMessage}) {
            $output = sprintf 'Queue %s reports "%s"',
                $data->{queueMessage}{queue}, $data->{queueMessage}{message};
        }
        elsif (defined $data->{typing}) {
            $output = sprintf '%s %s typing',
                $data->{name} || 'Anon',
                ($data->{typing} ? "is" : "has stopped");
        }
    }
    print sprintf "[%s] %s\n", $message->{channel}, $output || Dumper($message);
};

$commands->{subscribe} = {
    help => "Subscribe to a channel.  Args: ( \$channel )",
    short_help => "Subscribe to a channel",
    cmd => sub {
        my %param = @_;
        my ($channel) = @{ $param{args} };
        if (! $channel) {
            print STDERR "Call with channel\n";
            return;
        }

        $active_channel = $channel;
        $poe_kernel->post('client', 'subscribe', $channel, $subscribe_callback);
    },
};

$commands->{unsubscribe} = {
    help => "Unsubscribe from a channel.  Args: ( \$channel )",
    short_help => "Unsubscribe from a channel",
    cmd => sub {
        my %param = @_;
        my ($channel) = @{ $param{args} };
        if (! $channel) {
            print STDERR "Call with channel\n";
            return;
        }

        $active_channel = $channel;
        $poe_kernel->post('client', 'unsubscribe', $channel);
    },
};

$commands->{disconnect} = {
    help => "Disconnect from the service",
    short_help => "Disconnect from the service",
    cmd => sub {
        $poe_kernel->post('client', 'disconnect');
    },
};

POE::Component::DebugShell->spawn()
    unless $opt{noshell};

$poe_kernel->run();

## Session states

sub start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $kernel->alias_set('tester');
    $kernel->post('client', 'init');
    $kernel->yield('connected');
}

sub connected {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    if (! $client->clientId) {
        $kernel->yield('connected');
        return;
    }
    print "Connected with client id ".$client->clientId."\n";

    if ($opt{autojoin}) {
        $poe_kernel->post('client', 'subscribe', '/service/*', $subscribe_callback);
        $poe_kernel->post('client', 'subscribe', '/private/' . $client->clientId, $subscribe_callback);
    }
}

sub service {
    my ($kernel, $heap, $service, $args, $callback) = @_[KERNEL, HEAP, ARG0 .. $#_];

    my $channel = "/service/$service";

    # Subscribe so I can register the callback
    $kernel->call('client', 'subscribe', $channel, 'service_response');

    # Publish the request
    my $message_id = $kernel->call('client', 'publish', $channel, $args);

    # Remember the wrapped callback and waiting state
    $heap->{services}{$message_id} = {
        channel => $channel,
        waiting => 1,
        args => $args,
        callback => $callback,
    };
}

sub service_response {
    my ($kernel, $heap, $message) = @_[KERNEL, HEAP, ARG0];

    my $details = $heap->{services}{$message->{id}};
    if (! $details) {
        print STDERR "Received response from unknown message id ".$message->{id}."\n";
        return;
    }

    if ($message->{error}) {
        print STDERR "$$details{channel} yielded error '$$message{error}'\n";
    }

    # Call the original callback function with the message as a parameter
    # If the function returns boolean true, then we are still waiting for it to finish

    my $still_waiting = $details->{callback}($message);
    if (! $still_waiting) {
        $details->{waiting} = 0;
    }
}

1;
