use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Util qw(encode trim);
use Data::Dumper;

$ENV{MOJO_MAIL_TEST} = 1;
#$ENV{MOJO_LOG_LEVEL} = 'debug';

plugin 'EmailMailer' => {
    from     => 'sender-test@example.org',
    how      => 'sendmail',
    howargs  => { sendmail => '/usr/sbin/sendmail' }
};

get '/empty' => sub {
    my $self = shift;

    $self->render(json => { ok => 1, mail => $self->send_mail });
};

get '/html' => sub {
    my $self = shift;

    my $mail = $self->send_mail(
        to      => 'test@example.org',
        subject => 'Test letter 🤔',
        html    => "<p>Hello! 👋</p>"
    );

    $self->render(json => { ok => 1, headers => $self->app->get_headers_from_mail($mail), bodys => $self->app->get_bodys_from_mail($mail) });
};

get '/text' => sub {
    my $self = shift;

    my $mail = $self->send_mail(
        to      => '"Jane Doe" <test@example.org>, "Jane Doe 2" test2@example.org',
        cc      => '"Jane Doe 3" <test3@example.org>, Jane Doe 4 test4@example.org',
        bcc     => 'test4@example.org',
        subject => 'Test letter 🤔',
        text    => 'Hello! 👋',
    );

    $self->render(json => { ok => 1, headers => $self->app->get_headers_from_mail($mail), bodys => $self->app->get_bodys_from_mail($mail, 1) });
};

get '/attach' => sub {
    my $self = shift;

    my $mail = $self->send_mail(
        to          => 'test@example.org',
        subject     => 'Test attach',
        charset     => 'windows-1251',
        text        => 'This is a multi-part message in MIME format.',
        attachments => [
            {
                ctype    => 'application/pdf',
                name     => 'crash.pdf',
                encoding => 'base64',
                content  => 'binary data binary data binary data binary data binary data'
            }
        ],
        'X-My-Header' => 'Mojolicious',
        'X-Mailer'    => 'My mail client'
    );

    $self->render(json => { ok => 1, headers => $self->app->get_headers_from_mail($mail), bodys => $self->app->get_bodys_from_mail($mail) });
};

get '/render' => sub {
    my $self = shift;

    my $mail = $self->send_mail(
        to      => 'test@example.org',
        subject => 'Test render',
        text    => $self->render_mail('render_text', who => 'my friend'),
        html    => $self->render_mail('render', who => 'my friend'),
    );

    $self->render(json => { ok => 1, headers => $self->app->get_headers_from_mail($mail), bodys => $self->app->get_bodys_from_mail($mail) });
};

get '/multi' => sub {
    my $self = shift;

    my $mails = $self->send_multiple_mail(
        mail => {
            subject => 'Test multi',
            text    => 'This is a mail send multiple times.'
        },
        send => [
            { to => 'test0@example.org' },
            { to => 'test1@example.org', subject => 'Test multi, subject override' },
            { to => 'test2@example.org', html    => '<p>Test html in multi message</p>' }
        ]
    );

    my @results;
    my $i = 0;
    for my $mail (@{$mails}) {
        my $one_part = ($i < 2) ? 1 : 0;
        push @results, { headers => $self->app->get_headers_from_mail($mail, $i), bodys => $self->app->get_bodys_from_mail($mail, $one_part, $i++) };
    }

    $self->render(json => { ok => 1, mails => \@results });
};

get '/multi_fail_1' => sub {
    my $self = shift;

    my $mails = $self->send_multiple_mail(
        mail => {
            subject => 'Test multi',
            text    => 'This is a mail send multiple times.'
        }
    );

    $self->render(json => { ok => 1, mails => $mails });
};

get '/multi_fail_2' => sub {
    my $self = shift;

    my $mails = $self->send_multiple_mail(
        send => [
            { to => 'test0@example.org' },
            { to => 'test1@example.org', subject => 'Test multi, subject override' },
            { to => 'test2@example.org', html    => '<p>Test html in multi message</p>' }
        ]
    );

    $self->render(json => { ok => 1, mails => $mails });
};

helper get_headers_from_mail => sub {
    my $c     = shift;
    my $mail  = shift;
    my $multi = shift // 0;
    return $mail->{transport}->{deliveries}->[$multi]->{email}->[0]->{header}->{headers};
};

helper get_bodys_from_mail => sub {
    my $c        = shift;
    my $mail     = shift;
    my $one_part = shift // 0;
    my $multi    = shift // 0;

    my $bodys = {};
    if ($one_part) {
        my $type    = $mail->{transport}->{deliveries}->[$multi]->{email}->[0]->{ct}->{composite};
        my $value   = $mail->{transport}->{deliveries}->[$multi]->{email}->[0]->{body_raw};
        my $headers = $mail->{transport}->{deliveries}->[$multi]->{email}->[0]->{header}->{headers};
        $bodys->{$type} = {
            content => $value,
            headers => $headers
        };
    } else {
        my $parts = $mail->{transport}->{deliveries}->[$multi]->{email}->[0]->{parts};
        if (scalar @{$parts} && scalar @{$parts->[0]->{parts}}) {
            $parts = $parts->[0]->{parts};
        }
        for my $part (@{$parts}) {
            $bodys->{$part->{ct}->{composite}} = {
                content => $part->{body_raw},
                headers => $part->{header}->{headers}
            };
        }
    }
    return $bodys;
};


### Begin tests
## /empty
#
my $t = Test::Mojo->new;

$t->get_ok('/empty')
  ->status_is(200)
  ->json_is({ ok => 1, mail => 0 });

## /html
#
my $json = $t->get_ok('/html')
             ->status_is(200)
             ->json_is('/ok' => 1)
             ->json_has('/headers')
             ->json_has('/bodys')
             ->tx->res->json;

my $h = _to_mojo_headers($json->{headers});
my $xmailer = join ' ', 'Mojolicious',  $Mojolicious::VERSION, 'Mojolicious::Plugin::EmailMailer', $Mojolicious::Plugin::EmailMailer::VERSION, '(Perl)';
my $messageid = qr/\d+\.[a-zA-Z0-9]+\.\d+\@.*/;

$t->test('is',   $h->header('Subject'),                   '=?UTF-8?B?VGVzdCBsZXR0ZXIg8J+klA==?=', '/html, good Subject header');
$t->test('is',   $h->header('From'),                      'sender-test@example.org',              '/html, good From header');
$t->test('is',   $h->header('To'),                        'test@example.org',                     '/html, good To header');
$t->test('is',   $h->header('MIME-Version'),              '1.0',                                  '/html, good MIME-Version header');
$t->test('like', $h->header('Content-Type'),              qr@^multipart\/mixed; boundary=@,       '/html, good Content-Type header');
$t->test('is',   $h->header('Content-Transfer-Encoding'), '7bit',                                 '/html, good Content-Transfer-Encoding header');
$t->test('is',   $h->header('X-Mailer'),                   $xmailer,                              '/html, good X-Mailer header');
$t->test('like', $h->header('Message-ID'),                 $messageid,                            '/html, good Content-Type header');

$t->test('is', t($json->{bodys}->{plain}->{content}), 'Hello! =F0=9F=91=8B',         '/html, plain text body');
$t->test('is', t($json->{bodys}->{html}->{content}),  '<p>Hello! =F0=9F=91=8B</p>=', '/html, html body');

## /text
#
$json = $t->get_ok('/text')
          ->status_is(200)
          ->json_is('/ok' => 1)
          ->json_has('/headers')
          ->json_has('/bodys')
          ->tx->res->json;

$h = _to_mojo_headers($json->{headers});

$t->test('is',   $h->header('Subject'),                   '=?UTF-8?B?VGVzdCBsZXR0ZXIg8J+klA==?=', '/text, good Subject header');
$t->test('is',   $h->header('From'),                      'sender-test@example.org',              '/text, good From header');
$t->test('is',   $h->header('To'),                        '"Jane Doe" <test@example.org>',        '/text, removed bad address in To header');
$t->test('is',   $h->header('Cc'),                        '"Jane Doe 3" <test3@example.org>',     '/text, removed bad address in Cc header');
$t->test('is',   $h->header('MIME-Version'),              '1.0',                                  '/text, good MIME-Version header');
$t->test('is',   $h->header('Content-Type'),              'text/plain; charset=UTF-8',            '/text, good Content-Type header');
$t->test('is',   $h->header('Content-Transfer-Encoding'), 'quoted-printable',                     '/text, good Content-Transfer-Encoding header');
$t->test('is',   $h->header('X-Mailer'),                   $xmailer,                              '/text, good X-Mailer header');
$t->test('like', $h->header('Message-ID'),                 $messageid,                            '/text, good Content-Type header');

$t->test('is', t($json->{bodys}->{plain}->{content}), 'Hello! =F0=9F=91=8B=', '/text, plain text body');
$t->test('is', $json->{bodys}->{html},                 undef,      '/text, no html part');

## /attach
#
$json = $t->get_ok('/attach')
          ->status_is(200)
          ->json_is('/ok' => 1)
          ->json_has('/headers')
          ->json_has('/bodys')
          ->tx->res->json;

$h = _to_mojo_headers($json->{headers});

$t->test('is',   $h->header('MIME-Version'),              '1.0',                          '/attach, good MIME-Version header');
$t->test('like', $h->header('Content-Type'),            qr@^multipart\/mixed; boundary=@, '/attach, good Content-Type header');
$t->test('is',   $h->header('Content-Transfer-Encoding'), '7bit',                         '/attach, good Content-Transfer-Encoding header');
$t->test('is',   $h->header('X-My-Header'),               'Mojolicious',                  '/attach, good X-My-Header header');
$t->test('is',   $h->header('X-Mailer'),                  'My mail client',               '/attach, good X-Mailer header');
$t->test('is',   $h->header('From'),                      'sender-test@example.org',      '/attach, good From header');
$t->test('is',   $h->header('Subject'),                   'Test attach',                  '/attach, good Subject header');
$t->test('is',   $h->header('To'),                        'test@example.org',             '/attach, good To header');
$t->test('like', $h->header('Message-ID'),                 $messageid,                    '/attach, good Content-Type header');

$h = _to_mojo_headers($json->{bodys}->{plain}->{headers});
$t->test('is', t($json->{bodys}->{plain}->{content}), 'This is a multi-part message in MIME format.=', '/attach, plain text body');
$t->test('is', $h->header('MIME-Version'),            '1.0',                                          '/attach, good MIME-Version header for plain text');
$t->test('is', $json->{bodys}->{html},                 undef,                                         '/attach, no html part');

$h = _to_mojo_headers($json->{bodys}->{pdf}->{headers});
$t->test('is',   $h->header('MIME-Version'),              '1.0',                                  '/attach, good MIME-Version header for pdf attachment');
$t->test('is',   $h->header('Content-Transfer-Encoding'), 'base64',                               '/attach, good Content-Transfer-Encoding header for pdf attachment');
$t->test('like', $h->header('Content-Type'),            qr@application/pdf; name="?crash\.pdf"?@, '/attach, good Content-Type header for pdf attachment');
$t->test('like', $h->header('Content-Disposition'),     qr@attachment; filename="?crash\.pdf"?@,  '/attach, good Content-Disposition header for pdf attachment');

$t->test('like', t($json->{bodys}->{pdf}->{content}), qr@YmluYXJ5IGRhdGEgYmluYXJ5IGRhdGEgYmluYXJ5IGRhdGEgYmluYXJ5IGRhdGEgYmluYXJ5IGRh@, '/attach, pdf attachment body');

## /render
#
$json = $t->get_ok('/render')
          ->status_is(200)
          ->json_is('/ok' => 1)
          ->json_has('/headers')
          ->json_has('/bodys')
          ->tx->res->json;

$h = _to_mojo_headers($json->{headers});

$t->test('is',   $h->header('From'),                      'sender-test@example.org',        '/render, good From header');
$t->test('is',   $h->header('Subject'),                   'Test render',                    '/render, good Subject header');
$t->test('is',   $h->header('To'),                        'test@example.org',               '/render, good To header');
$t->test('is',   $h->header('MIME-Version'),              '1.0',                            '/render, good MIME-Version header');
$t->test('like', $h->header('Content-Type'),              qr@^multipart\/mixed; boundary=@, '/render, good Content-Type header');
$t->test('is',   $h->header('Content-Transfer-Encoding'), '7bit',                           '/render, good Content-Transfer-Encoding header');
$t->test('is',   $h->header('X-Mailer'),                   $xmailer,                        '/render, good X-Mailer header');
$t->test('like', $h->header('Message-ID'),                 $messageid,                      '/render, good Content-Type header');

$t->test('is', t($json->{bodys}->{plain}->{content}), 'Well, hello my friend. How are you?',  '/render, plain text body');
$t->test('is', t($json->{bodys}->{html}->{content}),  '<p>Hello my friend! =F0=9F=91=8B</p>', '/render, html body');

## /multi
#
$json = $t->get_ok('/multi')
          ->status_is(200)
          ->json_is('/ok' => 1)
          ->json_has('/mails')
          ->tx->res->json;

my $i = 0;
for my $mail (@{$json->{mails}}) {
    my $subject = ($i != 1) ? 'Test multi' : 'Test multi, subject override';
    my $to      = 'test'.$i.'@example.org';

    $h = _to_mojo_headers($mail->{headers});

    $t->test('is',   $h->header('MIME-Version'), '1.0',                     '/multi'.$i.', good MIME-Version header');
    $t->test('is',   $h->header('From'),         'sender-test@example.org', '/multi'.$i.', good From header');
    $t->test('is',   $h->header('Subject'),       $subject,                 '/multi'.$i.', good Subject header');
    $t->test('is',   $h->header('To'),            $to,                      '/multi'.$i.', good To header');
    $t->test('is',   $h->header('X-Mailer'),      $xmailer,                 '/multi'.$i.', good X-Mailer header');
    $t->test('like', $h->header('Message-ID'),    $messageid,               '/multi, good Content-Type header');

    if ($i < 2) {
        $t->test('is', t($mail->{bodys}->{plain}->{content}), 'This is a mail send multiple times.=', '/multi'.$i.', plain text body');
        $t->test('is', $mail->{bodys}->{html}, undef, '/multi'.$i.', no html part');

        $h = _to_mojo_headers($mail->{bodys}->{plain}->{headers});
        $t->test('is', $h->header('Content-Type'),              'text/plain; charset=UTF-8', '/multi'.$i.', good Content-Type header');
        $t->test('is', $h->header('Content-Transfer-Encoding'), 'quoted-printable',          '/multi'.$i.', good Content-Transfer-Encoding header');
    } else {
        $t->test('is', t($mail->{bodys}->{plain}->{content}), 'This is a mail send multiple times.=', '/multi'.$i.', plain text body');
        $t->test('is', t($mail->{bodys}->{html}->{content}),  '<p>Test html in multi message</p>=',   '/multi'.$i.', html body');

        $h = _to_mojo_headers($mail->{bodys}->{plain}->{headers});
        $t->test('is', $h->header('Content-Type'), 'text/plain; charset=UTF-8', '/multi'.$i.', good Content-Type header');
    }
    $i++;
}

## /multi_fail_1
#
$json = $t->get_ok('/multi_fail_1')
          ->status_is(200)
          ->json_is({ ok => 1, mails => 0 })
          ->tx->res->json;

## /multi_fail_2
#
$json = $t->get_ok('/multi_fail_2')
          ->status_is(200)
          ->json_is({ ok => 1, mails => 0 })
          ->tx->res->json;

done_testing;

sub _to_mojo_headers {
    my $headers = shift;

    my $h = Mojo::Headers->new;

    for (my $i = 0; $i < scalar @{$headers}; $i++) {
        my $name  = $headers->[$i++];
        my $value = (ref $headers->[$i] eq 'ARRAY') ? $headers->[$i]->[0] : $headers->[$i];
        $h->add($name => $value);
    }

    return $h;
};

#sub e {
#    return encode('UTF-8', shift);
#}
#
sub t {
    return trim(shift);
}

__DATA__

@@ render.mail.ep
<p>Hello <%= $who %>! 👋</p>

@@ render_text.mail.ep
Well, hello <%= $who %>. How are you?
