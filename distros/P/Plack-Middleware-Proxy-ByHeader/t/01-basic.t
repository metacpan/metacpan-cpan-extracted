use Plack::Test;
use Test::More;
use Plack::Middleware::Proxy::ByHeader;
use HTTP::Request::Common;
use Plack::Builder;
use URI;

my $err;
eval {
    builder { enable "Proxy::ByHeader", header => 'X-Taz-Proxy-To' };
};
chomp( $err = $@ );
$err =~ s/ at .*//;
is( $err, q{argument to 'header' must be an array reference} );

eval {
    builder { enable "Proxy::ByHeader", allowed => 'www.taz.de' };
};
chomp( $err = $@ );
$err =~ s/ at .*//;
is( $err, q{argument to 'allowed' must be an array reference} );

test_by_header(
    req_header  => [ Host => 'example.com', 'X-Taz-Proxy-To' => 'www.example.com', 'X-Taz-Proxy-To' => 'www2.example.com' ],
    by_header   => [ 'X-Taz-Proxy-To', 'Host' ],
    allowed     => [ 'example.com', 'www.example.com','www2.example.com'],
    expect      => 'http://www2.example.com/foo',
    description => 'use last value if header is sent multiple times',
);

test_by_header(
    req_header  => [ Host => 'example.com', 'X-Taz-Proxy-To' => 'www.example.com' ],
    by_header   => [ 'X-Taz-Proxy-To', 'Host' ],
    allowed     => [ 'example.com', 'www.example.com'],
    expect      => 'http://www.example.com/foo',
    description => 'use first by header'
);

test_by_header(
    req_header  => [ Host => 'example.com' ],
    by_header   => [ 'X-Taz-Proxy-To', 'Host' ],
    allowed     => ['example.com'],
    expect      => 'http://example.com/foo',
    description => 'use second by header'
);

test_by_header(
    req_header  => [ Host => 'example.com', 'X-Taz-Proxy-To' => 'www.example.com' ],
    by_header   => [ 'X-Taz-Proxy-To', 'Host' ],
    allowed     => [ 'example.com' ],
    expect      => '',
    description => 'use first by header, but not allowed, no fallback'
);

test_by_header(
    req_header  => [ Host => 'example.com' ],
    by_header   => undef,
    allowed     => [ 'example.com' ],
    expect      => 'http://example.com/foo',
    description => 'use default Host header'
);

test_by_header(
    req_header  => [ Host => 'example.com' ],
    by_header   => [],
    allowed     => [ 'example.com' ],
    expect      => '',
    description => 'ignore Host header if explicit empty array ref for header',
);

test_by_header(
    req_header  => [],
    by_header   => [],
    allowed     => [],
    expect      => '',
    description => 'no header, no allowed, no req header, no plack.proxy.url',
);

test_by_header(
    req_header  => [ 'X-Taz-Proxy-To' => 'www.example.com' ],
    by_header   => [ 'X-Taz-Proxy-To' ],
    allowed     => [],
    expect      => 'http://www.example.com/foo',
    description => 'empty allow allowes everything',
);


sub test_by_header {
    my %arg = @_;
    my $proxy_url;
    my %byheader_args;

    $byheader_args{header}  = $arg{by_header} if defined $arg{by_header};
    $byheader_args{allowed} = $arg{allowed}   if defined $arg{allowed};

    test_psgi(
        app => builder {
            enable "Proxy::ByHeader", %byheader_args;
            sub {
                my ($env) = shift;
                return [ 200, [], [ $env->{'plack.proxy.url'} ] ];
              }
        },
        client => sub {
            my $cb = shift;
            my $res = $cb->( GET "/foo", @{$arg{req_header}} );
            $proxy_url = $res->content;
        }
    );
    is( $proxy_url, $arg{expect}, $arg{description} );
    return;
}

done_testing();
