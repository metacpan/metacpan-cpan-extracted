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

${__PACKAGE__.'::errorcrawl'}='system';
sub who {
  return "The Global Object";
}

sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);

  my $name = $self->get('name');
  puke("The \'global\' class can generate an object only with the name \'globalobject\'".
       " and not \'$name\'\n") unless ($name eq 'globalobject');

  return $self;
}  

sub complete {
  my $self = shift;
  my $dir=$self->get('filesdir');
  blow("The \'filesdir\' property was not set for ".$self->who()."\n")
    unless ($dir);
  mkdir $dir, 0777 unless -e $dir;
  opendir(DIR,$dir) || blow("Failed to open $dir as a directory\n");
  my @A=readdir(DIR);
  closedir(DIR);
  foreach (grep /[^.]/, @A) {
    unlink "$dir/$_";
  }
}

# NOTE: execute does not allow extra methods or objects to be
# added once started.

sub execute {
  my $global = shift; # We're the global object, aren't we?
  puke("The execute method was not run from the global object\n")
    unless ($global == $global->globalobj());
  my $system = $global -> get('system');
  my @methods = $system -> get('methods');
  my @objects = ($global -> get('beginobjects'),
		 $global -> get('objects'),
		 $global -> get('endobjects'));
  my ($method, $object);

  # Note that the global object sneaks in first here
  @methods = grep { defined } @methods;
  @objects = grep { defined } ($global, @objects);

  foreach $method (@methods) {
    foreach $object (@objects) {
      $object->$method();
    }
    last if ($Perlilog::wrongflag);
  }
}

sub constreset {
  my ($self, $ID, $type) = @_;
  wrong ("Reset of unknown type \'$type\'")
    unless grep {$type eq $_} qw(sync negsync async negasync);
  wrong ("Unproper ID \'$ID\' given for reset signal\n")
    unless (defined $Perlilog::VARS[$ID]);
  # $self is global object!
  $self->const('reset_type', $type);
  $self->const('reset_ID', $ID);
}

sub instantiate {
  my $self = shift;
  $self->SUPER::instantiate(@_);
  my ($i, $ID, $drive, $obj, $var, $type, $parent);
  my ($from, $start, $to, $next, $f, $t, $toname);
  my ($fv, $tv, $dim, $nv, $nID, $tmp, $wf, $hashref);

  my %eqvars;
  my @eq;

  # Type conversion hashes
  my %toin=('input' => 'input',
	    'wire'  => 'input',
	    'inout' => 'inout',
	    'output'=> 'inout');
  my %toout=('output' => 'output',
	     'reg'    => 'outreg',
	     'outreg' => 'outreg',
	     'wire'   => 'output',
	     'inout'  => 'inout',
	     'input'  => 'inout');

  # We begin with triggering off tree studies.
  foreach $i (values %Perlilog::objects) {
    next unless (defined $i->get('inshash')); # Only Verilog objects...
    next if (ref $i->get('parent')); # Only "root" objects...
    $i->treestudy;
  }

  # Now we collapse the EQVARS list to the minimal number
  # of distinct lists. Note that the hash keys are the
  # string representation of the reference, and only
  # functions as a unique representation of the reference.
  # The value points to the index in EQVARS, which makes
  # is possible to retrieve the EQVARS list again.
  # We loop in reverse order, so that the value will represent
  # the variable in the cluster that was defined earliest.

  my $imax = $#Perlilog::EQVARS;
  for ($i=$imax; $i>=0; $i--) {
    next unless (ref $Perlilog::EQVARS[$i]);
    $eqvars{$Perlilog::EQVARS[$i]}=$i;
  }

  my @in;
  my @out;
  my @zout;
  my %where;

  # This little subroutine will help up make nice error messages.
  # Note that it runs in the current scope.

  my $s = sub {
    my $r = "These are the variables involved:\n";
    if (@out) {
      $r.="Driving variables:\n";
      foreach (@out)
	{ $r.="  Variable ".$self->varwho($_)."\n"; }
    }
    if (@zout) {
      $r.="Weakly driving variables:\n";
      foreach (@zout)
	{ $r.="  Variable ".$self->varwho($_)."\n"; }
    }
    if (@in) {
      $r.="Driven variables:\n";
      foreach (@in)
	{ $r.="  Variable ".$self->varwho($_)."\n"; }
    }
    return $r;
  };

  # This is the main loop. Each $i is a variable cluster that
  # needs to be interconnected.

  foreach $i (sort values %eqvars) {

    my @ids=@{$Perlilog::EQVARS[$i]}; # Get a local copy. The original may change
    next unless ($#ids>0); # No hassle with unconnected variables

    @in=(); @out=(); @zout=();
    %where=();

    # We now distribute the variables to the respective lists. We
    # also set up the %where hash that tells us the names of the
    # variables in the objects, if they exist. Again, the keys
    # are not real references but string representations, but it's
    # good enough for looking up.
  IDLOOP:
    foreach $ID (sort @ids) {
      ($obj, $var) = @{$Perlilog::VARS[$ID]};
      $drive = $obj->get(['vars', $var, 'drive']);

      # If $where{$obj} is already defined, it means we have two
      # equal variables in the same module. This is handled quite
      # gracefully as long as they don't happen to be both zouts.
      # For the case when they are both zouts, by make a nonstrength-
      # reducing transistor connecting, as would an inout connection,
      # and don't deal with the new variable any more.

      if (defined $where{$obj}) {
	if ($drive eq 'zout') {
	  if ($obj->get(['vars', $where{$obj}, 'drive']) eq 'zout') {
	    # Horrors! Two zouts in the same module!
	    my $tranins = $obj->suggestins('PL_tran');
	    $obj->addins($tranins, 'detached');
	    wrong("Failed to handle bidirectional variable \'".$var."\' in ".$obj->who.
		  " because the Verilog is static\n")
	      unless ($obj->append("  tran $tranins ($var, ".$where{$obj}.");\n"));
	    next IDLOOP; # Don't register this variable. It's already handled
	  } else {
	    # The existing variable wasn't a zout, but we'll set $where{$obj} to this
	    # variable, so we won't miss a zout clash in the future...
	    $where{$obj} = $var;
	  }
	}
	# Note that we do nothing if this is not a zout case. We let the previously
	# registered variable persist.
      } else {
	$where{$obj} = $var; # This is just the normal case. A first-timer
      }
      
      # We put the variable in the right list, according to "drive"

      if ($drive eq 'in') { push @in, $ID; }
      elsif ($drive eq 'out') { push @out, $ID; }
      elsif ($drive eq 'zout') { push @zout, $ID; }
      elsif ($drive eq 'via') {
	wrong("Variable ".$self->varwho($ID).
	      " was of drive-type \'via\' (System error?)\n");
      } else {
	wrong("Variable ".$self->varwho($ID).
	      " is of unknown drive-type \'$drive\'\n");
      }
    }

    # Now we complain if things aren't so good...
    if (($#out<0) && ($#zout<0)) {
      wrong("No driving variable in cluster\n".&$s);
    } elsif ($#out>0) {
      wrong("More than one exclusively driving variable in cluster\n".&$s);
    } elsif (($#out==0) && ($#zout>=0)) {
      wrong("Exclusiveness of driving variable was offended by weakly driven variables\n".&$s);
    }

    # Now we draw lines from every driving variable to every
    # driven variable.

  FLOOP: # The "from" loop -- driving variables
    foreach $f ((sort @out), (sort @zout)) {
      ($start, $fv) = @{$Perlilog::VARS[$f]};
    TLOOP: # The "to" loop -- driven variables
      foreach $t ((sort @in), (sort @zout)) {
	next TLOOP if ($t == $f);
	($to, $tv) = @{$Perlilog::VARS[$t]};
	$from = $start;
	$toname = $to->get('name');

	# If we happen to start and end at the same object,
	# why hassle? Just make an internal assignment. But
	# alas, the current object may not allow its Verilog
	# content to change, in which case append() fails.
	# In that case we simply go on, which will cause
	# a walk-up to the parent and back (good).
	next TLOOP
	  if (($start == $to) &&
	      ($start->append("  assign $tv = $fv;\n")));

	# OK, now we come to SLOOP: The walking around loop.
	# We travel our way to $to. treestudy() earlier
	# promised to take us there, so we trust it and
	# run the loop until we reach the place.

      SLOOP:
	while (1) {
	  # We fetch the next object to walk to
	  $next = ${$from->get('treepath')}{$toname};
	  unless (ref $next) {
	    wrong("No path found between variables ".$self->varwho($f).
		  " and ".$self->varwho($t)."\n");
	    next TLOOP;
	  }
	  
	  # Now the world splits in two: Either we went from child
	  # to parent, or the opposite way. Anyhow, this takes
	  # opposite treatment, since we always create the inputs and
	  # outputs on the child, whereas the parent gets a "wire" at
	  # most.

	  $parent = $next->get('parent');
	  if (defined ($parent) && ($parent == $from)) {

	    # This is the parent to child walk part:

	    # Get the variable name an $next's object. If we happen to
	    # have reached our destination, take $tv. This is because
	    # if there are two input variables in the same object,
	    # only one will be represented in $where{$next}

	    $nv = ($next==$to) ? $tv : $where{$next};

	    # If $nv is not defined, it means that object currently
	    # has no access to the variable. We create a via.
	    unless (defined $nv) {

	      # Now we want to set the name nicely. If the current object
	      # has the 'viasource' (list) property set, we scan through the objects
	      # from which we may borrow the name. Only non-via variables
	      # may donate names.
	      
	    VIALOOP1:
	      foreach my $source ($next->get('viasource')) {
		if ((defined $where{$source}) &&
		    ($source->get(['vars',$where{$source},'drive']) ne 'via')) {
		  $nv = $next->suggestvar($where{$source}); # This is a good source!
		  last VIALOOP1; # No more search!
		}
	      }

	      $nv = $next->suggestvar($fv.'_via') # Make _via
		unless (defined $nv);

	      $nID = $next->addvar($nv, 'wire', 'via');
	      $next->attach($f, $nID); # This will also get the 'dim' property right
	      $where{$next}=$nv; # Register it, so we won't do this again
	    }
	    
	    # Now we change the variable's type if needed.
	    $tmp = $toin{$next->get(['vars',$nv,'type'])};
	    blow("Expected a variable convertable to input/inout, got ".
		 "variable \'$nv\' of type \'".$next->get(['vars',$nv,'type'])."\' on ".
		 $next->who."\n")
	      unless (defined $tmp);

	    # We can't change variable types of static objects. Be sure.
	    
	    if ($next->get('static')) {
	      wrong("Attempted to change the variable type of $nv to $tmp in ".
		    $next->who()." but it is a static Verilog object\n") 
		unless ($next->get(['vars',$nv,'type']) eq $tmp)
	      } else {
		$next->set(['vars',$nv,'type'], $tmp);
	      }

	    # And finally, we register the connection in 'inshash'. We are not
	    # worried about if the entry is already set, because it will always
	    # be set to the same value, $where{$from}

	    $hashref = $next->get('inshash');
	    ${$hashref}{$nv}=$where{$from};
	
	  } else {

	    # This is the child to parent walk part: (quite similar)

	    # Get the variable name an $next's object. If we happen to
	    # have reached our destination, take $tv. This is because
	    # if there are two input variables in the same object,
	    # only one will be represented in $where{$next}

	    $nv = ($next==$to) ? $tv : $where{$next};

	    # If $nv is not defined, it means that object currently
	    # has no access to the variable. We create a via.
	    unless (defined $nv) {

	      # Now we want to set the name nicely. If the current object
	      # has the 'viasource' (list) property set, we scan through the objects
	      # from which we may borrow the name. Only non-via variables
	      # may donate names.
	    
	    VIALOOP2:
	      foreach my $source ($next->get('viasource')) {
		if ((defined $where{$source}) &&
		    ($source->get(['vars',$where{$source},'drive']) ne 'via')) {
		  $nv = $next->suggestvar($where{$source}); # This is a good source!
		  last VIALOOP2; # No more search!
		}
	      }

	      $nv = $next->suggestvar($fv.'_via') # Make _via
		unless (defined $nv);
	      
	      $nID = $next->addvar($nv, 'wire', 'via');
	      $next->attach($f, $nID); # This will also get the 'dim' property right
	      $where{$next}=$nv; # Register it, so we won't do this again
	    }
	    
	    # Now we change the variable's type if needed.
	    $wf = $where{$from}; # We use it a lot here, so...
	    $tmp = $toout{$from->get(['vars',$wf,'type'])};
	    blow("Expected a variable convertable to output/inout, got ".
		 "variable \'$wf\' of type \'".$from->get(['vars',$wf,'type'])."\' on ".
		 $from->who."\n")
	      unless (defined $tmp);

	    # We can't change variable types of static objects. Be sure.

	    if ($from->get('static')) {
	      wrong("Attempted to change the variable type of $wf to $tmp in ".
		    $from->who()." but it is a static Verilog object\n") 
		unless ($from->get(['vars',$wf,'type']) eq $tmp)
	      } else {
		$from->set(['vars',$wf,'type'], $tmp);
	      }

	    # And finally, we register the connection in 'inshash'. If the entry
	    # is already initialized, then we've already connected that variable.
	    # We use an assign instead. Note that this won't work with zouts.
	    $hashref = $from->get('inshash');
	    $tmp = ${$hashref}{$wf};
            if ((defined $tmp) && ($tmp ne $nv)) {
	      $next->append("  assign $nv = $tmp;\n");
	    } else {
	      ${$hashref}{$wf}=$nv;
            }
	  }

	  # Now it's time to see if we're finished. That is, have we
	  # reached our destination?

	  last SLOOP if ($next == $to);

	  $from = $next; # This is the actual walking
	}
      }
    }
  }
}
