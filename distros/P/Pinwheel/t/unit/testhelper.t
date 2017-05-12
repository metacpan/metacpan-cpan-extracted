#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 99;

BEGIN {
    $INC{'Config/Routes.pm'} = 'Config/Routes.pm';
    $INC{'Config/Templates.pm'} = 'Config/Templates.pm';
    $INC{'Config/Database.pm'} = 'Config/Database.pm';
}

use Pinwheel::TestHelper;
use Pinwheel::DocTest;


{
    print "# localise_test_state\n";

    my $n;
    no warnings 'redefine';
    my @g;
    local *Pinwheel::Controller::dispatch = sub { return @g };

    set_time(Pinwheel::Model::Time::local(2007, 1, 2, 12, 30, 45));
    @g = ({Status => ["Status", 200]}, '<a><b>Hello</b><b id="x">World</b></a>');
    get("dummy");

    is(Pinwheel::Model::Time::now->iso8601, '2007-01-02T12:30:45Z');
    is_content('b', count => 2);
    is_response('success');

    localise_test_state {
        is(Pinwheel::Model::Time::now->iso8601, '2007-01-02T12:30:45Z');
        is_content('b', count => 2, name => "same context on entry");
        is_response('success');

        set_time(Pinwheel::Model::Time::local(2009, 7, 7, 00, 12, 44));
        @g = ({Status => ["Status", 404]}, "<b>A<em>different</em>document</b>");
        get("dummy");

        is(Pinwheel::Model::Time::now->iso8601, '2009-07-07T00:12:44+01:00');
        is_content('b', count => 1, name => "different content inside block");
        is_response('missing');
    };

    is(Pinwheel::Model::Time::now->iso8601, '2007-01-02T12:30:45Z');
    is_content('b', count => 2, name => "content restored on exit");
    is_response('success');

    # TODO no test for localisation of $template / $content
}
our $mock_test = Pinwheel::DocTest::Mock->new('Test::Builder');
our $mock_url_for = Pinwheel::DocTest::Mock->new('url_for');
our $mock_dispatch = Pinwheel::DocTest::Mock->new('Pinwheel::Controller::dispatch');
our $mock_map = Pinwheel::DocTest::Mock->new('Pinwheel::Controller::map');
our $mock_make_template_name = Pinwheel::DocTest::Mock->new('make_template_name');
{
    $mock_dispatch->returns(sub { return ({x => ['X', 'Y']}, 'P') });
    no warnings 'redefine';
    *Pinwheel::TestHelper::_get_test_builder = sub { $mock_test };
    *Pinwheel::TestHelper::url_for = \&$mock_url_for;
    *Pinwheel::Controller::dispatch = \&$mock_dispatch;
    $Pinwheel::Controller::map = $mock_map;
    *Pinwheel::TestHelper::real_date_now = \&{Pinwheel::DocTest::Mock->new('Pinwheel::Model::Date::now')};
    *Pinwheel::TestHelper::real_time_now = \&{Pinwheel::DocTest::Mock->new('Pinwheel::Model::Time::now')};
    *Pinwheel::TestHelper::real_make_template_name = \&$mock_make_template_name;
    *Pinwheel::TestHelper::real_render = \&{Pinwheel::DocTest::Mock->new('render')};
}


=begin doctest

Get a URL

  >>> [get('/radio4/programmes')]
  Called Pinwheel::Controller::dispatch with [{"base" => "","host" => "127.0.0.1","method" => "GET","path" => "/radio4/programmes","query" => "","time" => ...}]
  [{"X" => "Y"},"P"]

  >>> [get('/radio4/programmes?x=y')]
  Called Pinwheel::Controller::dispatch with [{"base" => "","host" => "127.0.0.1","method" => "GET","path" => "/radio4/programmes","query" => "x=y","time" => ...}]
  [{"X" => "Y"},"P"]

Select part of the response HTML

  >>> $Pinwheel::TestHelper::content = '<a><b>Hello</b><b id="x">World</b></a>'
  >>> content('a')
  ["HelloWorld"]
  >>> content('b')
  ["Hello","World"]
  >>> content('b#?', 'x')
  ["World"]
  >>> content('x')
  []

=cut


=begin doctest

Check HTTP status code

  >>> $Pinwheel::TestHelper::headers = {'Status' => 999}
  >>> is_response('success')
  Called Test::Builder->is_num with [999,200,...]
  undef
  >>> is_response('redirect')
  Called Test::Builder->like with [999,qr/(?-xism:^3\d\d$)/,...]
  undef
  >>> is_response('missing')
  Called Test::Builder->is_num with [999,404,...]
  undef
  >>> is_response('error')
  Called Test::Builder->like with [999,qr/(?-xism:^5\d\d$)/,...]
  undef
  >>> is_response(100)
  Called Test::Builder->is_num with [999,100,...]
  undef

Get template name

  >>> $Pinwheel::TestHelper::template = 'abc'
  >>> is_template('xyz')
  Called Test::Builder->is_eq with ["abc","xyz",...]
  undef
  >>> get_template_name()
  "abc"

Get redirection target

  >>> $Pinwheel::TestHelper::headers = {'Location' => 'foo'}
  >>> $mock_url_for->returns('bar');
  undef
  >>> is_redirected_to('/bar')
  Called Test::Builder->is_eq with ["foo","http://127.0.0.1/bar",...]
  undef
  >>> is_redirected_to('http://foo.com')
  Called Test::Builder->is_eq with ["foo","http://foo.com",...]
  undef
  >>> is_redirected_to('bar')
  Called url_for with ["bar","only_path",0]
  Called Test::Builder->is_eq with ["foo","bar",...]
  undef
  >>> is_redirected_to('bar', x => 'y')
  Called url_for with ["bar","x","y","only_path",0]
  Called Test::Builder->is_eq with ["foo","bar",...]
  undef

  >>> $Pinwheel::TestHelper::headers = {'Location' => 'foo', 'Status' => 303}
  >>> $mock_url_for->returns('foo')
  undef
  >>> is_redirected_to('foo')
  Called url_for with ["foo","only_path",0]
  Called Test::Builder->like with [303,qr/(?-xism:^3\d\d$)/,...]
  undef

=cut


=begin doctest

Count nodes in selected output

  >>> $Pinwheel::TestHelper::content = '<a><b>Hello</b><b id="x">World</b></a>'
  >>> is_content('a', count => 0)
  Called Test::Builder->ok with [0,...]
  Called Test::Builder->diag with ["    found 1 nodes, expected 0"]
  undef
  >>> is_content('a', count => 1)
  Called Test::Builder->ok with [1,...]
  undef
  >>> is_content('a', count => 2)
  Called Test::Builder->ok with [0,...]
  Called Test::Builder->diag with ["    found 1 nodes, expected 2"]
  undef
  >>> is_content('a', minimum => 1)
  Called Test::Builder->ok with [1,...]
  undef
  >>> is_content('a', minimum => 2)
  Called Test::Builder->ok with [0,...]
  Called Test::Builder->diag with ["    found 1 nodes, expected at least 2"]
  undef
  >>> is_content('a', maximum => 1)
  Called Test::Builder->ok with [1,...]
  undef
  >>> is_content('a', maximum => 0)
  Called Test::Builder->ok with [0,...]
  Called Test::Builder->diag with ["    found 1 nodes, expected at most 0"]
  undef
  >>> is_content('x')
  Called Test::Builder->ok with [0,...]
  Called Test::Builder->diag with ["    found 0 nodes, expected at least 1"]
  undef

Compare string values in selected output

  >>> $Pinwheel::TestHelper::content = '<a><b>Hello</b><b id="x">World</b></a>'
  >>> is_content('b', ['Hello', 'World'])
  Called Test::Builder->ok with [1,...]
  undef
  >>> is_content('b#x', 'blah')
  Called Test::Builder->is_eq with ["World","blah",...]
  undef
  >>> is_content('b', ['Hello', 'World'])
  Called Test::Builder->ok with [1,...]
  undef
  >>> is_content('b#x', qr/world/i)
  Called Test::Builder->ok with [1,...]
  undef
  >>> is_content('b#x', qr/blah/)
  Called Test::Builder->like with ["World",qr/(?-xism:blah)/,...]
  undef
  >>> is_content('b', [qr/hello/i, qr/world/i])
  Called Test::Builder->ok with [1,...]
  undef
  >>> is_content('b', [qr/x/, qr/y/])
  Called Test::Builder->like with ["Hello",qr/(?-xism:x)/,...]
  undef
  >>> is_content('c', 'foo')
  Called Test::Builder->ok with [0,...]
  Called Test::Builder->diag with ["    found 0 nodes, expected 1"]
  undef
  >>> is_content('c', ['foo', 'bar'])
  Called Test::Builder->ok with [0,...]
  Called Test::Builder->diag with ["    found 0 nodes, expected 2"]
  undef

Specifying test name in is_content

  >>> is_content('//*', min => 1, name => "Test name here")
  Called Test::Builder->ok with [1,"Test name here"]
  undef

=cut


=begin doctest

Confirm that the expected URL is generated

  >>> is_generated('/foo', {something => 'else'})
  Called Pinwheel::Controller::map->generate with ["something","else"]
  Called Test::Builder->is_eq with [undef,"/foo",...]
  undef

Confirm that the URL is broken down as expected

  >>> $mock_map->match_returns({})
  undef
  >>> is_recognised({a => 'b'}, '/foo')
  Called Pinwheel::Controller::map->match with ["/foo"]
  Called Test::Builder->ok with [0,...]
  Called Test::Builder->diag with ["    missing key 'a' in match params"]
  undef
  >>> $mock_map->match_returns({a => 'x'})
  undef
  >>> is_recognised({a => 'b'}, '/foo')
  Called Pinwheel::Controller::map->match with ["/foo"]
  Called Test::Builder->ok with [0,...]
  Called Test::Builder->diag with ["    key 'a' differs: 'x' vs 'b'"]
  undef
  >>> $mock_map->match_returns({a => 'b'})
  undef
  >>> is_recognised({a => 'b'}, '/foo')
  Called Pinwheel::Controller::map->match with ["/foo"]
  Called Test::Builder->ok with [1,...]
  undef

Combined URL matching and generation

  >>> $mock_map->match_returns({a => 'b'})
  undef
  >>> $mock_map->generate_returns('/foo')
  undef
  >>> is_route('/foo', {a => 'b'})
  Called Pinwheel::Controller::map->generate with ["a","b"]
  Called Pinwheel::Controller::map->match with ["/foo"]
  Called Test::Builder->ok with [1,...]
  undef
  >>> $mock_map->generate_returns('/bar')
  undef
  >>> is_route('/foo', {a => 'b'})
  Called Pinwheel::Controller::map->generate with ["a","b"]
  Called Test::Builder->is_eq with ["/bar","/foo",...]
  undef

=cut


=begin doctest

Modify time

  >>> $t = Pinwheel::Model::Time::local(2007, 1, 2, 12, 30, 45)
  >>> set_time($t)
  bless( ... 'Pinwheel::Model::Time' )
  >>> Pinwheel::Model::Time::now->iso8601
  "2007-01-02T12:30:45Z"
  >>> Pinwheel::Model::Date::now->iso8601
  "2007-01-02"
  >>> set_time(undef)
  undef
  >>> Pinwheel::Model::Date::now
  Called Pinwheel::Model::Date::now with [...]
  undef
  >>> Pinwheel::Model::Time::now
  Called Pinwheel::Model::Time::now with [...]
  undef

Replace currently active render format

  >>> Pinwheel::Context::reset()
  ...
  >>> set_format('xhtmlmp')
  "html"
  >>> set_format('txt')
  "xhtmlmp"
  >>> Pinwheel::Context::set('render', format => ['foo', 'bar'])
  ...
  >>> set_format('html')
  "bar"
  >>> Pinwheel::Context::get('render')->{format}
  ["foo","html"]
  >>> Pinwheel::Context::set('render', format => [])
  ...
  >>> set_format('json')
  "html"

Capture template name

  >>> Pinwheel::Context::set('*Pinwheel::Controller', rendering => 2)
  ...
  >>> $Pinwheel::TestHelper::template = 'x'
  >>> $mock_make_template_name->returns('blah')
  undef
  >>> Pinwheel::TestHelper::test_make_template_name('foo')
  Called make_template_name with ["foo"]
  "blah"
  >>> $Pinwheel::TestHelper::template
  "x"
  >>> Pinwheel::Context::set('*Pinwheel::Controller', rendering => 1)
  ...
  >>> Pinwheel::TestHelper::test_make_template_name('foo')
  Called make_template_name with ["foo"]
  "blah"
  >>> $Pinwheel::TestHelper::template
  "blah"

=cut


Pinwheel::DocTest::test_file(__FILE__);

{
    print "# get() sets time using set_time, if set\n";
    no warnings 'redefine';
    my $passed_time;
    my $real_dispatch = \&Pinwheel::Controller::dispatch;

    *Pinwheel::Controller::dispatch = sub {
        $passed_time = $_[0]{time};
        return({}, "");
    };

    set_time(undef);
    $passed_time = 'x';
    get('dummy');
    is($passed_time, undef);

    set_time(Pinwheel::Model::Time->new(1227697217));
    $passed_time = 'x';
    get('dummy');
    is($passed_time, 1227697217);

    *Pinwheel::Controller::dispatch = $real_dispatch;
}

{
    print "# find_nodes\n";

    $Pinwheel::TestHelper::content = '<a><b>Hello</b><b id="x">World</b></a>';
    my $n;

    $n = find_nodes('//b');
    is(0+@$n, 2);
    is($n->[0]->getAttribute("id"), undef);
    is($n->[1]->getAttribute("id"), "x");

    $n = find_nodes('//b[@id="x"]');
    is(0+@$n, 1);
    is($n->[0]->nodeName, "b");
}

