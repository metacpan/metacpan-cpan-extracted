###  $Id: GameState.pm 429 2008-08-19 20:00:43Z duncan $
####------------------------------------------

## @file
# Define GameState Class
#
# Collection of items that make up a game

## @class GameState
# Container class holding all maps, chars & items
# Saving GameState saves all needed to continue the game
#
package OpenGL::QEng::GameState;

use strict;
use warnings;
use Carp;
use File::ShareDir;
use OpenGL::QEng::Parser ':all';
use OpenGL::QEng::MapHash;
use OpenGL::QEng::Team;
use OpenGL::QEng::SimpleThing; # used for handle_give and load, because ST hides
		       # classes inside

use base qw/OpenGL::QEng::Thing/;

use constant PI => 4*atan2(1,1); # 3.14159;
use constant RADIANS => PI/180.0;
use constant DEGREES => 180.0/PI;

#####
##### Class Methods - called as Class->function($a,$b,$c)
#####

## @cmethod GameState new()
#
#Create a new GameState instance
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};
  my $self;
  if (ref $class) {
    $self = $class;
    $class = ref $self;
    for my $attr qw(maps cmap parts holds) {
      undef $self->{$attr};
    }
    $self->{no_events} = 1;
  }
  else {
    $self = OpenGL::QEng::Thing->new;
    $self->{maps}   = undef;	# Hash of active maps
    $self->{cmap}   = undef;	# key value for current map
    $self->{team}   = undef;	# The Team
    bless($self,$class);
  }

  $self->passedArgs($props);
  $self->assimilate($self->{team}) if defined $self->{team};
  $self->assimilate($self->{maps}) if defined $self->{maps};
  $self->create_accessors;
  $self->register_events;

  $self;
}

#--------------------------------------------------
sub boring_stuff {
  my ($self) = @_;
  my $boring_stuff = $self->SUPER::boring_stuff;
  $boring_stuff->{team} = 1;
  $boring_stuff->{maps} = 1;
  $boring_stuff;
}

#--------------------------------------------------
sub load {

  my ($self,$filename,$want_map,$x,$z,$yaw) = @_;

  my $class;
  # if $self is a GameState, we are loading a Map or a saved game
  # if it is a classname, we have no GameState yet, so we will make one
  unless (ref($self)) {
    $class = $self;
    undef $self;
  }
  my %class_name;
  for my $o (qw/Map Wall ArchWall Door WoodDoor BarDoor WallDoor Opening/,
	     qw/Box Beam Bank Sign Switch Chest Level Character Detector/,
	     qw/Hinged Part Torch Sconce Stair Team MapHash GameState/,
	     qw/MappingKit Treasure Key Helmet Sword Robe Shoes Letter/,
	     qw/Lamp Knife CHex/,
	    ) {
    $class_name{lc $o} = $o;
  }
  if (!defined($filename) || $filename =~ /^maps/) {
    my $mapdir = File::ShareDir::dist_dir('Games-Quest3D');
    $filename = ($filename) ? "$mapdir/$filename"
                            : "$mapdir/maps/default_game.txt";
  }
  open(my $file,'<',$filename) or die "can't open $filename";
  my $lines = records(join('',<$file>));
  close $file;

  my $lexer = iterator_to_stream(
     make_lexer($lines,
		['QSTRING', qr/(?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")
			         |(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\'))/x],
		['TERMINATOR', qr/;\n*/,             sub{['TERMINATOR',';']} ],
		['CONTEXT',
		 qr/\b(?:done|in_last|partof_last|partof_next|inventory)\b/i],
		['DEFINE',     qr/\b(?:define|enddef)\b/i                    ],
		['COMPASS',    qr|\b[ENSWensw]\b|,
                   sub { ['INTEGER',{n=>0,e=>90,s=>180,w=>270}->{lc $_[0]}] }],
		['WORD',       qr|[A-Za-z_]\w*|                              ],
		['FLOAT',      qr/[+-]{0,1}(?:\d+\.\d+)|(?:\.\d+)|(?:\d+\.)/ ],
		['INTEGER',    qr/[+-]{0,1}\d+/                              ],
		['FATARROW',   qr/=>/                                        ],
		['COMMA',      qr/,/                                         ],
		['LCURLY',     qr/{/                                         ],
		['RCURLY',     qr/}/                                         ],
		['LSQBR',      qr/\[/                                        ],
		['RSQBR',      qr/\]/                                        ],
		['WHITESPACE', qr/\s+/,                 sub{''}              ],
		['UNKNOWN',    qr/./,  sub{die 'token?? [',join(',',@_),'] '}],
	       )
				);
#..............................................................................
  my $number   = alternate(lookfor('FLOAT'), lookfor('INTEGER'));
  my $position = concatenate($number,$number,$number);
  my $hkey     = alternate(lookfor('QSTRING'),
			   lookfor('WORD'),
			   $number);
  my $hval;
  my $Hval     = sub { $hval->(@_) };
  my $pair     = concatenate($hkey,lookfor('FATARROW'),$Hval);
  my $aref     = concatenate(lookfor('LSQBR'), list_of($Hval),lookfor('RSQBR'));
  my $href     = concatenate(lookfor('LCURLY'),list_of($pair),lookfor('RCURLY'));
     $hval     = alternate($hkey,$aref,$href);

  my $where;
  my $last;
  my $storing = 1;
  my @place;
  my @mode;
  my %name2obj;
  my $statement =
    alternate(
	      # class instance creation: make a Thing and put it in the map
	      T(alternate(concatenate(lookfor('WORD'),$position,list_of($pair),
				      lookfor('TERMINATOR')),
			  concatenate(lookfor('WORD'),$position,lookfor('COMMA'),
				      list_of($pair),lookfor('TERMINATOR')),     ),
		sub {
		  my $class = $class_name{lc $_[0]};
		  die "\nOops: $_[0] is not a known class of this game.\n",
		    "Check your map.\n\n" unless $class;
		  my @arg;
		  push @arg, x   => $_[1][0];
		  push @arg, z   => $_[1][1];
		  push @arg, yaw => $_[1][2];
		  my $par = ($_[2] eq ',') ? $_[3]: $_[2];
		  while (my $p = shift @$par) {
		    push @arg, digest_hval($p->[0][0]) => digest_hval($p->[0][2]);
		    if (ref($arg[-1]) eq 'HASH') {
		      if (exists $arg[-1]->{named}) {
			$arg[-1] = $name2obj{$arg[-1]->{named}};
		      }
		      else {
			for my $k (keys %{$arg[-1]}) {
			  undef($arg[-1]->{$k}) if $arg[-1]->{$k} eq 'undef';
			}
		      }
		    }
		  }
		  require "OpenGL/QEng/$class.pm"
		    unless OpenGL::QEng::SimpleThing->has_subclass($class);
		  if ($class eq 'Map' && exists {@arg}->{file}) {
		    my $cmap = $self->cmap if defined $self;
		    $last = $self->load({@arg}->{file},
					'map please',$arg[1],$arg[3],$arg[5]);
		    if ($cmap && $where && $where->isa('OpenGL::QEng::Map')) {
		      $self->cmap($cmap);
		    }
		  }
		  else {
		    if    ($class eq 'GameState' && ref $self) {
		      $last = $self->new(@arg);
		    }
		    elsif ($class eq 'Team' && $self->{team}) {
		      $last = $self->team->new(@arg);
		      $self->excise($self->team);
		    }
		    else {
		      $last = "OpenGL::QEng::$class"->new(@arg);
		    }
		  }
		  if (exists {@arg}->{name}) {
		    my $name = {@arg}->{name};
		    $name2obj{$name} = $last;
		  }
		  if ($class eq 'GameState') {
		    $self = $where = $last;
		    unless (defined $self->maps) {
		      $self->maps(OpenGL::QEng::MapHash->new);
		      $self->assimilate($self->{maps});
		    }
		    unless (defined $self->team) {
		      $self->team(OpenGL::QEng::Team->new);
		      $self->assimilate($self->{team});
		    }
		    $storing = 0;
		  }
		  elsif (!defined $where) {
		    die 'no map or gamestate' unless ref $last eq 'OpenGL::QEng::Map';
		    unless (defined $self) {
		      # make a gamestate, team, and maphash
		      $self = OpenGL::QEng::GameState->new(team => OpenGL::QEng::Team->new,
						   maps => OpenGL::QEng::MapHash->new);
		      $self->team->start(@{$last->start},$last);
		    }
		    $where = $last;
		    if (defined $x) {
		      $last->{x} = $x;
		      $last->{z} = $z||0;
		      $last->{yaw} = $yaw||0;
		    }
		    $last->{textMap} = $filename;
		    $self->maps->assimilate($last);
		    $self->add_map($last,$filename);
		    $storing = 1;
		  }
		  elsif ($storing) {
		    $where->put_thing($last,1);
		  }
		  else {
		    $where->assimilate($last) unless $where eq 'noplace';
		  }
		}
	       ),

	      # control where the next things get put
	      T(concatenate(lookfor('CONTEXT'),lookfor('TERMINATOR')),
		sub {
		  my ($place) = @_;
		  if    ($place eq 'in_last' || $place eq 'partof_last') {
		    push @place, $where;
		    push @mode, $storing;
		    $where = $last;
		    $storing = ($place eq 'in_last') ? 1 : 0;
		  }
		  elsif ($place eq 'partof_next') {
		    push @place, $where;
		    push @mode, $storing;
		    $where = 'noplace';
		    $storing = 0;
		  }
		  elsif ($place eq 'done') {
		    die 'stack underflow' unless @place;
		    $where   = pop @place;
		    $storing = pop @mode;
		  }
		  elsif ($place eq 'inventory') {
		    push @place, $where;
		    push @mode, $storing;
		    $where = $self->team;
		  }
		}),

	      # macro definition
	      T(concatenate(lookfor('DEFINE'),
			    lookfor('WORD'), # then body...
			    lookfor('DEFINE'),lookfor('TERMINATOR')),
		sub {
		  my (@args) = @_;
		  die "macro def = (",join(',',@_),")"
		}),

	      # empty statement
	      T(lookfor('TERMINATOR'),
		sub { }),
	     );

  my $mapper = star($statement);
  my ($result, $remains) = $mapper->($lexer);

  if (defined $remains) {
    require Data::Dumper;
    print "------------- remains ---------------\n";
    print Data::Dumper->Dump($remains),"\n";
  }
  return $self->{maps}{$filename} if $want_map;
  $self->send_event('new_map',$self->currmap); #let the overview know
  $self;
}

#####
##### Object Methods
#####

#--------------------------------------------------
sub register_events {
  my ($self) = @_;

  return if $self->no_events;
  for my $event (['map'        => \&switch_map   ],
		 ['dropped'    => \&handle_drop  ],
		 ['grabbed'    => \&handle_grab  ],
		 ['give_team'  => \&handle_give  ],
		 ['step_team'  => \&performStep  ],
		 ['try_unlock' => \&try_unlock   ],
		 ['touched_map'=> \&handle_touch ],
		 ['remove_me'  => \&handle_remove],
		 ['need_redraw'=> \&check_collision],
		) {
    $self->{event}->callback($self,$event->[0],$event->[1]);
  }
  # XXX just for testing -- remove me
  $self->{event}->notify($self,'special',
			 sub {$self->send_event('who_is','doggy door')});
  $self->{event}->notify($self,'i_am',
			 sub {
			   my ($self,$stash,$obj,@args) = @_;
			   $self->{event}->callback($self,'special',
			      sub {
				$obj->handle_touch($self->team);
				#$obj->printMe;
			      });
			 });
  # XXX end of just for testing
}

#--------------------------------------------------
## @method %map currmap([$map,$key])
# return the map associated with the given key
#
# If called without a key, the current map is returned
sub currmap {
  my ($self,$key) = @_;

  if ($key) {
    if (defined $self->{maps}{$key}) {
      $self->cmap($key);
    }
    else {			# !!! temp hack
      die 'new map case';
    }
  }
  die "currmap($self,",$key||'',") cmap=$self->{cmap} called from ",
    join(':',caller),' ' unless $self->cmap;
  $self->{maps}{$self->cmap};
}

#---------------------------------
## @method add_map($map,$key)
#Add a map with the given key
sub add_map {
  my ($self,$map,$key) = @_;

  $self->cmap($key);
  $self->{maps}{$key} = $map;
}

#---------------------------------
## @method save($filename)
#Save the state of the game on the given file
# $filename - file to save on
sub save {
  my ($self,$filename) = @_;

  local *STDOUT;
  open STDOUT,'>',$filename or die "Unable to redirect STDOUT";
  $self->printMe;
}

#---------------------------------
sub switch_map {
  my ($self,undef,undef,undef,$filename,@transition) = @_;

  if ($filename =~ /^maps/) {
    my $mapdir = File::ShareDir::dist_dir('Games-Quest3D');
    $filename = "$mapdir/$filename";
  }
  my $new_map = $self->{maps}{$filename};
  if ($new_map) {
    $self->{cmap} = $filename;
    # set the team at start
    $self->team->start(@{ $new_map->start},$new_map);
    $self->send_event('new_map',$self->currmap); #let the overview know
  }
  else {
    $self->load_map($filename,0,@transition);
  }
}

#---------------------------------
sub load_map {
  my ($self,$filename,$saved_position,@transition) = @_;

  my $map1;
  if ($filename =~ /^maps/) {
    my $mapdir = File::ShareDir::dist_dir('Games-Quest3D');
    $filename = "$mapdir/$filename";
  }
  if (-f $filename) {
    if (@transition) {
      $self->team->adjust_picture(@transition);
    }
    $map1 = $self->load($filename,'map please');
    $self->add_map($map1,$filename);
  } else {
    print "Can't locate file $filename\n";
    exit(-1);
  }

  # set the team at start
  $self->team->start(@{$map1->start},$map1) unless $saved_position;
  $self->send_event('new_map',$map1); #let the overview know

  $self;
}

#--------------------------
sub send_event { $_[0]->{event}->yell(@_) }


#------------------------------------------
sub digest_hval {
  my ($hv) = @_;

  return unless defined $hv;
  if (ref $hv) { # $hv is an ARRAY ref
    if ($hv->[0] eq '[') {
      my $ar = $hv->[1];
      $hv = [];
      while (my $li = shift @$ar) {
	$li = digest_hval($li->[0]);
	$li =~ s/^[\'\"]//;
	$li =~ s/[\'\"]$//;
	push @$hv, $li;
      }
    }
    elsif ($hv->[0] eq '{') {
      my $ar = $hv->[1];
      $hv = [];
      while (my $li = shift @$ar) {
	$li = $li->[0];
	my $k = digest_hval($li->[0]);
	my $v = digest_hval($li->[2]);
	push @$hv, $k => $v;
      }
      $hv = {@$hv};
    }
    else {
      die 'digest_hval(',join(',',@$hv),") $hv called from ",
	join(':',caller),"\n";
    }
  } else {
    my @m;
    if (@m = $hv =~ /^\'(.*)\'$/) {
      $hv = $m[0];
    }
    if (@m = $hv =~ /^\"(.*)\"$/) {
      $hv = $m[0];
    }
    $hv =~ s/\\n/\n/g;
    $hv =~ s/\\'/'/g;
    $hv =~ s/\\"/"/g;
  }

  $hv;
}

#--------------------------
## @method assimilate($thing)
# make $thing a part of $self
#
sub assimilate {
  my ($self,$thing) = @_;

  return unless defined($thing);
  if ($thing->isa('OpenGL::QEng::MapHash')) {
    $self->{maps} = $thing;
  }
  elsif ($thing->isa('OpenGL::QEng::Team')) {
    $self->{team} = $thing;
  }
 $self->SUPER::assimilate($thing);
}

#--------------------------------------------------
sub handle_give {
  my ($self,$stash,$obj,$ev,$class,@arg) = @_;

  require 'OpenGL/QEng/'.$class.'.pm'
    unless OpenGL::QEng::SimpleThing->has_subclass($class);
  $self->team->put_thing("OpenGL::QEng::$class"->new(@arg),1);
}

#--------------------------------------------------
## @method handle_touch($callback_args,$source_obj, $ev_type,$name, @args)
# default touch handler method for  things on the map
# Pass the touch event to the touched object
sub handle_touch {
  my ($self,$callback_args,$source_obj,$ev_type,$GLid) = @_;

  my $thing = OpenGL::QEng::Thing->find_thing_by_GLid($GLid);
  $thing->handle_touch($self->team) if ref $thing;
}

#-----------------------------------------------------------
sub try_unlock {
  my ($self,$stash,$thing,$ev) = @_;

  my $testkey = (defined $self->team->using)
              ? $self->team->holds->[$self->team->using]
              : undef;
  $thing->unlock($testkey);
}

#-----------------------------------------------------------
## @method handle_grab()
# Grab an item for the team
sub handle_grab {
  my ($self,$stash,$item,$ev,$where_i_was) = @_;

  my $items_carried = scalar @{$self->team->contains};
  if ($items_carried < $self->team->max_contains) {
    $self->team->put_thing($item);
  } else {
    $self->send_event('msg',
		      "Uh oh, aleady holding $items_carried things\n",
		      "Maybe we should drop something...\n", );
    confess "$self wasn't anywhere" unless ref $where_i_was;
    # store back in 'holds' array of last container
    $where_i_was->put_thing($item,1);
  }
}

#-----------------------------------------------------------
## @method handle_drop()
# Drop an item either at the team's feet or onto a surface
sub handle_drop {
  my ($self,$stash,$item,$ev) = @_;

  return unless defined($item);

  my $map  = $self->currmap or die 'no current map';
  my $team = $self->team;
  my $tx   = $team->x;
  my $ty   = $team->y;
  my $tz   = $team->z;
  my $tyaw = -$team->yaw+90;	# adjust for coordinate systems
  my ($thing,$surface);
  my $min_dist = 2.5;
  # find point $min_dist ft in front of the team
  my $p2x_ = $tx+$min_dist*sin($tyaw*RADIANS);
  my $p2z_ = $tz+$min_dist*cos($tyaw*RADIANS);

  $map->get_map_view;
  $map->find_objects;
  foreach my $obj (@{$map->{objects}}) {
    my ($ox,$oy,$oz,$or) = @$obj;
    if ($or->can_hold($item)) {
      my ($p2x,$p2z) = ($p2x_,$p2z_);
      my $touch = 0;
      my @sides = (defined $or->{tlines}) ? @{$or->{tlines}} : ();
      for my $side (@sides) {
	next unless defined $side;
	my ($p2rx,$p2rz) = intersect($side->[0],$side->[1],
				     $side->[2],$side->[3],
				     $tx,$tz,$p2x,$p2z);
	unless ($p2rx == -1 && $p2rz == -1) {
	  $p2x = $p2rx;		# Locate the nearest encounter
	  $p2z = $p2rz;
	  $touch = 1;
	  $thing = $side->[6];
	}
      }
      if ($touch) {
	my $dist_2 = (($tx-$ox)*($tx-$ox) + ($tz-$oz)*($tz-$oz));
	if ($dist_2 < ($min_dist*$min_dist)) {
	  $min_dist = sqrt($dist_2);
	  $surface = $thing;
	}
      }
    }
  }

  if (defined $surface) {
    $surface->put_thing($item,1);
  } else {
    # else drop at team feet (1/4" above floor)
    $item->x($tx);
    $item->z($tz);
    $item->y(($ty-5.5)+0.02);
    $map->put_thing($item,1);
  }
}

#------------------------------------------------
sub check_collision {
  my ($self,$stash,$sender,$ev,$not_moving,@args) = @_;

  return if $not_moving or
    $sender eq 'main' or $sender==$self or $sender==$self->{team};
  my $min_dist = 3;
  my $tx = $self->team->x;
  my $tz = $self->team->z;
  my $tyaw = -$self->team->yaw+90;	# adjust for coordinate systems

  my $container = $sender;
  while ($container->isa('OpenGL::QEng::Part')) { $container = $container->is_at; }
  # find point $min_dist ft in front of the team
  my $px = $tx+$min_dist*sin($tyaw*RADIANS);
  my $pz = $tz+$min_dist*cos($tyaw*RADIANS);
  my $touch = 0;
  $container->find_objects;
  if ($container->{objects}) {
    foreach my $obj (@{$container->{objects}}) {
      my ($ox,$oy,$oz,$or) = @$obj;
      next unless (($ox-$tx)*($ox-$tx)+($oz-$tz)*($oz-$oz)) < 10;
      next unless $or->{tlines};
      for my $side (@{$or->{tlines}}) {
	next unless defined $side;
	my ($prx,$prz) = intersect($side->[0],$side->[1],
				   $side->[2],$side->[3],
				   $tx,$tz,$px,$pz);
	unless ($prx == -1 && $prz == -1) {
	  $px = $prx;		# Locate the nearest encounter
	  $pz = $prz;
	  $touch = 1;
	}
      }
    }
  }
  my $dist = 1000;
  $dist = sqrt(($px-$tx)*($px-$tx)+($pz-$tz)*($pz-$tz)) if ($touch);

  if ($dist < 1) { #XXX how far?
    $self->send_event('collision',$container,$sender);
  }
}

#------------------------------------------------------------------------------
{;
 my $lastx    = -999;
 my $lastz    = -999;
 my $lastdir  = -999;
 my $lastdist = 0;;

 sub performStep {
   my ($self,$stash,$team,$ev,$steps,$speed,$direction) = @_;

   # Handle possibiity of no map during initialization
   return unless defined $self->{cmap};

   if ($speed < 0) {
     $direction = ($direction+180) % 360;
     $speed = -$speed;
   }
   my @min_dist = (10.0,10.0,10.0,10.0);		# look out 10 feet

   ## find teams field of view
   my $tx = $team->x;
   my $tz = $team->z;
   my $tyaw = -$team->yaw+90;	# adjust for coordinate systems
   my $pyaw = 65;
   my $step = $speed*$steps;
   my $moveYaw = $team->yaw + $direction;

   if ($ENV{DESLUG} && $tx==$lastx && $tz==$lastz && $moveYaw==$lastdir
       && $lastdist>$step+.5) {
     $team->x($team->x+$step*cos($moveYaw*RADIANS));
     $team->z($team->z+$step*sin($moveYaw*RADIANS));
     $min_dist[3] = $lastdist - $step;
   }
   else {
     #          left v   center v   right v    travel
     my @p_ = (['x','y'],['x','y'],['x','y'],['x','y']);

     # find point $min_dist ft out on the left peripherial vision ray
     $p_[0][0] = $tx+$min_dist[0]*sin(($tyaw-$pyaw)*RADIANS);
     $p_[0][1] = $tz+$min_dist[0]*cos(($tyaw-$pyaw)*RADIANS);

     # find point $min_dist ft in front of the team
     $p_[1][0] = $tx+$min_dist[1]*sin($tyaw*RADIANS);
     $p_[1][1] = $tz+$min_dist[1]*cos($tyaw*RADIANS);

     # find point $min_dist ft out on the right peripherial vision ray
     $p_[2][0] = $tx+$min_dist[2]*sin(($tyaw+$pyaw)*RADIANS);
     $p_[2][1] = $tz+$min_dist[2]*cos(($tyaw+$pyaw)*RADIANS);

     # find point $min_dist ft out in the direction of travel
     $p_[3][0] = $tx+$min_dist[3]*sin(($tyaw - $direction)*RADIANS);
     $p_[3][1] = $tz+$min_dist[3]*cos(($tyaw - $direction)*RADIANS);

     my @seen_maybe = ([],[],[]);
     my ($obstacle,$tractable,$thing);
     my $map = $self->currmap;
     $map->get_map_view;
     $map->find_objects;
     my ($oc,$ic) = (0,0);
     foreach my $o (@{$map->{objects}}) {
       $oc++;
       my ($ox,$oy,$oz,$or) = @$o;
       next unless (($ox-$tx)*($ox-$tx)+($oz-$tz)*($oz-$oz)) < 100;
       next if $or == $map;
       my @sides = (defined $or->{tlines}) ? @{$or->{tlines}} : ();
       for my $i (0..3) {
	 my ($px,$pz) = ($p_[$i][0],$p_[$i][1]);
	 my $touch = 0;
	 for my $side (@sides) {
	   next unless defined $side;
	   $ic++;
	   my ($prx,$prz) = intersect($side->[0],$side->[1],
				      $side->[2],$side->[3],
				      $tx,$tz,$px,$pz);
	   unless ($prx == -1 && $prz == -1) {
	     $px = $prx;		# Locate the nearest encounter
	     $pz = $prz;
	     $touch = 1;
	     $tractable = $side->[5];
	     $thing = $side->[6];
	   }
	 }
	 if ($touch) {
	   my $dist = sqrt(($px-$tx)*($px-$tx)+($pz-$tz)*($pz-$tz));
	   if ($dist < $min_dist[$i]) {
	     if ($i < 3) {		# checking for 'seen'
	       push @{$seen_maybe[$i]}, [$dist,$thing];
	       if ($tractable eq 'solid') {           # this will stop us, so
		 ($p_[$i][0],$p_[$i][1]) = ($px,$pz); # only look out this far
		 # from now on
		 $min_dist[$i] = $dist;
	       }
	     }
	     else {		# checking for obstacle to travel
	       if ($tractable ne 'passable') {        # this will stop us, so
		 ($p_[$i][0],$p_[$i][1]) = ($px,$pz); # only look out this far
		 # from now on
		 $min_dist[$i] = $dist;
		 $obstacle = $or;
	       }
	     }
	   }
	 }
       }
     }
     # sort out what is 'seen'
     my $thingsSeen = 0;		# things requiring nodding
     my $nodDist    = 6.0;		# look out 6 feet
     for my $i (0..3) {
       for my $candidate (@{$seen_maybe[$i]}) {
	 if ($candidate->[0] <= $min_dist[$i]) {
	   $candidate->[1]->{seen} = 'true';
	   # Check if looking down needed
	   if ($candidate->[1]->can('make_me_nod')
	       && $candidate->[1]->make_me_nod ) {
	     if ($candidate->[0] <= $nodDist) {
	       # make the team look down (nod)
	       $thingsSeen++;
	       my $elev = $team->y-1;
	       my $atan2val = -atan2($elev,$candidate->[0])*DEGREES;
	       $team->{target}{pitch} = $atan2val;
	     }
	   }
	 }
       }
     }
     ## stop looking down if nothing in sight on the floor
     $team->{target}{pitch} = 0 unless $thingsSeen;

     #my $step = $speed*$steps;
     return if ($step==0 and $direction==0);

     #Move the team, if possible
     my $dist = $min_dist[3];
     if ($dist >= abs($step)+0.5 || $ENV{'WIZARD'}) {
       my $moveYaw = $team->yaw + $direction;
       $team->x($team->x+$step*cos($moveYaw*RADIANS));
       $team->z($team->z+$step*sin($moveYaw*RADIANS));
       print STDERR "$obstacle is in our way\n"
	 if ($ENV{'WIZARD'} && $dist < abs($step)+0.5);
     } else {
       print "Bang!!\n";
       $self->send_event('msg',"Bang!!\n");
       $self->send_event('bell');
     }
   }
   $lastx = $team->x; $lastz = $team->z; $lastdir = $moveYaw;
   $lastdist = $min_dist[3];

   $team->is_at($self->currmap);
   $self->send_event('team_at',$team->x,$team->z,$self->currmap);
   $self->send_event('need_redraw');
 }
}

#--------------------------------------------------
### From Paul Bourke
#   http://local.wasp.uwa.edu.au/~pbourke/geometry/lineline2d/
#
sub intersect {
  my ($x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4) = @_;

  my $denom = (($y4-$y3)*($x2-$x1)-($x4-$x3)*($y2-$y1));
  if ($denom == 0) {
    return (-1,-1);
  }
  my $ua = (($x4-$x3)*($y1-$y3)-($y4-$y3)*($x1-$x3))/$denom;
  my $ub = (($x2-$x1)*($y1-$y3)-($y2-$y1)*($x1-$x3))/$denom;

  if (($ua<0) || ($ua>1) || ($ub<0) || ($ub>1)) {
    return (-1,-1);
  }

  return ($x1+$ua*($x2-$x1),$y1+$ua*($y2-$y1));
}

#==================================================================
###
### Test Driver
###
if (!defined(caller())) {
  package main;

  print "gameState\n";
  #my $g = OpenGL::QEng::GameState->new;

  open(my $m,'>','/tmp/gs_testmap.txt');
  print $m "map 0 0 0 xsize=>24, zsize=>24;\n";
  print $m "in_last;\n";
  print $m "   wall 16 0 270;\n";
  print $m "done;\n";
  close $m;

  #$g->load('/tmp/gs_testmap.txt','I want a map');
  my $g = GameState->load('/tmp/gs_testmap.txt');
  print "$g\n";
  print "bye\n";
}

1;

__END__

=head1 NAME

GameState -- Container class holding all maps, chars & items
Saving GameState saves all needed to continue the game

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

