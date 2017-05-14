#  $Id:  $

## @file
# Implements Key class

## @class Key
# Key which may open Doors or chests. Comes in many types and colors.
#

package OpenGL::QEng::Key;

use strict;
use warnings;
use OpenGL::QEng::glShapeP2p;

use base qw/OpenGL::QEng::SimpleThing/;

#--------------------------------------------------
# @cmethod Key new($class, @arg)
# Create a simpleThing of given type at given location
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my %ktexture = ('red'=>'red_key', 'black'=>'key','iron'=>'key',
		  'green'=>'green_key', 'brass'=>'key','glass'=>'key',
		  'wooden'=>'key', 'odd'=>'key', 'toothy'=>'key',
		  'silver'=>'key', 'heavy'=>'key', 'round'=>'key',
		  'gold'=>'key', 'rusty'=>'key', 'old'=>'key',
		  'worn'=>'key', 'red plastic'=>'key', 'green plastic'=>'key');

  my $self = OpenGL::QEng::SimpleThing->new;
  $self->{type}    = 'iron'; # Type of the key
  $self->{hang}    = 0;
  $self->{texture} = undef;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self->register_events;

  if (!defined($ktexture{$self->type})) {
    print "Unknown key type $self->type\n";
  } else {
    $self->{texture} = $ktexture{$self->type};
  }
  $self;
};

#------------------------------------------
sub is_at {
  my ($self,$where) = @_;

  if (@_ > 1) {
    $self->{is_at} = $where;
    $self->{hang} = 0
      unless $where->can('can_hang') && $where->can_hang($self);
  }
  $self->{is_at};
}

#------------------------------------------
## @method $ desc($self)
# Return a text description of this object
sub desc {
  my ($self) = @_;

  if (defined $self->type) {
    return "A key that looks ".$self->type;
  }
  return "Weird key";
}

#----------------------------------
## @method $ textName($self)
# Return a label for this thing
sub textName {
  my $self = shift @_;

  if (defined $self->type) {
    return $self->type."\nkey";
  }
  return "Weird key";
}

#------------------------------------------
{my $dl;			#closure over $dl
 my $chkErr = 01;
 my %kcolor = ('red'=>'red','black'=>'black','iron'=>'darkgray','green'=>'green',
	       'brass'=>'goldenrod1','glass'=>'white','wooden'=>'brown','odd'=>'purple',
	       'toothy'=>'cream','silver'=>'lightgray','heavy'=>'gray',
	       'round'=>'black','gold'=>'orange','rusty'=>'brown','old'=>'gray',
	       'worn'=>'gray','red plastic'=>'red', 'green plastic'=>'green');

 sub draw {
   my ($self, $mode) = @_;

   if ($mode == OpenGL::GL_SELECT) {
     OpenGL::glLoadName($self->{GLid});
   }
# Adjust the key origin from the end of the handle to the center and
# from the middle of the key to the bottom
   OpenGL::glTranslatef($self->{x}-0.6,$self->{y}+0.25,$self->{z});
   OpenGL::glRotatef(+270,0,0,1) if $self->{hang};
   OpenGL::glRotatef(90,1,0,0) if $self->{hang};
   OpenGL::glRotatef($self->{yaw},0,1,0) if $self->{yaw};

   $self->setColor($kcolor{$self->{type}} or 'gray');

   if ($dl) {
     OpenGL::glCallList($dl);
     $chkErr && $self->tErr('draw Key1');
   } else {
     $dl = $self->getDLname();
     OpenGL::glNewList($dl,OpenGL::GL_COMPILE);

     OpenGL::QEng::glShapeP2p::drawCyl(1.20,0,0,0.4,0,0,0.07,0.07);
     $chkErr && $self->tErr('draw Key2');
     OpenGL::QEng::glShapeP2p::drawBlock(1.15,0.02,-0.05,1.05,+0.05,-0.25);
     $chkErr && $self->tErr('draw Key3');
     OpenGL::QEng::glShapeP2p::drawBlock(1.05,.02,-.05,.95,+.05,-0.125);
     $chkErr && $self->tErr('draw Key4');

     OpenGL::QEng::glShapeP2p::drawBlock(.95,.02,-.05,.85,+.05,-.25);
     $chkErr && $self->tErr('draw Key5');
     OpenGL::QEng::glShapeP2p::drawBlock(.45,.07,-.2, .35,+0.0,+.2);
     OpenGL::QEng::glShapeP2p::drawBlock(.35,.07,+.1, .10,+0.0,+.2);
     OpenGL::QEng::glShapeP2p::drawBlock(.35,.07,-.1, .10,+.00,-.2);
     OpenGL::QEng::glShapeP2p::drawBlock(.10,.07,-.2,0,+0.0,+.2);
     OpenGL::glEndList();
     OpenGL::glCallList($dl); #### Draw it the first time
     $chkErr && $self->tErr('draw Key5');
   }
   OpenGL::glRotatef(-$self->{yaw},0,1,0) if $self->{yaw};
   OpenGL::glRotatef(-90,1,0,0) if $self->{hang};
   OpenGL::glRotatef(-270,0,0,1) if $self->{hang};
   OpenGL::glTranslatef(-$self->{x}+0.6,-$self->{y}-0.25,-$self->{z});

   $self->tErr('draw Key');
 }
}				#end closure

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Key -- SimpleThing to unlock things with

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

