#!perl
use lib 't/lib';
use TestHelp;
use Test::Fatal;

{no warnings 'redefine';
 sub Net::Stomp::_get_connection {}
}

subtest 'reconnect on fork' => sub {
    my $s = mkstomp();
    is($s->reconnect_on_fork,1,'defaults to true');
    $s = mkstomp(reconnect_on_fork => 0);
    is($s->reconnect_on_fork,0,'can be turned off');
};

subtest 'hosts' => sub {
    my $s = mkstomp(hosts=>[{foo=>'bar'}]);
    cmp_deeply($s->hosts,[{foo=>'bar'}],'one host ok');

    $s = mkstomp(hosts=>[{foo=>'bar'},{one=>'two'}]);
    cmp_deeply($s->hosts,[{foo=>'bar'},{one=>'two'}],'two hosts ok');
};

subtest 'failover' => sub {
    my %cases = (
        'failover:tcp://one:1234' => [
            {hostname=>'one',port=>1234},
        ],
        'failover:(tcp://one:1234)?opts' => [
            {hostname=>'one',port=>1234},
        ],
        'failover:tcp://one:1234,tcp://two:3456' => [
            {hostname=>'one',port=>1234},
            {hostname=>'two',port=>3456},
        ],
        'failover:(tcp://one:1234,tcp://two:3456)?opts' => [
            {hostname=>'one',port=>1234},
            {hostname=>'two',port=>3456},
        ],
    );

    for my $case (sort keys %cases) {
        my $s = mkstomp(
            failover=>$case,
        );
        cmp_deeply($s->hosts,$cases{$case},"$case parsed ok");
    }
};

subtest 'bad failover' => sub {
    like(
        exception { mkstomp(failover=>'bad') },
        qr{Unable to parse failover uri}i,
        'bad uri correct exception',
    );
    like(
        exception { mkstomp(failover=>'failover://(a,b)') },
        qr{Unable to parse failover component}i,
        'bad component correct exception',
    );

};

done_testing;
