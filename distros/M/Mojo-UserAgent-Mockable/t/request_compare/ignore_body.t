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
$r1->body('Zip zop zoom');
my $r2 = $r1->clone;
$r2->body('Foo bar baz');

my $compare = Mojo::UserAgent::Mockable::Request::Compare->new( ignore_body => 1 );
ok $compare->compare( $r1, $r2 ), 'Requests equivalent when "ignore_body" set';
is $compare->compare_result, '', 'Compare result correct';

my $compare2 = Mojo::UserAgent::Mockable::Request::Compare->new( ignore_body => 0 );
ok !$compare2->compare( $r1, $r2 ), 'Requests not equivalent when "ignore_body" not set';
is $compare2->compare_result, 'Body mismatch', 'Compare result correct';

done_testing;
