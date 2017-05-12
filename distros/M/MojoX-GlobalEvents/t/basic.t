#!/usr/bin/env perl

use strict;
use warnings;

use MojoX::GlobalEvents;

use Test::More;

{
  package Cat;
  use Mojo::Base '-base';
  use MojoX::GlobalEvents;
  
  has eyes => 2;

  sub tell {
    my $self = shift;
    publish( 'sunset' );
  }
}

package main;
  
my $msg = '';
my $cat = Cat->new;
$cat->on( 'sunset' => sub {
    $msg .= "even when it's dark I can see with my " . $cat->eyes . " eyes\n";
});

publish 'sunset';

is $msg, "even when it's dark I can see with my 2 eyes\n";

my $cat2 = Cat->new;
$cat2->on( 'sunset' => sub {
    $msg .= "even when it's dark I can see with my " . $cat->eyes . " eyes\n";
});

publish 'sunset';

is $msg, ("even when it's dark I can see with my 2 eyes\n" x 3);

$cat->tell;

is $msg, ("even when it's dark I can see with my 2 eyes\n" x 5);

done_testing();
