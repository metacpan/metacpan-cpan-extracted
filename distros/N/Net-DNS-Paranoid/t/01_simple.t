use strict;
use warnings;
use utf8;
use Test::More;
use lib 'lib';
use Net::DNS::Paranoid;
use t::MockResolver;

my $resolver = do {
    my $mock_resolver = t::MockResolver->new;

    # Record pointing to localhost:
    {
        my $packet = Net::DNS::Packet->new;
        $packet->push(answer => Net::DNS::RR->new("localhost-fortest.danga.com. 86400 A 127.0.0.1"));
        $mock_resolver->set_fake_record("localhost-fortest.danga.com", $packet);
    }

    # CNAME to blocked destination:
    {
        my $packet = Net::DNS::Packet->new;
        $packet->push(answer => Net::DNS::RR->new("bradlj-fortest.danga.com 300 IN CNAME brad.lj"));
        $mock_resolver->set_fake_record("bradlj-fortest.danga.com", $packet);
    }

    $mock_resolver;
};

my $dns = Net::DNS::Paranoid->new(resolver => $resolver);
$dns->blocked_hosts( [ qr/\.lj$/, "1.2.3.6", ] );

subtest 'hostnames pointing to internal IPs' => sub {
    is_deeply( [ $dns->resolve('localhost-fortest.danga.com') ],
        [ undef, 'Suspicious DNS results from A record' ] );
};

subtest 'random IP address forms' => sub {
    for (qw/0x7f.1 0x7f.0xffffff 037777777777 192.052000001 0x00.00/) {
        is_deeply( [ $dns->resolve($_) ],
            [ undef, 'DNS lookup resulted in bad host.' ] );
    }
};

subtest 'test the the blocked host above in decimal form is blocked by this non-decimal form' => sub {
    is_deeply( [ $dns->resolve('0x01.02.0x306') ],
        [ undef, 'DNS lookup resulted in bad host.' ] );
};

subtest 'more blocked spaces' => sub {
    for (qw/192.0.2.13 192.88.99.77/) {
        is_deeply( [ $dns->resolve($_) ],
            [ undef, 'DNS lookup resulted in bad host.' ] );
    }
};

subtest 'hostnames doing CNAMEs (this one resolves to "brad.lj", which is verboten)' => sub {
    is_deeply( [ $dns->resolve('bradlj-fortest.danga.com') ],
        [ undef, 'DNS lookup resulted in bad host.' ] );
};

subtest "can't do empty host name" => sub {
    is_deeply( [ $dns->resolve('') ],
        [ undef, 'DNS lookup resulted in bad host.' ] );
};

subtest "black-listed via blocked_hosts" => sub {
    is_deeply( [ $dns->resolve('brad.lj') ],
        [ undef, 'DNS lookup resulted in bad host.' ] );
};

subtest "can't do octal in IPs" => sub {
    is_deeply( [ $dns->resolve('012.1.2.1') ],
        [ undef, 'DNS lookup resulted in bad host.' ] );
};

subtest "can't do decimal/octal IPs" => sub {
    is_deeply( [ $dns->resolve('167838209') ],
        [ undef, 'DNS lookup resulted in bad host.' ] );
};

subtest "this domain is okay.  50.112.116.235.xip.io isn't blocked" => sub {
    is_deeply( [ $dns->resolve('50.112.116.235.xip.io') ],
        [ ['50.112.116.235'], undef ] );
};

subtest 'internal. bad.  blocked by default by module.' => sub {
    is_deeply( [ $dns->resolve('10.2.3.4') ],
        [ undef, 'DNS lookup resulted in bad host.' ] );
    is_deeply( [ $dns->resolve('50.112.116.235.xip.io') ],
        [ ['50.112.116.235'], undef ], 'ok' );
};

subtest 'localhost is blocked, case insensitive' => sub {
    is_deeply( [ $dns->resolve('LOCALhost') ],
        [ undef, 'DNS lookup resulted in bad host.' ] );
};

done_testing;

