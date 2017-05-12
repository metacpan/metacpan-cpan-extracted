use strict;
use warnings;

use Test::More;
use Test::MockObject;
use OAuth::Lite2::Client::Error;
use OIDC::Lite::Client::TokenResponseParser;

# new
TEST_NEW: {
    my $parser = OIDC::Lite::Client::TokenResponseParser->new;
    ok($parser, q{OIDC::Lite::Client::TokenResponseParser->new});
};

TEST_PARSE: {
    my $parser = OIDC::Lite::Client::TokenResponseParser->new;

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "";
        },
        'is_success' => sub {
            return 1;
        },
    );
    my $res = HTTP::Request->new;
    my $token;
    eval {
        $token = $parser->parse($res);
    };
    ok($@);
    my $error = $@;
    isa_ok($error, "OAuth::Lite2::Client::Error::InvalidResponse", q{InvalidResponse content-type});
    is($error->message, "Invalid response content-type: ", q{InvalidResponse content-type message});

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "application/invalid";
        },
        'is_success' => sub {
            return 1;
        },
    );
    $res = HTTP::Request->new;
    eval {
        $token = $parser->parse($res);
    };
    ok($@);
    $error = $@;
    isa_ok($error, "OAuth::Lite2::Client::Error::InvalidResponse", q{InvalidResponse content-type});
    is($error->message, "Invalid response content-type: application/invalid", q{InvalidResponse content-type message});

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "application/json";
        },
        'content' => sub {
            return '';
        },
        'is_success' => sub {
            return 1;
        },
    );
    $res = HTTP::Request->new;
    eval {
        $token = $parser->parse($res);
    };
    ok($@);
    $error = $@;
    isa_ok($error, "OAuth::Lite2::Client::Error::InvalidResponse", q{InvalidResponse content});
    like($error->message, qr/Invalid response format: malformed JSON string/, q{InvalidResponse content message});

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "application/json";
        },
        'content' => sub {
            return '{"foo":"bar"}';
        },
        'is_success' => sub {
            return 1;
        },
    );
    $res = HTTP::Request->new;
    eval {
        $token = $parser->parse($res);
    };
    ok($@);
    $error = $@;
    isa_ok($error, "OAuth::Lite2::Client::Error::InvalidResponse", q{InvalidResponse access_token});
    is($error->message, q{Response doesn't include 'access_token'}, q{InvalidResponse access_token message});

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "application/json";
        },
        'content' => sub {
            return '{"access_token":"at_string"}';
        },
        'is_success' => sub {
            return 1;
        },
    );
    $res = HTTP::Request->new;
    eval {
        $token = $parser->parse($res);
    };
    ok(!$@);
    ok($token);
    is($token->access_token, q{at_string}, q{Success});
    $token = undef;

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "application/invalid";
        },
        'status_line' => sub {
            return '';
        },
        'content' => sub {
            return '';
        },
        'is_success' => sub {
            return 0;
        },
    );
    $res = HTTP::Request->new;
    eval {
        $token = $parser->parse($res);
    };
    ok($@);
    $error = $@;
    isa_ok($error, "OAuth::Lite2::Client::Error::InvalidResponse", q{InvalidResponse empty message});
    is($error->message, q{invalid response}, q{InvalidResponse empty message message});

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "application/json";
        },
        'status_line' => sub {
            return '';
        },
        'content' => sub {
            return '';
        },
        'is_success' => sub {
            return 0;
        },
    );
    $res = HTTP::Request->new;
    eval {
        $token = $parser->parse($res);
    };
    ok($@);
    $error = $@;
    isa_ok($error, "OAuth::Lite2::Client::Error::InvalidResponse", q{InvalidResponse empty message});
    is($error->message, q{invalid response}, q{InvalidResponse empty message message});

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "application/json";
        },
        'status_line' => sub {
            return 'msg_str';
        },
        'content' => sub {
            return '';
        },
        'is_success' => sub {
            return 0;
        },
    );
    $res = HTTP::Request->new;
    eval {
        $token = $parser->parse($res);
    };
    ok($@);
    $error = $@;
    isa_ok($error, "OAuth::Lite2::Client::Error::InvalidResponse", q{InvalidResponse status_line});
    is($error->message, q{msg_str}, q{InvalidResponse status_line message});

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "application/json";
        },
        'content' => sub {
            return 'invalid';
        },
        'is_success' => sub {
            return 0;
        },
    );
    $res = HTTP::Request->new;
    $token = undef;
    eval {
        $token = $parser->parse($res);
    };
    ok($@);
    $error = $@;
    isa_ok($error, "OAuth::Lite2::Client::Error::InvalidResponse", q{InvalidResponse invalid content});
    is($error->message, q{invalid response}, q{InvalidResponse invalid content message});

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "application/json";
        },
        'content' => sub {
            return '{"foo":"bar"}';
        },
        'is_success' => sub {
            return 0;
        },
    );
    $res = HTTP::Request->new;
    eval {
        $token = $parser->parse($res);
    };
    ok($@);
    $error = $@;
    isa_ok($error, "OAuth::Lite2::Client::Error::InvalidResponse", q{InvalidResponse content});
    is($error->message, q{\{"foo":"bar"\}}, q{InvalidResponse content message});

    Test::MockObject->fake_module(
        'HTTP::Request',
        'new' => sub{bless {}, shift},
        'content_type' => sub {
            return "application/json";
        },
        'content' => sub {
            return '{"error":"error_str"}';
        },
        'is_success' => sub {
            return 0;
        },
    );
    $res = HTTP::Request->new;
    eval {
        $token = $parser->parse($res);
    };
    ok($@);
    $error = $@;
    isa_ok($error, "OAuth::Lite2::Client::Error::InvalidResponse", q{InvalidResponse content error});
    is($error->message, q{error_str}, q{InvalidResponse content error message});
};

done_testing;
