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

my $window_id = $vt->create_window(
       Window_Name => "window_one",
       Buffer_Size => 1000,
       History_Size => 50,
       Use_Status => 0,
       Use_Title => 0 );

POE::Session->create
  (inline_states =>
    { _start         => \&start_guts,
      got_term_input => \&handle_term_input,
    }
  );

$vt->print($window_id, "My Window ID is $window_id");

## Initialize the back-end guts of the "client".

sub start_guts {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  # Tell the terminal to send me input as "got_term_input".
  $kernel->post( interface => send_me_input => "got_term_input" );
#  $vt->print($window_id, $vt->[0]{$window_id}->{Screen_Height});
}

### The main input handler for this program.  This would be supplied
### by the guts of the client program.

sub handle_term_input {
  my ($kernel, $heap, $input, $exception) = @_[KERNEL, HEAP, ARG0, ARG1];

  # Got an exception.  These are interrupt (^C) or quit (^\).
  if (defined $exception) {
    warn "got exception: $exception";
    exit;
  }
  $vt->print($window_id, $input);
}

$poe_kernel->run();
$vt->shutdown;
exit 0;
