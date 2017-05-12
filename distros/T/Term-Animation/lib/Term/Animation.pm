package Term::Animation;

use 5.006;
use strict;
use warnings;
use Carp;
use Curses;
use Term::Animation::Entity;

use Data::Dumper;

=head1 NAME

Term::Animation - ASCII sprite animation framework

=head1 SYNOPSIS

  use Term::Animation;

  # Constructors
  $anim = Term::Animation->new();
  $anim = Term::Animation->new($curses_window);

=head1 ABSTRACT

A framework to produce sprite animations using ASCII art.

=head1 DESCRIPTION

This module provides a framework to produce sprite animations using
ASCII art. Each ASCII 'sprite' is given one or more frames, and placed
into the animation as an 'animation object'. An animation object can
have a callback routine that controls the position and frame of the
object.

If the constructor is passed no arguments, it assumes that it is 
running full screen, and behaves accordingly. Alternatively, it can
accept a curses window (created with the Curses I<newwin> call) as an
argument, and will draw into that window.

=head1 EXAMPLES

This example moves a small object across the screen from left to right.

    use Term::Animation;
    use Curses;

    $anim = Term::Animation->new();

    # set the delay for getch
    halfdelay( 2 );

    # create a simple shape we can move around
    $shape = "<=O=>";

    # turn our shape into an animation object
    $anim->new_entity(
                 shape         => $shape,        # object shape
                 position      => [3, 7, 10],    # row / column / depth
                 callback_args => [1, 0, 0, 0],  # the default callback
                                                 #  routine takes a list
                                                 #  of x,y,z,frame deltas
                 wrap          => 1              # turn screen wrap on
    );

    # animation loop
    while(1) {
      # run and display a single animation frame
      $anim->animate();

      # use getch to control the frame rate, and get input at the
      # same time. (not a good idea if you are expecting much input)
      my $input = getch();
      if($input eq 'q') { last; }
    }

    # cleanly end the animation, to avoid hosing up the user's terminal
    $anim->end();

This illustrates how to draw your animation into an existing Curses window.

    use Term::Animation;
    use Curses;

    # Term::Animation will not call initscr for you if
    # you pass it a window
    initscr();

    $win = newwin(5,10,8,7);

    $anim = Term::Animation->new($win);

Everything else would be identical to the previous example.

=head1 METHODS

=over 4

=cut

our $VERSION = '2.6';

our ($color_names, $color_ids) = _color_list();

=item I<new>

  $anim = Term::Animation->new();
  $anim = Term::Animation->new($curses_window);

The constructor. Optionally takes an existing curses window
to draw in.

=cut
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};

	$self->{ENTITIES} = {};
	$self->{ENTITYCOUNT} = 0;
	$self->{PHYSICALENTITIES} = {};
	$self->{PHYSICALCOUNT} = 0;
	$self->{COLOR_ENABLED} = 0;
	$self->{LAST_FRAME_TIME} = 0;

	# framerate related settings
	$self->{TRACK_FRAMERATE} = 1;
	$self->{FRAMERATE} = 0;
	$self->{FRAMES_THIS_SECOND} = 0;

	$self->{WIN} = shift;
	if(defined($self->{WIN})) {
		unless(ref($self->{WIN}) eq 'Curses::Window') {
			carp("Expecting Curses::Window object, recieved " . ref($self->{WIN}));
			return undef;
		}
		$self->{FULLSCREEN} = 0;
	} else {
		# this is the method in the docs...
		$self->{WIN} = new Curses;
		# ...but apparently it's broken with some versions of Curses or ncurses.
		# this seems to work everywhere, but the Curses.pm docs
		# say to call the constructor when using objects.
		unless(defined($self->{WIN})) {
			$self->{WIN} = Curses::initscr();
		}

		noecho();
		curs_set(0);
		$self->{FULLSCREEN} = 1;
	}

	($self->{WIDTH}, $self->{HEIGHT}, $self->{ASSUMED_SIZE}) = _get_term_size($self->{WIN});
	bless ($self, $class);
	return $self;
}

sub DESTROY {
	my ($self) = @_;
	if($self->{FULLSCREEN}) {
		endwin();
	}
}

=item I<new_entity>

  $anim->new_entity(
  	shape         => $shape,
	position      => [ 1, 2, 3 ],
	callback_args => [ 1, 0, 0 ]
  );

Creates a new Term::Animation::Entity object and adds it to the
animation. This is identical to:

  my $entity = Term::Animation::Entity->new(...);
  $anim->add_entity($entity);

See L<Term::Animation::Entity/PARAMETERS|PARAMETERS> and L<Term::Animation::Entity/new|new>
in L<Term::Animation::Entity> for details on calling this method.

=cut
sub new_entity {
	my ($self, @ent_args) = @_;
	my $entity = Term::Animation::Entity->new(@ent_args);
	$self->add_entity($entity);
	return $entity;
}

##################### COLOR UTILITIES #######################

# create lists mapping full color names (eg. 'blue') and
# single character color ids (eg. 'b')
sub _color_list {
	my %color_n;
	my %color_i = (
		black	=> 'k',
		white	=> 'w',
		red	=> 'r',
		green	=> 'g',
		blue	=> 'b',
		cyan	=> 'c',
		magenta	=> 'm',
		yellow	=> 'y',
	);

	for (keys %color_i) {
		$color_i{uc($_)} = uc($color_i{$_});
	}

	for (keys %color_i) {
		$color_n{$color_i{$_}} = $_;
		$color_n{$_} = $_;
		$color_n{uc($_)} = uc($_);
	}

	for(qw{ k w r g b c m y }) {
		$color_i{$_} = $_;
		$color_i{uc($_)} = uc($_);
	}

	return (\%color_n, \%color_i);
}

# build a list of every color combination for our current
# background color
sub _set_colors {
	my ($self) = @_;

	my $cid = 1;

	my $bg = eval "Curses::COLOR_$self->{BG}";

	for my $f ('w', 'r', 'g', 'b', 'c', 'm', 'y', 'k') {
		my $c = uc(color_name($f));
		init_pair($cid, eval "Curses::COLOR_$c", $bg);
		$self->{COLORS}{$f} = COLOR_PAIR($cid);
		$cid++;
	}
}

=item I<color_name>

  $name = $anim->color_name( $color );

Returns the full name of a color, given either a full
name or a single character abbreviation.

=cut
sub color_name {
	my ($color) = @_;
	if(defined($color_names->{$color})) {
		return $color_names->{$color};
	} else {
		carp("Attempt to allocate unknown color: $color");
		return undef;
	}
}

=item I<color_id>

  $id = $anim->color_id( $color );

Returns the single character abbreviation for a color, 
given either a full name or abbreviation.

=cut
sub color_id {
	my ($color) = @_;
	if(defined($color_ids->{$color})) {
		return $color_ids->{$color};
	} else {
		carp("Attempt to allocate unknown color: $color");
		return undef;
	}
}

=item I<is_valid_color>

  my $is_valid = $anim->is_valid_color($color_name);

Returns true if the supplied string is a valid color name ('blue')
or a valid color id ('b').

=cut
sub is_valid_color {
	my ($color) = @_;
	return(defined($color_ids->{$color}));
}

=item I<color>

  my $state = $anim->color();
  $anim->color($new_state);

Enable or disable ANSI color. This MUST be called immediately after creating
the animation object if you want color, because the Curses start_color call must 
be made immediately. You can then turn color on and off whenever you want.

=cut
sub color {
	my $self = shift;
	if(@_) {
		my $enable = shift;
		if($enable != $self->{COLOR_ENABLED}) {
			if($enable) {
				start_color();
				unless(defined($self->{BG})) { $self->{BG} = 'BLACK'; }
				$self->_set_colors();
				$self->{WIN}->bkgdset($self->{COLORS}{'w'});
			}
			$self->{COLOR_ENABLED} = $enable;
		}
	}
	return $self->{COLOR_ENABLED};
}

=item I<background>

  $anim->background( $color );

Change the background color. The default background color is black. You
can only have one background color for the entire Curses window that
the animation is running in.

=cut
sub background {
	my $self = shift;
	if(@_) {
		my $color = shift;
		my $bg_color = color_name($color);
		if(defined($bg_color)) {
			$self->{BG} = uc($bg_color);
			$self->_set_colors();
			$self->{WIN}->bkgdset($self->{COLORS}{'w'});
		}
	}
	return $self->{BG};
}

########## END COLOR UTILITIES ###########

########################## PHYSICS UTILITIES ##########################


# go through all of the physical entities looking for
# collisions.
sub _find_collisions {
	my ($self) = @_;

	my @col_set = ();
	my @coord = ();
	my @size = ();
	my @name = ();

	for my $ent (values %{$self->{ENTITIES}}) {
		next unless($ent->physical());
		push(@coord, [ $ent->position() ]);
		push(@size, [ $ent->size() ]);
		push(@name, $ent->name());

		for my $i (0..($#name-1)) {
			# X
			if( ($coord[$i][0] <= $coord[-1][0] and $coord[-1][0] < $coord[$i][0] + $size[$i][0]) or
				($coord[-1][0] <= $coord[$i][0] and $coord[$i][0] < $coord[-1][0] + $size[-1][0]) ) {
				# Y
				if( ($coord[$i][1] <= $coord[-1][1] and $coord[-1][1] < $coord[$i][1] + $size[$i][1]) or
					($coord[-1][1] <= $coord[$i][1] and $coord[$i][1] < $coord[-1][1] + $size[-1][1]) ) {
					# Z
					if( ($coord[$i][2] <= $coord[-1][2] and $coord[-1][2] < $coord[$i][2] + $size[$i][2]) or
						($coord[-1][2] <= $coord[$i][2] and $coord[$i][2] < $coord[-1][2] + $size[-1][2]) ) {
						push( @{$ent->{COLLISIONS}}, $self->{ENTITIES}{$name[$i]} );
						push( @{$self->{ENTITIES}{$name[$i]}{COLLISIONS}}, $ent );

					}
				}
			}
		}
	}

	return;
}

# update the list of physical entities when the physical state
# of an entity changes
sub _update_physical {
	my ($self, $entity) = @_;
	if($entity->{PHYSICAL} && !defined($self->{PHYSICALENTITIES}{$entity->{NAME}})) {
		$self->{PHYSICALCOUNT}++;
		$self->{PHYSICALENTITIES}{$entity->{NAME}} = $entity;
	} elsif(defined($self->{PHYSICALENTITIES}{$entity->{NAME}})) {
		$self->{PHYSICALCOUNT}--;
		delete $self->{PHYSICALENTITIES}{$entity->{NAME}};
	}
}

########## END PHYSICS UTILITIES ###########

=item I<animate>

  $anim->animate();

Perform a single animation cycle. Runs all of the callbacks,
does collision detection, and updates the display.

=cut
sub animate {
	my ($self) = @_;
	$self->_do_callbacks();
	if($self->{PHYSICALCOUNT} > 0) {
		$self->_find_collisions();
		$self->_collision_handlers();
	}
	$self->_remove_deleted_entities();
	$self->_move_followers();
	$self->_build_screen();
	$self->_display_screen();
	$self->_track_frame_rate() if $self->{TRACK_FRAMERATE};
}

sub _track_frame_rate {
	my ($self) = @_;
	my $time = time();
	if($time > $self->{LAST_FRAME_TIME}) {
		$self->{LAST_FRAME_TIME} = $time;
		$self->{FRAMERATE} = ($self->{FRAMERATE} + ($self->{FRAMES_THIS_SECOND} * 2) ) / 3;
		$self->{FRAMES_THIS_SECOND} = 1;
	} else {
		$self->{FRAMES_THIS_SECOND}++;
	}
}

=item I<track_framerate>

  $anim->track_framerate(1);
  $tracking_framerate = $anim->track_framerate();

Get or set the flag that indicates whether the module
should keep track of the animation framerate. This is
enabled by default.

=cut
sub track_framerate {
	my ($self) = @_;
	if(@_) {
		$self->{TRACK_FRAMERATE} = shift;
	}
	return $self->{TRACK_FRAMERATE};
}

=item I<framerate>

  $frames_per_second = $anim->framerate();

Returns the approximate number of frames being displayed
per second, as indicated by calls to the I<animate> method.

=cut
sub framerate {
	my ($self) = @_;
	return $self->{FRAMERATE};
}

=item I<screen_size>

  my ($width, $height, $assumed_size) = $anim->screen_size();

Returns the width and height of the screen. The third value
returned is a boolean indicating whether or not the default
screen size was used, because the size could not be determined.

=cut
sub screen_size {
	my $self = shift;
	return($self->{WIDTH}, $self->{HEIGHT}, $self->{ASSUMED_SIZE});
}

=item I<update_term_size>

  $anim->update_term_size();

Call this if you suspect the terminal size has changed (eg. if you
get a SIGWINCH signal). Call I<remove_all_entities> after this if
you want to recreate your animation from scratch.

=cut
sub update_term_size {
	my $self = shift;
	# dunno how portable this is. i should probably be using
	# resizeterm.
	endwin();
	refresh();
	($self->{WIDTH}, $self->{HEIGHT}, $self->{ASSUMED_SIZE}) = _get_term_size($self->{WIN});
}

# try to figure out the terminal size, and set
# a reasonable size if we can't. the 'assumed_size'
# variable will let programs know if we had to
# guess or not.
sub _get_term_size {
	my $win = shift;
	my ($width, $height, $assumed_size);
	# find the width and height of the terminal
	$width = $win->getmaxx();
	$height = $win->getmaxy();
	if($width and $height) {
		$assumed_size = 0; # so we know if we can limit the max size or not
	} else {
		$assumed_size = 1;
		$width = 80;
		$height = 24;
	}
	return($width, $height, $assumed_size);
}

# write to the curses window
sub _build_screen {
	my($self) = @_;

	# clear the window before we start redrawing
	$self->{WIN}->addstr( 0, 0, ' 'x$self->size() );

	return unless($self->{ENTITYCOUNT});
	foreach my $entity (sort {$b->{'Z'} <=> $a->{'Z'}} values %{$self->{ENTITIES}}) {
		_draw_entity($self, $entity);
	}
}

# draw an entity into the curses window in memory
sub _draw_entity {
	my ($self, $entity) = @_;

	# a few temporary variables to make the code below easier to read
	my $shape   = $entity->{SHAPE}[$entity->{CURR_FRAME}];
	my $colors  = $self->{COLORS};
	my $fg      = $entity->{COLOR}[$entity->{CURR_FRAME}];
	my $attrs   = $entity->{ATTR}[$entity->{CURR_FRAME}];
	my ($x, $y) = ($entity->{'X'}, $entity->{'Y'});
	my ($w, $h) = ($self->{WIDTH}, $self->{HEIGHT});
	my $wrap    = $entity->{WRAP};
	my $trans   = $entity->{TRANSPARENT};
	my $win     = $self->{WIN};
	my $color_enabled = $self->{COLOR_ENABLED};
	my $attr;

	for my $i (0..$#{$shape}) {
		my $y_pos = $y+$i;

		for my $j (0..$#{$shape->[$i]}) {
			unless($shape->[$i][$j] eq $trans) { # transparent char
				my $x_pos = $x+$j;

				if($wrap) {
					while($x_pos >= $w) { $x_pos -= $w; }
					while($y_pos >= $h) { $y_pos -= $h; }
				} elsif($x_pos >= $w or $y_pos >= $h) {
					next;
				}

				unless($x_pos < 0 or $y_pos < 0) {
					if($color_enabled) {
						if(defined($attrs->[$i][$j])) {
							$attr = $colors->{$fg->[$i][$j]} | $attrs->[$i][$j];
						} else {
							$attr = $colors->{$fg->[$i][$j]};
						}

						$win->attron( $attr );
						$win->addstr( int($y_pos), int($x_pos), $shape->[$i][$j]);
						$win->attroff( $attr );
					} else {
						$win->addstr( int($y_pos), int($x_pos), $shape->[$i][$j]);
					}
				}
			}
		}
	}
}

=item I<add_entity>

  $anim->add_entity( $entity1, $entity2, $entity3 );

Add one or more animation entities to the animation.

=cut
sub add_entity {
	my ($self, @entities) = @_;
	foreach my $entity (@entities) {
		$self->{ENTITYCOUNT}++;
		if($entity->{PHYSICAL}) {
			$self->{PHYSICALCOUNT}++;
			$self->{PHYSICALENTITIES}{$entity->{NAME}} = $entity;
		}
		$self->{ENTITIES}{$entity->{NAME}} = $entity;
		$entity->{ANIMATION} = $self;
	}
}

=item I<del_entity>

  $anim->del_entity( $entity_name );
  $anim->del_entity( $entity_ref );

Removes an entity from the animation. Accepts either an entity
name or a reference to the entity itself.

=cut
sub del_entity {
	my ($self, $entity) = @_;
	if(ref($entity)) {
		$entity = $entity->name();
	}
	if(defined($self->{ENTITIES}{$entity})) {
		push(@{$self->{DELETEQUEUE}}, $entity);
	} else {
		carp("Attempted to destroy nonexistant entity '$entity'");
	}
}

# go through the list of entities that have been queued for
# deletion using del_entity and remove them
sub _remove_deleted_entities {
	my ($self) = @_;
	while(my $entity_name = shift @{$self->{DELETEQUEUE}}) {
		my $entity = $self->{ENTITIES}{$entity_name};
		if(defined($entity->{DEATH_CB})) {
			$entity->{DEATH_CB}->($entity, $self);
		}
		if($entity->{PHYSICAL}) {
			$self->{PHYSICALCOUNT}--;
			delete $self->{PHYSICALENTITIES}{$entity_name};
		}
		delete $self->{ENTITIES}{$entity_name};
		$self->{ENTITYCOUNT}--;
	}
}

=item I<remove_all_entities>

  $anim->remove_all_entities();

Removes every animation object. This is useful if you need to start the
animation over (eg. after a screen resize)

=cut
sub remove_all_entities {
	my ($self) = @_;
	$self->{ENTITYCOUNT} = 0;
	$self->{PHYSICALCOUNT} = 0;
	$self->{PHYSICALENTITIES} = {};
	$self->{ENTITIES} = {};
}

=item I<entity_count>

  $number_of_entities = $anim->entity_count();

Returns the number of entities in the animation.

=cut
sub entity_count {
	my ($self) = @_;
	my $count = 0;
	foreach (keys %{$self->{ENTITIES}}) {
		$count++;
	}
	return $count;
}

=item I<get_entities>

  $entity_list = $anim->get_entities();

Returns a reference to a list of all entities in the animation.

=cut
sub get_entities {
	my ($self) = @_;
	my @entities = keys %{$self->{ENTITIES}};
	return \@entities;
}

=item I<get_entities_of_type>

  $entity_list = $anim->get_entities_of_type( $type );

Returns a reference to a list of all entities in the animation
that have the given type.

=cut
sub get_entities_of_type {
	my ($self, $type) = @_;
	my @entities;
	foreach my $entity (values %{$self->{ENTITIES}}) {
		if($entity->{TYPE} eq $type) {
			push(@entities, $entity->{NAME});
		}
	}
	return \@entities;
}

=item I<is_living>

  my $is_living = $anim->is_living( $entity );

Return 1 if the entity name or reference is in the animation
and is not scheduled for deletion. Returns 0 otherwise.

=cut
sub is_living {
	my ($self, $entity) = @_;

	if(ref($entity) eq 'Term::Animation::Entity') {
		$entity = $entity->name();
	}

	unless(exists($self->{'ENTITIES'}{$entity})) {
		return 0;
	}

	foreach my $dying_ent (@{$self->{DELETEQUEUE}}) {
		if($dying_ent eq $entity) {
			return 0;
		}
	}

	return 1;
}

=item I<entity>

  $entity_ref = $anim->entity( $entity_name );

If the animation contains an entity with the given name,
the Term::Animation::Entity object associated with the name
is returned. Otherwise, undef is returned.

=cut
sub entity {
	my ($self, $entity_name) = @_;
	if(defined($self->{ENTITIES}{$entity_name})) {
		return $self->{ENTITIES}{$entity_name};
	} else {
		return undef;
	}
}

=item I<width>

  $width = $anim->width();

Returns the width of the screen

=cut
sub width {
	my ($self) = @_;
	return $self->{WIDTH};
}

=item I<height>

  $height = $anim->height();

Returns the height of the screen

=cut
sub height {
	my ($self) = @_;
	return $self->{HEIGHT};
}

=item I<size()>

  $size = $anim->size();

Returns the number of characters in the curses window (width * height)

=cut
sub size {
	my ($self) = @_;
	return ( $self->{HEIGHT} * $self->{WIDTH} )
}

=item I<redraw_screen>

  $anim->redraw_screen();

Clear everything from the screen, and redraw what should be there. This
should be called after I<update_term_size>, or if the user indicates that
the screen should be redrawn to get rid of artifacts.

=cut
sub redraw_screen {
	my ($self) = @_;
	$self->{WIN}->clear();
	$self->{WIN}->refresh();
	$self->_build_screen();
	$self->{WIN}->move($self->{HEIGHT}-1, $self->{WIDTH}-1);
	$self->{WIN}->refresh();
}

# draw the elements of the screen that have changed since the last update
sub _display_screen {
	my ($self) = @_;
	$self->{WIN}->move($self->{HEIGHT}-1, $self->{WIDTH}-1);
	$self->{WIN}->refresh();
}


=item I<gen_path>

  # gen_path (x,y,z, x,y,z, [ frame_pattern ], [ steps ])

  $anim->gen_path( $x1, $y1, $z1, $x2, $y2, $z2, [ 1, 2, 0, 2 ], 'longest' );

Given beginning and end points, this will return a path for the
entity to follow that can be given to the default callback routine,
I<move_entity>. The first set of x,y,z coordinates are the point
the entity will begin at, the second set is the point the entity
will end at. 

You can optionally supply a list of frames to cycle through. The list
will be repeated as many times as needed to finish the path. If no
list of frames is supplied, only the first frame will be used.

You can also request the number of steps you would like for the entity
to take to finish the path. The default is 'shortest'.
Valid arguments are:
  longest      The longer of the X and Y distances
  shortest     The shorter of the X and Y distances
  X,Y or Z     The x, y or z distance
  <number>     Explicitly specify the number of steps to take

=cut
sub gen_path {
	my ($self, $x_start, $y_start, $z_start, $x_end, $y_end, $z_end, $frame_pattern, $steps_req) = @_;
	my @path = ();
	my $steps;

	my $x_dis = $x_end - $x_start;
	my $y_dis = $y_end - $y_start;
	my $z_dis = $z_end - $z_start;

	unless(defined($frame_pattern)) {
		$frame_pattern = [ 0 ];
	}

	# default path length if none specified
	unless(defined($steps_req)) {
		$steps_req = 'shortest';
	}

	if($steps_req eq 'shortest' or $steps_req eq 'longest') {
		if($x_dis == $y_dis)  { $steps = $y_dis; }
		elsif($x_dis == 0)    { $steps = $y_dis; }
		elsif($y_dis == 0)    { $steps = $x_dis; }
		elsif(abs($x_dis) < abs($y_dis)) {
			if($steps_req eq 'shortest') { $steps = $x_dis; }
			else { $steps = $y_dis; }
		} else {
			if($steps_req eq 'shortest') { $steps = $y_dis; }
			else { $steps = $x_dis; }
		}
	}
	elsif($steps_req =~ /^\d+$/) { $steps = $steps_req; }
	elsif(uc($steps_req) eq 'X') { $steps = $x_dis; }
	elsif(uc($steps_req) eq 'Y') { $steps = $y_dis; }
	elsif(uc($steps_req) eq 'Z') { $steps = $z_dis; }
	else {
		carp("Unknown path length method: $steps_req"); return();
	}

	$steps = abs($steps);

	if($steps == 0) { carp("Cannot create a zero length path!"); return (); }
	elsif($steps == 1) {
		# a path length of one is a special case where we just move from the origin to the destination
		$path[0] = [($x_end - $x_start), ($y_end - $y_start), ($z_end - $z_start), $frame_pattern->[0]];
		return \@path;
	}

	my $x_incr = $x_dis / $steps;
	my $y_incr = $y_dis / $steps;
	my $z_incr = $z_dis / $steps;

	my ($x_pos, $y_pos, $z_pos) = ($x_start, $y_start, $z_start);
	my ($x_act, $y_act, $z_act) = ($x_start, $y_start, $z_start);

	for(0..$steps-2) {
		my ($x_prev, $y_prev, $z_prev) = ($x_pos, $y_pos, $z_pos);

		$x_pos+=$x_incr; $y_pos+=$y_incr; $z_pos+=$z_incr;
		my $f_pos = $frame_pattern->[${_}%($#{$frame_pattern}+1)];

		my ($x_mov, $y_mov, $z_mov) = (int($x_pos) - int($x_prev), int($y_pos) - int($y_prev), int($z_pos) - int($z_prev));
		$x_act += $x_mov; $y_act += $y_mov; $z_act += $z_mov;

		$path[$_] = [$x_mov, $y_mov, $z_mov, $f_pos];
	}

	# through rounding errors, we might end up with a final position that is off by one from
	# what we actually wanted. ending up in the right place is the most important thing,
	# so we just set the final position to put us where we want to be
	$path[$steps-1] = [$x_end - $x_act, $y_end - $y_act, $z_end - $z_act, $frame_pattern->[($steps - 1)%($#{$frame_pattern}+1)]];

	return \@path;
}


# run the callback routines for all entities that have them, and update
# the entity accordingly. also checks for auto death status
sub _do_callbacks {
	my ($self) = @_;

	foreach my $entity (keys %{$self->{ENTITIES}}) {
		my $ent = $self->{ENTITIES}{$entity};
		
		# check for methods to automatically die
		if(defined($ent->{'DIE_TIME'}) and $ent->{'DIE_TIME'} <= time()) {
			del_entity($self, $entity); next;
		}

		if(defined($ent->{'DIE_FRAME'}) and ($ent->{'DIE_FRAME'}--) <= 0) {
			del_entity($self, $entity); next;
		}

		if(defined($ent->{'DIE_ENTITY'}) and !$self->is_living($ent->{'DIE_ENTITY'}) ) {
			del_entity($self, $entity); next;
		}

		if($ent->{'DIE_OFFSCREEN'}) {
			if($ent->{X} >= $self->{WIDTH} or $ent->{Y} >= $self->{HEIGHT} or
			   $ent->{X} < (0 - $ent->{WIDTH}) or $ent->{Y} < (0 - $ent->{HEIGHT})) {
				del_entity($self, $entity); next;
			}
		}

		if(defined($ent->{CALLBACK})) {
			my ($x, $y, $z, $f) = $ent->{CALLBACK}->($ent, $self);
			if(defined($x)) {
				if($ent->{WRAP}) {
					if($x >= $self->{WIDTH}) { $x = ($x - int($x)) + ($x % $self->{WIDTH});  }
					elsif($x < 0)            { $x = ($x - int($x)) + ($x % $self->{WIDTH});  }
				}
				$ent->{X} = $x;
			}
			if(defined($y)) {
				if($ent->{WRAP}) {
					if($y >= $self->{HEIGHT}) { $y = ($y - int($y)) + ($y % $self->{HEIGHT}); }
					elsif($y < 0)             { $y = ($y - int($y)) + ($y % $self->{HEIGHT}); }
				}
				$ent->{Y} = $y;
			}
			$ent->{Z} = defined($z) ? $z : $ent->{Z};
			$ent->{CURR_FRAME} = defined($f) ? $f : $ent->{CURR_FRAME};
		
		}
	}
}

# called after all other updates. moves any entities that
# follow another entity
sub _move_followers {
	my ($self) = @_;

	foreach my $entity_name (keys %{$self->{ENTITIES}}) {
		my $follower = $self->{ENTITIES}{$entity_name};

		next unless(defined($follower->{FOLLOW_ENTITY}));

		my $leader = $self->entity($follower->{FOLLOW_ENTITY});
		next unless(defined($leader));
		my $offset = $follower->{FOLLOW_OFFSET};

		if(defined($offset->[0])) { $follower->x( $offset->[0] + $leader->x ); }
		if(defined($offset->[1])) { $follower->y( $offset->[1] + $leader->y ); }
		if(defined($offset->[2])) { $follower->z( $offset->[2] + $leader->z ); }
		if(defined($offset->[3])) { $follower->frame( $offset->[3] + $leader->frame ); }
	}
}

sub _collision_handlers {
	my ($self) = @_;
	foreach my $entity (values %{$self->{ENTITIES}}) {
		if(defined($entity->{COLL_HANDLER}) && defined($entity->{COLLISIONS})) {
			$entity->{COLL_HANDLER}->($entity, $self);
		}
		$entity->{COLLISIONS} = ();
	}
}

=item I<end>

  $anim->end();

Run the Curses endwin function to get your terminal back to its
normal mode. This is called automatically when the object is
destroyed if the animation is running full screen (if you 
did not pass an existing Curses window to the constructor).

=cut
sub end {
	my ($self) = @_;
	endwin;
}

# write to a log file, for debugging
sub _elog {
	my ($mesg) = @_;
	open(F, ">>", "elog.log");
	print F "$mesg\n";
	close(F);
}

1;

=back

=head1 CALLBACK ROUTINES

Callback routines for all entities are called each time I<animate>
is called. A default callback routine is supplied, I<move_entity>, which
is sufficient for most basic movement. If you want to create an entity
that exhibits more complex behavior, you will have to write a custom
callback routine for it.

Callback routines take two arguments, a reference to the Term::Animation::Entity
object that it should act on, and a reference to the Term::Animation instance
that called it. Any arguments required to tell the callback what to do with
the object, or any state that needs to be maintained, should be put
in the I<callback_args> element of the object. I<callback_args> is only
referenced by the callback routine, and thus can contain any datastructure
that you find useful.

Here is an example custom callback that will make an entity move randomly
around the screen:

  sub random_movement {
      my ($entity, $anim) = @_;

      # get the current position of the entity
      my ($x, $y, $z) = $entity->position();

      # we'll use callback_args to store the last axis we moved in
      my $last_move = $entity->callback_args();

      # if we moved in x last time, move in y this time
      if($last_move eq 'x') {
          $entity->callback_args('y');
	  # move by -1, 0 or 1
	  $y += int(rand(3)) - 1; 
      } else {
          $entity->callback_args('x');
	  $x += int(rand(3)) - 1; 
      }

      # return the absolute x,y,z coordinates to move to
      return ($x, $y, $z);
  }

The return value of your callback routine should be of the form:

    return ($x, $y, $z, $frame)

$x, $y and $z represent the X, Y and Z coordinates to which the object
should move. $frame is the frame number that the object should display,
if it has multiple frames of animation. Any values that are unspecified
or undef will remain unchanged.

You can also call the default callback from within your callback, if
you want it to handle movement for you. For example, if your callback
is simply used to decide when an entity should die:

  sub wait_for_file {
      my ($entity, $anim) = @_;

      # kill this entity if a certain file shows up
      if(-e "/path/to/file") {
          $entity->kill();
	  return();
      }

      # use the default callback to handle the actual movement
      return $entity->move_entity($anim);
  }

If you use this, be aware that I<move_entity> relies on
I<callback_args>, so you cannot use it to store your own
arbitrary data.

=head1 COLOR

ANSI color is available for terminals that support it. Only a single
background color can be used for the window (it would look terrible
in most cases otherwise anyway). Colors for entities are specified by
using a 'mask' that indicates the color for each character. For
example, say we had a single frame of a bird:

  $bird = q#

  ---. .-. .---
    --\'v'/--
       \ /
       " "
  #;

To indicate the colors you want to use for the bird, create a matching
mask, with the first letter of each color in the appropriate position
(except black, which is 'k'). Pass this mask as the I<color> parameter.

  $mask = q#

  BBBB BBB BBBB
    BBBWYWBBB
       B B
       Y Y
  #;

When specifying a color, using uppercase indicates the color should be
bold. So 'BLUE' or 'B' means bold blue, and 'blue' or 'b' means non-bold
blue. 'Blue' means you get an error message.

You can also provide a default color with the default_color parameter.
This color will be used for any character that does
not have an entry in the mask. If you want the entire entity to be
a single color, you can just provide a default color with no mask.

The available colors are: red, green, blue, cyan, magenta, yellow, black
and white.

Here's an example call to build_object for the bird above.

    $anim->new_entity (
              name		=> "Bird",
              shape		=> $bird,
              position		=> [ 5, 8, 7 ],
              callback_args	=> [ 1, 2, 0, 0 ],
              color		=> $mask,
              default_color	=> "BLUE"
    );

=head1 AUTHOR

Kirk Baucom, E<lt>kbaucom@schizoid.comE<gt>

=head1 SEE ALSO

L<Curses|Curses>

=cut
