#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 80;
use Data::Dumper;
use lib 't/';

# Some special helpers to restove the environment
my %ORIG_ENV = %ENV;
sub restoreENV { %ENV = %ORIG_ENV }

# TEST: use
BEGIN { 
    use_ok('REST::Application');
    use_ok('Tie::IxHash');
    use_ok('UNIVERSAL');
    use_ok('CGI');
    use_ok('Carp');
    $SIG{'__WARN__'} = sub { &Carp::croak };
}

# TEST: new()
{
    my $rest = REST::Application->new();
    is(ref($rest), 'REST::Application', "Object instantiation.");
}

# TEST: query()
{
    my $rest = REST::Application->new();
    my $query = $rest->defaultQueryObject();
    is(ref($query), 'CGI', "Retrieving default query object.");
}

# TEST: query()
{
    my $rest = REST::Application->new();
    my $query = $rest->query();
    is(ref($query), 'CGI', "Retrieving query object.");
}

# TEST: query($value)
{
    my $rest = REST::Application->new();
    my $query = $rest->query("x/a/b");
    is($query, 'x/a/b', "Setting and retrieving a query object.");
}

# TEST: query(undef)
{
    my $rest = REST::Application->new();
    my $query = $rest->query(undef);
    is($query, undef, "Setting and retrieving a query object w/ undef.");
}

# TEST: defaultQueryObject($value)
{
    my $rest = REST::Application->new();
    my $query = $rest->defaultQueryObject("xxx");
    is($query, 'xxx', "Setting and retrieving default query object.");
}

# TEST: defaultQueryObject(undef)
{
    my $rest = REST::Application->new();
    my $query = $rest->defaultQueryObject(undef);
    is($query, undef, "Setting and retrieving default query object w/ undef value.");
}

# TEST: resourceHooks()
{
    my $rest = REST::Application->new();
    my $resources = $rest->resourceHooks();
    is_deeply($resources, {}, "Getting resource hooks when none are set.");
}

# TEST: resourceHooks()
{
    my $rest = REST::Application->new();
    my $sub = sub {};
    my $regex = qr/foobar/;
    my $resources = $rest->resourceHooks($regex => $sub);
    is(ref($resources), 'HASH', "Resource hook using a code ref (data type check)");
    is($resources->{$regex}, $sub, "Resource hook using a code ref (value check)");
}

# TEST: resourceHooks()
{
    my $rest = REST::Application->new();
    my %uniq;
    my @keys = map { my $x = int(rand(100000)); qr/$x/ } (1 .. 10000);
    @uniq{@keys} = 1;
    @keys = keys(%uniq);  # Make sure we have no duplicate keys
    my @k2 = @keys;
    my $resources = $rest->resourceHooks(map { $_ => "x" } @keys);
    my $keys = [ keys %$resources ];
    is_deeply(\@k2, \@keys, "Resource hook regexes have their order preserved.");
}

# TEST: resourceHooks()
{
    my $rest = REST::Application->new();
    my $resources = $rest->resourceHooks({ foo => 1 });
    is_deeply($resources, {foo => 1}, "Resource hook set from a hash ref");
}

# TEST: resourceHooks()
{
    my $rest = REST::Application->new();
    $rest->resourceHooks(foo => 1);
    my $resources = $rest->resourceHooks();
    is_deeply($resources, {foo => 1}, "Resource hook set and retrieved in 2 steps.");
}

# TEST: getPathInfo()
{
    require_ok('CGI');
    restoreENV();
    CGI->initialize_globals();
    $ENV{PATH_INFO} = "/blah/bar";
    my $rest = REST::Application->new();
    is_deeply($rest->getPathInfo(), "/blah/bar", "Retrieving path info.");
}

# TEST: getRequestMethod()
{
    restoreENV();
    CGI->initialize_globals();
    $ENV{REQUEST_METHOD} = "PuT";
    my $rest = REST::Application->new();
    is_deeply($rest->getRequestMethod(), "PUT", "Retrieving request method.");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $rest->resourceHooks(qr{^/parts/(\d+)\.(\w+)} => 
                            sub { ref($_[0]) . $_[1].$_[2] });
    is(${$rest->loadResource()}, "REST::Application12345xml", "Loading resource - code reference");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $rest->resourceHooks(qr{^/parts/(\d+)\.(\w+)} =>  undef);
    is(${$rest->loadResource()}, undef, "Loading resource - default hook via undef");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{PATH_INFO} = "/NOEXIST/12345.xml";
    $rest->resourceHooks(qr{^/parts/(\d+)\.(\w+)} =>  sub {1});
    is(${$rest->loadResource()}, undef, "Loading resource - default hook via non-match");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    use_ok('TestClass');
    my $rest = TestClass->new();
    $rest->resourceHooks(qr{parts} =>  "barMethod");
    my $resource = $rest->loadResource("parts", "blah", "bar", "baz");
    is($$resource, 'blah:bar:baz', "Loading resource - \"methodName\" hook");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $rest->resourceHooks(qr{^/parts/(\d+)\.(\w+)} =>  [$rest, "getPathInfo"]);
    my $resource = $rest->loadResource();
    is($$resource, '/parts/12345.xml', "Loading resource - [\$object w/ \"methodName\"] hook");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $rest->resourceHooks(qr{^/parts/(\d+)\.(\w+)} => {
                            get => sub { "x" },
                            puT => [$rest, "getPathInfo"],
                            POST => "getPathInfo",
                            'deLEte' =>  undef,
                         });
    my $resource = $rest->loadResource();
    is($$resource, 'x', "Loading resource for GET HTTP method.");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{REQUEST_METHOD} = "PuT";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $rest->resourceHooks(qr{^/parts/(\d+)\.(\w+)} => {
                            get => sub { "x" },
                            puT => [$rest, "getPathInfo"],
                            POST => "getPathInfo",
                            'deLEte' =>  undef,
                         });
    my $resource = $rest->loadResource();
    is($$resource, '/parts/12345.xml', "Loading resource for PUT HTTP method.");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{REQUEST_METHOD} = "PoSt";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $rest->resourceHooks(qr{^/parts/(\d+)\.(\w+)} => {
                            get => sub { "x" },
                            puT => [$rest, "getPathInfo"],
                            POST => "getPathInfo",
                            'deLEte' =>  undef,
                         });
    my $resource = $rest->loadResource();
    is($$resource, '/parts/12345.xml', "Loading resource for POST HTTP method.");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{REQUEST_METHOD} = "delete";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $rest->resourceHooks(qr{^/parts/(\d+)\.(\w+)} => {
                            get => sub { "x" },
                            puT => [$rest, "getPathInfo"],
                            POST => "getPathInfo",
                            'deLEte' =>  undef,
                         });
    my $resource = $rest->loadResource();
    is($$resource, undef, "Loading resource for DELETE HTTP method.");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{REQUEST_METHOD} = "delete";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    my $obj = TestClass->new();
    $rest->resourceHooks(qr{^/parts/(\d+)\.(\w+)} => $obj);
    my $resource = $rest->loadResource();
    is($$resource, "xAbC", "Loading resource - with \$object->DELETE() hook");
}

# TEST: headerType
{
    my $rest = REST::Application->new();
    is($rest->headerType(), 'header', "Retrieving default header type");
    $rest->headerType("redIRect");
    is($rest->headerType(), 'redirect', "Setting header type to \"redirect\".");
    $rest->headerType("nOne");
    is($rest->headerType(), 'none', "Setting header type to \"none\".");
    eval { $rest->headerType("blahblahlbha") };
    ok($@, "Checking error for invalid header type");
}

# TEST: header
{
    my $rest = REST::Application->new();
    my %hash = $rest->header();
    is_deeply(\%hash, {}, "Retrieving default header values.");
    $rest->header(-type => 'text/html', -foobar => 5);
    %hash = $rest->header();
    is_deeply(\%hash, {-type => 'text/html', -foobar => 5}, "Retrieving custom header values.");
}

# TEST: resetHeader()
{
    my $rest = REST::Application->new();
    my %hash1 = $rest->header(-type => 'text/html', -foobar => 5);
    my %hash2 = $rest->resetHeader();
    my %hash3 = $rest->header();
    is_deeply(\%hash1, \%hash2, "Resetting header, verifying return value.");
    is_deeply(\%hash3, {}, "Resetting header, verifying reset.");
}

# TEST: run()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub {
        my ($app, $part) = @_;
        $app->header(-type => 'text/plain');
        return "hubcap - $part - Honda";
    };
    $rest->resourceHooks(qr{^/parts/(\d+)\.\w+} => $resourceHook);
    my $output = $rest->run();
    my $answer = "Content-Type: text/plain; charset=ISO-8859-1\r\n\r\nhubcap - 12345 - Honda";
    is($output, $answer, "Running a REST Application");
}

# TEST: run()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { "this is a test" };
    $rest->resourceHooks(qr{^/parts/(\d+)\.\w+} => $resourceHook);
    my $answer = "Content-Type: text/html; charset=ISO-8859-1\r\n\r\nthis is a test";
    is($rest->run(), $answer, "Running a REST Application which has a resource being its own repr.");
}

# TEST: addRepresentation
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    my $x = "hi";
    $rest->addRepresentation(" world", \$x);
    is($x, "hi world", "Adding representation w/ a string.");

    my $xx = "hi";
    my $y = " world";
    $rest->addRepresentation(\$y, \$xx);
    is ($xx, "hi world", "Adding representation w/ a scalar references.");
}

# TEST: getHeaders 
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $rest->header(-type => "text/xml", -foop => "helloWorld");
    like($rest->getHeaders(),
       qr{[Ff]oop: helloWorld\r\nContent-Type: text/xml; charset=ISO-8859-1\r\n\r\n},
       "Sending representation.");
}

# TEST: BUG: run() produced warnings when sendRepresentation() returned an
# undefined value.  This test should exploit that and fail if it happens.
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { return };
    $rest->resourceHooks(qr{^/parts/(\d+)\.\w+} => $resourceHook);
    my $output = $rest->run();
    my $answer = "Content-Type: text/html; charset=ISO-8859-1\r\n\r\n";
    is($output, $answer, "Running a REST Application");
}

# TEST: preRun() and postRun()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { return "my resource" };
    $rest->resourceHooks(qr{^/parts/(\d+)\.\w+} => $resourceHook);
    $rest->run();
    is($rest->{preRun}, 1, "preRun() method.");
    is($rest->{postRun}, "my resource", "postRun() method.");
}

# TEST: setRedirect()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $rest->setRedirect("http://www.google.com");
    like($rest->getHeaders(), qr{^Status: 302 (Moved|Found)\r\n[lL]ocation: http://www\.google\.com\r\n\r\n$}, "Redirect header");
}

# TEST: getMatchText()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    $rest->{TEST_TEXT} = "radio is friendly";  # See TestClass
    my $resourceHook = sub { 
        my ($app, $is, $friendly) = @_; 
        return "$friendly $is";
    };
    $rest->resourceHooks(qr{^radio\s+(\w+)\s+(\w+)$} => $resourceHook);
    my $output = $rest->run();
    is($output, "Content-Type: text/html; charset=ISO-8859-1\r\n\r\nfriendly is", "Using alternate matching text instead of PATH_INFO.");
}

# TEST: checkMatch()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    $rest->{TEST_TEXT} = "Quis hic locus?";  # See TestClass
    $rest->{TEST_MATCH} = 1; # See TestClass
    my $resourceHook = sub { return "I match" };
    $rest->resourceHooks(q(Quis) => sub { undef }, 
                         q(Quis hic locus?) => $resourceHook);
    my $output = $rest->run();
    is($output, "Content-Type: text/html; charset=ISO-8859-1\r\n\r\nI match", "Using custom matching logic, checkMatch().");
}

# TEST: extraHandlerArgs()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { shift; join(" ", @_) };
    $rest->{TEST_TEXT} = "foo";
    $rest->{TEST_MATCH} = 1;
    $rest->resourceHooks(q(foo) => $resourceHook);
    $rest->extraHandlerArgs(qw(hello jello world foo bar));
    my $output = $rest->run();
    is($output, "Content-Type: text/html; charset=ISO-8859-1\r\n\r\nhello jello world foo bar", "Setting arguments for the handler.");
}

# TEST: extraHandlerArgs()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { shift; join(" ", @_) };
    $rest->{TEST_TEXT} = "foo";
    $rest->{TEST_MATCH} = 1;
    $rest->resourceHooks(q(foo) => $resourceHook);
    $rest->extraHandlerArgs([qw(hello jello world foo bar)]);
    my $output = $rest->run();
    is($output, "Content-Type: text/html; charset=ISO-8859-1\r\n\r\nhello jello world foo bar", "Setting arguments for the handler w/ a reference.");
}

# TEST: preHandler()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { shift; join(" ", @_) };
    $rest->{TEST_PRE} = 1;
    $rest->resourceHooks(q(foo) => $resourceHook);
    $rest->extraHandlerArgs(qw(hello jello world foo bar));
    my $output = $rest->run();
    is($rest->{preHandler}, "hello:jello:world:foo:bar", "Testing pre handler");
}

# TEST: postHandler()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{PATH_INFO} = "foo";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { shift; return join(" ", @_) };
    $rest->{TEST_POST} = 1;
    $rest->resourceHooks(qr(foo) => $resourceHook);
    $rest->extraHandlerArgs(qw(hello jello world foo bar));
    my $output = $rest->run();
    is($rest->{postHandler}, "hello jello world foo barhello:jello:world:foo:bar", "testing post handler");
}

# TEST: callHandler()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{PATH_INFO} = "foo";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { };
    $rest->{TEST_CALL} = 1;
    my $output = $rest->callHandler($resourceHook, "a", "b", "c");
    is($output, "CODEa:b:c", "The handle caller w/o error.");
}

# TEST: callHandler()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{PATH_INFO} = "foo";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { die "TEST ERROR" };
    $rest->{TEST_CALL} = 1;
    $rest->{TEST_CALL_ERROR} = 1;
    eval {
        $rest->callHandler($resourceHook);
    };
    like($@, qr/TEST ERROR/, "The handle caller with error.");
}

# TEST: '*' handler
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{REQUEST_METHOD} = "PUT";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $rest->resourceHooks(qr{^/parts/(\d+)\.(\w+)} => {
                            GET => sub { die },
                            POST => sub { die },
                            DELETE => sub { die },
                            '*' => sub { ref($_[0]) . $_[1].$_[2] }
                        });
    is(${$rest->loadResource()}, "REST::Application12345xml", "Loading resource - code reference");
}

# TEST: simpleContentNegotiation
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application->new();
    $ENV{REQUEST_METHOD} = "PUT";
    $ENV{PATH_INFO} = "/parts";
    $ENV{HTTP_ACCEPT} = 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5';  # Firefox default Accept header.
    my @types = qw(text/xml application/xml text/html text/json */*);
    my $hash = {
        '*/*' => sub { '*/*' },
        'text/json' => sub { '*/*' },
        'text/html' => sub { 'text/html' },
        'text/xml' => sub { 'text/xml' },
        'application/xml' => sub { 'application/xml' },
    };
    for my $type (@types, "") {
        $rest->resourceHooks(qr{/parts} => {PUT => $hash});
        my $wanted_type = $type ? $type : '*/*';
        $wanted_type = '*/*' if $type eq 'text/json';
        my $msg = $type ? $type : "empty string";
        is(${$rest->loadResource()}, $wanted_type, "con-neg on $msg");
        delete $hash->{$type} unless $type eq '*/*';
    }
}

# TEST: makeHandlerFromClass()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{REST_APP_RETURN_ONLY} = 1;
    $rest->{TEST_MHFC} = 1;
    $rest->resourceHooks(q(foo) => ["CowsLoveMe", "BecauseIhugThem"]);
    my $output = $rest->loadResource("foo");
    is($$output, "CowsLoveMe BecauseIhugThem", "Testing makeHandlerFromClass");
}

# TEST: makeHandlerFromRef()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = TestClass->new();
    $ENV{REST_APP_RETURN_ONLY} = 1;
    $rest->{TEST_MHFR} = 1;
    $rest->resourceHooks(qr/.*foo/ => [{}, "MAN"]);
    my $output = $rest->loadResource('foo');
    is($$output, "SMOKE HASH MAN", "Testing makeHandlerFromRef");
    is($rest->getLastMatchPattern(), qr/.*foo/, "Testing getLastMatchPattern");
    is($rest->getLastMatchPath(), "foo", "Testing getLastMatchPath");
}

# TEST: fake the http method
{
    restoreENV();
    CGI->initialize_globals();
    $ENV{REQUEST_METHOD} = "POST";
    $ENV{QUERY_STRING} = "http_method=PUT";
    my $rest = REST::Application->new();
    is_deeply( $rest->getRealRequestMethod(), "POST", "Test Real Method" );
    is_deeply( $rest->getRequestMethod(), "PUT",
        "Tunnel PUT over POST via query param." );
}

# TEST: fake the http method, again
{
    restoreENV();
    CGI->initialize_globals();
    $ENV{REQUEST_METHOD} = "POST";
    $ENV{QUERY_STRING} = "http_method=GET";
    my $rest = REST::Application->new();
    is_deeply( $rest->getRealRequestMethod(), "POST", "Test Real Method" );
    is_deeply( $rest->getRequestMethod(), "GET",
        "Tunnel GET over POST via query param." );
}

# TEST: fake the HTTP method
{
    restoreENV();
    CGI->initialize_globals();
    $ENV{REQUEST_METHOD} = "POST";
    $ENV{HTTP_X_HTTP_METHOD} = "DELETE";
    my $rest = REST::Application->new();
    is_deeply( $rest->getRealRequestMethod(), "POST", "Test Real Method" );
    is_deeply( $rest->getRequestMethod(), "DELETE",
        "Tunnel DELETE over POST via header." );
}

# TEST: fake the HTTP method
{
    restoreENV();
    CGI->initialize_globals();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{HTTP_X_HTTP_METHOD} = "POST";
    my $rest = REST::Application->new();
    is_deeply( $rest->getRealRequestMethod(), "GET", "Test Real Method" );
    is_deeply( $rest->getRequestMethod(), "GET",
        "Tunnel POST over GET does not work" );
}

# TEST: fake the HTTP method
{
    restoreENV();
    CGI->initialize_globals();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{HTTP_X_HTTP_METHOD} = "HEAD";
    my $rest = REST::Application->new();
    is_deeply( $rest->getRealRequestMethod(), "GET", "Test Real Method" );
    is_deeply( $rest->getRequestMethod(), "HEAD",
        "Tunnel HEAD over GET does work" );
}

# TEST: fake the HTTP method
{
    restoreENV();
    CGI->initialize_globals();
    $ENV{REQUEST_METHOD} = "POST";
    my $cgi = CGI->new;
    $cgi->param( "http_method", "PUT" );
    my $rest = REST::Application->new();
    $rest->query($cgi);
    is_deeply( $rest->getRealRequestMethod(), "POST", "Test Real Method" );
    is_deeply( $rest->getRequestMethod(), "PUT",
        "Tunnel PUT over POST content" );
}
