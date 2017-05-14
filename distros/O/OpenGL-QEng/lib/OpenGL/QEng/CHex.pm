###  $Id: CHex.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------

## @file Chex.pm
# Define Chex Class

## @class Chex
# Chex - Combination of stuff to make a cubicle/hexacle office
# @map_item    - Chex
#

package OpenGL::QEng::CHex;

use strict;
use warnings;
use OpenGL::QEng::Wall;
use OpenGL::QEng::Sign;
use OpenGL::QEng::Box;

use base qw/OpenGL::QEng::Volume/;

#------------------------------------------------------------
## @cmethod Chex new(@args)
# Create a chex at given location
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Volume->new;
  bless($self, $class);
  my (@w,$s,@b);
  push @w, OpenGL::QEng::Wall->new(x=>0, z=>0, yaw=>0, ysize=>5.2, xsize=>3,
		     texture=>'fabric');
  $s = OpenGL::QEng::Sign->new(x=>1.5, z=>0.3, yaw=>0, ysize=>1.5, xsize=>2.5,
		 texture=>'ceiling_tile', text=>' ', y=>4.4);
  push @w, OpenGL::QEng::Wall->new(x=>0, z=>0, yaw=>270, ysize=>5.2, xsize=>3,
		     texture=>'fabric');
  push @w, OpenGL::QEng::Wall->new(x=>3, z=>0, yaw=>0, ysize=>5.2, xsize=>3,
		     texture=>'fabric');
  push @b, OpenGL::QEng::Box->new(x=>4.5, z=>0.75, yaw=>0, xsize=>3, ysize=>1.5, zsize=>1,
		    color=>['black', 'gray25', 'gray25', 'gray25', 'gray25', 'gray25'],
		    texture=>'', y=>3.7);
  push @b, OpenGL::QEng::Box->new(x=>0.65, z=>0.75, yaw=>0, xsize=>1.3, ysize=>2, zsize=>1,
		    color=>'darkslategray', texture=>'');
  push @b, OpenGL::QEng::Box->new(x=>2.16, z=>0.75, yaw=>0, xsize=>1.3, ysize=>2, zsize=>1,
		    color=>'darkslategray', texture=>'');
  push @b, OpenGL::QEng::Box->new(x=>3, z=>1.25, yaw=>0, xsize=>6, ysize=>0.05, zsize=>2,
		    y=>2.2, texture=>'sand');
  push @w, OpenGL::QEng::Wall->new(x=>6, z=>0, yaw=>-60, ysize=>5.2, xsize=>3,
		     texture=>'fabric');
  push @w, OpenGL::QEng::Wall->new(x=>7.5, z=>2.6, yaw=>-60, ysize=>5.2, xsize=>3,
		     texture=>'fabric');
  push @b, OpenGL::QEng::Box->new(x=>6.6, z=>3.65, yaw=>-60, xsize=>6, ysize=>0.05, zsize=>2,
		    y=>2.2, texture=>'sand');
  push @b, OpenGL::QEng::Box->new(x=>6.5, z=>7.35, yaw=>-120, xsize=>6, ysize=>0.05, zsize=>2,
		    y=>2.2, texture=>'sand');
  push @w, OpenGL::QEng::Wall->new(x=>9, z=>5.19, yaw=>-120, ysize=>5.2, xsize=>3,
		     texture=>'fabric');
  push @w, OpenGL::QEng::Wall->new(x=>7.5, z=>7.79, yaw=>-120, ysize=>5.2, xsize=>3,
		     texture=>'fabric');
  push @b, OpenGL::QEng::Box->new(x=>4.6, z=>9.14, yaw=>0, xsize=>3, ysize=>0.05, zsize=>2,
		    y=>2.2, texture=>'sand');
  push @w, OpenGL::QEng::Wall->new(x=>6, z=>10.39, yaw=>-180, ysize=>5.2, xsize=>3,
		     texture=>'fabric');
  push @b, OpenGL::QEng::Box->new(x=>4.5, z=>9.74, yaw=>0, xsize=>3, ysize=>1.5, zsize=>1,
		    color=>['black', 'gray25', 'gray25', 'gray25', 'gray25', 'gray25'],
		    texture=>'', y=>3.7);
  push @w, OpenGL::QEng::Wall->new(x=>3, z=>10.39, yaw=>-180, ysize=>5.2, xsize=>3,
		     texture=>'fabric');
  push @b, OpenGL::QEng::Box->new(x=>1.5, z=>9.89, yaw=>0, xsize=>3, ysize=>5, zsize=>1,
		    texture=>'', color=>'darkslategray');
  push @w, OpenGL::QEng::Wall->new(x=>0, z=>7.39, yaw=>270, ysize=>5.2, xsize=>3,
		     texture=>'fabric');

  $self->passedArgs($props);
  $self->register_events;
  $self->create_accessors;
  for my $part (@w,@b,$s) {
    $self->assimilate($part);
  }
  $self;
}

#------------------------------------------
sub printMe { #XXX merge into Thing
  my ($self,$depth) = @_;

  (my $map_ref = ref $self) =~ s/OpenGL::QEng:://;
  print STDOUT '  'x$depth,"$map_ref $self->{x} $self->{z} $self->{yaw};\n";
}


#==============================================================================
1;

__END__

=head1 NAME

Chex - Combination of stuff to make a cubicle/hexacle office

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

