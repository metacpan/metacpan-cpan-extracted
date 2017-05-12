
use Test::More tests => 27;

BEGIN {
    use_ok('POE::Component::ControlPort');
    use_ok('POE::Component::ControlPort::Command');
}

# Command registration
ok(POE::Component::ControlPort::Command->can('register'),
   "->can('register')");


eval { POE::Component::ControlPort::Command->register('PIE') };
like($@, qr/Odd number/, 'register() with silly argument');


eval { POE::Component::ControlPort::Command->register('PIE' => 'tasty') };
like($@, qr/not listed in the validation options: PIE/, 
        'register() with several silly arguments');

eval { POE::Component::ControlPort::Command->register(
        help_text => ' ', usage => ' ', topic => ' ', 
        name =>'MONKEY', ); };
like($@, qr/Mandatory parameter 'command' missing/,
        'register() missing "command" argument');


my $command = {
    name => 'test',
    help_text => 'stupid test command',
    topic => 'test',
    usage => 'test',
    command => sub { return 'test' },
};

eval { POE::Component::ControlPort::Command->register( ( %$command ) ) };
is($@,'','exception check: register() with valid args');

ok(defined $POE::Component::ControlPort::Command::TOPICS{'test'}, 
   'topic creation');

ok(defined $POE::Component::ControlPort::Command::REGISTERED_COMMANDS{'test'}, 
   'command creation');

is_deeply($POE::Component::ControlPort::Command::REGISTERED_COMMANDS{'test'},
        $command,
        "command data validation");





# Run
ok(POE::Component::ControlPort::Command->can('run'),
    "'run' existence check");

eval { POE::Component::ControlPort::Command->run('PIE') };
like($@, qr/Odd number/, 'run() with silly argument');


eval { POE::Component::ControlPort::Command->run('PIE' => 'tasty') };
like($@, qr/not listed in the validation options: PIE/, 
        'run() with several silly arguments');

eval { POE::Component::ControlPort::Command->run(
        oob_data => {}, arguments => [], ); };
like($@, qr/Mandatory parameter 'command' missing/,
        'run() missing "command" argument');

my $ret;
eval { $ret = POE::Component::ControlPort::Command->run(
                command => 'PIE'
        );
};
ok(!$@, "run() exception check");
like( $ret, qr/ERROR: 'PIE' is unknown/, 
    "run() with bogus command name");

$ret = undef;
eval { 
    $ret = POE::Component::ControlPort::Command->run(
                command => 'test',
           );
};
ok(!$@, 'run() exception check');
like($ret, qr/^test$/,
     "run() return value check");




$command = {
    name => 'test2',
    help_text => 'stupid test command',
    topic => 'test',
    usage => 'test',
    command => sub { die "PANTS" },
};

eval { POE::Component::ControlPort::Command->register( ( %$command ) ) };
is($@,'','exception check: register() with valid args');

$ret = undef;
eval { 
    $ret = POE::Component::ControlPort::Command->run(
                command => 'test2',
           );
};
ok(!$@, 'run() exception check');
like($ret, qr/^ERROR: PANTS /,
     "run() error detection");





$command = {
    name => 'test3',
    help_text => 'stupid test command',
    topic => 'test',
    usage => 'test',
    command => sub { my %input = @_; return join ":",@{$input{args} } },
};

eval { POE::Component::ControlPort::Command->register( ( %$command ) ) };
is($@,'','exception check: register() with valid args');

$ret = undef;
eval { 
    $ret = POE::Component::ControlPort::Command->run(
                command => 'test3',
                arguments => [ 1, 2, 3 ],
           );
};
ok(!$@, 'run() exception check');
like($ret, qr/^1:2:3$/,
     "run() arguments passing");





$command = {
    name => 'test4',
    help_text => 'stupid test command',
    topic => 'test',
    usage => 'test',
    command => sub { 
        my %input = @_; 
        return join ":",( %{ $input{oob} } );
    },    
};

eval { POE::Component::ControlPort::Command->register( ( %$command ) ) };
is($@,'','exception check: register() with valid args');

$ret = undef;
eval { 
    $ret = POE::Component::ControlPort::Command->run(
                command => 'test4',
                oob_data => { client_addr => '127.0.0.1' },
           );
};
ok(!$@, 'run() exception check');
like($ret, qr/^client_addr:127.0.0.1$/,
     "run() oob data passing");


