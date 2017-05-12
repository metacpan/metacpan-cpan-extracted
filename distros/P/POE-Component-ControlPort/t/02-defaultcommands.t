
use Test::More tests => 27;

BEGIN {
    use_ok('POE::Component::ControlPort');
    use_ok('POE::Component::ControlPort::Command');
    use_ok('POE::Component::ControlPort::DefaultCommands');
}

use warnings;
use strict;

ok(POE::Component::ControlPort::DefaultCommands->can('status'),
    "'status' existence check");

my $ret;
eval { 
    $ret = POE::Component::ControlPort::DefaultCommands::status(
                oob => {
                    appname => 'APPNAME',
                    hostname => 'HOSTNAME',
                    client_addr => 'CLIENT_ADDR',
                    client_port => 'CLIENT_PORT',
                },
            );
};
is($@,'','status() exception check.');
like($ret, qr/Application APPNAME on host HOSTNAME\nClient is CLIENT_ADDR port CLIENT_PORT/,
        "status() text check");


ok(POE::Component::ControlPort::DefaultCommands->can('help'),
    "'help' existence check");

$ret = undef;
eval { 
    $ret = POE::Component::ControlPort::DefaultCommands::help(
                args => [ 'ARGUMENT' ],
            );
};
is($@,'','help() exception check.');
like($ret, qr/'ARGUMENT' is an unknown/,
        'help() unknown command return');




eval { 
    $ret = POE::Component::ControlPort::DefaultCommands::help(
                args => [ 'ARGUMENT', 'TOO MANY' ],
            );
};
is($@,'','help() exception check.');
like($ret, qr/ERROR: Can only provide help on one thing at a time./,
        'help() unknown command return');



$POE::Component::ControlPort::Command::TOPICS{PIE} = [ 'pants', 'skirts' ];
$ret = undef;
eval {
    $ret = POE::Component::ControlPort::DefaultCommands::help(
                args => [ 'PIE' ],
            );
};
is($@,'','help() exception check');
like($ret, qr/Commands available in topic 'PIE':/, 'help() topic string check');
like($ret, qr/\* pants/, 'help() topic string check');
like($ret, qr/\* skirts/, 'help() topic string check');


delete $POE::Component::ControlPort::Command::TOPICS{PIE};
$ret = undef;
my $command = {
    name => 'pants',
    help_text => 'stupid test command',
    topic => 'PIE',
    usage => 'pants',
    command => sub { return 'test' },
};

eval { POE::Component::ControlPort::Command->register( ( %$command ) ) };
is($@,'','register() exception check');


eval { 
    $ret = POE::Component::ControlPort::DefaultCommands::help(
                args => [ 'pants' ],
            );
};
is($@,'','help() exception check');
like($ret,qr/Help for command 'pants'/, "help() command string check");
like($ret, qr/Usage: pants/, "help() usage string check");



eval "use POE::Component::DebugShell; use POE::API::Peek";

SKIP: {
    skip("Need PoCo::DebugShell and POE::API::Peek", 8) if $@;

    eval {
        POE::Component::ControlPort::DefaultCommands::_add_poe_debug_commands();
    };

    is($@,'','_add_poe_debug_commands() exceptions check');
    ok(defined $POE::Component::ControlPort::Command::TOPICS{poe_debug}, 'poe_debug topic existence check');
    
    foreach my $n (qw(show_sessions list_aliases session_stats queue_dump)) {
        ok(defined $POE::Component::ControlPort::Command::REGISTERED_COMMANDS{ $n }, "$n command existence check");
    }

    $ret = undef;
    eval { 
        $ret = POE::Component::ControlPort::Command->run(
                    command => 'show_sessions',
            );
    };
    is($@, '', 'run() exception check');
    like($ret, qr/Session List:/, 'show_sessions output check');   
}


