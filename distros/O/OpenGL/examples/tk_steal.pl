#!/usr/local/bin/perl 
#
# This is an example of combining the tk module and opengl
# You have to have TK installed for this to work.
# this program opens a window and when you hit a key in
# the window a callback that does some opengl stuff is
# executed.  
# Yes, this is a totally lame program, but its a proof
# of concept sort of thing.
# We'll get something better next time :-)
#

use lib ('blib');
use Tk;
use OpenGL;

eval { $top = MainWindow->new(-container => 1, -bg => 'white') }
  or $top = MainWindow->new();
#$top = MainWindow->new();
#$top->configure(-container => 1);

my $kid;

sub CreateKid {
  return if $kid;
  my $par = shift;
  $id = $par->WindowId;
  print " window id: $id -> ", (sprintf '%#x', $$id),"\n";
  $w = $par->Width;
  $h = $par->Height;
  glpOpenWindow(width=>$w,height=>$h,parent=>$$id, steal => $par->cget('-container'));
  $kid = 1;
}

sub ResetKid {
  return unless $kid;
  $w = $top->Width;
  $h = $top->Height;
  glViewport(0,0,$w,$h);
  # glFlush();			# Does not help...
  print "viewport change: $w,$h\n";
  DrawKid();
}
sub DrawKid {
  return if $redraw_pending++;
  $top->DoWhenIdle(\&DrawKid1);
}
sub DrawKid1 {
  print STDERR "enter draw $w,$h\n";
  $redraw_pending = 0;
  return unless $kid;
	glClearColor(0,0,1,1);
	glClear(GL_COLOR_BUFFER_BIT);
	glOrtho(-1,1,-1,1,-1,1);

	glColor3f(1,0,0);
	glBegin(GL_POLYGON);
	  glVertex2f(-0.5,-0.5);
	  glVertex2f(-0.5, 0.5);
	  glVertex2f( 0.5, 0.5);
	  glVertex2f( 0.5,-0.5);
	glEnd();
	glColor3f(0,1,0);
	glBegin(GL_POLYGON);
	  glVertex2f(-1,-1);
	  glVertex2f(1,0.1);
	  glVertex2f(1,-0.1);
	glEnd();
	glBegin(GL_POLYGON);
	  glVertex2f(-1,-1);
	  glVertex2f(0.1,1);
	  glVertex2f(-0.1,1);
	glEnd();
	glBegin(GL_POLYGON);
	  glVertex2f(1,-1);
	  glVertex2f(-1,0.1);
	  glVertex2f(-1,-0.1);
	glEnd();
	glBegin(GL_POLYGON);
	  glVertex2f(1,-1);
	  glVertex2f(0.1,1);
	  glVertex2f(-0.1,1);
	glEnd();
	glBegin(GL_POLYGON);
	  glVertex2f(-1,1);
	  glVertex2f(1,0.1);
	  glVertex2f(1,-0.1);
	glEnd();
	glBegin(GL_POLYGON);
	  glVertex2f(-1,1);
	  glVertex2f(0.1,-1);
	  glVertex2f(-0.1,-1);
	glEnd();
	glBegin(GL_POLYGON);
	  glVertex2f(1,1);
	  glVertex2f(-1,0.1);
	  glVertex2f(-1,-0.1);
	glEnd();
	glBegin(GL_POLYGON);
	  glVertex2f(1,1);
	  glVertex2f(0.1,-1);
	  glVertex2f(-0.1,-1);
	glEnd();
	glFlush();
}
sub DoKey
{
  return if $kid;
  my $w = shift;
  CreateKid $w;
  DrawKid;
}

$top->bind("<Any-KeyPress>",\&DoKey);
$top->bind("<KeyPress-q>",[$top,'destroy']);
$top->bind("<KeyPress-Escape>",[$top,'destroy']);
$top->bind("<Configure>",\&ResetKid);
$top->bind("<Visibility>",\&DrawKid);

Tk::MainLoop();
