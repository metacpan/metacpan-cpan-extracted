use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use POSIX qw(WNOHANG);

use lib 'lib';
use lib 't/lib';

use Qmail::Deliverable;
use Qmail::Deliverable::Client;
use QDTest qw(setup_abs_fixtures start_daemon stop_daemon pick_port);

my $fixtures = setup_abs_fixtures();
my ( $pid, $port ) = start_daemon( qmail_dir => $fixtures );

END {
    stop_daemon($pid) if $pid;
}

$Qmail::Deliverable::Client::SERVER = "127.0.0.1:$port";

sub warning_like (&$$) {
    my ( $code, $re, $name ) = @_;
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $code->();
    }
    like join( "", @warnings ), $re, $name;
}

# Start a one-shot TCP server that sends $raw_response to the first connection.
# Returns ($pid, $port). Caller must waitpid($pid, 0) after use.
sub one_shot_server {
    my ($raw_response) = @_;
    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or die "one_shot_server: $!";
    my $sport = $srv->sockport;
    my $pid   = fork // die "fork: $!";
    if ( $pid == 0 ) {
        local $SIG{ALRM} = sub { POSIX::_exit(1) };
        alarm 5;
        my $c = $srv->accept;
        if ($c) {
            while ( my $line = <$c> ) { last if $line =~ /^\r?\n$/ }
            print {$c} $raw_response;
            $c->close;
        }
        $srv->close;
        POSIX::_exit(0);
    }
    $srv->close;
    return ( $pid, $sport );
}

subtest 'qmail_local: routes to daemon and returns the local part' => sub {
    is Qmail::Deliverable::Client::qmail_local('alice@sub.example.com'), 'alice', 'locals path';
    is Qmail::Deliverable::Client::qmail_local('bob@example.com'),
        'example.com-bob',
        'virtualdomain path';
};

subtest 'qmail_local: undef result on unknown domain' => sub {
    is Qmail::Deliverable::Client::qmail_local('user@nowhere.test'),
        undef,
        'undef passes through (204 from daemon)';
};

subtest 'qmail_local: bare local short-circuits, no HTTP request' => sub {

    # Point SERVER at a closed port. If the client makes an HTTP request,
    # it would warn. The bare-local fast path must skip the request entirely.
    local $Qmail::Deliverable::Client::SERVER = "127.0.0.1:1";
    is Qmail::Deliverable::Client::qmail_local('alice'),
        'alice',
        'bare local returned without contacting the daemon';
};

subtest 'deliverable: numeric status from daemon' => sub {
    is Qmail::Deliverable::Client::deliverable('alice@sub.example.com'),
        0xf1,
        '0xf1 for normal delivery';
    is Qmail::Deliverable::Client::deliverable('user@nowhere.test'), 0xff, '0xff for non-local';
};

subtest 'SERVER as callback' => sub {
    my $hits = 0;
    local $Qmail::Deliverable::Client::SERVER = sub {
        $hits++;
        return "127.0.0.1:$port";
    };
    is Qmail::Deliverable::Client::deliverable('alice@sub.example.com'),
        0xf1,
        'callback resolves to live daemon';
    cmp_ok $hits, '>', 0, 'callback was invoked';
};

subtest 'SERVER = undef -> faked failure, no warning' => sub {
    local $Qmail::Deliverable::Client::SERVER = undef;
    my $rv;
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $rv = Qmail::Deliverable::Client::deliverable('alice@sub.example.com');
    }
    is $rv,               0x2f, '0x2f returned';
    is scalar(@warnings), 0,    'no warning emitted on SERVER=undef';
};

subtest 'connection failure -> 0x2f with carp' => sub {
    my $closed_port = pick_port();    # close immediately; nothing listens
    local $Qmail::Deliverable::Client::SERVER = "127.0.0.1:$closed_port";
    my $rv;
    warning_like {
        $rv = Qmail::Deliverable::Client::deliverable('alice@sub.example.com');
    }
    qr/unreachable|broken/i, 'warning on connection failure';
    is $rv, 0x2f, '0x2f returned';
    like $Qmail::Deliverable::Client::ERROR, qr/unreachable|broken/i, '$ERROR is populated';
};

subtest 'qmail_local with connection failure returns ""' => sub {
    my $closed_port = pick_port();
    local $Qmail::Deliverable::Client::SERVER = "127.0.0.1:$closed_port";
    my $rv;
    warning_like {
        $rv = Qmail::Deliverable::Client::qmail_local('alice@sub.example.com');
    }
    qr/unreachable|broken/i, 'warning on connection failure';
    is $rv, '', 'empty string returned for failure';
};

subtest 'invalid address -> warns and returns undef' => sub {
    my ( $rv, $rv2 );
    warning_like { $rv = Qmail::Deliverable::Client::deliverable('not@@valid') }
    qr/Invalid address/, 'deliverable warns on bad address';
    is $rv, undef, 'deliverable returns undef for invalid address';

    warning_like { $rv2 = Qmail::Deliverable::Client::qmail_local('not@@valid') }
    qr/Invalid address/, 'qmail_local warns on bad address';
    is $rv2, undef, 'qmail_local returns undef for invalid address';
};

subtest 'SERVER callback returning undef -> silent QD_CLIENT_FAILURE' => sub {
    local $Qmail::Deliverable::Client::SERVER = sub {undef};
    my ( $rv, @warnings );
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $rv = Qmail::Deliverable::Client::deliverable('alice@sub.example.com');
    }
    is $rv,              0x2f, 'QD_CLIENT_FAILURE returned when callback returns undef';
    is scalar @warnings, 0,    'no warning emitted';
};

subtest 'invalid SERVER format -> warns and returns QD_CLIENT_FAILURE' => sub {
    local $Qmail::Deliverable::Client::SERVER = 'not-a-valid-host-port';
    my $rv;
    warning_like {
        $rv = Qmail::Deliverable::Client::deliverable('alice@sub.example.com');
    }
    qr/unreachable|broken/i, 'warns on invalid server address format';
    is $rv, 0x2f, 'QD_CLIENT_FAILURE returned';
};

subtest 'non-200/204 from server -> warns and returns QD_CLIENT_FAILURE' => sub {
    my ( $fpid, $fport ) =
        one_shot_server("HTTP/1.0 403 Forbidden\r\nContent-Length: 14\r\n\r\n403 Forbidden\r\n");
    local $Qmail::Deliverable::Client::SERVER = "127.0.0.1:$fport";
    my $rv;
    warning_like {
        $rv = Qmail::Deliverable::Client::deliverable('alice@sub.example.com');
    }
    qr/unreachable|broken/i, 'warns on non-200/204 status';
    is $rv, 0x2f, 'QD_CLIENT_FAILURE returned';
    waitpid $fpid, 0;
};

subtest 'malformed response -> warns and returns QD_CLIENT_FAILURE' => sub {
    my ( $fpid, $fport ) = one_shot_server("not HTTP at all\n");
    local $Qmail::Deliverable::Client::SERVER = "127.0.0.1:$fport";
    my $rv;
    warning_like {
        $rv = Qmail::Deliverable::Client::deliverable('alice@sub.example.com');
    }
    qr/unreachable|broken/i, 'warns on malformed response';
    is $rv, 0x2f, 'QD_CLIENT_FAILURE returned';
    waitpid $fpid, 0;
};

subtest 'plus-sign in local part roundtrips through HTTP' => sub {
    is Qmail::Deliverable::Client::qmail_local('alice+tag@sub.example.com'),
        'alice+tag',
        '+ in local part is correctly percent-encoded and decoded';
};

subtest 'percent-sign in local part roundtrips through HTTP' => sub {
    is Qmail::Deliverable::Client::qmail_local('alice%test@sub.example.com'),
        'alice%test',
        '% in local part is correctly percent-encoded and decoded';
};

done_testing();
