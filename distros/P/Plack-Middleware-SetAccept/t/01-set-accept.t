use strict;
use warnings;

use Data::Dumper;
use HTTP::Request;
use Test::Exception;
use Test::More;
use Test::XML;
use Plack::Builder;
use Plack::Test;

$Data::Dumper::Purity = 1;
$Data::Dumper::Terse  = 1;

sub REQUEST {
    my ( $method, $url, @headers ) = @_;

    return HTTP::Request->new($method => $url, \@headers);
}

my @methods         = qw/HEAD GET/;
my @tolerant_values = (undef, 0, 1);

plan tests => 213 * @methods * @tolerant_values + 4;

foreach my $tolerant (@tolerant_values) {
    foreach my $method (@methods) {
        my $inner_app = sub {
            my ( $env ) = @_;

            return [
                200,
                ['Content-Type' => 'text/plain'],
                [$env->{'HTTP_ACCEPT'} || 'undef'],
            ]
        };

        my %map = (
            json => 'application/json',
            xml  => 'application/xml',
        );

        my $app = builder {
            enable 'SetAccept', from => 'suffix', mapping => \%map, (defined $tolerant ? (tolerant => $tolerant) : ());
            $inner_app;
        };

        my $res;

        test_psgi $app, sub {
            my ( $cb ) = @_;

            $res = $cb->(REQUEST $method => => '/foo');
            is $res->code, 200;
            is $res->content, '*/*';

            $res = $cb->(REQUEST $method => '/foo.json');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo.xml');
            is $res->code, 200;
            is $res->content, 'application/xml';

            $res = $cb->(REQUEST $method => '/foo?format=json');
            is $res->code, 200;
            is $res->content, '*/*';

            $res = $cb->(REQUEST $method => '/foo?format=xml');
            is $res->code, 200;
            is $res->content, '*/*';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo.yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:5000/foo.json">application/json</a></li><li><a href="http://localhost:5000/foo.xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:9000/bar.yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:9000/bar.json">application/json</a></li><li><a href="http://localhost:9000/bar.xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => '/foo?format=yaml');
            is $res->code, 200;
            is $res->content, '*/*';

            $res = $cb->(REQUEST $method => '/foo', Accept => 'application/json');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo', Accept => 'application/x-yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'application/x-yaml';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:5000/foo.json">application/json</a></li><li><a href="http://localhost:5000/foo.xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:9000/bar', Accept => 'application/x-yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'application/x-yaml';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:9000/bar.json">application/json</a></li><li><a href="http://localhost:9000/bar.xml">application/xml</a></li></ul></body></html>';
                } else  {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo.json', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml, application/json';
        };

        $app = builder {
            enable 'SetAccept', from => 'param', param => 'format', mapping => \%map, (defined $tolerant ? (tolerant => $tolerant) : ());
            $inner_app;
        };

        test_psgi $app, sub {
            my ( $cb ) = @_;

            my $res;

            $res = $cb->(REQUEST $method => '/foo');
            is $res->code, 200;
            is $res->content, '*/*';

            $res = $cb->(REQUEST $method => '/foo.json');
            is $res->code, 200;
            is $res->content, '*/*';

            $res = $cb->(REQUEST $method => '/foo.xml');
            is $res->code, 200;
            is $res->content, '*/*';

            $res = $cb->(REQUEST $method => '/foo?format=json');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo?format=xml');
            is $res->code, 200;
            is $res->content, 'application/xml';

            $res = $cb->(REQUEST $method => '/foo.yaml');
            is $res->code, 200;
            is $res->content, '*/*';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo?format=yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:5000/foo?format=json">application/json</a></li><li><a href="http://localhost:5000/foo?format=xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:9000/bar?format=yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:9000/bar?format=json">application/json</a></li><li><a href="http://localhost:9000/bar?format=xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => '/foo', Accept => 'application/json');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo', Accept => 'application/x-yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'application/x-yaml';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:5000/foo?format=json">application/json</a></li><li><a href="http://localhost:5000/foo?format=xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:9000/bar', Accept => 'application/x-yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'application/x-yaml';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:9000/bar?format=json">application/json</a></li><li><a href="http://localhost:9000/bar?format=xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo?format=json', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml, application/json';
        };

        throws_ok {
            builder {
                enable 'SetAccept';
            };
        } qr/'from' parameter is required/;

        throws_ok {
            builder {
                enable 'SetAccept', from => 'suffix';
            };
        } qr/'mapping' parameter is required/;

        throws_ok {
            builder {
                enable 'SetAccept', from => 'frob', mapping => {};
            };
        } qr/'frob' is not a valid value for the 'from' parameter/;

        throws_ok {
            builder {
                enable 'SetAccept', from => 'suffix', mapping => [];
            };
        } qr/'mapping' parameter must be a hash reference/;

        throws_ok {
            builder {
                enable 'SetAccept', from => 'suffix', mapping => sub {};
            };
        } qr/'mapping' parameter must be a hash reference/;

        lives_ok {
            builder {
                enable 'SetAccept', from => ['suffix', 'param'], param => 'format', mapping => {};
            };
        };

        throws_ok {
            builder {
                enable 'SetAccept', from => 'param', mapping => {};
            };
        } qr/'param' parameter is required when using 'param' for from/;

        throws_ok {
            builder {
                enable 'SetAccept', from => ['suffix', 'param'], mapping => {};
            };
        } qr/'param' parameter is required when using 'param' for from/;

        throws_ok {
            builder {
                enable 'SetAccept', from => [], mapping => {};
            };
        } qr/'from' parameter cannot be an empty array reference/;

        throws_ok {
            builder {
                enable 'SetAccept', from => ['suffix', 'frob'], mapping => {};
            };
        } qr/'frob' is not a valid value for the 'from' parameter/;

        $app = builder {
            enable 'SetAccept', from => ['suffix', 'param'], param => 'format', mapping => \%map, (defined $tolerant ? (tolerant => $tolerant) : ());
            $inner_app;
        };

        test_psgi $app, sub {
            my ( $cb ) = @_;

            my $res;

            $res = $cb->(REQUEST $method => '/foo');
            is $res->code, 200;
            is $res->content, '*/*';

            $res = $cb->(REQUEST $method => '/foo.json');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo.xml');
            is $res->code, 200;
            is $res->content, 'application/xml';

            $res = $cb->(REQUEST $method => '/foo?format=json');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo?format=xml');
            is $res->code, 200;
            is $res->content, 'application/xml';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo.yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:5000/foo.json">application/json</a></li><li><a href="http://localhost:5000/foo.xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo?format=yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:5000/foo?format=json">application/json</a></li><li><a href="http://localhost:5000/foo?format=xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:9000/bar.yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:9000/bar.json">application/json</a></li><li><a href="http://localhost:9000/bar.xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:9000/bar?format=yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:9000/bar?format=json">application/json</a></li><li><a href="http://localhost:9000/bar?format=xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => '/foo', Accept => 'application/json');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo', Accept => 'application/x-yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'application/x-yaml';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:5000/foo.json">application/json</a></li><li><a href="http://localhost:5000/foo.xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:9000/bar', Accept => 'application/x-yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'application/x-yaml';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:9000/bar.json">application/json</a></li><li><a href="http://localhost:9000/bar.xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo?format=json', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml, application/json';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo.json', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml, application/json';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo.json?format=json', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml, application/json';
        };

        $app = builder {
            enable 'SetAccept', from => ['param', 'suffix'], param => 'format', mapping => \%map, (defined $tolerant ? (tolerant => $tolerant) : ());
            $inner_app;
        };

        test_psgi $app, sub {
            my ( $cb ) = @_;

            my $res;

            $res = $cb->(REQUEST $method => '/foo');
            is $res->code, 200;
            is $res->content, '*/*';

            $res = $cb->(REQUEST $method => '/foo.json');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo.xml');
            is $res->code, 200;
            is $res->content, 'application/xml';

            $res = $cb->(REQUEST $method => '/foo?format=json');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo?format=xml');
            is $res->code, 200;
            is $res->content, 'application/xml';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo.yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:5000/foo.json">application/json</a></li><li><a href="http://localhost:5000/foo.xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo?format=yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:5000/foo?format=json">application/json</a></li><li><a href="http://localhost:5000/foo?format=xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:9000/bar.yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:9000/bar.json">application/json</a></li><li><a href="http://localhost:9000/bar.xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:9000/bar?format=yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'undef';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:9000/bar?format=json">application/json</a></li><li><a href="http://localhost:9000/bar?format=xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => '/foo', Accept => 'application/json');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo', Accept => 'application/x-yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'application/x-yaml';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:5000/foo?format=json">application/json</a></li><li><a href="http://localhost:5000/foo?format=xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:9000/bar', Accept => 'application/x-yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
                is $res->content, 'application/x-yaml';
            } else {
                is $res->code, 406;
                is $res->content_type, 'application/xhtml+xml';
                if($method eq 'GET') {
                    is_xml $res->content, '<html xmlns="http://www.w3.org/1999/xhtml"><body><ul><li><a href="http://localhost:9000/bar?format=json">application/json</a></li><li><a href="http://localhost:9000/bar?format=xml">application/xml</a></li></ul></body></html>';
                } else {
                    is $res->content, '';
                }
            }

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo?format=json', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml, application/json';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo.json', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml, application/json';

            $res = $cb->(REQUEST $method => 'http://localhost:5000/foo.json?format=json', Accept => 'application/xml');
            is $res->code, 200;
            is $res->content, 'application/xml, application/json';
        };

        test_psgi $app, sub {
            my ( $cb ) = @_;

            $res = $cb->(REQUEST $method => '/foo.json', Accept => '*/*');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo.json', Accept => 'application/*');
            is $res->code, 200;
            is $res->content, 'application/json';

            $res = $cb->(REQUEST $method => '/foo.json', Accept => 'text/*');
            is $res->code, 200;
            is $res->content, 'text/*, application/json';
        };

        $app = builder {
            enable 'SetAccept', from => ['suffix', 'param'], param => 'format', mapping => \%map, (defined $tolerant ? (tolerant => $tolerant) : ());
            sub {
                my ( $env ) = @_;

                return [
                    200,
                    ['Content-Type' => 'text/plain'],
                    [Dumper([
                        @{$env}{qw/PATH_INFO REQUEST_URI QUERY_STRING HTTP_ACCEPT/}
                    ])],
                ];
            };
        };

        test_psgi $app, sub {
            my ( $cb ) = @_;

            my ( $path_info, $request_uri, $query_string, $accept );

            $res = $cb->(REQUEST $method => '/');
            ( $path_info, $request_uri, $query_string ) =
                @{ eval $res->content };

            is $path_info, '/';
            is $request_uri, '/';
            is $query_string, '';

            $res = $cb->(REQUEST $method => '/foo.json?foo=bar');
            ( $path_info, $request_uri, $query_string ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo?foo=bar';
            is $query_string, 'foo=bar';

            $res = $cb->(REQUEST $method => '/foo?foo=bar&format=json');
            ( $path_info, $request_uri, $query_string ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo?foo=bar';
            is $query_string, 'foo=bar';

            $res = $cb->(REQUEST $method => '/foo?foo=bar&format=json');
            ( $path_info, $request_uri, $query_string ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo?foo=bar';
            is $query_string, 'foo=bar';

            $res = $cb->(REQUEST $method => '/foo.xml?foo=bar&format=json');
            ( $path_info, $request_uri, $query_string ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo?foo=bar';
            is $query_string, 'foo=bar';

            $res = $cb->(REQUEST $method => '/foo.bar.json?foo=bar');
            ( $path_info, $request_uri, $query_string, $accept ) =
                @{ eval $res->content };

            is $path_info, '/foo.bar';
            is $request_uri, '/foo.bar?foo=bar';
            is $query_string, 'foo=bar';
            is $accept, 'application/json';

            $res = $cb->(REQUEST $method => '/foo?format=json&foo=bar&format=xml');
            ( $path_info, $request_uri, $query_string, $accept ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo?foo=bar';
            is $query_string, 'foo=bar';
            is $accept, 'application/json, application/xml';

            $res = $cb->(REQUEST $method => '/foo.json', Accept => 'application/json');
            ( $path_info, $request_uri, undef, $accept ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo';
            is $accept, 'application/json';

            $res = $cb->(REQUEST $method => '/foo.yaml?format=json', Accept => 'application/json');
            is $res->code, 200;
            ( $path_info, $request_uri, undef, $accept ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo';
            is $accept, 'application/json';

            $res = $cb->(REQUEST $method => '/foo bar.json?value=I like spaces!', Accept => 'application/json');
            ( $path_info, $request_uri, $query_string, $accept ) =
                @{ eval $res->content };

            is $path_info, '/foo%20bar';
            is $request_uri, '/foo%20bar?value=I%20like%20spaces!';
            is $query_string, 'value=I%20like%20spaces!';
            is $accept, 'application/json';

            $res = $cb->(REQUEST $method => '/foo.json', Accept => 'text/plain, application/xml');
            ( $path_info, $request_uri, undef, $accept ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo';
            is $accept, 'text/plain, application/xml, application/json';

            $res = $cb->(REQUEST $method => '/foo.yaml', Accept => 'application/xml');
            ( $path_info, $request_uri, undef, $accept ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo';
            is $accept, 'application/xml';

            $res = $cb->(REQUEST $method => '/foo', Accept => 'text/plain, application/xml');
            ( $path_info, $request_uri, undef, $accept ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo';
            is $accept, 'text/plain, application/xml';

            $res = $cb->(REQUEST $method => '/foo', Accept => 'text/plain, application/xml; q=0.1');
            ( $path_info, $request_uri, undef, $accept ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo';
            is $accept, 'text/plain, application/xml; q=0.1';

            $res = $cb->(REQUEST $method => '/foo', Accept => 'text/plain, application/x-yaml');
            if(!defined($tolerant) || $tolerant) {
                is $res->code, 200;
                pass;
            } else {
                is $res->code, 406;
                $res = $cb->(REQUEST $method => '/foo', Accept => 'application/json; q=0.8');
                ( $path_info, $request_uri, undef, $accept ) =
                    @{ eval $res->content };

                is $accept, 'application/json; q=0.8';
            }
            is $path_info, '/foo';
            is $request_uri, '/foo';

            $res = $cb->(REQUEST $method => '/foo.xml', Accept => 'application/json; q=0.8');
            ( $path_info, $request_uri, undef, $accept ) =
                @{ eval $res->content };

            is $path_info, '/foo';
            is $request_uri, '/foo';
            is $accept, 'application/json; q=0.8, application/xml';
        };

        $app = builder {
            enable 'SetAccept', from => ['suffix'], mapping => {
                json => 'application/json; q=0.2',
            }, (defined $tolerant ? (tolerant => $tolerant) : ());

            sub {
                my ( $env ) = @_;

                return [
                    200,
                    ['Content-Type' => 'text/plain'],
                    [Dumper([
                        @{$env}{qw/PATH_INFO REQUEST_URI QUERY_STRING HTTP_ACCEPT/}
                    ])],
                ];
            };
        };

        test_psgi $app, sub {
            my ( $cb ) = @_;

            my ( $path_info, $request_uri, $query_string, $accept );

            $res = $cb->(REQUEST $method => '/foo.json');
            is $res->code, 200;
            ( undef, undef, undef, $accept ) =
                @{ eval $res->content };
            is $accept, 'application/json; q=0.2';

            $res = $cb->(REQUEST $method => '/foo.json', Accept => 'application/json; q=0.2');
            is $res->code, 200;
            ( undef, undef, undef, $accept ) =
                @{ eval $res->content };
            is $accept, 'application/json; q=0.2';

            $res = $cb->(REQUEST $method => '/foo.json', Accept => 'application/json');
            is $res->code, 200;
            ( undef, undef, undef, $accept ) =
                @{ eval $res->content };
            is $accept, 'application/json; q=0.2';

            $res = $cb->(REQUEST $method => '/foo.json', Accept => 'application/json; q=0.3');
            is $res->code, 200;
            ( undef, undef, undef, $accept ) =
                @{ eval $res->content };
            is $accept, 'application/json; q=0.2';
        };
    }
}

my $inner_app = sub {
    my ( $env ) = @_;

    return [
        200,
        ['Content-Type' => 'text/plain'],
        [$env->{'HTTP_ACCEPT'} || 'undef'],
    ]
};

my %map = (
    json => 'application/json',
    xml  => 'application/xml',
);

my $app = builder {
    enable 'SetAccept', from => 'suffix', mapping => \%map;
    $inner_app;
};

my $res;

test_psgi $app, sub {
    my ( $cb ) = @_;

    $res = $cb->(REQUEST POST => '/foo.json');
    is $res->code, 200;
    is $res->content, 'undef';

    $res = $cb->(REQUEST POST => '/foo.json', Accept => 'application/xml');
    is $res->code, 200;
    is $res->content, 'application/xml';
};

