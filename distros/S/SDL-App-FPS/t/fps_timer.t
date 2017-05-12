#!/usr/bin/perl -w

# test the timer feature of SDL::App::FPS (especially overdue and firing
# order)

use Test::More tests => 10;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  }

use SDL::App::MyFPS2;

use SDL::Event;

my $options = { width => 640, height => 480, depth => 24, max_fps => 60};
my $app = SDL::App::MyFPS2->new( $options );

my $timer_a = { fired => 0, last => [], };
my $timer_b = { fired => 0, last => [], };
my $timer_c = { fired => 0, last => [],  };
my $timer_d = { fired => 0, last => [],  };

my $timer_string = '';

# since we wait at least 120 ms, the following should happen:

# at:             30 40  60  70  80  90 120
# timer X fires:  D  B   D   A   B   C  B

# Note that D does not fire at 90 or later, since it fires only twice
# Note that A does not fire at 140 or later, since it fires only once

# Also note: C ends the app, but B fires after it since the app only quits when
# all timers were checked for the current frame

# fires at "+70"
my $ta = $app->add_timer(70, 1, 0, 0, sub {
   my ($self,$timer,$overdue) = @_;
   my $now = $app->now();
   $timer_a->{fired}++; push @{$timer_a->{last}}, $overdue;
   $timer_string .= "A"; 
   print "# $now A overdue $overdue (real at ",$now-$overdue,
    "), next would be $timer->{next_shot}\n"; 
   SDL::Delay(10);
   } );
# fires at "+40 +80 +120 +160"
my $tb = $app->add_timer(40, -1, 0, 0, sub {
   my ($self,$timer,$overdue) = @_;
   my $now = $app->now();
   $timer_b->{fired}++; push @{$timer_b->{last}}, $overdue; 
   $timer_string .= "B"; 
   print "# $now B overdue $overdue (real at ",$now-$overdue,
     "), next would be $timer->{next_shot}\n"; 
   SDL::Delay(10);
   } );
# fires at "+180"
my $tc = $app->add_timer(90, -1, 0, 0, sub {
   my ($self,$timer,$overdue) = @_;
   my $now = $app->now();
   $timer_c->{fired}++; push @{$timer_c->{last}}, $overdue;
   $timer_string .= "C"; 
   print "# $now C overdue $overdue (real at ",$now-$overdue,
    "), next would be $timer->{next_shot}\n"; 
   $self->quit(); 
   } );
# fires at "+30 +60"
my $td = $app->add_timer(30, 2, 0, 0, sub {
   my ($self,$timer,$overdue) = @_;
   my $now = $app->now();
   $timer_d->{fired}++; push @{$timer_c->{last}}, $overdue;
   $timer_string .= "D"; 
   print "# $now D overdue $overdue (real at ",$now-$overdue,
    "), next would be $timer->{next_shot}\n"; 
   } );

$app->main_loop();

# check that timers run only once
is ($timer_a->{fired}, 1, 'timer a fired once');
is ($timer_b->{fired}, 3, 'timer b fired three times');
is ($timer_c->{fired}, 1, 'timer c fired once');
is ($timer_d->{fired}, 2, 'timer d fired twice');

# check that timer were run in the desired order
is ($timer_string, 'DBDABCB', 'timer order was okay');

is ($app->timers(), 2, 'two timers still running (B and A)'); 
is (ref($app->get_timer($tb->{id})), 'SDL::App::FPS::Timer', 'B still running');
is (ref($app->get_timer($tc->{id})), 'SDL::App::FPS::Timer', 'C still running');
is ($app->get_timer($ta->{id}), undef, 'timer A not running');
is ($app->get_timer($td->{id}), undef, 'timer D not running');

