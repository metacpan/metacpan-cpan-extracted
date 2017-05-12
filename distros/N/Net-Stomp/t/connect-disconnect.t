use lib 't/lib';
use TestHelp;
use Net::Stomp::Frame;

my ($s,$fh)=mkstomp_testsocket();

my $frame;my $buffer='';
$fh->{written} = sub {
    $buffer .= $_[0];
    $frame = Net::Stomp::Frame->parse($buffer);
    $buffer='' if $frame;
    return length($_[0]);
};

subtest 'connect' => sub {
    $fh->{to_read} = sub {
        if ($frame) {
            return Net::Stomp::Frame->new({
                command => 'CONNECTED',
                headers => {session=>'foo'},
            })->as_string;
        }
        return '';
    };

    $s->connect({login=>'me'});

    cmp_deeply(
        $frame,
        all(
            isa('Net::Stomp::Frame'),
            methods(
                command => 'CONNECT',
                headers => {login=>'me'},
                body => undef,
            ),
        ),
        'connect frame sent',
    );
    cmp_deeply(
        $s,
        methods(
            session_id => 'foo',
            _connect_headers => { login => 'me' },
        ),
        'connection data received and stored',
    );
};

subtest 'disconnect' => sub {
    $frame='';
    $s->disconnect;

    cmp_deeply(
        $frame,
        all(
            isa('Net::Stomp::Frame'),
            methods(
                command => 'DISCONNECT',
                headers => {},
                body => undef,
            ),
        ),
        'disconnect frame sent',
    );
    ok(not(defined($s->select->{socket})),'socket was removed from select');
};

done_testing;
