use 5.014;
use Test::Most;
use Mojo::Message::Request;
use Mojo::Parameters;
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
$r1->url(Mojo::URL->new(q{https://random.org/integers/?num=5&min=0&max=1000000000&col=1&base=10&format=plain&quux=alpha})); 
subtest 'Equivalent URL, different query order' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r2 = $r1->clone;
    $r2->url->query(Mojo::Parameters->new);
    my $new_url = $r2->url->to_abs->to_string . '?'; 
    
    # Since Mojo::URL isn't going to respect the order of parameters passed, and I can't 
    # count on the order of parameters always being different (since perl's hash key ordering
    # algorithm is randomized) I have to do it the hard way.
    my %query;
    for my $param (sort keys %{$r1->url->query->to_hash}) {
        my $val = $r1->url->query->param($param);
        $new_url .= qq{$param=$val&};
    } 
    $new_url =~ s/&$//;
    $r2->url($new_url);
    $r2->finish;

    ok $compare->compare( $r1, $r2 ), 'Equivalent requests are equivalent';
    is $compare->compare_result, '', 'Compare result is empty';
};

subtest 'Equivalent URL, different order of values for list param' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r2 = $r1->clone;
    my $r3 = $r1->clone;

    $r2->url->query->append(foo => ['baz','boo']);
    $r3->url->query->append(foo => ['boo','baz']);
    ok $compare->compare( $r2, $r3 ), 'Equivalent requests are equivalent';
    is $compare->compare_result, '', 'Compare result is empty';
};

subtest 'Different query' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r2 = $r1->clone;
    $r2->url->query(quux => 'beta');

    ok !$compare->compare( $r1, $r2 ), 'Different requests differ';
    like $compare->compare_result, qr/^URL query mismatch/, 'Compare result correct';
};

subtest 'Extra params in query' => sub {
    my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
    my $r2 = $r1->clone;
    $r2->url->query({ quuy => 'beta' });

    ok !$compare->compare( $r1, $r2 ), 'Different requests differ';
    like $compare->compare_result, qr/^URL query mismatch/, 'Compare result correct';
};

# FIXME: The tests are failing here but it's artificial. Something about the base and to_abs killing things
subtest 'Other URL bits' => sub {
    for my $attr (qw/scheme userinfo host port fragment path/) {
        my $compare = Mojo::UserAgent::Mockable::Request::Compare->new;
        
        subtest qq{Different $attr} => sub {
            my $r2 = $r1->clone;
            $r2->url->$attr('Apfelkraft');

            ok !$compare->compare( $r1, $r2 ), 'Different requests differ';
            like $compare->compare_result, qr/^URL $attr mismatch/, 'Compare result correct';
        };
    }
};

done_testing;
