use strict; use warnings;
use Test2::V0;
use Future;
use PAGI::Request::MultipartStream;

sub receiver {                              # receiver(@chunks) — last real chunk has more=0
    my @chunks = @_;
    return sub {
        my $c = shift @chunks;
        return Future->done(defined $c
            ? { type => 'http.request', body => $c, more => (@chunks ? 1 : 0) }
            : { type => 'http.disconnect' });
    };
}
sub mp_body {                               # build a multipart body from [name,filename,ct,data] rows
    my ($b, @rows) = @_;
    my $s = '';
    for my $r (@rows) {
        my ($name, $filename, $ct, $data) = @$r;
        my $cd = qq{form-data; name="$name"};
        $cd .= qq{; filename="$filename"} if defined $filename;
        $s .= "--$b\r\nContent-Disposition: $cd\r\n";
        $s .= "Content-Type: $ct\r\n" if defined $ct;
        $s .= "\r\n$data\r\n";
    }
    return $s . "--$b--\r\n";
}

my $b = 'BOUND';
my $body = mp_body($b, ['title',undef,undef,'Hello'], ['doc','a.txt','text/plain',"line1\nline2"]);

subtest 'yields a field then a file across split chunks' => sub {
    my $half = int(length($body)/2);
    my $s = PAGI::Request::MultipartStream->new(
        receive => receiver(substr($body,0,$half), substr($body,$half)), boundary => $b);
    my $p1 = $s->next->get;
    is $p1->type, 'field', 'first is a field';
    is $p1->name, 'title', 'field name';
    my $p2 = $s->next->get;
    is $p2->type, 'file', 'second is a file';
    is $p2->filename, 'a.txt', 'filename';
    is $p2->content_type, 'text/plain', 'content type';
    is $s->next->get, undef, 'undef at end';
};

subtest 'advancing past an unconsumed part auto-drains' => sub {
    my $s = PAGI::Request::MultipartStream->new(receive => receiver($body), boundary => $b);
    $s->next->get;                          # field, not consumed
    my $p2 = $s->next->get;
    ok $p2->is_file && $p2->filename eq 'a.txt', 'auto-drained to the file part';
};

subtest 'value buffers a small field' => sub {
    my $s = PAGI::Request::MultipartStream->new(receive => receiver($body), boundary => $b);
    is $s->next->get->value->get, 'Hello', 'field value';
};
subtest 'stream_to sends file bytes to a custom sink (no temp file)' => sub {
    my $s = PAGI::Request::MultipartStream->new(receive => receiver($body), boundary => $b);
    $s->next->get;                               # field
    my $sunk = '';
    my $n = $s->next->get->stream_to(sub { $sunk .= $_[0]; Future->done })->get;
    is $sunk, "line1\nline2", 'streamed bytes';
    is $n, 11, 'returned byte count';
};
subtest 'stream_to_file writes the part and refuses to clobber' => sub {
    my $s = PAGI::Request::MultipartStream->new(receive => receiver($body), boundary => $b);
    $s->next->get;
    my $path = "/tmp/pagi-mp-$$.txt"; unlink $path;
    my $n = $s->next->get->stream_to_file($path)->get;
    open my $rfh,'<:raw',$path; local $/; my $got = <$rfh>; close $rfh; unlink $path;
    is $got, "line1\nline2", 'file contents';
    open my $x,'>',$path; close $x;              # pre-existing file
    my $s2 = PAGI::Request::MultipartStream->new(receive => receiver($body), boundary => $b);
    $s2->next->get;
    like dies { $s2->next->get->stream_to_file($path)->get }, qr/Cannot create/, 'O_EXCL refuses existing path';
    unlink $path;
};
subtest 'a throwing sink poisons the stream and does not auto-drain' => sub {
    my $s = PAGI::Request::MultipartStream->new(receive => receiver($body), boundary => $b);
    $s->next->get;
    my $file = $s->next->get;
    like dies { $file->stream_to(sub { die "boom\n" })->get }, qr/boom/, 'sink error propagates';
    like dies { $s->next->get }, qr/sink error|boom/, 'stream poisoned after sink error';
};

subtest 'stream_to_file unlinks the partial file on a mid-write error' => sub {
    # Split so the part yields and a first under-limit chunk is written (creating
    # the file), then a later chunk trips max_file_size mid-write — exercising the
    # partial-file cleanup path rather than tripping the limit during ->next.
    my $big = mp_body($b, ['doc','big.bin','application/octet-stream', 'x' x 50]);
    my $cut = index($big, "\r\n\r\n") + 4 + 5;   # 5 body bytes in the first chunk
    my $s = PAGI::Request::MultipartStream->new(
        receive => receiver(substr($big,0,$cut), substr($big,$cut)),
        boundary => $b, max_file_size => 10);
    my $p = $s->next->get;
    my $path = "/tmp/pagi-mp-err-$$.bin"; unlink $path;
    like dies { $p->stream_to_file($path)->get }, qr/too large/i, 'oversized file croaks';
    ok !-e $path, 'partial file removed on error';
};

done_testing;
