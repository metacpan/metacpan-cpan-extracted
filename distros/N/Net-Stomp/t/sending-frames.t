use lib 't/lib';
use TestHelp;

my @frames;
{no warnings 'redefine';
 sub Net::Stomp::send_frame {push @frames,$_[1];return;}
}

my ($s,$fh)=mkstomp_testsocket();

sub _testit {
    my ($method,$arg,@tests) = @_;
    @frames=();
    my $ret = $s->$method($arg);
    ok($ret,"$method returned true");
    cmp_deeply(
        \@frames,
        [all(
            isa('Net::Stomp::Frame'),
            methods(@tests),
        )],
        "$method sent ok",
    );
}

subtest 'send and ack' => sub {
    _testit(
        send => {'message-id'=>12,body=>'string'},
        command=>'SEND',
        headers=>{'message-id'=>12},
        body=>'string',
    );
    my $message = $frames[0];
    _testit(
        ack => {frame=>$message},
        command=>'ACK',
        headers=>{'message-id'=>12},
        body=>undef,
    );
    _testit(
        ack => {frame=>$message,receipt=>'foo'},
        command=>'ACK',
        headers=>{'message-id'=>12,receipt=>'foo'},
        body=>undef,
    );
};

subtest 'send and nack' => sub {
    _testit(
        send => {'message-id'=>12,body=>'string'},
        command=>'SEND',
        headers=>{'message-id'=>12},
        body=>'string',
    );
    my $message = $frames[0];
    _testit(
        nack => {frame=>$message},
        command=>'NACK',
        headers=>{'message-id'=>12},
        body=>undef,
    );
    _testit(
        nack => {frame=>$message,receipt=>'foo'},
        command=>'NACK',
        headers=>{'message-id'=>12,receipt=>'foo'},
        body=>undef,
    );
};

subtest '(un)subscribe by id' => sub {
    _testit(
        subscribe => {id=>1,destination=>'/queue/foo'},
        command=>'SUBSCRIBE',
        headers=>{id=>1,destination=>'/queue/foo'},
        body => undef,
    );
    cmp_deeply(
        $s->subscriptions,
        {'id-1'=>{id=>1,destination=>'/queue/foo'}},
        'recorded ok',
    );
    _testit(
        unsubscribe => {id=>1,destination=>'/queue/foo'},
        command=>'UNSUBSCRIBE',
        headers=>{id=>1,destination=>'/queue/foo'},
        body => undef,
    );
    cmp_deeply(
        $s->subscriptions,
        {},
        'recorded ok',
    );
};

subtest 'subscribe without id' => sub {
    _testit(
        subscribe => {destination=>'/queue/foo'},
        command=>'SUBSCRIBE',
        headers=>{destination=>'/queue/foo'},
        body => undef,
    );
    cmp_deeply(
        $s->subscriptions,
        {'dest-/queue/foo'=>{destination=>'/queue/foo'}},
        'recorded ok',
    );
    _testit(
        unsubscribe => {destination=>'/queue/foo'},
        command=>'UNSUBSCRIBE',
        headers=>{destination=>'/queue/foo'},
        body => undef,
    );
    cmp_deeply(
        $s->subscriptions,
        {},
        'recorded ok',
    );
};

done_testing;
