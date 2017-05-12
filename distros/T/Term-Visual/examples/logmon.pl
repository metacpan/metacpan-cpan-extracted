#!/usr/bin/perl -w
use strict;
use POE;
use POE qw(Wheel::FollowTail Filter::Line Driver::SysRW);
use Term::Visual;

my @files = qw(/var/log/messages /var/log/kernel.log /var/log/maillog
 /var/log/ftp.log /var/log/lpd-errs);

# Start Term::Visual.

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
       Window_Name => "logmon",

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
                   1 =>
                   { format => " Observing: %s",
                     fields => [ qw( file ) ] },
                 },

       Buffer_Size => 1000,
       History_Size => 50,

       Title => "System Log Monitor" );

POE::Session->create
  (inline_states =>
    { _start         => \&start_guts,
      got_term_input => \&handle_term_input,
      update_time    => \&update_time,
      update_file    => \&update_file,
      input_tail     => \&input_tail,
    }
  );

## Initialize the back-end guts of the "client".

sub start_guts {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  # Tell the terminal to send me input as "got_term_input".
  $kernel->post( interface => send_me_input => "got_term_input" );

  $kernel->yield( "update_time" );

  my $window_name = $vt->get_window_name($window_id);
  $vt->set_status_field( $window_id, name => $window_name );


  my $filist = join(" ",@files);
  $filist =~ s!/var/log/!!g;
  $vt->set_status_field( $window_id, file => $filist);
#  $kernel->yield( update_file => $filist);


  # Start Following a File
  foreach my $file (@files) {
    $heap->{"wheel_$file"} = POE::Wheel::FollowTail->new
      ( Filename     => $file,
        Driver       => POE::Driver::SysRW->new(),
        Filter       => POE::Filter::Line->new(),
        PollInterval => 1,
        InputEvent   => "input_tail",
        ErrorEvent   => \&error_tail,
        ResetEvent   => \&reset_tail,
      );

  }
}

### The main input handler for this program.  This would be supplied
### by the guts of the client program.

sub handle_term_input {
  my ($kernel, $heap, $input, $exception) = @_[KERNEL, HEAP, ARG0, ARG1];

  # Got an exception.  These are interrupt (^C) or quit (^\).
  if (defined $exception) {
    warn "got exception: $exception";
    $vt->delete_window($window_id);
    exit;
  }

  if ($input =~ s{^/\s*(\S+)\s*}{}) {
    my $cmd = uc($1);

    if ($cmd eq 'QUIT') {
     # might close open filehandles here.
      $vt->delete_window($window_id);
      exit;
    }
    # Unknown command?
    warn "Unknown command: $cmd";
    return;
  }

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

sub update_file {
  my ($kernel,$file) = @_[KERNEL,ARG0];

  $vt->set_status_field( $window_id, file => $file );
}

sub input_tail {
    my ($heap, $input, $wheel_id) = @_[HEAP, ARG0, ARG1];
  $vt->print( $window_id, $input );
}

sub error_tail {
    my ($operation, $errnum, $errstr, $wheel_id) = @_[ARG0..ARG3];
    warn "Wheel $wheel_id generated $operation error $errnum: $errstr";
}

sub reset_tail {
    my $wheel_id = $_[ARG0];
    $vt->print( $window_id, "Reset $wheel_id");
}

$poe_kernel->run();
$vt->shutdown;
exit 0;


