package Term::Animation::Entity;

use 5.006;
use strict;
use warnings;
use Carp;
use Curses;
use Term::Animation;

=head1 NAME

Term::Animation::Entity

=head1 SYNOPSIS

  use Term::Animation::Entity;

  # Constructor
  my $entity = Term::Animation::Entity->new(
      shape         => ';-)',
      position      => [ 1, 2, 3 ],
      callback_args => [ 0, 1, 0, 0 ],
  );

=head1 ABSTRACT

A sprite object for use with Term::Animation

=head1 DESCRIPTION

Term::Animation::Entity is used by L<Term::Animation|Term::Animation> to
represent a single sprite on the screen.

=head1 PARAMETERS

  name < SCALAR >
        A string uniquely identifying this object

  shape < REF >
        The ASCII art for this object. It can be provided as:
                  1) A single multi-line text string (no animation)
                  2) An array of multi-line text strings, where each
		     element is a single animation frame
                  3) An array of 2D arrays. Each element in the outer
		     array is a single animation frame.
        If you provide an array, each element is a single frame of animation.
	If you provide either 1) or 2), a single newline will be stripped off
	of the beginning of each string. 3) is what the module uses internally.

  auto_trans < BOOLEAN >
        Whether to automatically make whitespace at the beginning of each line
	transparent.  Default: 0

  position < ARRAY_REF >
        A list specifying initial x,y and z coordinates
        Default: [ 0, 0, 0 ]

  callback < SUBROUTINE_REF >
        Callback routine for this entity. Default: I<move_entity()>

  callback_args < REF >
        Arguments to the callback routine.

  curr_frame < INTEGER >
        Animation frame to begin with. Default: 0

  wrap < BOOLEAN >
        Whether this entity should wrap around the edge of the screen. Default: 0

  transparent < SCALAR >
        Character used to indicate transparency. Default: ?

  die_offscreen < BOOLEAN >
  	Whether this entity should be killed if
	it goes off the screen. Default: 0

  die_entity < ENTITY >
  	Specifies an entity (ref or name). When the named
	entity dies, this entity should die as well. Default: undef

  die_time < INTEGER >
  	The time at which this entity should be killed. This 
	should be a UNIX epoch time, as returned
	by I<time>.  Default: undef

  die_frame < INTEGER >
  	Specifies the number of frames that should be displayed
	before this entity is killed. Default: undef

  death_cb < SUBROUTINE_REF >
        Callback routine used when this entity dies

  dcb_args < REF >
        Arguments to the entity death callback routine

  color
        Color mask. This follows the same format as 'shape'.
	See the 'COLOR' section below for more details.

  default_color < SCALAR >
        A default color to use for the entity.  See the 'COLOR' section
	for more details.

  data < REF >
  	Store some data about this entity. It is not used by the module.
	You can use it to store state information about this entity.

=head1 METHODS

=over 4

=item I<new>

  my $entity = Term::Animation::Entity->new(
      shape         => ';-)',
      position      => [ 1, 2, 3 ],
      callback_args => [ 0, 1, 0, 0 ],
  );

Create a Term::Animation::Entity instance. See the PARAMETERS section for
details.

=cut
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	my %p = @_;

	# default sprite is a single asterisk
	unless(defined($p{'shape'})) { $p{'shape'} = '*'; } 

	# if no name is supplied, generate a random one
	if(defined($p{'name'})) {
		$self->{NAME} = $p{'name'};
	} else {
		my $rand_name = rand();
		while(defined($self->{OBJECTS}{$rand_name})) {
			$rand_name = rand();
		}
		$self->{NAME} = $rand_name;
	}

	# appearance
	$self->{TRANSPARENT}		= defined($p{'transparent'})	? $p{'transparent'}		: '?';
	$self->{AUTO_TRANS}		= defined($p{'auto_trans'})	? $p{'auto_trans'}		: 0;
	if($self->{AUTO_TRANS}) { $p{'shape'} = _auto_trans($p{'shape'}, $self->{TRANSPARENT}); }
	($self->{SHAPE}, $self->{HEIGHT}, $self->{WIDTH}) = _build_shape($self, $p{'shape'});
	($self->{X}, $self->{Y}, $self->{Z})	= defined($p{'position'})	? @{$p{'position'}}		: ( 0, 0, 0 );
	$self->{DEF_COLOR}		= defined($p{'default_color'})	? Term::Animation::color_id($p{'default_color'}) : 'w';
	_build_mask($self, $p{'color'});

	# collision detection
	$self->{DEPTH}		= defined($p{'depth'})        ? $p{'depth'}        : 1;
	$self->{PHYSICAL}	= defined($p{'physical'})     ? $p{'physical'}     : 0;
	$self->{COLL_HANDLER}	= defined($p{'coll_handler'}) ? $p{'coll_handler'} : undef;

	# behavior
	$self->{CALLBACK_ARGS}	= defined($p{'callback_args'})? $p{'callback_args'}: undef;
	$self->{WRAP}		= defined($p{'wrap'})         ? $p{'wrap'}         : 0;
	if   (defined($p{'callback'}))      { $self->{CALLBACK} = $p{'callback'}; }
	elsif(defined($p{'callback_args'})) { $self->{CALLBACK} = \&move_entity;  }
	else                                { $self->{CALLBACK} = undef;          }
	$self->{FOLLOW_ENTITY}  = defined($p{'follow_entity'})? $self->_get_entity_name($p{'follow_entity'}) : undef;
	$self->{FOLLOW_OFFSET}  = defined($p{'follow_offset'})? $p{'follow_offset'} : undef;

	# state
	$self->{CURR_FRAME}	= defined($p{'curr_frame'})   ? $p{'curr_frame'}   : 0;

	# entity death
	$self->{DIE_OFFSCREEN}  = defined($p{'die_offscreen'}) ? $p{'die_offscreen'} : 0;
	$self->{DIE_TIME}       = defined($p{'die_time'})      ? $p{'die_time'}      : undef;
	$self->{DIE_FRAME}      = defined($p{'die_frame'})     ? $p{'die_frame'}     : undef;
	$self->{DEATH_CB}	= defined($p{'death_cb'})      ? $p{'death_cb'}      : undef;
	$self->{DCB_ARGS}	= defined($p{'dcb_args'})      ? $p{'dcb_args'}      : undef;
	$self->{DIE_ENTITY}     = defined($p{'die_entity'})    ? $self->_get_entity_name($p{'die_entity'}) : undef;

	# misc
	$self->{TYPE}		= defined($p{'type'})		? $p{'type'}	: "self";
	$self->{DATA}		= defined($p{'data'})		? $p{'data'}	: undef;

	bless($self, $class);
	return $self;
}

=item I<physical>

  $entity->physical( 1 );
  $state = $entity->physical();

Enables or disabled collision detection for this entity.

=cut
sub physical {
	my $self = shift;
	if (@_) {
		my $new_physical = shift;
		if($new_physical != $self->{PHYSICAL}) {
			$self->{PHYSICAL} = $new_physical;
			if(defined($self->{ANIMATION})) {
				$self->{ANIMATION}->_update_physical($self);
			}
		}
	}
        return $self->{PHYSICAL};
}

=item I<auto_trans>

  $entity->auto_trans( 1 );
  $state = $entity->auto_trans();

Enables or disables automatic transparency for this entity's sprite.
This will only affect subsequent calls to I<shape>, the current sprite
will be unchanged.

=cut
sub auto_trans {
	my $self = shift;
	if(@_) { $self->{AUTO_TRANS} = shift; }
	return $self->{AUTO_TRANS};
}

=item I<transparent>

  $entity->transparent( '*' );
  $trans_char = $entity->transparent();

Gets or sets the transparent character for this entity's sprite.
This will only affect subsequent calls to I<shape>, the current
sprite will be unchanged.

=cut
sub transparent {
	my $self = shift;
	if(@_) { $self->{TRANSPARENT} = shift; }
	return $self->{TRANSPARENT};
}

=item I<wrap>

  $entity->wrap( 1 );
  $wrap = $entity->wrap;

Gets or sets the boolean that indicates whether this entity
should wrap around when it gets to an edge of the screen.

=cut
sub wrap {
	my $self = shift;
	if(@_) { $self->{WRAP} = shift; }
	return $self->{WRAP};
}

=item I<data>

  $entity->data( $stuff );
  $data = $entity->data();

Get or set the 'data' associated with the entity. It should
be a single scalar or ref. This can be whatever you want,
it is not used by the module and is provided for convenience.

=cut
sub data {
	my $self = shift;
	if(@_) { $self->{DATA} = shift; }
	return $self->{DATA};
}

=item I<name>

  $name = $entity->name();

Returns the name of the entity.

=cut
sub name {
	my $self = shift;
	return $self->{NAME};
}

=item I<type>

  $entity->type( 'this_type' );
  $type = $entity->type();

Get or set the 'type' of the entity. The type can be any string,
and is not used by the animation itself.

=cut
sub type {
	my $self = shift;
	if (@_) { $self->{TYPE} = shift }
        return $self->{TYPE};
}

=item I<frame>

  $entity->frame( 3 );
  $current_frame = $entity->frame();

Gets or sets the current animation frame of the entity.

=cut
sub frame {
	my $self = shift;
	if (@_) {
		my $new_frame = shift;
		unless($new_frame =~ /^\d+$/ &&
			$new_frame >= 0 &&
			$new_frame <= $#{$self->{SHAPE}}) {
			carp "Invalid frame number: $new_frame\n";
			return $self->{CURR_FRAME};
		}
		$self->{CURR_FRAME} = $new_frame;
	}
	return $self->{CURR_FRAME};
}

=item I<width>

  my $width = $entity->width();

Returns the width (columns) of the entity.

=cut
sub width {
	my $self = shift;
	return $self->{WIDTH};
}

=item I<height>

  my $height = $entity->height();

Returns the height (rows) of the entity.

=cut
sub height {
	my $self = shift;
	return $self->{HEIGHT};
}

=item I<depth>

  my $depth = $entity->depth();

Returns the depth of the entity.

=cut
sub depth {
	my $self = shift;
	return $self->{DEPTH};
}

=item I<size>

  my ($width, $height, $depth) = $entity->size();

Returns the X / Y / Z dimensions of the entity.

=cut

sub size {
	my $self = shift;
	return ($self->{WIDTH}, $self->{HEIGHT}, $self->{DEPTH});
}

=item I<position>

  my ($x, $y, $z) = $entity->position();
  $entity->position($x, $y, $z);

Gets or sets the X / Y / Z coordinates of the entity. You can also
access each coordinate individually.

  my $x = $entity->x;
  $entity->x(5);

Note that you should normally position an entity using its callback routine,
instead of calling one of these methods.

=cut
sub position {
	my $self = shift;
	if(@_) { ($self->{X}, $self->{Y}, $self->{Z}) = @_; }
	return ($self->{X}, $self->{Y}, $self->{Z});
}

sub x {
	my $self = shift;
	if(@_) { ($self->{X}) = @_ }
	return $self->{X};
}

sub y {
	my $self = shift;
	if(@_) { ($self->{Y}) = @_ }
	return $self->{Y};
}

sub z {
	my $self = shift;
	if(@_) { ($self->{Z}) = @_ }
	return $self->{Z};
}

=item I<callback_args>

  $entity->callback_args( $args );
  $args = $entity->callback_args();

Get or set the arguments to the entity's callback routine. This
should be either a single scalar or a single ref.

=cut
sub callback_args {
	my $self = shift;
	if(@_) { $self->{CALLBACK_ARGS} = shift; }
	return $self->{CALLBACK_ARGS};
}

=item I<callback>

  $entity->callback( \&callback_routine );
  $callback_routine = $entity->callback();

Get or set the callback routine for the entity

=cut
sub callback {
	my $self = shift;
	if(@_) { $self->{CALLBACK} = shift; }
	return $self->{CALLBACK};
}

=item I<death_cb>

  $entity->death_cb( \&death_callback_routine );
  $death_callback_routine = $entity->death_cb();

Get or set the callback routine that is called
when the entity dies. Set to undef if you do not
want anything to be called.

=cut
sub death_cb {
	my $self = shift;
	if(@_) { $self->{DEATH_CB} = shift; }
	return $self->{DEATH_CB};
}

=item I<die_offscreen>

  $entity->die_offscreen( 1 );
  $die_offscreen = $entity->die_offscreen;

Get or set the flag that indicates whether this
entity should die when it is entirely off the screen.

=cut
sub die_offscreen {
	my $self = shift;
	if(@_) { $self->{DIE_OFFSCREEN} = shift; }
	return $self->{DIE_OFFSCREEN};
}

=item I<die_frame>

  $entity->die_frame( 1 );
  $die_frame = $entity->die_frame;

Get or set the frame number in which this entity
should die, counting from the time when die_frame
is called. Set to undef to disable.

=cut
sub die_frame {
	my $self = shift;
	if(@_) { $self->{DIE_FRAME} = shift; }
	return $self->{DIE_FRAME};
}

=item I<die_time>

  $entity->die_time( time() + 20 );
  $die_time = $entity->die_time;

Get or set the time at which this entity should die.
The time is a UNIX epoch time. Set to undef to disable.

=cut
sub die_time {
	my $self = shift;
	if(@_) { $self->{DIE_TIME} = shift; }
	return $self->{DIE_TIME};
}

=item I<die_entity>

  $entity->die_entity( $other_entity );
  $other_entity = $entity->die_entity;

Get or set an entity whose death will cause the
death of this entity. Either an entity name or
Term::Animation::Entity reference are accepted, but
an entity name is always returned. Set to undef to disable.

=cut
sub die_entity {
	my $self = shift;
	if(@_) {
		my $ent = shift;
		if(ref($ent)) {
			$ent = $ent->name;
		}
		$self->{DIE_ENTITY} = $ent;
	}
	return $self->{DIE_ENTITY};
}

sub follow_entity {
	my $self = shift;
	if(@_ && defined($self->animation)) {
		
		my ($ent) = @_;

		if(defined($ent)) {
			$self->{FOLLOW_ENTITY} = $self->_get_entity_name($ent);
		} else {
			$self->{FOLLOW_ENTITY} = undef;
		}
	}
	return $self->{FOLLOW_ENTITY};

}

sub follow_offset {
	my $self = shift;

	if(@_) {
		$self->{FOLLOW_OFFSET} = shift;
	}
	return $self->{FOLLOW_OFFSET};
}

=item I<shape>

  $entity->shape($new_shape);
 
Set the sprite image for the entity. See the C<shape> argument
to I<new> for details. 

=cut
sub shape {
	my $self = shift;
	if(@_) {
		my $shape = shift;
		if($self->{AUTO_TRANS}) {
			$shape = _auto_trans($shape, $self->{TRANSPARENT});
		}
		($self->{SHAPE},$self->{HEIGHT},$self->{WIDTH}) = $self->_build_shape($shape);
	}
}

=item I<collisions>

  $collisions = $entity->collisions();

Returns a reference to a list of entities that this entity
collided with during this animation cycle.

=cut
sub collisions {
	my $self = shift;
	return $self->{COLLISIONS};
}

=item I<animation>

  $entity->animation( $anim );
  $anim = $entity->animation();

Get or set the Term::Animation object that this entity is
part of.

=cut
sub animation {
	my $self = shift;
	if(@_) { $self->{ANIMATION} = shift; }
	return $self->{ANIMATION};
}

=item I<default_color>

  $entity->default_color( 'blue' );
  $def_color = $entity->default_color();

Get or set the default color for the entity. The color can
be either a single character or the full name of the color.

=cut
sub default_color {
	my $self = shift;
	if(@_) {
		my $color = shift;
		if(is_valid_color($color)) {
			$self->{DEF_COLOR} = color_id($color);
			$self->_build_mask();
		} else {
			carp("Invalid color supplied: $color");
		}
	}
	return $self->{DEF_COLOR};
}

=item I<color_mask>

  $entity->color_mask( $mask );

Set the color mask for the entity. See the L<Term::Animation/COLOR|COLOR> section of
L<Term::Animation> for details.

=cut
sub color_mask {
	my $self = shift;
	if(@_) { $self->_build_mask(shift); }
}



=item I<move_entity>

The default callback. You can also call this from your own
callback to do the work of moving and animating the entity
after you have done whatever other processing you want to do.

  sub my_callback {
    my ($entity, $animation) = @_;
    
    # do something here
    
    return $entity->move_object($animation);

  }

=cut
sub move_entity {
	my ($ent, $anim) = @_;
	my $cb_args;
	my $f;
	# figure out if we just have a set of deltas, or if we have
	# a full animation path to follow
	if(ref($ent->{CALLBACK_ARGS}[1]) eq 'ARRAY') {
		$cb_args = $ent->{CALLBACK_ARGS}[1][$ent->{CALLBACK_ARGS}[0]];
		$ent->{CALLBACK_ARGS}[0]++;
		if($ent->{CALLBACK_ARGS}[0] > $#{$ent->{CALLBACK_ARGS}[1]}) {
			$ent->{CALLBACK_ARGS}[0] = 0;
		}
		$f = $cb_args->[3];
	} else {
		$cb_args = $ent->{CALLBACK_ARGS};
		if($cb_args->[3]) {
			$f = $ent->{CURR_FRAME} + $cb_args->[3];
			$f = ($f - int($f)) + ($f % ($#{$ent->{SHAPE}} + 1));
		}
	}

	my $x = $ent->{X} + $cb_args->[0];
	my $y = $ent->{Y} + $cb_args->[1];
	my $z = $ent->{Z} + $cb_args->[2];

	if($ent->{WRAP}) {
		if($x >= $anim->{WIDTH})  { $x = ($x - int($x)) + ($x % $anim->{WIDTH});  }
		elsif($x < 0)            { $x = ($x - int($x)) + ($x % $anim->{WIDTH});  }
		if($y >= $anim->{HEIGHT}) { $y = ($y - int($y)) + ($y % $anim->{HEIGHT}); }
		elsif($y < 0)            { $y = ($y - int($y)) + ($y % $anim->{HEIGHT}); }
	}
	return($x, $y, $z, $f);
}

=item I<kill>

  $entity->kill();

Remove this entity from the animation. This is equivilent
to:

  $animation->del_entity($entity);

This does not destroy the object, so you can still
readd it later (or put it in a different animation) as long
as you have a reference to it.

=cut
sub kill {
	my $self = shift;
	if(defined($self->{ANIMATION})) {
		$self->{ANIMATION}->del_entity($self);
	}
}

# create a color mask for an entity
sub _build_mask {
	my ($self, $shape) = @_;

	my @amask;
	my $mask = ();

	# store the color mask in case we are asked to 
	# change the default color later
	if(defined($shape)) {
		$self->{SUPPLIED_MASK} = $shape;
		($mask) = _build_shape($self, $shape);
	} elsif(defined($self->{SUPPLIED_MASK})) {
		$shape = $self->{SUPPLIED_MASK};
		($mask) = _build_shape($self, $shape);
	}

	# if we were given fewer mask frames
	# than we have animation frames, then
	# repeat what we got to make up the difference.
	# this allows the user to pass a single color
	# mask that is the same for every animation frame
	if($#{$mask} < $#{$self->{SHAPE}}) {
		my $diff = $#{$self->{SHAPE}} - $#{$mask};
		for (1..$diff) {
			push(@{$mask}, $mask->[$_ - 1]);
		}
	}

	$self->{COLOR} = ();
	for my $f (0..$#{$self->{SHAPE}}) {
		for my $i (0..$self->{HEIGHT}-1) {
			for my $j (0..$self->{WIDTH}-1) {
				if(!defined($mask->[$f][$i][$j]) or $mask->[$f][$i][$j] eq ' ') {
					$mask->[$f][$i][$j] = $self->{DEF_COLOR};
				} elsif(defined($mask->[$f][$i][$j])) {
					# make sure it's a valid color
					unless(Term::Animation::is_valid_color($mask->[$f][$i][$j]) ) {
						carp("Invalid color mask: $mask->[$f][$i][$j]");
						$mask->[$f][$i][$j] = undef;
					}
				}

				# capital letters indicate bold colors
				if($mask->[$f][$i][$j] =~ /[A-Z]/) {
					$self->{COLOR}->[$f][$i][$j] = lc($mask->[$f][$i][$j]);
					$amask[$f][$i][$j] = Curses::A_BOLD;
				} else {
					$self->{COLOR}->[$f][$i][$j] = lc($mask->[$f][$i][$j]);
				}
			}
		}
	}
	$self->{ATTR} = \@amask;
}

# automatically make whitespace appearing on a line before the first non-
# whitespace character transparent
sub _auto_trans {
	my ($shape, $char) = @_;
	unless(defined($char)) { $char = '?'; }

	if(ref($shape) eq 'ARRAY') {
		my @shape_array = ();
		foreach my $i (0..$#{$shape}) {
			if(ref($shape->[$i] eq 'ARRAY')) {
				# unimplemented
			}
			else { push(@shape_array, _trans_fill_string($shape->[$i], $char)); }
		}
		return \@shape_array;
	} else {
		return _trans_fill_string($shape, $char);
	}

}

# called by _auto_trans to handle a single string
sub _trans_fill_string {
	my ($shape, $char) = @_;
	my $new = '';
	foreach my $line (split("\n", $shape)) {
		my $len = length(($line =~ /^(\s*)/)[0]);
		my $fill = ${char}x$len;
		$line =~ s/^\s{$len}/$fill/;
		$new .= $line . "\n";
	}
	return $new;
}

# take one of 1) a string 2) an array of strings 3) an array of 2D arrays
# use these to generate a shape in the format we want (which is #3 above)
sub _build_shape {
	my ($self, $shape) = @_;

	my @shape_array = ();
	my $height = 0;
	my $width = 0;

	if(ref($shape) eq 'ARRAY') {
		for my $i (0..$#{$shape}) {
			my $this_height = 0;
			if(ref($shape->[$i]) eq 'ARRAY') {
				$this_height = $#{$shape->[$i]};
				$shape_array[$i] = $shape->[$i];
			}
			else {
				# strip an empty line from the top, for convenience
				$shape->[$i] =~ s/^\n//;
				for my $line (split("\n", $shape->[$i])) {
					$this_height++;
					if(length($line) > $width) { $width = length($line); }
					push @{$shape_array[$i]}, [split('', $line)];
				}
			}
			if($this_height > $height) { $height = $this_height; }
		}
	} else {
		# strip an empty line from the top, for convenience
		$shape =~ s/^\n//;
		for my $line (split("\n", $shape)) {
			$height++;
			if(length($line) > $width) { $width = length($line); }
			push @{$shape_array[0]}, [split('', $line)];
		}
	}
	return \@shape_array, $height, $width;
}

# look up the name of an entity if given an entity,
# just return the string if we got a string
sub _get_entity_name {
	my ($self, $entity) = @_;

	if(ref($entity)) {
		return $entity->name;
	} else {
		return $entity;
	}
}

1;

=back

=head1 AUTHOR

Kirk Baucom E<lt>kbaucom@schizoid.comE<gt>

=head1 SEE ALSO

L<Term::Animation|Term::Animation>

=cut
