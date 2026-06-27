use strict; use warnings;
use Test2::V0;
use Future;
use PAGI::Request::MultipartStream;

sub recv_then_disconnect {        # each given chunk has more=1; then http.disconnect
    my @c = @_;
    return sub { my $x = shift @c; Future->done(defined $x ? {type=>'http.request',body=>$x,more=>1} : {type=>'http.disconnect'}) };
}
sub mp_body {
    my ($b,@rows)=@_; my $s='';
    for my $r (@rows){ my ($n,$f,$ct,$d)=@$r; my $cd=qq{form-data; name="$n"}; $cd.=qq{; filename="$f"} if defined $f;
        $s.="--$b\r\nContent-Disposition: $cd\r\n"; $s.="Content-Type: $ct\r\n" if defined $ct; $s.="\r\n$d\r\n"; }
    return $s."--$b--\r\n";
}
my $b = 'BOUND';
my $partial = "--$b\r\nContent-Disposition: form-data; name=\"doc\"; filename=\"a.bin\"\r\n\r\nABC";  # no closing boundary

subtest 'truncated mid-part is a distinct error (not silent EOF)' => sub {
    my $s = PAGI::Request::MultipartStream->new(receive => recv_then_disconnect($partial), boundary => $b);
    my $p = $s->next->get;
    ok $p && $p->is_file, 'got the (truncated) file part';
    like dies { 1 while defined $p->next_chunk->get }, qr/disconnect|truncat|end of stream/i, 'truncation croaks';
};

subtest 'complete body then disconnect ends cleanly (no error)' => sub {
    my $complete = mp_body($b, ['doc','a.txt','text/plain','hi']);     # includes closing --BOUND--
    my $s = PAGI::Request::MultipartStream->new(receive => recv_then_disconnect($complete), boundary => $b);
    my @got;
    ok lives { while (defined(my $p = $s->next->get)) { push @got, $p->value->get } }, 'drains cleanly despite trailing disconnect';
    is \@got, ['hi'], 'got the part value';
};

subtest 'stream_to_file unlinks the partial file on truncation' => sub {
    my $s = PAGI::Request::MultipartStream->new(receive => recv_then_disconnect($partial), boundary => $b);
    my $p = $s->next->get;
    my $path = "/tmp/pagi-mp-disc-$$.bin"; unlink $path;
    like dies { $p->stream_to_file($path)->get }, qr/disconnect|truncat|end of stream/i, 'truncation croaks';
    ok !-e $path, 'partial file removed';
};

subtest 'empty body (immediate disconnect, no data) ends cleanly' => sub {
    my $s = PAGI::Request::MultipartStream->new(
        receive => sub { Future->done({ type => 'http.disconnect' }) }, boundary => $b);
    is $s->next->get, undef, 'no parts, no croak';
};
subtest 'empty body (zero-length more=0) ends cleanly' => sub {
    my $s = PAGI::Request::MultipartStream->new(
        receive => sub { Future->done({ type => 'http.request', body => '', more => 0 }) }, boundary => $b);
    is $s->next->get, undef, 'no parts, no croak';
};

done_testing;
