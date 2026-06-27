use strict; use warnings;
use Test2::V0;
use Future;
use PAGI::Request;

my $b = 'BOUND';
sub mp_body {
    my ($bd,@rows)=@_; my $s='';
    for my $r (@rows){ my ($n,$f,$ct,$d)=@$r; my $cd=qq{form-data; name="$n"}; $cd.=qq{; filename="$f"} if defined $f;
        $s.="--$bd\r\nContent-Disposition: $cd\r\n"; $s.="Content-Type: $ct\r\n" if defined $ct; $s.="\r\n$d\r\n"; }
    return $s."--$bd--\r\n";
}
my $body = mp_body($b, ['doc','a.txt','text/plain','hi']);

sub req {
    my @chunks = @_;
    my $scope = { type => 'http', method => 'POST',
        headers => [['content-type', "multipart/form-data; boundary=$b"]] };
    my $recv  = sub { my $c = shift @chunks;
        Future->done(defined $c ? {type=>'http.request',body=>$c,more=>(@chunks?1:0)} : {type=>'http.disconnect'}) };
    return PAGI::Request->new($scope, $recv);
}

subtest 'multipart_stream streams a part without spooling' => sub {
    my $stream = req($body)->multipart_stream;
    my $p = $stream->next->get;
    is $p->filename, 'a.txt', 'got the file part';
    is $p->value->get, 'hi', 'streamed its bytes';
};

subtest 'non-multipart request croaks' => sub {
    my $r = PAGI::Request->new(
        { type=>'http', method=>'POST', headers=>[['content-type','application/json']] },
        sub { Future->done({type=>'http.disconnect'}) });
    like dies { $r->multipart_stream }, qr/multipart/i, 'non-multipart croaks';
};

subtest 'consumed-once latch, both directions' => sub {
    my $r1 = req($body); $r1->multipart_stream;
    like dies { $r1->form_params->get }, qr/consumed|stream|already/i, 'form_params after multipart_stream croaks';

    my $r2 = req($body); $r2->form_params->get;
    like dies { $r2->multipart_stream }, qr/consumed|already/i, 'multipart_stream after form_params croaks';

    my $r3 = req($body); $r3->multipart_stream;
    like dies { $r3->multipart_stream }, qr/consumed|already/i, 'second multipart_stream croaks';
};

done_testing;
