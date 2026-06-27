use strict; use warnings;
use Test2::V0;
use Future;
use PAGI::Request::MultipartStream;

sub receiver { my @c=@_; return sub { my $x=shift @c; Future->done(defined $x ? {type=>'http.request',body=>$x,more=>(@c?1:0)} : {type=>'http.disconnect'}) } }
sub mp_body {
    my ($b, @rows) = @_;
    my $s = '';
    for my $r (@rows) {
        my ($name,$filename,$ct,$data) = @$r;
        my $cd = qq{form-data; name="$name"};
        $cd .= qq{; filename="$filename"} if defined $filename;
        $s .= "--$b\r\nContent-Disposition: $cd\r\n";
        $s .= "Content-Type: $ct\r\n" if defined $ct;
        $s .= "\r\n$data\r\n";
    }
    return $s . "--$b--\r\n";
}
my $b = 'BOUND';

subtest 'per-file size limit trips (and names the part)' => sub {
    my $body = mp_body($b, ['doc','big.bin','application/octet-stream', 'x' x 50]);
    my $s = PAGI::Request::MultipartStream->new(receive => receiver($body), boundary => $b, max_file_size => 10);
    my $err = dies { my $p = $s->next->get; $p && $p->stream_to(sub { Future->done })->get };
    like $err, qr/File part .* too large/i, 'oversized file croaks';
    like $err, qr/'doc'/,                   'message names the offending part';
};
subtest 'per-field size limit trips' => sub {
    my $body = mp_body($b, ['note',undef,undef, 'y' x 50]);
    my $s = PAGI::Request::MultipartStream->new(receive => receiver($body), boundary => $b, max_field_size => 10);
    like dies { my $p = $s->next->get; $p && $p->value->get }, qr/Field part .* too large/i, 'oversized field croaks';
};
subtest 'too many parts trips' => sub {
    my @rows = map { ["f$_", undef, undef, 'v'] } 1..5;
    my $body = mp_body($b, @rows);
    my $s = PAGI::Request::MultipartStream->new(receive => receiver($body), boundary => $b, max_fields => 2);
    my $err = dies { my $n=0; while (defined(my $p = $s->next->get)) { $p->value->get; last if ++$n > 20 } };
    like $err, qr/Too many field parts/, 'field count enforced';
};
subtest 'aggregate max_request_body trips regardless of Content-Length' => sub {
    my $body = mp_body($b, ['doc','a.bin','application/octet-stream', 'z' x 100]);
    my @chunks = $body =~ /(.{1,16})/gs;        # tiny chunks; no Content-Length is ever consulted
    my $s = PAGI::Request::MultipartStream->new(receive => receiver(@chunks), boundary => $b, max_request_body => 32);
    like dies {
        my $p = $s->next->get; $p && $p->stream_to(sub { Future->done })->get; $s->next->get;
    }, qr/max_request_body/, 'aggregate cap enforced';
};
subtest 'missing boundary is rejected at construction' => sub {
    like dies { PAGI::Request::MultipartStream->new(receive => sub {}, boundary => '') },
        qr/boundary is required/, 'empty boundary croaks';
};

done_testing;
