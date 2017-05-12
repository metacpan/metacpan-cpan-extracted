#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 308;

use Pinwheel::Context;
use Pinwheel::Controller;

use FindBin qw($Bin);


# Config::Hooks template
{
    package Config::Hooks;
    our @log;
    sub _initialise { push @log, 'initialise' };
    sub _before_dispatch { push @log, ['before_dispatch', @_] };
    sub _after_dispatch { push @log, ['after_dispatch', @_] };
}


{
    package Pinwheel::Helpers;
    our @EXPORT_OK = qw(render);
    use Pinwheel::Controller qw(render);

    package Helpers::Application;
    our @EXPORT_OK = qw(foo yield);
    sub foo { 'foo' }
    sub yield { Pinwheel::Context::get('render')->{content}{layout} }

    package Helpers::NumberOne;
    our @EXPORT_OK = qw(bar);
    sub bar { }; bar(); # Keep Devel::Cover happy

    package Helpers::Pagination;
    our @EXPORT_OK = qw(paginate nonexistent);
    sub paginate { }; paginate(); # Keep Devel::Cover happy

    package Helpers::Three;
    our @EXPORT_OK = qw(foo);
    sub foo { }; foo(); # Keep Devel::Cover happy


    package Controllers::NumberOne;
    our @ACTIONS = qw(show);
    sub show { }; show(); # Keep Devel::Cover happy

    package Controllers::Two;
    our @ACTIONS = qw(show ping error bad_template);
    our @HELPERS = qw(Pagination);
    sub show { Pinwheel::Controller::render(action => 'ping') }
    sub ping { }
    sub error { die 'blah' }
    sub bad_template { }

    package Controllers::Three;
    our @ACTIONS = qw(nonexistent);
    our $LAYOUT = 'blah';

    package Controllers::Bad;
}

# By default, just suppress error logging.
is($Pinwheel::Controller::error_logger, \&Pinwheel::Controller::default_error_logger, 'error_logger defaults to default_error_logger');
$Pinwheel::Controller::error_logger = sub {};

# Controller info
{
    my $c;

    # Default helpers come from Helpers::Application and Helpers::<Controller>
    $c = Pinwheel::Controller::_get_controller('number_one');
    is(scalar(keys %{$c->{helpers}}), 4);
    is($c->{helpers}{foo}, \&Helpers::Application::foo);
    is($c->{helpers}{yield}, \&Helpers::Application::yield);
    is($c->{helpers}{render}, \&Pinwheel::Helpers::render);
    is($c->{helpers}{bar}, \&Helpers::NumberOne::bar);
    is(scalar(keys %{$c->{actions}}), 1);
    is($c->{actions}{show}, \&Controllers::NumberOne::show);
    is($c->{layout}, undef);

    # Helpers::<Controller> is optional
    # Extra helpers can be listed in @HELPERS
    $c = Pinwheel::Controller::_get_controller('two');
    is(scalar(keys %{$c->{helpers}}), 4);
    is($c->{helpers}{foo}, \&Helpers::Application::foo);
    is($c->{helpers}{yield}, \&Helpers::Application::yield);
    is($c->{helpers}{render}, \&Pinwheel::Helpers::render);
    is($c->{helpers}{paginate}, \&Helpers::Pagination::paginate);
    is(scalar(keys %{$c->{actions}}), 4);
    is($c->{actions}{show}, \&Controllers::Two::show);
    is($c->{actions}{ping}, \&Controllers::Two::ping);
    is($c->{actions}{error}, \&Controllers::Two::error);
    is($c->{actions}{bad_template}, \&Controllers::Two::bad_template);
    is($c->{layout}, undef);

    # The controller helper has a higher priority than Helpers::Application
    $c = Pinwheel::Controller::_get_controller('three');
    is(scalar(keys %{$c->{helpers}}), 3);
    is($c->{helpers}{yield}, \&Helpers::Application::yield);
    is($c->{helpers}{render}, \&Pinwheel::Helpers::render);
    is($c->{helpers}{foo}, \&Helpers::Three::foo);
    is(scalar(keys %{$c->{actions}}), 0);
    is($c->{layout}, 'blah');

    # The controller information is cached after the first lookup
    $Controllers::Three::LAYOUT = 'wibble';
    $c = Pinwheel::Controller::_get_controller('three');
    is($c->{layout}, 'blah');

    # Bad controller (no @ACTIONS)
    $c = Pinwheel::Controller::_get_controller('bad');
    ok(!defined($c));
}

# Layout helpers
{
    my $helpers;

    $helpers = Pinwheel::Controller::_get_layout_helpers();
    is(scalar(keys %$helpers), 3);
    is($helpers->{yield}, \&Helpers::Application::yield);
    is($helpers->{foo}, \&Helpers::Application::foo);
    is($helpers->{render}, \&Pinwheel::Helpers::render);

    # Cached after first lookup
    is($helpers, Pinwheel::Controller::_get_layout_helpers());
}

# Route parameter validator
{
    my $params;

    # Bad controller values
    ok(!Pinwheel::Controller::_check_route_params(undef));
    $params = { controller => '0', action => 'show' };
    ok(!Pinwheel::Controller::_check_route_params($params));
    $params = { controller => '..', action => 'show' };
    ok(!Pinwheel::Controller::_check_route_params($params));

    # Good controller values
    $params = { controller => 'x', action => 'show' };
    ok(Pinwheel::Controller::_check_route_params($params));
    $params = { controller => 'aaa', action => 'show' };
    ok(Pinwheel::Controller::_check_route_params($params));
    $params = { controller => 'a0_9', action => 'show' };
    ok(Pinwheel::Controller::_check_route_params($params));

    # Bad action values
    $params = { controller => 'x', action => '0' };
    ok(!Pinwheel::Controller::_check_route_params($params));
    $params = { controller => 'x', action => '..' };
    ok(!Pinwheel::Controller::_check_route_params($params));

    # Good action values
    $params = { controller => 'x', action => 'x' };
    ok(Pinwheel::Controller::_check_route_params($params));
    $params = { controller => 'x', action => 'aaa' };
    ok(Pinwheel::Controller::_check_route_params($params));
    $params = { controller => 'x', action => 'a0_9' };
    ok(Pinwheel::Controller::_check_route_params($params));
}

# name_like_this to NameLikeThis converter
{
    my $fn = \&Pinwheel::Controller::_make_mixed_case;

    is(&$fn('x'), 'X');
    is(&$fn('abc'), 'Abc');
    is(&$fn('abc_def'), 'AbcDef');
    is(&$fn('abc_def_ghi'), 'AbcDefGhi');
    is(&$fn('a2z'), 'A2z');
    is(&$fn('a_b_c'), 'ABC');
}

# Construct template name (eg, for render)
{
    my ($fn, $route);

    $fn = sub { Pinwheel::Controller::_make_template_name(@_) };
    $route = { controller => 'foo', action => 'bar' };

    is(&$fn({}, $route), 'foo/bar');

    is(&$fn({action => 'x'}, $route), 'foo/x');
    is(&$fn({action => 'x_y'}, $route), 'foo/x_y');
    is(&$fn({action => '.'}, $route), undef);
    is(&$fn({action => '..'}, $route), undef);
    is(&$fn({action => 'x/y'}, $route), undef);
    is(&$fn({action => 'x.y'}, $route), undef);

    is(&$fn({template => 'a'}, $route), undef);
    is(&$fn({template => 'a/b'}, $route), 'a/b');
    is(&$fn({template => 'a_b/c_d'}, $route), 'a_b/c_d');
    is(&$fn({template => 'a/b/c'}, $route), undef);
    is(&$fn({template => 'a/..'}, $route), undef);
    is(&$fn({template => 'a/b..'}, $route), undef);
    is(&$fn({template => 'a/b.c'}, $route), undef);
    is(&$fn({template => '../a'}, $route), undef);

    is(&$fn({partial => 'a'}, $route), 'foo/_a');
    is(&$fn({partial => 'a/b'}, $route), 'a/_b');
    is(&$fn({partial => 'a/_b'}, $route), 'a/__b');
    is(&$fn({partial => 'a/b.c'}, $route), undef);
    is(&$fn({partial => 'a/b/c'}, $route), undef);
}

# url_for (wrapper around Mapper::generate)
{
    my ($request, $url);

    $request = {
        host => 'www.bbc.co.uk',
        path => '/radio4/p/today',
        base => '/~paulc'
    };

    $Pinwheel::Controller::map->reset();
    Pinwheel::Controller::connect('r', '/:network/p/:brand');
    Pinwheel::Controller::connect('s', '/:foo/x');
    Pinwheel::Controller::connect('t', 'http://foo.com/*path');
    
    $url = Pinwheel::Controller::url_for('s', foo => 'a');
    is($url, '/a/x');

    Pinwheel::Context::set('*Pinwheel::Controller',
        request => $request,
        route => $Pinwheel::Controller::map->match($request->{path})
    );

    $url = Pinwheel::Controller::url_for();
    is($url, '/~paulc/radio4/p/today');
    $url = Pinwheel::Controller::url_for(only_path => 0);
    is($url, 'http://www.bbc.co.uk/~paulc/radio4/p/today');
    $url = Pinwheel::Controller::url_for(network => 'radio1');
    is($url, '/~paulc/radio1/p/today');
    $url = Pinwheel::Controller::url_for(brand => 'tomorrow');
    is($url, '/~paulc/radio4/p/tomorrow');
    $url = Pinwheel::Controller::url_for('s', foo => 'a');
    is($url, '/~paulc/a/x');
    $url = Pinwheel::Controller::url_for('s', foo => 'a', only_path => 1);
    is($url, '/~paulc/a/x');
    $url = Pinwheel::Controller::url_for('s', foo => 'a', only_path => 0);
    is($url, 'http://www.bbc.co.uk/~paulc/a/x');
    $url = Pinwheel::Controller::url_for('t', path => 'a/b/c');
    is($url, 'http://foo.com/a/b/c');

    $url = Pinwheel::Controller::url_for('x', foo => 'a');
    is($url, undef);
}

# Retrieve compiled template
{
    my ($t, $t2, $c);

    Pinwheel::Controller::set_templates_root("$Bin/../fixtures/tmpl");

    # %Pinwheel::Controller::template_cache isn't part of the public API, but these
    # tests use the hash.
    my $cacheref = \%Pinwheel::Controller::template_cache;
    is(scalar(keys %$cacheref), 0, 'template cache starts off empty');

    $t = Pinwheel::Controller::_get_template('text/hello.txt');
    like($t->({}, {}, {}), qr/^hello$/s);
    # Templates are cached in the session's context
    $t2 = Pinwheel::Controller::_get_template('text/hello.txt');
    is($t, $t2);
    is(scalar(keys %$cacheref), 1, 'template cache now non-empty');

    # Name must be valid before the filesystem is checked
    $t = Pinwheel::Controller::_get_template('text/invisible');
    is($t, undef);
    $t = Pinwheel::Controller::_get_template('text/invisible.x.y');
    is($t, undef);

    # Multiple extensions are supported
    $t = Pinwheel::Controller::_get_template('text/old.txt');
    like($t->({}, {}, {}), qr/^old$/s);

    # File exists, but template names must be \w+/\w+\.\w+
    ok(!Pinwheel::Controller::_get_template('text/invisible.x.y'));
    ok(!Pinwheel::Controller::_get_template('../out_of_reach.txt'));
    ok(!Pinwheel::Controller::_get_template('shared/../out_of_reach.txt')); # but is OK via symlink
    ok(!Pinwheel::Controller::_get_template('out_of_reach.txt'));
    # File exists, but extension ('blah') is unknown
    ok(!Pinwheel::Controller::_get_template('text/unknown.txt'));
    # File doesn't exist
    ok(!Pinwheel::Controller::_get_template('text/nonexistent.txt'));

    %$cacheref = ();
    Pinwheel::View::Data::_clear_templates();
    Pinwheel::Controller::preload_templates();

    is(scalar(keys %$cacheref), 22, 'preload_templates loads all valid templates');

    # Verify that, just in case File::Find::find returns things outside of
    # templates_root, we don't attempt to load them
    my $old_find = \&File::Find::find;
    my $fake_find = sub {
        my ($opts, $dir) = @_;
        my $w = $$opts{wanted};
        local $_ = "$Bin/../fixtures/out_of_reach.txt.erb";
        &$w();
    };
    { no warnings 'redefine'; *File::Find::find = $fake_find; }

    %$cacheref = ();
    Pinwheel::View::Data::_clear_templates();
    Pinwheel::Controller::preload_templates();

    is(scalar(keys %$cacheref), 0, 'preload_templates validates templates_root');
    { no warnings 'redefine'; *File::Find::find = $old_find; }
}

# Retrieve compiled layout template
{
    my ($ctx, $t);

    Pinwheel::Controller::set_templates_root("$Bin/../fixtures/tmpl");
    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');

    $t = Pinwheel::Controller::_get_layout('html', {});
    is($t, Pinwheel::Controller::_get_template('layouts/application.html'));
    $t = Pinwheel::Controller::_get_layout('html', {layout => 0});
    ok(!$t);

    $ctx->{controller} = Pinwheel::Controller::_get_controller('three');
    $t = Pinwheel::Controller::_get_layout('html', {});
    is($t, Pinwheel::Controller::_get_template('layouts/blah.html'));
    delete $ctx->{controller};

    $ctx->{route}{controller} = 'one';
    $t = Pinwheel::Controller::_get_layout('html', {});
    is($t, Pinwheel::Controller::_get_template('layouts/one.html'));
    $t = Pinwheel::Controller::_get_layout('blah', {});
    ok(!$t);
    delete $ctx->{route};

    $t = Pinwheel::Controller::_get_layout('html', {partial => 'foo'});
    ok(!$t);

    $ctx->{route}{controller} = 'text';
    $t = Pinwheel::Controller::_get_layout(
        'txt', {partial => 'hello', layout => 'wrapper'}
    );
    is($t, Pinwheel::Controller::_get_template('text/_wrapper.txt'));
    delete $ctx->{route};
    $t = Pinwheel::Controller::_get_layout(
        'txt', {partial => 'text/hello', layout => 'wrapper'}
    );
    is($t, Pinwheel::Controller::_get_template('text/_wrapper.txt'));

    eval { Pinwheel::Controller::_get_layout('html', {layout => 'nonexistent'}) };
    like($@, qr/unable to find layouts\/nonexistent/i);
}

# Render a template with optional layout
{
    my ($ctx, $renderctx, $fn, $content);

    Pinwheel::Context::reset();
    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    $renderctx = Pinwheel::Context::get('render');
    $fn = sub {
        my ($name, $lname, $format, $locals, $globals) = @_;
        my ($template, $layout);
        $template = Pinwheel::Controller::_get_template("$name.$format");
        $layout = Pinwheel::Controller::_get_template("$lname.$format") if ($lname);
        $locals ||= {};
        $globals ||= {};
        Pinwheel::Context::set('template', %$globals);
        return Pinwheel::Controller::_render_template($template, $layout, $locals);
    };

    $content = &$fn('text/hello', undef, 'txt');
    like($content, qr/^hello$/s);
    $content = &$fn('text/hello', 'text/_wrapper', 'txt');
    like($content, qr/^t:hello\s*$/s);

    # Locals are visible to the layout too
    $content = &$fn('text/local', 'text/_var', 'txt', {var => 'x'});
    like($content, qr/^x\s*-x\s*$/s);

    $content = &$fn('text/local', undef, 'txt', {var => 'local'});
    like($content, qr/^local$/s);
    $content = &$fn('text/global', undef, 'txt', {}, {var => 'global'});
    like($content, qr/^global$/s);
    # Ensure the base helpers are picked up even without a controller
    $content = &$fn('text/helper', undef, 'txt');
    like($content, qr/^foo$/s);
    # Same again, with a controller
    $ctx->{controller}{helpers} = Pinwheel::Controller::_get_helpers(['Application']);
    $content = &$fn('text/helper', undef, 'txt');
    like($content, qr/^foo$/s);

    $renderctx->{format} = ['txt'];
    $ctx->{route}{controller} = 'text';
    $ctx->{controller}{helpers} = Pinwheel::Controller::_get_helpers(['Pinwheel::Helpers']);
    $content = &$fn('text/nest', undef, 'txt');
    like($content, qr/nest:t:nested\s*$/s);
}

# Render the content part of a response
{
    my ($ctx, $renderctx, $s, $f, $obj);

    Pinwheel::Context::reset();
    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    $ctx->{route}{controller} = 'text';
    $ctx->{route}{action} = 'hello';
    $ctx->{controller}{helpers} = Pinwheel::Controller::_get_helpers(['Pinwheel::Helpers']);
    $renderctx = Pinwheel::Context::get('render');
    $renderctx->{format} = ['txt'];

    ($s, $f) = Pinwheel::Controller::_render_content({text => 'test'});
    is($s, 'test');
    is($f, 'txt');
    ($s, $f) = Pinwheel::Controller::_render_content({text => ''});
    is($s, '');
    is($f, 'txt');

    ($s, $f) = Pinwheel::Controller::_render_content({});
    like($s, qr/^hello$/s);
    is($f, 'txt');
    ($s, $f) = Pinwheel::Controller::_render_content({layout => 'prefix'});
    like($s, qr/^text:hello\s*$/s);
    is($f, 'txt');
    ($s, $f) = Pinwheel::Controller::_render_content({format => 'json'});
    like($s, qr/^\("hello"\)\s*$/s);
    is($f, 'json');
    ($s, $f) = Pinwheel::Controller::_render_content({
        action => 'nest',
        layout => 'prefix'
    });
    like($s, qr/^text:nest:t:nested\s*$/s);
    is($f, 'txt');

    ($s, $f) = Pinwheel::Controller::_render_content({via => 'hash', format => 'json'});
    like($s->to_string($f), qr/{\s*"p":\s*"hello"\s*}/);
    is($f, 'json');
    ($s, $f) = Pinwheel::Controller::_render_content({via => 'hash', format => 'xml'});
    like($s->to_string($f), qr/<p>hello<\/p>/);
    is($f, 'xml');
    Pinwheel::View::Data::_clear_templates();

    eval { Pinwheel::Controller::_render_content({partial => '../blah'}) };
    like($@, qr/invalid template name/i);
    eval { Pinwheel::Controller::_render_content({partial => 'nonexistent'}) };
    like($@, qr/unable to find template/i);
}

# Render the response headers
{
    my ($fn, $headers);

    $fn = sub {
        my ($ctx, $raw, %h);
        $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
        delete $ctx->{response}{headers}{'status'};
        delete $ctx->{response}{headers}{'content-type'};
        delete $ctx->{response}{headers}{'location'};
        $raw = Pinwheel::Controller::_render_headers(@_);
        $h{$_->[0]} = $_->[1] foreach (values %$raw);
        return \%h;
    };

    Pinwheel::Context::reset();

    $headers = &$fn({}, undef);
    is_deeply($headers, {'Status' => 200, 'Content-Type' => 'text/html'});
    $headers = &$fn({}, 'xml');
    is_deeply($headers, {'Status' => 200, 'Content-Type' => 'application/xml'});
    $headers = &$fn({}, 'unknown');
    is_deeply($headers, {'Status' => 200, 'Content-Type' => 'text/html'});
    $headers = &$fn({status => 201}, undef);
    is_deeply($headers, {'Status' => 201, 'Content-Type' => 'text/html'});
    $headers = &$fn({content_type => 'text/xml'}, undef);
    is_deeply($headers, {'Status' => 200, 'Content-Type' => 'text/xml'});
    $headers = &$fn({location => '/a/b/c'}, undef);
    is($headers->{'Location'}, '/a/b/c');
    $headers = &$fn({}, 'xml');
    is_deeply($headers, {'Status' => 200, 'Content-Type' => 'application/xml'});
    $headers = &$fn({}, 'txt');
    is_deeply($headers, {'Status' => 200, 'Content-Type' => 'text/plain'});

    set_header('X-Test', 'Blah');
    $headers = &$fn({}, 'txt');
    is_deeply($headers, {
        'Status' => 200,
        'Content-Type' => 'text/plain',
        'X-Test' => 'Blah',
    });

    $fn = sub {
        my ($raw, %h);
        $raw = Pinwheel::Controller::_render_headers(@_);
        $h{$_->[0]} = $_->[1] foreach (values %$raw);
        return \%h;
    };

    Pinwheel::Context::reset();
    set_header('Content-Type', 'abc/xyz');
    $headers = &$fn({}, 'txt');
    is_deeply($headers, {'Status' => 200, 'Content-Type' => 'abc/xyz'});

    Pinwheel::Context::reset();
    set_header('Content-Type', 'abc/xyz');
    $headers = &$fn({content_type => 'x'}, 'txt');
    is_deeply($headers, {'Status' => 200, 'Content-Type' => 'x'});

    Pinwheel::Context::reset();
    set_header('Status', 123);
    $headers = &$fn({}, 'txt');
    is_deeply($headers, {'Status' => 123, 'Content-Type' => 'text/plain'});

    Pinwheel::Context::reset();
    set_header('Status', 123);
    $headers = &$fn({status => 321}, 'txt');
    is_deeply($headers, {'Status' => 321, 'Content-Type' => 'text/plain'});

    Pinwheel::Context::reset();
    set_header('Status', 123);
    set_header('sTATUS', 456);
    $headers = &$fn({}, 'txt');
    is_deeply($headers, {'sTATUS' => 456, 'Content-Type' => 'text/plain'});

    Pinwheel::Context::reset();
    set_header('Status', 123);
    set_header('sTATUS', 456);
    $headers = &$fn({status => 321}, 'txt');
    is_deeply($headers, {'Status' => 321, 'Content-Type' => 'text/plain'});
}

# URL parameters
{
    my $ctx;

    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    $ctx->{route} = {
        a => 'main',
        b => 'index',
        c => 'radio4',
        d => undef
    };

    is(Pinwheel::Controller::params('a'), 'main');
    is_deeply(Pinwheel::Controller::params(qw(a b c)), ['main', 'index', 'radio4']);
    is_deeply(Pinwheel::Controller::params(qw(c a)), ['radio4', 'main']);
    is_deeply(Pinwheel::Controller::params(qw(d b)), [undef, 'index']);
    is_deeply(Pinwheel::Controller::params(qw(d foo a)), [undef, undef, 'main']);
}

# Query parameters
{
    my ($ctx);

    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');

    $ctx->{request}{query} = '';
    is(Pinwheel::Controller::query_params('f'), undef);
    is_deeply($ctx->{query}, {});
    delete $ctx->{query};

    $ctx->{request}{query} = undef;
    is(Pinwheel::Controller::query_params('g'), undef);
    is_deeply($ctx->{query}, {});
    delete $ctx->{query};

    $ctx->{request}{query} = 'a=b=c+%26+d&x=&f';
    is(Pinwheel::Controller::query_params('a'), 'b=c & d');
    is(Pinwheel::Controller::query_params('x'), '');
    is(Pinwheel::Controller::query_params('f'), '');
    is_deeply($ctx->{query}, {a => 'b=c & d', x => '', f => ''});

    delete $ctx->{query};
    $ctx->{request}{query} = 'a+b%3dc=d+e%26f';
    is(Pinwheel::Controller::query_params('a b=c'), 'd e&f');
    is_deeply($ctx->{query}, {'a b=c' => 'd e&f'});

    delete $ctx->{query};
    $ctx->{request}{query} = 'a=1&b=2&c=3';
    is_deeply(Pinwheel::Controller::query_params('a', 'c', 'b'), [1, 3, 2]);
    is_deeply(Pinwheel::Controller::query_params('c', 'b', 'a'), [3, 2, 1]);
    is_deeply($ctx->{query}, {a => 1, b => 2, c => 3});

    delete $ctx->{query};
    my $warnings = 0;
    local $SIG{__WARN__} = sub { ++$warnings };
    $ctx->{request}{query} = 'a=1&&b=2';
    is_deeply(Pinwheel::Controller::query_params('a', 'b'), [1, 2]);
    is($warnings, 0);

    delete $ctx->{query};
    $warnings = 0;
    local $SIG{__WARN__} = sub { ++$warnings };
    $ctx->{request}{query} = '&a=1&b=2';
    is_deeply(Pinwheel::Controller::query_params('a', 'b'), [1, 2]);
    is($warnings, 0);
}

# Cache expiry times
{
    my ($render_headers, $ctx, $h);

    $render_headers = sub {
        my ($raw, %h);
        $raw = Pinwheel::Controller::_render_headers(@_);
        $h{$_->[0]} = $_->[1] foreach (values %$raw);
        return \%h;
    };

    Pinwheel::Context::reset();
    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    $ctx->{request}{time} = Pinwheel::Model::Time::local(2008, 1, 1)->timestamp;

    expires_in(10);
    $h = &$render_headers();
    is($h->{'Date'}, 'Tue, 01 Jan 2008 00:00:00 GMT');
    is($h->{'Expires'}, 'Tue, 01 Jan 2008 00:00:10 GMT');
    is($h->{'Cache-Control'}, 'max-age=10');

    expires_in(14 * 24 * 60 * 60);
    $h = &$render_headers();
    is($h->{'Date'}, 'Tue, 01 Jan 2008 00:00:00 GMT');
    is($h->{'Expires'}, 'Tue, 15 Jan 2008 00:00:00 GMT');
    is($h->{'Cache-Control'}, 'max-age=1209600');

    expires_at(Pinwheel::Model::Time::local(2008, 6, 1, 0, 0, 0));
    $h = &$render_headers();
    is($h->{'Date'}, 'Tue, 01 Jan 2008 00:00:00 GMT');
    is($h->{'Expires'}, 'Sat, 31 May 2008 23:00:00 GMT');
    is($h->{'Cache-Control'}, 'max-age=13129200');

    expires_now();
    $h = &$render_headers();
    is($h->{'Cache-Control'}, 'no-cache');
    is($h->{'Pragma'}, 'no-cache');
}

# Error rendering functions
{
    my ($ctx, $renderctx);

    Pinwheel::Context::reset();
    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    $ctx->{route} = {controller => 'foo', action => 'bar'};
    $ctx->{controller} = Pinwheel::Controller::_get_controller('number_one');
    $renderctx = Pinwheel::Context::get('render');
    $renderctx->{format} = ['html'];

    $ctx->{headers} = $ctx->{response} = undef;
    $ctx->{rendering} = 0;
    Pinwheel::Controller::render_404('x');
    is($ctx->{headers}{'status'}[1], 404);
    like($ctx->{content}, qr/^a:4:x\s*$/);
    Pinwheel::Controller::render_404('overwrite');
    like($ctx->{content}, qr/^a:4:overwrite\s*$/);

    $ctx->{headers} = $ctx->{response} = undef;
    $ctx->{rendering} = 0;
    Pinwheel::Controller::render_500('x');
    is($ctx->{headers}{'status'}[1], 500);
    like($ctx->{content}, qr/^a:5:x\s*$/);
    Pinwheel::Controller::render_500('overwrite');
    like($ctx->{content}, qr/^a:5:overwrite\s*$/);

    $ctx->{headers} = $ctx->{response} = undef;
    $ctx->{rendering} = 0;
    Pinwheel::Controller::render_error(403, 'x');
    is($ctx->{headers}{'status'}[1], 403);
    like($ctx->{content}, qr/^x\s*$/);
    Pinwheel::Controller::render_error(403, 'overwrite');
    like($ctx->{content}, qr/^overwrite\s*$/);

    $ctx->{headers} = $ctx->{response} = undef;
    $ctx->{rendering} = 0;
    Pinwheel::Controller::render_error(499, 'x');
    is($ctx->{headers}{'status'}[1], 500);
    is($ctx->{headers}{'content-type'}[1], 'text/html');
    like($ctx->{content}, qr/unknown function .*error499\.html/i);

    $ctx->{headers} = $ctx->{response} = undef;
    $ctx->{rendering} = 0;
    $renderctx->{format} = ['boom'];
    Pinwheel::Controller::render_500('x');
    is($ctx->{headers}{'status'}[1], 500);
    is($ctx->{headers}{'content-type'}[1], 'text/plain');
    like($ctx->{content}, qr/unknown function .*error500\.boom/i);
}

# Top-level render functions
{
    my ($ctx, $renderctx, $s);

    Pinwheel::Context::reset();
    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    $ctx->{controller} = Pinwheel::Controller::_get_controller('number_one');
    $ctx->{route} = { controller => 'text' };
    $renderctx = Pinwheel::Context::get('render');
    $renderctx->{format} = ['txt'];

    $s = Pinwheel::Controller::render_to_string(template => 'text/hello');
    like($s, qr/^hello\s*$/);
    $s = Pinwheel::Controller::render_to_string(template => 'text/nest');
    like($s, qr/^nest:t:nested\s*$/);
    ok(!defined($ctx->{headers}));

    $ctx->{headers} = 1;
    $s = Pinwheel::Controller::render_to_string(template => 'text/hello');
    like($s, qr/^hello\s*$/);
    $ctx->{headers} = 1;
    is(Pinwheel::Controller::render(template => 'text/hello'), undef);

    $ctx->{headers} = undef;
    like(Pinwheel::Controller::render(template => 'text/hello'), qr/^hello\s*$/);
    $ctx->{headers} = undef;
    like(Pinwheel::Controller::render(template => 'text/nest'), qr/^nest:t:nested\s*$/);
}

# Accepts
{
    my ($status, $render_error, $accepts, $ctx);

    $render_error = \&Pinwheel::Controller::render_error;
    {
        no warnings 'redefine';
        *Pinwheel::Controller::render_error = sub { $status = $_[0] };
    }
    $accepts = sub { $status = undef; Pinwheel::Controller::accepts(@_) };

    Pinwheel::Context::reset();
    Pinwheel::Context::set('*Pinwheel::Controller',
        route => {
            format => 'html',
            representation => 'xhtml',
        }
    );
    $ctx = Pinwheel::Context::get('render');
    $ctx->{format} = ['foo'];

    ok(&$accepts('html'));
    is($status, undef);
    is(Pinwheel::Controller::format(), 'html');
    ok(!&$accepts('rss'));
    is($status, 404);

    Pinwheel::Controller::set_format_param('representation');
    ok(!&$accepts('html'));
    is($status, 404);
    ok(&$accepts('html', 'xhtml'));
    is($status, undef);
    is(Pinwheel::Controller::format(), 'xhtml');

    Pinwheel::Controller::set_base_format('foo');
    Pinwheel::Controller::set_format_param('blah');
    ok(&$accepts('foo'));
    ok(!&$accepts('html'));
    Pinwheel::Controller::set_format_param('format');

    Pinwheel::Controller::set_base_format('foo');
    ok(&$accepts('rss', 'atom', 'html'));
    is($status, undef);
    is(Pinwheel::Controller::format(), 'html');
    push @{$ctx->{format}}, 'x';
    ok(&$accepts('html'));
    is($status, undef);
    is(Pinwheel::Controller::format(), 'x');

    {
        no warnings 'redefine';
        *Pinwheel::Controller::render_error = $render_error;
    }
}

# Responds to
{
    my (@formats, @args, $respond_to, $render_fn, $render_error_fn);

    $respond_to = sub {
        Pinwheel::Context::set('*Pinwheel::Controller', route => {format => shift});
        Pinwheel::Controller::respond_to(@_);
    };
    $render_fn = \&Pinwheel::Controller::render;
    $render_error_fn = \&Pinwheel::Controller::render_error;
    {
        no warnings 'redefine';
        *Pinwheel::Controller::render = sub { @args = ('render', @_) };
        *Pinwheel::Controller::render_error = sub { @args = ('error', @_) };
    }
    Pinwheel::Context::set('render', format => ['html']);

    @formats = (
        'html',
        'json' => sub { @args = @{Pinwheel::Context::get('render')->{format}} },
        'xml',
    );

    Pinwheel::Context::reset();
    &$respond_to('html', @formats);
    is_deeply(\@args, ['render', 'format', 'html']);

    Pinwheel::Context::reset();
    Pinwheel::Context::set('render', format => ['html']);
    &$respond_to(undef, @formats);
    is_deeply(\@args, ['render', 'format', 'html']);

    Pinwheel::Context::reset();
    &$respond_to('json', @formats);
    is_deeply(\@args, ['json']);

    Pinwheel::Context::reset();
    &$respond_to('xml', @formats);
    is_deeply(\@args, ['render', 'format', 'xml']);

    Pinwheel::Context::reset();
    &$respond_to('blah', @formats);
    is_deeply([@args[0, 1]], ['error', 404]);

    Pinwheel::Context::reset();
    Pinwheel::Context::set('*Pinwheel::Controller', route => {blah => 'foo'});
    Pinwheel::Controller::set_format_param('blah');
    Pinwheel::Controller::respond_to('foo');
    is_deeply(\@args, ['render', 'format', 'foo']);
    Pinwheel::Controller::set_format_param('format');

    {
        no warnings 'redefine';
        *Pinwheel::Controller::render = $render_fn;
        *Pinwheel::Controller::render_error = $render_error_fn;
    }
}

# Render format
{
    my ($ctx);

    Pinwheel::Context::reset();
    $ctx = Pinwheel::Context::get('render');

    $ctx->{format} = ['html'];
    is(Pinwheel::Controller::format(), 'html');

    $ctx->{format} = ['html', 'xml'];
    is(Pinwheel::Controller::format(), 'xml');
}

# Redirects
{
    my ($ctx, $hdr, @url);

    Pinwheel::Context::reset();
    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    $ctx->{request} = {
        host => 'www.bbc.co.uk',
        path => '/radio4/p/today',
        base => '/~paulc'
    };
    $hdr = sub { $ctx->{headers}{$_[0]}[1] };

    $Pinwheel::Controller::map->reset();
    Pinwheel::Controller::connect('r', '/:network/p/:brand');
    Pinwheel::Controller::connect('fixed', '/fixed_url');
    @url = ('r', network => 'r0', brand => 'foo');

    delete $ctx->{headers};
    Pinwheel::Controller::redirect_to(@url);
    is(&$hdr('status'), 302);
    is(&$hdr('location'), Pinwheel::Controller::url_for(@url, only_path => 0));

    delete $ctx->{headers};
    Pinwheel::Controller::redirect_to('fixed');
    is(&$hdr('status'), 302);
    is(&$hdr('location'), 'http://www.bbc.co.uk/~paulc/fixed_url');

    delete $ctx->{headers};
    Pinwheel::Controller::redirect_to('fixed', status => 303);
    is(&$hdr('status'), 303);
    is(&$hdr('location'), 'http://www.bbc.co.uk/~paulc/fixed_url');
    
    delete $ctx->{headers};
    Pinwheel::Controller::redirect_to(undef, network => 'r8', brand => 'bar' );
    is(&$hdr('status'), 302);
    is(&$hdr('location'), 'http://www.bbc.co.uk/~paulc/r8/p/bar');

    delete $ctx->{headers};
    Pinwheel::Controller::redirect_to('/foo');
    is(&$hdr('status'), 302);
    is(&$hdr('location'), 'http://www.bbc.co.uk/foo');

    delete $ctx->{headers};
    Pinwheel::Controller::redirect_to('/foo', undef);
    is(&$hdr('status'), 302);
    is(&$hdr('location'), 'http://www.bbc.co.uk/foo');

    delete $ctx->{headers};
    Pinwheel::Controller::redirect_to('http://foo.com/bar');
    is(&$hdr('status'), 302);
    is(&$hdr('location'), 'http://foo.com/bar');

    delete $ctx->{headers};
    Pinwheel::Controller::redirect_to('http://foo.com/bar', status => 302);
    is(&$hdr('status'), 302);
    is(&$hdr('location'), 'http://foo.com/bar');

    delete $ctx->{headers};
    Pinwheel::Controller::redirect_to('http://foo.com/bar', status => 303);
    is(&$hdr('status'), 303);
    is(&$hdr('location'), 'http://foo.com/bar');
}

# Dispatch
{
    my ($ctx, $renderctx, $request, $i, $headers, $content);

    Pinwheel::Context::reset();
    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    $request = {
        host => 'www.bbc.co.uk',
        path => '/radio4/p/today',
        base => '/~paulc'
    };
    $ctx->{request} = $request;
    $renderctx = Pinwheel::Context::get('render');
    $renderctx->{format} = ['html'];
    $Pinwheel::Controller::map->reset();
    Pinwheel::Controller::connect('/bad_controller', controller => '$foo');
    Pinwheel::Controller::connect('/bad_action', action => '$bar');
    Pinwheel::Controller::connect('/missing_controller', controller => 'missing');
    Pinwheel::Controller::connect('/missing_action', controller => 'two', action => 'x');
    Pinwheel::Controller::connect('/ping', controller => 'two', action => 'ping');
    Pinwheel::Controller::connect('/show', controller => 'two', action => 'show');
    Pinwheel::Controller::connect('/error', controller => 'two', action => 'error');
    Pinwheel::Controller::connect('/badt', controller => 'two', action => 'bad_template');
    Pinwheel::Controller::connect('/getping',
        controller => 'two', action => 'ping',
        conditions => {method => 'GET'},
    );

    $request->{path} = '/bad_controller';
    Pinwheel::Controller::_process_request({}, $ctx);
    is($ctx->{headers}{'status'}[1], 404);

    $ctx->{headers} = $ctx->{response} = undef;
    $request->{path} = '/bad_action';
    Pinwheel::Controller::_process_request({}, $ctx);
    is($ctx->{headers}{'status'}[1], 404);

    $ctx->{headers} = $ctx->{response} = undef;
    $request->{path} = '/missing_controller';
    Pinwheel::Controller::_process_request({}, $ctx);
    is($ctx->{headers}{'status'}[1], 404);

    $ctx->{headers} = $ctx->{response} = undef;
    $request->{path} = '/missing_action';
    Pinwheel::Controller::_process_request({}, $ctx);
    is($ctx->{headers}{'status'}[1], 404);

    $ctx->{headers} = $ctx->{response} = undef;
    $request->{path} = '/ping';
    Pinwheel::Controller::_process_request({}, $ctx);
    is($ctx->{headers}, undef);
    Pinwheel::Controller::render();
    is($ctx->{headers}{'status'}[1], 200);
    is($ctx->{headers}{'content-type'}[1], 'text/html');
    like($ctx->{content}, qr/^a:pong\s*$/);

    $ctx->{headers} = $ctx->{response} = undef;
    $request->{path} = '/ping';
    Pinwheel::Controller::_process_request({}, $ctx);
    is($ctx->{headers}, undef);
    Pinwheel::Controller::render(format => 'txt');
    is($ctx->{headers}{'status'}[1], 200);
    is($ctx->{headers}{'content-type'}[1], 'text/plain');
    like($ctx->{content}, qr/^txtpong\s*$/);

    $request->{path} = '/ping';
    ($headers, $content) = Pinwheel::Controller::dispatch($request);
    is($headers->{'status'}[1], 200);
    like($content, qr/^a:pong\s*$/s);

    $request->{path} = '/show';
    ($headers, $content) = Pinwheel::Controller::dispatch($request);
    is($headers->{'status'}[1], 200);
    like($content, qr/^a:pong\s*$/s);

    $request->{path} = '/error';
    ($headers, $content) = Pinwheel::Controller::dispatch($request);
    is($headers->{'status'}[1], 500);

    $request->{path} = '/badt';
    ($headers, $content) = Pinwheel::Controller::dispatch($request);
    is($headers->{'status'}[1], 500);

    $request->{method} = 'POST';
    $request->{path} = '/getping';
    ($headers, $content) = Pinwheel::Controller::dispatch($request);
    is($headers->{'status'}[1], 404);

    $request->{method} = 'GET';
    $request->{path} = '/getping';
    ($headers, $content) = Pinwheel::Controller::dispatch($request);
    is($headers->{'status'}[1], 200);
    like($content, qr/^a:pong\s*$/s);
}

# Hooks
{
    my ($hooks, $request, $ctx);

    $hooks = \%Config::Hooks::;
    $request = {
        host => 'www.bbc.co.uk',
        path => '/ping',
        base => '/~paulc'
    };
    $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    $ctx->{request} = $request;

    $hooks->{before_dispatch} = \&Config::Hooks::_before_dispatch;
    Pinwheel::Controller::dispatch($request);
    is_deeply(\@Config::Hooks::log, [['before_dispatch', $request]]);
    delete $hooks->{before_dispatch};
    @Config::Hooks::log = ();
    Pinwheel::Controller::dispatch($request);
    is_deeply(\@Config::Hooks::log, []);

    $hooks->{after_dispatch} = \&Config::Hooks::_after_dispatch;
    Pinwheel::Controller::dispatch($request);
    is($Config::Hooks::log[0][0], 'after_dispatch');
    is_deeply($Config::Hooks::log[0][1]{status}, ['Status', 200]);
    like(${$Config::Hooks::log[0][2]}, qr/pong/);
    @Config::Hooks::log = ();
    Pinwheel::Controller::dispatch({%$request, path => '/error'});
    is_deeply(\@Config::Hooks::log, []);
    delete $hooks->{after_dispatch};
    @Config::Hooks::log = ();
    Pinwheel::Controller::dispatch($request);
    is_deeply(\@Config::Hooks::log, []);

    $hooks->{initialise} = \&Config::Hooks::_initialise;
    Pinwheel::Controller::initialise();
    is_deeply(\@Config::Hooks::log, ['initialise']);
    delete $hooks->{initialise};
    @Config::Hooks::log = ();
    Pinwheel::Controller::_process_request({}, $ctx);
    is_deeply(\@Config::Hooks::log, []);
}

# Static paths
{
    my $fn = \&Pinwheel::Controller::expand_static_path;

    Pinwheel::Context::reset();
    Pinwheel::Controller::set_static_root('/some/where');

    is(&$fn('x'), '/some/where/x');
    is(&$fn('/x'), '/some/where/x');
    is(&$fn('//x'), '/some/where/x');

    is(&$fn('../x'), undef);
    is(&$fn('/../x'), undef);
    is(&$fn('/.x'), undef);
    is(&$fn('/x/..'), undef);
    is(&$fn('/x/../y'), undef);

    is(&$fn('x/y/z'), '/some/where/x/y/z');
    is(&$fn('x///y///z'), '/some/where/x/y/z');

    Pinwheel::Context::set('*Pinwheel::Controller', request => {base => '/foo'});

    is(&$fn('foo/x'), '/some/where/x');
    is(&$fn('/foo/x'), '/some/where/x');
    is(&$fn('/x'), '/some/where/x');
}

# Error logger
{
    my @e;
    local $Pinwheel::Controller::error_logger = sub { push @e, [@_] };

    Pinwheel::Context::reset();
    my $ctx = Pinwheel::Context::get('*Pinwheel::Controller');
    my $request = {
        host => 'www.bbc.co.uk',
        path => undef,
        base => '/~paulc'
    };
    $ctx->{request} = $request;
    my $renderctx = Pinwheel::Context::get('render');
    $renderctx->{format} = ['html'];
    $Pinwheel::Controller::map->reset();

    Pinwheel::Controller::connect('/bad_controller', controller => '$foo');
    Pinwheel::Controller::connect('/ping', controller => 'two', action => 'ping');
    Pinwheel::Controller::connect('/error', controller => 'two', action => 'error');

    @e = ();
    Pinwheel::Controller::dispatch({%$request, path => '/ping'});
    is(0+@e, 0, 'successful requests do not call the error_logger');

    @e = ();
    Pinwheel::Controller::dispatch({%$request, path => '/no_such_route'});
    is(0+@e, 1, '404 generates 1 error');
    is($e[0][0], 404, '404 calls error_logger with status=404');
    is($e[0][2], 0, '404 calls error_logger with depth=0');

    @e = ();
    Pinwheel::Controller::dispatch({%$request, path => '/error'});
    is(0+@e, 1, '500 generates 1 error');
    is($e[0][0], 500, '500 calls error_logger with status=404');
    is($e[0][2], 1, '500 calls error_logger with depth=1');

    local $Pinwheel::Controller::error_logger = \&Pinwheel::Controller::default_error_logger;
    my @msg;
    my $real_cluck = \&Carp::cluck;
    my $my_cluck = sub { push @msg, $_[0] };
    { no warnings 'redefine'; *Carp::cluck = $my_cluck; }

    # The default logger should do nothing on 404, 406 etc
    @msg = ();
    Pinwheel::Controller::dispatch({%$request, path => '/no_such_route'});
    is(0+@msg, 0, 'the default logger should do nothing on 404, 406 etc');

    # The default logger should call Carp::cluck with a sensible message on 500
    @msg = ();
    Pinwheel::Controller::dispatch({%$request, path => '/error'});
    is(0+@msg, 1, 'the default logger call Carp::cluck for 500 errors');

    { no warnings 'redefine'; *Carp::cluck = $real_cluck; }
}

# request_time
{
    my ($headers, $content);
    my $request;

    my $inner_request_time;
    my $inner_request_time_model;

    {
        package Controllers::RT;
        our @ACTIONS = qw( show );
        sub show {
            my $t0 = time;
            sleep 1 until time() > $t0;
            $inner_request_time = Pinwheel::Controller::request_time();
            $inner_request_time_model = Pinwheel::Controller::request_time_model();
            Pinwheel::Controller::render(text => "");
        }
    }

    $Pinwheel::Controller::map->reset();
    Pinwheel::Controller::connect('/request_time', controller=> 'r_t', action => 'show');

    my $run_test = sub {
        my ($t) = @_;

        $request = {
            host => 'localhost',
            path => '/request_time',
            time => $t,
        };

        my $now = time;
        $inner_request_time = 'x';
        ($headers, $content) = Pinwheel::Controller::dispatch($request);

        if ($t)
        {
            is($inner_request_time, $t);
            is($inner_request_time_model->timestamp, $t);
        } else {
            # dispatch defaults time to now
            my $now2 = $now + 1; # iffy race condition avoidance
            like($inner_request_time, qr/^($now|$now2)$/);
            is($inner_request_time_model->timestamp, $inner_request_time);
        }
    };

    &$run_test(time());
    &$run_test(time()+100);
    &$run_test(time()-100);
    # dispatch defaults time to now
    &$run_test(0);
    &$run_test(undef);
}

{
    print "# EXPORT tests\n";

    eval 'package SomeFoo; use Pinwheel::Controller; 1';
    die $@ if $@;

    my @by_default = qw(
        url_for
        redirect_to
        render
        render_to_string
        render_404
        render_500
        set_header
        expires_in
        expires_at
        expires_now
        accepts
        respond_to
        params
        query_params
    );

    my @subs;
    my $stash = \%SomeFoo::;
    while (my ($name, $glob) = each %$stash)
    {
        defined &$glob or next;
        push @subs, $name;
    }

    is(
        join(" ", sort @subs),
        join(" ", sort @by_default),
        'default export list'
    );

    eval 'package SomeFoo; use Pinwheel::Controller qw(
        connect
        dispatch
        format
        set_base_format
        set_format_param
        expand_static_path
        set_static_root
        set_templates_root
        request_time
        request_time_model
    )';
    is($@, '', 'additional exports');
}
