#!/usr/bin/env perl

use v5.38;
use experimental 'class';

use PAGI::FastAPI;
use Future::AsyncAwait;

my $app    = PAGI::FastAPI->new;
my $SECRET = 'test-csrf-secret-12345';

$app->add_middleware('PAGI::Middleware::Session', secret => $SECRET);
$app->enable_csrf(secret => $SECRET);

$app->get('/', handler => async sub ($c) {
    # enable_csrf() below defaults to enforce => 'header', so the token
    # must travel as an X-CSRF-Token request header, not a form field.
    # A plain <form method="POST"> submission cannot add a custom header,
    # so this demo submits via fetch() instead, reading the CSRF cookie
    # PAGI::Middleware::CSRF sets (readable by JS, i.e. not HttpOnly, by
    # design - that's the "double submit cookie" pattern) and mirroring
    # it into the X-CSRF-Token header.
    my $html = qq{
        <!DOCTYPE html>
        <html>
        <body>
            <h2>CSRF Protection Demo</h2>
            <form id="demo-form">
                <input type="text" name="data" value="Hello World">
                <button type="submit">Submit Form</button>
            </form>
            <pre id="result"></pre>
            <script>
                function csrfCookie() {
                    const m = document.cookie.match(/(?:^|; )csrf_token=([^;]+)/);
                    return m ? decodeURIComponent(m[1]) : '';
                }

                document.getElementById('demo-form').addEventListener('submit', async (e) => {
                    e.preventDefault();
                    const res = await fetch('/submit', {
                        method:  'POST',
                        headers: {
                            'Content-Type':  'application/json',
                            'X-CSRF-Token':  csrfCookie(),
                        },
                        body: JSON.stringify({ data: e.target.data.value }),
                    });
                    document.getElementById('result').textContent =
                        res.status + ' ' + JSON.stringify(await res.json());
                });
            </script>
        </body>
        </html>
    };

    return $c->html($html);
});

$app->post('/submit', handler => async sub ($c) {
    return { status => 'ok', message => 'Data saved' };
});

$app->to_app;
