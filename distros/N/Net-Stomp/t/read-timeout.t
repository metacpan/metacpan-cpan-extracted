use lib 't/lib';
use TestHelp;
use Net::Stomp::Frame;

my ($s,$fh)=mkstomp_testsocket(timeout=>1);

my $str = "string\0with\0zeroes\0";
my $frame = Net::Stomp::Frame->new({
    command=>'MESSAGE',
    body=>$str,
    headers=>{
        'message-id'=>1,
        'content-length'=>length($str),
    },
});
my $frame_string = $frame->as_string;

my $time_out_next=0;
$fh->{to_read} = sub {
    return if $time_out_next;
    my $ret = substr($frame_string,0,2,'');
    $time_out_next=1;
    return $ret;
};
$s->select->{can_read} = sub {
    return 1 unless $time_out_next;
    $time_out_next=0;
    return;
};

my $calls_needed = length($frame_string)/2;
for (1..$calls_needed-1) {
    my $received = $s->receive_frame;
    ok(!defined($received),'frame not received yet, time out');
}
my $received = $s->receive_frame;
cmp_deeply($received,$frame,'received and parsed');

done_testing;
