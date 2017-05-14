###  $Id: Box.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Box Class

## @class Box
# Box -- several game objects are built from these
#

package OpenGL::QEng::Box;

use strict;
use warnings;
use OpenGL qw/:all/;
use OpenGL::QEng::VecText qw/render_string/;

use base qw/OpenGL::QEng::Volume/;

use constant PI => 4*atan2(1,1); # 3.14159;
use constant RADIANS => PI/180.0;

sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Volume->new;
  #                      top    front   left    back   right  bottom
  $self->{texture}   = [undef,  'wood','wood', 'wood','wood','wood'];
  $self->{color}     = ['brown','red', 'green','blue','gray','cyan'];
  $self->{face}      = [ 1,      1,     1,      1,     1,     1    ];
  $self->{tex_fs}    = $props->{tex_fs}|| 3; # full size for texture image: 3' or ?
  $self->{xsize}     = $props->{xsize} || $self->{tex_fs};
  $self->{ysize}     = $props->{ysize} || $self->{tex_fs};
  $self->{zsize}     = $props->{zsize} || $self->{tex_fs};
  $self->{stretchi}  = 0;
  $self->{visible}   = 1;
  $self->{store_at}  = {x    => 0, y     => $self->{ysize}+0.01, z   => 0,
			roll => 0, pitch => 0,                   yaw => 0};
  $self->{model}     = {miny =>  0,
		        maxy => +$self->{ysize},
		        minx => -$self->{xsize}/2,
		        maxx => +$self->{xsize}/2,
		        minz => -$self->{zsize}/2,
		        maxz => +$self->{zsize}/2,};
  bless($self,$class);

  $self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;

  $self;
}

#--------------------------------------------------
sub get_corners {
  #XXX
  require OpenGL::QEng::Thing;
  $_[0]->OpenGL::QEng::Thing::get_corners();
}

#------------------------------------------
## @method draw($mode)
# Draw this object in its current state at its current location
# or set up for testing for a touch
sub draw {
  my ($self,$mode) = @_;

  my $chkErr = 1; # flag

  my $yaw = $self->{yaw};
  my ($selfX,$selfZ) = ($self->x,$self->z);
  my $model = $self->model;
  my ($minx,$maxx,$miny,$maxy,$minz,$maxz);
  if (defined $model) {
    ($minx,$maxx) = ($model->{minx},$model->{maxx});
    ($miny,$maxy) = ($model->{miny},$model->{maxy});
    ($minz,$maxz) = ($model->{minz},$model->{maxz});
  }
  my $face = $self->face;
  $face = [$face,$face,$face,$face,$face,$face]
    unless (ref($face) eq 'ARRAY');
  my $color = $self->color;
  $color = [$color,$color,$color,$color,$color,$color]
    unless (ref($color) eq 'ARRAY');
  my $texture = $self->texture;
  $texture = [$texture,$texture,$texture,$texture,$texture,$texture]
    unless (ref($texture) eq 'ARRAY');

  if ($mode == OpenGL::GL_SELECT) {
    glLoadName($self->{GLid});
  }
  glTranslatef($self->x,$self->y,$self->z);
  glRotatef($self->{roll}, 0,0,1) if $self->{roll};
  glRotatef($self->{yaw},  0,1,0) if $self->{yaw};
  glRotatef($self->{pitch},1,0,0) if $self->{pitch};

  my $fs = $self->tex_fs;
  my ($sx,$sy,$sz) = (           0,           0,           0);
  my ( $l, $h, $t) = ($self->xsize,$self->ysize,$self->zsize);
  if ($self->stretchi) {
    ($l,$h,$t) = ($fs,$fs,$fs);
  }
  elsif (exists $self->{i_am_a_wall_chunk}) {
    $sx = $self->x;
    $l  = $self->x + $l;
    $sy = $self->y;
    $h  = $self->y + $h;
    $sz = $self->z;
    $t  = $self->z + $t;
  }

  if ($face->[0]) {	# top face ------------------
    if ($texture->[0]) {
      $self->pickTexture($texture->[0]);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_T, GL_REPEAT);
      glEnable(GL_TEXTURE_2D);
    } else {
      $self->setColor($color->[0]||'pink');
    }
    glBegin(OpenGL::GL_QUADS);

    glTexCoord2f($sx/$fs,$sz/$fs); glVertex3f($minx,$maxy,$minz);
    glTexCoord2f($sx/$fs, $t/$fs); glVertex3f($minx,$maxy,$maxz);
    glTexCoord2f( $l/$fs, $t/$fs); glVertex3f($maxx,$maxy,$maxz);
    glTexCoord2f( $l/$fs,$sz/$fs); glVertex3f($maxx,$maxy,$minz);

    glEnd();
    glDisable(GL_TEXTURE_2D);
    $chkErr && $self->tErr('draw Box[0]');
  }
  if ($face->[1]) {	# front face ------------------
    if ($texture->[1]) {
      $self->pickTexture($texture->[1]);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_T, GL_REPEAT);
      glEnable(GL_TEXTURE_2D);
    } else {
      $self->setColor($color->[1]||'pink');
    }
    glBegin(OpenGL::GL_QUADS);

    glTexCoord2f($sx/$fs,$sy/$fs); glVertex3f($minx,$miny,$minz);
    glTexCoord2f($sx/$fs, $h/$fs); glVertex3f($minx,$maxy,$minz);
    glTexCoord2f( $l/$fs, $h/$fs); glVertex3f($maxx,$maxy,$minz);
    glTexCoord2f( $l/$fs,$sy/$fs); glVertex3f($maxx,$miny,$minz);

    glEnd();
    glDisable(GL_TEXTURE_2D);
    $chkErr && $self->tErr('draw Box[1]');
  }
  if ($face->[2]) {	# left face ------------------
    if ($texture->[2]) {
      $self->pickTexture($texture->[2]);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_T, GL_REPEAT);
      glEnable(GL_TEXTURE_2D);
    } else {
      $self->setColor($color->[2]||'pink');
    }
    glBegin(OpenGL::GL_QUADS);

    glTexCoord2f($sz/$fs,$sy/$fs); glVertex3f($minx,$miny,$minz);
    glTexCoord2f( $t/$fs,$sy/$fs); glVertex3f($minx,$miny,$maxz);
    glTexCoord2f( $t/$fs, $h/$fs); glVertex3f($minx,$maxy,$maxz);
    glTexCoord2f($sz/$fs, $h/$fs); glVertex3f($minx,$maxy,$minz);

    glEnd();
    glDisable(GL_TEXTURE_2D);
    $chkErr && $self->tErr('draw Box[2]');
  }
  if ($face->[3]) {	# back face ------------------
    if ($texture->[3]) {
      $self->pickTexture($texture->[3]);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_T, GL_REPEAT);
      glEnable(GL_TEXTURE_2D);
    } else {
      $self->setColor($color->[3]||'pink');
    }
    glBegin(OpenGL::GL_QUADS);

    glTexCoord2f($sx/$fs,$sy/$fs); glVertex3f($minx,$miny,$maxz);
    glTexCoord2f($sx/$fs, $h/$fs); glVertex3f($minx,$maxy,$maxz);
    glTexCoord2f( $l/$fs, $h/$fs); glVertex3f($maxx,$maxy,$maxz);
    glTexCoord2f( $l/$fs,$sy/$fs); glVertex3f($maxx,$miny,$maxz);

    glEnd();
    glDisable(GL_TEXTURE_2D);
    $chkErr && $self->tErr('draw Box[3]');
  }
  if ($face->[4]) {	# right face ------------------
    if ($texture->[4]) {
      $self->pickTexture($texture->[4]);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_T, GL_REPEAT);
      glEnable(GL_TEXTURE_2D);
    } else {
      $self->setColor($color->[4]||'pink');
    }
    glBegin(OpenGL::GL_QUADS);

    glTexCoord2f($sz/$fs,$sy/$fs); glVertex3f($maxx,$miny,$minz);
    glTexCoord2f( $t/$fs,$sy/$fs); glVertex3f($maxx,$miny,$maxz);
    glTexCoord2f( $t/$fs, $h/$fs); glVertex3f($maxx,$maxy,$maxz);
    glTexCoord2f($sz/$fs, $h/$fs); glVertex3f($maxx,$maxy,$minz);

    glEnd();
    glDisable(GL_TEXTURE_2D);
    $chkErr && $self->tErr('draw BoxT');
  }
  if ($face->[5]) {	# bottom face ------------------
    if ($texture->[5]) {
      $self->pickTexture($texture->[5]);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameterf(GL_TEXTURE_2D, OpenGL::GL_TEXTURE_WRAP_T, GL_REPEAT);
      glEnable(GL_TEXTURE_2D);
    } else {
      $self->setColor($color->[5]||'pink');
    }
    glBegin(OpenGL::GL_QUADS);

    glTexCoord2f($sx/$fs,$sz/$fs); glVertex3f($minx,$miny,$minz);
    glTexCoord2f($sx/$fs, $t/$fs); glVertex3f($minx,$miny,$maxz);
    glTexCoord2f( $l/$fs, $t/$fs); glVertex3f($maxx,$miny,$maxz);
    glTexCoord2f( $l/$fs,$sz/$fs); glVertex3f($maxx,$miny,$minz);

    glEnd();
    glDisable(GL_TEXTURE_2D);
    $chkErr && $self->tErr('draw Box[5]');
  }
  if (defined($self->{text}) && length($self->{text})) {
    my ($tX,$tY,$tZ,$tP) =
      ($self->can('text_location')) ? $self->text_location : (0,0,0,0);
    OpenGL::QEng::VecText::render_string($tX,$tY,$tZ,$tP,0.01,0.01,$self->{'text'});
  }
  if ($self->contains) {
    foreach my $o (@{$self->contains}) {
      $o->draw($mode);
    }
  }
  glRotatef(-$self->{pitch},1,0,0) if $self->{pitch};
  glRotatef(-$self->{yaw},  0,1,0) if $self->{yaw};
  glRotatef(-$self->{roll}, 0,0,1) if $self->{roll};
  glTranslatef(-$self->x,-$self->y,-$self->z);

  $chkErr && $self->tErr('draw Box');
}

#------------------------------------------
sub tractable { # tractability - 'solid', 'seethru', 'passable'
  'solid';
}

#==============================================================================
1;

__END__

=head1 NAME

Box -- a basic bulding block for anything with a few flat sides

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

