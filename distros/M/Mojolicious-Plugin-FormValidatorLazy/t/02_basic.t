use strict;
use warnings;
use utf8;
use Test::Mojo;
use Mojolicious::Lite;
use Test::More tests => 179;
use Mojo::JSON qw(decode_json);
use Mojo::Util qw{hmac_sha1_sum b64_decode};

my $TERM_ACTION             = 0;
my $TERM_SCHEMA             = 1;
my $TERM_PROPERTIES         = 'properties';
my $TERM_REQUIRED           = 'required';
my $TERM_MAXLENGTH          = 'maxLength';
my $TERM_MIN_LENGTH         = 'minLength';
my $TERM_OPTIONS            = 'options';
my $TERM_PATTERN            = 'pattern';
my $TERM_MIN                = 'maximam';
my $TERM_MAX                = 'minimum';
my $TERM_TYPE               = 'type';
my $TERM_ADD_PROPS          = 'additionalProperties';
my $TERM_NUMBER             = 'number';

my $namespace = 'FormValidatorLazy';

plugin form_validator_lazy => {
    namespace => $namespace,
    action => ['/receptor1', '/receptor3'],
    blackhole => sub {
        $_[0]->res->code(400);
        $_[0]->render(text => $_[1]);
    },
};

get '/test1' => sub {
    shift->render('test1');
};

post '/receptor1' => sub {
    my $c = shift;
    is $c->tx->req->param($namespace. '-token'), undef, 'token is cleaned up';
    $c->render(text => 'post completed');
};

post '/receptor2' => sub {
    shift->render(text => 'post completed');
};

post '/receptor3' => sub {
    shift->render(text => 'post completed');
};

{
    no strict 'refs';
    *{__PACKAGE__. '::deserialize'} = \&Mojolicious::Plugin::FormValidatorLazy::deserialize;
    *{__PACKAGE__. '::serialize'} = \&Mojolicious::Plugin::FormValidatorLazy::serialize;
    *{__PACKAGE__. '::unsign'} = \&Mojolicious::Plugin::FormValidatorLazy::unsign;
}

my $t = Test::Mojo->new;
my $dom;

$t->get_ok('/test1');
$t->status_is(200);

my $sessid = extract_session($t)->{$namespace. '-sessid'};

my $token = $t->tx->res->dom->find('form')->[0]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES => {
                bar => {
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
                baz => {
                    $TERM_OPTIONS => ["bazValue"],
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
                foo => {
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
                yada => {
                    $TERM_OPTIONS => ["yadaValue"],
                },
                btn => {
                    $TERM_OPTIONS => ["send", "send2"],
                },
                btn3 => {
                    $TERM_OPTIONS => ["send3"],
                },
            },
        },
    }, 'right schema';
}

my $token2 = $t->tx->res->dom->find('form')->[1]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token2, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES => {
                "foo" => {
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
            },
        },
    }, 'right schema';
}

my $token3 = $t->tx->res->dom->find('form')->[2]->at("input[name=$namespace-schema]");
is $token3, undef;

my $token4 = $t->tx->res->dom->find('form')->[3]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token4, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES=> {
                "foo" => {
                    $TERM_OPTIONS => ["fooValue1", "fooValue2", "fooValue3", "fooValue4"],
                },
            },
        },
    }, 'right schema';
}

my $token5 = $t->tx->res->dom->find('form')->[4]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token5, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES=> {
                foo => {
                    $TERM_OPTIONS => ["fooValue1","fooValue2","fooValue3","fooValue4"],
                },
            },
        },
    }, 'right schema';
}

my $token6 = $t->tx->res->dom->find('form')->[5]->at("input[name=$namespace-schema]");
is $token6, undef;

my $token7 = $t->tx->res->dom->find('form')->[6]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token7, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES=> {
                foo => {
                    $TERM_OPTIONS => ['', "fooValue1", "fooValue2"],
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
            },
        },
    }, 'right schema';
}

my $token8 = $t->tx->res->dom->find('form')->[7]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token8, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES=> {
                foo1 => {
                    $TERM_MAXLENGTH => 32,
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
                foo2 => {
                    $TERM_MAXLENGTH => 0,
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
                foo3 => {
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
            }
        },
    }, 'right schema';
}

my $token9 = $t->tx->res->dom->find('form')->[8]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token9, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES => {
                foo1 => {
                    $TERM_MIN_LENGTH => 1,
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
            },
        },
    }, 'right schema';
}

my $token10 = $t->tx->res->dom->find('form')->[9]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token10, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION   => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS     => Mojo::JSON->false,
            $TERM_PROPERTIES=> {
                foo => {
                    $TERM_OPTIONS => ['fooValue1', 'fooValue2', 'fooValue3'],
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
            },
        },
    }, 'right schema';
}

my $token11 = $t->tx->res->dom->find('form')->[10]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token11, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES=> {
                foo => {
                    $TERM_OPTIONS => [
                        '', 'fooValue1', 'fooValue2', 'a"b', 'a/b',
                    ],
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
            },
        },
    }, 'right schema';
}

my $token12 = $t->tx->res->dom->find('form')->[11]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token12, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES=> {
                foo => {
                    $TERM_PATTERN => "\\d\\d\\d",
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
            },
        },
    }, 'right schema';
}

my $token13 = $t->tx->res->dom->find('form')->[12]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token13, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES=> {
                foo => {
                    $TERM_MIN => "5",
                    $TERM_MAX => "10",
                    $TERM_TYPE => $TERM_NUMBER,
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
            },
        },
    }, 'right schema';
}

my $token14 = $t->tx->res->dom->find('form')->[13]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token14, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor3',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES => {},
        },
    }, 'right schema';
}

my $token15 = $t->tx->res->dom->find('form')->[14]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token15, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES => {
                foo => {
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
                bar => {
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
            },
        },
    }, 'right schema';
}

my $token16 = $t->tx->res->dom->find('form')->[15]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token16, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES => {
                foo => {
                    $TERM_OPTIONS => ['value1', 'value2'],
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
            },
        },
    }, 'right schema';
}

my $token17 = $t->tx->res->dom->find('form')->[16]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token17, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES => {
                foo => {
                    $TERM_OPTIONS => ['やったー'],
                },
            },
        },
    }, 'right schema';
}

my $token18 = $t->tx->res->dom->find('form')->[17]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token18, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES => {
                foo => {
                    $TERM_OPTIONS => ['fooValue1', 'fooValue2', 'fooValue3'],
                },
            },
        },
    }, 'right schema';
}

my $token19 = $t->tx->res->dom->find('form')->[18]->at("input[name=$namespace-schema]")->attr('value');
{
    my $schema = deserialize(unsign($token19, $sessid. app->secrets->[0]));
    is_deeply $schema, {
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_ADD_PROPS => Mojo::JSON->false,
            $TERM_PROPERTIES => {
                foo => {
                    $TERM_REQUIRED => Mojo::JSON->true,
                },
                bar => {
                },
                baz => {
                    $TERM_REQUIRED => Mojo::JSON->true,
                    $TERM_MIN_LENGTH => 1,
                },
            },
        },
    }, 'right schema';
}

$t->text_is("#jp", 'やったー');

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
    "$namespace-schema" => $token,
});
$t->status_is(200);
$t->content_is('post completed');

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
    yada => 'yadaValue',
    "$namespace-schema" => $token,
});
$t->status_is(200);
$t->content_is('post completed');

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
    btn => 'send',
    "$namespace-schema" => $token,
});
$t->status_is(200);
$t->content_is('post completed');

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
    btn => 'send2',
    "$namespace-schema" => $token,
});
$t->status_is(200);
$t->content_is('post completed');

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
    btn3 => 'send3',
    "$namespace-schema" => $token,
});
$t->status_is(200);
$t->content_is('post completed');

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
    btn3 => 'tampered',
    "$namespace-schema" => $token,
});
$t->status_is(400);
$t->content_like(qr{btn3});
$t->content_like(qr{tampered});

$t->post_ok('/receptor2' => form => {
    foo => 'fooValue',
    bar => 'barValue',
});
$t->status_is(200);
$t->content_is('post completed');

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
    biz => 'bizValue',
    "$namespace-schema" => $token,
});
$t->status_is(400);
$t->content_like(qr{biz});
$t->content_like(qr{injected});

$t->post_ok('/receptor1' => form => {
    bar => 'barValue',
    baz => 'bazValue',
    "$namespace-schema" => $token,
});
$t->status_is(400);
$t->content_like(qr{foo});

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue-tampered!',
    "$namespace-schema" => $token,
});
$t->status_is(400);
$t->content_like(qr{baz});
$t->content_like(qr{tampered});

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
    yada => 'yadaValue-tampered!',
    "$namespace-schema" => $token,
});
$t->status_is(400);
$t->content_like(qr{yada});
$t->content_like(qr{tampered});

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
});
$t->status_is(400);
$t->content_like(qr{schema}i);
$t->content_like(qr{missing});

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
    "$namespace-schema" => $token.'-tampered',
});
$t->status_is(400);
$t->content_like(qr{schema}i);
$t->content_like(qr{missing});

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    baz => 'bazValue',
    "$namespace-schema" => 'tampered-'. $token,
});
$t->status_is(400);
$t->content_like(qr{schema}i);
$t->content_like(qr{missing});

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    "$namespace-schema" => $token2,
});
$t->status_is(200);
$t->content_is('post completed');

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue',
    bar => 'barValue',
    "$namespace-schema" => $token2,
});
$t->status_is(400);
$t->content_like(qr{bar});
$t->content_like(qr{injected});

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue1',
    "$namespace-schema" => $token4,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue5',
    "$namespace-schema" => $token4,
});
$t->status_is(400);
$t->content_like(qr{foo});
$t->content_like(qr{tampered});

$t->post_ok('/receptor1' => form => {
    "$namespace-schema" => $token4,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    foo => ['fooValue1','invalid'],
    "$namespace-schema" => $token4,
});
$t->status_is(400);
$t->content_like(qr{foo});
$t->content_like(qr{tampered});

$t->post_ok('/receptor1' => form => {
    foo => ['fooValue1','fooValue2'],
    "$namespace-schema" => $token5,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    "$namespace-schema" => $token5,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    foo => '',
    "$namespace-schema" => $token5,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo1 => 'a',
    foo2 => '',
    foo3 => 'a',
    "$namespace-schema" => $token8,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    foo1 => 'a' x 33,
    foo2 => '',
    foo3 => 'a',
    "$namespace-schema" => $token8,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo1 => '',
    foo2 => 'a',
    foo3 => 'a',
    "$namespace-schema" => $token8,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo1 => '',
    "$namespace-schema" => $token9,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo1 => '1',
    "$namespace-schema" => $token9,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    "$namespace-schema" => $token10,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue1',
    "$namespace-schema" => $token10,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue1',
    "$namespace-schema" => $token11,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    foo => '',
    "$namespace-schema" => $token11,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    foo => 'fooValue3',
    "$namespace-schema" => $token11,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    "$namespace-schema" => $token11,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo => '333',
    "$namespace-schema" => $token12,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    foo => '3333',
    "$namespace-schema" => $token12,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo => '33a',
    "$namespace-schema" => $token12,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo => '',
    "$namespace-schema" => $token12,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo => '',
    "$namespace-schema" => $token12,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo => '7',
    "$namespace-schema" => $token13,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    foo => '10',
    "$namespace-schema" => $token13,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    foo => '1',
    "$namespace-schema" => $token13,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo => '22',
    "$namespace-schema" => $token13,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo => 'a',
    "$namespace-schema" => $token13,
});
$t->status_is(400);

$t->post_ok('/receptor1' => form => {
    foo => ['6', 11],
    "$namespace-schema" => $token13,
});
$t->status_is(400);

$t->post_ok('/receptor3' => form => {
    "$namespace-schema" => $token14,
});
$t->status_is(200);

$t->post_ok('/receptor1' => form => {
    "$namespace-schema" => $token14,
});
$t->status_is(400);
$t->content_like(qr{Action attribute});

$t->post_ok('/receptor1' => form => {
    foo => 'やったー',
    "$namespace-schema" => $token17,
});
$t->status_is(200);

$t->get_ok('/test2.css');
$t->status_is(200);
$t->header_is('Content-Length', 151);

$t->post_ok('/receptor3' => form => {
    "$namespace-schema" => $token14,
});
$t->status_is(200);

# checksum tampering
{
    my $token14_tampered = serialize({
        $TERM_ACTION    => '/receptor1',
        $TERM_SCHEMA => {
            $TERM_PROPERTIES => {},
        },
    });
    $t->post_ok('/receptor1' => form => {
        "$namespace-schema" => $token14_tampered. '--'. hmac_sha1_sum($token14_tampered, $sessid),
    });
    $t->status_is(400);
    $t->content_like(qr[schema]i);
    $t->content_like(qr[missing]i);
}

$t->reset_session;

$t->post_ok('/receptor3' => form => {
    "$namespace-schema" => $token14,
});
$t->status_is(400);
$t->content_like(qr{schema});
$t->content_like(qr{missing});

sub extract_session {
    my $t = shift;
    my $jar = $t->ua->cookie_jar;
    my $app = $t->app;
    my $session_name = $app->sessions->cookie_name || 'mojolicious';
    my ($session_cookie) = grep { $_->name eq $session_name } @{$jar->all};
    return unless $session_cookie;
    (my $value = $session_cookie->value) =~ s/--([^\-]+)$//;
    $value =~ tr/-/=/;
    my $session = decode_json(b64_decode $value);
    return $session;
}

__END__
