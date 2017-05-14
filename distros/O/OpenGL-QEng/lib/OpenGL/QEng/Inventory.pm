###  $Id: $
####------------------------------------------
## @file
# Display Current inventory and handle inventory controls
#

## @class Inventory
# Display Current inventory and handle inventory controls
package OpenGL::QEng::Inventory;

use strict;
use warnings;
use OpenGL::QEng::GUIButton;
use OpenGL::QEng::GUILabel;

use base qw/OpenGL::QEng::GUIFrame/;

#####
##### Class Methods - called as Class->function($a,$b,$c)
#####

## @cmethod % new()
# Create an Inventory
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = OpenGL::QEng::GUIFrame->new();
  $self->{x}             = 10;
  $self->{y}             = 10;
  $self->{width}         = 50; #???
  $self->{height}        = 60; #???
  $self->{max_items}     = 4;
  $self->{buttons}       = undef; # array of buttons to hold inventory items
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self->setupInventory;

  $self;
}

#####
##### Object Methods
#####

#--------------------------------------------------
## @method setupInventory($self)
# display the inventory pane
# @event_ref set up to send 'dropit' from button
# @event_ref set up to send 'examit' from button
sub setupInventory {
  my ($self) = @_;

  my $bw     = 50;
  my $bh     = 32;
  my $iw     = 60;
  my $ih     = 40;
  my $ydelta = $ih + 8;
  my $xleft  = $self->x;
  my $xright = $self->x + $iw + 8;
  my $y      = $self->y;

  $self->adopt(OpenGL::QEng::GUILabel->new(text=>"Inventory",
			     textColor=>'white',
			     x=>$xleft, y=>$y,
			     width=>2*$iw, height=>$bh,
			     font=>OpenGL::GLUT_BITMAP_HELVETICA_18));
  $y += 30;
  $self->adopt(OpenGL::QEng::GUILabel->new(text=>"  Now Using->",
			     textColor=>'white',
			     x=>$xleft, y=>$y,
			     width=>$iw, height=>$ih));
  $self->{usingb} =
    OpenGL::QEng::GUIiButton->new(text=>"empty",
		    texture       => ['brass_btn','brass_btn'],
		    relief=>'flat',
		    #background=>'lightgreen',
		    color         => 'beige',
		    textColor     => 'black',
		    x=>$xright, y=>$y, width=>$iw, height=>$ih);
  $self->adopt($self->{usingb});

  $y += $ydelta;
  $self->adopt(OpenGL::QEng::GUIiButton->new(text=>' Drop  ',
			       texture=>['brass_btn_up','brass_btn_dn'],
			       textColor     => 'black',
			       clickCallback=>
			       sub {$self->send_event('dropit')},
			       #background=>'lightgreen',
			       x=>$xleft+4, y=>$y,
			       width=>$bw, height=>$bh));

  $self->adopt(OpenGL::QEng::GUIiButton->new(text=>'Examine',
			       texture=>['brass_btn_up','brass_btn_dn'],
			       textColor     => 'black',
			       clickCallback=>
			       sub {$self->send_event('tell_using')},
			       #background=>'lightgreen',
			       x=>$xright+5, y=>$y,
			       width=>$bw, height=>$bh));
  $y += 20+$ydelta/2;
  for (my $i=0; $i<$self->max_items; ) {
    for (0..1) {
      $self->{buttons}[$i] =
	OpenGL::QEng::GUIiButton->new(text         => "Inv # $i",
			x             => ($_ == 0) ? $xleft : $xright,
			y             => $y,
			height        => $ih,
			width         => $iw,
			relief        => 'flat',
			color         => 'beige',
			texture       => ['brass_btn','brass_btn'],
			textColor     => 'black',
			clickCallback =>
			[sub {$self->send_event('team_use',1+shift)},$i],);
      $self->adopt($self->{buttons}[$i++]);
    }
    $y += $ydelta;
  }
}

#--------------------------------------------------
 sub show {
   my ($self,$team) = @_;

   #print STDERR 'show() c.f.: ',join(':',caller),"\n";
   for my $b (@{$self->{buttons}}) {undef $b->{text}}
   if (defined $team->holds &&
       defined $team->using &&
       defined $team->holds->[$team->using]) {
       $self->{usingb}->text($team->holds->[$team->using]->textName);
     }
   else {
     $self->{usingb}->text('empty');
   }
   my $i = 0;
   for my $obj (@{$team->contains}) {
     $self->{buttons}[$i++]->text($obj->textName);
   }
 }

#==================================================================
###
### Test Driver
###
if (not defined caller()) {
  package main;

  require OpenGL;
  require GUIMaster;
  require Team;
  #require Map;

  my $winsize = 600;
  my $winw = 200;
  my $winh = $winsize;

  OpenGL::glutInit;
  OpenGL::glutInitDisplayMode(OpenGL::GLUT_RGB   |
			      OpenGL::GLUT_DEPTH |
			      OpenGL::GLUT_DOUBLE);
  OpenGL::glutInitWindowSize($winsize+200,$winsize);
  OpenGL::glutInitWindowPosition(200,100);
  my $win1 = OpenGL::glutCreateWindow("OpenGL Inventory Test");
  glViewport(0,0,$winw,$winh);

  my $GUIRoot = OpenGL::QEng::GUIMaster->new(wid=>$win1, x=>$winsize, y=>0,
			       width=>200, height=>$winsize);

  # Create a inventory object
  my $v = OpenGL::QEng::Inventory->new(max_items=>14);
  $GUIRoot->adopt($v);
  #my $map = OpenGL::QEng::Map->new(zsize=>24,xsize=>24);
  my $team = OpenGL::QEng::Team->new(x=>4,z=>4);

  glutDisplayFunc(      sub{ $GUIRoot->GUIDraw(@_) });
  glutMouseFunc(        sub{ $GUIRoot->mouseButton(@_) });
  glutMotionFunc(       sub{ $GUIRoot->mouseMotion(@_) });
  glutPassiveMotionFunc(sub{ $GUIRoot->mousePassiveMotion(@_) });

  glutMainLoop;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Inventory -- 2D GL GUI frame: collection of buttons and inventory item tokens

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

