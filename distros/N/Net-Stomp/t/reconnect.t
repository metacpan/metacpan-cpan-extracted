#!perl
use lib 't/lib';
use TestHelp;
use Net::Stomp::Frame;
use Log::Any::Adapter::Test;
Log::Any::Adapter->set(
    { lexically => \(my $guard) },
    'Test',
);

my ($s,$fh) = mkstomp_testsocket;

my $get_socket_called;
{no warnings 'redefine';
*Net::Stomp::_get_socket = sub {
    ++$get_socket_called;
    if ($get_socket_called>1) {
        $fh->{connected}=1;
        return $fh;
    }
    else {
        return undef;
    }
}
};
$fh->{to_read} = sub {
    return Net::Stomp::Frame->new({
        command => 'CONNECTED',
        headers => {session=>'foo'},
    })->as_string;
};
my @frames;our $written_inner;
$fh->{written} = sub {
    my ($input)= @_;
    my $frame = Net::Stomp::Frame->parse($input);
    if ($frame) {
        push @frames,$frame;
    }
    else {
        push @frames,$input;
    }
    if ($written_inner) {
        return $written_inner->(@_);
    }
    return length($input);
};

$s->connect({login=>'me'});
$s->subscribe({destination=>'/queue/my'});


my $expected_send_frame = methods(
    command=>'SEND',
    headers=>{destination=>'here'},
    body => 'string',
);
my $expected_connect_frame = methods(
    command=>'CONNECT',
    headers=>{login=>'me'},
);
my $expected_subscribe_frame = methods(
    command=>'SUBSCRIBE',
    headers=>{destination=>'/queue/my'},
);
sub _test_send {
    my (@different_expect) = @_;

    $get_socket_called=0;@frames=();
    $s->send({destination=>'here',body=>'string'});
    is($get_socket_called,2,'reconnected ok');

    cmp_deeply(
        \@frames,
        (@different_expect ? \@different_expect : [
            $expected_connect_frame,
            $expected_subscribe_frame,
            $expected_send_frame,
        ]),
    );
}

sub _test_receive {
    my (@different_expect) = @_;

    $get_socket_called=0;@frames=();
    my $f = $s->receive_frame;
    is($get_socket_called,2,'reconnected ok');

    cmp_deeply(
        \@frames,
        (@different_expect ? \@different_expect : [
            $expected_connect_frame,
            $expected_subscribe_frame,
        ]),
    );
}

subtest 'reconnect on fork' => sub {
    ++$s->{_pid}; # fake a fork
    _test_send;
};

subtest 'not-reconnect on fork' => sub {
    local $s->{reconnect_on_fork}=0;
    local $s->{_pid}=1; # fake a fork
    $get_socket_called=0;
    $s->send({some=>'stuff'});
    is($get_socket_called,0,'reconnect_on_fork can be disabled');
};

subtest 'reconnect on disconnect before send' => sub {
    $fh->{connected}=undef; # fake a disconnect
    _test_send;
};

subtest 'reconnect on disconnect before send (defined but false)' => sub {
    $fh->{connected}=0; # fake a different kind of disconnect
    _test_send;
};

subtest 'reconnect on disconnect while sending' => sub {
    # fake a disconnect after the syswrite, only once
    my $called=0;
    local $written_inner = sub {
        $fh->{connected} = undef unless $called++;
        return length($_[0]);
    };
    _test_send(
        $expected_send_frame,
        $expected_connect_frame,
        $expected_subscribe_frame,
        $expected_send_frame,
    );
};

subtest 'reconnect on write failure' => sub {
    # fake a disconnect after the syswrite, only once
    my $called=0;
    local $written_inner = sub {
        my $ret;
        if ($called) {
            $ret = $called -1;
            if ($ret > length($_[0])) {
                $ret=length($_[0]);
            }
        }
        else {
            $ret = undef;
            $!=1;
        }
        ++$called;
        return $ret;
    };
    _test_send(
        $expected_send_frame,
        $expected_connect_frame,
        $expected_connect_frame,
        methods(command=>'ONNECT'), # partial writes!
        methods(command=>'NECT'),
        methods(command=>'T'),
        "gin:me\n\n\0",
        "e\n\n\0",
        $expected_subscribe_frame,
        methods(command=>'BE'),
        "nation:/queue/my\n\n\0",
        "ueue/my\n\n\0",
        $expected_send_frame,
        "ation:here\n\nstring\0",
        "string\0",
    );
};

subtest 'reconnect on disconnect before receive' => sub {
    $fh->{connected}=undef; # fake a disconnect
    _test_receive;
};

subtest 'report failure if not can_read' => sub {
    my $ret = do {
        local $s->select->{can_read}=0;
        $s->receive_frame;
    };
    ok(!defined($ret),'reported undef');
    ok(defined($fh->{connected}),'socket still open');
    $ret = $s->receive_frame;
    cmp_deeply(
        $ret,
        methods(command=>'CONNECTED'),
        'receive recovered'
    );
};

subtest 'report failure if sysread fails' => sub {
    my $ret = do {
        local $fh->{to_read} = sub {$!=1;return};
        $s->receive_frame;
    };
    ok(!defined($ret),'reported undef');
    ok(!defined($fh->{connected}),'socket closed');
    _test_receive;
};

subtest 'report failure if sysread EOF' => sub {
    my $ret = do {
        local $fh->{to_read} = sub {return ''};
        $s->receive_frame;
    };
    ok(!defined($ret),'reported undef');
    ok(!defined($fh->{connected}),'socket closed');
    _test_receive;
};

subtest 'send_with_receipt report failure if receive_frame does' => sub {
    my $ret = do {
        local $fh->{to_read} = sub {$!=1;return};
        $s->send_with_receipt({some=>'header',body=>'string'});
    };
    ok(!$ret,'reported false');
    ok(!defined($fh->{connected}),'socket closed');
};

done_testing;
