package PDL::Graphics::TriD::GL::GLX;

use strict;
use warnings;
use OpenGL qw/ :glxconstants /;

our @ISA = qw(PDL::Graphics::TriD::GL);

sub new {
  my ($class,$options,$window_obj) = @_;
  my @db = OpenGL::GLX_DOUBLEBUFFER;
  if ($PDL::Graphics::TriD::offline) {$options->{x} = -1; @db=()}
  $options->{attributes} = [GLX_RGBA, @db,
			    GLX_RED_SIZE,1,
			    GLX_GREEN_SIZE,1,
			    GLX_BLUE_SIZE,1,
			    GLX_DEPTH_SIZE,1,
			    # Alpha size?
			   ] unless defined $options->{attributes};
  $options->{mask} = (KeyPressMask | ButtonPressMask |
			 ButtonMotionMask | ButtonReleaseMask |
			 ExposureMask | StructureNotifyMask |
			 PointerMotionMask) unless defined $options->{mask};
  my $self = $class->SUPER::new($options,$window_obj);
  print STDERR "Creating X11 OO window\n" if $PDL::Graphics::TriD::verbose;
  my $p = $self->{Options};
  my $win = OpenGL::glpcOpenWindow(
     $p->{x},$p->{y},$p->{width},$p->{height},
     $p->{parent},$p->{mask}, $p->{steal}, @{$p->{attributes}});
  @$self{keys %$win} = values %$win;
  $self;
}

sub event_pending {
  my ($self) = @_;
  OpenGL::XPending($self->{Display});
}

my %ev2str = (
  VisibilityNotify() => 'visible',
  Expose() => 'visible',
  ConfigureNotify() => 'reshape',
  DestroyNotify() => 'destroy',
  KeyPress() => 'keypress',
  MotionNotify() => 'motion',
  ButtonPress() => 'buttonpress',
  ButtonRelease() => 'buttonrelease',
);
sub next_event {
  my ($self) = @_;
  my @e = OpenGL::glpXNextEvent($self->{Display});
  if ($e[0] == MotionNotify) {
    my $but = -1;
    SWITCH: {
      $but = 0, last SWITCH if $e[1] & Button1Mask;
      $but = 1, last SWITCH if $e[1] & Button2Mask;
      $but = 2, last SWITCH if $e[1] & Button3Mask;
      $but = 3, last SWITCH if $e[1] & Button4Mask;
      print "No button pressed...\n" if $PDL::Graphics::TriD::verbose;
    }
    $e[1] = $but;
  }
  $e[0] = $ev2str{$e[0]};
  @e;
}

sub swap_buffers {
  my ($this) = @_;
  OpenGL::glXSwapBuffers($this->{Window},$this->{Display});  # Notice win and display reversed [sic]
}

1;
