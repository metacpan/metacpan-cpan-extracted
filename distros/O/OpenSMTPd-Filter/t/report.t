use Test2::V0
    -target => 'OpenSMTPd::Filter',
    qw< ok is like dies hash field E etc diag done_testing >;

use Storable qw< dclone >;
use IO::File;

my $has_pledge = do { local $@; eval { local $SIG{__DIE__};
    require OpenBSD::Pledge } };

# Open these before possibly pledging
my $input  = IO::File->new_tmpfile;
my $output = IO::File->new_tmpfile;

# Failed tests attempt to load this and cause pledge violations.
{ local $@; eval { local $SIG{__DIE__};
    require Test2::API::Breakage } };

diag "Testing $CLASS on perl $^V" . ( $has_pledge ? " with pledge" : "" );
OpenBSD::Pledge::pledge() || die "Unable to pledge: $!" if $has_pledge;

ok CLASS->new, "Created a new $CLASS instance";

is CLASS->new->_handle_report(
    '0.5|1576146008.006099|smtp-in|link-connect|7641df9771b4ed00|mail.openbsd.org|pass|199.185.178.25:33174|45.77.67.80:25'
    ), {
    request   => 'report',
    version   => '0.5',
    timestamp => '1576146008.006099',
    subsystem => 'smtp-in',
    event     => 'link-connect',
    session   => '7641df9771b4ed00',
    rdns      => 'mail.openbsd.org',
    fcrdns    => 'pass',
    src       => '199.185.178.25:33174',
    dest      => '45.77.67.80:25',
}, "Able to handle_report for a link-connect";

is CLASS->new->_handle_report(
    '0.6|1576146008.006099|smtp-in|link-auth|7641df9771b4ed00|foobar|pass'
), {
    event     => 'link-auth',
    request   => 'report',
    result    => 'pass',
    session   => '7641df9771b4ed00',
    subsystem => 'smtp-in',
    timestamp => '1576146008.006099',
    username  => 'foobar',
    version   => '0.6',
}, 'Able to handle_report for a 0.6 link-auth';

is CLASS->new->_handle_report(
    '0.7|1576146008.006099|smtp-in|link-auth|7641df9771b4ed00|pass|foo|bar'
), {
    event     => 'link-auth',
    request   => 'report',
    result    => 'pass',
    session   => '7641df9771b4ed00',
    subsystem => 'smtp-in',
    timestamp => '1576146008.006099',
    username  => 'foo|bar',
    version   => '0.7',
}, 'Able to handle_report for a 0.7 link-auth';

like dies { CLASS->new->_handle_report('0.5|1576146008.006099') },
    qr{^\QUnsupported report undef|undef at },
    "Undef report event throws exception";

like dies { CLASS->new->_handle_report('0.5|1576146008.006099|xxx|yyy') },
    qr{^\QUnsupported report 'xxx'|'yyy' at },
    "Unsupported report type throws exception";

like
    dies { CLASS->new->_handle_report('0.5|1576146008.006099|smtp-in|unknown') },
    qr{^\QUnsupported report 'smtp-in'|'unknown' at },
    "Unsupported report event throws exception";

{
    $_->seek( 0, 0 ), $_->truncate(0) for $input, $output;
    $input->say("config|ready");

    $input->print(<<'EOL');
report|0.6|1613343975.082146|smtp-in|link-connect|68d0e60751ca8d79|localhost|pass|[::1]:33310|[::1]:25
report|0.6|1613343975.082230|smtp-in|filter-response|68d0e60751ca8d79|connected|proceed
report|0.6|1613343975.082234|smtp-in|protocol-server|68d0e60751ca8d79|220 mail.example.test ESMTP OpenSMTPD
report|0.6|1613343975.082237|smtp-in|link-greeting|68d0e60751ca8d79|mail.example.test
report|0.6|1613343981.283480|smtp-in|protocol-client|68d0e60751ca8d79|ehlo mail
report|0.6|1613343981.283595|smtp-in|filter-response|68d0e60751ca8d79|ehlo|proceed
report|0.6|1613343981.283598|smtp-in|link-identify|68d0e60751ca8d79|EHLO|mail
report|0.6|1613343981.283605|smtp-in|protocol-server|68d0e60751ca8d79|250-mail.example.test Hello mail [::1], pleased to meet you
report|0.6|1613343981.283609|smtp-in|protocol-server|68d0e60751ca8d79|250-8BITMIME
report|0.6|1613343981.283611|smtp-in|protocol-server|68d0e60751ca8d79|250-ENHANCEDSTATUSCODES
report|0.6|1613343981.283614|smtp-in|protocol-server|68d0e60751ca8d79|250-SIZE 36700160
report|0.6|1613343981.283616|smtp-in|protocol-server|68d0e60751ca8d79|250-DSN
report|0.6|1613343981.283617|smtp-in|protocol-server|68d0e60751ca8d79|250 HELP
report|0.6|1613343990.063508|smtp-in|protocol-client|68d0e60751ca8d79|mail from: <andrew>
report|0.6|1613343990.063632|smtp-in|filter-response|68d0e60751ca8d79|mail-from|proceed
report|0.6|1613343990.064630|smtp-in|protocol-server|68d0e60751ca8d79|250 2.0.0 Ok
report|0.6|1613343990.064633|smtp-in|tx-begin|68d0e60751ca8d79|71df546e
report|0.6|1613343990.064635|smtp-in|tx-mail|68d0e60751ca8d79|71df546e|ok|andrew
report|0.6|1613343994.662611|smtp-in|protocol-client|68d0e60751ca8d79|rcpt to: <afresh1>
report|0.6|1613343994.663100|smtp-in|filter-response|68d0e60751ca8d79|rcpt-to|proceed
report|0.6|1613343994.664498|smtp-in|tx-envelope|68d0e60751ca8d79|71df546e|71df546ec15abbfa
report|0.6|1613343994.664506|smtp-in|protocol-server|68d0e60751ca8d79|250 2.1.5 Destination address valid: Recipient ok
report|0.6|1613343994.664508|smtp-in|tx-rcpt|68d0e60751ca8d79|71df546e|ok|afresh1
report|0.6|1613343999.514133|smtp-in|protocol-client|68d0e60751ca8d79|rcpt to: <root>
report|0.6|1613343999.514251|smtp-in|filter-response|68d0e60751ca8d79|rcpt-to|proceed
report|0.6|1613343999.515987|smtp-in|tx-envelope|68d0e60751ca8d79|71df546e|71df546ee5247710
report|0.6|1613343999.515994|smtp-in|protocol-server|68d0e60751ca8d79|250 2.1.5 Destination address valid: Recipient ok
report|0.6|1613343999.515996|smtp-in|tx-rcpt|68d0e60751ca8d79|71df546e|ok|root
report|0.6|1613344002.448571|smtp-in|protocol-client|68d0e60751ca8d79|data
report|0.6|1613344002.448700|smtp-in|filter-response|68d0e60751ca8d79|data|proceed
report|0.6|1613344002.449727|smtp-in|protocol-server|68d0e60751ca8d79|354 Enter mail, end with "." on a line by itself
report|0.6|1613344002.449730|smtp-in|tx-data|68d0e60751ca8d79|71df546e|ok
report|0.6|1613344022.915763|smtp-in|protocol-client|68d0e60751ca8d79|.
report|0.6|1613344022.915950|smtp-in|filter-response|68d0e60751ca8d79|commit|proceed
report|0.6|1613344022.916424|smtp-in|protocol-server|68d0e60751ca8d79|250 2.0.0 71df546e Message accepted for delivery
report|0.6|1613344022.916428|smtp-in|tx-commit|68d0e60751ca8d79|71df546e|475
report|0.6|1613344022.916429|smtp-in|tx-reset|68d0e60751ca8d79|71df546e
report|0.6|1613344038.749683|smtp-in|protocol-client|68d0e60751ca8d79|mail from: <aahf>
report|0.6|1613344038.749886|smtp-in|filter-response|68d0e60751ca8d79|mail-from|proceed
report|0.6|1613344038.750173|smtp-in|protocol-server|68d0e60751ca8d79|250 2.0.0 Ok
report|0.6|1613344038.750174|smtp-in|tx-begin|68d0e60751ca8d79|9e8fd416
report|0.6|1613344038.750176|smtp-in|tx-mail|68d0e60751ca8d79|9e8fd416|ok|aahf
report|0.6|1613344044.525187|smtp-in|protocol-client|68d0e60751ca8d79|rcpt to: <afresh1>
report|0.6|1613344044.525522|smtp-in|filter-response|68d0e60751ca8d79|rcpt-to|proceed
report|0.6|1613344044.526811|smtp-in|tx-envelope|68d0e60751ca8d79|9e8fd416|9e8fd41612d29cc8
report|0.6|1613344044.526819|smtp-in|protocol-server|68d0e60751ca8d79|250 2.1.5 Destination address valid: Recipient ok
report|0.6|1613344044.526821|smtp-in|tx-rcpt|68d0e60751ca8d79|9e8fd416|ok|afresh1
report|0.6|1613344046.457594|smtp-in|protocol-client|68d0e60751ca8d79|data
report|0.6|1613344046.457925|smtp-in|filter-response|68d0e60751ca8d79|data|proceed
report|0.6|1613344046.458481|smtp-in|protocol-server|68d0e60751ca8d79|354 Enter mail, end with "." on a line by itself
report|0.6|1613344046.458483|smtp-in|tx-data|68d0e60751ca8d79|9e8fd416|ok
report|0.6|1613344067.342864|smtp-in|protocol-client|68d0e60751ca8d79|.
report|0.6|1613344067.343049|smtp-in|filter-response|68d0e60751ca8d79|commit|proceed
report|0.6|1613344067.343353|smtp-in|protocol-server|68d0e60751ca8d79|250 2.0.0 9e8fd416 Message accepted for delivery
report|0.6|1613344067.343357|smtp-in|tx-commit|68d0e60751ca8d79|9e8fd416|545
report|0.6|1613344067.343358|smtp-in|tx-reset|68d0e60751ca8d79|9e8fd416
report|0.6|1613344069.173194|smtp-in|protocol-client|68d0e60751ca8d79|quit
report|0.6|1613344069.173309|smtp-in|filter-response|68d0e60751ca8d79|quit|proceed
report|0.6|1613344069.173314|smtp-in|protocol-server|68d0e60751ca8d79|221 2.0.0 Bye
report|0.6|1613355813.464299|smtp-in|link-connect|3647ceea74a815de|localhost|pass|[::1]:37403|[::1]:25
report|0.6|1613355813.464422|smtp-in|filter-response|3647ceea74a815de|connected|proceed
report|0.6|1613355813.464431|smtp-in|protocol-server|3647ceea74a815de|220 mail.example.test ESMTP OpenSMTPD
report|0.6|1613355813.464464|smtp-in|link-greeting|3647ceea74a815de|mail.example.test
report|0.6|1613355827.573193|smtp-in|protocol-client|3647ceea74a815de|helo mail.afresh1.test
report|0.6|1613355827.573458|smtp-in|filter-response|3647ceea74a815de|helo|proceed
report|0.6|1613355827.573462|smtp-in|link-identify|3647ceea74a815de|HELO|mail.afresh1.test
report|0.6|1613355827.573469|smtp-in|protocol-server|3647ceea74a815de|250 mail.example.test Hello mail.afresh1.test [::1], pleased to meet you
report|0.6|1613355841.676066|smtp-in|protocol-client|3647ceea74a815de|mail from: <aahf>
report|0.6|1613355841.676251|smtp-in|filter-response|3647ceea74a815de|mail-from|proceed
report|0.6|1613355841.676772|smtp-in|protocol-server|3647ceea74a815de|250 2.0.0 Ok
report|0.6|1613355841.676774|smtp-in|tx-begin|3647ceea74a815de|5e170a6f
report|0.6|1613355841.676781|smtp-in|tx-mail|3647ceea74a815de|5e170a6f|ok|aahf
report|0.6|1613355848.331771|smtp-in|protocol-client|3647ceea74a815de|rcpt to: <afresh1>
report|0.6|1613355848.331883|smtp-in|filter-response|3647ceea74a815de|rcpt-to|proceed
report|0.6|1613355848.333733|smtp-in|tx-envelope|3647ceea74a815de|5e170a6f|5e170a6fd549b5d5
report|0.6|1613355848.333740|smtp-in|protocol-server|3647ceea74a815de|250 2.1.5 Destination address valid: Recipient ok
report|0.6|1613355848.333741|smtp-in|tx-rcpt|3647ceea74a815de|5e170a6f|ok|afresh1
report|0.6|1613355851.130171|smtp-in|protocol-client|3647ceea74a815de|data
report|0.6|1613355851.130503|smtp-in|filter-response|3647ceea74a815de|data|proceed
report|0.6|1613355851.131003|smtp-in|protocol-server|3647ceea74a815de|354 Enter mail, end with "." on a line by itself
report|0.6|1613355851.131005|smtp-in|tx-data|3647ceea74a815de|5e170a6f|ok
report|0.6|1613355867.061794|smtp-in|protocol-client|3647ceea74a815de|.
report|0.6|1613355867.062127|smtp-in|filter-response|3647ceea74a815de|commit|proceed
report|0.6|1613355867.062640|smtp-in|protocol-server|3647ceea74a815de|250 2.0.0 5e170a6f Message accepted for delivery
report|0.6|1613355867.062645|smtp-in|tx-commit|3647ceea74a815de|5e170a6f|559
report|0.6|1613355867.062646|smtp-in|tx-reset|3647ceea74a815de|5e170a6f
report|0.6|1613356167.075372|smtp-in|timeout|3647ceea74a815de
EOL

    $input->flush;
    $input->seek( 0, 0 );

    my $f = CLASS->new( input => $input, output => $output );
    $f->ready;

    my $event = hash {
        field request   => 'report';
        field version   => E();
        field timestamp => E();
        field subsystem => E();
        field event     => E();
        field session   => E();
        etc();
    };
    my @messages = (
        {   'mail-from'    => 'aahf',
            'rcpt-to'      => ['afresh1'],
            'envelope-id'  => '5e170a6fd549b5d5',
            'message-id'   => '5e170a6f',
            'message-size' => '559',
            'result'       => 'ok'
        },
        {   'mail-from'    => 'andrew',
            'rcpt-to'      => [ 'afresh1', 'root' ],
            'envelope-id'  => '71df546ee5247710',
            'message-id'   => '71df546e',
            'message-size' => '475',
            'result'       => 'ok'
        },
        {   'mail-from'    => 'aahf',
            'rcpt-to'      => ['afresh1'],
            'envelope-id'  => '9e8fd41612d29cc8',
            'message-id'   => '9e8fd416',
            'message-size' => '545',
            'result'       => 'ok'
        }
    );

    my %expect = (
        '3647ceea74a815de' => {
            events   => [ ($event) x 28 ],
            messages => [ $messages[0] ],
            state    => {
                'message'   => $messages[0],
                'version'   => '0.6',
                'timestamp' => '1613356167.075372',
                'subsystem' => 'smtp-in',
                'session'   => '3647ceea74a815de',
                'src'       => '[::1]:37403',
                'identity'  => 'mail.afresh1.test',
                'rdns'      => 'localhost',
                'fcrdns'    => 'pass',
                'dest'      => '[::1]:25',
                'hostname'  => 'mail.example.test',
                'method'    => 'HELO',
                'event'     => 'timeout',
                'response'  =>
                    '250 2.0.0 5e170a6f Message accepted for delivery',
                'command' => '.',
                'phase'   => 'commit',
                'param'   => undef,
            }

        },
        '68d0e60751ca8d79' => {
            events   => [ ($event) x 59 ],
            messages => [ @messages[ 1, 2 ] ],
            state    => {
                'message'   => $messages[2],
                'command'   => 'quit',
                'dest'      => '[::1]:25',
                'event'     => 'protocol-server',
                'fcrdns'    => 'pass',
                'hostname'  => 'mail.example.test',
                'identity'  => 'mail',
                'method'    => 'EHLO',
                'param'     => undef,
                'phase'     => 'quit',
                'rdns'      => 'localhost',
                'response'  => '221 2.0.0 Bye',
                'session'   => '68d0e60751ca8d79',
                'src'       => '[::1]:33310',
                'subsystem' => 'smtp-in',
                'timestamp' => '1613344069.173314',
                'version'   => '0.6'
            }
        },
    );

    is $f->{_sessions}, \%expect, "Got the sessions we expected";

    is $f->_dispatch(
        'report|0.6|1613344069.173652|smtp-in|link-disconnect|68d0e60751ca8d79'
    ), {
        request   => 'report',
        version   => '0.6',
        timestamp => '1613344069.173652',
        subsystem => 'smtp-in',
        event     => 'link-disconnect',
        session   => '68d0e60751ca8d79',
    }, "Got back the report from the disconnect";

    ok !$f->{_sessions}->{'68d0e60751ca8d79'},
        "Removed the session that disconnected";

    is $f->_dispatch(
        'report|0.6|1613356167.075380|smtp-in|link-disconnect|3647ceea74a815de'
    ), {
        request   => 'report',
        version   => '0.6',
        timestamp => '1613356167.075380',
        subsystem => 'smtp-in',
        event     => 'link-disconnect',
        session   => '3647ceea74a815de',
    }, "Got the timeout event";

    is $f->{_sessions}, {}, "No more sessions after they all disconnected";
}

{
    my @events;
    my $cb = sub { push @events, dclone( \@_ ) };
    my $f  = CLASS->new(
        on => {
            report => {
                'smtp-in' => {
                    'link-connect'    => $cb,
                    'filter-response' => $cb,
                    'link-disconnect' => $cb,
                }
            }
        },
    );

    $f->_dispatch($_)
        for (
        'report|0.6|1613354148.037118|smtp-in|link-connect|a5003f502d509539|localhost|pass|[::1]:13393|[::1]:25',
        'report|0.6|1613354148.037240|smtp-in|filter-response|a5003f502d509539|connected|proceed',
        'report|0.6|1613354148.037249|smtp-in|protocol-server|a5003f502d509539|220 trillian.home.hewus.com ESMTP OpenSMTPD',
        'report|0.6|1613354148.037302|smtp-in|link-greeting|a5003f502d509539|trillian.home.hewus.com',
        'report|0.6|1613354153.366420|smtp-in|protocol-client|a5003f502d509539|ehlo mail',
        'report|0.6|1613354153.366873|smtp-in|filter-response|a5003f502d509539|ehlo|proceed',
        'report|0.6|1613354153.366876|smtp-in|link-identify|a5003f502d509539|EHLO|mail',
        'report|0.6|1613354153.366896|smtp-in|protocol-server|a5003f502d509539|250-trillian.home.hewus.com Hello mail [::1], pleased to meet you',
        'report|0.6|1613354153.366901|smtp-in|protocol-server|a5003f502d509539|250-8BITMIME',
        'report|0.6|1613354153.366903|smtp-in|protocol-server|a5003f502d509539|250-ENHANCEDSTATUSCODES',
        'report|0.6|1613354153.366905|smtp-in|protocol-server|a5003f502d509539|250-SIZE 36700160',
        'report|0.6|1613354153.366907|smtp-in|protocol-server|a5003f502d509539|250-DSN',
        'report|0.6|1613354153.366909|smtp-in|protocol-server|a5003f502d509539|250 HELP',
        'report|0.6|1613354453.375358|smtp-in|timeout|a5003f502d509539',
        'report|0.6|1613354453.375366|smtp-in|link-disconnect|a5003f502d509539',
        );

    my $event = hash {
        field version   => E();
        field timestamp => E();
        field subsystem => E();
        field event     => E();
        field session   => E();
        etc();
    };

    my %state = (
        'version'   => '0.6',
        'timestamp' => '1613354148.037118',
        'subsystem' => 'smtp-in',
        'event'     => 'link-connect',
        'session'   => 'a5003f502d509539',

        'src'    => '[::1]:13393',
        'dest'   => '[::1]:25',
        'rdns'   => 'localhost',
        'fcrdns' => 'pass',
    );

    is \@events, [
        [ 'link-connect', { events => [ ($event) x 1 ], state => {%state} } ],
        [   'filter-response',
            {   events => [ ($event) x 2 ],
                state  => {
                    %state,
                    'timestamp' => '1613354148.037240',
                    'event'     => 'filter-response',
                    'response'  => 'proceed',
                    'param'     => undef,
                    'phase'     => 'connected',
                }
            }
        ],
        [   'filter-response',
            {   events => [ ($event) x 6 ],
                state  => {
                    %state,
                    'timestamp' => '1613354153.366873',
                    'event'     => 'filter-response',
                    'response'  => 'proceed',
                    'param'     => undef,
                    'phase'     => 'ehlo',
                    'command'   => 'ehlo mail',
                    'hostname'  => 'trillian.home.hewus.com',
                }
            }
        ],
        [   'link-disconnect',
            {   events => [ ($event) x 15 ],
                state  => {
                    %state,
                    'timestamp' => '1613354453.375366',
                    'event'     => 'link-disconnect',
                    'response'  => '250 HELP',
                    'param'     => undef,
                    'phase'     => 'ehlo',
                    'method'    => 'EHLO',
                    'command'   => 'ehlo mail',
                    'identity'  => 'mail',
                    'hostname'  => 'trillian.home.hewus.com',
                }
            }
        ],
    ], "Got the events we expected";
}

done_testing;
