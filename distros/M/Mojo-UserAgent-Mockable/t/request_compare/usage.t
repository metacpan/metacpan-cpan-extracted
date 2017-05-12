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
$r1->parse(qq{Host: www.random.org\cM\cJ\cM\cJ});
$r1->finish;

subtest 'Equivalent requests' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r2 = $r1->clone;

    ok $compare->compare( $r1, $r2 ), 'Equivalent requests are equivalent';
    is $compare->compare_result, '', 'Compare result is empty';
};

subtest 'Different method' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r2 = $r1->clone->method('POST');
    
    ok !$compare->compare( $r1, $r2 ), 'Different requests differ';
    like $compare->compare_result, qr/^Method mismatch/, 'Compare result correct';
};

subtest 'Different body' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r1 = $r1->clone;
    $r1->body('Nac Mac Feegle!');
    my $r2 = $r1->clone;
    $r2->body('Zip zop zoobity bop');
    
    ok !$compare->compare( $r1, $r2 ), 'Different requests differ';
    is $compare->compare_result, q{Body mismatch}, 'Compare result correct';
};

subtest 'Different Body 2' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r2 = $r1->clone;
    $r2->body('Zip zop zoobity bop');
    
    ok !$compare->compare( $r1, $r2 ), 'Different requests differ';
    is $compare->compare_result, q{Body mismatch}, 'Compare result correct';
};

subtest 'Missing header' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r2 = $r1->clone;
    $r2->headers->remove('X-Day');
    
    ok !$compare->compare( $r1, $r2 ), 'Different requests differ';
    is $compare->compare_result, q{Header count mismatch}, 'Compare result correct';
};

subtest 'Extra header' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r2 = $r1->clone;
    $r2->headers->add('X-Clacks-Overhead' => 'GNU Terry Pratchett');

    ok !$compare->compare( $r1, $r2 ), 'Different requests differ';
    is $compare->compare_result, q{Header count mismatch}, 'Compare result correct';
};

subtest 'Different header' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r2 = $r1->clone;
    $r2->headers->user_agent('tazendra.lavode@dzurmountain.com');
    
    ok !$compare->compare( $r1, $r2 ), 'Different requests differ';
    like $compare->compare_result, qr/^Header "[A-Za-z0-9-]+" mismatch/, 'Compare result correct';
};

subtest 'Blank header, same count' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    
    my $r1 = Mojo::Message::Request->new;
    $r1->parse(qq{GET /integers/?num=5&min=0&max=1000000000&col=1&base=10&format=plain&quux=alpha HTTP/1.1\cM\cJ});
    $r1->parse(qq{Content-Length: 0\cM\cJ});
    $r1->parse(qq{Accept-Encoding: gzip\cM\cJ});
    $r1->parse(qq{User-Agent: kit.peters\@broadbean.com\cM\cJ});
    $r1->parse(qq{Connection: keep-alive\cM\cJ});
    $r1->parse(qq{X-Day: 8661\cM\cJ});
    $r1->parse(qq{X-Foo:\cM\cJ});
    $r1->parse(qq{Host: www.random.org\cM\cJ\cM\cJ});
    $r1->finish;
    
    my $r2 = Mojo::Message::Request->new;
    $r2->parse(qq{GET /integers/?num=5&min=0&max=1000000000&col=1&base=10&format=plain&quux=alpha HTTP/1.1\cM\cJ});
    $r2->parse(qq{Content-Length: 0\cM\cJ});
    $r2->parse(qq{Accept-Encoding: gzip\cM\cJ});
    $r2->parse(qq{User-Agent: kit.peters\@broadbean.com\cM\cJ});
    $r2->parse(qq{Connection: keep-alive\cM\cJ});
    $r2->parse(qq{X-Day: 8661\cM\cJ});
    $r2->parse(qq{X-Bar:\cM\cJ});
    $r2->parse(qq{Host: www.random.org\cM\cJ\cM\cJ});
    $r2->finish;

    ok !$compare->compare( $r1, $r2 ), 'Different requests differ';
    like $compare->compare_result, qr/^Header "[A-Za-z0-9-]+" mismatch/, 'Compare result correct';
};

done_testing;
