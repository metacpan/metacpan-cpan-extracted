#!/usr/bin/perl -W
use strict;
use Carp;
use POE;
use Term::Visual;

my $vt = Term::Visual->new( Alias => "interface" );

$vt->set_palette( mycolor       => "magenta on black",
                  statcolor     => "green on black",
                  sockcolor     => "cyan on black",
                  ncolor        => "white on black",
                  st_frames     => "bright cyan on blue",
                  st_values     => "bright white on blue",
                  stderr_bullet => "bright white on red",
                  stderr_text   => "bright yellow on black",
                  err_input     => "bright white on red",
                  help          => "white on black",
                  help_cmd      => "bright white on black" );

my @window_ids;

sub window {
    push( @window_ids, $vt->create_window(
       Window_Name => "window_$_",

       Status => { 0 =>
                   { format => "\0(st_frames)" .
                               " [" .
                               "\0(st_values)" .
                               "%8.8s" .
                               "\0(st_frames)" .
                               "] " .
                               "\0(st_values)" .
                               "%s",
                     fields => [qw( time name )] },
#                   1 =>
#                   { format => "template for status line 2",
#                     fields => [ qw( foo bar ) ] },
                 },
 
       Buffer_Size => 1000,
       History_Size => 50,
 
       Title => "Title of window_$_" ) );
} 

for (0..50) {
  window($_);
}

POE::Session->create
  (inline_states =>
    { _start         => \&start_guts,
      got_term_input => \&handle_term_input,
      update_time    => \&update_time,
    } 
  ); 

for (@window_ids) {
  $vt->print($_, "My Window ID is $_");
} 

## Initialize the back-end guts of the "client".
 
sub start_guts {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  # Tell the terminal to send me input as "got_term_input".
  $kernel->post( interface => send_me_input => "got_term_input" );
 
  for my $window_id (@window_ids) {
    my $window_name = $vt->get_window_name($window_id);
    $vt->set_status_field( $window_id, name => $window_name ); 
  }

  $kernel->yield( "update_time" );
  warn "Testing Error Output";
}

sub handle_term_input {

  my ($kernel, $heap, $input, $exception) = @_[KERNEL, HEAP, ARG0, ARG1];
 
  my $window_id = $vt->current_window;
  $vt->print($window_id, $input);
}

### Update the time on the status bar.
 
sub update_time {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  # New time format.
  use POSIX qw(strftime);
  
  for my $window_id (@window_ids) {
   $vt->set_status_field( $window_id, time => strftime("%I:%M %p", localtime) );
  }
  # Schedule another time update for the next minute.  This is more
  # accurate than using delay() because it schedules the update at the
  # beginning of the minute.
  $kernel->alarm( update_time => int(time() / 60) * 60 + 60 );
}

$poe_kernel->run();
$vt->shutdown;
exit 0;

