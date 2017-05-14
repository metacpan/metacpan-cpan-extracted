#  $Id: TextureList.pm 424 2008-08-19 16:27:43Z duncan $

####------------------------------------------

## @file
# Define TextureList Class

## @class TextureList
#
# Collection of texture information, collects texture
# images from the image directory.
#
#Texture images have file names of the form texture_\<name\>.\<imgSuffix\>
# Handles .png files
#Makes a list of the \<names\> available.  Allows selection of a texture
#from the \<name\>
#
#

package OpenGL::QEng::TextureList;

use strict;
use warnings;
use OpenGL qw/:all/;
use OpenGL::Image;

use base qw/OpenGL::QEng::OUtil/;

#### Verify that Magick is available to load the images
my $engine_hashref = OpenGL::Image::GetEngines();
unless ($engine_hashref->{Magick}) {
  warn "Magick is missing-- no textures will show";
}

#-----------------------------------------------------------
## @cmethod TextureList new()
# Build the texture list
sub new {
  my ($class,$dir) = @_;

  my @textureFiles;
  {
    my $img_dir;
    opendir $img_dir, $dir or die "can\'t open $dir: $!";
    # ignore files not starting with "texture_"
    @textureFiles = grep /^texture_/, readdir $img_dir;
    closedir $img_dir;
  }

  my $textureList;
  glGenTextures_s(scalar @textureFiles, $textureList);

  my $self = {textlist => $textureList,
	      next     => 1,
	      list     => {},
	      filelist => {},};

  for my $file (@textureFiles) {
    (my $name = $file) =~ s/^texture_//;
    $name =~ s/\.(png|ppm)$//;
    $self->{list}{$name}     = -1;
    $self->{filelist}{$name} = "$dir/$file";
  }
  bless $self, $class;
  $self->create_accessors;
  $self;
}

#-----------------------------------------------------------
## @method $ pickTexture($name)
# Return a handle to the texture matching $name
sub pickTexture {
  my ($self,$name) = @_;

  return unless defined $name;
  $self->tErr("glBindTexture-in $name");

  my $id = $self->{list}{$name};

  if (defined($id) && $id<0) {
    glBindTexture(GL_TEXTURE_2D,$self->{next});
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    textureFileRead($self->{filelist}{$name});
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
    $self->{list}{$name} = $self->{next};
    $id = $self->{next};
    $self->{next}++;
  }
  if (defined $id) {
    glBindTexture(GL_TEXTURE_2D,$id);
  } else {
    print "Texture $name not found\n";
  }
  $id;
}

#-----------------------------------------------------------
sub textureFileRead {
  my $file = shift;

  my $image = new OpenGL::Image(engine=>'Magick',source=>$file);
  return $image unless defined($image);

  my ($w, $h) = $image->Get('width','height');
  if (($w<1) || ($h<1) || ($w>1000) || ($h>1000)) {
    die "bad sizes $w,$h in $file";
  }

  my ($Tex_Type, $Tex_Format, $Tex_Size) =
    $image->Get('gl_internalformat','gl_format','gl_type');
  my $Tex_Pixels = $image->GetArray();
  glTexImage2D_c(GL_TEXTURE_2D, 0, $Tex_Type, $w,$h,
		 0, $Tex_Format, $Tex_Size, $Tex_Pixels->ptr());
}

#-----------------------------------------------------------
## @method tErr
# print any pending OpenGL error
sub tErr {
  my ($self, $w) = @_;

  my $e;
  while ($e = glGetError()) {
    print "$e, ",gluErrorString($e)," \@:$w\n";
  }
}

#==================================================================
###
### Test Driver
###
if (!defined(caller())) {

  package main;
  use OpenGL ':all';


  if (0) {
  glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA);
  glutInitWindowSize(200,200);
  glutCreateWindow("Texture Display");
} else {
  OpenGL::glpOpenWindow(width=>200,height=>200,
#		attributes=>[GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA]);
#		attributes=>[GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH ]
		       );
}
  TextureList::tErr('Window Init');
  glClearColor(0,0,0,1);
  glColor3f (1.0, 1.0, 1.0);
  glShadeModel (GL_FLAT);

  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LESS);
  TextureList->tErr('set depth');

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(60.0, 1.0 , 1.0, 30.0);

  glMatrixMode(GL_MODELVIEW);
  TextureList->tErr('set mode');
  #glutMainLoop();
  my $tl = OpenGL::QEng::TextureList->new("./images");
  my $list = $tl->getList();
  foreach my $name (keys %$list) {
    my $id = $tl->pickTexture($name);
    print "texture $name\n";
    display($id);
    #warn 'show';
    #$tl->show;
    my $char =<stdin>;
    #last;
  }
#----------------------------------------------------------------------
  ## @fn $ display
  # display the passed texture
  sub display {
    my $tex = shift;
    glEnable(GL_TEXTURE_2D);
    glClearColor(0.8,0.8,0.8,0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glBindTexture(GL_TEXTURE_2D,$tex);
    glLoadIdentity ();
    glTranslatef(0.0, 0.0, -2.6);
    TextureList->tErr('translate');

    glPushMatrix();
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 1.0); glVertex3f(-1.0, -1.0, 0.0);
    glTexCoord2f(0.0, 0.0); glVertex3f(-1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 0.0); glVertex3f(1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 1.0); glVertex3f(1.0, -1.0, 0.0);
    glEnd();
    glPopMatrix();

    glFlush();
    if(01){
      glXSwapBuffers();
    #glutSwapBuffers();
  } else {
    OpenGL::glpSwapBuffers();
  }
    TextureList->tErr('flush');
    #OpenGL::glutMainLoopEvent();
  }
  #glutMainLoop();
}

1;

__END__

=head1 NAME

TextureList -- Collection of texture information, collects texture 
images from the image directory.

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

