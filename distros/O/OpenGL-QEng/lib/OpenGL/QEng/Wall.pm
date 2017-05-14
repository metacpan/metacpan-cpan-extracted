eval 'exec perl -S $0 ${1+"$@"}' # -*-Perl-*-
  if $running_under_some_shell;
#  $Id: Wall.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Wall Class

## @class Wall
# Wall in the game
#

package OpenGL::QEng::Wall;

use strict;
use warnings;

use OpenGL qw/:all/;
#use Carp;
#use Data::Dumper;

use base qw/OpenGL::QEng::Volume/;

use constant PI => 4*atan2(1,1); # 3.14159;
use constant RADIANS => PI/180.0;

#####
##### Class Methods - called as Class->function($a,$b,$c)
#####

#--------------------------------------------------
## @cmethod % new()
# Create a length of wall
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Volume->new;
  $self->{chunk}   = []; # pieces of the wall
  $self->{gaplist} = []; # pieces that aren't wall
  $self->{texture} = 'wall-grey';
  $self->{xsize}   = $props->{xsize}  || 8;  # walls default to 8'H x8'L
  $self->{ysize}   = $props->{ysize}  || 8;
  $self->{zsize}   = $props->{zsize}  || .5; # walls default to 6" thick
  $self->{tex_fs}  = $self->{ysize};
  $self->{store_at}= undef;
  $self->{model}   = {miny =>  0,
		      maxy =>  $self->{ysize},
		      minx =>  0,
		      maxx =>  $self->{xsize},
		      minz => -$self->{zsize}/2,
		      maxz => +$self->{zsize}/2};
  bless($self,$class);

  $self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;
  $self->make_chunks;

  $self;
}

#--------------------------------------------------
sub boring_stuff {
  my ($self) = @_;
  my $boring_stuff = $self->SUPER::boring_stuff;
  $boring_stuff->{gaplist} = 1;
  $boring_stuff->{model} = 1;
  $boring_stuff->{chunk} = 1;
  $boring_stuff;
}

#--------------------------------------------------
sub can_hang {1} # announce that we can have things hung on

#--------------------------------------------------
sub assimilate {
  my ($self,$thing) = @_;

  return unless defined($thing);
  $self->SUPER::assimilate($thing);
  $self->make_chunks if $thing->isa('OpenGL::QEng::Opening');
}

#--------------------------------------------------
## @method put_thing($thing)
#put arg (a thing instance) into the current thing
sub put_thing {
  my ($self,$thing,$store) = @_;
  return unless defined($thing);

  die "put_thing($self,$thing) from ",join(':',caller)," " unless $store;
  $self->SUPER::put_thing($thing,$store);
  if ($thing->y > 0.5 && exists $thing->{hang}) {
    $thing->{hang} = 1;
  }
}

#---------------------------------------------------------
sub find_openings {
  my ($self) = @_;

  my @doors;
  foreach my $o (@{$self->{parts}}) {
    if ($o->isa('OpenGL::QEng::Opening')) {
      push @doors, $o;	# find all my doors
    }
  }
  return unless @doors;

  $self->{gaplist} = [];
  for my $d (@doors) {	# use them to make openings
    if ($d->yaw == 0) {
      push @{$self->{gaplist}}, [$d->x+$d->model->{minx},
				 $d->x+$d->model->{maxx},
				 $d->y+$d->model->{miny},
				 $d->y+$d->model->{maxy}];
    } else {
      push @{$self->{gaplist}}, [$d->x-$d->model->{maxx},
				 $d->x-$d->model->{minx},
				 $d->y+$d->model->{miny},
				 $d->y+$d->model->{maxy}];
    }
  }
  # sort openings by first x pos
  @{$self->{gaplist}} = sort {$a->[0] <=> $b->[0]} @{$self->{gaplist}};
}

#---------------------------------------------------------
sub make_chunks {
  my ($self) = @_;

  $self->find_openings;

  # throw away all my wall chunks
  for my $b (@{$self->{chunk}}) {
    $self->excise($b);
  }
  $self->{chunk} = [];
  my @openings = @{$self->{gaplist}};
  my $xfend = (@openings) ? $openings[0][0] : $self->xsize;
  my $chunk;

  # left block(s), always
  my $xbeg = 0;
  my $xend = 0;
  my $xchunk = $self->tex_fs;
  while ($xfend > $xbeg) {
    $xend = ($xfend-$xend >= $xchunk) ? $xend+$xchunk : $xfend;
    $chunk = OpenGL::QEng::Box->new(x       => $xbeg,
		    y       => 0,
		    z       => 0,
		    roll    => 0,
		    pitch   => 0,
		    yaw     => 0,
		    xsize   => $xend - $xbeg,
		    ysize   => $self->ysize,
		    zsize   => $self->zsize,
		    texture => $self->texture,
		    tex_fs  => $self->tex_fs,
		    color   => 'slate gray',
		    model   => {miny => $self->{model}{miny},
				maxy => $self->{model}{maxy},
				minx => 0,
				maxx => $xend - $xbeg,
				minz => $self->{model}{minz},
				maxz => $self->{model}{maxz}},
		   );
    $chunk->{i_am_a_wall_chunk} = 1;
    push @{$self->{chunk}}, $chunk;
    $self->assimilate($chunk);
    $xbeg = $xend;
  }
  #N right and N top/bottom blocks, where N = number of gaps
  while (my $op = shift @openings) {
    # bottom block
    if ($op->[2] > 0) { #XXX need to adjust these if wall y != 0
      $chunk = OpenGL::QEng::Box->new(x       => $op->[0],
		      y       => 0,
		      z       => 0,
		      roll    => 0,
		      pitch   => 0,
		      yaw     => 0,
		      xsize   => $op->[1] - $op->[0],
		      ysize   => $op->[2],
		      zsize   => $self->zsize,
		      texture => $self->texture,
		      tex_fs  => $self->tex_fs,
		      color   => 'slate gray',
		      model   => {miny => 0,
				  maxy => $op->[2],
				  minx => 0,
				  maxx => $op->[1] - $op->[0],
				  minz => $self->{model}{minz},
				  maxz => $self->{model}{maxz}},
		     );
      $chunk->{i_am_a_wall_chunk} = 1;
      push @{$self->{chunk}}, $chunk;
      $self->SUPER::assimilate($chunk);
    }
    # top block
    if ($op->[3] < $self->ysize) { #XXX need to adjust these if wall y != 0
      $chunk = OpenGL::QEng::Box->new(x       => $op->[0],
		      y       => $op->[3],
		      z       => 0,
		      roll    => 0,
		      pitch   => 0,
		      yaw     => 0,
		      xsize   => $op->[1] - $op->[0],
		      ysize   => $self->ysize - $op->[3],
		      zsize   => $self->zsize,
		      texture => $self->texture,
		      tex_fs  => $self->tex_fs,
		      color   => 'slate gray',
		      model   => {miny => 0,
				  maxy => $self->ysize - $op->[3],
				  minx => 0,
				  maxx => $op->[1] - $op->[0],
				  minz => $self->{model}{minz},
				  maxz => $self->{model}{maxz}},
		     );
      $chunk->{i_am_a_wall_chunk} = 1;
      push @{$self->{chunk}}, $chunk;
      $self->SUPER::assimilate($chunk);
    }
    # right block(s)
    $xfend = (@openings) ? $openings[0][0] : $self->xsize;
    $xbeg = $op->[1];
    $xend = $op->[1];
    while ($xfend > $xbeg) {
      $xend = ($xfend-$xend >= $xchunk) ? $xend+$xchunk : $xfend;
      $chunk = OpenGL::QEng::Box->new(x       => $xbeg,
		      y       => 0,
		      z       => 0,
		      roll    => 0,
		      pitch   => 0,
		      yaw     => 0,
		      xsize   => $xend - $xbeg,
		      ysize   => $self->ysize,
		      zsize   => $self->zsize,
		      texture => $self->texture,
		      tex_fs  => $self->tex_fs,
		      color   => 'slate gray',
		      model   => {miny => $self->{model}{miny},
				  maxy => $self->{model}{maxy},
				  minx => 0,
				  maxx => $xend - $xbeg,
				  minz => $self->{model}{minz},
				  maxz => $self->{model}{maxz}},
		     );
      $chunk->{i_am_a_wall_chunk} = 1;
      push @{$self->{chunk}}, $chunk;
      $self->SUPER::assimilate($chunk);
      $xbeg = $xend;
    }
  }
}

#==============================================================================
1;

__END__

=head1 NAME

Wall -- hmm...how do I explain this one?

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

