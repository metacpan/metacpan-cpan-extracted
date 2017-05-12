use HTTP::Request::Common;
use Plack::Builder;
use Plack::Request;
use Plack::Session;
use Plack::Session::State::URI;
use Plack::Session::Store::File;
use Plack::Test;
use Test::More;
use File::Temp;

my $app = builder {
    enable 'Plack::Middleware::Session',
        store => Plack::Session::Store::File->new(
            dir => File::Temp->newdir( 'XXXXXXXX', TMPDIR => 1, CLEANUP => 1, TEMPDIR => 1 )
        ),
        state => Plack::Session::State::URI->new(
            session_key => 'sid'
        );
    sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $session = Plack::Session->new($env);

        if (defined $req->param('data')) {
            $session->set('data', $req->param('data'));
        }

        my $data = $session->get('data');

        $data = '' unless defined $data;

        if (my $url = $req->param('url')) {
            [
                302,
                ['Location', $url],
                ['']
            ];
        } else {
            [
                200,
                ['Content-Type', 'text/html; charset="UTF-8"'],
                [qq{<a href="/?foo=1">ok</a><p>$data</p>}]
            ]
        }
    }
};

test_psgi $app, sub {
    my $cb = shift;

    my $data = 'param1';

    my $res = $cb->(GET '/?data=' . $data);
    my ($sid) = $res->content=~m|sid=(\w+)|;
    ok $sid, 'sid generate.';

    my $res2 = $cb->(GET '/?sid=' . $sid);
    my ($sid2) = $res2->content=~m|sid=(\w+)|;
    is $sid, $sid2, 'sid equal.';

    my ($data2) = $res2->content=~m|<p>(.*)</p>|;
    is $data, $data2, 'data equal.';

    my $res3 = $cb->(GET '/?url=http://example.org/&sid=' . $sid);
    my ($sid3) = $res3->header('Location')=~m|sid=(\w+)|;
    is $sid, $sid3, 'sid equal. (redirect)';

    my $res4 = $cb->(GET '/');
    my ($sid4) = $res4->content=~m|sid=(\w+)|;
    isnt $sid, $sid4, 'new sid generate.'
};

done_testing();