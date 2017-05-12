#
# This file is part of the Perlilog project.
#
# Copyright (C) 2003, Eli Billauer
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
# A copy of the license can be found in a file named "licence.txt", at the
# root directory of this project.
#

# Perlilog's basic root class
${__PACKAGE__.'::errorcrawl'}='system';
#our $errorcrawl='system';
sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);
  my $class = ref($this) || $this;
  $self = {} unless ref($self); 
  bless $self, $class;
  $self->store_hash([], @_);
  if (defined $Perlilog::interface_rec) {
    my $name = $self->get('nick');
    puke("New \'$class\' transient object created without the 'nick' property set\n")
      unless (defined $name);
    puke("New \'$class\' transient object created with illegal nick: \'$name\'\n")
      unless ($name=~/^[a-zA-Z_]\w*$/);	
    $self -> set('perlilog-transient', 'transient'); 
  } else {
    my $name = $self->get('name');
    puke("New \'$class\' object created without the 'name' property set\n")
      unless (defined $name);
    puke("New \'$class\' object created with illegal name: ".$self->prettyval($name)."\n")
      unless ($name=~/^[a-zA-Z_]\w*$/);

    blow("New \'$class\' object created with an already occupied name: \'$name\'\n")
      if (exists $Perlilog::objects{$name});
    my $lc = lc($name);
    foreach (keys %Perlilog::objects) {
      blow("New \'$class\' object created with a name \'$name\' when \'$_\' is already in the system (only case difference)\n")
	if (lc($_) eq $lc);
    }
    $Perlilog::objects{$name}=$self;
    my $papa = $self->get('parent');
    $self -> setparent($papa) if (ref($papa));
  }
  $self -> const('perlilog-object-count', $Perlilog::objectcounter++);
  return $self;
}  

sub sustain {
  my $self = shift;
  my $name = $self->suggestname($self->get('nick'));
  $self->const('name', $name);
  $Perlilog::objects{$name}=$self;
  $self -> set('perlilog-transient', 'sustained'); 
  my $papa = $self->get('parent');
  $self -> setparent($papa) if (ref($papa));
}

sub who {
  my $self = shift;
  return "object \'".$self->get('name')."\'";
}

sub safewho {
  my ($self, $who) = @_;
  return "(non-object item)" unless ($self->isobject($who));
  return $who->who;
}

sub isobject {
  my ($self, $other) = @_;
  my $r = ref $other;
  return 1 if (Perlilog::definedclass($r) == 2);
  return undef;
}

sub objbyname {
  my ($junk, $name) = @_;
  return $Perlilog::objects{$name};
}

sub suggestname {
  my ($self, $name) = @_;
  my $sug = $name;
  my ($bulk, $num) = ($name =~ /^(.*)_(\d+)$/);
  my %v;

  foreach (keys %Perlilog::objects) { $v{lc($_)}=1; } # Store lowercased names
  unless (defined $bulk) {
    $bulk = $name;
    $num = 0;
  }
  
  while ($v{lc($sug)}) {
    $num++;
    $sug = $bulk.'_'.$num;
  }
  return $sug;
}

sub get {
  my $self = shift;
  my $prop = shift;
  my $final;

  my @path = (ref($prop)) ? @{$prop} : ($prop);

  $final = $self->{join("\n", 'plPROP', @path)};

  # Now try to return it the right way. If we have a reference, then
  # the property is set. So if the calling context wants an array, why
  # hassle? Let's just give an array.
  # But if a scalar is expected, and we happen to have only one
  # member in the list -- let's be kind and give the first value
  # as a scalar.

  if (ref($final)) {
    return @{$final} if (wantarray);
    return ${$final}[0];
  }

  # We got here, so the property wasn't defined. Now, if
  # we return an undef in an array context, it's no good, because it
  # will be considered as a list with lenght 1. If the property
  # wasn't defined we want to say "nothing" -- and that's an empty list.

  return () if (wantarray);

  # Wanted a scalar? Undef is all we can offer now.

  return undef;
}

sub getraw {
  my $self = shift;
 
  return $self->{join("\n", 'plPROP', @_)};
}

sub store_hash {
  my $self = shift;
  my $rpath = shift;
  my @path = @{$rpath};
  my %h = @_;

  foreach (keys %h) {
    my $val = $h{$_};

    if (ref($val) eq 'HASH') {
      $self->store_hash([@path, $_], %{$val});
    } elsif (ref($val) eq 'ARRAY') {
      $self->const([@path, $_], @{$val});
    } else {
      $self->const([@path, $_], $val);
    }
  }
}

sub const {
  my $self = shift;
  my $prop = shift;

  my @path = (ref($prop)) ? @{$prop} : ($prop);

  my @newval = @_;

  my $pre = $self->getraw(@path);

  if (defined($pre)) {
    puke("Attempt to change a settable property into constant\n")
      unless (ref($pre) eq 'PL_const');

    my @pre = @{$pre};

    my $areeq = ($#pre == $#newval);
    my $i;
    my $eq = $self->get(['plEQ',@path]);

    if (ref($eq) eq 'CODE') {
      for ($i=0; $i<=$#pre; $i++) {
	$areeq = 0 unless (&{$eq}($pre[$i], $newval[$i]));
      }
    } else { 
      for ($i=0; $i<=$#pre; $i++) {
	$areeq = 0 unless ($pre[$i] eq $newval[$i]); 
      }
    }

    unless ($areeq) {
      if (($#path==2) && ($path[0] eq 'vars') && ($path[2] eq 'dim')) {
	# This is dimension inconsintency. Will happen a lot to novices,
	# and deserves a special error message.
	wrong("Conflict in setting the size of variable \'$path[1]\' in ".
	      $self->who.". The conflicting values are ".
	      $self->prettyval(@pre)." and ".$self->prettyval(@newval).
	      ". (This usually happens as a result of connecting variables of".
	      " different sizes, possibly indirectly)\n");
	
	
      } else {
	{ local $@; require Perlilog::PLerrsys; }  # XXX fix require to not clear $@?
	my ($at, $hint) = &Perlilog::PLerror::constdump();
	
	wrong("Attempt to change constant value of \'".
	      join(",",@path)."\' to another unequal value ".
	      "on ".$self->who." $at\n".
	      "Previous value was ".$self->prettyval(@pre).
	      " and the new value is ".$self->prettyval(@newval)."\n$hint\n");
      }
    }
  } else {
    if ($Perlilog::callbacksdepth) {
      my $prop = join ",",@path;
      my $who = $self->who;
      hint("On $who: \'$prop\' = ".$self->prettyval(@newval)." due to magic property setting\n");
    }
    $self->domutate((bless \@newval, 'PL_const'), @path);

    my $cbref = $self->getraw('plMAGICS', @path);
    return unless (ref($cbref) eq 'PL_settable');
    my $subref;

    $Perlilog::callbacksdepth++;
    while (ref($subref=shift @{$cbref}) eq 'CODE') {
      &{$subref}($self, @path);
    }
     $Perlilog::callbacksdepth--;
  }
}

sub set {
  my $self = shift;
  my $prop = shift;

  my @path;
  @path = (ref($prop)) ? @{$prop} : ($prop);

  my @newval = @_;

  my $pre = $self->getraw(@path);
  my $ppp = ref($pre);
  puke ("Attempted to set a constant property\n")
    if ((defined $pre) && ($ppp ne 'PL_settable'));
  $self->domutate((bless \@newval, 'PL_settable'), @path);
  return 1;
}

sub domutate {
  my $self = shift;
  my $newval = shift;
  my $def = 0;
  $def=1 if ((defined ${$newval}[0]) || ($#{$newval}>0));
 
  if ($def) {
    $self->{join("\n", 'plPROP', @_)} = $newval;
  } else { delete $self->{join("\n", 'plPROP', @_)}; }
  return 1;
}

sub seteq {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop)) ? @{$prop} : ($prop);
  my $eq = shift;
  puke("Callbacks should be references to subroutines\n")
    unless (ref($eq) eq 'CODE');
  $self->set(['plEQ', @path], $eq);
}

sub addmagic {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop)) ? @{$prop} : ($prop);
  my $callback = shift;

  unless (defined($self->get([@path]))) {   
    $self->punshift(['plMAGICS', @path], $callback);
  } else {
    $Perlilog::callbacksdepth++;
    &{$callback}($self, @path);
    $Perlilog::callbacksdepth--;
  }
}

sub registerobject {
  my $self = shift;
  my $phase = shift;
  if (defined $phase) {
    return undef if ($phase eq 'noreg');
    return $self -> globalobj -> ppush('beginobjects', $self) if ($phase eq 'begin');
    return $self -> globalobj -> ppush('endobjects', $self) if ($phase eq 'end');
  }
  return $self -> globalobj -> ppush('objects', $self);
}

sub pshift {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop)) ? @{$prop} : ($prop);
  my $pre = $self->getraw(@path);
  if (ref($pre) eq 'PL_settable') {
    return shift @{$pre}; 
  } else {
    return $self->set($prop, undef) # We're changing a constant property here. Will puke.
      if (defined $pre);
    return undef; # There was nothing there.
  }
}

sub ppop {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop)) ? @{$prop} : ($prop);
  my $pre = $self->getraw(@path);
  if (ref($pre) eq 'PL_settable') {
    return pop @{$pre}; 
  } else {
    return $self->set($prop, undef) # We're changing a constant property here. Will puke.
      if (defined $pre);
    return undef; # There was nothing there.
  }
}

sub punshift {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop)) ? @{$prop} : ($prop);
  
  my @val = @_;

  my $pre = $self->getraw(@path);
  if (ref($pre) eq 'PL_settable') {
    unshift @{$pre}, @val; 
  } else {
    $self->set(\@path, (defined($pre))? ($pre, @val) : @val);
  }
}

sub ppush {
  my $self = shift;
  my $prop = shift;
  my @path = (ref($prop)) ? @{$prop} : ($prop);
  
  my @val = @_;

  my $pre = $self->getraw(@path);
  if (ref($pre) eq 'PL_settable') {
    push @{$pre}, @val; 
  } else {
    $self->set(\@path, (defined($pre))? (@val, $pre) : @val);
  }
}

sub globalobj {
  return &Perlilog::globalobj();
}

sub setparent {
  my ($self, $papa)=@_;
  wrong("Can't add a child to a static object ".$papa->who()."\n")
    if ($papa->get('static'));
  $self->const('parent', $papa);
  $papa->ppush('children',$self);
}

sub linebreak {
  my $self = shift;
  return &Perlilog::linebreak(@_);
}

sub objdump {
  my $self = shift;
  my @todump;

  unless (@_) {
    @todump = sort {$Perlilog::objects{$a}->get('perlilog-object-count') <=> 
		      $Perlilog::objects{$b}->get('perlilog-object-count')} 
    keys %Perlilog::objects;
    @todump = map {$Perlilog::objects{$_}} @todump; 
  } else {
    @todump = (@_);
  }

  foreach my $obj (@todump) {
    unless ($self->isobject($obj)) {
      my $r = $Perlilog::objects{$obj};
      if (defined $r) {
	$obj = $r;
      } else {
	print "Unknown object specifier ".$self->prettyval($obj)."\n\n";
	next;
      }
    }
    
    my @prefix = ();
    print $self->linebreak($self->safewho($obj).", class=\'".ref($obj)."\':")."\n";
    my $indent = '    ';
    foreach my $prop (sort keys %$obj) {
      my @path = split("\n", $prop);
      shift @path if ($path[0] eq 'plPROP');
      my $propname = pop @path;

      # Now we make sure that the @path will be exactly like @prefix
      # First, we shorten @prefix if it's longer than @path, or if it
      # has items that are unequal to @path.

      CHOP: while (1) {
	# If @prefix is longer, no need to check -- we need chopping
	# anyhow
	unless ($#path < $#prefix) {
	  my $i;
	  my $last = 1;
	  for ($i=0; $i<=$#prefix; $i++) {
	    if ($prefix[$i] ne $path[$i]) {
	      $last = 0; last;
	    }
	  }
	  last CHOP if $last;
	}
	my $tokill = pop @prefix;
	$indent = substr($indent, 0, -((length($tokill) + 3)));
      }

      my $out = $indent;

      # And now we fill in the missing @path to @prefix
      while ($#path > $#prefix) {
	my $toadd = $path[$#prefix + 1];
	push @prefix, $toadd;
	$out .= "$toadd > ";
	$toadd =~ s/./ /g; # Substitute any character with white space...
	$indent .= "$toadd   ";
      }
      $out .= "$propname=";

      # Now we pretty-print the value.
      my $valref = $obj->{$prop};
      my @val = (ref($valref)) ? @$valref : (undef);
 
      my $extraindent = $out;
      $extraindent =~ s/./ /g;

      $out .= $self->prettyval(@val);

      # Finally, we do some linebreaking, so that the output will be neat
      print $self->linebreak($out, $extraindent)."\n";
    }
    print "\n";
  }
}

sub prettyval {
  my $self = shift;
  my $MaxListToPrint = 4;
  my $MaxStrLen = 40;

  my @a = @_; # @a will be manipulated. Get a local copy

  if (@a > $MaxListToPrint) {
    # cap the length of $#a and set the last element to '...'
    $#a = $MaxListToPrint;
    $a[$#a] = "...";
  }
  for (@a) {
    # set args to the string "undef" if undefined
    $_ = "undef", next unless defined $_;
    if (ref $_) {
      if ($Perlilog::classes{ref($_)}) { # Is this a known object?
	$_='{'.$_->who.'}';    # Get the object's pretty ID
	next;
      }
      # force reference to string representation
      $_ .= '';
      s/'/\\'/g;
    }
    else {
      s/'/\\'/g;
      # terminate the string early with '...' if too long
      substr($_,$MaxStrLen) = '...'
	if $MaxStrLen and $MaxStrLen < length;
    }
    # 'quote' arg unless it looks like a number
    $_ = "'$_'" unless /^-?[\d.]+$/;
    # print high-end chars as 'M-<char>'
    s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
    # print remaining control chars as ^<char>
    s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
  }
  
  # append 'all', 'the', 'data' to the $sub string
  return ($#a != 0) ? '(' . join(', ', @a) . ')' : $a[0];
}

# Notes about the treestudy function:
# 1. It can be rerun on a tree. It should be rerun direcly before
#    the 'treehash' will be used and/or the tree integrity is
#    a must.
# 2. It can be run on any object in the tree.
# 3. For each object, the path to the object itself will be via
#    the father (and back).
# 4. If the functions returns (as opposed to puke()s), the tree's
#    integrity is assured (no loops, proper parent-child cross refs).
# 5. If the function returns, we're sure that object references can
#    be resolved with the name and %Perlilog::objects (regarding the
#    objects in the tree).

sub treestudy {
  my $self = shift;
  my %beenthere = ($self, 1);
  my @beenlist = ($self);
  my ($i, $next);

  # We now climb up to reach grandpa

  $i=$self;
  while (defined ($next=$i->get('parent'))) {
    puke($i->who." has a non-object registered as a parent\n")
      unless $self->isobject($next);

    # If we've already been where we were just about to climb,
    # we have a loop. Very bad.
    if ($beenthere{$next}) {
      my $err = "Corrupted object tree (parent references are cyclic)\n";
      $err.="The path crawled was as follows: ";
      $err.=join(" -> ",map {$self->safewho($_); } (@beenlist, $next));
      puke("$err\n");
    }
    # Fine. Mark this point, and go on climbing.
    $beenthere{$next}=1;
    push @beenlist, $next;
    $i=$next;
  }

  # We now make calls to two recursive functions, that do the
  # real job. $i is the reference to the grandpa now.

  $i->treecrawldown;
  $i->treecrawlup;
  return $i;
}

# treecrawlup: The children tell parents who their children are

sub treecrawldown {
  my $self = shift;
  my @children = $self -> get('children');
  my ($child, $reflection); # Does this sound poetic to you?
  my %treepath=();
  my $n;

  # We now enrich our %treepath with everything that the
  # children tell us that they have

  foreach $child (@children) {
    # We begin with making sure that $child is in fact
    # a recognized object
    puke($self->who." has a non-object member registered as a child\n")
      unless $self->isobject($child);

    # We check up that the child recognizes us as the
    # parent. Except for the feelings involved, this check
    # assures there are no loops.
    $reflection = $child->get('parent');
    unless ($reflection eq $self) { # Poetic again?
      my ($s, $c, $r) = map {$self->safewho($_);} ($self, $child, $reflection);
      my $err="Faulty parent-child relations: ";
      $err.="$c is marked as a child of $s, ";
      $err.="but $r is the parent of $c\n";
      puke($err);
    }

    # Now we make sure that we can use the object's name
    # instead of a reference to it.

    puke($self->safewho($child)." is badly registered in the global object hash\n")
      unless ($child eq $Perlilog::objects{$child->get('name')});

    # We're safe now... We fill %treepath so that the
    # keys are those objects that we can reach, values
    # are which object to go to reach them. We also
    # add the direct way to the child.
    
    foreach ($child->get('name'), $child->treecrawldown) { # RECURSIVE CALL!
      $treepath{$_} = $child;
    }
  }
  $self->set('treepath', \%treepath);
  return keys %treepath; # Tell our caller what we can reach.
}

# treecrawlup - The children ask the parents what is above them
sub treecrawlup {
  my $self = shift;
  my @children = $self->get('children');
  my $tpr = $self->get('treepath'); # Tree Path Reference
  my $papa = $self->get('parent');
  my @ups;
  my $child;

  # If this object has a parent (true for all except the root
  # object), we learn from it about objects we haven't seen yet.

  if (ref($papa)) {
    @ups = ($papa->get('name'), keys %{$papa->get('treepath')});

    # If we didn't know about the object, we add it and point
    # to papa. Note that papa has a pointer to us, so we add
    # ourselves here too (intentional).
    # I truly apologize for the "${$tpr}{$_}" thing. It really
    # means "$treehash{$_}", where %treehash is exactly the one
    # created in treecrawldown().
      
    foreach (@ups) {
      ${$tpr}{$_} = $papa unless ref(${$tpr}{$_});
    }
  }
  # Now we know about all objects in the tree and how to reach
  # them. Let our children enjoy the same fun.

  foreach $child (@children) {
    $child->treecrawlup;
  }
}

