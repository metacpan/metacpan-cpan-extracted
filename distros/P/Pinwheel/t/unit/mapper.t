#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 124;

use Pinwheel::Mapper;


{
    package MockRouteParam;
    sub new {
        my ($class, $v) = @_;
        return bless({v => $v}, $class);
    }
    sub route_param { $_[0]->{v} }
}


# Sanity checks
{
    my $mapper;

    $mapper = Pinwheel::Mapper->new();
    ok(defined($mapper), 'new() returns something');
    ok($mapper->isa('Pinwheel::Mapper'), 'new() returns a Pinwheel::Mapper instance');
}

# Path tidying
{
    my $s;

    $s = Pinwheel::Mapper::_tidy_path('');
    is($s, '/', '_tidy_path ensures leading slash');
    $s = Pinwheel::Mapper::_tidy_path('///');
    is($s, '/', '_tidy_path ensures leading slash after collapsing');
    $s = Pinwheel::Mapper::_tidy_path('/a/');
    is($s, '/a', '_tidy_path strips trailing slashes');
    $s = Pinwheel::Mapper::_tidy_path('/a//b');
    is($s, '/a/b', '_tidy_path collapses multiple slashes');
    $s = Pinwheel::Mapper::_tidy_path('/abc.');
    is($s, '/abc.', '_tidy_path preserves trailing dot');
    $s = Pinwheel::Mapper::_tidy_path('/abc...');
    is($s, '/abc...', '_tidy_path preserves multiple trailing dots');
    $s = Pinwheel::Mapper::_tidy_path('/.abc');
    is($s, '/.abc', '_tidy_path keeps /. at the beginning');
    $s = Pinwheel::Mapper::_tidy_path('///.abc');
    is($s, '/.abc', '_tidy_path collapses multiple slashes at beginning');
    $s = Pinwheel::Mapper::_tidy_path('http://foo');
    is($s, 'http://foo', '_tidy_path preserves protocol prefix');
    $s = Pinwheel::Mapper::_tidy_path('http://foo//bar');
    is($s, 'http://foo/bar', '_tidy_path collapses slashes after http://');
}

# Empty route matching
{
    my ($mapper, $m);
    my $expected = {controller => 'content', action => 'index'};

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('');
    $m = $mapper->match('/');
    is_deeply($m, $expected, 'empty route matches /');

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('');
    $m = $mapper->match('/');
    is_deeply($m, $expected, '"/" route matches /');

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('');
    $m = $mapper->match('');
    is_deeply($m, $expected, 'empty route matches empty path');
}

# Reset connected routes
{
    my ($mapper, $m);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('');
    $mapper->reset();
    $m = $mapper->match('/');
    ok(!defined($m), 'reset clears connected routes');
}

# Simple routes
{
    my ($mapper, $m);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('/foo/:bar');
    $m = $mapper->match('/foo/123');
    is($m->{bar}, 123, 'routes can contain variables');

    $mapper->reset();
    $mapper->connect('foo/:bar');
    $m = $mapper->match('/foo/123');
    is($m->{bar}, 123, 'leading / is ignored in connect call');
    $m = $mapper->match('/foo/%40A%42');
    is($m->{bar}, '@AB', 'components are unescaped by match');
    $m = $mapper->match('/blah/foo/123');
    ok(!defined($m), 'leading text in path is not ignored');
}

# controller/action/id as variables
{
    my ($mapper, $m);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect(':controller');
    $m = $mapper->match('/foo');
    is_deeply($m, { controller => 'foo', action => 'index' },
        'controller can be a variable');

    $mapper->reset();
    $mapper->connect(':controller/:x');
    $m = $mapper->match('/foo/bar');
    is_deeply($m, { controller => 'foo', action => 'index', x => 'bar' },
        'controller can be one of many variables');

    $mapper->reset();
    $mapper->connect(':controller/:action/:id');
    $m = $mapper->match('/c/a/1');
    is_deeply($m, { controller => 'c', action => 'a', id => 1 },
        'variables extracted from /:controller/:action/:id rule');
    $m = $mapper->match('/c/a');
    is_deeply($m, { controller => 'c', action => 'a', id => undef },
        'id is optional in /:controller/:action/:id');
    $m = $mapper->match('/c');
    ok(!defined($m), 'action is not optional in /:controller/:action/:id');

    $mapper->reset();
    $mapper->connect(
        'foo/:controller/:action',
        defaults => { controller => 'c', action => 'a' },
    );
    $m = $mapper->match('/foo');
    is_deeply($m, { controller => 'c', action => 'a' },
        'variable controller and action parameters can have defaults');
}

# Default values
{
    my ($mapper, $m);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect(':controller/:action/:id', id => 1);
    $m = $mapper->match('/c/a');
    is_deeply($m, {controller => 'c', action => 'a', id => 1},
        'default id value can be overridden');

    $mapper->reset();
    $mapper->connect(':controller/:action/:id', action => 'blah');
    $m = $mapper->match('/c');
    is_deeply($m, {controller => 'c', action => 'blah', id => undef},
        'default action value can be overridden');

    $mapper->reset();
    $mapper->connect(':year/:month', month => 1);
    $m = $mapper->match('/2001');
    is($m->{year}, 2001);
    is($m->{month}, 1, '/:year/:month matches with default month');
    $m = $mapper->match('/2001/5');
    is($m->{year}, 2001);
    is($m->{month}, 5, '/:year/:month matches with supplied month');

    $mapper->reset();
    $mapper->connect(':y/:m/:d', defaults => { m => 5, d => 4 });
    $m = $mapper->match('/2001');
    is($m->{y}, 2001);
    is($m->{m}, 5);
    is($m->{d}, 4, '/:y/:m/:d matches with defaults in defaults hash');

    $mapper->reset();
    $mapper->connect(':y/:m/:d', defaults => { m => 2 }, d => 1);
    $m = $mapper->match('/2001');
    is($m->{y}, 2001);
    is($m->{m}, 2);
    is($m->{d}, 1, '/:y/:m/:d matches with mixed defaults syntax');
}

# Requirements
{
    my ($mapper, $m);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect(':num', requirements => { num => '\d+' });
    $m = $mapper->match('/foo');
    ok(!defined($m), '/foo does not match \d+ requirements');
    $m = $mapper->match('/1x');
    ok(!defined($m), '/1x does not match \d+ requirements');
    $m = $mapper->match('/x1');
    ok(!defined($m), '/x1 does not match \d+ requirements');
    $m = $mapper->match('/1');
    is($m->{num}, 1, '/1 matches \d+ requirements');
    $m = $mapper->match('/314159');
    is($m->{num}, 314159, '/314159 matches \d+ requirements');

    $mapper->reset();
    $mapper->connect(':pip', requirements => { pip => '\w{5}' });
    $m = $mapper->match('/abcd');
    ok(!defined($m), '/abcd does not match \w{5}');
    $m = $mapper->match('/abcdef');
    ok(!defined($m), '/abcdef does not match \w{5}');
    $m = $mapper->match('/abcde');
    is($m->{pip}, 'abcde', '/abcde matches \w{5} requirements');
}

# Conditions
{
    my ($mapper, $m);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('/a', conditions => { method => 'PUT' });
    $mapper->connect('/b', conditions => { method => 'any' });
    $mapper->connect('/c');
    $mapper->connect('/d', action => 'c', conditions => { method => 'POST' });
    $mapper->connect('/d', action => 'r', conditions => { method => 'GET' });

    $m = $mapper->match('/a', 'PUT');
    ok(defined($m), 'route matched when methods are the same');
    $m = $mapper->match('/a', 'GET');
    ok(!defined($m), 'route not match when methods differ');
    $m = $mapper->match('/a', 'any');
    ok(defined($m), 'method of "any" matches any method condition');
    $m = $mapper->match('/a');
    ok(defined($m), 'method of undef matches any method condition');

    $m = $mapper->match('/b', 'GET');
    ok(defined($m), 'method condition of "any" matches any method');
    $m = $mapper->match('/b', 'any');
    ok(defined($m), 'method condition of "any" matches "any"');
    $m = $mapper->match('/b');
    ok(defined($m), 'method condition of "any" matches undef method');

    $m = $mapper->match('/c', 'PUT');
    ok(defined($m), 'missing method condition matches any method');
    $m = $mapper->match('/c', 'any');
    ok(defined($m), 'missing method condition matches "any"');
    $m = $mapper->match('/c');
    ok(defined($m), 'missing method condition matches undef method');

    $m = $mapper->match('/d', 'POST');
    is($m->{action}, 'c', 'found correct route based on POST method');
    $m = $mapper->match('/d', 'GET');
    is($m->{action}, 'r', 'found correct route based on GET method');
}

# Groupings
{
    my ($mapper, $m);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect(':year/wk:(week)', week => 1);
    $m = $mapper->match('/2032/wk4');
    is($m->{year}, 2032);
    is($m->{week}, 4, 'matched mixed static/dynamic part');
    $m = $mapper->match('/2032/wk');
    is($m->{year}, 2032);
    is($m->{week}, 1, 'matched mixed part with default value');

    $mapper->reset();
    $mapper->connect(':year/wk:(week)', requirements => { week => '\d+' });
    $m = $mapper->match('/2012/wk5');
    is($m->{year}, 2012);
    is($m->{week}, 5, 'matched mixed part with \d+ requirements');
    $m = $mapper->match('/2012/wk');
    ok(!defined($m), 'numeric requirements prevented null week');
    $m = $mapper->match('/2012/wktwo');
    ok(!defined($m), 'numeric requirements prevented match');

    $mapper->reset();
    $mapper->connect('r/:(name).:(format)');
    $m = $mapper->match('/r/picture.jpg');
    is($m->{name}, 'picture');
    is($m->{format}, 'jpg', 'matched with multiple groupings');
    $m = $mapper->match('/r/code.tar.gz');
    is($m->{name}, 'code');
    is($m->{format}, 'tar.gz', 'default matching after . only stops at /');

    $mapper->reset();
    $mapper->connect('r/:name.:format', format => undef);
    $m = $mapper->match('/r/calendar.rss');
    is($m->{name}, 'calendar');
    is($m->{format}, 'rss');
    $m = $mapper->match('/r/schedule');
    is($m->{name}, 'schedule');
    is($m->{format}, undef);

    $mapper->reset();
    $mapper->connect('r/:name.:format', name => undef, format => undef);
    $m = $mapper->match('/r.rss');
    is($m->{name}, undef);
    is($m->{format}, 'rss');

    $mapper->reset();
    $mapper->connect('x/y-:z');
    $m = $mapper->match('/x/y-abc');
    is($m->{z}, 'abc', 'brackets are optional for groupings');
}

# Wildcards
{
    my ($mapper, $m);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('file/*(path)');
    $m = $mapper->match('/file/a/b/c/d.html');
    is($m->{path}, 'a/b/c/d.html', 'matched wildcard');

    $mapper->reset();
    $mapper->connect('file/*(path).html');
    $m = $mapper->match('/file/a/b/c/d.html');
    is($m->{path}, 'a/b/c/d', 'matched wildcard with static suffix');

    $mapper->reset();
    $mapper->connect('file/*path.html');
    $m = $mapper->match('/file/a/b/c/d.html');
    is($m->{path}, 'a/b/c/d', 'brackets are optional for wildcards');
}

# Multiple routes
{
    my ($mapper, $m);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect(':numbers', requirements => { numbers => '\d+' });
    $mapper->connect(':letters', requirements => { letters => '[a-z]+' });
    $m = $mapper->match('/abc');
    is($m->{letters}, 'abc', 'matched letters route through requirements');
    $m = $mapper->match('/123');
    is($m->{numbers}, '123', 'matched numbers route through requirements');

    $mapper->reset();
    $mapper->connect('files/view/:id', controller => 'blah');
    $mapper->connect(':controller/:action/:id');
    $m = $mapper->match('/files/view/4');
    is_deeply($m, { controller => 'blah', action => 'index', id => 4 },
        'matched first route');
    $m = $mapper->match('/foo/view/4');
    is_deeply($m, { controller => 'foo', action => 'view', id => 4 },
        'matched default route');
}

# Static routes
{
    my ($m, $p);

    $m = Pinwheel::Mapper->new();
    $m->connect('*foo', _static => 1);
    $m->connect('http://www.bbc.co.uk/programmes');
    is(scalar(@{$m->{routes}}), 0, 'static and absolute routes cannot match');
    $m->connect('r/:s');

    $p = $m->match('/r/foo');
    is($p->{s}, 'foo', 'later routes trump static routes');
    $p = $m->match('/foo/bar');
    ok(!defined($p), 'static routes never match');
}

# Simple generation
{
    my ($mapper, $s);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('r/:s');
    $s = $mapper->generate(s => 'hello');
    is($s, '/r/hello', 'generate replaces single variable');

    $mapper->reset();
    $mapper->connect('r/:a/:b');
    $s = $mapper->generate(a => 'hello', b => 'world');
    is($s, '/r/hello/world', 'generate replaces multiple variables');
}

# URL escaping
{
    my ($mapper, $s);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('r/:s');
    $s = $mapper->generate(s => 'hello world');
    is($s, '/r/hello%20world', 'spaces are URL escaped');
    $s = $mapper->generate(s => 'hello/world');
    is($s, '/r/hello%2Fworld', 'slashes are URL escaped');

    $mapper->reset();
    $mapper->connect('r/*s');
    $s = $mapper->generate(s => 'hello/goodbye world');
    is($s, '/r/hello/goodbye%20world', 'slashes are kept in wildcards');
}

# Named route generation
{
    my ($mapper, $s);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('r', ':x');
    $s = $mapper->generate('r');
    ok(!defined($s), 'generate does not ignore mandatory parameters');

    $mapper->reset();
    $mapper->connect(':name');
    $mapper->connect('js', 'r/:(name).js');
    $s = $mapper->generate('js', name => 'blah');
    is($s, '/r/blah.js', 'generate works with named routes');

    $mapper->reset();
    $mapper->connect('r', 'r/*path');
    $s = $mapper->generate(path => 'a/b/c');
    is($s, '/r/a/b/c', 'un-named generate can find named routes');

    $mapper->reset();
    $mapper->connect('x', 'x');
    $mapper->connect('y', 'y');
    $mapper->connect('a', 'a');
    is_deeply($mapper->names, ['a', 'x', 'y']);
}

# Generate with defaults
{
    my ($mapper, $s);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('r', ':a/:b/:c/*path', b => undef);
    $s = $mapper->generate('r', a => 'x', c => 'css', path => 'a/b');
    is($s, '/x/css/a/b', 'undef default is left out of generated path');
    $s = $mapper->generate('r', a => 'x', b => 'r1', c => 'js', path => '9');
    is($s, '/x/r1/js/9', 'default can be replaced in generated path');

    $mapper->reset();
    $mapper->connect('r', 'r/:name.:format', format => undef);
    $s = $mapper->generate('r', name => 'schedule');
    is($s, '/r/schedule');
    $s = $mapper->generate('r', name => 'schedule', format => 'rss');
    is($s, '/r/schedule.rss');
    $s = $mapper->generate('r', name => 'release', format => 'tar.gz');
    is($s, '/r/release.tar.gz');

    $mapper->reset();
    $mapper->connect('r', 'r/:name.:format', name => undef, format => undef);
    $s = $mapper->generate('r', format => 'rss');
    is($s, '/r.rss');
}

# Generate with static routes
{
    my ($mapper, $s);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('a/:x', _static => 1);
    $mapper->connect('b/:x');
    $s = $mapper->generate(x => 'test');
    is($s, '/b/test', 'unnamed static rules are ignored by generate');

    $mapper->reset();
    $mapper->connect('r', 'x/:x', _static => 1);
    $s = $mapper->generate('r', x => 'test');
    is($s, '/x/test', 'named static rules can be used by generate');

    $mapper->reset();
    $mapper->connect('r', 'x/*x', _static => 1);
    $s = $mapper->generate('r', x => 'test');
    is($s, '/x/test', 'static routes don\'t add a trailing slash');
    $s = $mapper->generate('r', x => 'test/');
    is($s, '/x/test/', 'static routes leave a trailing slash in place');
    $s = $mapper->generate('r', x => 'test//');
    is($s, '/x/test//', 'static routes preserve multiple trailing slashes');
}

# Generate with multiple candidates
{
    my ($mapper, $s);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('a/:x', requirements => { x => '\d+' });
    $mapper->connect('b/:x', controller => 'one');
    $mapper->connect('c/:x', controller => 'two');
    $s = $mapper->generate(x => 42);
    is($s, '/a/42', 'generate uses first matching route');
    $s = $mapper->generate(x => 'abc');
    ok(!defined($s), 'generate needs to match controller');
    $s = $mapper->generate(x => 'abc', controller => 'two');
    is($s, '/c/abc', 'generate skipped second route due to controller');
}

# Generate with grouped and wildcard parameters
{
    my ($mapper, $s);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('r', ':a/:(b):(c)');
    $mapper->connect('s', 'file/*(url).html');
    $s = $mapper->generate('r', a => 'archives', b => 'week', c => 5);
    is($s, '/archives/week5', 'generate fills in grouped parameters');
    $s = $mapper->generate('s', url => 'foo/bar');
    is($s, '/file/foo/bar.html', 'generate fills in wildcard parameters');
}

# Filter functions
{
    my ($mapper, $s, $filter);

    $filter = sub {
        my $params = shift;
        $params->{n} = sprintf('%04d', $params->{n});
    };
    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('r', ':n', _filter => $filter);
    $s = $mapper->generate('r', n => 1);
    is($s, '/0001', 'filter can mutate generate parameters');

    $filter = sub {
        my $params = shift;
        $params->{x} = $params->{y};
    };
    $mapper->reset();
    $mapper->connect('r', ':x', _filter => $filter);
    $s = $mapper->generate('r', y => 'foo');
    is($s, '/foo', 'filter can provide mandatory parameters');
}

# Expanding object parameters
{
    my ($mapper, $s, $obj);

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect('number', ':n');
    $mapper->connect('rgb', ':r/:g/:b');
    $mapper->connect('digits', 'd/:d', requirements => { d => '\d+' });

    $s = $mapper->generate('number', n => MockRouteParam->new(42));
    is($s, '/42', 'object can provide a scalar route parameter');
    $s = $mapper->generate('number', obj => MockRouteParam->new({n => 5}));
    is($s, '/5', 'object can provide a route parameter via a hash');

    $obj = MockRouteParam->new({r => 10, g => 20, b => 30});
    $s = $mapper->generate('rgb', obj => $obj);
    is($s, '/10/20/30', 'object can provide many route parameters');

    $obj = MockRouteParam->new({d => 10});
    $s = $mapper->generate('digits', d => $obj);
    is($s, '/d/10', 'route param is expanded before validation');
    $obj = MockRouteParam->new({d => 'x'});
    $s = $mapper->generate('digits', d => $obj);
    ok(!defined($s), 'expanded route param must match requirements');
}

# Base parameters
{
    my ($mapper, $s, $base);

    $base = { controller => 'c', action => 'i', a => 1, b => 2 };

    $mapper = Pinwheel::Mapper->new();
    $mapper->connect(':a/:b', controller => 'c', action => 'i');
    $mapper->connect(':a/:b/xyz', controller => 'a', action => 'index');
    $s = $mapper->generate(_base => $base);
    is($s, '/1/2', 'base parameters can fill in requirements');
    $s = $mapper->generate(b => 3, _base => $base);
    is($s, '/1/3', 'supplied parameters override _base');
    $s = $mapper->generate(controller => 'a', a => 10, b => 20, _base => $base);
    is($s, '/10/20/xyz', 'base parameters can be ignored');

    $mapper->reset();
    $mapper->connect('/:controller/:a/:b');
    $s = $mapper->generate(_base => $base);
    ok(!defined($s), 'base parameters cannot in controller');
    $s = $mapper->generate(controller => 'x', a => 10, b => 20);
    is($s, '/x/10/20', 'base controller can be ignored');
}
