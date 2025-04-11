package PDL::Graphics::TriD::GL::GLFW;

use strict;
use warnings;
use OpenGL::GLFW qw( :all );

our @ISA = qw(PDL::Graphics::TriD::GL);
my ($window_seq, @fakeXEvents, %winObjects) = 0;

sub new {
  my ($class,$options,$window_obj) = @_;
  my $self = $class->SUPER::new($options,$window_obj);
  print STDERR "Creating GLFW OO window\n" if $PDL::Graphics::TriD::verbose;
  glfwSetErrorCallback(\&_error_callback);
  die "Failed to initialise GLFW" if glfwInit() != GLFW_TRUE;
  $self->{xevents} = \@fakeXEvents;
  $self->{winobjects} = \%winObjects;
  my $p = $self->{Options};
  glfwWindowHint(GLFW_SCALE_FRAMEBUFFER, GLFW_FALSE);
  die "GLFW failed to create window"
    if !defined(my $glfwin = $self->{glfwwindow} = glfwCreateWindow(@$p{qw(width height)}, "GLFW TriD", NULL, NULL));
  $self->{window_seq} = ++$window_seq;
  glfwSetWindowTitle($glfwin, "GLFW TriD #$self->{window_seq}");
  glfwSetWindowSizeCallback($glfwin, \&_fake_ConfigureNotify);
  glfwSetWindowCloseCallback($glfwin, \&_fake_exit_handler);
  glfwSetCharCallback($glfwin, \&_fake_KeyPress);
  glfwSetMouseButtonCallback($glfwin, \&_fake_button_event);
  glfwSetScrollCallback($glfwin, \&_fake_scroll_event);
  glfwSetCursorPosCallback($glfwin, \&_fake_MotionNotify);
  glfwSetWindowRefreshCallback($glfwin,\&_display_wrapper);
  glfwShowWindow($glfwin);
  if ($PDL::Graphics::TriD::verbose) {
    print "gdriver: Got TriD::GL object(GLFW window ID#$self->{window_seq} " . $self->{glfwwindow} . ")\n";
  }
  $self->{winobjects}->{$self->{glfwwindow}} = $window_obj;      # circular ref
  $self;
}

END { glfwSetErrorCallback(undef); glfwTerminate(); }

sub _error_callback {
  my ($err_code, $err_str) = @_;
  warn "GLFW error $err_code: $err_str";
}

sub DESTROY {
  my ($self) = @_;
  print __PACKAGE__."::DESTROY called (win=$self->{glfwwindow})\n" if $PDL::Graphics::TriD::verbose;
  @{ $self->{xevents} } = ();
  return if !defined $self->{glfwwindow};
  glfwDestroyWindow($self->{glfwwindow}); # removes callbacks
  delete $self->{glfwwindow};
}

sub _display_wrapper {
   my ($win) = @_;
   if ( defined($win) and defined($winObjects{$win}) ) {
      $winObjects{$win}->display;
   }
}

sub _fake_exit_handler {
   my ($win) = shift;
   print "_fake_exit_handler: clicked for window $win\n" if $PDL::Graphics::TriD::verbose;
   push @fakeXEvents, [ 'destroy', @_ ];
}

sub _fake_ConfigureNotify {
   print "_fake_ConfigureNotify: got (@_)\n" if $PDL::Graphics::TriD::verbose;
   push @fakeXEvents, [ 'reshape', @_[1,2] ];
}

sub _fake_KeyPress {
   print "_fake_KeyPress: got (@_)\n" if $PDL::Graphics::TriD::verbose;
   push @fakeXEvents, [ 'keypress', chr($_[1]) ];
}

{
  my @button_to_mask = (1<<8, 1<<9, 1<<10);
  my $fake_mouse_state = 0;
  my ($lastx, $lasty);

  sub _fake_button_event {
    print "_fake_button_event: got (@_)\n" if $PDL::Graphics::TriD::verbose;
    my ($win, $button, $action) = @_;
    my $but = $button == GLFW_MOUSE_BUTTON_LEFT ? 0 :
      $button == GLFW_MOUSE_BUTTON_MIDDLE ? 1 :
      $button == GLFW_MOUSE_BUTTON_RIGHT ? 2 :
      return;
    my $ev = $action == GLFW_PRESS ? 'buttonpress' :
      $action == GLFW_RELEASE ? 'buttonrelease' :
      return;
    my $mask = $button_to_mask[$but];
    if ( $ev eq 'buttonpress' ) {       # a press
      $fake_mouse_state |= $mask;
    } elsif ( $_[1] == 1 ) {  # a release
      $fake_mouse_state &= ~$mask;
    }
    push @fakeXEvents, [ $ev, $but+1, $lastx, $lasty ];
  }

  sub _fake_scroll_event {
    print "_fake_scroll_event: got (@_)\n" if $PDL::Graphics::TriD::verbose;
    my ($win, $xoffset, $yoffset) = @_;
    my $but = $yoffset > 0 ? 3 : 4;
    push @fakeXEvents, [ 'buttonpress', $but+1, $lastx, $lasty ];
    push @fakeXEvents, [ 'buttonrelease', $but+1, $lastx, $lasty ];
  }

  sub _fake_MotionNotify {
    print "_fake_MotionNotify: got (@_)\n" if $PDL::Graphics::TriD::verbose;
    my ($win, $xpos, $ypos) = @_;
    my $but = -1;
    SWITCH: {
      for (0..2) {
        $but = $_, last SWITCH if $fake_mouse_state & $button_to_mask[$_];
      }
      print "No button pressed...\n" if $PDL::Graphics::TriD::verbose;
    }
    ($lastx, $lasty) = ($xpos, $ypos);
    return if $but < 0;
    push @fakeXEvents, [ 'motion', $but, $xpos, $ypos ];
  }

}

sub event_pending {
   my($self) = @_;
   # monitor state of @fakeXEvents, return number on queue
   glfwPollEvents() if !@{$self->{xevents}};
   print STDERR "OO::event_pending: have " .  scalar( @{$self->{xevents}} ) . " xevents\n" if $PDL::Graphics::TriD::verbose > 1;
   scalar @{$self->{xevents}};
}

sub next_event {
  my($self) = @_;
  glfwWaitEvents() while !@{$self->{xevents}}; # not all GLFW events are ours
  # Extract first event from fake event queue and return
  @{ shift @{$self->{xevents}} };
}

sub swap_buffers {
  my ($this) = @_;
  glfwSwapBuffers($this->{glfwwindow});
}

sub set_window {
  my ($this) = @_;
  # set context to current window (for multiwindow support)
  glfwMakeContextCurrent($this->{glfwwindow});
}

1;
