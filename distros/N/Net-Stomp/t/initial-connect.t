#!perl
use lib 't/lib';
use TestHelp;
use Test::Fatal;
use Log::Any::Adapter::Test;

our @sockets;
{no warnings 'redefine';
 sub Net::Stomp::_get_socket {
     my $ret = shift @sockets;
     $!=1 unless $ret;
     return $ret;
 }
}

subtest 'simplest case' => sub {
    local @sockets=(\*STDIN);
    my $s = mkstomp();
    cmp_deeply(
        $s,
        methods(
            hostname => 'localhost',
            port => 61613,
            current_host => 0,
            socket => \*STDIN,
            select => noclass(superhashof({socket=>\*STDIN})),
        ),
        'correct',
    );
};

subtest 'simplest case, old style' => sub {
    local @sockets=(\*STDIN);
    my $s = mkstomp(hosts=>undef,hostname=>'localhost',port=>61613,);
    cmp_deeply(
        $s,
        methods(
            hostname => 'localhost',
            port => 61613,
            current_host => undef,
            socket => \*STDIN,
            select => noclass(superhashof({socket=>\*STDIN})),
        ),
        'correct',
    );
};

subtest 'two host, first one' => sub {
    local @sockets=(\*STDIN);
    my $s = mkstomp(hosts=>[{hostname=>'one',port=>1234},{hostname=>'two',port=>3456,ssl=>1}]);
    cmp_deeply(
        $s,
        methods(
            hostname => 'one',
            port => 1234,
            ssl => bool(0),
            current_host => 0,
            socket => \*STDIN,
        ),
        'correct',
    );
};

subtest 'two host, second one' => sub {
    Log::Any::Adapter->set(
        { lexically => \(my $guard) },
        'Test',
    );
    Log::Any::Adapter::Test->clear;

    local @sockets=(undef,\*STDIN);
    my $s = mkstomp(hosts=>[{hostname=>'one',port=>1234},{hostname=>'two',port=>3456,ssl=>1,ssl_options=>{a=>'b'}}]);
    cmp_deeply(
        $s,
        methods(
            hostname => 'two',
            port => 3456,
            ssl => 1,
            ssl_options => {a=>'b'},
            current_host => 1,
            socket => \*STDIN,
        ),
        'correct',
    );

    cmp_deeply(
        Log::Any::Adapter::Test->msgs,
        [
            superhashof({ message => re(qr{error connecting}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
        ],
        'failure should be logged',
    );
};

subtest 'two host, second one, SSL on first' => sub {
    Log::Any::Adapter->set(
        { lexically => \(my $guard) },
        'Test',
    );
    Log::Any::Adapter::Test->clear;

    local @sockets=(undef,\*STDIN);
    my $s = mkstomp(hosts=>[{hostname=>'one',port=>1234,ssl=>1,ssl_options=>{a=>'b'}},{hostname=>'two',port=>3456}]);
    cmp_deeply(
        $s,
        methods(
            hostname => 'two',
            port => 3456,
            ssl => bool(0),,
            ssl_options => {},
            current_host => 1,
            socket => \*STDIN,
        ),
        'correct',
    );

    cmp_deeply(
        Log::Any::Adapter::Test->msgs,
        [
            superhashof({ message => re(qr{error connecting}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
        ],
        'failure should be logged',
    );
};

subtest 'two host, none' => sub {
    Log::Any::Adapter->set(
        { lexically => \(my $guard) },
        'Test',
    );
    Log::Any::Adapter::Test->clear;

    local @sockets=(undef,undef);
    my $s;
    my $err = exception { $s=mkstomp(hosts=>[{hostname=>'one',port=>1234},{hostname=>'two',port=>3456}]) };
    cmp_deeply($s,undef,'expected failure');
    cmp_deeply($err,re(qr{Error connecting.*giving up}),'expected exception');
    ok(@sockets==0,'two attempts');

    cmp_deeply(
        Log::Any::Adapter::Test->msgs,
        [(
            superhashof({ message => re(qr{error connecting}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
        ) x 2],
        'failure should be logged',
    );
};

subtest 'two host, none, keep trying' => sub {
    Log::Any::Adapter->set(
        { lexically => \(my $guard) },
        'Test',
    );
    Log::Any::Adapter::Test->clear;

    local @sockets=(undef,undef,undef,undef,undef,undef);
    my $s;
    my $err = exception { $s=mkstomp(
        hosts=>[{hostname=>'one',port=>1234},{hostname=>'two',port=>3456}],
        initial_reconnect_attempts => 2,
    ) };
    cmp_deeply($s,undef,'expected failure');
    cmp_deeply($err,re(qr{Error connecting}),'expected exception');
    ok(@sockets==2,'four attempts');

    cmp_deeply(
        Log::Any::Adapter::Test->msgs,
        [(
            superhashof({ message => re(qr{error connecting}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
        ) x 4],
        'failure should be logged',
    );
};

subtest 'old style, failure' => sub {
    Log::Any::Adapter->set(
        { lexically => \(my $guard) },
        'Test',
    );
    Log::Any::Adapter::Test->clear;

    local @sockets=(undef);
    my $s;
    my $err = exception { $s=mkstomp(hosts=>undef,hostname=>'localhost',port=>61613,) };
    cmp_deeply($s,undef,'expected failure');
    cmp_deeply($err,re(qr{Error connecting}),'expected exception');
    cmp_deeply(
        Log::Any::Adapter::Test->msgs,
        [
            superhashof({ message => re(qr{error connecting}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
        ],
        'failure should be logged',
    );
};

subtest 'old style, failure, keep trying' => sub {
    Log::Any::Adapter->set(
        { lexically => \(my $guard) },
        'Test',
    );
    Log::Any::Adapter::Test->clear;

    local @sockets=(undef,undef,undef);
    my $s;
    my $err = exception { $s=mkstomp(
        hosts=>undef,hostname=>'localhost',port=>61613,
        initial_reconnect_attempts => 2,
    ) };
    cmp_deeply($s,undef,'expected failure');
    cmp_deeply($err,re(qr{Error connecting}),'expected exception');
    ok(@sockets==1,'two attempts');
    cmp_deeply(
        Log::Any::Adapter::Test->msgs,
        [(
            superhashof({ message => re(qr{error connecting}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
        ) x 2],
        'failure should be logged',
    );
};

done_testing;
