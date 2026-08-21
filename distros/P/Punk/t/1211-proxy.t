#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();

# The `proxy` keyword end to end: what pp_resolve does to the env at the top
# of punk_serve, and what the keyword refuses at boot.
#
# The point of rewriting REMOTE_ADDR rather than adding a new key is that
# every existing consumer - rate_limit, block_ip, the access log, $c->req -
# becomes correct without any of them being changed. So the assertions here
# are about the env a handler sees.

sub caller_for {
    my ($app) = @_;
    return sub {
        my (%a) = @_;
        open my $in, '<', \'';
        my $env = {
            REQUEST_METHOD => $a{method} // 'GET',
            PATH_INFO      => $a{path}   // '/env',
            QUERY_STRING   => '',
            SERVER_NAME    => 'localhost',
            SERVER_PORT    => 80,
            HTTP_HOST      => 'localhost',
            REMOTE_ADDR    => $a{peer} // '10.0.0.1',
            REMOTE_PORT    => 54321,
            'psgi.url_scheme' => 'http',
            'psgi.input'      => $in,
        };
        $env->{HTTP_X_FORWARDED_FOR}   = $a{xff}   if defined $a{xff};
        $env->{HTTP_X_FORWARDED_PROTO} = $a{proto} if defined $a{proto};
        $env->{HTTP_X_FORWARDED_HOST}  = $a{host}  if defined $a{host};
        $env->{HTTP_X_FORWARDED_PORT}  = $a{port}  if defined $a{port};
        $env->{"HTTP_\U$a{hdr}"}       = $a{hval}  if defined $a{hdr};
        my $res = $app->($env);
        return $res;
    };
}

# The handler echoes back exactly the env keys under test, so what is
# asserted is what a real handler would read.
sub echo {
    my ($c) = @_;
    my $e = $c->env;
    return $c->json({
        remote_addr => $e->{REMOTE_ADDR},
        remote_port => $e->{REMOTE_PORT},
        peer_addr   => $e->{'punk.peer_addr'},
        scheme      => $e->{'psgi.url_scheme'},
        https       => $e->{HTTPS},
        host        => $e->{HTTP_HOST},
        port        => $e->{SERVER_PORT},
        req_address => $c->req->address,
    });
}

sub body_of {
    my ($res) = @_;
    require JSON::PP;
    return JSON::PP::decode_json(join '', @{ $res->[2] });
}

# ---- no policy: nothing happens at all -------------------------------------

{
    package NoProxy;
    use Punk;
    get '/env' => \&main::echo;
}
{
    my $call = caller_for(NoProxy->to_app);
    my $d = body_of($call->(xff => '1.2.3.4'));
    is $d->{remote_addr}, '10.0.0.1',
       'without `proxy` the forwarded header is ignored entirely';
    is $d->{remote_port}, 54321, 'REMOTE_PORT untouched';
    is $d->{peer_addr}, undef,
       'punk.peer_addr is not even set when no policy resolved the request';
}

# ---- one hop, the common case ----------------------------------------------

{
    package OneHop;
    use Punk;
    proxy;
    get '/env' => \&main::echo;
}
{
    my $call = caller_for(OneHop->to_app);

    my $d = body_of($call->(xff => '1.2.3.4'));
    is $d->{remote_addr}, '1.2.3.4', 'bare `proxy` resolves one hop';
    is $d->{req_address}, '1.2.3.4',
       '$c->req->address follows, with no change to Punk::Request';
    is $d->{peer_addr}, '10.0.0.1', 'the socket peer is preserved';
    is $d->{remote_port}, undef,
       'REMOTE_PORT is dropped: it described the proxy socket and is now a lie';

    # the spoof, through a real request this time
    $d = body_of($call->(xff => '9.9.9.9, 1.2.3.4'));
    is $d->{remote_addr}, '1.2.3.4',
       'a client-forged leading entry does not become REMOTE_ADDR';

    $d = body_of($call->());
    is $d->{remote_addr}, '10.0.0.1', 'no header: the peer, unchanged';
    is $d->{remote_port}, 54321, 'and the port survives when nothing moved';
    is $d->{peer_addr}, '10.0.0.1', 'punk.peer_addr is set regardless';
}

# ---- scheme, host and port -------------------------------------------------

{
    package Fwd;
    use Punk;
    proxy;
    get '/env' => \&main::echo;
}
{
    my $call = caller_for(Fwd->to_app);

    my $d = body_of($call->(proto => 'https'));
    is $d->{scheme}, 'https',
       'X-Forwarded-Proto sets psgi.url_scheme behind terminated TLS';
    is $d->{https}, 'on', 'and HTTPS=on, which is the key other code reads';

    $d = body_of($call->(proto => 'HTTPS'));
    is $d->{scheme}, 'https', 'the scheme compare is case-insensitive';

    $d = body_of($call->(proto => 'https, http'));
    is $d->{scheme}, 'https',
       'a comma-joined proto list takes the client-facing (leftmost) hop';

    $d = body_of($call->(proto => 'gopher'));
    is $d->{scheme}, 'http', 'an unknown scheme changes nothing';

    $d = body_of($call->(host => 'app.example.com'));
    is $d->{host}, 'app.example.com', 'X-Forwarded-Host sets HTTP_HOST';

    $d = body_of($call->(port => '443'));
    is $d->{port}, '443', 'X-Forwarded-Port sets SERVER_PORT';

    $d = body_of($call->(port => '44a3'));
    is $d->{port}, 80, 'a non-numeric forwarded port is ignored';
}

# ---- custom header names ---------------------------------------------------

{
    package Custom;
    use Punk;
    proxy trust => 1, for_header => 'CF-Connecting-IP';
    get '/env' => \&main::echo;
}
{
    my $call = caller_for(Custom->to_app);
    my $d = body_of($call->(hdr => 'CF_CONNECTING_IP', hval => '1.2.3.4',
                            xff => '9.9.9.9'));
    is $d->{remote_addr}, '1.2.3.4', 'for_header names a different header';
    isnt $d->{remote_addr}, '9.9.9.9',
       'and the standard X-Forwarded-For is not consulted once it is renamed';
}

# ---- CIDR trust ------------------------------------------------------------

{
    package Cidr;
    use Punk;
    proxy trust => ['10.0.0.0/8'];
    get '/env' => \&main::echo;
}
{
    my $call = caller_for(Cidr->to_app);
    my $d = body_of($call->(xff => '1.2.3.4, 10.0.0.7', peer => '10.0.0.1'));
    is $d->{remote_addr}, '1.2.3.4', 'CIDR trust walks to the first outsider';

    $d = body_of($call->(xff => '1.2.3.4, 10.0.0.7', peer => '8.8.8.8'));
    is $d->{remote_addr}, '8.8.8.8',
       'an untrusted socket peer means the header is not believed';
}

# ---- what block_ip does behind a proxy -------------------------------------

# Banning the address the socket came from bans the load balancer. Boot config
# cannot catch it, and a silent no-op would leave an operator believing they
# had banned someone.
{
    package Ban;
    use Punk;
    proxy;
    get '/ban-peer'   => sub {
        my ($c) = @_;
        $c->block_ip($c->env->{'punk.peer_addr'});
        $c->text('banned');
    };
    get '/ban-client' => sub {
        my ($c) = @_;
        $c->block_ip($c->req->address);
        $c->text('banned');
    };
    get '/env' => \&main::echo;
}
{
    my $call = caller_for(Ban->to_app);

    my $res = $call->(path => '/ban-peer', xff => '1.2.3.4');
    is $res->[0], 500, 'block_ip on the proxy address is refused';
    like join('', @{ $res->[2] }), qr/reverse proxy|took the site down|would take/i,
        'and says why rather than failing silently';

    $res = $call->(path => '/ban-client', xff => '1.2.3.4');
    is $res->[0], 200, 'banning the real client is fine';
}

# ---- boot-time refusals ----------------------------------------------------

sub boot_fails {
    my ($body, $like, $what) = @_;
    my $pkg = 'Boot' . int(rand 1e9);
    eval "package $pkg; use Punk; $body; ${pkg}->to_app; 1";
    my $err = $@ || '';
    like $err, $like, $what;
}

boot_fails 'proxy trust => "sideways"', qr/hop count|arrayref|'all'/,
    'a nonsense trust value croaks at boot';
boot_fails 'proxy trust => 0', qr/usable hop count/,
    'trust => 0 croaks rather than meaning something';
boot_fails 'proxy trust => -1', qr/usable hop count/,
    'a negative hop count croaks';
boot_fails 'proxy trust => ["10.0.0.0/8", "not-a-network"]',
    qr/not an address or CIDR/,
    'a mistyped CIDR croaks at boot, not per request';
boot_fails 'proxy trust => ["10.0.0.0/64"]', qr/not an address or CIDR/,
    'a v4 prefix longer than 32 croaks';
boot_fails 'proxy trust => []', qr/trusts nothing/,
    'an empty trust list croaks instead of silently trusting nothing';
boot_fails 'proxy trust => {}', qr/hop count|arrayref|'all'/,
    'a hashref trust value croaks';
boot_fails 'proxy unknown_option => 1', qr/unknown option 'unknown_option'/,
    'an unknown option croaks and names itself';
boot_fails 'proxy; proxy trust => 2', qr/already declared/,
    'a second `proxy` croaks rather than replacing the first';

# trust => 'all' believes anyone. With no proxy in front that is a total
# bypass, so it must not be reachable by typo in production.
{
    local $ENV{PUNK_ENV} = 'production';
    boot_fails "proxy trust => 'all'", qr/development/,
        "trust => 'all' is refused in production";
}
{
    local $ENV{PUNK_ENV} = 'development';
    my $pkg = 'BootDev' . int(rand 1e9);
    eval "package $pkg; use Punk; proxy trust => 'all';"
       . "get '/env' => \\&main::echo; ${pkg}->to_app; 1";
    is $@, '', "trust => 'all' is allowed under PUNK_ENV=development";
}

done_testing;
