eval 'exec perl -S $0 ${1+"$@"}' # -*-Perl-*-
  if $running_under_some_shell;

#  $Id: glGrid.pm 361 2008-08-06 18:44:58Z overmars $
####------------------------------------------
###
## @file
# Define Grid Class

## @class Grid
# Draw a grid for help in positioning things
# @map_item - Grid for positioning (use in place of Floor during map
# development
#    map format - (grid)
#
package Grid;

use strict;
use warnings;

use Carp;
use OpenGL qw/:all/;

use base qw(Thing);

#------------------------------------------

#####
##### Class Methods - called as Class->function($a,$b,$c)
#####

## @cmethod Grid new()
# Create a grid
sub new { warn 'Grid::new() ',join ':', caller;
  my ($class,@props) = @_;

  if (ref $class) {		#create from another Thing - clone
    confess 'no cloning today!'
  }
  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = Thing->new;
  bless($self,$class);
  $self->passedArgs({@props});

  $self;
}

##
## instance methods
##

#------------------------------------------
## @method $ draw($self, $mode)
# Draw this object in its current state at its current location
# or set up for testing for a touch
#
sub draw { #die join ':', caller;
  my ($self,$mode) = @_;

  my $x_extent = 40.0;	      # Maximum of the grid in the x direction in feet
  my $z_extent = 40.0;	      # Maximum of the grid in the z direction in feet

  glColor3f(1.0,1.0,0);
  glBegin(OpenGL::GL_QUADS);
  #bottom
  glVertex3f(0,0,0);
  glVertex3f(0,0,40.0);
  glVertex3f(0.1,0,40);
  glVertex3f(0.1,0,0);
  glColor3f(1.0,0,0);
  for (my $x = 8.0; $x<=$x_extent; $x+=8.0){
    glVertex3f($x,    0.0,0.0);
    glVertex3f($x,    0.0,$z_extent);
    glVertex3f($x+0.1,0.0,$z_extent);
    glVertex3f($x+0.1,0.0,0);
  }

  glColor3f(0,1.0,1.0);
  glVertex3f(0,0,0);
  glVertex3f(40.0,0,0);
  glVertex3f(40.0,0,0.1);
  glVertex3f(0,0,0.1);
  glColor3f(0,0,1.0);
  for (my $z=8.0; $z<=$z_extent; $z+=8.0) {
    glVertex3f(0.0,      0.0,$z);
    glVertex3f($x_extent,0.0,$z);
    glVertex3f($x_extent,0.0,$z+0.1);
    glVertex3f(0.0,      0.0,$z+0.1);
  }
  glEnd();
}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Grid -- Draw a grid for help in positioning things

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@rejiquar.com>E<gt>,
and Rob Duncan E<lt>F<duncan@rejiquar.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars, All rights reserved.

=head1 LICENSE

This software is provided under the Perl License.  It may be distributed
and revised according to the terms of that license.

=cut
