#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 67;
use lib 't/';

# Some special helpers to restove the environment
my %ORIG_ENV = %ENV;
sub restoreENV { %ENV = %ORIG_ENV }

# TEST: use
BEGIN {
    use_ok('REST::Application::Routes');
    $SIG{'__WARN__'} = sub { &Carp::croak };
}

# TEST: new()
{
    my $rest = REST::Application::Routes->new();
    isa_ok($rest, 'REST::Application::Routes', "Object instantiation.");
    isa_ok($rest, 'REST::Application', "Object instantiation.");
}

# TEST: query()
{
    my $rest = REST::Application::Routes->new();
    my $query = $rest->defaultQueryObject();
    is(ref($query), 'CGI', "Retrieving default query object.");
}

# TEST: query()
{
    my $rest = REST::Application::Routes->new();
    my $query = $rest->query();
    is(ref($query), 'CGI', "Retrieving query object.");
}

# TEST: query($value)
{
    my $rest = REST::Application::Routes->new();
    my $query = $rest->query("x/a/b");
    is($query, 'x/a/b', "Setting and retrieving a query object.");
}

# TEST: query(undef)
{
    my $rest = REST::Application::Routes->new();
    my $query = $rest->query(undef);
    is($query, undef, "Setting and retrieving a query object w/ undef.");
}

# TEST: defaultQueryObject($value)
{
    my $rest = REST::Application::Routes->new();
    my $query = $rest->defaultQueryObject("xxx");
    is($query, 'xxx', "Setting and retrieving default query object.");
}

# TEST: defaultQueryObject(undef)
{
    my $rest = REST::Application::Routes->new();
    my $query = $rest->defaultQueryObject(undef);
    is($query, undef, "Setting and retrieving default query object w/ undef value.");
}

# TEST: resourceHooks()
{
    my $rest = REST::Application::Routes->new();
    my $resources = $rest->resourceHooks();
    is_deeply($resources, {}, "Getting resource hooks when none are set.");
}

# TEST: resourceHooks()
{
    my $rest = REST::Application::Routes->new();
    my $sub = sub {};
    my $template = '/var/foo/bar/baz';
    my $resources = $rest->resourceHooks($template => $sub);
    isa_ok($resources, 'HASH', "Resource hook using a code ref (data type check)");
    is($resources->{$template}, $sub, "Resource hook using a code ref (value check)");
}

# TEST: resourceHooks()
{
    my $rest = REST::Application::Routes->new();
    my %uniq;
    my @keys = map { int(rand(100000)); } (1 .. 10000);
    @uniq{@keys} = 1;
    @keys = keys(%uniq);  # Make sure we have no duplicate keys
    my @k2 = @keys;
    my $resources = $rest->resourceHooks(map { $_ => "x" } @keys);
    my $keys = [ keys %$resources ];
    is_deeply(\@k2, \@keys, "Resource hook regexes have their order preserved.");
}

# TEST: resourceHooks()
{
    my $rest = REST::Application::Routes->new();
    my $resources = $rest->resourceHooks({ foo => 1 });
    is_deeply($resources, {foo => 1}, "Resource hook set from a hash ref");
}

# TEST: resourceHooks()
{
    my $rest = REST::Application::Routes->new();
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
    my $rest = REST::Application::Routes->new();
    is_deeply($rest->getPathInfo(), "/blah/bar", "Retrieving path info.");
}

# TEST: getRequestMethod()
{
    restoreENV();
    CGI->initialize_globals();
    $ENV{REQUEST_METHOD} = "PuT";
    my $rest = REST::Application::Routes->new();
    is_deeply($rest->getRequestMethod(), "PUT", "Retrieving request method.");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application::Routes->new();
    $ENV{PATH_INFO} = "/parts/12345/foo";
    $rest->resourceHooks('/parts/:nums/:var' =>
                            sub { ref($_[0]) . $_[1]->{nums}.$_[1]->{var} });
    is(${$rest->loadResource()}, "REST::Application::Routes12345foo", "Loading resource - code reference");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application::Routes->new();
    $ENV{PATH_INFO} = "/parts/12345/foo";
    $rest->resourceHooks('/parts/:nums/:var' => undef);
    is(${$rest->loadResource()}, undef, "Loading resource - default hook via undef");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application::Routes->new();
    $ENV{PATH_INFO} = "/NOEXIST/12345.xml";
    $rest->resourceHooks('/parts/:nums/:var' => sub {1});
    is(${$rest->loadResource()}, undef, "Loading resource - default hook via non-match");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    use_ok('RoutesTestClass');
    my $rest = RoutesTestClass->new();
    $rest->resourceHooks(parts =>  "barMethod");
    my $resource = $rest->loadResource("parts", "blah", "bar", "baz");
    is($$resource, 'blah:bar:baz', "Loading resource - \"methodName\" hook");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application::Routes->new();
    $ENV{PATH_INFO} = "/parts/12345/cows";
    $rest->resourceHooks('/parts/:var/:foo' =>  [$rest, "getPathInfo"]);
    my $resource = $rest->loadResource();
    is($$resource, '/parts/12345/cows', "Loading resource - [\$object w/ \"methodName\"] hook");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application::Routes->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345/cows";
    $rest->resourceHooks('/parts/:var/:foo' => {
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
    my $rest = REST::Application::Routes->new();
    $ENV{REQUEST_METHOD} = "PuT";
    $ENV{PATH_INFO} = "/parts/12345/cows";
    $rest->resourceHooks('/parts/:var/:foo' => {
                            get => sub { "x" },
                            puT => [$rest, "getPathInfo"],
                            POST => "getPathInfo",
                            'deLEte' =>  undef,
                         });
    my $resource = $rest->loadResource();
    is($$resource, '/parts/12345/cows', "Loading resource for PUT HTTP method.");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application::Routes->new();
    $ENV{REQUEST_METHOD} = "PoSt";
    $ENV{PATH_INFO} = "/parts/12345/cows";
    $rest->resourceHooks('/parts/:var/:foo' => {
                            get => sub { "x" },
                            puT => [$rest, "getPathInfo"],
                            POST => "getPathInfo",
                            'deLEte' =>  undef,
                         });
    my $resource = $rest->loadResource();
    is($$resource, '/parts/12345/cows', "Loading resource for POST HTTP method.");
}

# TEST: loadResource()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application::Routes->new();
    $ENV{REQUEST_METHOD} = "delete";
    $ENV{PATH_INFO} = "/parts/12345/cows";
    $rest->resourceHooks('/parts/:var/:foo' => {
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
    my $rest = REST::Application::Routes->new();
    $ENV{REQUEST_METHOD} = "delete";
    $ENV{PATH_INFO} = "/parts/12345/cows";
    my $obj = RoutesTestClass->new();
    $rest->resourceHooks('/parts/:var/:nam' => $obj);
    my $resource = $rest->loadResource();
    is($$resource, "xAbC", "Loading resource - with \$object->getResource() hook");
}

# TEST: headerType
{
    my $rest = REST::Application::Routes->new();
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
    my $rest = REST::Application::Routes->new();
    my %hash = $rest->header();
    is_deeply(\%hash, {}, "Retrieving default header values.");
    $rest->header(-type => 'text/html', -foobar => 5);
    %hash = $rest->header();
    is_deeply(\%hash, {-type => 'text/html', -foobar => 5}, "Retrieving custom header values.");
}

# TEST: resetHeader()
{
    my $rest = REST::Application::Routes->new();
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
    my $rest = REST::Application::Routes->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/honda/hubcaps/12345";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub {
        my ($app, $hash) = @_;
        $app->header(-type => 'text/plain');
        return "hubcap - $hash->{id} - Honda";
    };
    $rest->resourceHooks('/honda/hubcaps/:id' => $resourceHook);
    my $output = $rest->run();
    my $answer = "Content-Type: text/plain; charset=ISO-8859-1\r\n\r\nhubcap - 12345 - Honda";
    is($output, $answer, "Running a REST Application");
}

# TEST: run()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application::Routes->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/honda/hubcaps/12345";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { "this is a test" };
    $rest->resourceHooks('/honda/hubcaps/:id' => $resourceHook);
    my $answer = "Content-Type: text/html; charset=ISO-8859-1\r\n\r\nthis is a test";
    is($rest->run(), $answer, "Running a REST Application which has a resource being its own repr.");
}

# TEST: addRepresentation
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application::Routes->new();
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
    my $rest = REST::Application::Routes->new();
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
    my $rest = REST::Application::Routes->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345/cows";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { return };
    $rest->resourceHooks('/parts/:num/:var' => $resourceHook);
    my $output = $rest->run();
    my $answer = "Content-Type: text/html; charset=ISO-8859-1\r\n\r\n";
    is($output, $answer, "Running a REST Application");
}

# TEST: preRun() and postRun()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = RoutesTestClass->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345/cows";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { return "my resource" };
    $rest->resourceHooks('/parts/:num/:var' => $resourceHook);
    $rest->run();
    is($rest->{preRun}, 1, "preRun() method.");
    is($rest->{postRun}, "my resource", "postRun() method.");
}

# TEST: setRedirect()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = REST::Application::Routes->new();
    $rest->setRedirect("http://www.google.com");
    like($rest->getHeaders(), qr{^Status: 302 (Moved|Found)\r\n[lL]ocation: http://www\.google\.com\r\n\r\n$}, "Redirect header");
}

# TEST: getMatchText()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = RoutesTestClass->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345/cows";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    $rest->{TEST_TEXT} = "radio/is/friendly";  # See TestClass
    my $resourceHook = sub {
        my ($app, $h) = @_;
        return "$h->{bar} $h->{foo}";
    };
    $rest->resourceHooks('radio/:foo/:bar' => $resourceHook);
    my $output = $rest->run();
    is($output, "Content-Type: text/html; charset=ISO-8859-1\r\n\r\nfriendly is", "Using alternate matching text instead of PATH_INFO.");
}

# TEST: checkMatch()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = RoutesTestClass->new();
    $ENV{REQUEST_METHOD} = "GET";
    $ENV{PATH_INFO} = "/parts/12345.xml";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    $rest->{TEST_TEXT} = "Quis/hic/locus?";  # See TestClass
    $rest->resourceHooks( q(Quis/hic/locus?) => sub { return "I match" },
                          q(Quis) => sub { undef } );
    my $output = $rest->run();
    is($output, "Content-Type: text/html; charset=ISO-8859-1\r\n\r\nI match", "Using custom matching logic, checkMatch().");
}

# TEST: extraHandlerArgs()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = RoutesTestClass->new();
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { shift; shift; join(" ", @_) };
    $rest->{TEST_TEXT} = "foo";
    $rest->resourceHooks(q(foo) => $resourceHook);
    $rest->extraHandlerArgs(qw(hello jello world foo bar));
    my $output = $rest->run();
    is($output, "Content-Type: text/html; charset=ISO-8859-1\r\n\r\nhello jello world foo bar", "Setting arguments for the handler.");
}

# TEST: preHandler()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = RoutesTestClass->new();
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { shift; shift; join(" ", @_) };
    $rest->{TEST_PRE} = 1;
    $rest->resourceHooks(q(foo) => $resourceHook);
    $rest->extraHandlerArgs(qw(hello jello world foo bar));
    my $output = $rest->run();
    is($rest->{preHandler}, "hello:jello:world:foo:bar");
}

# TEST: postHandler()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = RoutesTestClass->new();
    $ENV{PATH_INFO} = "foo";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { shift; shift; return join(" ", @_) ; };
    $rest->{TEST_POST} = 1;
    $rest->resourceHooks(foo => $resourceHook);
    $rest->extraHandlerArgs(qw(hello jello world foo bar));
    my $output = $rest->run();
    is($rest->{postHandler}, "hello jello world foo barhello:jello:world:foo:bar");
}

# TEST: callHandler()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = RoutesTestClass->new();
    $ENV{PATH_INFO} = "foo";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $resourceHook = sub { };
    $rest->{TEST_CALL} = 1;
    my $output = $rest->callHandler($resourceHook, {}, "a", "b", "c");
    is($output, "CODEa:b:c", "The handle caller w/o error.");
}

# TEST: callHandler()
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = RoutesTestClass->new();
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

# TEST: Test that the order of the routes is preserved.
{
    my $obj = REST::Application::Routes->new();
    $obj->resourceHooks(map {$_ => $_*$_} (1 .. 1000));
    is_deeply([keys %{$obj->resourceHooks}], [(1 .. 1000)],
              'resourceHooks contains ordered keys.');
    is_deeply([values %{$obj->resourceHooks}], [map {$_*$_} (1 .. 1000)],
              'resourceHooks contains ordered values.');
}

# TEST: run, simple usage.
{
    restoreENV();
    CGI->initialize_globals();
    my $rest = RoutesTestClass->new();
    $ENV{PATH_INFO} = "foo";
    $ENV{REST_APP_RETURN_ONLY} = 1;
    my $obj = REST::Application::Routes->new();
    $obj->resourceHooks('/foo/:var/bar', => sub {shift; shift;});
    is_deeply(${$obj->loadResource("/foo/42/bar")}, {var => 42},
              "Testing parsing action");
    is($obj->getLastMatchPath(), "/foo/42/bar", "Testing getLastMatchPath");
    is($obj->getLastMatchPattern(), "/foo/:var/bar", 
       "Testing getLastMatchPattern");
}

# TEST: run, more advanced usage.
{
   my $obj = REST::Application::Routes->new();
   $obj->resourceHooks(
       '/data/tags/:tag', => sub {shift; shift},
       '/data/tags', => sub {shift; shift;},
       '/data/pages/:page/sections/:section', => sub {shift; shift;},
       '/data/workspaces/:ws/pages/:page', => sub {shift; shift;},
       '/data/workspaces/:ws', => sub {shift; shift;},
   );

   is_deeply(${$obj->loadResource("/data/tags")}, {}, '/data/tags matches');
   is_deeply(${$obj->loadResource("/data/tags/foo")}, {tag => 'foo'}, 
             '/data/tags/foo matches');
   is_deeply(${$obj->loadResource("/data/pages/cows/sections/udder")},
                       {page => 'cows', section => 'udder'},
                       '/data/pages/cows/sections/udder/love/cakes matches');
   is(${$obj->loadResource("/data/pages/cows/sections/udder/love/cakes")},
                        undef,
                       '/data/pages/cows/sections/udder/love/cakes no match');
   is_deeply(${$obj->loadResource("/data/workspaces/cows")}, {ws => 'cows'},
             '/data/workspaces/cows matches');
}

# TEST: Empty variable fix, from Chris Dent.
{
   my $obj = REST::Application::Routes->new();
   $obj->resourceHooks(
       '/data/tags/:tag', => sub {shift; shift},
       '/data/tags', => sub {shift; "cow"},
   );

   is_deeply(${$obj->loadResource("/data/tags")}, "cow", '/data/tags matches');
   is_deeply(${$obj->loadResource("/data/tags/")}, "cow", '/data/tags matches');
   is_deeply(${$obj->loadResource("/data/tags/foo")}, {tag => 'foo'}, 
             '/data/tags/foo matches');
}

# TEST: make sure /foo does not match in the middle of something else
{
    my $obj = REST::Application::Routes->new();
    $obj->resourceHooks(
        '/foo', => sub { shift; "cow" },
    );
    is( ${$obj->loadResource("/fooCOW")}, undef,
        '/fowCOW is not matched' );
}
