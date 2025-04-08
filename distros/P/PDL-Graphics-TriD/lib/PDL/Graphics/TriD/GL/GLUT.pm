package PDL::Graphics::TriD::GL::GLUT;

use strict;
use warnings;
use OpenGL::GLUT qw( :all );
use OpenGL::Config;

our @ISA = qw(PDL::Graphics::TriD::GL);
my (@fakeXEvents, @winObjects);

sub new {
  my ($class,$options,$window_obj) = @_;
  my $self = $class->SUPER::new($options,$window_obj);
  print STDERR "Creating GLUT OO window\n" if $PDL::Graphics::TriD::verbose;
  glutInit() unless done_glutInit();        # make sure glut is initialized
  $self->{xevents} = \@fakeXEvents;
  $self->{winobjects} = \@winObjects;
  $self->_init_glut_window($window_obj);
  $self;
}

sub _init_glut_window {
  my ($self, $window_obj) = @_;
  my $p = $self->{Options};
  OpenGL::GLUT::glutInitWindowPosition( $p->{x}, $p->{y} );
  OpenGL::GLUT::glutInitWindowSize( $p->{width}, $p->{height} );
  OpenGL::GLUT::glutInitDisplayMode( OpenGL::GLUT::GLUT_RGBA() | OpenGL::GLUT::GLUT_DOUBLE() | OpenGL::GLUT::GLUT_DEPTH() );        # hardwire for now
  if ($^O ne 'MSWin32' and not $OpenGL::Config->{DEFINE} =~ /-DHAVE_W32API/) { # skip these MODE checks on win32, they don't work
     if (not OpenGL::GLUT::glutGet(OpenGL::GLUT::GLUT_DISPLAY_MODE_POSSIBLE()))
     {
        warn "glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA) not possible";
        warn "...trying without GLUT_ALPHA";
        # try without GLUT_ALPHA
        OpenGL::GLUT::glutInitDisplayMode( OpenGL::GLUT::GLUT_RGBA() | OpenGL::GLUT::GLUT_DOUBLE() | OpenGL::GLUT::GLUT_DEPTH() );
        if ( not OpenGL::GLUT::glutGet( OpenGL::GLUT::GLUT_DISPLAY_MODE_POSSIBLE() ) )
        {
           die "display mode not possible";
        }
     }
  }
  $self->{glutwindow} = OpenGL::GLUT::glutCreateWindow( "GLUT TriD" );
  OpenGL::GLUT::glutSetWindowTitle("GLUT TriD #$self->{glutwindow}");
  OpenGL::GLUT::glutReshapeFunc( \&_pdl_fake_ConfigureNotify );
  OpenGL::GLUT::glutCloseFunc( \&_pdl_fake_exit_handler );
  OpenGL::GLUT::glutKeyboardFunc( \&_pdl_fake_KeyPress );
  OpenGL::GLUT::glutMouseFunc( \&_pdl_fake_button_event );
  OpenGL::GLUT::glutMotionFunc( \&_pdl_fake_MotionNotify );
  OpenGL::GLUT::glutDisplayFunc( \&_pdl_display_wrapper );
  OpenGL::GLUT::glutSetOption(OpenGL::GLUT::GLUT_ACTION_ON_WINDOW_CLOSE(), OpenGL::GLUT::GLUT_ACTION_GLUTMAINLOOP_RETURNS()) if OpenGL::GLUT::_have_freeglut();
  OpenGL::GLUT::glutMainLoopEvent();       # pump event loop so window appears
  if ($PDL::Graphics::TriD::verbose) {
    print "gdriver: Got TriD::GL object(GLUT window ID# " . $self->{glutwindow} . ")\n";
  }
  $self->{winobjects}->[$self->{glutwindow}] = $window_obj;      # circular ref
}

sub DESTROY {
  my ($self) = @_;
  return if !OpenGL::GLUT::done_glutInit();
  print __PACKAGE__."::DESTROY called (win=$self->{glutwindow}), GLUT says ", OpenGL::GLUT::glutGetWindow(), "\n" if $PDL::Graphics::TriD::verbose;
  OpenGL::GLUT::glutMainLoopEvent(); # pump to deal with any clicking "X"
  if (!OpenGL::GLUT::glutGetWindow()) {
    # "X" was clicked, clear queue then stop
    @{ $self->{xevents} } = ();
    OpenGL::GLUT::glutMainLoopEvent(); # pump once
    return;
  }
  OpenGL::GLUT::glutSetWindow($self->{glutwindow});
  OpenGL::GLUT::glutReshapeFunc();
  OpenGL::GLUT::glutCloseFunc();
  OpenGL::GLUT::glutKeyboardFunc();
  OpenGL::GLUT::glutMouseFunc();
  OpenGL::GLUT::glutMotionFunc();
  OpenGL::GLUT::glutDestroyWindow($self->{glutwindow});
  OpenGL::GLUT::glutMainLoopEvent() for 1..2; # pump so window gets actually closed
  delete $self->{glutwindow};
}

sub _pdl_display_wrapper {
   my ($win) = OpenGL::GLUT::glutGetWindow();
   if ( defined($win) and defined($winObjects[$win]) ) {
      $winObjects[$win]->display();
   }
}

sub _pdl_fake_exit_handler {
   my ($win) = shift;
   print "_pdl_fake_exit_handler: clicked for window $win\n" if $PDL::Graphics::TriD::verbose;
   push @fakeXEvents, [ 'destroy', @_ ];
}

sub _pdl_fake_ConfigureNotify {
   print "_pdl_fake_ConfigureNotify: got (@_)\n" if $PDL::Graphics::TriD::verbose;
   OpenGL::GLUT::glutPostRedisplay();
   push @fakeXEvents, [ 'reshape', @_ ];
}

sub _pdl_fake_KeyPress {
   print "_pdl_fake_KeyPress: got (@_)\n" if $PDL::Graphics::TriD::verbose;
   push @fakeXEvents, [ 'keypress', chr($_[0]) ];
}

{
   my @button_to_mask = (1<<8, 1<<9, 1<<10, 1<<11);
   my $fake_mouse_state = 16;  # default have EnterWindowMask set;
   my $last_fake_mouse_state;

   sub _pdl_fake_button_event {
      print "_pdl_fake_button_event: got (@_)\n" if $PDL::Graphics::TriD::verbose;
      $last_fake_mouse_state = $fake_mouse_state;
      my $mask = $button_to_mask[$_[0]];
      return if !defined $mask; # MacOS sometimes gives button ID 5
      if ( $_[1] == 0 ) {       # a press
         $fake_mouse_state |= $mask;
         push @fakeXEvents, [ 'buttonpress', $_[0]+1, @_[2,3], -1, -1, $last_fake_mouse_state ];
      } elsif ( $_[1] == 1 ) {  # a release
         $fake_mouse_state &= ~$mask;
         push @fakeXEvents, [ 'buttonrelease', $_[0]+1 , @_[2,3], -1, -1, $last_fake_mouse_state ];
      } else {
         die "ERROR: _pdl_fake_button_event got unexpected value!";
      }
   }

   sub _pdl_fake_MotionNotify {
      print "_pdl_fake_MotionNotify: got (@_)\n" if $PDL::Graphics::TriD::verbose;
      my $but = -1;
      SWITCH: {
        for (0..3) {
          $but = $_, last SWITCH if $fake_mouse_state & $button_to_mask[$_];
        }
        print "No button pressed...\n" if $PDL::Graphics::TriD::verbose;
      }
      push @fakeXEvents, [ 'motion', $but, @_ ];
   }

}

sub event_pending {
   my($self) = @_;
   # monitor state of @fakeXEvents, return number on queue
   OpenGL::GLUT::glutMainLoopEvent() if !@{$self->{xevents}};
   print STDERR "OO::event_pending: have " .  scalar( @{$self->{xevents}} ) . " xevents\n" if $PDL::Graphics::TriD::verbose > 1;
   scalar( @{$self->{xevents}} );
}

sub next_event {
  my($self) = @_;
  while ( !scalar( @{$self->{xevents}} ) ) {
    # If no events, we keep pumping the event loop
    OpenGL::GLUT::glutMainLoopEvent();
  }
  # Extract first event from fake event queue and return
  @{ shift @{$self->{xevents}} };
}

sub glpRasterFont {
  my($this,@args) = @_;
  print STDERR "gdriver: window_type => 'glut' so not actually setting the rasterfont\n" if $PDL::Graphics::TriD::verbose;
  eval { OpenGL::GLUT_BITMAP_8_BY_13() };
}

sub swap_buffers {
  my ($this) = @_;
  OpenGL::GLUT::glutSwapBuffers();
}

sub set_window {
  my ($this) = @_;
  # set GLUT context to current window (for multiwindow support)
  OpenGL::GLUT::glutSetWindow($this->{glutwindow});
}

1;
