use strict;
use Test::More (tests => 3);

BEGIN
{
    use_ok("POE::Component::MessageQueue::Message");
}

my $message_id  = 'test-message';
my $destination = '/queue/foo/bar';
my $body        = '0123456789abcdefghijklmnopqrstuvwxyz';
my $persistent  = 1;
my $in_use_by   = "client-id";
my $timestamp   = time();
my $size        = length($body);

can_ok(
    'POE::Component::MessageQueue::Message',
    qw(new id destination body persistent claimant timestamp size),
    qw(create_stomp_frame)
);

{
    my $msg = POE::Component::MessageQueue::Message->new({
        id          => $message_id,
        destination => $destination,
        body        => $body,
        persistent  => $persistent,
    });

    my $want = Net::Stomp::Frame->new( {
        command => 'MESSAGE',
        headers => {
            'destination'    => $destination,
            'message-id'     => $message_id,
            'content-length' => length($body),
        },
        body    => $body
    });
    is_deeply( $msg->create_stomp_frame, $want );
}
