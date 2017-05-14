#  $Id: SimpleThing.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
#{
##@file
# Define SimpleThing and the SimpleThing Subclasses

## @class SimpleThing
#  Implements things that can be carried

package OpenGL::QEng::SimpleThing;

use strict;
use warnings;

use OpenGL qw/:all/;
#use Carp;

use base qw/OpenGL::QEng::Box/;

#------------------------------------------------------------------------------
## @cmethod Simple new($class, @arg)
# Create a simpleThing of given type at given location
#
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);

  my $self = OpenGL::QEng::Box->new;
  $self->{texture} = lc($class); # Texture image for this thing
  $self->{texture} =~ s/OpenGL::QEng:://i;
  $self->{color}   = 'red';
  $self->{model}   = {minx =>-1.0, maxx => 1.0,
		      minz =>-1.0, maxz => 1.0,
		      miny =>.001, maxy => 0.1};
  $self->{y}       = 0;           # elevation of origin
  $self->{face}    = [1,0,0,0,0,0];
  $self->{power}   = undef;
  bless($self,$class);

  $self->passedArgs({@props});
  $self->create_accessors;
  $self->register_events;

  $self;
};

#-----------------------------------------------------------------------------
# class method has_sublass -- returns true if $sub is a subclass of
#                             SimpleThing without its own class file
sub has_subclass {
  my ($class,$sub) = @_;
  {Helmet=>1, Robe=>1, Shoes=>1, Letter=>1, Lamp=>1, Knife=>1, }->{$sub};
}

#-----------------------------------------------------------------
sub make_me_nod {
  1;
}

#------------------------------------------------------------
sub tractable { # tractability - 'solid', 'seethru', 'passable'
  'passable';
}

#-------------   Instance Methods    -------------------------------

## @method handle_touch()
#handle SimpleThing being touched:
# pick it up or drop it
#
sub handle_touch { #XXX allow for other methods?
  my ($self) = @_;

  my $where_am_i = $self->is_at;
  $where_am_i->take_thing($self);

  if (ref($where_am_i) eq 'Team') {
    $self->send_event('dropped',$where_am_i);
  } else {
    $self->send_event('grabbed',$where_am_i);
  }
  $self->send_event('need_redraw');
  $self->send_event('need_ov_redraw');
}

#---------------------------------------------------------------------------
## @method $ desc
# return the description of this type -- Used by Examine button?
sub desc { ref($_[0]) }

#--------------------------
## @method $ combine()
# Fails at combining for all non-treasures
sub combine {0}

#--------------------------
## @method $ value
# return value of this treasure
sub value {0}


###############################################################################
#
#Other micro subclasses of SimpleThing:
#

## @class Helmet
# Armor

push @OpenGL::QEng::Helmet::ISA, 'OpenGL::QEng::SimpleThing';

#---------------------------------------------------------------------------
## @method $ textName
# Displayable name of this thing
sub Helmet::textName { "Dented\nhelmet" }

#---------------------------------------------------------------------------
## @class Robe
# Help avoid embarassment

#use base qw/OpenGL::QEng::SimpleThing/;
push @OpenGL::QEng::Robe::ISA, 'OpenGL::QEng::SimpleThing';

#---------------------------------------------------------------------------
## @method $ textName
# Displayable name of this thing
sub Robe::textName { "Warm robe" }

#---------------------------------------------------------------------------
## @class Shoes
# Reduce wear and tear of the feet

#use base qw/OpenGL::QEng::SimpleThing/;
push @OpenGL::QEng::Shoes::ISA, 'OpenGL::QEng::SimpleThing';

## @method $ desc($self)
# Return a text description of this object
sub Shoes::desc { 'Better than bare feet or sandals' }

## @method $ textName
# get a printable name for this item
sub Shoes::textName { "Battered\n shoes" }

#---------------------------------------------------------------------------
## @class Letter
# Junk mail

#use base qw/OpenGL::QEng::SimpleThing/;
push @OpenGL::QEng::Letter::ISA, 'OpenGL::QEng::SimpleThing';

## @method $ desc($self)
# Return a text description of this object
sub Letter::desc { 'Your credit is assured, just fill out this application and send it in with the deed to your house' }

## @method $ textName
# Displayable name of this thing
sub Letter::textName { "First Class\n letter" }

#---------------------------------------------------------------------------
## @class Lamp
# Enlighten your journey

#use base qw/OpenGL::QEng::SimpleThing/;
push @OpenGL::QEng::Lamp::ISA, 'OpenGL::QEng::SimpleThing';

## @method $ textName
# Displayable name of this thing
sub Lamp::textName { "Oddly shaped\nlamp" }

## @method $ desc($self)
# Return a text description of this object
sub Lamp::desc { 'Lights the way and never runs out of oil' }

#---------------------------------------------------------------------------
## @class Knife
# tool

push @OpenGL::QEng::Knife::ISA, 'OpenGL::QEng::SimpleThing';

## @method $ textName
# Displayable name of this thing
sub Knife::textName { 'Old knife' }

## @method $ desc($self)
# Return a text description of this object
sub Knife::desc {
  'A little dull but servicable'}

#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

SimpleThing -- Base class for items that may be carried and used by the Team

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

