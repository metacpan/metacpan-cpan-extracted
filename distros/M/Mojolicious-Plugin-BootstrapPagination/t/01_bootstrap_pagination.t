#!/usr/bin/env perl


use strict;
use warnings;


BEGIN{
  $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 ;
  $ENV{MOJO_APP} = undef; # 
}
use Test::More tests => 27;
use Test::Mojo;


use Mojolicious::Lite;
plugin 'bootstrap_pagination';
get( "/" => sub(){
    my $self = shift;
    $self->render( text => $self->bootstrap_pagination( 10, 15 ) . "\n" );
  } );

get( "/none" => sub(){
    my $self = shift;
    $self->render( text => $self->bootstrap_pagination( 1, 1) . "\n" );
  } );

get( "/class" => sub(){
    my $self = shift;
    $self->render( text => $self->bootstrap_pagination( 1, 2, {class=>"test"}) . "\n" );
  } );

get( "/param" => sub(){
    my $self = shift;
    $self->render( text => $self->bootstrap_pagination( 1, 2, {param=>"p"}) . "\n" );
  } );

get( "/round" => sub(){
    my $self = shift;
    $self->render( text => $self->bootstrap_pagination( 10, 15, {round=>1}) . "\n" );
  } );

get( "/outer" => sub(){
    my $self = shift;
    $self->render( text => $self->bootstrap_pagination( 10, 15, {round=>1,outer=>1}) . "\n" );
  } );

get( "/query" => sub(){
    my $self = shift;
    $self->render( text => $self->bootstrap_pagination( 5, 10, {round=>1,outer=>1,query=>"&id1=value1"}) . "\n" );
  } );

get( "/start" => sub(){
    my $self = shift;
    $self->render( text => $self->bootstrap_pagination( 9, 18, {start=>2, round=>1,outer=>1}) . "\n" );
  } );

get( "/start2" => sub(){
    my $self = shift;
    $self->render( text => $self->bootstrap_pagination( 9, 18, {start=>2, round=>1,outer=>1}) . "\n" );
  } );

my $t = Test::Mojo->new(  );
$t->get_ok( "/" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<ul class="pagination"><li><a href="/?page=9" >&laquo;</a></li><li><a href="/?page=1">1</a></li><li><a href="/?page=2">2</a></li><li><a href="/?page=4" >&hellip;</a></li><li><a href="/?page=6">6</a></li><li><a href="/?page=7">7</a></li><li><a href="/?page=8">8</a></li><li><a href="/?page=9">9</a></li><li class="active"><span>10</span></li><li><a href="/?page=11">11</a></li><li><a href="/?page=12">12</a></li><li><a href="/?page=13">13</a></li><li><a href="/?page=14">14</a></li><li><a href="/?page=15">15</a></li><li><a href="/?page=11" >&raquo;</a></li></ul>
EOF

$t->get_ok( "/none" )
  ->status_is( 200 )
  ->content_is(<<EOF);

EOF

$t->get_ok( "/class" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<ul class="pagination test"><li class="disabled"><a href="#" >&laquo;</a></li><li class="active"><span>1</span></li><li><a href="/class?page=2">2</a></li><li><a href="/class?page=2" >&raquo;</a></li></ul>
EOF

$t->get_ok( "/param" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<ul class="pagination"><li class="disabled"><a href="#" >&laquo;</a></li><li class="active"><span>1</span></li><li><a href="/param?p=2">2</a></li><li><a href="/param?p=2" >&raquo;</a></li></ul>
EOF

$t->get_ok( "/round" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<ul class="pagination"><li><a href="/round?page=9" >&laquo;</a></li><li><a href="/round?page=1">1</a></li><li><a href="/round?page=2">2</a></li><li><a href="/round?page=6" >&hellip;</a></li><li><a href="/round?page=9">9</a></li><li class="active"><span>10</span></li><li><a href="/round?page=11">11</a></li><li><a href="/round?page=13" >&hellip;</a></li><li><a href="/round?page=14">14</a></li><li><a href="/round?page=15">15</a></li><li><a href="/round?page=11" >&raquo;</a></li></ul>
EOF

$t->get_ok( "/outer" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<ul class="pagination"><li><a href="/outer?page=9" >&laquo;</a></li><li><a href="/outer?page=1">1</a></li><li><a href="/outer?page=6" >&hellip;</a></li><li><a href="/outer?page=9">9</a></li><li class="active"><span>10</span></li><li><a href="/outer?page=11">11</a></li><li><a href="/outer?page=13" >&hellip;</a></li><li><a href="/outer?page=15">15</a></li><li><a href="/outer?page=11" >&raquo;</a></li></ul>
EOF

$t->get_ok( "/query" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<ul class="pagination"><li><a href="/query?page=4&id1=value1" >&laquo;</a></li><li><a href="/query?page=1&id1=value1">1</a></li><li><a href="/query?page=3&id1=value1" >&hellip;</a></li><li><a href="/query?page=4&id1=value1">4</a></li><li class="active"><span>5</span></li><li><a href="/query?page=6&id1=value1">6</a></li><li><a href="/query?page=8&id1=value1" >&hellip;</a></li><li><a href="/query?page=10&id1=value1">10</a></li><li><a href="/query?page=6&id1=value1" >&raquo;</a></li></ul>
EOF

$t->get_ok( "/start" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<ul class="pagination"><li><a href="/start?page=8" >&laquo;</a></li><li><a href="/start?page=2">2</a></li><li><a href="/start?page=5" >&hellip;</a></li><li><a href="/start?page=8">8</a></li><li class="active"><span>9</span></li><li><a href="/start?page=10">10</a></li><li><a href="/start?page=14" >&hellip;</a></li><li><a href="/start?page=18">18</a></li><li><a href="/start?page=10" >&raquo;</a></li></ul>
EOF

$t->get_ok( "/start2?id=1" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<ul class="pagination"><li><a href="/start2?id=1&page=8" >&laquo;</a></li><li><a href="/start2?id=1&page=2">2</a></li><li><a href="/start2?id=1&page=5" >&hellip;</a></li><li><a href="/start2?id=1&page=8">8</a></li><li class="active"><span>9</span></li><li><a href="/start2?id=1&page=10">10</a></li><li><a href="/start2?id=1&page=14" >&hellip;</a></li><li><a href="/start2?id=1&page=18">18</a></li><li><a href="/start2?id=1&page=10" >&raquo;</a></li></ul>
EOF
