use strict;

package Games::Roguelike::Mob;

use Games::Roguelike::Utils qw(:all);
use Games::Roguelike::Console;
use Games::Roguelike::Area;
use Data::Dumper;
use Carp qw(croak confess);

=head1 NAME

Games::Roguelike::Mob - Roguelike mobile object

=head1 SYNOPSIS

 package myMob;
 use base 'Games::Roguelike::Mob';

 $area = Games::Roguelike::Area->new();
 $m = myMob->new($area, sym=>'D', x=>5,y=>6);       # creates a mob at location 5, 6
                                                    # with symbol 'D', inside area $area

 $m->autoex()					    # moves the mob towards the nearest unexplored area
 $m->kbdmove($c)				    # moves the mob according to keystroke '$c' using traditional roguelike semantics

=head1 DESCRIPTION

Mobile object used by drawing routines in Roguelke::Area

=head2 METHODS

=over 4

=item new($area, %options)

Area is an ::Area object, common options are:

 sym=>'@', 		# symbol to use when rendering
 items=>[], 		# array ref of contained items
 hasmem=>1,		# whether the mob uses the "memory" feature
 pov=>-1, 	        # distance the mob can "see" (-1 = infinite, 0 = blind)
 singleminded=>0,	# whether the mob will "wander" when the movetoward function is called

All "unknown" options are saved in the object's hash, with the assumption that they 
will be used by the game, for example "->{MaxHp}", etc.

=cut

sub new {
        my $pkg = shift;
        my $area = shift;
	croak("can't create mob without area") unless $area && $area->isa('Games::Roguelike::Area');

        my $self = {};

        $self->{area} = $area;
	$self->{sym}='@';
	$self->{msglog} = [];
	$self->{items} = [];
	$self->{odir} = '';
	$self->{hasmem} = 1;
	$self->{pov} = -1;
	$self->{singleminded} = 0;		# whether it tries to wander around in pursuit of a goal

        while( my ($k, $v) = splice(@_, 0, 2)) {
                $self->{$k} = $v;
        }

        if (!defined($self->{x})) {
                ($self->{x}, $self->{y}) = $area->findrandmap($area->{fsym}, 0, 1);
        }

        bless $self, $pkg;
        $area->addmob($self);
        return $self;
}

=item area([new])

Either returns the current area (no arguments) or set the area (one argument).  

If an area is supplied, the old area has "delmob" called on it,and the new area has "addmob" called on it.

=cut 

sub area {
        my $self = shift;
        if (@_) {
		$self->{area}->delmob($self);
        	$self->{area} = $_[0];
        	$_[0]->addmob($self);
		if ($self->{area}->{world}) {
			$self->{area}->{world}->area($self->{area});
		}
        }
        return $self->{area};
}

=item x()

=item y()

Returns the location of the mob

=cut

sub x {
	return $_[0]->{x};
}

sub y {
	return $_[0]->{y};
}

=item on()

Returns the map symbol from the current area at the mob's current x, y location.

=cut

sub on {
	my $self = shift; 
	return $self->{area}->{map}->[$self->{x}][$self->{y}];
}

=item movetofeature(@ARGS)

Calls the "findfeature" function on the current area with the @ARGS, and, if one is returned, reposition with x/y coordinates to match.

Checkmove/aftermove are not called.

=cut

sub movetofeature {
	my $self = shift;
        my ($cx,$cy) = $self->{area}->findfeature(@_);
	if (defined($cx)) {
        	$self->{x} = $cx;
        	$self->{y} = $cy;
		return 1;
	} else {
		return 0;
	}
}

my %DIAGS = (
	'nw'=>['n','w'],
	'ne'=>['n','e'],
	'sw'=>['s','w'],
	'se'=>['s','e'],
	'n',=>['nw','ne'],
	's',=>['sw','se'],
	'e',=>['ne','ne'],
	'w',=>['sw','nw'],
);

=item movetoward($x, $y, $error)

Moves the mob toward the point specified.   If error is specified, the destination point is "blurred" by the error radius.

=cut

sub movetoward {
	my $self = shift;
	my ($x, $y, $err) = @_;
	my ($dx, $dy) = ($x - $self->{x}, $y - $self->{y});
	
	if ($err > 0) {
		$dx += (randi($err*2+1)- $err);
		$dy += (randi($err*2+1)- $err);
		intify($dx, $dy);
	}

	return 0 if $dx == 0 && $dy == 0;
	my $d;

	if ($dy > 0) {
		$d = 's'
	} elsif ($dy < 0) {
		$d = 'n'
	}

	if ($dx > 0) {
		$d .= 'e'
	} elsif ($dx < 0) {
		$d .= 'w'
	}

	# nonzero means move happened
	my $ok = $self->move($d);
	return $ok if $ok;

	# try moving orthoganally again sometimes... to range farther
	if (($self->{singleminded}==0) && rand(2) > 1 && $self->{odir}) {
                $ok = $self->move($self->{odir});
		$self->{area}->dprint("ortho repeat of $self->{odir}") if $ok;
                return $ok if $ok;
	}

	# try moving diags of move
	my @d;
	
	if (abs($dy) > abs($dx)) {
		@d = @{$DIAGS{$d}};
	} elsif (abs($dy) < abs($dx)) {
		@d = ($DIAGS{$d}->[1],$DIAGS{$d}->[0]);
	} else {
		@d = randsort(@{$DIAGS{$d}});
	}
	
	for (@d) {
		$ok = $self->move($_);
		$self->{odir} = '' if $ok;
		return $ok if $ok;
	}

	return 0 if $self->{singleminded} > 1;

	# try moving orthoganally to the way you want to go
	for (randsort(orthogs($d))) {
                $ok = $self->move($_);
		$self->{area}->dprint("moved orthog $_") if $ok;
		$self->{odir} = $_ if $ok;
                return $ok if $ok;
	}

	return 0;
}

my %ORTHOGS = (
	'n'=>['e','w','ne','nw'],
	's'=>['e','w','se','sw'],
	'e'=>['n','s','ne','se'],
	'w'=>['n','s','nw','sw'],
	'ne'=>['nw','se'],
	'nw'=>['ne','sw'],
	'se'=>['ne','sw'],
	'sw'=>['nw','se'],
);

sub orthogs {
	my ($d) = @_;
	return @{$ORTHOGS{$d}};
}

=item kbdmove($c[, $testonly])

Moves the mob in direction '$c': 'h' is LEFT, 'l' is RIGHT, etc.

The testonly flag is passed to the "move" function.

=cut

sub kbdmove {
	my $self = shift;
	my ($c, $testonly) = @_;
        if ($c eq '.') {
                return $self->move('.', $testonly);
        }
        if ($c eq 'h' || $c eq 'LEFT') {
                return $self->move('w', $testonly);
        }
        if ($c eq 'l' || $c eq 'RIGHT') {
                return $self->move('e', $testonly);
        }
        if ($c eq 'j' || $c eq 'DOWN') {
                return $self->move('s', $testonly);
        }
        if ($c eq 'k' || $c eq 'UP') {
                return $self->move('n', $testonly);
        }
        if ($c eq 'y') {
                return $self->move('nw', $testonly);
        }
        if ($c eq 'b') {
                return $self->move('sw', $testonly);
        }
        if ($c eq 'u') {
                return $self->move('ne', $testonly);
        }
        if ($c eq 'n') {
                return $self->move('se', $testonly);
        }
	return 0;
}

=item safetomove()

Returns true if it's safe to continue autoexploring.

Default behavior is to return false if any mobs are in view.

=cut

sub safetomove {
        my $self = shift;
        my $area = $self->{area};
        for my $m (@{$area->{mobs}}) {
                next if $m eq $self;
                if ($area->checkpov($self, $m->{x}, $m->{y})) {
                	return 0;
                }
        }
	return 1;
}

=item autoex ([bool only1])

Find closest unexplored square and move towards it until it's no longer unexplored.

If world is specified, this loops and draws the map.   Otherwise, it moves only 1 step.

=cut

sub autoex {
        my $self = shift;
	my ($world) = @_;

        # flood fill find unexplored area
        my $area = $self->{area};
        my ($x1, $y1) = ($self->{x}, $self->{y});
        my $f;

        my @f;
        push @f, [$x1, $y1, []];
        my @bread;
        my ($cx, $cy) = ($x1, $y1);
        my $minlen = 1000000;

	if (!$self->safetomove()) {
		return 0;
	}

	if (!$world && $self->{autopath} && @{$self->{autopath}}) {
		my $moved = $self->move(shift(@{$self->{autopath}}));
		if ($self->{memory}->{$self->{area}->{name}}->[$self->{autocx}][$self->{autocy}]) {
			$self->{autopath} = undef;
		}
		return $moved;
	}
	
	my $path;		# path to take
        while (@f) {
                my $c = shift @f;	# breadth first
                for (my $d=0;$d<8;++$d) {
                        next unless $self->{memory}->{$self->{area}->{name}}->[$c->[0]][$c->[1]];	# has to be "moving from" a place we have seen

                        my $tx = $DD[$d]->[0]+$c->[0];
                        my $ty = $DD[$d]->[1]+$c->[1];
			my $p = [@{$c->[2]}, $DIRS[$d]];

                        # not off edge
                        next if $tx < 0 || $ty < 0;
                        next if $tx >= $area->{w} || $ty >= $area->{h};

                        next if $bread[$tx][$ty];
                        $bread[$tx][$ty]='.';     #been there in this algorithm

			my $seen = $self->{memory}->{$self->{area}->{name}}->[$tx][$ty];

                        if (!$seen) {	# not explored already;
                          $path = $p;
                          $cx = $tx;
                          $cy = $ty;
			  @f = ();
			  last;
			}

                        # not thru void
                        next if !defined($area->{map}->[$tx][$ty]);
                        next if $area->{map}->[$tx][$ty] eq '';

                        # not thru wall
                        next if index($area->{nomove}, $area->{map}->[$tx][$ty]) >= 0;
	
	                push @f, [$tx, $ty, $p];    #add to list of places can get to;
                }
        }

	if ($path) {
		if (!$world) {
			my $moved = $self->move(shift(@{$path}));
                        if (!($self->{memory}->{$self->{area}->{name}}->[$cx][$cy])) {
                        	$self->{autopath} = $path;
                        	$self->{autocx} = $cx;
                        	$self->{autocy} = $cy;
                        }
			return $moved;
		} else {
			my $con = $world->{con};
			my $stm=1;
			for (@$path) {
				my $bc = $con->nbgetch();
				if ($bc eq 'q' || $bc eq 'ESC') {
					$stm = 0;
					last;
				}
				my $moved = $self->move($_);
				$stm = $self->safetomove();
				last if !$stm;
				# explored the one we were looking for...remove this to reduce recusion at the expense of wasted moves
				if (($self->{memory}->{$self->{area}->{name}}->[$cx][$cy])) {
					last;
				}
			}
			if (!$stm) {
				return 1;
			} else {
				$world->drawmap();
				$self->autoex(@_);
			}
		}
	}
}


=item move (direction[, testonly])

Uses checkmove to see whether the direction is ok.  If it returns > 0, then moves the mob, 
changing its x,y position, and saving the move in "lastmove".

Aftermove is then called if the return value of checkmove was nonzero.

=item lastmove

Returns the direction parameter passed to "move" that resulted in a successful move.

=cut

sub move {
	my $self = shift;
	my ($d, $testonly) = @_;			# news direction
	my $nx = $self->{x} + $DD{$d}->[0];
	my $ny = $self->{y} + $DD{$d}->[1];
	my $r;
	$r = $self->checkmove($nx, $ny, scalar $self->{area}->mobat($nx, $ny), $testonly);
	# less than eq zero means remain still (but move may have occurred)
	if (!$testonly) {
	  if ($r > 0) {
		$self->{area}->dprint("moved $d");
		$self->{x} = $nx;
		$self->{y} = $ny;
		$self->{lastmove} = $d;
	        $self->aftermove($d);
	  } elsif ($r < 0) { 
	        $self->aftermove(undef);
	  }
	}
	return $r;
}

sub getmovexy {
        my $self = shift;
        my ($d, $flag) = @_;                    # news direction
        my $nx = $self->{x} + $DD{$d}->[0];
        my $ny = $self->{y} + $DD{$d}->[1];
	return ($nx, $ny); 
}

sub lastmove {
	return $_[0]->{lastmove};
}

=item aftermove (direction)

Called after the mob moved with the direction it moved.  

If the mob attacks or otherwise moves "nowhere" it is called with 'undef' as the direction.

=cut

sub aftermove {
}

=item checkmove (new-x, new-y, othermob (at location x/y), testonly)

Called before the mob moves with the direction it will move if allowed.  

Return value 0 		= no move occurs
Return value 1 		= move occurs
Return value -1 	= attack/move occured, but keep in the same place

=cut

sub checkmove {
	my $self = shift;
	my ($x, $y, $othermob, $testonly) = @_;
	return 0 unless $self->{area}->{map}->[$x][$y] eq $self->{area}->{fsym};
	return 0 unless !$othermob;
	return 1;
}

=item additem (item)

Adds item to inventory.  Override this to add pack full messages, etc.

Return value 0 		= can't add, too full
Return value 1 		= add ok
Return value -1 	= move occured, but not added

=cut

sub additem {
	my $self = shift;
	my $item = shift;
	# i'm never full
	return $item->setcont($self);
}

=item delitem (item)

Removes item from the mob.

=cut

sub delitem {
        my $self = shift;
        my $ob = shift;
	confess("not a mob") unless $self->isa('Games::Roguelike::Mob');
	$self->{area}->dprint("h1");
        my $i = 0;
        for (@{$self->{items}}) {
		if ($_ == $ob) {
                	splice @{$self->{items}}, $i, 1;
			return $_;;
		}
                ++$i;
        }
	return undef;
}

=item dropitem (item)

Removes item, changes it's coordinates, and then tries to put it in the "area".

Returns the result of the "additem" from the area object (which may be a failure).

=cut

sub dropitem {
        my $self = shift;
        my $item = shift;
	$item->{x} = $self->{x};
	$item->{y} = $self->{y};
        $self->{area}->additem($item);
	return 1;
}

=back

=head1 AUTHOR

Erik Aronesty C<earonesty@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html> or the included LICENSE file.

=cut

1;
