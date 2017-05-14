###  $Id: Thing.pm 427 2008-08-19 18:40:46Z duncan $
####------------------------------------------
## @file Thing.pm
# Define Thing Class

## @class Thing
# Base class for all things in this universe
#
# Everything that can be seen is a thing

package OpenGL::QEng::Thing;

use strict;
use warnings;
use OpenGL qw/:all/;
use File::ShareDir;
use OpenGL::QEng::Event;
use OpenGL::QEng::TextureList;

use base qw/OpenGL::QEng::OUtil/;

use constant PI => 4*atan2(1,1); # 3.14159;
use constant RADIANS => PI/180.0;

#------------------------------------------
# @cmethod % new()
# Create a Thing
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self =
    {event        => OpenGL::QEng::Event->new,
     xsize        => undef,
     ysize        => undef,
     zsize        => undef,
     x            => 0,		# Thing current location x
     y            => 0,		# Thing current location y
     z            => 0,		# Thing current location z
     roll         => 0,		# rotation about z axis
     pitch        => 0,		# rotation about x axis
     yaw          => 0,		# rotation about y axis
     is_at        => undef,	# container of this Object
     seen         => 0,		# this thing been seen by the team? y/n XXX?
     texture      => undef,	# Texture image for this thing
     GLid         => undef,
     state        => undef,
     event_script => undef,
     event_code   => {},
     near_script  => undef,
     near_code    => undef,
     range        => undef,
     wrap_class   => undef,
     target       => {},
     eye_magnet   => 0,
     holder       => 0,
     visible      => 1,
     store_at     => {x=>0, y=>0.01, z=>0, roll=>0, pitch=>0, yaw=>0},
     holds        => undef,
     parts        => undef,
     name         => undef,
     no_events    => undef,
    };
  bless($self,$class);

  $self->passedArgs($props) if keys %$props;
  $self->create_accessors;
  $self->claim_GLid;
  $self->register_events;
  $self;
}

#--------------------------------------------------
sub register_events {
  my ($self) = @_;

  return if $self->no_events;
  if (defined $self->event_script) {
    for my $event (keys %{$self->event_script}) {
      unless (ref($self->event_code->{$event})) {
	my $cmdTxt = '$self->{event_code}{$event} = '
	  .$self->event_script->{$event};
	eval $cmdTxt;
	if ($@) {
	  print STDERR "EVAL ($cmdTxt) FAILED: $@\n";
	  next;
	}
      }
      $self->event->callback($self,$event,$self->event_code->{$event});
    }
  }
  if (defined $self->near_script) {
    unless (ref $self->near_code) {
      my $cmdTxt = '$self->{near_code} = ' .$self->near_script;
      eval $cmdTxt;
      if ($@) {
	print STDERR "EVAL ($cmdTxt) FAILED: $@\n";
      }
    }
    $self->{event}->callback($self,'team_at',\&handle_near);
  }
  if (defined $self->name) {
    $self->{event}->callback($self,'who_is',
			    sub {
			      my ($self,$stash,$obj,$ev,$name,@args) = @_;
			      $self->send_event('i_am',$name)
				if $self->name eq $name;
			    });
  }
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
{my $GLid_serial = 1000;	# GLid starting number
 my %GLid2objref;

#--------------------
 sub find_thing_by_GLid {
   my ($class, $GLid) = @_;
   $GLid2objref{$GLid};
 }

#--------------------
 sub claim_GLid {
   my ($self) = @_;
   die "$self -> sub claim_GLid(): no GLid method" unless $self->can('GLid');
   if (defined $self->GLid) {
     warn "$self already has GLid $self->{GLid}";
   } else {
     $self->{GLid} = $GLid_serial++;
   }
   $GLid2objref{$self->GLid} = $self;
 }
} #end closure - - - - - - - - - - - - - - - - - - - - - - -

#-----------------------------------------------------------------
sub make_me_nod {
  my ($self) = @_;
  $self->eye_magnet || 0;
}

#-----------------------------------------------------------------
sub can_hold {
  my ($self,$thing) = @_;
  $self->holder || 0;
}

#-----------------------------------------------------------------
sub special_parts {} #no parts are special by default

#------------------------------------------
## @method draw($mode)
# Draw this object in its current state at its current location
# or set up for testing for a touch
sub draw {
  die join(':', caller),' called Thing::draw()';
}

#---------------------------------------------------------
##@method contains(@things)
#
#With array arg, add all to things contained by the current thing
#Always return things contained by current thing
#
sub contains {
  my ($self,@things) = @_;

  die "contains($self,@things) from ",join(':',caller)," " if @things;

  my ($p,$h) = ($self->parts || [],$self->holds || []);
  return [@$p,@$h];
}

#--------------------------
## @method assimilate($thing)
# make $thing a part of $self
#
sub assimilate {
  my ($self,$thing) = @_;

  return unless defined($thing);
  push @{$self->{parts}}, $thing;
  $thing->is_at($self);
  $thing->invalidate_map_view;
}

#--------------------------
## @method put_thing($thing)
#put arg (a thing instance) into the current thing
sub put_thing {
  my ($self,$thing,$store) = @_;

  return unless defined($thing);
  die "put_thing($self,$thing) from ",join(':',caller)," " unless $store;

  push @{$self->{holds}}, $thing;
  $thing->is_at($self);
  $thing->invalidate_map_view;
  $self->invalidate_map_view($thing); #XXX ??? test

  if (defined(my $store_location = $self->store_at)) {
    $thing->x    ($store_location->{x})    if defined $store_location->{x};
    $thing->y    ($store_location->{y})    if defined $store_location->{y};
    $thing->z    ($store_location->{z})    if defined $store_location->{z};
    $thing->roll ($store_location->{roll}) if defined $store_location->{roll};
    $thing->pitch($store_location->{pitch})if defined $store_location->{pitch};
    $thing->yaw  ($store_location->{yaw})  if defined $store_location->{yaw};
  }
}

#--------------------------
## @method take_thing($desired_thing)
#remove arg (a thing instance) from the current thing and return it
sub take_thing {
  my ($self,$desired_thing) = @_;

  return unless defined $desired_thing;
  my $returned_thing;
  my @things;
  while (my $thing = shift(@{$self->{holds}})) {
    if ($thing eq $desired_thing) {
      $returned_thing = $thing;
    } else {
      push(@things,$thing);
    }
  }
  $self->{holds} = \@things;
  unless (defined $returned_thing) {
    print STDERR "$desired_thing not found in $self\n";
    return;
  }
  $returned_thing->is_at->invalidate_map_view($returned_thing);
  $returned_thing;
}

#--------------------------
sub excise {
  my ($self,$thing) = @_;

  return unless defined $thing;
  my $returned_thing;
  my @things = @{$self->{parts}};
  $self->{parts} = [];
  while (my $t = shift @things) {
    if ($t == $thing) {
      $returned_thing = $t;
    } else {
      push @{$self->{parts}}, $t;
    }
  }
  unless (defined $returned_thing) {
    print STDERR "$thing not found in $self\n";
    return;
  }
  $returned_thing->is_at->invalidate_map_view($returned_thing)
    if defined $returned_thing->is_at;
  $returned_thing;
}

#-------------------------------------
## @method   send_event(%event)
#signal an event
sub send_event {
  $_[0]->{event}->yell(@_)
}

#------------------------------------------
sub printArray {
  my ($aref) = @_;

  print STDOUT "[";
  for my $i (@$aref) {
    if    (ref($i) eq '') {
      printScalar($i);
    }
    elsif (ref($i) eq 'ARRAY') {
      printArray($i);
    }
    elsif (ref($i) eq 'HASH') {
      printHash($i);
    }
    else {
      warn "printArray won't do '$i' because it is a ", ref $i,
	" caller ",join(':',caller);
    }
  }
  print STDOUT "],";
}

#------------------------------------------
sub printHash {
  my ($href) = @_;

  print STDOUT "{";
  for my $k (keys %$href) {
    print STDOUT "$k=>";
    if    (ref($href->{$k}) eq '') {
      printScalar($href->{$k});
    }
    elsif (ref($href->{$k}) eq 'ARRAY') {
      printArray($href->{$k});
    }
    elsif (ref($href->{$k}) eq 'HASH') {
      printHash($href->{$k});
    }
    else {
      warn "printHash won't do '$href->{$k}' because it is a ",
	ref $href->{$k};
    }
  }
  print STDOUT "},";
}

#------------------------------------------
sub printScalar {
  my ($s) = @_;

  #return unless defined $s;
  if (! defined $s) {
    print STDOUT 'undef,';
  }
  elsif (ref($s) eq '') {
    no warnings 'numeric';
    if ($s eq 0+$s) {		                               #num
      print STDOUT "$s,";
    }
    elsif ((index($s,"\n") == -1) and (index($s,"'") == -1)) { #q
      print STDOUT "'$s',";
    }
    else {			                               #qq
      $s =~ s/\n/\\n/g;
      $s =~ s/"/\\"/g;
      print STDOUT "\"$s\",";
    }
  }
  else {
    warn "printScalar won't do '$s' because it is a ", ref $s;
  }
}

#------------------------------------------
{;
 my %deflt_cache;

 sub not_default {
   my ($self) = @_;

   unless (exists $deflt_cache{ref $self}) {
     $deflt_cache{ref $self} = ref($self)->new(no_events=>1);
   }
   my $dflt = $deflt_cache{ref $self};

   my $href = {};
   for my $key (keys %{$self}) {
     if (!defined($dflt->{$key})) {
       $href->{$key} = $self->{$key};
     }
     elsif (defined $self->{$key}) {
       $href->{$key} = $self->{$key}
	 if (ref2str($self->{$key}) ne ref2str($dflt->{$key}));
     }
   }
   $href;
 }
} # end closure

#------------------------------------------
sub boring_stuff {
  {x         => 1,
   z         => 1,
   yaw       => 1,
   GLid      => 1,
   event     => 1,
   is_at     => 1,
   holds     => 1,
   parts     => 1,
   map_view  => 1,
   range_2   => 1,
   near_code => 1,
   event_code=> 1,
   wrap_class=> 1,
   objects   => 1,
   tlines    => 1,
  }		
}

#------------------------------------------
sub printMe {
  my ($self,$depth) = @_;

  $depth ||= 0;
  my $started = 0;
  for my $sp ($self->special_parts) {
    next unless defined $self->{$sp};
    unless ($started) {
      print STDOUT '  'x$depth,"partof_next;\n" unless $started;
      $started = 1;
    }
    $self->{$sp}->{name} =
      'XX'.$self->{$sp} unless defined($self->{$sp}->{name});
    $self->{$sp}->printMe($depth+1);
  }
  print STDOUT '  'x$depth,"done;\n" if $started;

  (my $map_ref = ref $self) =~ s/OpenGL::QEng:://;
  print STDOUT '  'x$depth,"$map_ref $self->{x} $self->{z} $self->{yaw}";
  my $spec = $self->not_default;
  my $boring = $self->boring_stuff;
  for my $key (keys %{$spec}) {
    next unless defined $spec->{$key};
    next if defined $boring->{$key};

    if    (ref($spec->{$key}) eq '') {
      print STDOUT " $key=>";
      printScalar($spec->{$key});
    }
    elsif (ref($spec->{$key}) eq 'ARRAY') {
      next unless @{$spec->{$key}};
      print STDOUT " $key=>";
      printArray($spec->{$key});
    }
    elsif (ref($spec->{$key}) eq 'HASH') {
      next unless keys %{$spec->{$key}};
      print STDOUT " $key=>";
      printHash($spec->{$key});
    }
    else {
      warn "$self ->printMe won't do '$key' because it is a ",
	ref $spec->{$key};
    }
  }
  for my $sp ($self->special_parts) {
    print STDOUT " $sp=>{named=>'$self->{$sp}->{name}'},"
      if defined($self->{$sp});
  }
  print STDOUT ";\n";

  my @parts = @{$self->parts} if $self->parts;
  $started = 0;
 PART:
  for my $thing (@parts) {
    next if exists $thing->{i_am_a_wall_chunk};
    for my $sp ($self->special_parts) {
      next PART if ((!$self->{$sp}) || $thing eq $self->{$sp});
    }
    unless ($started) {
      print STDOUT '  'x$depth,"partof_last;\n" unless $started;
      $started = 1;
    }
    $thing->printMe($depth+1);
  }
  print STDOUT '  'x$depth,"done;\n" if $started;

  my @holds = @{$self->holds} if $self->holds;
  $started = 0;
  for my $thing (@holds) {
    unless ($started) {
      print STDOUT '  'x$depth,"in_last;\n" unless $started;
      $started = 1;
    }
    $thing->printMe($depth+1);
  }
  print STDOUT '  'x$depth,"done;\n" if $started;
}

#-----------------------------------------------------------
## @method handle_touch()
#default touch handler method for Things
#
sub handle_touch {
  return unless defined($ENV{WIZARD});
  my $where = $_[0]->is_at || 'undef';
  print STDERR "Thing::handle_touch(",join(',',@_),")\n";
  print STDERR "--\t$_[0] is_at: $where\n";
}

#--------------------------------------------------
sub handle_near {
  my ($self,$stash,$obj,$ev,$tx,$tz,$currmap,@args) = @_;
  warn 'handle_near: undefined currmap' unless defined $currmap;

  return unless defined $self->range;
  my $range = $self->range;
  $self->range(undef);		# poor man's exclusion lock

  if (defined($self->near_code) && $self->is_at eq $currmap) {
    my $distSq = ($self->x-$tx)*($self->x-$tx)+($self->z-$tz)*($self->z-$tz);
    $self->{range_2} ||= $range*$range;
    $self->near_code->($distSq) if ($distSq <= $self->{range_2});
  }

  $self->range($range);		# unlock me
}

#------------------------------------------------------------
sub tractable { # tractability - 'solid', 'seethru', 'passable'
  return 'passable';
}

#-------------------------------------
sub color_me_gone {
  my $self = shift;

  my $where_am_i = $self->is_at();
  $where_am_i->take_thing($self);
}

#-----------------------------------------------------------
## @method unlock($self,$team)
#Attempt to unlock this Thing.  Test that the team is using the matching key.
#Provide helpful feed back to the game player.
#
sub unlock {
  my ($self,$team_holds) = @_;

  my ($unlocker) = ($self->key or $self->opener or '(undef)');
  my $try_key =
    (ref($team_holds) eq 'OpenGL::QEng::Key') ? $team_holds->type : ref($team_holds);
  $try_key =~ s/OpenGL::QEng:://;

  if ($try_key eq $unlocker) {# success
    $self->state('closed');
    #$self->send_event('state');
    if (defined $self->opener) {
      $self->send_event('msg',"'Using the $try_key, frees the door'\n");
    } else {
      $self->send_event('msg',"The $try_key key turns in the lock\n",
			      "'Click'\n");
    }
    return $team_holds;
  } else {                    # failure
    print "Locked/Stuck tryed: $try_key, need: $unlocker\n"
      if ($ENV{WIZARD});
    if (defined $self->opener) {       # need opener and have nothing
                                       # or need opener and have wrong thing
      $self->send_event('msg',"Stuck\n");
    }
    else {
      if (ref($team_holds) eq 'OpenGL::QEng::Key') { # need key and have wrong key
	$self->send_event('msg',"The $try_key key doesn't fit.\n");
      }
      elsif ($try_key) {               # need key and have something else
	$self->send_event('msg',"A $try_key won't unlock it.\n");
      }
      else {                           # need key and don't have anything
	$self->send_event('msg',"Locked\n");
      }
    }
    return 0;
  }
}

#--------------------------------------------------
sub model {
  die "bad arg @_ from ",join(':',caller) if defined $_[1] && !ref $_[1];
  die "$_[0] has no model in hash ",join(':',caller)
    unless exists $_[0]->{model};
  return unless exists $_[0]->{model};
  $_[0]->{model} = $_[1] if defined $_[1];
  $_[0]->{model};
}

#---------------------------------------------------------
sub get_corners {
  my ($self) = @_;

  my $corners = [];
  return $corners unless $self->visible;

  my $color = ($self->seen) ? $self->color || 'black' : undef;
  $color = $color->[0] if ref $color eq 'ARRAY';
  my $tract = $self->tractable;
  die "oops: $self" unless $tract;

  die 'bad model' unless (ref $self->{model} eq 'HASH');
  my ($minx, $maxx) = ($self->{model}{minx}, $self->{model}{maxx});
  my ($miny, $maxy) = ($self->{model}{miny}, $self->{model}{maxy});
  my ($minz, $maxz) = ($self->{model}{minz}, $self->{model}{maxz});

  if (defined($minx) && defined($maxx) && defined($minz) && defined($maxz)) {
    if (($self->y+$miny) < 1 && ($self->y+$maxy) > 0) {
      push @$corners,
	[$minx, $minz, $minx, $maxz, $color, $tract, $self],
        [$minx, $maxz, $maxx, $maxz, $color, $tract, $self],
	[$maxx, $maxz, $maxx, $minz, $color, $tract, $self],
	[$maxx, $minz, $minx, $minz, $color, $tract, $self];
    }
    #XXX later this test should be modified by the team current y
  }
  $corners;
}

#-----------------------------------------------------------
sub find_objects {
  my ($self) = @_;

  unless (defined $self->{objects}) {
    my $yaw = $self->yaw;
    my ($selfX,$selfY,$selfZ) = ($self->x,$self->y,$self->z);
    die "$self missing prereqs: $yaw,$selfX,$selfZ"
      unless defined($yaw) && defined($selfX) && defined($selfZ);

    my $objects;
    for my $obj (@{$self->contains}) {
      for my $list ($obj->find_objects) {
	die "poor map view from $obj: list=$list\n"
	  unless defined $list && ref($list) eq 'ARRAY';
	push @$objects, @$list;
      }
    }
    push @{$self->{objects}}, [$self->x,$self->y,$self->z,$self];
    for my $line (@$objects) {
      push @{$self->{objects}},
	[$selfX+cos($yaw*RADIANS)*$line->[0]+sin($yaw*RADIANS)*$line->[2],
	 $selfY+$line->[1],
	 $selfZ-sin($yaw*RADIANS)*$line->[0]+cos($yaw*RADIANS)*$line->[2],
	 $line->[3]];
    }
  }
  return $self->{objects};
}

#-----------------------------------------------------------
## @method @ get_map_view()
# Get the location of this object and
# a color reflecting if the object has been seen yet
sub get_map_view {
  my $self = shift;

  unless (defined $self->{map_view}) {
    my $yaw = $self->yaw;
    my ($selfX,$selfY,$selfZ) = ($self->x,$self->y,$self->z);
    die "$self missing prereqs: $yaw,$selfX,$selfZ"
      unless defined($yaw) && defined($selfX) && defined($selfZ);

    my @corners = @{$self->get_corners};

    for my $obj (@{$self->contains}) {
      my %parts;
      for my $line ($obj->get_map_view) {
	die "poor map view from $obj:"
	  unless defined $line && ref($line) eq 'ARRAY' && @$line >= 4;
	push @corners,[$line->[0],$line->[1],$line->[2],$line->[3],
		       $line->[4],$line->[5],$line->[6]];
	$parts{$line->[6]} = $line->[6];
      }
      for my $p (keys %parts) { delete($parts{$p}->{tlines}) }
    }

    my @view;
    for my $line (@corners) {
      my $tline =
	[$selfX+cos($yaw*RADIANS)*$line->[0]+sin($yaw*RADIANS)*$line->[1],
	 $selfZ-sin($yaw*RADIANS)*$line->[0]+cos($yaw*RADIANS)*$line->[1],
	 $selfX+cos($yaw*RADIANS)*$line->[2]+sin($yaw*RADIANS)*$line->[3],
	 $selfZ-sin($yaw*RADIANS)*$line->[2]+cos($yaw*RADIANS)*$line->[3],
	 $line->[4],$line->[5],$line->[6]];
      push @view, $tline;
      push @{$line->[6]->{tlines}}, $tline;
    }
    $self->{map_view} = \@view;
  }
  return @{$self->{map_view}};
}

#----------------------------------------------------------------------
sub invalidate_map_view {
  my ($self,$thing) = @_;

  undef $self->{map_view};
  undef $self->{objects} if ref $thing;

  $self->is_at->invalidate_map_view($thing)
    if defined $self->is_at && $self->is_at->can('invalidate_map_view');
  (print STDERR "$self has no home\n",return) unless defined $self->is_at;
  print STDERR "${self}'s home can't invalidate\n" unless $self->is_at->can('invalidate_map_view');
}

#------------------------------------------
## @method move()
# Step the animation
sub move {
  my ($self) = @_;

  my $need_redraw = 0;
  if (values %{$self->target}) {
    my %quantum = (x=>.2,   y=>.2,   z=>.2,
		   roll=>2, pitch=>2, yaw=>2,
		   opening=>2, levang=>2);
    for my $attr (keys %quantum) {
      if (defined $self->{target}{$attr}) {
	die "oops: $attr" unless defined $self->{$attr};
	if ($self->{$attr} == $self->{target}{$attr}) {
	  undef $self->{target}{$attr};
	}
	else {
	  my $delta = abs($self->{$attr} - $self->{target}{$attr});
	  if ($delta <= $quantum{$attr}) {
	    $self->{$attr} = $self->{target}{$attr};
	    undef $self->{target}{$attr};
	  } elsif ($self->{target}{$attr} > $self->{$attr}) {
	    $self->{$attr} += $quantum{$attr};
	  } else {
	    $self->{$attr} -= $quantum{$attr};
	  }
	  $need_redraw++;
	  $self->invalidate_map_view($self);
	}
      }
    }
  }
  if ($self->isa('OpenGL::QEng::Team')) {
    $self->send_event('team_at',$self->x,$self->z,$self->is_at)
      if $need_redraw;
  }
  elsif ($self->contains) {
    foreach my $o (@{$self->contains}) {
      $o->move;
    }
  }
  $self->send_event('need_redraw') if $need_redraw;
}

#----------------------------------------------------
{;
 my $textList;

## @method $ pickTexture($key)
# Set the texture from a texture name string
 sub pickTexture {
   my ($self,$key) = @_;

   unless (defined $textList) {
     my $idir = File::ShareDir::dist_dir('Games-Quest3D');
     $idir .= '/images';
     $textList = OpenGL::QEng::TextureList->new($idir);
   }
   $textList->pickTexture($key);
 }
}

#-------------------------------------
## select a color by name

{;# @map_item Current colors are:
 my %colors;

 sub make_color_map {
   %colors = ('blue'     =>[0.0,0.0,1.0],
	      'purple'   =>[160.0/255.0, 23.0/255.0, 240.0/255.0],
	      'pink'     =>[1.0,192.0/255.0,203.0/255.0],
	      'red'      =>[1.0,0.0,0.0],
	      'magenta'  =>[1.0,0.0,1.0],
	      'yellow'   =>[1.0,1.0,0.0],
	      'white'    =>[1.0,1.0,1.0],
	      'cyan'     =>[0.0,1.0,1.0],
	      'green'    =>[0.0,1.0,0.0],
	      'beige'    =>[245.0/255.0,245.0/255.0,135.0/255.0],
	      'brown'    =>[141.0/255.0, 76.0/255.0, 47.0/255.0],
	      'orange'   =>[255.0/255.0,165.0/255.0,0.0/255.0],
	      'gold'     =>[255.0/255.0,215.0/255.0,0.0/255.0],
	      'gray'     =>[64.0/255.0,64.0/255.0,64.0/255.0],
	      'gray75'   =>[191.0/255.0,191.0/255.0,191.0/255.0],
	      'slate gray'=>[112.0/255.0,128.0/255.0,144.0/255.0],
	      'darkgray' =>[47.0/255.0,79.0/255.0,79.0/255.0],
	      'medgray'  =>[192.0/255.0,192.0/255.0,192.0/255.0],
	      'lightgray'=>[211.0/255.0,211.0/255.0,211.0/255.0],
	      'black'    =>[0.0,0.0,0.0],
	      'cream'    =>[250.0/255.0,240.0/255.0,230.0/255.0],
	      'light green' =>[144.0/255.0,238.0/255.0,144.0/255.0],
	      'light blue' =>[173.0/255.0,216.0/255.0,230.0/255.0],
	     );
   my $path = 'rgb.txt';
   for my $p ('/etc/X11/rgb.txt',
	      '/usr/share/X11/rgb.txt',
	      '/usr/X11R6/lib/X11/rgb.txt',
	      '/usr/openwin/lib/X11/rgb.txt',
	     ) {
     ($path=$p, last) if -f $p;
   }
   if (open my $rgb,'<',$path) {
     while (my $line = <$rgb>) {
       my ($r,$g,$b,$name);
       next unless ($r,$g,$b,$name) =
	 $line =~ /^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\w.*\w)\s*$/;
       $colors{lc $name} = [$r/255.0,$g/255.0,$b/255.0,];
     }
     close $rgb;
   }
 }

#-------------------------------------
## @method setColor($color)
# set the color from a text name
 sub setColor {
   my ($self,$color) = @_;

   die "setColor($self,) c.f. ",join(':',caller),"\n" unless $color;
   make_color_map() unless $colors{red};
   $color = lc $color;
   if ($color eq 'clear'){
     glColor4f(0.0,0.0,0.0,1.0);
   } elsif (defined($colors{$color})) {
     glColor4f($colors{$color}[0],$colors{$color}[1],$colors{$color}[2],1.0);
   } else {
     print "unknown color $color\n";
   }
 }

#-------------------------------------
## @method @ getColor($color)
# get the color value triplet from a text name
 sub getColor {
   my ($self,$color) = @_;

   die "getColor($self,) c.f. ",join(':',caller),"\n" unless $color;
   make_color_map() unless $colors{red};
   $color = lc $color;
   if (defined $colors{$color}) {
     return @{$colors{$color}};
   }
   print "unknown color $color\n";
 }
} # end closure

#------------------------------------------
## @method $ tErr
# print any pending OpenGL error
sub tErr { return; #XXX for timing
  my ($self,$w) = @_;

  while (my $e = glGetError()) {
    print "$e, ",gluErrorString($e)," \@:$w\n";
  }
}

#-------------------------------------
{my $dlRoot = 1;
 sub getDLname {
   $dlRoot++;
 }
}

#------------------------------------------
sub ref2str {
  my ($ref) = @_;

  if    (ref($ref) eq 'ARRAY') {
    return aref2str($ref);
  }
  elsif (ref($ref) eq 'HASH') {
    return href2str($ref);
  }
  elsif (! defined $ref) {
    return 'undef';
  }
  else {
    return $ref;
  }
}

#------------------------------------------
sub aref2str {
  my ($aref) = @_;

  my $str = '[';
  for my $i (@$aref) {
    #next unless defined $i;
    if    (ref($i) eq 'ARRAY') {
      $str .= aref2str($i);
    }
    elsif (ref($i) eq 'HASH') {
      $str .= href2str($i);
    }
    elsif (! defined $i) {
      $str .= 'undef,';
    }
    else {
      $str .= $i.',';
    }
  }
  $str .= '],';
}

#------------------------------------------
sub href2str {
  my ($href) = @_;

  my $str = '{';
  for my $k (keys %$href) {
    #next unless defined $href->{$k};
    $str .= "$k=>";
    if    (ref($href->{$k}) eq 'ARRAY') {
      $str .= aref2str($href->{$k});
    }
    elsif (ref($href->{$k}) eq 'HASH') {
      $str .= href2str($href->{$k});
    }
    elsif (! defined $href->{$k}) {
      $str .= 'undef,';
    }
    else {
      $str .= $href->{$k}.',';
    }
  }
  $str .= '},';
}

#==================================================================
###
### Test Driver for Thing Objects
###
if (not defined caller()) {
  package main;
  #require Data::Dumper;

  my $v = OpenGL::QEng::Thing->new;
  warn $v;
  $v->printMe;
  #print '$v is',Dumper($v),"\n";
}

1;

__END__

=head1 NAME

Thing -- Base class for everything in the 3D part of the game

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

