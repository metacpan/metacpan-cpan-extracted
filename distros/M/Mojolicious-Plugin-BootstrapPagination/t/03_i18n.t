#!/usr/bin/env perl

use strict;
use warnings;

BEGIN{
  $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 ;
  $ENV{MOJO_APP} = undef; # 
}
use Test::More;
use Test::Mojo;


use Mojolicious::Lite;
plugin 'bootstrap_pagination' => {
   localize => \&localize,
};
get( "/" => sub(){
    my $self = shift;
    $self->render( text => $self->bootstrap_pagination( 10, 15 ) . "\n" );
  } );

my $t = Test::Mojo->new(  );
$t->get_ok( "/" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<ul class="pagination"><li><a href="/?page=9" >&laquo;</a></li><li><a href="/?page=1">one</a></li><li><a href="/?page=2">two</a></li><li><a href="/?page=4" >&hellip;</a></li><li><a href="/?page=6">six</a></li><li><a href="/?page=7">seven</a></li><li><a href="/?page=8">eight</a></li><li><a href="/?page=9">nine</a></li><li class="active"><span>ten</span></li><li><a href="/?page=11">eleven</a></li><li><a href="/?page=12">twelve</a></li><li><a href="/?page=13">thirteen</a></li><li><a href="/?page=14">fourteen</a></li><li><a href="/?page=15">fifteen</a></li><li><a href="/?page=11" >&raquo;</a></li></ul>
EOF

done_testing();

sub localize {
    my ($self, $number) = @_;

    my %trans = (
      1 => 'one',
      2 => 'two',
      6 => 'six',
      7 => 'seven',
      8 => 'eight',
      9 => 'nine',
     10 => 'ten',
     11 => 'eleven',
     12 => 'twelve',
     13 => 'thirteen',
     14 => 'fourteen',
     15 => 'fifteen',
    );

    return $trans{$number};
}

