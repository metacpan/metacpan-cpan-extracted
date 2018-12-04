use Test::More;

ok(
    eval { require Socket::MsgHdr; 1 },
    'loaded dynamically',
);

my $send_msg = Socket::MsgHdr->new(
    buf => 12345,
);
$send_msg->cmsghdr( 0, 0, "\0" x 24 );

my $recv_msg = Socket::MsgHdr->new(
    buflen => 1,
    controllen => 32,
);

ok 1, '… and messages can be created';

done_testing();
