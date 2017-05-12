use lib 't/lib';
use TestHelp;
use Net::Stomp::Frame;

my ($s,$fh)=mkstomp_testsocket(
    receipt_timeout => 5,
);

my @frames;my $buffer='';
$fh->{written} = sub {
    $buffer .= $_[0];
    my $frame = Net::Stomp::Frame->parse($buffer);
    if ($frame) {
        $buffer='';
        push @frames,$frame;
    }
    return length($_[0]);
};

# expected:
# -> SEND
# <- RECEIPT
#
# or
# -> SEND
# <- something else

sub _testit {
    my ($response_frame,$expected) = @_;
    $fh->{to_read} = sub {
        if ($frames[0]) {
            return $response_frame->($frames[0]->headers->{receipt})
                ->as_string;
        }
        return '';
    };

    @frames=();
    my $ret = $s->send_with_receipt({some=>'header',body=>'string',timeout=>5});

    is(scalar(@frames),1,'1 frame sent');

    cmp_deeply(
        $frames[0],
        methods(
            command => 'SEND',
            headers => {
                some=>'header',
                receipt=>ignore(),
            },
            body => 'string',
        ),
        'send ok',
    );

    is ($ret,$expected,'return value as expected');
}

subtest 'successful' => sub {
    _testit(sub{ Net::Stomp::Frame->new({
        command=>'RECEIPT',
        headers=>{'receipt-id'=>$_[0]},
        body=>undef,
    }) },1);
};

subtest 'failed' => sub {
    _testit(sub{ Net::Stomp::Frame->new({
        command=>'ERROR',
        headers=>{some=>'header'},
        body=>undef,
    }) },0);
};

subtest 'bad receipt' => sub {
    _testit(sub{ Net::Stomp::Frame->new({
        command=>'RECEIPT',
        headers=>{'receipt-id'=>"not-$_[0]"},
        body=>undef,
    }) },0);
};

subtest 'no receipt (timeout)' => sub {
    local $s->select->{can_read}=0;
    _testit(sub{ Net::Stomp::Frame->new({
        command=>'BLARGH',
        body=>undef,
    }) },0);
};

done_testing;
