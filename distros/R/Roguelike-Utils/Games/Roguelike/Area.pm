package Games::Roguelike::Area;

# puposely don't use much of the curses windowing stuff since curses doesn't port well
# purpose of library:
#
#     keep track of map/location
#     convenience for collision, line of sight, path-finding
#     assume some roguelike concepts (mobs/items)
#     allow me to make 7-day rl's in 7-days

=head1 NAME

Games::Roguelike::Area - Roguelike area map

=head1 SYNOPSIS

 package myArea;
 use base 'Games::Roguelike::Area';

 $a = myArea->new(w=>80,h=>50);     				# creates an area with specified width/height
 $a->generate('cavelike');                                         	# make a cavelike maze
 $char = Games::Roguelike::Mob->new($a, sym=>'@');              # add a mobile object with symbol '@'

=head1 DESCRIPTION

Library for loading or generating mazes, managing items/mobs

	* assumes the user will be using overridden Games::Roguelike::Mob's as characters in the game
	* provides a flexible load() function
	* contains an array of 'features', which can be named, searched for and positioned

=head2 METHODS

=over 4

=cut 

use strict;
use Games::Roguelike::Utils qw(:all);
use Games::Roguelike::Mob;

use Data::Dumper;
use Carp qw(croak confess carp);

our $OKINLINEPOV;
our $AUTOLOAD;

our $VERSION = '0.5.' . [qw$Revision: 259 $]->[1];

BEGIN {
        eval('use Games::Roguelike::Utils::Pov_C;');
        $OKINLINEPOV = !$@;
} 

=item new(OPT1=>VAL1, OPT2=>VAL2...)
	
Options can also all be set/get as class accessors:

	world => undef,			# world this area belongs to (optional container which can "addarea")
	name => '', 			# name of this level/area (required if world is specified)
	map => [] 			# double-indexed array of map symbols 
	color => []			# double-indexed array of strings (used to color map symbols)
	mobs => [],			# list of mobs
	items => [],			# list of items

 # These will default to the world defaults, if world is set

        w=>80, h=>40,			# width/height of this area
        debugmap => 0, 			# turn on map coordinate display
	memcolor => 'gray',		# color drawn when an area is not in sight

 # These vars, or the world defaults (if a world is defined)
 # are used by map-making, pathfinding and field-of view, rather than using hooks
 # specifically because function calling seems to slow things down

        wsym => '#', 			# default wall symbol
        fsym => '.', 			# default floor symbol
        dsym => '+', 			# default door symbol
        noview => '#+', 		# list of symbols that block view
        nomove => '#', 			# list of symbols that block movement	
	
=cut

sub new {
        my $pkg = shift;
	croak "usage: Games::Roguelike::Area->new()" unless $pkg;

        my $self = bless {}, $pkg;
	$self->init(@_);
	return $self;
}

sub init {
        my $self = shift;
	my %opts = @_;

	croak("need to specify a name for this area") if $opts{world} && !$opts{name};

	# set defaults

	$self->{map} = [];
	$self->{color} = [];
	$self->{mobs} = [];
	$self->{items} = [];

	if (!$opts{world}) {
		$self->{h} = 40;
		$self->{w} = 80;
		$self->{wsym} = '#';
		$self->{fsym} = '.';
		$self->{dsym} = '+';
		$self->{debugmap} = 0;
	} else {
		# really, should create functions for each one which reads from world member
		for (qw(h w noview nomove wsym fsym dsym debugmap memcolor)) {
			$self->{$_} = $opts{world}->$_;
		}
	}

	# override defaults	
	for (keys(%opts)) {
		$self->{$_} = $opts{$_};
	}
	
	$self->{memcolor} = 'gray' unless defined $self->{memcolor};
	$self->{nomove} = $self->{wsym} unless $self->{nomove};
	$self->{noview} = $self->{wsym}.$self->{dsym} unless $self->{noview};
	if ($self->{world}) {
		$self->{world}->addarea($self);
		$self->{world}->area($self) if !$self->{world}->area;
	}
}

sub setworld {
	my $self = shift;
	my $world = shift;

	croak("need to specify a name for this area") if !$self->{name};

	if ($self->{world} != $world) {
		$self->{world}->delarea($self) if ($self->{world});
		$self->{world} = $world;
		$world->addarea($self);
                for (qw(h w noview nomove wsym fsym dsym debugmap)) {
                        $self->{$_} = $self->{world}->$_ if !defined($self->{$_});
                }
	}
}

# perl accessors are slow compared to just accessing the hash directly
# autoload is even slower
sub AUTOLOAD {
	my $self = shift;
	my $pkg = ref($self) or croak "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion

	$name =~ s/^set// if @_ && !exists $self->{$name};

	unless (exists $self->{$name}) {
	    croak "Can't access `$name' field in class $pkg";
	}

	if (@_) {
	    return $self->{$name} = $_[0];
	} else {
	    return $self->{$name};
	}
}

sub DESTROY {
}

=item getmapsym ($x,$y)

=item getmapcolor ($x,$y)

=item setmap ($x,$y, $sym [,$color])

Raw accessors may be subject to change in future versions, but are much faster.

 $area->{map}[$x][$y] = $sym, 
 $area->{color}[$x][$y] = $color

Function accessors will always work, but are slower:

 $sym=$area->getmapsym($x,$y) 
 $color=$area->getmapcolor($x,$y) 
 $area->setmap($x,$y, $sym [,$color]);

If you're looping over the whole map, you can use foreachmap().

etcetera.

=cut

sub getmapsym {
        my $self = shift;
	my ($x, $y) = @_;
        return $self->{map}->[$x][$y];
}

sub setmapsym {
        my $self = shift;
	my ($x, $y, $sym) = @_;
        $self->{map}->[$x][$y] = $sym;
}

sub setmap {
        my $self = shift;
        my ($x, $y, $sym, $color) = @_;
	if (ref($sym)) {
	        $self->{map}->[$x][$y] = $sym->{sym};
        	$self->{color}->[$x][$y] = $sym->{color} if defined $sym->{color};
	} else {
	        $self->{map}->[$x][$y] = $sym;
        	$self->{color}->[$x][$y] = $color if defined $color;
	}
}

sub mapsym {
        my $self = shift;
        my ($x, $y, $s) = @_;
	if ($s) {
                return $self->{map}->[$x][$y] = $s;
	} else {
                return $self->{map}->[$x][$y];
	}
}

sub mapcolor {
        my $self = shift;
        my ($x, $y, $c) = @_;
        if ($c) {
                return $self->{color}->[$x][$y] = $c;
        } else {
                return $self->{color}->[$x][$y];
        }
}

sub map {
        my $self = shift;
	if (@_) {
        	my ($x, $y) = (shift, shift);
		return $self->{map}->[$x][$y];
	} else {
		return $self->{map};
	}
}

=item rpoint ()

Returns a random point as an X/Y array, that's within the map, and not on the edge..

=cut

sub rpoint {
	my $self = shift;
	croak unless $self;
	return (1+int(rand()*($self->{w}-2)), 1+int(rand()*($self->{h}-2)));
}

=item rpoint_empty ()

Returns a random point that's empty (eiher the symbol is ''' or is undefined)

=cut

sub rpoint_empty {
        my $self = shift;
	croak unless $self;
	# well, there's better ways to do this, but this has worked so far
	while (1) {
	        my ($x, $y) = (1+int(rand()*($self->{w}-2)), 1+int(rand()*($self->{h}-2)));
		return ($x, $y) if $self->{map}->[$x][$y] eq '';
	}
}

############ part of genmaze1 ############

sub genroom {
	# make a room around x/y with options
	# options are: minx, miny, maxx, maxy, nooverlap, withdoor
	
        my $self = shift;
        my ($x, $y, %opts) = @_;
	
	if ($x =~ /^[a-z]/i) {
		%opts = @_;
		$x = $opts{x};
		$y = $opts{y};
		if (! defined $x) {
			($x, $y) = $self->rpoint_empty();
		}
	}
	
	my $m = $self->{map};

	# room width/height
	my $rw = max(1,2+($self->{w}/2-2)*rand()*rand());
	my $rh = max(1,2+($self->{h}/2-2)*rand()*rand());

	$rw=$opts{minw} if $opts{minw} && $rw < $opts{minw};
	$rh=$opts{minh} if $opts{minh} && $rh < $opts{minh};
	$rw=$opts{maxw} if $opts{maxw} && $rw > $opts{maxw};
	$rh=$opts{maxh} if $opts{maxh} && $rh > $opts{maxh};
	
	# top left corner of room (not including walls)
	my $rx = min($x, max(1,int(rand() + $x - ($rw-1)/2)));
	my $ry = min($y, max(1,int(rand() + $y - ($rh-1)/2)));

	$rw = min($rw, $self->{w}-$rx-1);
	$rh = min($rh, $self->{h}-$ry-1);

	if (!$rh || !$rw) {
		#push @{$self->{f}}, [$rx, $ry, 'NULLROOM'];
		return 0;
	}

	if ($opts{nooverlap}) {
		my $ov = 0;
		for (my $i = -1; $i <= $rw; ++$i) {
			if ($m->[$rx+$i][int($ry+($i * $rw/$rh))]) {
				$rw = $i-1;
				$rh = int(($i * $rw/$rh)) - 1;
			}
		}
		if ($rw <= 1 || $rh <= 1) {
			return 0;
		}
	}

	intify($rx, $ry, $rw, $rh);

	if ($x > ($rx+$rw) || $y > ($ry+$rh)) {
		return 0;
	}

	for (my $i = -1; $i <= $rw; ++$i) {
		next if ($rx+$i) < 0;
		$m->[$rx+$i][$ry-1] 	= $self->{wsym} unless $m->[$rx+$i][$ry-1] || ($ry == 0);
		$m->[$rx+$i][$ry+$rh] 	= $self->{wsym} unless $m->[$rx+$i][$ry+$rh];
	}	
	for (my $i = 0; $i < $rw; ++$i) {
        for (my $j = 0; $j < $rh; ++$j) {
                $m->[$rx+$i][$ry+$j] 	= $self->{fsym} unless $m->[$rx+$i][$ry+$j];
        }
	}
	for (my $i = -1; $i <= $rh; ++$i) {
		next if ($ry+$i) < 0;
		$m->[$rx-1][$ry+$i] 	= $self->{wsym} unless $m->[$rx-1][$ry+$i] || ($rx == 0);
		$m->[$rx+$rw][$ry+$i] 	= $self->{wsym} unless $m->[$rx+$rw][$ry+$i];
	}
		if ($opts{door}) {
			if (rand() > .5) {
				if (rand() > .5) {
					$m->[$rx+rand()*$rw][$ry-1] 	= $self->{dsym};
				} else {
					$m->[$rx+rand()*$rw][$ry+$rh] 	= $self->{dsym};
				}
				--$opts{door};
			} else {
				if (rand() > .5) {
					$m->[$rx-1][$ry+rand()*$rh] 	= $self->{dsym};
				} else {
					$m->[$rx+$rw][$ry+rand()*$rh] 	= $self->{dsym};
				}
				--$opts{door};
			}	
		}

	if (0) {
		my $sig = chr(64 + int($rw));
		print "$sig:$rx, $ry / $rw,$rh\n";
		$m->[$x][$y] = $sig;
		$m->[$rx][$ry] = 'C';
	}

	push @{$self->{f}}, [$x, $y, 'ROOM'];

	return 1;
}

=item findpath(x1, y1, x2, y2)

Returns 1 if there is a path from x1,y2 to x2,y2.  Uses "nomove" member as the list of symbols that cannot be moved through.

=cut

sub findpath {
	# flood fill 'path exists' search

	my $self = shift;
	my ($x1, $y1, $x2, $y2) = @_;
	my $f;

	return 1 if ($x1 == $x2 && $y1 == $y2);

	my @f;
	my @bread;
	push @f, [$x1, $y1];
	while (@f) {
		my $c = pop @f;
		for (my $d=0;$d<8;++$d) {
			my $tx = $DD[$d]->[0]+$c->[0];
			my $ty = $DD[$d]->[1]+$c->[1];

			# not off edge
			next if $tx < 0 || $ty < 0;
			next if $tx >= $self->{w} || $ty >= $self->{h};

			# not thru void
			next if !defined($self->{map}->[$tx][$ty]);
			next if $self->{map}->[$tx][$ty] eq '';

			# not thru wall
			next if index($self->{nomove}, $self->{map}->[$tx][$ty]) >= 0;

			next if $bread[$tx][$ty];		
			$bread[$tx][$ty] = '.'; 	#been there

			return 1 if ($tx == $x2 && $ty == $y2);

			push @f, [$tx, $ty];	#add to list;
		}
	}

	return 0;
}

=item findclose(x1, y1, x2, y2)

Returns the closest you can get to x2,y2 from x1,y2 without going through a "nomove" symbol.

Return value is (X,Y) array, or undefined if there's no path.

=cut

#if (!defined(&findclose)) {
sub findclose {
        # flood fill return closest you can get to x2/y2 without going thru a barrier
        my $self = shift;
        my ($x1, $y1, $x2, $y2) = @_;
        my $f;
        my @f;
        push @f, [$x1, $y1];
	my @bread;
	my ($cx, $cy) = ($x1, $y1);
	my $mindist = ($self->{w} + $self->{h}) * 2;

        while (@f) {
                my $c = pop @f;
                for (my $d=0;$d<8;++$d) {
                        my $tx = $DD[$d]->[0]+$c->[0];
                        my $ty = $DD[$d]->[1]+$c->[1];

                        # not off edge
                        next if $tx < 0 || $ty < 0;
                        next if $tx >= $self->{w} || $ty >= $self->{h};

                        # not thru void
                        next if !defined($self->{map}->[$tx][$ty]) || $self->{map}->[$tx][$ty] eq '';

                        # not thru wall
			next if index($self->{nomove}, $self->{map}->[$tx][$ty]) >= 0;

                        next if $bread[$tx][$ty];
                        $bread[$tx][$ty] = '.';     #been there

                        return ($tx, $ty, 0) if ($tx == $x2 && $ty == $y2);

			if ((my $tdist = distance($tx, $ty, $x2, $y2)) < $mindist) {
				$cx = $tx;
				$cy = $ty;
				$mindist = $tdist;
			}

                        push @f, [$tx, $ty];    #add to list of places can get to;
                }
        }

#	my ($ax,$ay,$ad) = findclose_c($self, $x1, $y1, $x2,$y2);
#	if ($ax!=$cx||$ay!=$cy) {
#		croak "C and perl disagree: ($ax,$ay <> $cx,$cy);"
#	}

#	$self->{color}->[$cx][$cy] = 'green';
        return ($cx, $cy, $mindist);
}#}


=item maxcardinal ()

Maximum point someone can walk from x/y in each of 4 cardinal directions, returned as an array of XY arrays.

Array is sorted n,s,e,w.

=cut

sub maxcardinal {
        my $self = shift;
        my ($x, $y) = @_;

	# maximum direction you can walk from x/y in each of the 4 directions, returned as a nsew array of points
	my @r;
        for (my $d=0;$d<4;++$d) {
		my ($cx, $cy) = ($x,$y);
		while (1) {
	                my $tx = $DD[$d]->[0]+$cx;
	                my $ty = $DD[$d]->[1]+$cy;

                        # not thru void
                        last if !defined($self->{map}->[$tx][$ty]) || $self->{map}->[$tx][$ty] eq '';

                        # not thru wall
			last if index($self->{nomove}, $self->{map}->[$tx][$ty]) >= 0;

                        # not off edge
                        last if $tx < 0 || $ty < 0;
                        last if $tx >= $self->{w} || $ty > $self->{h};

			# record
			($cx, $cy) = ($tx,$ty);
		};

		push @r, [$cx, $cy];
	}

	return @r;		
}

=item digone (x, y, $ws, $fs)

"Digs" one square of the map, at position x,y - turning it into a "floor", 
while also turning the surrounding areas into "walls", if they are currently
not assigned.

Optionally can specify wall & floor symbols (or uses area defaults).

Does nothing if the map symbol at x,y is not a wall or void.

Returns the number of walls that the new point is surrounded by or -1 if the point was off the map. 

=cut

sub digone {
        my $self = shift;
        my ($x, $y, $ws, $fs) = @_;

	$ws = $self->{wsym} unless $ws;
	$fs = $self->{fsym} unless $fs;
	
	return -1 if ($x <=0 || $y <= 0);
	return -1 if ($x >=($self->{w}-1) || $y >= ($self->{h}-1));

	my $c = $self->{map}->[$x][$y];
	return unless !defined($c) || ($c eq $ws) || ($c eq '');
	$self->{map}->[$x][$y] = $fs;

      	for (my $d=0;$d<8;++$d) {
                my $tx = $DD[$d]->[0]+$x;
                my $ty = $DD[$d]->[1]+$y;
		my $c = $self->{map}->[$tx][$ty];
		next unless !defined($c) || $c eq '';
		$self->{map}->[$tx][$ty] = $ws;
       	}

	#$self->drawmap();
	
	return 1;
}

sub debug {
	return 1;
}


=item nexttosym(x, y, sym)

Returns a direction if x,y are adjacent to sym, otherwise returns undef.

=cut

sub nexttosym {
        my $self = shift;
	my ($x, $y, $sym) = @_;
	my $dn = 0;
	for (@DD) {
		my $tx = $x + $_->[0];
		my $ty = $y + $_->[1];
		return $DIRS[$dn] if index($sym, $self->{map}[$tx][$ty]) >= 0;
		++$dn;
	}
	return undef;
}


=item okdoor(x, y)

Looks at the clockwize adjacent symbols for an alternating pattern of walls and floors, to see if a door
would be meaningful.

Uses {nomove} as the list of "wall" symbols.

=cut

sub okdoor {
        my $self = shift;
        my ($x, $y) = @_;
        my $cnt = 0;
	my $cur;
	my $first;
	my $flip = 0;
        for (@CWDIRS) {
                my $tx = $x + $DD{$_}->[0];
                my $ty = $y + $DD{$_}->[1];
		my $sym = $self->{map}[$tx][$ty];
                my $wl = !defined($sym) || (index($self->{nomove}, $sym) >= 0) || $sym eq $self->{dsym};
		if (! defined $cur) {
			$cur = $wl;
			$first = $wl;
		} else {
			if ($cur != $wl) {
				++$flip;
				$cur = $wl;
			}
		}
		 
        }
	if ($cur != $first) {
		++$flip;
	}

        return $flip == 4;
}

=item makepath(x1, y1, x2, y2)

Drill a right-angled corridor between 2 nonempty points using digone().

** Notably the whole auto-door upon breaking into an open area doesn't always work right, and should.

=cut

sub placedoors {
	my $self=shift;
	my @doors = @_;
        for (@doors) {
                my ($x, $y) = @$_;
                if ($self->okdoor($x, $y) && $self->{dsym}) {
                        $self->{map}->[$x][$y] = $self->{dsym};
                }
        }
}

sub makepath {
        my $self = shift;
        my ($ox, $oy, $x2, $y2) = @_;

	croak "can't make a path without floor and wall symbols set" 
		unless $self->{wsym} && $self->{fsym};

#	$self->{map}->[$x][$y] = chr(64 + ++$self->{dseq}) if $self->debug;
#	$self->{map}->[$x2][$y2] = chr(64 + ++$->{dseq}) if $self->debug;

	my ($x, $y) = ($ox, $oy);

	if ($self->{map}->[$x][$y] eq '') {
		return;
	}
	if ($self->{map}->[$x2][$y2] eq '') {
		return;
	}

	my $d;
	if ($y < $y2) {
		$d = 's';
	} elsif ($y > $y2) {
		$d = 'n';
	}

	if ($x < $x2) {
		$d .= 'e';
	} elsif ($x > $x2) {
		$d .= 'w';
	}

	return if !$d;

	# 2 directions, randomly sorted
	
	my @d;
	$d[1] = $d;
	$d[0] = substr($d, rand()*2, 1);
	$d[1] =~ s/$d[0]//;

	# closest can get now
	($x, $y) = $self->findclose($x, $y, $x2, $y2);

#	$self->dprint "($x, $y) closest from $ox $oy to $x2, $y2";

	# choose a random square among maximum wall range from closest point
	my @mc = $self->maxcardinal($x, $y);
	$d=$d[0];
	my $len;
	if ($d =~ /^n|s$/) {
		$x = $mc[$DI{w}]->[0] + rand() * ($mc[$DI{e}]->[0] - $mc[$DI{w}]->[0]);
	} else {
		$y = $mc[$DI{n}]->[1] + rand() * ($mc[$DI{s}]->[1] - $mc[$DI{n}]->[1]);
	}
	intify($x, $y);

	my @doors;

	my $firstdig = 1;		# first dig out of an area gets a door
	for my $d (@d) {
		next unless $d;

		$self->{map}->[$x][$y] = $d if $self->debug > 1;

	        if ($d =~ /^n|s$/) {
	                $len = abs($y-$y2);
	        } else {
	                $len = abs($x-$x2);
	        }

		my $already_dug = 0;
		my $waswall = 0;
	
		for (my $i = 0; $i < $len; ++$i) {
			my ($px,$py) = ($x, $y);
			$x += $DD{$d}->[0];
			$y += $DD{$d}->[1];

			my $iswall = $self->{map}->[$x][$y] eq $self->{wsym};
			if ($iswall || $self->{map}->[$x][$y] eq '') {
				$self->digone($x,$y);
				if ($firstdig) {
                                	push @doors, [$x, $y];
					$firstdig = 0;
				}
			} else {
				# not a wall, already dug
				$already_dug = 1;
				if ($waswall) {
                                	push @doors, [$px, $py];
				} else {
					# 2 non walls in a row = reset firstdig
					$firstdig = 1;
				}
			}
			$waswall = $iswall;

			
                        if ( $already_dug ) {
                        	my ($fx, $fy, $dist) = $self->findclose($x, $y, $x2, $y2);
				if (&distance($fx, $fy, $x, $y) >= 2 ) {
					my $res = $self->makepath($fx, $fy, $x2, $y2);
                        		$self->placedoors(@doors);
					return $res;
				}
                        	last if $dist == 0;
                        }

			#$self->{world}->drawmap();
			# too close to edge
			last if $x<=1 || $y<=1 || $x>=($self->{w}-1) || $y>=($self->{h}-1);
		}
		last if ($x == $x2 && $y == $y2);
	}

	
	if (!$self->findpath($ox, $oy, $x2, $y2)) {
		$self->makepath2($ox, $oy, $x2, $y2);
	}

        $self->placedoors(@doors);

        return 1;
}

=item makepath2 (x1, y1, x2, y2)

Like makepath, but diagonal and with no doors.

=cut


sub makepath2 {
        my $self = shift;
        my ($ox, $oy, $x2, $y2) = @_;

        croak "can't make a path without floor and wall symbols set"
                unless $self->{wsym} && $self->{fsym};

        my ($x, $y) = ($ox, $oy);

	($x, $y) = $self->findclose($x, $y, $x2, $y2);

	while (($x != $x2) || ($y != $y2)) {
		$self->digone($x, $y);
		my $d;
        	if ($y < $y2) {
                	$d = 's';
        	} elsif ($y > $y2) {
                	$d = 'n';
        	}
		if ($x < $x2) {
			$d .= 'e';
		} elsif ($x > $x2) {
			$d .= 'w';
		}

                $x += $DD{$d}->[0];
                $y += $DD{$d}->[1];
	}
}


=item findfeature (symbol)

Searches "map feature list" for the given symbol, returns coordinates if found.

=cut

sub findfeature {
	my $self = shift;
	my ($sym) = @_;

	for (@{$self->{f}}) {
		my ($fx, $fy) = @$_;
		if ($self->{map}->[$fx][$fy] eq $sym) {
			return ($fx, $fy);
		}
	}
}

=item addfeature (symbol [, x, y])

Adds a symbol to the map (to a random open floor point if one is not specified), and also adds it to the searchable "feature list".

=cut

sub addfeature {
        my $self = shift;
        my ($sym, $x, $y) = @_;

	if (!defined($x)) {
		($x, $y) = $self->findrandmap($self->{fsym}, 0, 1);
	}
	$self->{map}->[$x][$y] = $sym;
	push @{$self->{f}}, [$x, $y];
}

=item inbound(x, y)

Returns true if x >= 0 and x < $self->{w} and y >= 0 and y < $self->{h}.

=cut

sub inbound {
        my $self = shift;
        return ($_[0]>=0)&&($_[0]<($self->{w}))&&($_[1]>=0)&&($_[1]<($self->{h}));
}


=item generate ($type [, options ... ])

This calls "$type::generate" if it is defined, perhaps in the caller's package, etc.

Predefined types are "Rooms", "Cavelike" and "Maze" (see below).

If no "::" is present, 'Games::Roguelike::Area::' is prepended, and the first character is propercased.

If &{"$type::generate"} is not defined, it will require "$type" and then try again.

Assuming there is no function named "wilderness::generate", then the following are roughly equivalent:

 $self->generate('Games::Roguelike::Area::Rooms');
or
 $self->generate('rooms');  
or
 Games::Roguelike::Area::Rooms::generate($self);
or
 $self = new Games::Roguelike::Area::Rooms; $self->generate();

Additonal options are passed to the generate function.  Generate functions should support named parameters..

Common option is a "with=>[feature1, feature2]" feature list, that get added to empty floor map locations, 
and appended to the map's feature list.

Height, width are taken from the area object.

=cut

sub generate {
        my $self = shift;
	my $type = shift;

	my $path = $type . '::generate';
	if (defined &$path) { 
		no strict 'refs';
		return &$type($self, @_);
	}

	if ($type !~ /::/) {
		$type =~ s/^(\w)/\U$1/;
		$type = 'Games::Roguelike::Area::' . $type;
		$path = $type . '::generate';
		if (defined &$path) {
			no strict 'refs';
			return &$path($self, @_);
		}
	}
	eval "require $type";
	no strict 'refs';
	return &$path($self, @_);
}


# this is intended as *example* of making a map that i got to work in a few hours
# it is not intended as a good map
# if map-making isn't what you want to work on in the beginning, you can start here


=item generate('cavelike', [with=>[sym1[,sym2...]])

Makes a random map with a bunch of cave-like rooms connected by corridors.

Can specify a list of symbols to be added as "features" of the map.

=cut

sub diginbound {
        my $self = shift;
	return ($_[0]>0)&&($_[0]<($self->{w}-2))&&($_[1]>0)&&($_[1]<($self->{h}-2));
}

sub genmaze2 {
        my $self = shift;
        my %opts = @_;

        my ($m, $fx, $fy);

	my $digc = 0;

	do {
	my ($cx, $cy) = $self->rpoint();
	$self->digone($cx, $cy);
	if (my $feature = shift @{$opts{with}}) {
		$self->{map}->[$cx][$cy]=$feature;
		push @{$self->{f}}, [$cx, $cy, 'FEATURE'];
	} else {
		push @{$self->{f}}, [$cx, $cy, 'ROOM'];
	}
	my @v;
	$v[$cx][$cy]=1;
	my $dug = 0;
	do {
	  my $o = randi(4);
	  $dug = 0;
	  for (my $i=0;$i<4;++$i) {
		my ($tx, $ty) = ($cx+$DD[($i+$o)%4]->[0], $cy+$DD[($i+$o)%4]->[1]);
		if ((!$v[$tx][$ty]) && $self->diginbound($tx, $ty)) {
			($cx, $cy) = ($tx, $ty);
			++$digc if $self->digone($cx, $cy);
			#print "dig at $cx, $cy $v[$cx][$cy]\n"; 
			$v[$cx][$cy] = 1;
			$dug = 1;
			last;
		}
	  }
	} while ($dug);

	} while ($digc < (($self->{w}*$self->{h})/8));

        # dig out paths
        my ($px, $py);
        for (randsort(@{$self->{f}})) {
                my ($x, $y, $reason) = @{$_};
                if ($px) {
                        if (!$self->findpath($x, $y, $px, $py)) {
                                $self->makepath($x, $y, $px, $py);
                                #$self->drawmap();
                                #$self->getch();
                        }
                }
                ($px, $py) = ($x, $y);
        }
}

=item generate ('rooms', [with=>[sym1[,sym2...]])

Makes a random nethack-style map with a bunch of rectangle rooms connected by corridors

If you specify a "with" list, it puts those symbols on the map in random rooms, and calls "addfeature" on them.

=cut

sub genmaze1 {  
	my $self = shift;
	my %opts = @_;

	my ($m, $fx, $fy);

	my $rooms = 0;

	for my $feature (@{$opts{with}}) {
		($fx, $fy) = $self->rpoint_empty();
		$self->{map}->[$fx][$fy]=$feature;
		push @{$self->{f}}, [$fx, $fy, 'FEATURE'];
		++$rooms if $self->genroom($fx, $fy);		# put rooms around features
	}

	# some extra rooms
	while($rooms < ($self->{w}*$self->{h}/600)) {
		++$rooms if $self->genroom(($fx, $fy) = $self->rpoint_empty(), nooverlap=>1);
	}

	# dig out paths
	my ($px, $py);
	for (randsort(@{$self->{f}})) {
		my ($x, $y, $reason) = @{$_};
		if ($px) {
			if (!$self->findpath($x, $y, $px, $py)) {
				$self->makepath($x, $y, $px, $py);
				if (!$self->findpath($x, $y, $px, $py)) {
					$self->{map}->[$px][$py] = '1';
					$self->{map}->[$x][$y] = '2';
					$self->dump();
					die "makepath failed!!!\n";
					$self->makepath($x, $y, $px, $py);
				}
				#$self->drawmap();
			}
		}
		($px, $py) = ($x, $y);
	}
}

=item generate('maze', rand=>number, with=>feature-list) 

Generate a tight, difficult maze.  Rand defaults to 5 (higher numbers are less random).

=cut

sub genmaze3 {
        my $self = shift;
	my %opts = @_;

	$opts{w} = $self->{w} if !$opts{w};
	$opts{h} = $self->{h} if !$opts{h};

        my ($cNx,$cNy, $cSx, $cSy);
        my $intDir;
        my $intDone = 0;

        my $blnBlocked;

        use constant X => 0;
        use constant Y => 1;

        $opts{rand} = 5 if !$opts{rand};

        $opts{w} -= 1 if !($opts{w}%2);
        $opts{h} -= 1 if !($opts{h}%2);

        # stores the directions that corridors go in
        my @cDir;
        my @blnMaze;

        do {
            # this code is used to make sure the numbers are odd
            $cSx = 1 + (int((($opts{w} - 1) * rand()) / 2) * 2);
            $cSy = 1 + (int((($opts{h} - 1) * rand()) / 2) * 2);

            # first opening is free!
            $blnMaze[$cSx][$cSy] = 1 if !$intDone;

            if ($blnMaze[$cSx][$cSy]) {
                # randomize directions to start
                @cDir = &getRandomDirections();
                do {
                    # only randomisation directions, based on the constant
                    @cDir = &getRandomDirections() if !int($opts{rand} * rand());
                    $blnBlocked = 1;
                    # loop through order of directions
                    for ($intDir = 0; $intDir < 4; ++$intDir) {
                        # work out where this direction is
                        $cNx = $cSx + ($cDir[$intDir][X] * 2);
                        $cNy = $cSy + ($cDir[$intDir][Y] * 2);
                        # check if the tile can be used
                        my $isFree;
                        if ($cNx < ($opts{w}-1) && $cNx >= 1 && $cNy < ($opts{h}-1) && $cNy >= 1) {
                                # true if it hasn't been used yet
                                $isFree = !$blnMaze[$cNx][$cNy];
                        }
                        if ($isFree) {
                            # create a path
                            $blnMaze[$cNx][$cNy] = 1;
                            # and the square inbetween
                            $blnMaze[$cSx + $cDir[$intDir][X]][$cSy + $cDir[$intDir][Y]] = 1;
                            # this is now the current square
                            $cSx = $cNx;
                            $cSy = $cNy;
                            $blnBlocked = 0;
                            # increment paths created
                            $intDone = $intDone + 1;
                            last;
                        }
                    }
                # loop until a path was created
                } while (!$blnBlocked)
           }
        } while ( $intDone + 1 < ( (($opts{w} - 1) * ($opts{h} - 1)) / 4 ) );
        # create enough paths to fill the whole grid


        # this changes the direction to go from the current square, to the next available
        sub getRandomDirections {
            # clear the array
            my @a = ([-1,0],[1,0],[0,-1],[0,1]);
            my @b;
            while (@a) {
                push @b, splice(@a, rand()*scalar(@a), 1);
            }
            return @b;
        }

	$self->{map} = [];

	for (my $y = 0; $y < $opts{h}; ++$y) {
		for (my $x = 0; $x < $opts{w}; ++$x) {
			$self->{map}->[$x][$y]  = ($blnMaze[$x][$y] ? $self->{fsym} : $self->{wsym});
		}
	}


        for my $feature (@{$opts{with}}) {
                my ($fx, $fy) = $self->findrandmap('.');
                $self->{map}->[$fx][$fy]=$feature;
                push @{$self->{f}}, [$fx, $fy, 'FEATURE'];
        }
}

=item foreachmap (code-reference [,noborder=>1] [,border=>1])

Loops over each map location, and calls the code with parameters x, y and map-symbol.

Option "border" calls the code only for border (edge) squares.

Option "noborder" calls the code for everything but border (edge) squares.

=cut

sub foreachmap {
	my $self = shift;
	my $code = shift;
	my %opts = @_;
	
	if ($opts{border}) {
		for my $y ((0,$self->{h}-1)) {
			for (my $x = 0; $x < $self->{w}; ++$x) {
				&{$code}($x, $y, $self->{map}->[$x][$y]); 
			}
		}
		for my $x ((0,$self->{w}-1)) {
			for (my $y = 0; $y < $self->{h}; ++$y) {
				&{$code}($x, $y, $self->{map}->[$x][$y]); 
			}
		}
	} else {
		my ($x1, $y1, $x2, $y2) = (0, 0, $self->{w},$self->{h});

		if ($opts{nobodrder}) {
			$x1++;	$y1++;
			$x2--;	$y2--;
		}

		for (my $y = $y1; $y < $y2; ++$y) {
			for (my $x = $x1; $x < $x2; ++$x) {
				&{$code}($x, $y, $self->{map}->[$x][$y]); 
			}
		}
	}
}

=item draw ({dispx=>, dispy=>, vp=>, con=>});

Draws the map using offset params dispx, dispy,disph,dispw, 

Uses the perspective of $vp (viewpoint), if specified.  $vp can contain an x, y coordinate 
and a "pov" integer which is the maximum sight distance.

Uses the console $con to draw the map.

Uses the algorithm provided by the "checkpov" function for field of view calculations.

Usually done after each move.

=cut

sub draw {
	my $self = shift;
	my ($opts) = @_;

	my $dispx = $opts->{dispx};
	my $dispy = $opts->{dispy};
	my $dispw = $opts->{dispw};
	my $disph = $opts->{disph};
	my $vp = $opts->{vp};
	my $con = $opts->{con};

	my $debugx = $dispx;
	my $debugy = $dispy;
	if ($self->{debugmap}) {
		$dispx += 3; $dispw -= 3;
		$dispy += 3; $disph -= 3;
	}

	my $ox = 0;
	my $oy = 0;	
	if ($vp) {
	  $ox = $vp->{x}-($dispw/2);	#substract offsets from actual
	  $oy = $vp->{y}-($disph/2);
	  $ox = 0 if $ox < 0;
	  $oy = 0 if $oy < 0;
	  $ox = $self->{w}-$dispw if ($ox+$dispw) > $self->{w};
	  $oy = $self->{h}-$disph if ($oy+$disph) > $self->{h};
	}
	intify($ox, $oy);

	if ($self->{debugmap}) {
		# show labels to help debuggin map routines
		$con->addstr($debugy,$debugx," " x 3);
		for (my $x = $ox; $x < $dispw+$ox; ++$x) {
			$con->addstr(substr(sprintf("%03.0d", $x),-2,1));
		}
		$con->addstr($debugy+1,$debugx," " x 3);
		for (my $x = $ox; $x < $dispw+$ox; ++$x) {
			$con->addstr(substr(sprintf("%03.0d", $x),-1,1));
		}
		$con->addstr($debugy+2,$debugx," " x 3);
		for (my $x = $ox; $x < $dispw+$ox; ++$x) {
			$con->addstr("-");
		}
	}

	#$self->dprint("OXY: $ox, $oy DXY: $dispx,$dispy");
	
	#actual map drawn at user-requested location/virtual window
	for (my $y = $oy; $y < ($disph+$oy); ++$y) {
		# x/y is the game map-coord, not drawn location
		if ($self->{debugmap}) {
			$con->addstr($y-$oy+$dispy, $debugx, sprintf("%02.0d|", $y));
		}
		for (my $x = $ox; $x < $dispw+$ox; ++$x) {
			if (my $memtyp = $self->checkmap($vp, $x, $y, $self->{map}->[$x][$y])) {
				my ($color) = $self->{color}->[$x][$y];
				my $sym = ($memtyp == 2) ? $vp->{memory}->{$self->{name}}->[$x][$y] : $self->{map}->[$x][$y] ? $self->{map}->[$x][$y] : ' ';
				$color = $self->{memcolor} if $memtyp == 2 && $self->{memcolor};		# if the area is memorized, then draw as gray
				$con->attrch($color, $y-$oy+$dispy,$x-$ox+$dispx,$sym);
			} else {
				$con->addch($y-$oy+$dispy,$x-$ox+$dispx,' ');
			}
		}
	}

	# drawitems
        for my $i (@{$self->{items}}) {
		$self->drawob($i, $opts, $ox, $oy, $dispx, $dispy);
        }

	# drawmobs on top
        for my $m (@{$self->{mobs}}) {
		$self->drawob($m, $opts, $ox, $oy, $dispx, $dispy);
        }

	$con->refresh();
}

# 
# This draws a thing that has a symbol, a color, an x and a y
# It is called by draw() above
#

sub drawob {
	my $self = shift;
        my ($ob, $opts, $ox, $oy, $xoff, $yoff) = @_;

        my $vp = $opts->{vp};
        my $con = $opts->{con};

        # $ox, $oy must be subtracted to get display coords (relative to display box, don't draw if outside box)
        # $xoff, $yoff musy be ADDED to get absolute coords (relative to console box)

        if ($self->checkpov($vp, $ob->{x}, $ob->{y})) {
            if ( (($ob->{y}-$oy) >= 0) && (($ob->{x}-$ox) >= 0) && (($ob->{x}-$ox) < $opts->{dispw}) && (($ob->{y}-$oy) < $opts->{disph}) ) {
                $con->attrch($ob->{color},$ob->{y}-$oy+$yoff, $ob->{x}-$ox+$xoff, $ob->{sym});
            }
	    #if the object is not the char, and the object is novel then memorize it and set the "saw something new this turn" flag
	    if ($vp && $ob != $vp && !($vp->{memory}->{$self->{name}}->[$ob->{x}][$ob->{y}] eq $ob->{sym})) {
		    $vp->{memory}->{$self->{name}}->[$ob->{x}][$ob->{y}] = $ob->{sym};
		    $vp->{sawnew} = 1;
	    }
	    return 1;
        }
}


# These can be easily optimized also storing items/mobs at {m-items}[x][y] and {m-mobs}[x][y]
# But a list approach is simpler for now, and reduces some overhead on sets

=item mobat (x, y)

Returns a single mob located at x/y, or undef if none is there.

=cut

sub mobat {
	my $self = shift;
	my ($x, $y) = @_;
	#$self->dprint("mobat $x, $y");
	my @r;
        for my $m (@{$self->{mobs}}) {
        	return $m if ($m->{x} == $x) && ($m->{y} == $y);
        }
}

=item items ([x, y])

Returns reference to array of items located at x/y, or reference to array of all items if no x/y is supplied.

=cut

sub items {
	my $self = shift;
	if (!@_) {
		return $self->{items} 
	} else {
		my ($x, $y) = @_;
		my @r;
		for my $i (@{$self->{items}}) {
			push @r, $i if ($i->{x} == $x) && ($i->{y} == $y);
		}
		return \@r;
	}
}

=item mobs ([x, y])

Returns reference to array of all mobs located at x/y, or all mobs if no x/y is supplied.

=cut

sub mobs {
	my $self = shift;
	if (!@_) {
		return $self->{mobs} 
	} else {
		my ($x, $y) = @_;
		my @r;
		for my $m (@{$self->{mobs}}) {
			push @r, $m if ($m->{x} == $x) && ($m->{y} == $y);
		}
		return \@r;
	}
}

=item checkpov (vp, x, y)

Returns 1 if the $vp object (something that has an x, a y and a pov) can see x/y.

Uses the "noview" area variable to determine what can be seen through.

=cut

# this is used to show monster at the current location
sub checkpov {
	my $self = shift;
	my ($vp, $x, $y) = @_;
	return 1 if (!$vp);	# no viewpoint, draw everything
	return 1 if ($vp->{pov}<0 || !defined($vp->{pov}));	# see all
	return 0 if ($vp->{pov}==0);	# blind
	my $vx = $vp->{x};
	my $vy = $vp->{y};

	my $dist = distance($vx, $vy, $x, $y);
	
	return 0 unless $dist <= $vp->{pov};

	return 1 if $dist <= 1;		# always see close

        print "---FOV2: $vx, $vy, $x, $y D:$dist\n" if $self->{debugfov};
	if ($OKINLINEPOV) {
		print "using inline pov\n" if $self->{debugfov};
		return checkpov_c($vx, $vy, $x, $y, $self->{map}, $self->{noview}, $self->{debugfov} ? 1 : 0);
	}

# here's where we need to actually do some field of view calculations

        my $dx = $x-$vx;
        my $dy = $y-$vy;

	# trace 4 parallel rays from corner to corner
	# without cosines!
	# this code allows diagonal blocking pillars

        my @ok = (1,1,1,1);
	for (my $i = 1; $i <= $dist; $i+=0.5) {
		my $tx = $vx+($i/$dist)*$dx;	# delta-fraction of distance
		my $ty = $vy+($i/$dist)*$dy;	

		my (@x, @y);
                $x[0] = (0.1+$tx);		# not quite the corners
                $y[0] = (0.1+$ty);
                $x[1] = (0.9+$tx);
                $y[1] = (0.9+$ty);
                $x[2] = (0.9+$tx);
                $y[2] = (0.1+$ty);
                $x[3] = (0.1+$tx);
                $y[3] = (0.9+$ty);

		my $ok = 0;
		for (my $j = 0; $j < 4; ++$j) {
                        next if !$ok[$j];
			if (int($x[$j]) eq $x && int($y[$j]) eq $y) {
                        	print "$i: sub $j: $x[$j],$y[$j] SAME ($self->{map}->[$x[$j]][$y[$j]])\n" if $self->{debugfov};
				next;
			}
			if ($dx != 0 && $dy != 0 && (abs($dx/$dy) > 0.1) && (abs($dy/$dx) > 0.1)) {
				# allow peeking around corners if target is near the edge
				if (round($x[$j]) eq $x && round($y[$j]) eq $y && $i >= ($dist -1)) {
                        		print "$i: sub $j: $x[$j],$y[$j] PEEK ($self->{map}->[$x[$j]][$y[$j]])\n" if $self->{debugfov};
					next;
				}
			}
			if (($self->{map}->[$x[$j]][$y[$j]] =~ /^(#|\+)$/)) {
				$ok[$j] = 0;
                                print "$i: sub $j: $x[$j],$y[$j] WALL ($self->{map}->[$x[$j]][$y[$j]])\n" if $self->{debugfov};
			} else {
                                print "$i: sub $j: $x[$j],$y[$j] OK ($self->{map}->[$x[$j]][$y[$j]])\n" if $self->{debugfov};
			}
		}
		return 0 if !$ok[0] && !$ok[1] && !$ok[2] && !$ok[3];
	}
	return 1;
}

=item checkmap (vp, x, y, sym)

Returns 1 if the $vp mob can see x/y, 2 if $vp has a memory of x/y, 
and also memorizes x/y if it can be seen by adding it to the vp's "memory" variable..

Uses the "noview" area variable to determine what can be seen through.

=cut

# this is used to show the map
sub checkmap {
        my $self = shift;
        my ($vp, $x, $y, $sym) = @_;
	if ($vp && $vp->{hasmem}) {
		if ($self->checkpov($vp, $x, $y)) {
	        	$vp->{memory}->{$self->{name}}->[$x][$y]=$sym;
			return 1; 
		}
	        # $self->dprint("mem $self->{name}: $x,$y") if $vp->{memory}->{$self->{name}}->[$x][$y];
	        return 2 if $vp->{memory}->{$self->{name}}->[$x][$y];
		return 0;
	} else {
	        return $self->checkpov($vp, $x, $y);
	}
}

=item addmob (mob)

Adds a mob to the area, unless it's already in it.

=cut

sub addmob {
	my $self = shift;
	my $m = shift;
	for (@{$self->{mobs}}) {
		return 0 if $_ eq $m;
	}
	push @{$self->{mobs}}, $m;
	return $m;
}

=item delmob (mob)

Removes mob from the area.

=cut

sub delmob {
        my $self = shift;
        my $m = shift;
	my $i = 0;
        for (@{$self->{mobs}}) {
                splice @{$self->{mobs}}, $i, 1 if $_ == $m;
		++$i;
        }
}

=item findrandmap (symbol[, mobok=0])

Finds a random map location containing symbol (if mobok is not set, then it won't returns locations that have mobs).

=cut

sub findrandmap {
    my $self = shift;
    my $sym = shift;
    my $mobok = shift;

    my $index = [];

    for (my $x = 0; $x < $self->{w}; ++$x) {
	for (my $y = 0; $y < $self->{h}; ++$y) {
		push @{$index}, [$x, $y] 
			if defined($self->{map}->[$x][$y]) 
			&& ($self->{map}->[$x][$y] eq $sym && ($mobok || !$self->mobat($x,$y)));
	}
	}
    $self->{index}->{$sym} = $index;

    my $i = int(rand() * scalar(@{$index}));

    return $index->[$i]->[0], $index->[$i]->[1];
}

=item dump

Prints map to stdout, without mobs and items.   For a more flexible approach, create a ::Console::Dump object and call draw() using it.

=cut

sub dump {
	my $self = shift;

        my $ox = 0;
        my $oy = 0;

	my ($xx, $xy, $mx, $my) = (0, 0, $self->{w}, $self->{h});
        for (my $y = 0; $y < $self->{h}; ++$y) {
                for (my $x = 0; $x < $self->{w}; ++$x) {
			if ($self->{map}->[$x][$y]) {
                                $mx = $x if ($x < $mx);
                                $my = $y if ($y < $my);
                                $xx = $x if ($x > $xx);
                                $xy = $y if ($y > $xy);
                        }
                }
        }

	$ox=max($ox, $mx);
	$oy=max($oy, $my);

        #actual map drawn at user-requested location/virtual window
        for (my $y = $oy; $y < $self->{h} && $y <= $xy; ++$y) {
                for (my $x = $ox; $x < $self->{w} && $x <= $xx; ++$x) {
                        print $self->{map}->[$x][$y] ? $self->{map}->[$x][$y] : ' ';
                }
                print "\n";
        }
}

=item additem (item)

Adds item to floor.  Override this to add floor full messages, etc.

Return value 0 		= can't add, too full
Return value 1 		= add ok
Return value -1 	= move occured, but not added

If the item doesn't have an {x} and {y} value then the item is added to a random location.

=cut

sub additem {
	my $self = shift;
	my $item = shift;
	if ($item->setcont($self)) {
		if (!defined($item->{x})) {
			($item->{x}, $item->{y}) = $self->findrandmap($self->{fsym}, 0, 1);
		}
	}
	return 1;			# i'm never full
}

=item delitem (item)

Removes item from the area.

=cut

sub delitem {
        my $self = shift;
        my $ob = shift;
        my $i = 0;
        for (@{$self->{items}}) {
                splice @{$self->{items}}, $i, 1 if $_ == $ob;
                ++$i;
        }
}

=item load (file | options)

Loads an area from a file, which is a perl program that sets these vars:

 $map 		: 2d map as one big string
 or $yxarray	: 2d map as y then x indexed array
 %key		: for each symbol in the map *optionally* provide:
	color	- color of that symbol
	sym	- real symbol to use
	feature - name of feature for feature table, don't specify with class!
	class	- optional package to use for "new", passed the area itself as the first argument to new
	lib	- look up item or mob from library

 %lib		: hash of hashes, used to populate items or monsters - as needed

Alternatively, these can be passed as named options to the load function.

The map system knows very little about game semantics.   It's merely a way of loading maps
 made of symbols - some of which may correlate to perl objects.  The tictactoe example script
uses the map load system.

'>', and '<' are assumed to be "stair features" unless otherwise specified.

Objects can be looked up by name from the item library instead of specified in full.

At a minimum, classes must add themselves, somehow, to the area object when new is called.

  The example below loads a standard map, with blue doors, 2 mobs and 1 item

  One mob is loaded via a package "mymonster", and is passed "hd" & "name" parameters,
  in addition to the "x", "y" and "sym" parameters which are derived from its location.

  The other mob is loaded from the library named "blue dragon", and has it's "name" and "hp" 
  parameters modified.

About lib entries: 

If a key entry has a "lib", it's assumed to the be the name of an entry in the lib hash.

The lib hash is then looked up and has its values copied into the key entry before using the key entry.

"lib" entries can be recursive.

The "lib" can be loaded from an external shared file, so multiple maps can use the same "lib".

About items:

The "items" member of an object (mob or backpack), if it is an array reference, will be auto-expanded 
by creating an item object for each array member with the parent object set as the first, unnamed, argument to new.

If a member of the items array is a hash ref, it's treated like a key entry.  If it's a scalar string, it's
equivalent to {lib=>'string'}.

If there's no class set within an item, a warning is emitted.

EXAMPLE 1:

 $map = '
 ##########
 #k <+  ! #
 ######## #
 #>  D    #
 ##########
 ';

 %key = (
	'k'=>{class=>'mymonster', type='kobold', name=>'Harvey', hd=>12, 
	      items=>['potion of healing',
		      {class=>'myweapon', name=>'Blue Sword', hd=>9, dd=>4, drain=>1, glow=>1}
		     ]
	     },
	'!'=>{lib=>'potion of speed'},
	'D'=>{lib=>'blue dragon', name=>'Charlie', hp=>209},
	'+'=>{color=>'blue'}
       );

 %lib = (
	'potion of speed'=>{class=>'myitem', type=>'potion', effect=>'speed', power=>1},	
	'blue dragon'=>{class=>'mymob', type=>'dragon', breath=>'lightning', hp=>180, hd=>12, at=>[10,5], dm=>[5,10], speed=>5, loot=>4},
       );

  $area->load(map=>$map, key=>%key, lib=>\%lib);

EXAMPLE 2:
	
 use Games::Roguelike::Caves;
 my $yx = generate_cave($r->{w},$r->{h}, 12, .46, '#', '.');
 $area->load(yxarray=>$yx);

=cut

sub load {
        my $self = shift;

        confess("cannot call load without a filename or a map/key and lib") 
		if (!@_);

	my $map;
	my %key;
	my %lib;

        my ($fn);
	my %opts;

	if (@_ == 1) {
        	($fn) = @_;
	} else {
		%opts = @_;
		$fn = $opts{file};
	}

	if ($fn) {
    		eval {
		use Safe;
		my $in = new Safe;
		$in->permit_only(':base_core');
		$in->rdo($fn);
		$map = $in->reval('$map');
		%key = $in->reval('%key');
		%lib = $in->reval('%lib');
		};
	} else {
		$map = $opts{map};	
		%key = %{$opts{key}} if $opts{key};
		%lib = %{$opts{lib}} if $opts{lib};
	}

	my $mapyx;

	if ($opts{yxarray} && ref($opts{yxarray})) {
		$mapyx = $opts{yxarray};
	} else {
		if (!$map) {
			cluck("no 'map' or 'xyarray' found in parameters");
			return 0;
		}
		$map =~ s/^[\r\n]+//;
		$map =~ s/[\r\n]+$//;
		my @ylines = split(/[\r\n]/,$map);
		my $y = 0;
		for (@ylines) {
                        my @l = split(//, $_);
                        $mapyx->[$y++]= \@l;
		}
	}

	$self->{map} = [];
	$self->{color} = [];

	my $y = 0;
	for (@{$mapyx}) {
		my $x = 0;
		for (@{$mapyx->[$y]}) {
			my $sym = $mapyx->[$y][$x];
			expandkey($sym, \%key, \%lib);
			my $opt = $key{$sym};
			if ($opt) {	
				if ($opt->{sym}) {
					$sym = $self->{map}->[$x][$y] = $opt->{sym};
				}
				if ($opt->{class}) {
					$self->{map}->[$x][$y] = $self->{fsym};
					my $ob;
					my ($cpack) = caller;
					eval {$ob = $opt->{class}->new($self, x=>$x, y=>$y, sym=>$sym, %{$opt});};
					carp "failed to create $opt->{class}: $@" if !$ob;
					if (ref($opt->{items}) eq 'ARRAY') {
						for(@{$opt->{items}}) {
							if (!ref($_)) {
								expandkey($_, \%lib, \%lib);
								$_ = $lib{$_};
							} else {
								expandhash($_, \%lib);
							}
							my $it;
							eval {$it = $_->{class}->new($ob, %{$_});};
							carp "failed to create $_->{class}: $@" if !$ob;
						}
					}
				} else {
					if ($opt->{feature}) {
						push @{$self->{f}}, [$x, $y];
					}
					$self->{map}->[$x][$y] = $sym;
					$self->{color}->[$x][$y] = $opt->{color};
				}
			} else {
				$self->{map}->[$x][$y] = $mapyx->[$y][$x];
			}
			$x++;
		}
		$y++;
	}

	$self->{w} = @{$self->{map}};
	$self->{h} = @{$self->{map}->[0]};
}

# this looks in the hash "key" for an entry called "lib", which should be a string
# it then looks in the hash "lib" for that string
# finally it copied the keys from "lib" to the hash "key"
# really no reason for 2 hashes... 1 would suffice (for map keys and lib entries), 
# but i think it's easier to keep track of for the users that way

sub expandhash {
	my ($hash, $lib) = @_;

        return if !$hash;
        return if $hash->{__lib__};
        return if !(my $libname = $hash->{lib});

        croak "no entry for '$libname'"
                if !$lib->{$libname};

        # allow recursion
        expandhash($lib, $lib);

        for (keys(%{$lib->{$libname}})) {
                next if $_ eq 'lib';
                $hash->{$_}=$lib->{$libname}->{$_};
        }

}

sub expandkey {
	my ($index, $key, $lib) = @_;
	return if !$key->{$index};
	expandhash($key->{$index}, $lib);
}


sub dprint {
	my $self=shift;
	if ($self->{world}) {
		$self->{world}->dprint(@_)
	} else {
		print @_, "\n";
	} 
}

=back

=cut

# this allows the "generate" function to work and support the old interface

package Games::Roguelike::Area::Rooms;
use base 'Games::Roguelike::Area';

sub generate {
	Games::Roguelike::Area::genmaze1(@_);
}

package Games::Roguelike::Area::Cavelike;
use base 'Games::Roguelike::Area';

sub generate {
        Games::Roguelike::Area::genmaze2(@_);
}

package Games::Roguelike::Area::Maze;
use base 'Games::Roguelike::Area';

sub generate {
        Games::Roguelike::Area::genmaze3(@_);
}

=head1 SEE ALSO

L<Games::Roguelike::World>, L<Games::Roguelike::Mob>, L<Games::Roguelike::Console>

=head1 AUTHOR

Erik Aronesty C<earonesty@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html> or the included LICENSE file.

=cut

1;

