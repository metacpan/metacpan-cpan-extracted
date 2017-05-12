use lib 't/lib';
use TestHelp;
use Net::Stomp::Frame;

my ($s,$fh)=mkstomp_testsocket(timeout=>1);

subtest 'one frame' => sub {
    my $timeout_in_call;

    my $orig = \&Net::Stomp::_read_data;
    no warnings 'redefine';
    local *Net::Stomp::_read_data = sub {
        my ($self,$timeout) = @_;
        $timeout_in_call=$timeout;
        $self->$orig($timeout);
    };

    my $frame = Net::Stomp::Frame->new({
        command=>'MESSAGE',
        headers=>{'message-id'=>1},
        body=>'string',
    });

    $fh->{to_read}=$frame->as_string;
    my $received = $s->receive_frame;
    cmp_deeply($received,$frame,'received and parsed');
    is($timeout_in_call,1,'correct timeout passed');

    $fh->{to_read}=$frame->as_string;
    $received = $s->receive_frame({timeout=>3});
    is($timeout_in_call,3,'correct timeout passed');
};

subtest 'two frames' => sub {
    my @frames = map {Net::Stomp::Frame->new({
        command=>'MESSAGE',
        headers=>{'message-id'=>$_},
        body=>'string',
    })} (1,2);

    $fh->{to_read}=join '',map {$_->as_string} @frames;
    my $received = $s->receive_frame;
    cmp_deeply($received,$frames[0],'received and parsed');
    $received = $s->receive_frame;
    cmp_deeply($received,$frames[1],'received and parsed');
};

subtest 'a few bytes at a time' => sub {
    my $frame = Net::Stomp::Frame->new({
        command=>'MESSAGE',
        headers=>{'message-id'=>1},
        body=>'string',
    });
    my $frame_string = $frame->as_string;

    $fh->{to_read} = sub {
        return substr($frame_string,0,2,'');
    };
    my $received = $s->receive_frame;
    cmp_deeply($received,$frame,'received and parsed');

};

subtest 'one frame, with content-length' => sub {
    my $str = "string\0with\0zeroes\0";
    my $frame = Net::Stomp::Frame->new({
        command=>'MESSAGE',
        body=>$str,
        headers=>{
            'message-id'=>1,
            'content-length'=>length($str),
        },
    });

    $fh->{to_read}=$frame->as_string;
    my $received = $s->receive_frame;
    cmp_deeply($received,$frame,'received and parsed');
};

subtest 'a few bytes at a time, with content-length' => sub {
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

    $fh->{to_read} = sub {
        return substr($frame_string,0,2,'');
    };
    my $received = $s->receive_frame;
    cmp_deeply($received,$frame,'received and parsed');

};

subtest 'buffer boundary condition' => sub {
    # this is a regression test for RT #105500, thanks Dryapak Grigory
    # for reporting it
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
    # the first read gets the entire frame *minus the terminating 0*
    # the second read gets the zero
    my $bufsize = length($frame_string)-1;
    $s->bufsize($bufsize);
    # let's add another frame
    $frame_string .= $frame_string;

    $fh->{to_read} = sub {
        return substr($frame_string,0,$bufsize,'');
    };
    my $received = $s->receive_frame;
    cmp_deeply($received,$frame,'received and parsed');
    $received = $s->receive_frame;
    cmp_deeply($received,$frame,'received and parsed, twice');
};

done_testing;
