#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

# Disable epoll, kqueue and IPv6
BEGIN { $ENV{MOJO_POLL} = $ENV{MOJO_NO_IPV6} = 1 }

use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
plugin 'DevexpressHelpers';
app->log->level('error'); #silence

# routes
get '/' => 'index';
get '/customstore' => 'customstore';
get '/customeoptions' => 'customeoptions';

# Test
my $t = Test::Mojo->new;

# GET / default
$t->get_ok('/')
  ->status_is(200)
  ->element_exists('html body div[id=dxctl1]')
  ->text_is('script' => q{$(window).on("load",function(){
$("#dxctl1").dxDataGrid({columns: ["id","name",{"cellTemplate":function(c,o){ return 42 }},{"allowFiltering":false}],
dataSource: {store:{type:'odata',url:'/web-service.json'}}});
});});

# GET /customstore
$t->get_ok('/customstore')
  ->status_is(200)
  ->element_exists('html body div[id=myGrid1]')
  ->text_is('script' => q{$(window).on("load",function(){
$("#myGrid1").dxDataGrid({columns: ["id","name",{"cellTemplate":function(c,o){ return 42 }},{"allowFiltering":false}],
dataSource: SERVICES.myEntity});
});});

# GET /customeoptions
$t->get_ok('/customeoptions')
  ->status_is(200)
  ->element_exists('html body div[id=myGrid2]')
  ->text_is('script' => q{$(window).on("load",function(){
$("#myGrid2").dxDataGrid(SERVICES.gridsOptions.myEntity);
});});

done_testing;

__DATA__
@@ index.html.ep
% layout 'main';
%= dxdatagrid undef, '/web-service.json' => { columns => [ qw(id name), { cellTemplate => \q{function(c,o){ return 42 }}}, {allowFiltering => false} ] }

@@ customstore.html.ep
% layout 'main';
%= dxdatagrid myGrid1 => \'SERVICES.myEntity' => { columns => [ qw(id name), { cellTemplate => \q{function(c,o){ return 42 }}}, {allowFiltering => false} ] }

@@customeoptions.html.ep
% layout 'main';
%= dxdatagrid myGrid2 => { options => 'SERVICES.gridsOptions.myEntity', dumy => 42 }

@@ layouts/main.html.ep
<!doctype html>
<html>
    <head>
       <title>Test</title>
    </head>
    <body><%== content %>
%= dxbuild
</body>
</html>