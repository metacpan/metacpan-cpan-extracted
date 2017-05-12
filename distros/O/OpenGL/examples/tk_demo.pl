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
use strict;
use Tk;
use OpenGL;

my $top = MainWindow->new();

my $kid;

sub CreateKid { 
  my $par = shift;
  my $id = $par->WindowId;
  print " window id: $id -> ", (sprintf '%#x', $$id),"\n";
  my ($w, $h) = ($par->Width, $par->Height);
  my ($xbord, $ybord) = (int($w/8), int($h/8));
  $kid = glpOpenWindow( x => $xbord, y => $ybord, width=> ($w-2*$xbord),
			height=> ($h-2*$ybord),parent=>$$id);
}

sub ResetKid {
  return unless $kid;
  my $par = shift;
  my $w = $par->Width;
  my $h = $par->Height;
  my ($xbord, $ybord) = (int($w/8), int($h/8));
  $w = $w-2*$xbord;
  $h = $h-2*$ybord;
  glpMoveResizeWindow($xbord,$ybord,$w,$h);
  glViewport(0,0,$w,$h);
  print "viewport $w x $h, origin $xbord, $ybord\n";
  DrawKid();
}

my $pending = 0;
sub DrawKid {
	return unless $kid;
	return if $pending++;
	$top->DoWhenIdle(\&DrawKid_do);
}
sub DrawKid_do {
	return unless $kid;
	$pending = 0;
	print "Drawing...\n";
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
	glFlush();
}
sub DrawKid1 {
	return unless $kid;
	print "Visibility change\n";
	DrawKid;
}
sub DrawKid2 {
	return unless $kid;
	print "Expose change\n";
	DrawKid;
}

sub DoKey
{
	my $w = shift;
	return if $kid;
	CreateKid $w;
	DrawKid;
}

sub DoMouse
{
	shift;
	my ($b,$p) = (shift,shift);
	print "mouse-$b $p\n";
}


$top->bind("<Any-KeyPress>",\&DoKey);
$top->bind("<Any-ButtonPress>",[\&DoMouse, Ev('b'), Ev('@')]);
$top->bind("<KeyPress-q>",[$top, 'destroy']);
$top->bind("<KeyPress-Escape>",[$top, 'destroy']);
$top->bind("<Configure>",\&ResetKid);
$top->bind("<Visibility>",\&DrawKid1);
$top->bind("<Expose>",\&DrawKid2);

Tk::MainLoop();
