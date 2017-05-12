package Games::Roguelike::World;

# purpose of library:
#
#     keep track of map/location
#     convenience for collision, line of sight, path-finding
#     assume some roguelike concepts (mobs/items)
#     allow someone to make 7-day rl's in 7-days

=head1 NAME

Games::Roguelike::World - Roguelike World

=head1 SYNOPSIS

 package myWorld;
 use base 'Games::Roguelike::World';

 $r = myWorld->new(w=>80,h=>50,dispw=>40,disph=>18);     # creates a world with specified width/height & map display width/height
 $r->area(new Games::Roguelike::Area(name=>'1'));			# create a new area in this world called "1"
 $r->area->genmaze2();                                   # make a cavelike maze
 $char = Games::Roguelike::Mob->new($r->area, sym=>'@', pov=>8);      # add a mobile object with symbol '@'
 $r->setvp($char);                                       # set viewpoint to be from $char's perspective
 $r->drawmap();                                          # draw the active area map from the current perspective
 while (!((my $c = $r->getch()) eq 'q')) {
        $char->kbdmove($c);
        $r->drawmap();
 }

=head1 DESCRIPTION

General pupose object which pulls together field of view, item, mob handling and map drawing code.   

	* contains a hash of Games::Roguelike::Area's for each "level" or "region" in the game
	* uses the Games::Roguelike::Console library to draw the current area
	* assumes the user will be using overridden Games::Roguelike::Mob's as characters in the game
	* assumes the user will be using overridden Games::Roguelike::Item's as items in the game

=head2 METHODS

=over 4

=cut 

use strict;
use Games::Roguelike::Utils qw(:all);
use Games::Roguelike::Console;
use Games::Roguelike::Mob;

use Math::Trig;
use Data::Dumper;
use Carp qw(croak confess carp);

our $AUTOLOAD;
our $VERSION = '0.4.' . [qw$Revision: 256 $]->[1];

=item new(OPT1=>VAL1, OPT2=>VAL2...)
	
Options can also all be set/get as class accessors:

	vp => undef			# Games::Roguelike::Mob that is the 'viewpoint'
	dispx, dispy => (0,1) 		# x/y location, of the map
	dispw, disph => (60,24) 	# width & height of the map
	msgx, msgy => (0,0) 		# x/y location of the "scrolling message box"
	msgw, msgh => (60, 1)		# width & height of the "scrolling message box"
	maxlog => 80, 			# maximum number of rows stored message log
	msgoldcolor => 'gray', 		# color of non-curent messages (if left blank, color is left alone)
	wsym => '#', 			# default wall symbol
	fsym => '.', 			# default floor symbol
	dsym => '+', 			# default door symbol
	debugmap => 0, 			# turn on map coordinate display
	debug => 0, 			# debug level (higher = more)
	noview => '#+', 		# list of symbols that block view
	nomove => '#', 			# list of symbols that block movement	
	area => undef,			# Games::Roguelike::Area that contains the currrent map
	
None of these features have to be used, and can be easily ignored or overridden.

=cut

sub new {
        my $pkg = shift;
	croak "usage: Games::Roguelike::World->new()" unless $pkg;

        my $self = bless {}, $pkg;
	$self->init(@_);
	return $self;
}

sub init {
        my $self = shift;

	$self->{hasmem} = 1;
	$self->{dispy} = 1;
	$self->{dispx} = 0;
	$self->{h} = 40;
	$self->{w} = 80;
	$self->{maxlog} = 80;
	$self->{msgx} = 0;
	$self->{msgoldcolor} = 'gray';
	$self->{msgy} = 0;
	$self->{msgh} = 1;
	$self->{noview} = '#+';
	$self->{wsym} = '#';						# default wall symbol
	$self->{fsym} = '.';						# default floor symbol
	$self->{dsym} = '+';
	$self->{debugmap} = 0;
	$self->{vp} = undef;
	$self->{dn} = 0;
	$self->{memcolor} = 'gray';

	# allow all of the above to be overridden by params	
	while( my ($k, $v) = splice(@_, 0, 2)) {
		$self->{$k} = $v;
	}
	
	$self->{nomove} = $self->{wsym} unless $self->{nomove};			# by default, can't move through walls
	$self->{disph} = min(24, $self->{h}) unless $self->{disph};		# default display sizes
	$self->{dispw} = min(60,$self->{w}) unless $self->{dispw};		
	$self->{msgw} = min(60,$self->{dispw}) unless $self->{msgw};		# default message window size

	# create console object
	$self->{con} = new Games::Roguelike::Console(noinit=>$self->{noinit}, type=>$self->{console_type}) 
		unless $self->{con} || $self->{noconsole};
}

=item area([name or Games::Roguelike::Area])

No arguments: returns the current area

Specify a scalar name: returns an area with that name

Specify an Games::Roguelike::Area object: stores that object in the area hash, 
	overwriting any with the same name, then makes it the active area

=cut

sub area {
	my $self = shift;
	if (@_) {
	 if (ref($_[0])) {
		my $area = shift;
		$self->addarea($area);
		$self->{area} = $area;
	 } else {
		return $self->{areas}->{$_[0]};
	 }
	}
	return $self->{area};
}

sub areas {
	my $self = shift;
	return values(%{$self->{areas}});
}

sub addarea {
	my $self = shift;
	my $area =  shift;
	confess("this world already has an area named $area->{name}") 
		if $self->{areas}->{$area->{name}} && $self->{areas}->{$area->{name}} != $area;
	$self->{areas}->{$area->{name}} = $area;
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

=item dprint ( msg1 [,msg2...msgn] [,level] )

Debug print messages

For now, hard coded to far right side of screen, at col 82, past most terminal game widths

=cut
 
sub dprint {
	my $self = shift;

	my $level = 1;

	# last arg is an integer number
	$level = pop  if int(0+$_[$#_]) eq $_[$#_];

	return unless $self->{debug} >= $level;

	#windows cant have a "wide" console
	if ($self->{con} && ref($self->{con}) !~ /win32/i && ref($self->{con}) !~ /dump/i) {
		my $msg = substr(join("\t",@_),0,40);
		$self->{con}->addstr($self->{dn},82,$msg . (" " x (40-length($msg))));
		++$self->{dn};
		$self->{dn} = 0 if $self->{dn} > 30;
	} else {
		my $msg = join("\t",@_);
		open  DEBUG, ">>rll-debug.txt"; 
		print DEBUG scalar(localtime), "\t", $msg, "\n";
		close DEBUG;
	}
}

=item getch ()

Read one character, blocks until a char is pressed.

=cut

sub getch {
	my $self = shift;
	$self->{con}->getch();	
}

=item getstr ([echo=>1[,empty=>0]])

Calls getch repeatedly, optionally echoing characters to the active console.  If "empty" is not 
set to true, it will not return empty strings.

=cut

sub getstr {
        my $self = shift;
	my %opts = @_;
	$opts{max} = 40 if !defined $opts{max};
	$opts{echo} = 1 if !defined $opts{echo};
	$opts{empty} = 0 if !defined $opts{empty};

	$self->{con}->cursor(1);
	my ($c, $str);
	while (1) {
        	$c = $self->{con}->getch();
		if ($c =~ /[\n\r]/) {
			last if length($str) > 0 || $opts{empty};
		}
		if ($opts{echo} && length($str) < $opts{max}) {
			if ($c eq 'BACKSPACE') {
				$self->{con}->addch(chr(8));
				$self->{con}->addch(' ');
				$self->{con}->addch(chr(8));
			} elsif ((length($c)==1) && (ord($c) > 30) && (ord($c) < 128)) {
        			$self->{con}->addch($c); 
			}
		}
		$self->{con}->refresh();
                if ($c eq 'BACKSPACE') {
                        $str = substr($str, 0, -1);
		} elsif ((length($c)==1) && (ord($c) > 30) && (ord($c) < 128)) {
			$str .= $c;
                };
		$c = '' if !length($str);
	}

	$self->{con}->cursor(0);
	chomp $str;
	return $str;
}


=item refresh ()

Refreshes the console display.

=cut

sub refresh {
        my $self = shift;
        $self->{con}->refresh();
}

=item nbgetch ()

Read one character, nonblocking, returns undef if none are available.

=cut

sub nbgetch {
	my $self = shift;
	$self->{con}->nbgetch();	
}

=item findfeature (symbol)

searches "map feature list" for the given symbol, returns coordinates if found

=cut

sub findfeature {
	my $self = shift;
	return $self->{area}->findfeature(@_);	
}

=item dispclear ()

Erases the "display world", and resets the "display line" (used by dispstr)

Useful for displaying an in-game menu, inventory, ability or skill list, etc.

=cut

sub dispclear {
	my $self = shift;

	my ($y) = @_;
	$y = $self->{dispy} if ! defined $y; 

	for (my $i = $y; $i < ($self->{disph}+$self->{dispy}); ++$i) {
		$self->{con}->addstr($i,$self->{dispx}," " x ($self->{dispw}));
	}
	$self->{displine} = $self->{dispy};
}

=item dispstr (str[, line])

Draws a tagged string at the "displine" position and increments the "displine".

Return value: 0 (offscreen, did not draw), 1  (ok), 2 (ok, but next call will be offscreen).

=cut

sub dispstr {
        my $self = shift;
	my ($str, $line) = @_;
	
	my $ret = 1;

	if ($line) {
		$self->{displine} = $line;
	}

	for (split(/\n/, $str)) {
		if ($self->{displine} >= ($self->{dispy} + $self->{disph})) {
			return 0;
		}
		$self->{con}->tagstr($self->{displine}, $self->{dispx}, rpad($_, $self->{dispw}));
		$self->{con}->move($self->{displine}, $self->{dispx}+length($_));
		$self->{displine} += 1;
	}

	if ($self->{displine} >= ($self->{dispy} + $self->{disph})) {
		$ret = 2;
	}

	return $ret;
}

=item drawmap ()

Draws the map, usually do this after each move

=cut

sub drawmap {
	my $self = shift;
	$self->{area}->draw($self);
}

=item prompt (msg[, match])

Same as showmsg, but also shows the cursor, and gets a character response, optionally waiting until it matches.

=cut

sub prompt {
	my $self = shift;
	my ($msg, $match) = @_;
	$match = '.' if !$match;
	$self->showmsg($msg);
	$self->{con}->cursor(1);
	$self->{con}->move($self->{msgy},$self->{msgx}+length($msg)+1);
	my $c;
	do {
                $c = $self->getch();
	} while ($c !~ /$match/);
	$self->{con}->cursor(0);
	return $c;
}

=item cursor (bool)

Turn on/off display of cursor for next operation.

=cut

sub cursor {
        my $self = shift;
        $self->{con}->cursor(@_);
}

=item pushmsg (msg, color)

Shows a message and pushes it into the log.  Use of color argument is deprecated.  Prefer to use "<$color>$msg" tagged strings.

=cut

sub pushmsg {
	return showmsg(@_[0..2],1);
}

=item showmsg (msg, color[, push])

Shows a message at msgx, msgy coorinates and optionally logs it.  Also displays up to (msgh-1) old messages.

=cut

sub showmsg {
	my $self = shift;
	my ($msg, $color, $keep) = @_;
	$msg = substr($msg, 0, $self->{msgw});

	# use the character's log, unless there is none
	my $msglog = $self->{vp} ? $self->{vp}->{msglog} : $self->{msglog} ? $self->{msglog} : ($self->{msglog} = []);

	push @$msglog, [$msg, $color];
	
	if (@$msglog > $self->{maxlog}) {
		shift @$msglog;
	}

	my $mlx = $#{$msglog};
	for (my $i = 0; $i < $self->{msgh}; ++$i) {
		next unless $i <= $mlx;				# no more messages in log
		my ($m, $a) = @{$msglog->[$mlx-$i]};
		if ($self->{msgoldcolor}) {
			$a = $self->{msgoldcolor} if $i > 0;
			$m =~ s/<[^<>]*>//g;
		}
		$m = "<$a>$m" if $a;
		$self->{con}->tagstr($self->{msgy}+$i, $self->{msgx}, $m.(' 'x($self->{msgw}-length($m))));
	}

	$self->{con}->move($self->{msgy},$self->{msgx}+length($msglog->[0]->[0]));

	if (!$keep) {
		pop @$msglog;
	}

	$self->{con}->cursor(0);
	$self->{con}->refresh();
}

sub showmsglog {
	my @sort;
        my $self = shift;
	my $x = $self->{dispx};
        my $y = $self->{dispy};
	my $h = $self->{disph};
	if ($x == $self->{msgx} && ($self->{msgy} + $self->{msgh}) == $y) {
		$y=$self->{msgy};
	}
	if ($x == $self->{msgx} && ($y + $self->{disph}) == $self->{msgy}) {
		$h = $self->{disph} + $self->{msgh};
	}
        for (@{$self->{vp}->{msglog}}) {
		my ($msg,$color) = @$_;
		$self->{con}->attrstr($color,$y,$x,$msg.(' 'x($self->{dispw}-length($msg))));
		++$y;
		last if $y >= $h; 
        }
}

=item save ([file])

Saves the world (!), optionally specify filename which defaults to "rll.world".

=cut

sub save {
        my $self = shift;
        my $fn = shift;
	$fn = "rll.world" if (!$fn);
  	use Storable;
	local $self->{con} = undef;
	store $self,$fn;
}

=item load ([file])

Loads a world, optionally specify filename, returns a reference to the new world. 

Console is not initialized, and is, instead, copied from the current world. 

=cut

sub load {
        my $self = shift;
        my $fn = shift;
        $fn = "rll.world" if (!$fn);
        use Storable;

	my $n = retrieve $fn;

	$n->{con} = $self->{con};
	$n->{console_type} = $self->{console_type};

	return $n;
}

=back

=head1 SEE ALSO

L<Games::Roguelike::Area>, L<Games::Roguelike::Mob>, L<Games::Roguelike::Console>

=head1 AUTHOR

Erik Aronesty C<earonesty@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html> or the included LICENSE file.

=cut

1;

