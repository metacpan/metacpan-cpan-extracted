use lib 't/lib';
use TestHelp;
use Net::Stomp::Frame;

my ($s,$fh)=mkstomp_testsocket();

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
# -> BEGIN
# -> SEND
# <- RECEIPT
# -> COMMIT
#
# or
# -> BEGIN
# -> SEND
# <- something else
# -> COMMIT

sub _testit {
    my ($response_frame,$expected_ret,$expected_command) = @_;
    $fh->{to_read} = sub {
        if ($frames[1]) {
            return $response_frame->($frames[1]->headers->{receipt})
                ->as_string;
        }
        return '';
    };

    @frames=();
    my $ret = $s->send_transactional({some=>'header',body=>'string'});

    cmp_deeply($ret,bool($expected_ret),"expected return value");

    is(scalar(@frames),3,'3 frames sent');

    cmp_deeply(
        $frames[0],
        methods(
            command=>'BEGIN',
            headers => {transaction => ignore()},
        ),
        'begin ok',
    );
    my $transaction = $frames[0]->headers->{transaction};

    cmp_deeply(
        $frames[1],
        methods(
            command => 'SEND',
            headers => {
                some=>'header',
                transaction=>$transaction,
                receipt=>ignore(),
            },
            body => 'string',
        ),
        'send ok',
    );

    cmp_deeply(
        $frames[2],
        methods(
            command => uc($expected_command),
            headers => {
                transaction=>$transaction,
            },
        ),
        "\L$expected_command\E ok",
    );
}

subtest 'successful' => sub {
    _testit(sub{ Net::Stomp::Frame->new({
        command=>'RECEIPT',
        headers=>{'receipt-id'=>$_[0]},
        body=>undef,
    }) },1,'COMMIT');
};

subtest 'failed' => sub {
    _testit(sub{ Net::Stomp::Frame->new({
        command=>'ERROR',
        headers=>{some=>'header'},
        body=>undef,
    }) },0,'ABORT');
};

subtest 'bad receipt' => sub {
    _testit(sub{ Net::Stomp::Frame->new({
        command=>'RECEIPT',
        headers=>{'receipt-id'=>"not-$_[0]"},
        body=>undef,
    }) },0,'ABORT');
};

subtest 'no receipt (timeout)' => sub {
    local $s->select->{can_read}=0;
    _testit(sub{ Net::Stomp::Frame->new({
        command=>'BLARGH',
        body=>undef,
    }) },0,'ABORT');
};

done_testing;
