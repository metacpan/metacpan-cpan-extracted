#!perl

package Test::ojo;
use Mojo::Base -base;
use warnings FATAL => 'all';

sub lol {
    [
        [ "head1", "NAME" ],
        [ "Para",  "ojo - Fun one-liners with Mojo" ],
        [ "head1", "SYNOPSIS" ],
        [
            "Verbatim",
"  \$ perl -Mojo -E 'say g(\"mojolicious.org\")->dom->at(\"title\")->text'"
        ],
        [ "head1", "DESCRIPTION" ],
        [
            "Para",
"A collection of automatically exported functions for fun Perl one-liners. Ten redirects will be followed by default, you can change this behavior with the MOJO_MAX_REDIRECTS environment variable."
        ],
        [
            "Verbatim",
"  \$ MOJO_MAX_REDIRECTS=0 perl -Mojo -E 'say g(\"example.com\")->code'"
        ],
        [
            "Para",
"Proxy detection is enabled by default, but you can disable it with the MOJO_PROXY environment variable."
        ],
        [
            "Verbatim",
            "  \$ MOJO_PROXY=0 perl -Mojo -E 'say g(\"example.com\")->body'"
        ],
        [
            "Para",
"TLS certificate verification can be disabled with the MOJO_INSECURE environment variable."
        ],
        [
            "Verbatim",
"  \$ MOJO_INSECURE=1 perl -Mojo -E 'say g(\"https://127.0.0.1:3000\")->body'"
        ],
        [
            "Para",
            "Every ojo one-liner is also a Mojolicious::Lite application."
        ],
        [
            "Verbatim",
"  \$ perl -Mojo -E 'get \"/\" => {inline => \"%= time\"}; app->start' get /"
        ],
        [
            "Para",
            "On Perl 5.20+ subroutine signatures will be enabled automatically."
        ],
        [
            "Verbatim",
"  \$ perl -Mojo -E 'a(sub (\$c) { \$c->render(text => \"Hello!\") })->start' get /"
        ],
        [
            "Para",
"If it is not already defined, the MOJO_LOG_LEVEL environment variable will be set to fatal."
        ],
        [ "head1", "FUNCTIONS" ],
        [
            "Para",
"ojo implements the following functions, which are automatically exported."
        ],
        [ "head2", "a" ],
        [
            "Verbatim",
"  my \$app = a('/hello' => sub { \$_->render(json => {hello => 'world'}) });"
        ],
        [
            "Para",
"Create a route with \"any\" in Mojolicious::Lite and return the current Mojolicious::Lite object. The current controller object is also available to actions as \$_. See also Mojolicious::Guides::Tutorial for more argument variations."
        ],
        [
            "Verbatim",
"  \$ perl -Mojo -E 'a(\"/hello\" => {text => \"Hello Mojo!\"})->start' daemon"
        ],
        [ "head2",    "b" ],
        [ "Verbatim", "  my \$stream = b('lalala');" ],
        [ "Para",     "Turn string into a Mojo::ByteStream object." ],
        [
            "Verbatim",
"  \$ perl -Mojo -E 'b(g(\"mojolicious.org\")->body)->html_unescape->say'"
        ],
        [ "head2",    "c" ],
        [ "Verbatim", "  my \$collection = c(1, 2, 3);" ],
        [ "Para",     "Turn list into a Mojo::Collection object." ],
        [ "head2",    "d" ],
        [
            "Verbatim",
"  my \$res = d('example.com');\n  my \$res = d('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = d('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = d('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
        ],
        [
            "Para",
"Perform DELETE request with \"delete\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
        ],
        [ "head2",    "f" ],
        [ "Verbatim", "  my \$path = f('/home/sri/foo.txt');" ],
        [ "Para",     "Turn string into a Mojo::File object." ],
        [ "Verbatim", "  \$ perl -Mojo -E 'say r j f(\"hello.json\")->slurp'" ],
        [ "head2",    "g" ],
        [
            "Verbatim",
"  my \$res = g('example.com');\n  my \$res = g('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = g('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = g('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
        ],
        [
            "Para",
"Perform GET request with \"get\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
        ],
        [
            "Verbatim",
"  \$ perl -Mojo -E 'say g(\"mojolicious.org\")->dom(\"h1\")->map(\"text\")->join(\"\\n\")'"
        ],
        [ "head2", "h" ],
        [
            "Verbatim",
"  my \$res = h('example.com');\n  my \$res = h('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = h('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = h('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
        ],
        [
            "Para",
"Perform HEAD request with \"head\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
        ],
        [ "head2", "j" ],
        [
            "Verbatim",
"  my \$bytes = j([1, 2, 3]);\n  my \$bytes = j({foo => 'bar'});\n  my \$value = j(\$bytes);"
        ],
        [
            "Para",
"Encode Perl data structure or decode JSON with \"j\" in Mojo::JSON."
        ],
        [
            "Verbatim",
"  \$ perl -Mojo -E 'f(\"hello.json\")->spurt(j {hello => \"world!\"})'"
        ],
        [ "head2",    "l" ],
        [ "Verbatim", "  my \$url = l('https://mojolicious.org');" ],
        [ "Para",     "Turn a string into a Mojo::URL object." ],
        [
            "Verbatim",
"  \$ perl -Mojo -E 'say l(\"/perldoc\")->to_abs(l(\"https://mojolicious.org\"))'"
        ],
        [ "head2",    "n" ],
        [ "Verbatim", "  n {...};\n  n {...} 100;" ],
        [
            "Para",
"Benchmark block and print the results to STDERR, with an optional number of iterations, which defaults to 1."
        ],
        [
            "Verbatim",
            "  \$ perl -Mojo -E 'n { say g(\"mojolicious.org\")->code }'"
        ],
        [ "head2", "o" ],
        [
            "Verbatim",
"  my \$res = o('example.com');\n  my \$res = o('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = o('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = o('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
        ],
        [
            "Para",
"Perform OPTIONS request with \"options\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
        ],
        [ "head2", "p" ],
        [
            "Verbatim",
"  my \$res = p('example.com');\n  my \$res = p('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = p('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = p('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
        ],
        [
            "Para",
"Perform POST request with \"post\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
        ],
        [ "head2",    "r" ],
        [ "Verbatim", "  my \$perl = r({data => 'structure'});" ],
        [ "Para", "Dump a Perl data structure with \"dumper\" in Mojo::Util." ],
        [
            "Verbatim",
            "  perl -Mojo -E 'say r g(\"example.com\")->headers->to_hash'"
        ],
        [ "head2", "t" ],
        [
            "Verbatim",
"  my \$res = t('example.com');\n  my \$res = t('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = t('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = t('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
        ],
        [
            "Para",
"Perform PATCH request with \"patch\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
        ],
        [ "head2", "u" ],
        [
            "Verbatim",
"  my \$res = u('example.com');\n  my \$res = u('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = u('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = u('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
        ],
        [
            "Para",
"Perform PUT request with \"put\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
        ],
        [ "head2",    "x" ],
        [ "Verbatim", "  my \$dom = x('<div>Hello!</div>');" ],
        [ "Para",     "Turn HTML/XML input into Mojo::DOM object." ],
        [
            "Verbatim",
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'"
        ],
        [ "head2",    "x2()" ],    # Added just for testing.
        [ "Verbatim", "  my \$dom = x('<div>Hello!</div>');" ],
        [ "Para",     "Turn HTML/XML input into Mojo::DOM object." ],
        [
            "Verbatim",
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'"
        ],
        [ "head1", "SEE ALSO" ],
        [
            "Para",
            "Mojolicious, Mojolicious::Guides, https://mojolicious.org."
        ]
    ];
}

sub expected_tree {
    [
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" => "ojo - Fun one-liners with Mojo"
                }
            ],
            "tag"  => "head1",
            "text" => "NAME"
        },
        {
            "kids" => [
                {
                    "tag"  => "Verbatim",
                    "text" =>
"  \$ perl -Mojo -E 'say g(\"mojolicious.org\")->dom->at(\"title\")->text'"
                }
            ],
            "tag"  => "head1",
            "text" => "SYNOPSIS"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
"A collection of automatically exported functions for fun Perl one-liners. Ten redirects will be followed by default, you can change this behavior with the MOJO_MAX_REDIRECTS environment variable."
                },
                {
                    "tag"  => "Verbatim",
                    "text" =>
"  \$ MOJO_MAX_REDIRECTS=0 perl -Mojo -E 'say g(\"example.com\")->code'"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"Proxy detection is enabled by default, but you can disable it with the MOJO_PROXY environment variable."
                },
                {
                    "tag"  => "Verbatim",
                    "text" =>
"  \$ MOJO_PROXY=0 perl -Mojo -E 'say g(\"example.com\")->body'"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"TLS certificate verification can be disabled with the MOJO_INSECURE environment variable."
                },
                {
                    "tag"  => "Verbatim",
                    "text" =>
"  \$ MOJO_INSECURE=1 perl -Mojo -E 'say g(\"https://127.0.0.1:3000\")->body'"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"Every ojo one-liner is also a Mojolicious::Lite application."
                },
                {
                    "tag"  => "Verbatim",
                    "text" =>
"  \$ perl -Mojo -E 'get \"/\" => {inline => \"%= time\"}; app->start' get /"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"On Perl 5.20+ subroutine signatures will be enabled automatically."
                },
                {
                    "tag"  => "Verbatim",
                    "text" =>
"  \$ perl -Mojo -E 'a(sub (\$c) { \$c->render(text => \"Hello!\") })->start' get /"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"If it is not already defined, the MOJO_LOG_LEVEL environment variable will be set to fatal."
                }
            ],
            "tag"  => "head1",
            "text" => "DESCRIPTION"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
"ojo implements the following functions, which are automatically exported."
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  my \$app = a('/hello' => sub { \$_->render(json => {hello => 'world'}) });"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Create a route with \"any\" in Mojolicious::Lite and return the current Mojolicious::Lite object. The current controller object is also available to actions as \$_. See also Mojolicious::Guides::Tutorial for more argument variations."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  \$ perl -Mojo -E 'a(\"/hello\" => {text => \"Hello Mojo!\"})->start' daemon"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "a"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" => "  my \$stream = b('lalala');"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
                              "Turn string into a Mojo::ByteStream object."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  \$ perl -Mojo -E 'b(g(\"mojolicious.org\")->body)->html_unescape->say'"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "b"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" => "  my \$collection = c(1, 2, 3);"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
                              "Turn list into a Mojo::Collection object."
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "c"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  my \$res = d('example.com');\n  my \$res = d('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = d('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = d('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Perform DELETE request with \"delete\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "d"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" => "  my \$path = f('/home/sri/foo.txt');"
                        },
                        {
                            "tag"  => "Para",
                            "text" => "Turn string into a Mojo::File object."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  \$ perl -Mojo -E 'say r j f(\"hello.json\")->slurp'"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "f"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  my \$res = g('example.com');\n  my \$res = g('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = g('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = g('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Perform GET request with \"get\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  \$ perl -Mojo -E 'say g(\"mojolicious.org\")->dom(\"h1\")->map(\"text\")->join(\"\\n\")'"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "g"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  my \$res = h('example.com');\n  my \$res = h('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = h('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = h('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Perform HEAD request with \"head\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "h"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  my \$bytes = j([1, 2, 3]);\n  my \$bytes = j({foo => 'bar'});\n  my \$value = j(\$bytes);"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Encode Perl data structure or decode JSON with \"j\" in Mojo::JSON."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  \$ perl -Mojo -E 'f(\"hello.json\")->spurt(j {hello => \"world!\"})'"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "j"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" =>
                              "  my \$url = l('https://mojolicious.org');"
                        },
                        {
                            "tag"  => "Para",
                            "text" => "Turn a string into a Mojo::URL object."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  \$ perl -Mojo -E 'say l(\"/perldoc\")->to_abs(l(\"https://mojolicious.org\"))'"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "l"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" => "  n {...};\n  n {...} 100;"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Benchmark block and print the results to STDERR, with an optional number of iterations, which defaults to 1."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  \$ perl -Mojo -E 'n { say g(\"mojolicious.org\")->code }'"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "n"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  my \$res = o('example.com');\n  my \$res = o('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = o('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = o('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Perform OPTIONS request with \"options\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "o"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  my \$res = p('example.com');\n  my \$res = p('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = p('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = p('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Perform POST request with \"post\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "p"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" => "  my \$perl = r({data => 'structure'});"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Dump a Perl data structure with \"dumper\" in Mojo::Util."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  perl -Mojo -E 'say r g(\"example.com\")->headers->to_hash'"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "r"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  my \$res = t('example.com');\n  my \$res = t('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = t('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = t('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Perform PATCH request with \"patch\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "t"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  my \$res = u('example.com');\n  my \$res = u('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = u('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = u('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Perform PUT request with \"put\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "u"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" => "  my \$dom = x('<div>Hello!</div>');"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
                              "Turn HTML/XML input into Mojo::DOM object."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "x"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Verbatim",
                            "text" => "  my \$dom = x('<div>Hello!</div>');"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
                              "Turn HTML/XML input into Mojo::DOM object."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "x2()"
                }
            ],
            "tag"  => "head1",
            "text" => "FUNCTIONS"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
"Mojolicious, Mojolicious::Guides, https://mojolicious.org."
                }
            ],
            "tag"  => "head1",
            "text" => "SEE ALSO"
        }
    ];
}

sub expected_find_title {
    "ojo - Fun one-liners with Mojo";
}

sub expected_find_events {
    [];
}

sub define_cases {
    [
        {
            method               => "x",
            expected_find_method => [
                "x:",
                "",
                "  my \$dom = x('<div>Hello!</div>');",
                "",
                "  Turn HTML/XML input into Mojo::DOM object.",
                "",
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'",
                ""
            ],
            expected_find_method_summary =>
              "Turn HTML/XML input into Mojo::DOM object.",
        },
        {
            method               => "x2()",
            expected_find_method => [
                "x2():",
                "",
                "  my \$dom = x('<div>Hello!</div>');",
                "",
                "  Turn HTML/XML input into Mojo::DOM object.",
                "",
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'",
                ""
            ],
            expected_find_method_summary =>
              "Turn HTML/XML input into Mojo::DOM object.",
        },
        {
            method               => "j",
            expected_find_method => [
                "j:",
                "",
"  my \$bytes = j([1, 2, 3]);\n  my \$bytes = j({foo => 'bar'});\n  my \$value = j(\$bytes);",
                "",
"  Encode Perl data structure or decode JSON with \"j\" in\n  Mojo::JSON.",
                "",
"  \$ perl -Mojo -E 'f(\"hello.json\")->spurt(j {hello => \"world!\"})'",
                "",
            ],
            expected_find_method_summary =>
"Encode Perl data structure or decode JSON with \"j\" in Mojo::JSON.",
        },
    ]
}

sub define_find_cases {
    [

        # Bad input.
        {
            name            => "No find parameter",
            expected_struct => [],
            expected_find   => [],
            error           => 1,
        },
        {
            name            => "No find parameter hash input",
            find            => "",
            expected_struct => [],
            expected_find   => [],
            error           => 1,
        },

        # Existing use cases.
        {
            name            => "find_title",
            find            => "head1=NAME[0]/Para[0]",
            expected_struct => [
                {
                    tag  => "head1",
                    text => "NAME",
                    nth  => 0,
                },
                {
                    tag => "Para",
                    nth => 0,
                },
            ],
            expected_find => [ "ojo - Fun one-liners with Mojo", ],
        },
        {
            name            => "find_method",
            find            => '~^head\d$=(x)[0]**',
            expected_struct => [
                {
                    tag          => qr/^head\d$/i,
                    text         => "x",
                    nth_in_group => 0,
                    keep_all     => 1,
                },
            ],
            expected_find => [
                "x:",
                "",
                "  my \$dom = x('<div>Hello!</div>');",
                "",
                "  Turn HTML/XML input into Mojo::DOM object.",
                "",
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'",
                "",
            ],
        },
        {
            name            => "find_method_summary",
            find            => '~^head\d$=(x)[0]/~(?:Data|Para)[0]',
            expected_struct => [
                {
                    tag          => qr/^head\d$/i,
                    text         => "x",
                    nth_in_group => 0,
                },
                {
                    tag => qr/(?:Data|Para)/i,
                    nth => 0,
                },
            ],
            expected_find => ["Turn HTML/XML input into Mojo::DOM object."],
        },
        {
            name            => "find_events - names",
            find            => '~^head\d$=EVENTS[0]/~^head\d$*',
            expected_struct => [
                {
                    tag  => qr/^head\d$/i,
                    text => "EVENTS",
                    nth  => 0,
                },
                {
                    tag  => qr/^head\d$/i,
                    keep => 1,
                },
            ],
            expected_find => [

            ],
        },
        {
            name            => "find_events",
            find            => '~^head\d$=EVENTS[0]/~^head\d$*/(Para)[0]',
            expected_struct => [
                {
                    tag  => qr/^head\d$/i,
                    text => "EVENTS",
                    nth  => 0,
                },
                {
                    tag  => qr/^head\d$/i,
                    keep => 1,
                },
                {
                    tag          => "Para",
                    nth_in_group => 0,
                },
            ],
            expected_find => [],
        },

        # Tag.
        {
            name            => "find tag=head1",
            find            => 'head1',
            expected_struct => [
                {
                    tag => "head1",
                },
            ],
            expected_find =>
              [ "NAME", "SYNOPSIS", "DESCRIPTION", "FUNCTIONS", "SEE ALSO", ],
        },
        {
            name            => "find tag=head1, keep=1 (same)",
            find            => 'head1*',
            expected_struct => [
                {
                    tag  => "head1",
                    keep => 1,
                },
            ],
            expected_find =>
              [ "NAME", "SYNOPSIS", "DESCRIPTION", "FUNCTIONS", "SEE ALSO", ],
        },
        {
            name            => "find tag=head1, keep_all=1",
            find            => 'head1**',
            expected_struct => [
                {
                    tag      => "head1",
                    keep_all => 1,
                },
            ],
            expected_find => [
                "NAME:",
                "",
                "  ojo - Fun one-liners with Mojo",
                "",
                "SYNOPSIS",
                "",
"  \$ perl -Mojo -E 'say g(\"mojolicious.org\")->dom->at(\"title\")->text'",
                "",
                "DESCRIPTION",
                "",
"  A collection of automatically exported functions for\n  fun Perl one-liners. Ten redirects will be followed by\n  default, you can change this behavior with the\n  MOJO_MAX_REDIRECTS environment variable.",
                "",
"  \$ MOJO_MAX_REDIRECTS=0 perl -Mojo -E 'say g(\"example.com\")->code'",
                "",
"  Proxy detection is enabled by default, but you can\n  disable it with the MOJO_PROXY environment variable.",
                "",
"  \$ MOJO_PROXY=0 perl -Mojo -E 'say g(\"example.com\")->body'",
                "",
"  TLS certificate verification can be disabled with the\n  MOJO_INSECURE environment variable.",
                "",
"  \$ MOJO_INSECURE=1 perl -Mojo -E 'say g(\"https://127.0.0.1:3000\")->body'",
                "",
"  Every ojo one-liner is also a Mojolicious::Lite\n  application.",
                "",
"  \$ perl -Mojo -E 'get \"/\" => {inline => \"%= time\"}; app->start' get /",
                "",
"  On Perl 5.20+ subroutine signatures will be enabled\n  automatically.",
                "",
"  \$ perl -Mojo -E 'a(sub (\$c) { \$c->render(text => \"Hello!\") })->start' get /",
                "",
"  If it is not already defined, the MOJO_LOG_LEVEL\n  environment variable will be set to fatal.",
                "",
                "FUNCTIONS",
                "",
"  ojo implements the following functions, which are\n  automatically exported.",
                "",
                "a",
                "",
"  my \$app = a('/hello' => sub { \$_->render(json => {hello => 'world'}) });",
                "",
"  Create a route with \"any\" in Mojolicious::Lite and\n  return the current Mojolicious::Lite object. The\n  current controller object is also available to actions\n  as \$_. See also Mojolicious::Guides::Tutorial for more\n  argument variations.",
                "",
"  \$ perl -Mojo -E 'a(\"/hello\" => {text => \"Hello Mojo!\"})->start' daemon",
                "",
                "b",
                "",
                "  my \$stream = b('lalala');",
                "",
                "  Turn string into a Mojo::ByteStream object.",
                "",
"  \$ perl -Mojo -E 'b(g(\"mojolicious.org\")->body)->html_unescape->say'",
                "",
                "c",
                "",
                "  my \$collection = c(1, 2, 3);",
                "",
                "  Turn list into a Mojo::Collection object.",
                "",
                "d",
                "",
"  my \$res = d('example.com');\n  my \$res = d('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = d('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = d('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});",
                "",
"  Perform DELETE request with \"delete\" in\n  Mojo::UserAgent and return resulting\n  Mojo::Message::Response object.",
                "",
                "f",
                "",
                "  my \$path = f('/home/sri/foo.txt');",
                "",
                "  Turn string into a Mojo::File object.",
                "",
                "  \$ perl -Mojo -E 'say r j f(\"hello.json\")->slurp'",
                "",
                "g",
                "",
"  my \$res = g('example.com');\n  my \$res = g('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = g('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = g('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});",
                "",
"  Perform GET request with \"get\" in Mojo::UserAgent and\n  return resulting Mojo::Message::Response object.",
                "",
"  \$ perl -Mojo -E 'say g(\"mojolicious.org\")->dom(\"h1\")->map(\"text\")->join(\"\\n\")'",
                "",
                "h",
                "",
"  my \$res = h('example.com');\n  my \$res = h('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = h('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = h('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});",
                "",
"  Perform HEAD request with \"head\" in Mojo::UserAgent\n  and return resulting Mojo::Message::Response object.",
                "",
                "j",
                "",
"  my \$bytes = j([1, 2, 3]);\n  my \$bytes = j({foo => 'bar'});\n  my \$value = j(\$bytes);",
                "",
"  Encode Perl data structure or decode JSON with \"j\" in\n  Mojo::JSON.",
                "",
"  \$ perl -Mojo -E 'f(\"hello.json\")->spurt(j {hello => \"world!\"})'",
                "",
                "l",
                "",
                "  my \$url = l('https://mojolicious.org');",
                "",
                "  Turn a string into a Mojo::URL object.",
                "",
"  \$ perl -Mojo -E 'say l(\"/perldoc\")->to_abs(l(\"https://mojolicious.org\"))'",
                "",
                "n",
                "",
                "  n {...};\n  n {...} 100;",
                "",
"  Benchmark block and print the results to STDERR, with\n  an optional number of iterations, which defaults to 1.",
                "",
                "  \$ perl -Mojo -E 'n { say g(\"mojolicious.org\")->code }'",
                "",
                "o",
                "",
"  my \$res = o('example.com');\n  my \$res = o('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = o('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = o('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});",
                "",
"  Perform OPTIONS request with \"options\" in\n  Mojo::UserAgent and return resulting\n  Mojo::Message::Response object.",
                "",
                "p",
                "",
"  my \$res = p('example.com');\n  my \$res = p('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = p('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = p('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});",
                "",
"  Perform POST request with \"post\" in Mojo::UserAgent\n  and return resulting Mojo::Message::Response object.",
                "",
                "r",
                "",
                "  my \$perl = r({data => 'structure'});",
                "",
"  Dump a Perl data structure with \"dumper\" in\n  Mojo::Util.",
                "",
                "  perl -Mojo -E 'say r g(\"example.com\")->headers->to_hash'",
                "",
                "t",
                "",
"  my \$res = t('example.com');\n  my \$res = t('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = t('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = t('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});",
                "",
"  Perform PATCH request with \"patch\" in Mojo::UserAgent\n  and return resulting Mojo::Message::Response object.",
                "",
                "u",
                "",
"  my \$res = u('example.com');\n  my \$res = u('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = u('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = u('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});",
                "",
"  Perform PUT request with \"put\" in Mojo::UserAgent and\n  return resulting Mojo::Message::Response object.",
                "",
                "x",
                "",
                "  my \$dom = x('<div>Hello!</div>');",
                "",
                "  Turn HTML/XML input into Mojo::DOM object.",
                "",
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'",
                "",
                "x2()",
                "",
                "  my \$dom = x('<div>Hello!</div>');",
                "",
                "  Turn HTML/XML input into Mojo::DOM object.",
                "",
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'",
                "",
                "SEE ALSO",
                "",
"  Mojolicious, Mojolicious::Guides,\n  https://mojolicious.org.",
                ""
            ],
        },
        {
            name            => "find tag=Para",
            find            => 'Para',
            expected_struct => [
                {
                    tag => "Para",
                },
            ],
            expected_find => [
                "ojo - Fun one-liners with Mojo",
"A collection of automatically exported functions for fun Perl one-liners. Ten redirects will be followed by default, you can change this behavior with the MOJO_MAX_REDIRECTS environment variable.",
"Proxy detection is enabled by default, but you can disable it with the MOJO_PROXY environment variable.",
"TLS certificate verification can be disabled with the MOJO_INSECURE environment variable.",
                "Every ojo one-liner is also a Mojolicious::Lite application.",
"On Perl 5.20+ subroutine signatures will be enabled automatically.",
"If it is not already defined, the MOJO_LOG_LEVEL environment variable will be set to fatal.",
"ojo implements the following functions, which are automatically exported.",
                "Mojolicious, Mojolicious::Guides, https://mojolicious.org."
            ],
        },

        # Tag, Nth.
        {
            name            => "find tag=Para, nth=0",
            find            => 'Para[0]',
            expected_struct => [
                {
                    tag => "Para",
                    nth => 0,
                },
            ],
            expected_find => [ "ojo - Fun one-liners with Mojo", ],
        },
        {
            name            => "find tag=Para, nth=-1",
            find            => 'Para[-1]',
            expected_struct => [
                {
                    tag => "Para",
                    nth => -1,
                },
            ],
            expected_find =>
              ["Mojolicious, Mojolicious::Guides, https://mojolicious.org."],
        },

        # Tag, Text.
        {
            name            => "find tag=Para, text=Literal",
            find            => 'Para=ojo - Fun one-liners with Mojo',
            expected_struct => [
                {
                    tag  => "Para",
                    text => "ojo - Fun one-liners with Mojo",
                },
            ],
            expected_find => [ "ojo - Fun one-liners with Mojo", ],
        },
        {
            name            => "find tag=Para, text='Literal'",
            find            => 'Para="ojo - Fun one-liners with Mojo"',
            expected_struct => [
                {
                    tag  => "Para",
                    text => "ojo - Fun one-liners with Mojo",
                },
            ],
            expected_find => [ "ojo - Fun one-liners with Mojo", ],
        },
        {
            name            => "find tag=Para, text=Any,Literal",
            find            => '~./Para=ojo - Fun one-liners with Mojo',
            expected_struct => [
                {
                    tag => qr/./i,
                },
                {
                    tag  => "Para",
                    text => "ojo - Fun one-liners with Mojo",
                },
            ],
            expected_find => [ "ojo - Fun one-liners with Mojo", ],
        },

        # find_title - alternatives.
        {
            name            => "find_title - alt 1",
            find            => 'head1=NAME[0]/Para[0]',
            expected_struct => [
                {
                    tag  => "head1",
                    text => "NAME",
                    nth  => 0,
                },
                {
                    tag => "Para",
                    nth => 0,
                },
            ],
            expected_find => [ "ojo - Fun one-liners with Mojo", ],
        },
        {
            name => "find_title - alt 2 - last keep/star is optional",
            find => 'head1=NAME[0]/Para[0]',
            expected_struct => [
                {
                    tag  => "head1",
                    text => "NAME",
                    nth  => 0,
                },
                {
                    tag => "Para",
                    nth => 0,
                },
            ],
            expected_find => [ "ojo - Fun one-liners with Mojo", ],
        },
        {
            name => "find_title - alt 3 - same without index (although slower)",
            find => 'head1=NAME[0]/Para[0]',
            expected_struct => [
                {
                    tag  => "head1",
                    text => "NAME",
                    nth  => 0,
                },
                {
                    tag => "Para",
                    nth => 0,
                },
            ],
            expected_find => ["ojo - Fun one-liners with Mojo"],
        },
        {
            name            => "find_title - alt 4 - same insensitive",
            find            => 'head1=~name[0]/Para[0]',
            expected_struct => [
                {
                    tag  => "head1",
                    text => qr/name/i,
                    nth  => 0,
                },
                {
                    tag => "Para",
                    nth => 0,
                },
            ],
            expected_find => [ "ojo - Fun one-liners with Mojo", ],
        },

        # Nth.
        {
            name            => "find nth=First,First",
            find            => '~.[0]/~.[0]',
            expected_struct => [
                {
                    tag => qr/./i,
                    nth => 0,
                },
                {
                    tag => qr/./i,
                    nth => 0,
                },
            ],
            expected_find => ["ojo - Fun one-liners with Mojo"],
        },
        {
            name            => "find nth=Second,First",
            find            => '~.[1]/~.[0]',
            expected_struct => [
                {
                    tag => qr/./i,
                    nth => 1,
                },
                {
                    tag => qr/./i,
                    nth => 0,
                },
            ],
            expected_find => [
"  \$ perl -Mojo -E 'say g(\"mojolicious.org\")->dom->at(\"title\")->text'"
            ],
        },

        # nth_in_group.
        {
            name            => "find nth=Second,First",
            find            => '~.[1]/~.[0]',
            expected_struct => [
                {
                    tag => qr/./i,
                    nth => 1,
                },
                {
                    tag => qr/./i,
                    nth => 0,
                },
            ],
            expected_find => [
"  \$ perl -Mojo -E 'say g(\"mojolicious.org\")->dom->at(\"title\")->text'"
            ],
        },
        {
            name =>
"find nth_in_group=Second (no effect since not reach index), nth=First",
            find            => '(~.)[1]/~.[0]',
            expected_struct => [
                {
                    tag          => qr/./i,
                    nth_in_group => 1,
                },
                {
                    tag => qr/./i,
                    nth => 0,
                },
            ],
            expected_find => ["ojo - Fun one-liners with Mojo"],
        },

        # Other.
        {
            name            => "find tag=Para, text=Any,First,Literal",
            find            => '~.[0]/Para[0]',
            expected_struct => [
                {
                    tag => qr/./i,
                    nth => 0,
                },
                {
                    tag => "Para",
                    nth => 0,
                },
            ],
            expected_find => [ "ojo - Fun one-liners with Mojo", ],
        },

        # Bug fixes.
        {
            name            => "Trailing slash should not be an error",
            find            => 'head1/',
            expected_struct => [
                {
                    tag => "head1",
                },
            ],
            expected_find =>
              [ "NAME", "SYNOPSIS", "DESCRIPTION", "FUNCTIONS", "SEE ALSO" ],
        },
        {
            name            => "Leading slash should not be an error",
            find            => '/head1',
            expected_struct => [
                {
                    tag => "head1",
                },
            ],
            expected_find =>
              [ "NAME", "SYNOPSIS", "DESCRIPTION", "FUNCTIONS", "SEE ALSO" ],
        },
        {
            name => "Trailing slash should not be an error (anywhere)",
            find => '~.[0]/Para[0]/',
            expected_struct => [
                {
                    tag => qr/./i,
                    nth => 0,
                },
                {
                    tag => "Para",
                    nth => 0,
                },
            ],
            expected_find => ["ojo - Fun one-liners with Mojo"],
        },

    ]
}


package main;
use Mojo::Base -strict;
use FindBin();
use lib $FindBin::RealBin;

Test::ojo->with_roles( 'Role::Test::Module' )
  ->run( module => "ojo", tests => 104 );

