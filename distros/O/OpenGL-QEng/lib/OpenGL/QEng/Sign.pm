###  $Id: Sign.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Sign Class

## @class Sign
# Signs in game

package OpenGL::QEng::Sign;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::Box/;

#------------------------------------------
## @cmethod Sign new(@args)
# Create a sign at given location
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Box->new;
  $self->{texture}   = 'sand';       # Texture image for this sign
  $self->{color}     = 'orange';
  $self->{face}      = [0,1,0,0,0,0];# show only front,rear face
  $self->{stretchi}  = 1;
  $self->{text}      = 'BLANK SIGN'; # Text to show
  $self->{xsize}     = $props->{xsize} || 4;
  $self->{ysize}     = $props->{ysize} || 3;
  $self->{zsize}     = $props->{zsize} || 0.05;
  $self->{y}         = 5.5;
  $self->{model}     = {miny => -$self->{ysize}/2,
			maxy => +$self->{ysize}/2,
			minx => -$self->{xsize}/2,
			maxx => +$self->{xsize}/2,
			minz =>  0,
			maxz => +$self->{zsize}};
  bless($self,$class);

  $self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;

  $self;
}

#------------------------------------------
sub text_location {
  my ($self) = @_;

  my $model = $self->{model};

  # Need to handle string vs array
  my $textlen = length($self->{'text'} or '');
  my $charWidth = 0.13;

  ($model->{minx}+($model->{maxx}-$model->{minx}-$textlen*$charWidth)/2, # X
   $model->{miny}+($model->{maxy}-$model->{miny})/2-0.06,                # Y
   $model->{maxz}+0.01,0);                                               # Z
}

#===========================================================================
#
# the map 'new_quests.txt' has many signs for testing, so does 'startMap.txt'
#

#---------------------------------------------------------------------------
1;

__END__

=head1 NAME

Sign -- Signs in game - static and variable

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

