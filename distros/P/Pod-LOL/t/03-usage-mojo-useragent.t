#!perl
use v5.26;    # Indented heredoc.
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );

BEGIN {
   use_ok( 'Pod::LOL' ) || print "Bail out!\n";
}

diag( "Testing Pod::LOL $Pod::LOL::VERSION, Perl $], $^X" );

my @cases = (
   {
      name          => "Module - Mojo::UserAgent",
      expected_root => [
         [ "head1", "NAME" ],
         [
            "Para",
            "Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent"
         ],
         [ "head1", "SYNOPSIS" ],
         [
            "Verbatim",
"  use Mojo::UserAgent;\n\n  # Fine grained response handling (dies on connection errors)\n  my \$ua  = Mojo::UserAgent->new;\n  my \$res = \$ua->get('docs.mojolicious.org')->result;\n  if    (\$res->is_success)  { say \$res->body }\n  elsif (\$res->is_error)    { say \$res->message }\n  elsif (\$res->code == 301) { say \$res->headers->location }\n  else                      { say 'Whatever...' }\n\n  # Say hello to the Unicode snowman and include an Accept header\n  say \$ua->get('www.\x{2603}.net?hello=there' => {Accept => '*/*'})->result->body;\n\n  # Extract data from HTML and XML resources with CSS selectors\n  say \$ua->get('www.perl.org')->result->dom->at('title')->text;\n\n  # Scrape the latest headlines from a news site\n  say \$ua->get('blogs.perl.org')->result->dom->find('h2 > a')->map('text')->join(\"\\n\");\n\n  # IPv6 PUT request with Content-Type header and content\n  my \$tx = \$ua->put('[::1]:3000' => {'Content-Type' => 'text/plain'} => 'Hi!');\n\n  # Quick JSON API request with Basic authentication\n  my \$url = Mojo::URL->new('https://example.com/test.json')->userinfo('sri:\x{2603}');\n  my \$value = \$ua->get(\$url)->result->json;\n\n  # JSON POST (application/json) with TLS certificate authentication\n  my \$tx = \$ua->cert('tls.crt')->key('tls.key')->post('https://example.com' => json => {top => 'secret'});\n\n  # Form POST (application/x-www-form-urlencoded)\n  my \$tx = \$ua->post('https://metacpan.org/search' => form => {q => 'mojo'});\n\n  # Search DuckDuckGo anonymously through Tor\n  \$ua->proxy->http('socks://127.0.0.1:9050');\n  say \$ua->get('api.3g2upl4pq6kufc4m.onion/?q=mojolicious&format=json')->result->json('/Abstract');\n\n  # GET request via UNIX domain socket \"/tmp/myapp.sock\" (percent encoded slash)\n  say \$ua->get('http+unix://%2Ftmp%2Fmyapp.sock/test')->result->body;\n\n  # Follow redirects to download Mojolicious from GitHub\n  \$ua->max_redirects(5)\n    ->get('https://www.github.com/mojolicious/mojo/tarball/main')\n    ->result->save_to('/home/sri/mojo.tar.gz');\n\n  # Non-blocking request\n  \$ua->get('mojolicious.org' => sub (\$ua, \$tx) { say \$tx->result->dom->at('title')->text });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;\n\n  # Concurrent non-blocking requests (synchronized with promises)\n  my \$mojo_promise = \$ua->get_p('mojolicious.org');\n  my \$cpan_promise = \$ua->get_p('cpan.org');\n  Mojo::Promise->all(\$mojo_promise, \$cpan_promise)->then(sub (\$mojo, \$cpan) {\n    say \$mojo->[0]->result->dom->at('title')->text;\n    say \$cpan->[0]->result->dom->at('title')->text;\n  })->wait;\n\n  # WebSocket connection sending and receiving JSON via UNIX domain socket\n  \$ua->websocket('ws+unix://%2Ftmp%2Fmyapp.sock/echo.json' => sub (\$ua, \$tx) {\n    say 'WebSocket handshake failed!' and return unless \$tx->is_websocket;\n    \$tx->on(json => sub (\$tx, \$hash) {\n      say \"WebSocket message via JSON: \$hash->{msg}\";\n      \$tx->finish;\n    });\n    \$tx->send({json => {msg => 'Hello World!'}});\n  });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [ "head1", "DESCRIPTION" ],
         [
            "Para",
"Mojo::UserAgent is a full featured non-blocking I/O HTTP and WebSocket user agent, with IPv6, TLS, SNI, IDNA, HTTP/SOCKS5 proxy, UNIX domain socket, Comet (long polling), Promises/A+, keep-alive, connection pooling, timeout, cookie, multipart, gzip compression and multiple event loop support."
         ],
         [
            "Para",
"All connections will be reset automatically if a new process has been forked, this allows multiple processes to share the same Mojo::UserAgent object safely."
         ],
         [
            "Para",
"For better scalability (epoll, kqueue) and to provide non-blocking name resolution, SOCKS5 as well as TLS support, the optional modules EV (4.32+), Net::DNS::Native (0.15+), IO::Socket::Socks (0.64+) and IO::Socket::SSL (2.009+) will be used automatically if possible. Individual features can also be disabled with the MOJO_NO_NNR, MOJO_NO_SOCKS and MOJO_NO_TLS environment variables."
         ],
         [
            "Para",
            "See \"USER AGENT\" in Mojolicious::Guides::Cookbook for more."
         ],
         [ "head1", "EVENTS" ],
         [
            "Para",
"Mojo::UserAgent inherits all events from Mojo::EventEmitter and can emit the following new ones."
         ],
         [ "head2",    "prepare" ],
         [ "Verbatim", "  \$ua->on(prepare => sub (\$ua, \$tx) {...});" ],
         [
            "Para",
"Emitted whenever a new transaction is being prepared, before relative URLs are rewritten and cookies added. This includes automatically prepared proxy CONNECT requests and followed redirects."
         ],
         [
            "Verbatim",
"  \$ua->on(prepare => sub (\$ua, \$tx) {\n    \$tx->req->url(Mojo::URL->new('/mock-mojolicious')) if \$tx->req->url->host eq 'mojolicious.org';\n  });"
         ],
         [ "head2",    "start" ],
         [ "Verbatim", "  \$ua->on(start => sub (\$ua, \$tx) {...});" ],
         [
            "Para",
"Emitted whenever a new transaction is about to start. This includes automatically prepared proxy CONNECT requests and followed redirects."
         ],
         [
            "Verbatim",
"  \$ua->on(start => sub (\$ua, \$tx) {\n    \$tx->req->headers->header('X-Bender' => 'Bite my shiny metal ass!');\n  });"
         ],
         [ "head1", "ATTRIBUTES" ],
         [ "Para",  "Mojo::UserAgent implements the following attributes." ],
         [ "head2", "ca" ],
         [
            "Verbatim",
            "  my \$ca = \$ua->ca;\n  \$ua    = \$ua->ca('/etc/tls/ca.crt');"
         ],
         [
            "Para",
"Path to TLS certificate authority file used to verify the peer certificate, defaults to the value of the MOJO_CA_FILE environment variable."
         ],
         [
            "Verbatim",
"  # Show certificate authorities for debugging\n  IO::Socket::SSL::set_defaults(SSL_verify_callback => sub { say \"Authority: \$_[2]\" and return \$_[0] });"
         ],
         [ "head2", "cert" ],
         [
            "Verbatim",
"  my \$cert = \$ua->cert;\n  \$ua      = \$ua->cert('/etc/tls/client.crt');"
         ],
         [
            "Para",
"Path to TLS certificate file, defaults to the value of the MOJO_CERT_FILE environment variable."
         ],
         [ "head2", "connect_timeout" ],
         [
            "Verbatim",
"  my \$timeout = \$ua->connect_timeout;\n  \$ua         = \$ua->connect_timeout(5);"
         ],
         [
            "Para",
"Maximum amount of time in seconds establishing a connection may take before getting canceled, defaults to the value of the MOJO_CONNECT_TIMEOUT environment variable or 10."
         ],
         [ "head2", "cookie_jar" ],
         [
            "Verbatim",
"  my \$cookie_jar = \$ua->cookie_jar;\n  \$ua            = \$ua->cookie_jar(Mojo::UserAgent::CookieJar->new);"
         ],
         [
            "Para",
"Cookie jar to use for requests performed by this user agent, defaults to a Mojo::UserAgent::CookieJar object."
         ],
         [
            "Verbatim",
"  # Ignore all cookies\n  \$ua->cookie_jar->ignore(sub { 1 });\n\n  # Ignore cookies for public suffixes\n  my \$ps = IO::Socket::SSL::PublicSuffix->default;\n  \$ua->cookie_jar->ignore(sub (\$cookie) {\n    return undef unless my \$domain = \$cookie->domain;\n    return (\$ps->public_suffix(\$domain))[0] eq '';\n  });\n\n  # Add custom cookie to the jar\n  \$ua->cookie_jar->add(\n    Mojo::Cookie::Response->new(\n      name   => 'foo',\n      value  => 'bar',\n      domain => 'docs.mojolicious.org',\n      path   => '/Mojolicious'\n    )\n  );"
         ],
         [ "head2", "inactivity_timeout" ],
         [
            "Verbatim",
"  my \$timeout = \$ua->inactivity_timeout;\n  \$ua         = \$ua->inactivity_timeout(15);"
         ],
         [
            "Para",
"Maximum amount of time in seconds a connection can be inactive before getting closed, defaults to the value of the MOJO_INACTIVITY_TIMEOUT environment variable or 40. Setting the value to 0 will allow connections to be inactive indefinitely."
         ],
         [ "head2", "insecure" ],
         [
            "Verbatim",
"  my \$bool = \$ua->insecure;\n  \$ua      = \$ua->insecure(\$bool);"
         ],
         [
            "Para",
"Do not require a valid TLS certificate to access HTTPS/WSS sites, defaults to the value of the MOJO_INSECURE environment variable."
         ],
         [
            "Verbatim",
"  # Disable TLS certificate verification for testing\n  say \$ua->insecure(1)->get('https://127.0.0.1:3000')->result->code;"
         ],
         [ "head2", "ioloop" ],
         [
            "Verbatim",
"  my \$loop = \$ua->ioloop;\n  \$ua      = \$ua->ioloop(Mojo::IOLoop->new);"
         ],
         [
            "Para",
"Event loop object to use for blocking I/O operations, defaults to a Mojo::IOLoop object."
         ],
         [ "head2", "key" ],
         [
            "Verbatim",
"  my \$key = \$ua->key;\n  \$ua     = \$ua->key('/etc/tls/client.crt');"
         ],
         [
            "Para",
"Path to TLS key file, defaults to the value of the MOJO_KEY_FILE environment variable."
         ],
         [ "head2", "max_connections" ],
         [
            "Verbatim",
"  my \$max = \$ua->max_connections;\n  \$ua     = \$ua->max_connections(5);"
         ],
         [
            "Para",
"Maximum number of keep-alive connections that the user agent will retain before it starts closing the oldest ones, defaults to 5. Setting the value to 0 will prevent any connections from being kept alive."
         ],
         [ "head2", "max_redirects" ],
         [
            "Verbatim",
"  my \$max = \$ua->max_redirects;\n  \$ua     = \$ua->max_redirects(3);"
         ],
         [
            "Para",
"Maximum number of redirects the user agent will follow before it fails, defaults to the value of the MOJO_MAX_REDIRECTS environment variable or 0."
         ],
         [ "head2", "max_response_size" ],
         [
            "Verbatim",
"  my \$max = \$ua->max_response_size;\n  \$ua     = \$ua->max_response_size(16777216);"
         ],
         [
            "Para",
"Maximum response size in bytes, defaults to the value of \"max_message_size\" in Mojo::Message::Response. Setting the value to 0 will allow responses of indefinite size. Note that increasing this value can also drastically increase memory usage, should you for example attempt to parse an excessively large response body with the methods \"dom\" in Mojo::Message or \"json\" in Mojo::Message."
         ],
         [ "head2", "proxy" ],
         [
            "Verbatim",
"  my \$proxy = \$ua->proxy;\n  \$ua       = \$ua->proxy(Mojo::UserAgent::Proxy->new);"
         ],
         [
            "Para",
            "Proxy manager, defaults to a Mojo::UserAgent::Proxy object."
         ],
         [
            "Verbatim",
"  # Detect proxy servers from environment\n  \$ua->proxy->detect;\n\n  # Manually configure HTTP proxy (using CONNECT for HTTPS/WebSockets)\n  \$ua->proxy->http('http://127.0.0.1:8080')->https('http://127.0.0.1:8080');\n\n  # Manually configure Tor (SOCKS5)\n  \$ua->proxy->http('socks://127.0.0.1:9050')->https('socks://127.0.0.1:9050');\n\n  # Manually configure UNIX domain socket (using CONNECT for HTTPS/WebSockets)\n  \$ua->proxy->http('http+unix://%2Ftmp%2Fproxy.sock') ->https('http+unix://%2Ftmp%2Fproxy.sock');"
         ],
         [ "head2", "request_timeout" ],
         [
            "Verbatim",
"  my \$timeout = \$ua->request_timeout;\n  \$ua         = \$ua->request_timeout(5);"
         ],
         [
            "Para",
"Maximum amount of time in seconds establishing a connection, sending the request and receiving a whole response may take before getting canceled, defaults to the value of the MOJO_REQUEST_TIMEOUT environment variable or 0. Setting the value to 0 will allow the user agent to wait indefinitely. The timeout will reset for every followed redirect."
         ],
         [
            "Verbatim",
"  # Total limit of 5 seconds, of which 3 seconds may be spent connecting\n  \$ua->max_redirects(0)->connect_timeout(3)->request_timeout(5);"
         ],
         [ "head2", "server" ],
         [
            "Verbatim",
"  my \$server = \$ua->server;\n  \$ua        = \$ua->server(Mojo::UserAgent::Server->new);"
         ],
         [
            "Para",
"Application server relative URLs will be processed with, defaults to a Mojo::UserAgent::Server object."
         ],
         [
            "Verbatim",
"  # Mock web service\n  \$ua->server->app(Mojolicious->new);\n  \$ua->server->app->routes->get('/time' => sub (\$c) {\n    \$c->render(json => {now => time});\n  });\n  my \$time = \$ua->get('/time')->result->json->{now};\n\n  # Change log level\n  \$ua->server->app->log->level('fatal');\n\n  # Port currently used for processing relative URLs blocking\n  say \$ua->server->url->port;\n\n  # Port currently used for processing relative URLs non-blocking\n  say \$ua->server->nb_url->port;"
         ],
         [ "head2", "socket_options" ],
         [
            "Verbatim",
"  my \$options = \$ua->socket_options;\n  \$ua         = \$ua->socket_options({LocalAddr => '127.0.0.1'});"
         ],
         [
            "Para",
"Additional options for IO::Socket::IP when opening new connections."
         ],
         [ "head2", "transactor" ],
         [
            "Verbatim",
"  my \$t = \$ua->transactor;\n  \$ua   = \$ua->transactor(Mojo::UserAgent::Transactor->new);"
         ],
         [
            "Para",
"Transaction builder, defaults to a Mojo::UserAgent::Transactor object."
         ],
         [
            "Verbatim",
"  # Change name of user agent\n  \$ua->transactor->name('MyUA 1.0');\n\n  # Disable compression\n  \$ua->transactor->compressed(0);"
         ],
         [ "head1", "METHODS" ],
         [
            "Para",
"Mojo::UserAgent inherits all methods from Mojo::EventEmitter and implements the following new ones."
         ],
         [ "head2", "build_tx" ],
         [
            "Verbatim",
"  my \$tx = \$ua->build_tx(GET => 'example.com');\n  my \$tx = \$ua->build_tx(PUT => 'http://example.com' => {Accept => '*/*'} => 'Content!');\n  my \$tx = \$ua->build_tx(PUT => 'http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$tx = \$ua->build_tx(PUT => 'http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
         ],
         [
            "Para",
"Generate Mojo::Transaction::HTTP object with \"tx\" in Mojo::UserAgent::Transactor."
         ],
         [
            "Verbatim",
"  # Request with custom cookie\n  my \$tx = \$ua->build_tx(GET => 'https://example.com/account');\n  \$tx->req->cookies({name => 'user', value => 'sri'});\n  \$tx = \$ua->start(\$tx);\n\n  # Deactivate gzip compression\n  my \$tx = \$ua->build_tx(GET => 'example.com');\n  \$tx->req->headers->remove('Accept-Encoding');\n  \$tx = \$ua->start(\$tx);\n\n  # Interrupt response by raising an error\n  my \$tx = \$ua->build_tx(GET => 'http://example.com');\n  \$tx->res->on(progress => sub (\$res) {\n    return unless my \$server = \$res->headers->server;\n    \$res->error({message => 'Oh noes, it is IIS!'}) if \$server =~ /IIS/;\n  });\n  \$tx = \$ua->start(\$tx);"
         ],
         [ "head2", "build_websocket_tx" ],
         [
            "Verbatim",
"  my \$tx = \$ua->build_websocket_tx('ws://example.com');\n  my \$tx = \$ua->build_websocket_tx( 'ws://example.com' => {DNT => 1} => ['v1.proto']);"
         ],
         [
            "Para",
"Generate Mojo::Transaction::HTTP object with \"websocket\" in Mojo::UserAgent::Transactor."
         ],
         [
            "Verbatim",
"  # Custom WebSocket handshake with cookie\n  my \$tx = \$ua->build_websocket_tx('wss://example.com/echo');\n  \$tx->req->cookies({name => 'user', value => 'sri'});\n  \$ua->start(\$tx => sub (\$ua, \$tx) {\n    say 'WebSocket handshake failed!' and return unless \$tx->is_websocket;\n    \$tx->on(message => sub (\$tx, \$msg) {\n      say \"WebSocket message: \$msg\";\n      \$tx->finish;\n    });\n    \$tx->send('Hi!');\n  });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [ "head2", "delete" ],
         [
            "Verbatim",
"  my \$tx = \$ua->delete('example.com');\n  my \$tx = \$ua->delete('http://example.com' => {Accept => '*/*'} => 'Content!');\n  my \$tx = \$ua->delete('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$tx = \$ua->delete('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
         ],
         [
            "Para",
"Perform blocking DELETE request and return resulting Mojo::Transaction::HTTP object, takes the same arguments as \"tx\" in Mojo::UserAgent::Transactor (except for the DELETE method, which is implied). You can also append a callback to perform requests non-blocking."
         ],
         [
            "Verbatim",
"  \$ua->delete('http://example.com' => json => {a => 'b'} => sub (\$ua, \$tx) { say \$tx->result->body });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [ "head2", "delete_p" ],
         [
            "Verbatim",
            "  my \$promise = \$ua->delete_p('http://example.com');"
         ],
         [
            "Para",
"Same as \"delete\", but performs all requests non-blocking and returns a Mojo::Promise object instead of accepting a callback."
         ],
         [
            "Verbatim",
"  \$ua->delete_p('http://example.com' => json => {a => 'b'})->then(sub (\$tx) {\n    say \$tx->result->body;\n  })->catch(sub (\$err) {\n    warn \"Connection error: \$err\";\n  })->wait;"
         ],
         [ "head2", "get" ],
         [
            "Verbatim",
"  my \$tx = \$ua->get('example.com');\n  my \$tx = \$ua->get('http://example.com' => {Accept => '*/*'} => 'Content!');\n  my \$tx = \$ua->get('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$tx = \$ua->get('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
         ],
         [
            "Para",
"Perform blocking GET request and return resulting Mojo::Transaction::HTTP object, takes the same arguments as \"tx\" in Mojo::UserAgent::Transactor (except for the GET method, which is implied). You can also append a callback to perform requests non-blocking."
         ],
         [
            "Verbatim",
"  \$ua->get('http://example.com' => json => {a => 'b'} => sub (\$ua, \$tx) { say \$tx->result->body });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [ "head2",    "get_p" ],
         [ "Verbatim", "  my \$promise = \$ua->get_p('http://example.com');" ],
         [
            "Para",
"Same as \"get\", but performs all requests non-blocking and returns a Mojo::Promise object instead of accepting a callback."
         ],
         [
            "Verbatim",
"  \$ua->get_p('http://example.com' => json => {a => 'b'})->then(sub (\$tx) {\n    say \$tx->result->body;\n  })->catch(sub (\$err) {\n    warn \"Connection error: \$err\";\n  })->wait;"
         ],
         [ "head2", "head" ],
         [
            "Verbatim",
"  my \$tx = \$ua->head('example.com');\n  my \$tx = \$ua->head('http://example.com' => {Accept => '*/*'} => 'Content!');\n  my \$tx = \$ua->head('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$tx = \$ua->head('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
         ],
         [
            "Para",
"Perform blocking HEAD request and return resulting Mojo::Transaction::HTTP object, takes the same arguments as \"tx\" in Mojo::UserAgent::Transactor (except for the HEAD method, which is implied). You can also append a callback to perform requests non-blocking."
         ],
         [
            "Verbatim",
"  \$ua->head('http://example.com' => json => {a => 'b'} => sub (\$ua, \$tx) { say \$tx->result->body });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [ "head2",    "head_p" ],
         [ "Verbatim", "  my \$promise = \$ua->head_p('http://example.com');" ],
         [
            "Para",
"Same as \"head\", but performs all requests non-blocking and returns a Mojo::Promise object instead of accepting a callback."
         ],
         [
            "Verbatim",
"  \$ua->head_p('http://example.com' => json => {a => 'b'})->then(sub (\$tx) {\n    say \$tx->result->body;\n  })->catch(sub (\$err) {\n    warn \"Connection error: \$err\";\n  })->wait;"
         ],
         [ "head2", "options" ],
         [
            "Verbatim",
"  my \$tx = \$ua->options('example.com');\n  my \$tx = \$ua->options('http://example.com' => {Accept => '*/*'} => 'Content!');\n  my \$tx = \$ua->options('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$tx = \$ua->options('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
         ],
         [
            "Para",
"Perform blocking OPTIONS request and return resulting Mojo::Transaction::HTTP object, takes the same arguments as \"tx\" in Mojo::UserAgent::Transactor (except for the OPTIONS method, which is implied). You can also append a callback to perform requests non-blocking."
         ],
         [
            "Verbatim",
"  \$ua->options('http://example.com' => json => {a => 'b'} => sub (\$ua, \$tx) { say \$tx->result->body });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [ "head2", "options_p" ],
         [
            "Verbatim",
            "  my \$promise = \$ua->options_p('http://example.com');"
         ],
         [
            "Para",
"Same as \"options\", but performs all requests non-blocking and returns a Mojo::Promise object instead of accepting a callback."
         ],
         [
            "Verbatim",
"  \$ua->options_p('http://example.com' => json => {a => 'b'})->then(sub (\$tx) {\n    say \$tx->result->body;\n  })->catch(sub (\$err) {\n    warn \"Connection error: \$err\";\n  })->wait;"
         ],
         [ "head2", "patch" ],
         [
            "Verbatim",
"  my \$tx = \$ua->patch('example.com');\n  my \$tx = \$ua->patch('http://example.com' => {Accept => '*/*'} => 'Content!');\n  my \$tx = \$ua->patch('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$tx = \$ua->patch('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
         ],
         [
            "Para",
"Perform blocking PATCH request and return resulting Mojo::Transaction::HTTP object, takes the same arguments as \"tx\" in Mojo::UserAgent::Transactor (except for the PATCH method, which is implied). You can also append a callback to perform requests non-blocking."
         ],
         [
            "Verbatim",
"  \$ua->patch('http://example.com' => json => {a => 'b'} => sub (\$ua, \$tx) { say \$tx->result->body });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [ "head2", "patch_p" ],
         [
            "Verbatim", "  my \$promise = \$ua->patch_p('http://example.com');"
         ],
         [
            "Para",
"Same as \"patch\", but performs all requests non-blocking and returns a Mojo::Promise object instead of accepting a callback."
         ],
         [
            "Verbatim",
"  \$ua->patch_p('http://example.com' => json => {a => 'b'})->then(sub (\$tx) {\n    say \$tx->result->body;\n  })->catch(sub (\$err) {\n    warn \"Connection error: \$err\";\n  })->wait;"
         ],
         [ "head2", "post" ],
         [
            "Verbatim",
"  my \$tx = \$ua->post('example.com');\n  my \$tx = \$ua->post('http://example.com' => {Accept => '*/*'} => 'Content!');\n  my \$tx = \$ua->post('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$tx = \$ua->post('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
         ],
         [
            "Para",
"Perform blocking POST request and return resulting Mojo::Transaction::HTTP object, takes the same arguments as \"tx\" in Mojo::UserAgent::Transactor (except for the POST method, which is implied). You can also append a callback to perform requests non-blocking."
         ],
         [
            "Verbatim",
"  \$ua->post('http://example.com' => json => {a => 'b'} => sub (\$ua, \$tx) { say \$tx->result->body });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [ "head2",    "post_p" ],
         [ "Verbatim", "  my \$promise = \$ua->post_p('http://example.com');" ],
         [
            "Para",
"Same as \"post\", but performs all requests non-blocking and returns a Mojo::Promise object instead of accepting a callback."
         ],
         [
            "Verbatim",
"  \$ua->post_p('http://example.com' => json => {a => 'b'})->then(sub (\$tx) {\n    say \$tx->result->body;\n  })->catch(sub (\$err) {\n    warn \"Connection error: \$err\";\n  })->wait;"
         ],
         [ "head2", "put" ],
         [
            "Verbatim",
"  my \$tx = \$ua->put('example.com');\n  my \$tx = \$ua->put('http://example.com' => {Accept => '*/*'} => 'Content!');\n  my \$tx = \$ua->put('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$tx = \$ua->put('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
         ],
         [
            "Para",
"Perform blocking PUT request and return resulting Mojo::Transaction::HTTP object, takes the same arguments as \"tx\" in Mojo::UserAgent::Transactor (except for the PUT method, which is implied). You can also append a callback to perform requests non-blocking."
         ],
         [
            "Verbatim",
"  \$ua->put('http://example.com' => json => {a => 'b'} => sub (\$ua, \$tx) { say \$tx->result->body });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [ "head2",    "put_p" ],
         [ "Verbatim", "  my \$promise = \$ua->put_p('http://example.com');" ],
         [
            "Para",
"Same as \"put\", but performs all requests non-blocking and returns a Mojo::Promise object instead of accepting a callback."
         ],
         [
            "Verbatim",
"  \$ua->put_p('http://example.com' => json => {a => 'b'})->then(sub (\$tx) {\n    say \$tx->result->body;\n  })->catch(sub (\$err) {\n    warn \"Connection error: \$err\";\n  })->wait;"
         ],
         [ "head2", "start" ],
         [
            "Verbatim",
            "  my \$tx = \$ua->start(Mojo::Transaction::HTTP->new);"
         ],
         [
            "Para",
"Perform blocking request for a custom Mojo::Transaction::HTTP object, which can be prepared manually or with \"build_tx\". You can also append a callback to perform requests non-blocking."
         ],
         [
            "Verbatim",
"  my \$tx = \$ua->build_tx(GET => 'http://example.com');\n  \$ua->start(\$tx => sub (\$ua, \$tx) { say \$tx->result->body });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [ "head2", "start_p" ],
         [
            "Verbatim",
            "  my \$promise = \$ua->start_p(Mojo::Transaction::HTTP->new);"
         ],
         [
            "Para",
"Same as \"start\", but performs all requests non-blocking and returns a Mojo::Promise object instead of accepting a callback."
         ],
         [
            "Verbatim",
"  my \$tx = \$ua->build_tx(GET => 'http://example.com');\n  \$ua->start_p(\$tx)->then(sub (\$tx) {\n    say \$tx->result->body;\n  })->catch(sub (\$err) {\n    warn \"Connection error: \$err\";\n  })->wait;"
         ],
         [ "head2", "websocket" ],
         [
            "Verbatim",
"  \$ua->websocket('ws://example.com' => sub {...});\n  \$ua->websocket('ws://example.com' => {DNT => 1} => ['v1.proto'] => sub {...});"
         ],
         [
            "Para",
"Open a non-blocking WebSocket connection with transparent handshake, takes the same arguments as \"websocket\" in Mojo::UserAgent::Transactor. The callback will receive either a Mojo::Transaction::WebSocket or Mojo::Transaction::HTTP object, depending on if the handshake was successful."
         ],
         [
            "Verbatim",
"  \$ua->websocket('wss://example.com/echo' => ['v1.proto'] => sub (\$ua, \$tx) {\n    say 'WebSocket handshake failed!' and return unless \$tx->is_websocket;\n    say 'Subprotocol negotiation failed!' and return unless \$tx->protocol;\n    \$tx->on(finish => sub (\$tx, \$code, \$reason) { say \"WebSocket closed with status \$code.\" });\n    \$tx->on(message => sub (\$tx, \$msg) {\n      say \"WebSocket message: \$msg\";\n      \$tx->finish;\n    });\n    \$tx->send('Hi!');\n  });\n  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;"
         ],
         [
            "Para",
"You can activate permessage-deflate compression by setting the Sec-WebSocket-Extensions header, this can result in much better performance, but also increases memory usage by up to 300KiB per connection."
         ],
         [
            "Verbatim",
"  \$ua->websocket('ws://example.com/foo' => {\n    'Sec-WebSocket-Extensions' => 'permessage-deflate'\n  } => sub {...});"
         ],
         [ "head2", "websocket_p" ],
         [
            "Verbatim",
            "  my \$promise = \$ua->websocket_p('ws://example.com');"
         ],
         [
            "Para",
"Same as \"websocket\", but returns a Mojo::Promise object instead of accepting a callback."
         ],
         [
            "Verbatim",
"  \$ua->websocket_p('wss://example.com/echo')->then(sub (\$tx) {\n    my \$promise = Mojo::Promise->new;\n    \$tx->on(finish => sub { \$promise->resolve });\n    \$tx->on(message => sub (\$tx, \$msg) {\n      say \"WebSocket message: \$msg\";\n      \$tx->finish;\n    });\n    \$tx->send('Hi!');\n    return \$promise;\n  })->catch(sub (\$err) {\n    warn \"WebSocket error: \$err\";\n  })->wait;"
         ],
         [ "head1", "DEBUGGING" ],
         [
            "Para",
"You can set the MOJO_CLIENT_DEBUG environment variable to get some advanced diagnostics information printed to STDERR."
         ],
         [ "Verbatim", "  MOJO_CLIENT_DEBUG=1" ],
         [ "head1",    "SEE ALSO" ],
         [
            "Para",
            "Mojolicious, Mojolicious::Guides, https://mojolicious.org."
         ]
      ],
      pod => <<~'POD',
      =encoding utf8
      
      =head1 NAME
      
      Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent
      
      =head1 SYNOPSIS
      
        use Mojo::UserAgent;
      
        # Fine grained response handling (dies on connection errors)
        my $ua  = Mojo::UserAgent->new;
        my $res = $ua->get('docs.mojolicious.org')->result;
        if    ($res->is_success)  { say $res->body }
        elsif ($res->is_error)    { say $res->message }
        elsif ($res->code == 301) { say $res->headers->location }
        else                      { say 'Whatever...' }
      
        # Say hello to the Unicode snowman and include an Accept header
        say $ua->get('www.☃.net?hello=there' => {Accept => '*/*'})->result->body;
      
        # Extract data from HTML and XML resources with CSS selectors
        say $ua->get('www.perl.org')->result->dom->at('title')->text;
      
        # Scrape the latest headlines from a news site
        say $ua->get('blogs.perl.org')->result->dom->find('h2 > a')->map('text')->join("\n");
      
        # IPv6 PUT request with Content-Type header and content
        my $tx = $ua->put('[::1]:3000' => {'Content-Type' => 'text/plain'} => 'Hi!');
      
        # Quick JSON API request with Basic authentication
        my $url = Mojo::URL->new('https://example.com/test.json')->userinfo('sri:☃');
        my $value = $ua->get($url)->result->json;
      
        # JSON POST (application/json) with TLS certificate authentication
        my $tx = $ua->cert('tls.crt')->key('tls.key')->post('https://example.com' => json => {top => 'secret'});
      
        # Form POST (application/x-www-form-urlencoded)
        my $tx = $ua->post('https://metacpan.org/search' => form => {q => 'mojo'});
      
        # Search DuckDuckGo anonymously through Tor
        $ua->proxy->http('socks://127.0.0.1:9050');
        say $ua->get('api.3g2upl4pq6kufc4m.onion/?q=mojolicious&format=json')->result->json('/Abstract');
      
        # GET request via UNIX domain socket "/tmp/myapp.sock" (percent encoded slash)
        say $ua->get('http+unix://%2Ftmp%2Fmyapp.sock/test')->result->body;
      
        # Follow redirects to download Mojolicious from GitHub
        $ua->max_redirects(5)
          ->get('https://www.github.com/mojolicious/mojo/tarball/main')
          ->result->save_to('/home/sri/mojo.tar.gz');
      
        # Non-blocking request
        $ua->get('mojolicious.org' => sub ($ua, $tx) { say $tx->result->dom->at('title')->text });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
        # Concurrent non-blocking requests (synchronized with promises)
        my $mojo_promise = $ua->get_p('mojolicious.org');
        my $cpan_promise = $ua->get_p('cpan.org');
        Mojo::Promise->all($mojo_promise, $cpan_promise)->then(sub ($mojo, $cpan) {
          say $mojo->[0]->result->dom->at('title')->text;
          say $cpan->[0]->result->dom->at('title')->text;
        })->wait;
      
        # WebSocket connection sending and receiving JSON via UNIX domain socket
        $ua->websocket('ws+unix://%2Ftmp%2Fmyapp.sock/echo.json' => sub ($ua, $tx) {
          say 'WebSocket handshake failed!' and return unless $tx->is_websocket;
          $tx->on(json => sub ($tx, $hash) {
            say "WebSocket message via JSON: $hash->{msg}";
            $tx->finish;
          });
          $tx->send({json => {msg => 'Hello World!'}});
        });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      =head1 DESCRIPTION
      
      L<Mojo::UserAgent> is a full featured non-blocking I/O HTTP and WebSocket user agent, with IPv6, TLS, SNI, IDNA,
      HTTP/SOCKS5 proxy, UNIX domain socket, Comet (long polling), Promises/A+, keep-alive, connection pooling, timeout,
      cookie, multipart, gzip compression and multiple event loop support.
      
      All connections will be reset automatically if a new process has been forked, this allows multiple processes to share
      the same L<Mojo::UserAgent> object safely.
      
      For better scalability (epoll, kqueue) and to provide non-blocking name resolution, SOCKS5 as well as TLS support, the
      optional modules L<EV> (4.32+), L<Net::DNS::Native> (0.15+), L<IO::Socket::Socks> (0.64+) and L<IO::Socket::SSL>
      (2.009+) will be used automatically if possible. Individual features can also be disabled with the C<MOJO_NO_NNR>,
      C<MOJO_NO_SOCKS> and C<MOJO_NO_TLS> environment variables.
      
      See L<Mojolicious::Guides::Cookbook/"USER AGENT"> for more.
      
      =head1 EVENTS
      
      L<Mojo::UserAgent> inherits all events from L<Mojo::EventEmitter> and can emit the following new ones.
      
      =head2 prepare
      
        $ua->on(prepare => sub ($ua, $tx) {...});
      
      Emitted whenever a new transaction is being prepared, before relative URLs are rewritten and cookies added. This
      includes automatically prepared proxy C<CONNECT> requests and followed redirects.
      
        $ua->on(prepare => sub ($ua, $tx) {
          $tx->req->url(Mojo::URL->new('/mock-mojolicious')) if $tx->req->url->host eq 'mojolicious.org';
        });
      
      =head2 start
      
        $ua->on(start => sub ($ua, $tx) {...});
      
      Emitted whenever a new transaction is about to start. This includes automatically prepared proxy C<CONNECT> requests
      and followed redirects.
      
        $ua->on(start => sub ($ua, $tx) {
          $tx->req->headers->header('X-Bender' => 'Bite my shiny metal ass!');
        });
      
      =head1 ATTRIBUTES
      
      L<Mojo::UserAgent> implements the following attributes.
      
      =head2 ca
      
        my $ca = $ua->ca;
        $ua    = $ua->ca('/etc/tls/ca.crt');
      
      Path to TLS certificate authority file used to verify the peer certificate, defaults to the value of the
      C<MOJO_CA_FILE> environment variable.
      
        # Show certificate authorities for debugging
        IO::Socket::SSL::set_defaults(SSL_verify_callback => sub { say "Authority: $_[2]" and return $_[0] });
      
      =head2 cert
      
        my $cert = $ua->cert;
        $ua      = $ua->cert('/etc/tls/client.crt');
      
      Path to TLS certificate file, defaults to the value of the C<MOJO_CERT_FILE> environment variable.
      
      =head2 connect_timeout
      
        my $timeout = $ua->connect_timeout;
        $ua         = $ua->connect_timeout(5);
      
      Maximum amount of time in seconds establishing a connection may take before getting canceled, defaults to the value of
      the C<MOJO_CONNECT_TIMEOUT> environment variable or C<10>.
      
      =head2 cookie_jar
      
        my $cookie_jar = $ua->cookie_jar;
        $ua            = $ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
      
      Cookie jar to use for requests performed by this user agent, defaults to a L<Mojo::UserAgent::CookieJar> object.
      
        # Ignore all cookies
        $ua->cookie_jar->ignore(sub { 1 });
      
        # Ignore cookies for public suffixes
        my $ps = IO::Socket::SSL::PublicSuffix->default;
        $ua->cookie_jar->ignore(sub ($cookie) {
          return undef unless my $domain = $cookie->domain;
          return ($ps->public_suffix($domain))[0] eq '';
        });
      
        # Add custom cookie to the jar
        $ua->cookie_jar->add(
          Mojo::Cookie::Response->new(
            name   => 'foo',
            value  => 'bar',
            domain => 'docs.mojolicious.org',
            path   => '/Mojolicious'
          )
        );
      
      =head2 inactivity_timeout
      
        my $timeout = $ua->inactivity_timeout;
        $ua         = $ua->inactivity_timeout(15);
      
      Maximum amount of time in seconds a connection can be inactive before getting closed, defaults to the value of the
      C<MOJO_INACTIVITY_TIMEOUT> environment variable or C<40>. Setting the value to C<0> will allow connections to be
      inactive indefinitely.
      
      =head2 insecure
      
        my $bool = $ua->insecure;
        $ua      = $ua->insecure($bool);
      
      Do not require a valid TLS certificate to access HTTPS/WSS sites, defaults to the value of the C<MOJO_INSECURE>
      environment variable.
      
        # Disable TLS certificate verification for testing
        say $ua->insecure(1)->get('https://127.0.0.1:3000')->result->code;
      
      =head2 ioloop
      
        my $loop = $ua->ioloop;
        $ua      = $ua->ioloop(Mojo::IOLoop->new);
      
      Event loop object to use for blocking I/O operations, defaults to a L<Mojo::IOLoop> object.
      
      =head2 key
      
        my $key = $ua->key;
        $ua     = $ua->key('/etc/tls/client.crt');
      
      Path to TLS key file, defaults to the value of the C<MOJO_KEY_FILE> environment variable.
      
      =head2 max_connections
      
        my $max = $ua->max_connections;
        $ua     = $ua->max_connections(5);
      
      Maximum number of keep-alive connections that the user agent will retain before it starts closing the oldest ones,
      defaults to C<5>. Setting the value to C<0> will prevent any connections from being kept alive.
      
      =head2 max_redirects
      
        my $max = $ua->max_redirects;
        $ua     = $ua->max_redirects(3);
      
      Maximum number of redirects the user agent will follow before it fails, defaults to the value of the
      C<MOJO_MAX_REDIRECTS> environment variable or C<0>.
      
      =head2 max_response_size
      
        my $max = $ua->max_response_size;
        $ua     = $ua->max_response_size(16777216);
      
      Maximum response size in bytes, defaults to the value of L<Mojo::Message::Response/"max_message_size">. Setting the
      value to C<0> will allow responses of indefinite size. Note that increasing this value can also drastically increase
      memory usage, should you for example attempt to parse an excessively large response body with the methods
      L<Mojo::Message/"dom"> or L<Mojo::Message/"json">.
      
      =head2 proxy
      
        my $proxy = $ua->proxy;
        $ua       = $ua->proxy(Mojo::UserAgent::Proxy->new);
      
      Proxy manager, defaults to a L<Mojo::UserAgent::Proxy> object.
      
        # Detect proxy servers from environment
        $ua->proxy->detect;
      
        # Manually configure HTTP proxy (using CONNECT for HTTPS/WebSockets)
        $ua->proxy->http('http://127.0.0.1:8080')->https('http://127.0.0.1:8080');
      
        # Manually configure Tor (SOCKS5)
        $ua->proxy->http('socks://127.0.0.1:9050')->https('socks://127.0.0.1:9050');
      
        # Manually configure UNIX domain socket (using CONNECT for HTTPS/WebSockets)
        $ua->proxy->http('http+unix://%2Ftmp%2Fproxy.sock') ->https('http+unix://%2Ftmp%2Fproxy.sock');
      
      =head2 request_timeout
      
        my $timeout = $ua->request_timeout;
        $ua         = $ua->request_timeout(5);
      
      Maximum amount of time in seconds establishing a connection, sending the request and receiving a whole response may
      take before getting canceled, defaults to the value of the C<MOJO_REQUEST_TIMEOUT> environment variable or C<0>.
      Setting the value to C<0> will allow the user agent to wait indefinitely. The timeout will reset for every followed
      redirect.
      
        # Total limit of 5 seconds, of which 3 seconds may be spent connecting
        $ua->max_redirects(0)->connect_timeout(3)->request_timeout(5);
      
      =head2 server
      
        my $server = $ua->server;
        $ua        = $ua->server(Mojo::UserAgent::Server->new);
      
      Application server relative URLs will be processed with, defaults to a L<Mojo::UserAgent::Server> object.
      
        # Mock web service
        $ua->server->app(Mojolicious->new);
        $ua->server->app->routes->get('/time' => sub ($c) {
          $c->render(json => {now => time});
        });
        my $time = $ua->get('/time')->result->json->{now};
      
        # Change log level
        $ua->server->app->log->level('fatal');
      
        # Port currently used for processing relative URLs blocking
        say $ua->server->url->port;
      
        # Port currently used for processing relative URLs non-blocking
        say $ua->server->nb_url->port;
      
      =head2 socket_options
      
        my $options = $ua->socket_options;
        $ua         = $ua->socket_options({LocalAddr => '127.0.0.1'});
      
      Additional options for L<IO::Socket::IP> when opening new connections.
      
      =head2 transactor
      
        my $t = $ua->transactor;
        $ua   = $ua->transactor(Mojo::UserAgent::Transactor->new);
      
      Transaction builder, defaults to a L<Mojo::UserAgent::Transactor> object.
      
        # Change name of user agent
        $ua->transactor->name('MyUA 1.0');
      
        # Disable compression
        $ua->transactor->compressed(0);
      
      =head1 METHODS
      
      L<Mojo::UserAgent> inherits all methods from L<Mojo::EventEmitter> and implements the following new ones.
      
      =head2 build_tx
      
        my $tx = $ua->build_tx(GET => 'example.com');
        my $tx = $ua->build_tx(PUT => 'http://example.com' => {Accept => '*/*'} => 'Content!');
        my $tx = $ua->build_tx(PUT => 'http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
        my $tx = $ua->build_tx(PUT => 'http://example.com' => {Accept => '*/*'} => json => {a => 'b'});
      
      Generate L<Mojo::Transaction::HTTP> object with L<Mojo::UserAgent::Transactor/"tx">.
      
        # Request with custom cookie
        my $tx = $ua->build_tx(GET => 'https://example.com/account');
        $tx->req->cookies({name => 'user', value => 'sri'});
        $tx = $ua->start($tx);
      
        # Deactivate gzip compression
        my $tx = $ua->build_tx(GET => 'example.com');
        $tx->req->headers->remove('Accept-Encoding');
        $tx = $ua->start($tx);
      
        # Interrupt response by raising an error
        my $tx = $ua->build_tx(GET => 'http://example.com');
        $tx->res->on(progress => sub ($res) {
          return unless my $server = $res->headers->server;
          $res->error({message => 'Oh noes, it is IIS!'}) if $server =~ /IIS/;
        });
        $tx = $ua->start($tx);
      
      =head2 build_websocket_tx
      
        my $tx = $ua->build_websocket_tx('ws://example.com');
        my $tx = $ua->build_websocket_tx( 'ws://example.com' => {DNT => 1} => ['v1.proto']);
      
      Generate L<Mojo::Transaction::HTTP> object with L<Mojo::UserAgent::Transactor/"websocket">.
      
        # Custom WebSocket handshake with cookie
        my $tx = $ua->build_websocket_tx('wss://example.com/echo');
        $tx->req->cookies({name => 'user', value => 'sri'});
        $ua->start($tx => sub ($ua, $tx) {
          say 'WebSocket handshake failed!' and return unless $tx->is_websocket;
          $tx->on(message => sub ($tx, $msg) {
            say "WebSocket message: $msg";
            $tx->finish;
          });
          $tx->send('Hi!');
        });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      =head2 delete
      
        my $tx = $ua->delete('example.com');
        my $tx = $ua->delete('http://example.com' => {Accept => '*/*'} => 'Content!');
        my $tx = $ua->delete('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
        my $tx = $ua->delete('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});
      
      Perform blocking C<DELETE> request and return resulting L<Mojo::Transaction::HTTP> object, takes the same arguments as
      L<Mojo::UserAgent::Transactor/"tx"> (except for the C<DELETE> method, which is implied). You can also append a callback
      to perform requests non-blocking.
      
        $ua->delete('http://example.com' => json => {a => 'b'} => sub ($ua, $tx) { say $tx->result->body });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      =head2 delete_p
      
        my $promise = $ua->delete_p('http://example.com');
      
      Same as L</"delete">, but performs all requests non-blocking and returns a L<Mojo::Promise> object instead of accepting
      a callback.
      
        $ua->delete_p('http://example.com' => json => {a => 'b'})->then(sub ($tx) {
          say $tx->result->body;
        })->catch(sub ($err) {
          warn "Connection error: $err";
        })->wait;
      
      =head2 get
      
        my $tx = $ua->get('example.com');
        my $tx = $ua->get('http://example.com' => {Accept => '*/*'} => 'Content!');
        my $tx = $ua->get('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
        my $tx = $ua->get('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});
      
      Perform blocking C<GET> request and return resulting L<Mojo::Transaction::HTTP> object, takes the same arguments as
      L<Mojo::UserAgent::Transactor/"tx"> (except for the C<GET> method, which is implied). You can also append a callback to
      perform requests non-blocking.
      
        $ua->get('http://example.com' => json => {a => 'b'} => sub ($ua, $tx) { say $tx->result->body });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      =head2 get_p
      
        my $promise = $ua->get_p('http://example.com');
      
      Same as L</"get">, but performs all requests non-blocking and returns a L<Mojo::Promise> object instead of accepting a
      callback.
      
        $ua->get_p('http://example.com' => json => {a => 'b'})->then(sub ($tx) {
          say $tx->result->body;
        })->catch(sub ($err) {
          warn "Connection error: $err";
        })->wait;
      
      =head2 head
      
        my $tx = $ua->head('example.com');
        my $tx = $ua->head('http://example.com' => {Accept => '*/*'} => 'Content!');
        my $tx = $ua->head('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
        my $tx = $ua->head('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});
      
      Perform blocking C<HEAD> request and return resulting L<Mojo::Transaction::HTTP> object, takes the same arguments as
      L<Mojo::UserAgent::Transactor/"tx"> (except for the C<HEAD> method, which is implied). You can also append a callback
      to perform requests non-blocking.
      
        $ua->head('http://example.com' => json => {a => 'b'} => sub ($ua, $tx) { say $tx->result->body });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      =head2 head_p
      
        my $promise = $ua->head_p('http://example.com');
      
      Same as L</"head">, but performs all requests non-blocking and returns a L<Mojo::Promise> object instead of accepting a
      callback.
      
        $ua->head_p('http://example.com' => json => {a => 'b'})->then(sub ($tx) {
          say $tx->result->body;
        })->catch(sub ($err) {
          warn "Connection error: $err";
        })->wait;
      
      =head2 options
      
        my $tx = $ua->options('example.com');
        my $tx = $ua->options('http://example.com' => {Accept => '*/*'} => 'Content!');
        my $tx = $ua->options('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
        my $tx = $ua->options('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});
      
      Perform blocking C<OPTIONS> request and return resulting L<Mojo::Transaction::HTTP> object, takes the same arguments as
      L<Mojo::UserAgent::Transactor/"tx"> (except for the C<OPTIONS> method, which is implied). You can also append a
      callback to perform requests non-blocking.
      
        $ua->options('http://example.com' => json => {a => 'b'} => sub ($ua, $tx) { say $tx->result->body });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      =head2 options_p
      
        my $promise = $ua->options_p('http://example.com');
      
      Same as L</"options">, but performs all requests non-blocking and returns a L<Mojo::Promise> object instead of
      accepting a callback.
      
        $ua->options_p('http://example.com' => json => {a => 'b'})->then(sub ($tx) {
          say $tx->result->body;
        })->catch(sub ($err) {
          warn "Connection error: $err";
        })->wait;
      
      =head2 patch
      
        my $tx = $ua->patch('example.com');
        my $tx = $ua->patch('http://example.com' => {Accept => '*/*'} => 'Content!');
        my $tx = $ua->patch('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
        my $tx = $ua->patch('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});
      
      Perform blocking C<PATCH> request and return resulting L<Mojo::Transaction::HTTP> object, takes the same arguments as
      L<Mojo::UserAgent::Transactor/"tx"> (except for the C<PATCH> method, which is implied). You can also append a callback
      to perform requests non-blocking.
      
        $ua->patch('http://example.com' => json => {a => 'b'} => sub ($ua, $tx) { say $tx->result->body });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      =head2 patch_p
      
        my $promise = $ua->patch_p('http://example.com');
      
      Same as L</"patch">, but performs all requests non-blocking and returns a L<Mojo::Promise> object instead of accepting
      a callback.
      
        $ua->patch_p('http://example.com' => json => {a => 'b'})->then(sub ($tx) {
          say $tx->result->body;
        })->catch(sub ($err) {
          warn "Connection error: $err";
        })->wait;
      
      =head2 post
      
        my $tx = $ua->post('example.com');
        my $tx = $ua->post('http://example.com' => {Accept => '*/*'} => 'Content!');
        my $tx = $ua->post('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
        my $tx = $ua->post('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});
      
      Perform blocking C<POST> request and return resulting L<Mojo::Transaction::HTTP> object, takes the same arguments as
      L<Mojo::UserAgent::Transactor/"tx"> (except for the C<POST> method, which is implied). You can also append a callback
      to perform requests non-blocking.
      
        $ua->post('http://example.com' => json => {a => 'b'} => sub ($ua, $tx) { say $tx->result->body });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      =head2 post_p
      
        my $promise = $ua->post_p('http://example.com');
      
      Same as L</"post">, but performs all requests non-blocking and returns a L<Mojo::Promise> object instead of accepting a
      callback.
      
        $ua->post_p('http://example.com' => json => {a => 'b'})->then(sub ($tx) {
          say $tx->result->body;
        })->catch(sub ($err) {
          warn "Connection error: $err";
        })->wait;
      
      =head2 put
      
        my $tx = $ua->put('example.com');
        my $tx = $ua->put('http://example.com' => {Accept => '*/*'} => 'Content!');
        my $tx = $ua->put('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
        my $tx = $ua->put('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});
      
      Perform blocking C<PUT> request and return resulting L<Mojo::Transaction::HTTP> object, takes the same arguments as
      L<Mojo::UserAgent::Transactor/"tx"> (except for the C<PUT> method, which is implied). You can also append a callback to
      perform requests non-blocking.
      
        $ua->put('http://example.com' => json => {a => 'b'} => sub ($ua, $tx) { say $tx->result->body });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      =head2 put_p
      
        my $promise = $ua->put_p('http://example.com');
      
      Same as L</"put">, but performs all requests non-blocking and returns a L<Mojo::Promise> object instead of accepting a
      callback.
      
        $ua->put_p('http://example.com' => json => {a => 'b'})->then(sub ($tx) {
          say $tx->result->body;
        })->catch(sub ($err) {
          warn "Connection error: $err";
        })->wait;
      
      =head2 start
      
        my $tx = $ua->start(Mojo::Transaction::HTTP->new);
      
      Perform blocking request for a custom L<Mojo::Transaction::HTTP> object, which can be prepared manually or with
      L</"build_tx">. You can also append a callback to perform requests non-blocking.
      
        my $tx = $ua->build_tx(GET => 'http://example.com');
        $ua->start($tx => sub ($ua, $tx) { say $tx->result->body });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      =head2 start_p
      
        my $promise = $ua->start_p(Mojo::Transaction::HTTP->new);
      
      Same as L</"start">, but performs all requests non-blocking and returns a L<Mojo::Promise> object instead of accepting
      a callback.
      
        my $tx = $ua->build_tx(GET => 'http://example.com');
        $ua->start_p($tx)->then(sub ($tx) {
          say $tx->result->body;
        })->catch(sub ($err) {
          warn "Connection error: $err";
        })->wait;
      
      =head2 websocket
      
        $ua->websocket('ws://example.com' => sub {...});
        $ua->websocket('ws://example.com' => {DNT => 1} => ['v1.proto'] => sub {...});
      
      Open a non-blocking WebSocket connection with transparent handshake, takes the same arguments as
      L<Mojo::UserAgent::Transactor/"websocket">. The callback will receive either a L<Mojo::Transaction::WebSocket> or
      L<Mojo::Transaction::HTTP> object, depending on if the handshake was successful.
      
        $ua->websocket('wss://example.com/echo' => ['v1.proto'] => sub ($ua, $tx) {
          say 'WebSocket handshake failed!' and return unless $tx->is_websocket;
          say 'Subprotocol negotiation failed!' and return unless $tx->protocol;
          $tx->on(finish => sub ($tx, $code, $reason) { say "WebSocket closed with status $code." });
          $tx->on(message => sub ($tx, $msg) {
            say "WebSocket message: $msg";
            $tx->finish;
          });
          $tx->send('Hi!');
        });
        Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
      
      You can activate C<permessage-deflate> compression by setting the C<Sec-WebSocket-Extensions> header, this can result
      in much better performance, but also increases memory usage by up to 300KiB per connection.
      
        $ua->websocket('ws://example.com/foo' => {
          'Sec-WebSocket-Extensions' => 'permessage-deflate'
        } => sub {...});
      
      =head2 websocket_p
      
        my $promise = $ua->websocket_p('ws://example.com');
      
      Same as L</"websocket">, but returns a L<Mojo::Promise> object instead of accepting a callback.
      
        $ua->websocket_p('wss://example.com/echo')->then(sub ($tx) {
          my $promise = Mojo::Promise->new;
          $tx->on(finish => sub { $promise->resolve });
          $tx->on(message => sub ($tx, $msg) {
            say "WebSocket message: $msg";
            $tx->finish;
          });
          $tx->send('Hi!');
          return $promise;
        })->catch(sub ($err) {
          warn "WebSocket error: $err";
        })->wait;
      
      =head1 DEBUGGING
      
      You can set the C<MOJO_CLIENT_DEBUG> environment variable to get some advanced diagnostics information printed to
      C<STDERR>.
      
        MOJO_CLIENT_DEBUG=1
      
      =head1 SEE ALSO
      
      L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.
      
      
      =cut

      POD
   },
);

my ( $fh, $file ) = tempfile( SUFFIX => ".pm" );

for my $case ( @cases ) {

   # Empty the tempfile.
   truncate $fh, 0;
   $fh->seek( 0, 0 );

   # Add some pod.
   print $fh $case->{pod};

   # Make at the beginning of the file.
   $fh->seek( 0, 0 );

   # Parse and compare
   is_deeply(
      Pod::LOL->new_root( $file ),
      $case->{expected_root},
      $case->{name},
   );
}

done_testing();

