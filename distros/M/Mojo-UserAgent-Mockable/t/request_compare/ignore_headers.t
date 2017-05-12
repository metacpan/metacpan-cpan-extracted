use 5.014;
use Test::Most;
use Mojo::Message::Request;
use Mojo::UserAgent::Mockable::Request::Compare;

my $r1 = Mojo::Message::Request->new;
$r1->parse(qq{GET /integers/?num=5&min=0&max=1000000000&col=1&base=10&format=plain&quux=alpha HTTP/1.1\cM\cJ});
$r1->parse(qq{Content-Length: 0\cM\cJ});
$r1->parse(qq{Accept-Encoding: gzip\cM\cJ});
$r1->parse(qq{User-Agent: kit.peters\@broadbean.com\cM\cJ});
$r1->parse(qq{Connection: keep-alive\cM\cJ});
$r1->parse(qq{X-Day: 8661\cM\cJ});
$r1->parse(qq{X-Alpha: Foo\cM\cJ});
$r1->parse(qq{X-Beta: Foo\cM\cJ});
$r1->parse(qq{X-Gamma: Foo\cM\cJ});
$r1->parse(qq{X-Delta: Foo\cM\cJ});
$r1->parse(qq{Host: www.random.org\cM\cJ\cM\cJ});
$r1->finish;

subtest all => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new( ignore_headers => 'all' );
        my $r2 = $r1->clone;
        for my $header ( @{ $r2->headers->names } ) {
        if ( $header =~ /^X/ ) {
            $r2->headers->remove($header);
        }
    }
    ok $compare->compare( $r1, $r2 ), 'Requests are equivalent save for headers';
    is $compare->compare_result, '', 'Compare result correct';

    my $r3 = $r2->clone;
    $r3->url->host('www.randoom.org');
    ok !$compare->compare( $r1, $r3 ), 'Different requests differ';
    like $compare->compare_result, qr/^URL host mismatch/, 'Compare result correct';
};

subtest 'single header' => sub {
    for my $header ( @{ $r1->headers->names } ) {
        my $compare = Mojo::UserAgent::Mockable::Request::Compare->new( ignore_headers => [$header] );
        my $r2 = $r1->clone;
        $r2->headers->remove($header);

        ok $compare->compare( $r1, $r2 ), qq{Requests equivalent save for "$header" header};
        is $compare->compare_result, '', 'Compare result correct';

        my $r3 = $r2->clone;
        $r3->url->host('www.randoom.org');
        ok !$compare->compare( $r1, $r3 ), 'Different requests differ';
        like $compare->compare_result, qr/^URL host mismatch/, 'Compare result correct';
    }
};

done_testing;
