# Tests for protocol handshake, script execution, error handling, and stdin forwarding.
use v5.36;
use Test::More;
use IPC::Open3 qw(open3);
use IO::Select;
use Symbol qw(gensym);

use lib 'lib';
use Remote::Perl::Bootstrap qw(bootstrap_payload wait_for_ready READY_MARKER);
use Remote::Perl::Protocol qw(
    HEADER_LEN PROTOCOL_VERSION
    MSG_HELLO MSG_READY MSG_RUN MSG_DATA MSG_EOF
    MSG_CREDIT MSG_MOD_REQ MSG_RETURN MSG_ERROR MSG_BYE
    STREAM_CONTROL STREAM_STDIN STREAM_STDOUT STREAM_STDERR
    encode_message encode_hello encode_credit decode_return
    TMPFILE_NONE
    encode_run
);

# -- Helpers -------------------------------------------------------------------

sub spawn_remote() {
    my ($in, $out, $err);
    $err = gensym();
    my $pid = open3($in, $out, $err, $^X);
    binmode($in); binmode($out); binmode($err);
    $in->autoflush(1);
    print $in bootstrap_payload();
    return ($in, $out, $err, $pid);
}

sub send_msg($fh, $type, $stream, $body = '') {
    print $fh encode_message($type, $stream, $body);
}

# Read messages from $out_fh.  $init is an initial byte string already read
# (leftover from wait_for_ready).  Blocks until $pred returns true or timeout.
sub read_until($out_fh, $pred, $timeout_s = 10, $init = '') {
    my $parser = Remote::Perl::Protocol::Parser->new;
    my @msgs;
    push @msgs, $parser->feed($init) if length $init;
    return @msgs if $pred->(\@msgs);

    my $sel      = IO::Select->new($out_fh);
    my $deadline = time + $timeout_s;
    while (time < $deadline) {
        my @ready = $sel->can_read($deadline - time);
        last unless @ready;
        my $data;
        my $n = sysread($out_fh, $data, 65536);
        last unless $n;
        push @msgs, $parser->feed($data);
        return @msgs if $pred->(\@msgs);
    }
    return @msgs;
}

sub has_type($msgs, $type) { grep { $_->{type} == $type } @$msgs }

# -- Handshake -----------------------------------------------------------------

{
    my ($in, $out, $err, $pid) = spawn_remote();
    my $leftover = wait_for_ready($out);
    pass('bootstrap: readiness marker received');

    send_msg($in, MSG_HELLO, STREAM_CONTROL, encode_hello(PROTOCOL_VERSION, 65536));

    my @msgs    = read_until($out, sub { has_type($_[0], MSG_READY) }, 10, $leftover);
    my ($ready) = has_type(\@msgs, MSG_READY);
    ok($ready, 'bootstrap: READY message received');
    is($ready && $ready->{stream}, STREAM_CONTROL, 'bootstrap: READY on control stream');

    send_msg($in, MSG_BYE, STREAM_CONTROL);
    read_until($out, sub { has_type($_[0], MSG_BYE) });
    close $in;
    waitpid($pid, 0);
    pass('bootstrap: clean shutdown');
}

# -- Run a trivial script ------------------------------------------------------

{
    my ($in, $out, $err, $pid) = spawn_remote();
    my $leftover = wait_for_ready($out);
    send_msg($in, MSG_HELLO, STREAM_CONTROL, encode_hello(PROTOCOL_VERSION, 65536));
    my @msgs = read_until($out, sub { has_type($_[0], MSG_READY) }, 10, $leftover);
    $leftover = '';   # consumed

    send_msg($in, MSG_CREDIT, STREAM_STDOUT, encode_credit(65536));
    send_msg($in, MSG_CREDIT, STREAM_STDERR, encode_credit(65536));
    send_msg($in, MSG_RUN, STREAM_CONTROL, encode_run(TMPFILE_NONE, 'print "hello from remote\n";'));

    @msgs = read_until($out, sub { has_type($_[0], MSG_RETURN) }, 15);

    my ($stdout_msg) = grep { $_->{type} == MSG_DATA && $_->{stream} == STREAM_STDOUT } @msgs;
    my ($ret)        = has_type(\@msgs, MSG_RETURN);

    ok($stdout_msg, 'run: DATA on stdout received');
    is($stdout_msg && $stdout_msg->{body}, "hello from remote\n", 'run: correct stdout');

    ok($ret, 'run: RETURN received');
    my ($exit_code) = $ret ? decode_return($ret->{body}) : (undef);
    is($exit_code, 0, 'run: exit code 0');

    send_msg($in, MSG_BYE, STREAM_CONTROL);
    read_until($out, sub { has_type($_[0], MSG_BYE) });
    close $in;
    waitpid($pid, 0);
}

# -- Script with eval error ----------------------------------------------------

{
    my ($in, $out, $err, $pid) = spawn_remote();
    my $leftover = wait_for_ready($out);
    send_msg($in, MSG_HELLO, STREAM_CONTROL, encode_hello(PROTOCOL_VERSION, 65536));
    read_until($out, sub { has_type($_[0], MSG_READY) }, 10, $leftover);

    send_msg($in, MSG_CREDIT, STREAM_STDOUT, encode_credit(65536));
    send_msg($in, MSG_CREDIT, STREAM_STDERR, encode_credit(65536));
    send_msg($in, MSG_RUN, STREAM_CONTROL, encode_run(TMPFILE_NONE, 'die "oops\n";'));

    my @msgs  = read_until($out, sub { has_type($_[0], MSG_RETURN) }, 15);
    my ($ret) = has_type(\@msgs, MSG_RETURN);

    ok($ret, 'error: RETURN received after die');
    my ($exit_code, $msg) = $ret ? decode_return($ret->{body}) : ();
    is($exit_code, 255,  'error: exit code 255');
    like($msg, qr/oops/, 'error: die message in RETURN body');

    send_msg($in, MSG_BYE, STREAM_CONTROL);
    read_until($out, sub { has_type($_[0], MSG_BYE) });
    close $in;
    waitpid($pid, 0);
}

# -- STDIN forwarding ----------------------------------------------------------

{
    my ($in, $out, $err, $pid) = spawn_remote();
    my $leftover = wait_for_ready($out);
    send_msg($in, MSG_HELLO, STREAM_CONTROL, encode_hello(PROTOCOL_VERSION, 65536));
    read_until($out, sub { has_type($_[0], MSG_READY) }, 10, $leftover);

    send_msg($in, MSG_CREDIT, STREAM_STDOUT, encode_credit(65536));
    send_msg($in, MSG_CREDIT, STREAM_STDERR, encode_credit(65536));
    send_msg($in, MSG_RUN, STREAM_CONTROL, encode_run(TMPFILE_NONE, 'my $l = <STDIN>; print "got: $l";'));

    # Client will send CREDIT on STREAM_STDIN when the script blocks on <STDIN>.
    my @msgs = read_until($out, sub { has_type($_[0], MSG_CREDIT) }, 10);
    my ($cred) = has_type(\@msgs, MSG_CREDIT);
    ok($cred && $cred->{stream} == STREAM_STDIN, 'stdin: client requested stdin credit');

    send_msg($in, MSG_DATA, STREAM_STDIN, "ping\n");
    send_msg($in, MSG_EOF,  STREAM_STDIN);

    @msgs = read_until($out, sub { has_type($_[0], MSG_RETURN) }, 15);
    my ($stdout_msg) = grep { $_->{type} == MSG_DATA && $_->{stream} == STREAM_STDOUT } @msgs;
    ok($stdout_msg, 'stdin: stdout DATA received');
    is($stdout_msg && $stdout_msg->{body}, "got: ping\n", 'stdin: echoed correctly');

    send_msg($in, MSG_BYE, STREAM_CONTROL);
    read_until($out, sub { has_type($_[0], MSG_BYE) });
    close $in;
    waitpid($pid, 0);
}

done_testing;
