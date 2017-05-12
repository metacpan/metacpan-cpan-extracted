
use strict;
use warnings;
use Test::More;

BEGIN { $ENV{PROTOCOL_OTR_ENABLE_QUICK_RANDOM} = 1 }

use Protocol::OTR qw( :constants );
use File::Temp qw( tempdir );

my $tmpdir = tempdir( 'XXXXXXXX', DIR => "t/", CLEANUP => 1 );

eval {
    my $otr = Protocol::OTR->new( [ 123 ]);
};
ok($@, '->new() args are passed as hashref');

my $otr = Protocol::OTR->new(
    {
        privkeys_file => "$tmpdir/otr.private_key",
        contacts_file => "$tmpdir/otr.fingerprints",
        instance_tags_file => "$tmpdir/otr.instance_tags",
    }
);
isa_ok($otr, 'Protocol::OTR');

eval {
    my $act = $otr->account('user@domain');
};
ok($@, 'otr->account() requires protocol');

eval {
    my $act = $otr->account();
};
ok($@, 'otr->account() requires accountname');

eval {
    my $act = $otr->find_account('user@domain');
};
ok($@, 'otr->find_account() requires protocol');

eval {
    my $act = $otr->find_account();
};
ok($@, 'otr->find_account() requires accountname');


my $act = $otr->account('user@domain', 'protocol');

isa_ok($act, 'Protocol::OTR::Account');


eval {
    my $cnt = $act->contact();
};
ok($@, 'otr->contact() requires username');

eval {
    my $cnt = $act->contact(1,2,3,4,5);
};
ok($@, 'otr->contact() accepts no more then four arguments');

my $cnt = $act->contact('contact@domain', '12345678 90ABCDEF 12345678 90ABCDEF 12345678');

eval {
    my $channel = $cnt->channel();
};
ok($@, 'cnt->channel() requires arguments');

eval {
    my $channel = $cnt->channel( [123] );
};
ok($@, 'cnt->channel() args are passed as hashref');

my ($fingerprint) = $cnt->fingerprints();

eval {
    $fingerprint->set_verified();
};
ok($@, 'fingerprint->set_verified() requires single argument');

my $channel = $cnt->channel( {
        on_write => sub { },
        on_read => sub { },
    }
);

eval {
    $channel->init( 123 );
};
ok($@, 'channel->init() does not accept arguments');

eval {
    $channel->create_symkey( 123 );
};
ok($@, 'channel->create_symkey() requires use_for information');

eval {
    $channel->create_symkey( 1,2,3 );
};
ok($@, 'channel->create_symkey() accepts no more then two arguments');

eval {
    $channel->finish( 123 );
};
ok($@, 'channel->finish() does not accept arguments');

eval {
    $channel->write();
};
ok($@, 'channel->write() requires message');

eval {
    $channel->ping( 123 );
};
ok($@, 'channel->ping() does not accept arguments');

eval {
    $channel->smp_verify();
};
ok($@, 'channel->smp_verify() requires as least the answer');

eval {
    $channel->smp_abort( 123 );
};
ok($@, 'channel->smp_abort() does not accept arguments');

eval {
    $channel->read();
};
ok($@, 'channel->read() requires message');

eval {
    $channel->sessions( 123 );
};
ok($@, 'channel->sessions() does not accept arguments');

eval {
    $channel->select_session();
};
ok($@, 'channel->select_session() requires session id');

done_testing();

