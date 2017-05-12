use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'Plack::Session';
use Plack::Test;
use Plack::Builder;

my $COMMIT;
my $form_html = <<'...';
<!doctype html>
<html>
<form method="post" action="/do">
    <input type="text" name="body" />
    <input type="submit" name="post" />
</form>
</html>
...

{
    package MyApp;
    use Nephia plugins => [
        'CSRFDefender' => { no_validate_hook => 1 },
        'PlackSession',
        'Dispatch',
    ];

    app {
        get '/form' => sub {
            return [
                200, [], [$form_html],
            ];
        };
        post '/do' => sub {
            $COMMIT++;
            return redirect('/finished');
        };
        post '/do2' => sub {
            if (validate_csrf()) {
                return [
                    200, [], ['valid token'],
                ];
            } else {
                return [
                    403, [], ['denied'],
                ];
            }
        };
        get '/finished' => sub {
            return [
                200, [], ['finished'],
            ]
        };
        get '/get_csrf_defender_token' => sub {
            return [
                200, [], [get_csrf_defender_token()],
            ]
        };
    }
}

my $app = builder {
    enable 'Session';
    MyApp->run();
};

$COMMIT = 0;
subtest 'success case' => sub {
    my $mech = Test::WWW::Mechanize::PSGI->new(
        app => $app,
    );
    $mech->get_ok('http://localhost/form');
    $mech->content_like(qr[<input type="hidden" name="csrf_token" value="[a-zA-Z0-9_]{32}" />]);
    $mech->submit_form(form_number => 1, fields => {body => 'yay'});
    is $mech->base, 'http://localhost/finished';
    is $COMMIT, 1;
};

$COMMIT = 0;
subtest 'there is no validation' => sub {
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/do'));
            is $res->code, '303';
            is $COMMIT, 1;
        };
};

$COMMIT = 0;
subtest 'but you can validate manually' => sub {
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/do2'));
            is $res->code, '403';
            is $COMMIT, 0;
        };
};

subtest 'get_csrf_defender_token' => sub {
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(GET => 'http://localhost/get_csrf_defender_token'));
            is $res->code, '200';
            ::like $res->content(), qr{^[a-zA-Z0-9_]{32}$};
        };
};

done_testing;
