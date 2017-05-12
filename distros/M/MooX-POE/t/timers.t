#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

my $right_cnt = 0;
my $inside_cnt = 0;
my $outside_cnt = 0;
my $wrong_cnt = 0;

{
  package Test::MooX::POE::Timers::Doer;

  use Moo;
  with 'MooX::POE';
   
  sub on_tick {
    my ( $self ) = @_;
    $right_cnt++;
    $self->inside_self_delay;
  }

  sub on_inside_self_delay_tick {
    my ( $self ) = @_;
    $inside_cnt++;
  }

  sub on_outside_self_delay_tick {
    my ( $self ) = @_;
    $outside_cnt++;
  }

  sub inside_self_delay {
    my ( $self ) = @_;
    $self->delay( 'inside_self_delay_tick' => 1 );
  }

  sub outside_self_delay {
    my ( $self ) = @_;
    $self->delay( 'outside_self_delay_tick' => 1 );
  } 
}
 
{
  package Test::MooX::POE::Timers::SomeoneElse;

  use Moo;
  with 'MooX::POE';

  sub START {
    my ( $self ) = @_;
    my $doer = Test::MooX::POE::Timers::Doer->new();
    $doer->delay( 'tick' => 1 );
    $doer->outside_self_delay;
  }
   
  sub on_tick {
    $wrong_cnt++;
  }
}
 
Test::MooX::POE::Timers::SomeoneElse->new;
POE::Kernel->run;
 
is($inside_cnt, 1, 'right self_tick is called by $self inside the session');
is($outside_cnt, 1, 'right self_tick is called by $self outside the session');
is($right_cnt, 1, 'right tick is called');
is($wrong_cnt, 0, 'wrong tick isnt called');
 
done_testing();