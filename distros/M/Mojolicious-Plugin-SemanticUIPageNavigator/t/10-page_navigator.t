#!/usr/bin/env perl
 
use strict;
use warnings;
 
BEGIN{
  $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 ;
  $ENV{MOJO_APP} = undef; # 
}
use Test::More tests => 3;
use Test::Mojo;
 
use Mojolicious::Lite;
plugin 'SemanticUIPageNavigator';
get( "samples" => sub(){
    my $self = shift;
    $self->render( text => $self->page_navigator( 1, 18, {round => 2} ) . "\n"  );
  } );
 
 
my $t = Test::Mojo->new(  );
$t->get_ok( "/samples" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<div class="pagination_outer" style="margin: 10px auto; text-align: center"><div class="ui pagination menu"><a class="item" href="/samples?p=1">首页</a><a class="item" href="/samples?p=0">上一页</a><a class="active teal item" href="/samples?p=1">1</a><a class="item" href="/samples?p=2">2</a><a class="item" href="/samples?p=3">3</a><a class="item" href="/samples?p=4">4</a><a class="item" href="/samples?p=5">5</a><a class="item" href="/samples?p=6">6</a><a class="item">..</a><a class="item" href="/samples?p=17">17</a><a class="item" href="/samples?p=18">18</a><a class="item" href="/samples?p=2">下一页</a><a class="item" href="/samples?p=18">末页</a></div></div>
EOF
1;
