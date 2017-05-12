use Test::Most;
use Mojo::Redis::Processor;
use RedisDB;

throws_ok { Mojo::Redis::Processor->new({invalid => 1,}) } qr/Error, invalid parameters/, 'checking invalid parameters';
lives_ok { Mojo::Redis::Processor->new } 'No data parameter will suggest it is a processor has no minimum requiements';
throws_ok { Mojo::Redis::Processor->new({data => 'DATA'}) } qr/Error, missing parameters: trigger/,
    'setting data will suggest it is a process requestor and needs to set a trigger';
lives_ok { Mojo::Redis::Processor->new(data => 'DATA', trigger => 'TRIGGER') } 'data and trigger together will pass the minimum';
lives_ok {
    Mojo::Redis::Processor->new(
        data        => 'DATA',
        trigger     => 'TRIGGER',
        prefix      => 1,
        expire      => 1,
        usleep      => 1,
        redis_read  => 1,
        redis_write => 1,
        retry       => 1
        )
}
'setting all params still works.';

lives_ok {
    my $rp = Mojo::Redis::Processor->new(redis_write => 'redis://127.0.0.1:6379/0');
    $rp->_write;
}
'setting redis_write to a different value than redis_read and calling it will work.';

RedisDB->new->flushall;

# Websocket part
{
    my $rp = Mojo::Redis::Processor->new({
        data    => 'Data',
        trigger => 'R_25',
    });
    $rp->send();

    is(RedisDB->new->get('Redis::Processor::load::1'),                          '["Data","R_25"]', 'set payload');
    is(RedisDB->new->get('Redis::Processor::job'),                              1,                 'job incremented');
    is(RedisDB->new->ttl('Redis::Processor::34b18bba480282531e815255f2012110'), 60,                'set key expiry');
}

#Daemon part
{
    my $rp   = Mojo::Redis::Processor->new;
    my $next = $rp->next();

    is($next,          1,      'got a job');
    is($rp->{data},    'Data', 'got the data correct');
    is($rp->{trigger}, 'R_25', 'got the trigger correct');
    is($rp->_expired,  undef,  'at first a new job should not be expired');

    RedisDB->new->expire('Redis::Processor::34b18bba480282531e815255f2012110', 0);
    is($rp->_expired, 1, 'no activity for sometime should set the expiry');
}

done_testing();
