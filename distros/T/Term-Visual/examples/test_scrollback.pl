#!/usr/bin/perl -W
use strict;
use Carp;
use POE;
use Term::Visual;

sub MAX_SECS_BETWEEN_LINES  () { 5 }
sub MAX_SECS_BETWEEN_STATUS () { 60 }
sub MAX_SECS_BETWEEN_STDERR () { 30 }
my @alphabet = ('A'..'Z', 'a'..'z', '0'..'9');

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

my $window_id = $vt->create_window(
       Window_Name => "window_one",

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
                 },

       Buffer_Size => 1000,
       History_Size => 50,

       Title => "Title of window_one"  );

POE::Session->create
  (inline_states =>
    { _start         => \&start_guts,
      got_term_input => \&handle_term_input,
      update_time    => \&update_time,
      update_name    => \&update_name,
      test_stderr    => \&test_stderr,
      activity       => \&activity,
    }
  );

$vt->print($window_id, "My Window ID is $window_id");

## Initialize the back-end guts of the "client".

sub start_guts {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  # Tell the terminal to send me input as "got_term_input".
  $kernel->post( interface => send_me_input => "got_term_input" );

  # Start updating the time.
  $kernel->yield( "update_time" );
  $kernel->yield( "update_name" );
  $kernel->yield( "test_stderr" );
  $kernel->yield( "activity"    );
}

### The main input handler for this program.  This would be supplied
### by the guts of the client program.

sub handle_term_input {
#  beep();
  my ($kernel, $heap, $input, $exception) = @_[KERNEL, HEAP, ARG0, ARG1];

  $vt->print($window_id, $input);
}

### Update the time on the status bar.

sub update_time {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  # New time format.
  use POSIX qw(strftime);
  $vt->set_status_field( $window_id, time => strftime("%I:%M %p", localtime) );

  # Schedule another time update for the next minute.  This is more
  # accurate than using delay() because it schedules the update at the
  # beginning of the minute.
  $kernel->alarm( update_time => int(time() / 60) * 60 + 60 );
}

sub update_name {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  $vt->set_status_field( $window_id, name => $alphabet[rand @alphabet] x (rand(15) + 3) );
$kernel->delay( update_name => rand(MAX_SECS_BETWEEN_STATUS) );
}

# Periodically test STDERR redirection.

sub test_stderr {
  my $kernel = $_[KERNEL];
  warn "generic stderr message: " . scalar(gmtime()) . " GMT";
  $kernel->delay( test_stderr => rand(MAX_SECS_BETWEEN_STDERR) );
}

# Simulate Screen Activity.

sub activity {
  my $kernel = $_[KERNEL];
  my @words;
  my $word_count = int(rand(29)) + 1;
  for (1..$word_count) {
    push @words, $alphabet[rand @alphabet] x (rand(10)+1);
  }

  my $input = shift(@words);
  foreach my $word (@words) {
    $input .= (" " x (rand(5)+1)) . $word;
  }

  $vt->print( $window_id, $input );
  $kernel->delay( activity => rand(MAX_SECS_BETWEEN_LINES) );
}


$poe_kernel->run();

$vt->shutdown;
exit 0;
