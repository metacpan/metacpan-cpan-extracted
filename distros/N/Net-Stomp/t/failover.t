#!perl
use lib 't/lib';
use TestHelp;
use Test::Fatal;
use Log::Any::Adapter::Test;

subtest 'default reconnect attempts' => sub {
    Log::Any::Adapter->set(
        { lexically => \(my $guard) },
        'Test',
    );
    Log::Any::Adapter::Test->clear;

    my ($s,$fh) = mkstomp_testsocket(
        hosts => [
            {hostname=>'one',port=>1},
            {hostname=>'two',port=>2},
            {hostname=>'three',port=>3},
        ],
    );

    my @connected_hosts;
    {no warnings 'redefine';
     *Net::Stomp::_get_socket = sub {
         my ($self) = @_;
         push @connected_hosts,$self->current_host;
         if (@connected_hosts>4) {
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

    $fh->{connected}=undef; # fake a disconnect
    $s->send({destination=>'here',body=>'string'});
    cmp_deeply(
        \@connected_hosts,
        [1,2,0,1,2],
        'tried all hosts, round-robin, re-starting',
    );

    cmp_deeply(
        Log::Any::Adapter::Test->msgs,
        [
            superhashof({ message => re(qr{sending}) }),
            superhashof({ message => re(qr{closing}) }),
            superhashof({ message => re(qr{reconnecting}) }),
            superhashof({ message => re(qr{error connecting to two}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
            superhashof({ message => re(qr{error connecting to three}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
            superhashof({ message => re(qr{error connecting to one}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
            superhashof({ message => re(qr{error connecting to two}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
            superhashof({ message => re(qr{connecting}i) }),
            superhashof({ message => re(qr{waiting}i) }),
            superhashof({ message => re(qr{connected}i) }),
        ],
        'reconnecting should be logged',
    );
};

subtest 'limited reconnect attempts' => sub {
    Log::Any::Adapter->set(
        { lexically => \(my $guard) },
        'Test',
    );
    Log::Any::Adapter::Test->clear;

    my ($s,$fh) = mkstomp_testsocket(
        hosts => [
            {hostname=>'one',port=>1},
            {hostname=>'two',port=>2},
            {hostname=>'three',port=>3},
        ],
        reconnect_attempts => 2,
    );

    my @connected_hosts;
    {no warnings 'redefine';
     *Net::Stomp::_get_socket = sub {
         my ($self) = @_;
         push @connected_hosts,$self->current_host;
         return undef;
     }
    };
    $fh->{to_read} = sub {
        return Net::Stomp::Frame->new({
            command => 'CONNECTED',
            headers => {session=>'foo'},
        })->as_string;
    };

    $fh->{connected}=undef; # fake a disconnect
    my $e = exception { $s->send({destination=>'here',body=>'string'}) };
    ok(defined $e,'died ok');
    like($e,qr{giving up},'correct exception');
    cmp_deeply(
        \@connected_hosts,
        [1,2,0,1,2,0],
        'tried all hosts, round-robin, re-starting, then stopped',
    );

    cmp_deeply(
        Log::Any::Adapter::Test->msgs,
        [
            superhashof({ message => re(qr{sending}) }),
            superhashof({ message => re(qr{closing}) }),
            superhashof({ message => re(qr{reconnecting}) }),
            superhashof({ message => re(qr{error connecting to two}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
            superhashof({ message => re(qr{error connecting to three}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
            superhashof({ message => re(qr{error connecting to one}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
            superhashof({ message => re(qr{error connecting to two}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
            superhashof({ message => re(qr{error connecting to three}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
            superhashof({ message => re(qr{error connecting to one}i) }),
            superhashof({ message => re(qr{failed to connect}i) }),
        ],
        'reconnecting should be logged',
    );
};


done_testing;
