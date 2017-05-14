###  $Id: $
####------------------------------------------
## @file
# Define Control Class

## @class Control
# Game control panel content handler
# @event_ref handle 'cpush' by pushing another control button pattern
# into the control area
# @event_ref handle 'cpop' by popping the prior control button pattern
# into the control area

package OpenGL::QEng::Control;

use strict;
use warnings;
use OpenGL qw/:all/;
use OpenGL::QEng::GUIiButton;

use base qw/OpenGL::QEng::GUIFrame/;

#-----------------------------------------------------------
## @cmethod Control new()
#
#Create a new instance of a Control with the given components
# $style     - Style of command button set
#
sub new {
  my ($class, @props) = @_;

  my $self = OpenGL::QEng::GUIFrame->new;
  $self->{style}   = 'move';
  $self->{width}   = 128;
  $self->{height}  = 216;
  $self->{buttons} = undef;
  $self->{stack}   = [];
  $self->{repeat}  = undef;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self->_present;
  $self->register_events;

  $self;
}

#-----------------------------------------------------------
sub register_events {
  my ($self) = @_;

  for my $event (['cpush' => sub{$_[0]->cpush($_[4])},],
		 ['cpop'  => sub{$_[0]->cpop}, ],
		) {
    $self->{event}->callback($self,$event->[0],$event->[1]);
  }
}

{;
 # button definitions to send events
 my %BUTS =
   ('move' =>
    [['go_forward',      0,1,['step',0.3,0.0], '<Up>',       'repeat'],
     ['go_back',         2,1,['step',0.3,180.0],'<Down>',    'repeat'],
     ['turn_right',      0,2,['turn',+90],     '<Right>',    undef   ],
     ['turn_left',       0,0,['turn',-90],     '<Left>',     undef   ],
     ['turn_around',     1,1,['turn',180],     '<Control_A>',undef   ],
     ['go_right',        2,2,['step',+0.3,+90],'<Control_R>','repeat'],
     ['go_left',         2,0,['step',+0.3,-90],'<Control_L>','repeat'],
     ['turn_left_some',  1,0,['turn',-3.0],    '<Left>',     'repeat'],
     ['turn_right_some', 1,2,['turn',+3.0],    '<Right>',    'repeat'],
     ['Save',            4,0,['saveGame'],     ' ',          'text'  ],
     ['Load',            4,2,['loadGame'],     ' ',          'text'  ],
     ['Quit',            4,1,['quit'],         '<Control_Q>','text'  ],
     ['event',           3,0,['special'],      ' ',          'text'  ],
    ],

    'yesno' => [
		['Yes',    1,0,['answer','Yes'],  '<Y>',    'text'],
		['No',     1,2,['answer','No'],   '<N>',    'text'],
		['Quit',   3,1,['quit'],   '  <Control_Q>', 'text'],
	       ],

    'blank' => [
		['Quit',   3,1,['quit'],  '<Control_Q>', 'text'],
	       ],
   );

#-----------------------------------------------------------
## @nethod _present
# Set up control buttons and associated events
 sub _present {
   my ($self) = @_;

   undef $self->{repeat};
   my ($w,$h) = (40,40);

   $self->{buttons} = $BUTS{$self->style};
   my $i = 0;
   foreach my $bi ( @{$self->{buttons}} ) {
     ($i++,next) if $bi->[5] && $bi->[5] eq 'blank';
     ($i++,next) if $bi->[3][0] eq 'special' and not $ENV{WIZARD};

     my ($tex,$label);
     my $pcb;			                    # PressCallBack
     my $ccb = sub {#print STDERR "ccb for $bi->[0]\n";
		    $self->send_event(@{$bi->[3]})}; # ClickCallBack

     if ($bi->[5] and $bi->[5] eq 'text') {
       $label = $bi->[0];
       $tex = 'brass_btn';
     }
     else {
       $tex = $bi->[0];
     }
     if ($bi->[5] && $bi->[5] eq 'repeat') {
       my $ri = $i;
       $pcb     = sub {#print STDERR "pcb for $bi->[0]\n";
		       $self->{repeat} = $ri};
       $ccb     = sub {undef $self->{repeat}};
     }
     $self->adopt(OpenGL::QEng::GUIiButton->new(text         => $label,
				  textColor    => 'black',
				  texture      => [$tex.'_up',$tex.'_dn',],
				  x            => $bi->[2]*($w+4)+$self->x,
				  y            => $bi->[1]*($h+4)+$self->y,
				  width        => $w,
				  height       => $h,
				  pressCallback=> $pcb,
				  clickCallback=> $ccb,
				 ));
     $i++;
   }
 }
}

#-----------------------------------------------------------
sub stateTest {
  my ($self) = @_;

  return unless defined $self->{repeat};
  #print STDERR "repeating event ",time,"\n";
  $self->send_event(@{ $self->{buttons}[$self->{repeat}][3] })
    if defined($self->{repeat});
}

#-----------------------------------------------------------
## @method cpush($style)
#Push a new control panel onto the game.
#Available styles 'yesno', 'action','move', 'item'
#
sub cpush {
  my ($self,$style) = @_;

  push @{$self->{stack}}, $self->{style};
  undef $self->{repeat};
  undef $self->{children};
  $self->{style} = $style;
  $self->_present;
}

#-----------------------------------------------------------
## @method cpop()
#
#Pop prior control panel with callback onto the game.
#
sub cpop {
  my ($self) = @_;

  if (@{$self->{stack}}) {
    undef $self->{repeat};
    undef $self->{children};
    $self->{style} = pop @{$self->{stack}};
    $self->_present;
  }
  else {warn 'cpop with empty stack'}
  $self;
}

#-----------------------------------------------------------
sub keyboard {
  my ($self, $key, $x, $y) = @_;
  die "keyboard($self) from ",join(':',caller), unless ref $self;

  return unless ref $self;
  if    ($key == 100) { # <-
    $self->send_event('pivot',-3.0);
  }
  elsif ($key == 101) { # ^
    $self->send_event('step', 0.3,0);
  }
  elsif ($key == 102) { # ->
    $self->send_event('pivot',+3.0);
  }
  elsif ($key == 103) { # v
    $self->send_event('step', 0.3,180);
  }
  elsif ($key == 104) { # PgUp
    $self->send_event('turn',+90.0);
  }
  elsif ($key == 105) { # PgDn
    $self->send_event('step',+0.3,+90);
  }
  elsif ($key == 106) { # Home
    $self->send_event('turn',-90.0);
  }
  elsif ($key == 107) { # End
    $self->send_event('step',+0.3,-90);
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

  my $winsize = 400;
  OpenGL::glutInit;
  OpenGL::glutInitDisplayMode(OpenGL::GLUT_RGB   |
			      OpenGL::GLUT_DEPTH |
			      OpenGL::GLUT_DOUBLE);
  OpenGL::glutInitWindowSize($winsize,$winsize);
  OpenGL::glutInitWindowPosition(200,100);

  my $win1 = OpenGL::glutCreateWindow("OpenGL Control Test");
  glViewport(0,0,$winsize,$winsize);

  my $GUIRoot = OpenGL::QEng::GUIMaster->new(wid=>$win1,
			       x=>$winsize, y=>0,
			       width=>$winsize, height=>$winsize);
  glutDisplayFunc(\&GUIMaster::GUIDraw);
  $GUIRoot->adopt(OpenGL::QEng::Control->new($GUIRoot,'move',100,100));

  $GUIRoot->adopt(OpenGL::QEng::GUIButton->new(x=>150,y=>300,width=>100,height=>30,
				 text=>'Quit',
				 clickCallback=>sub{exit(0)},
				 pressCallback=>
				 sub{print STDERR "Waiting for Release\n";}));

  glutDisplayFunc(sub{ $GUIRoot->GUIDraw(@_) });
  glutMouseFunc(  sub{ $GUIRoot->mouseButton(@_) });

  glutMainLoop;
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Control -- 2D GL GUI frame: collection of control buttons

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

