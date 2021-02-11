#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Test::Output;

use Mojolicious::Lite;
use Mojo::ByteStream 'b';

my $t = Test::Mojo->new;
my $app = $t->app;

$app->plugin('Util::Endpoint');

my ($level, $msg);

$app->log->handle(*STDOUT);

$app->log->on(
  message => sub {
    (my $l2, $level, $msg) = @_;
  });

my $endpoint_host = 'endpoi.nt';

# Set endpoint
my $r_test = $app->routes->any('/test');
$r_test->endpoint(
  'test1' =>
    {
      host   => $endpoint_host,
      scheme => 'https'
    });

$r_test->any('/fun')->name('fun');


# Test redefinition
my $lev = $app->log->level;
$app->log->level('debug');
ok($app->routes->any('/nothing')->endpoint('test1'), 'Route is returned');
is($msg, 'Route endpoint "test1" already defined', 'Log level correct');
$app->log->level($lev);

is($app->endpoint('test1'),
   "https://$endpoint_host/test",
   'endpoint 1');

$r_test->endpoint(test2 => {
    host => $endpoint_host,
    scheme => 'https',
    query => [ a => '{var1}'] });

is($app->endpoint('test2'),
   'https://'.$endpoint_host.'/test?a={var1}',
   'endpoint 2');

is($app->endpoint('test2', {var1 => 'b'}),
   'https://'.$endpoint_host.'/test?a=b',
   'endpoint 3');

$r_test->endpoint(test3 => {
  host => $endpoint_host,
  query => [ a => '{var1}',
	     b => '{var2}'
	   ]});

is($app->endpoint('test3', {var1 => 'b'}),
   'http://'.$endpoint_host.'/test?a=b&b={var2}',
   'endpoint 4');

is($app->endpoint('test3', {var2 => 'd'}),
   'http://'.$endpoint_host.'/test?a={var1}&b=d',
   'endpoint 5');

is($app->endpoint('test3', {var1 => 'c', var2 => 'd'}),
   'http://'.$endpoint_host.'/test?a=c&b=d',
   'endpoint 6');


$app->routes->any('/define')->endpoint('testport' => {
  port => '6666',
  host   => $endpoint_host,
});

is($app->endpoint('testport'),
   "http://endpoi.nt:6666/define",
   'endpoint 1');

$r_test = $app->routes->any('/suggest');
$r_test->endpoint(test4 => {
		      host => $endpoint_host,
		      query => [ q => '{searchTerms}',
		                 start => '{startIndex?}'
			  ]});

is($app->endpoint('test4'),
   'http://'.$endpoint_host.'/suggest?q={searchTerms}&start={startIndex?}',
   'endpoint 7');

is($app->endpoint('test4' => { searchTerms => 'simpsons'}),
   'http://'.$endpoint_host.'/suggest?q=simpsons&start={startIndex?}',
   'endpoint 8');

is($app->endpoint('test4' => { startIndex => 4}),
   'http://'.$endpoint_host.'/suggest?q={searchTerms}&start=4',
   'endpoint 9');

is($app->endpoint('test4' => {
                     searchTerms => 'simpsons',
                     '?' => undef
                  }),
   'http://'.$endpoint_host.'/suggest?q=simpsons',
   'endpoint 10');


my $acct    = 'acct:akron@sojolicious.example';
my $btables = 'hmm&bobby=tables';
is($app->endpoint('test4' => {
                     searchTerms => $acct,
                     startIndex => $btables
                  }),
   'http://'.$endpoint_host.'/suggest?' . 
   'q=' . b($acct)->url_escape . 
   '&start=' . b($btables)->url_escape,
   'endpoint 11');

$r_test->endpoint(test5 => {
    query => [ a => '{foo?}',
	       b => '{bar?}',
	       c => '{foo}',
	       d => '{BAR}'
	]});

is($app->endpoint('test5' =>
		  {
		      bar => 'This is a {test}'
		  }),
   '/suggest?a={foo?}&b=This%20is%20a%20%7Btest%7D&c={foo}&d={BAR}',
   'endpoint 12');

is($app->endpoint('test5' =>
		  {
		      BAR => '?'
		  }),
   '/suggest?a={foo?}&b={bar?}&c={foo}&d=%3F',
   'endpoint 13');

is($app->endpoint('test5' =>
		  {
		      bar => '}&{'
		  }),
   '/suggest?a={foo?}&b=%7D%26%7B&c={foo}&d={BAR}',
   'endpoint 14');

is($app->endpoint('test5' =>
		  {
		      '?' => undef
		  }),
   '/suggest?c={foo}&d={BAR}',
   'endpoint 15');

$r_test->endpoint(test6 => {
    query => [ a => '{foo?}',
	       b => '{bar?}',
	       c => '{foo}',
	       d => '{BAR}',
	       e => '{test:foo?}',
	       f => '*'
	]});

is($app->endpoint('test6' =>
		  {
		      '?' => undef
		  }),
   '/suggest?c={foo}&d={BAR}&f=*',
   'endpoint 16');

is($app->endpoint('test6' =>
		  {
		      'test:foo' => 'check',
		      '?' => undef
		  }),
   '/suggest?c={foo}&d={BAR}&e=check&f=*',
   'endpoint 17');

my $hash = $app->get_endpoints;

is ($hash->{test1},
    'https://'.$endpoint_host.'/test',
    'hash-test 1');

is ($hash->{test2},
    'https://'.$endpoint_host.'/test?a={var1}',
    'hash-test 2');

is ($hash->{test3},
    'http://'.$endpoint_host.'/test?a={var1}&b={var2}',
    'hash-test 3');

is ($hash->{test4},
    'http://'.$endpoint_host.'/suggest?q={searchTerms}&start={startIndex?}',
    'hash-test 4');

is ($hash->{test5},
    '/suggest?a={foo?}&b={bar?}&c={foo}&d={BAR}',
    'hash-test 5');

is ($hash->{test6},
    '/suggest?a={foo?}&b={bar?}&c={foo}&d={BAR}&e={test:foo?}&f=*',
    'hash-test 6');

# Define by string
ok($app->endpoint(test7 => 'http://grimms-abenteuer.de/test'), 'Define by string');
is($app->endpoint('test7'), 'http://grimms-abenteuer.de/test', 'Define by string');

# Define by URL
ok($app->endpoint(test8 => Mojo::URL->new('/hi/test')), 'Define by URL');
is($app->endpoint('test8'), '/hi/test', 'Define by URL');

# Define by string
ok($app->endpoint(test9 => 'http://grimms-abenteuer.de/test?q={try}'),
   'Define by string');
is($app->endpoint('test9' => { try => 'Akron'}),
   'http://grimms-abenteuer.de/test?q=Akron',
   'Define by string');

# Define by string
ok($app->endpoint(test10 => 'http://grimms-abenteuer.de/test?q={try}&p={ready?}'),
   'Define by string');
is($app->endpoint('test10' => { try => 'Akron'}),
   'http://grimms-abenteuer.de/test?q=Akron&p={ready?}',
   'Define by string');
is($app->endpoint('test10' => { try => 'Akron', ready => 'yeah'}),
   'http://grimms-abenteuer.de/test?q=Akron&p=yeah',
   'Define by string');
is($app->endpoint('test10' => { try => 'Akron', '?' => undef}),
   'http://grimms-abenteuer.de/test?q=Akron',
   'Define by string');


# Test with placeholders
my $r_test_2 = $app->routes->any('/:placeholder');
$r_test_2->endpoint('check');
is($app->endpoint('check'), '/{placeholder}', 'Check path placeholder');
is($app->endpoint('check' => {
  placeholder => 'try'
}), '/try', 'Check path placeholder');

my $r_test_3 = $app->routes->any('/:placeholder/:try');
$r_test_3->endpoint('check2');
is($app->endpoint('check2'), '/{placeholder}/{try}',
   'Check path placeholder 2');
is($app->endpoint('check2' => {
  placeholder => 'try1',
}), '/try1/{try}', 'Check path placeholder 2');
is($app->endpoint('check2' => {
  placeholder => 'try1',
  try => 'try2'
}), '/try1/try2', 'Check path placeholder 2');

my $r_test_4 = $app->routes->any('/:placeholder/:try');
$r_test_4->endpoint('check3' => {
  query => [ q => '{test}' ]
});
is($app->endpoint('check3'), '/{placeholder}/{try}?q={test}',
   'Check path placeholder 3');
is($app->endpoint('check3' => {
  placeholder => 'try1',
}), '/try1/{try}?q={test}', 'Check path placeholder 3');
is($app->endpoint('check3' => {
  placeholder => 'try1',
  try => 'try2'
}), '/try1/try2?q={test}', 'Check path placeholder 3');
is($app->endpoint('check3' => {
  placeholder => 'try1',
  try => 'try2',
  test => 'try3'
}), '/try1/try2?q=try3', 'Check path placeholder 3');

my $r_test_5 = $app->routes->any('/opensearch.xml');

ok($r_test_5->endpoint(
  opensearch => {
    query => [
      q => '{searchTerms}',
      count => '{count?}',
      startIndex => '{startIndex?}',
      startPage => '{startPage?}',
      format => '{format?}'
    ]
  }
), 'Opensearch Test 1');

is ($app->endpoint('opensearch'),
    '/opensearch.xml?q={searchTerms}&' .
      'count={count?}&startIndex={startIndex?}&' .
	'startPage={startPage?}&format={format?}',
    'Opensearch Test 2');

is ($app->endpoint('opensearch' => { format => 'rss'}),
    '/opensearch.xml?q={searchTerms}&' .
      'count={count?}&startIndex={startIndex?}&' .
	'startPage={startPage?}&format=rss',
    'Opensearch Test 3');

is ($app->endpoint('opensearch' => { format => 'atom'}),
    '/opensearch.xml?q={searchTerms}&' .
      'count={count?}&startIndex={startIndex?}&' .
	'startPage={startPage?}&format=atom',
    'Opensearch Test 4');


ok($app->endpoint('opensearch-2' => '?peter={a?}'), 'Nearly empty endpoint');

is($app->endpoint('opensearch-2' => { '?' => undef }), '', 'Nearly empty endpoint');

ok(my $c = Mojolicious::Controller->new, 'New Controller');


ok($c->app($app), 'Set App to controller');

ok($c->app->build_controller->req->url->port('23456'), 'Set port');
is($c->endpoint('test9'), 'http://grimms-abenteuer.de/test?q={try}',
   'Test9 with port');

# Wildcards
$r_test = $app->routes->any('/test2');
my $r_test2 = $r_test->any('/:fine');
my $r_test3 = $r_test2->any('/peter-*huhu');
my $r_test4 = $r_test3->any('/#all');
my $r_test5 = $r_test4->any('/*hui', hui => qr{\d+});

$r_test5->endpoint('test-wildcards' =>
		    {
		      host   => $endpoint_host,
		      scheme => 'https'
		    });

is($app->endpoint('test-wildcards' => { 'fine' => 'jai' }),
   'https://endpoi.nt/test2/jai/peter-{huhu}/{all}/{hui}',
   'Correct placeholder interpolation');

is($app->endpoint(
  'http://sojolicious.example/.well-known/webfinger?resource={uri}' => {
    uri => 'acct:akron@sojolicious.example'
  }),
  'http://sojolicious.example/.well-known/webfinger?resource=acct%3Aakron%40sojolicious.example',
  'Arbitrary template url'
);

is($app->endpoint(
  'http://sojolicious.example/.well-known/webfinger?resource={uri}&res={uri}' => {
    uri => 'acct:akron@sojolicious.example'
  }),
  'http://sojolicious.example/.well-known/webfinger?resource=acct%3Aakron%40sojolicious.example&res=acct%3Aakron%40sojolicious.example',
  'Arbitrary template url'
);

is($app->endpoint(
  'http://sojolicious.example/.well-known/webfinger?resource={uri}&rel={rel?}' => {
    uri => 'acct:akron@sojolicious.example'
  }),
  'http://sojolicious.example/.well-known/webfinger?resource=acct%3Aakron%40sojolicious.example&rel={rel?}',
  'Arbitrary template url'
);

is($app->endpoint(
  'http://sojolicious.example/.well-known/webfinger?resource={uri}&rel={rel?}' => {
    uri => 'acct:akron@sojolicious.example',
    '?' => undef
  }),
  'http://sojolicious.example/.well-known/webfinger?resource=acct%3Aakron%40sojolicious.example',
  'Arbitrary template url'
);

is($app->endpoint(
  'http://sojolicious.example/{user}/webfinger?resource={uri}&rel={rel?}' => {
    uri => undef
  }),
  'http://sojolicious.example/{user}/webfinger?rel={rel?}',
  'Arbitrary template url'
);

is($app->endpoint(
  'http://sojolicious.example/{user?}/webfinger?resource={uri}&rel={rel?}' => {
    uri => undef,
    user => undef
  }),
  'http://sojolicious.example/webfinger?rel={rel?}',
  'Arbitrary template url'
);

is($app->endpoint('fun'), '/test/fun', 'named route');


done_testing;
