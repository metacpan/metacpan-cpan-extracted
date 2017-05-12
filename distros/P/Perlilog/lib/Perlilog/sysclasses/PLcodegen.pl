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
  my $self = shift;
  return "CodeGen. Obj. \'".$self->get('name')."\'";
}

sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);
  $self -> registerobject($self -> get('beginend'))
    unless (defined $Perlilog::interface_rec);
	  
  return $self;
}

sub sustain {
  my $self = shift;
  $self->SUPER::sustain(@_);
  $self -> registerobject($self -> get('beginend'));
}

sub complete {
  my $self = shift;
  $self->SUPER::complete(@_);
  $self->set('header-comment',
	     "// This is a generated file. Do not edit -- changes will be lost\n".
	     "// Created by Perlilog v".
	     $Perlilog::VERSION." on ".$Perlilog::STARTTIME."\n".
	     "// Originating object: ".$self->who."\n\n");
}

sub IDvar {
  my ($junk, $ID)=@_;
  my ($obj, $var)=@{$Perlilog::VARS[$ID]};
  if (ref $obj) {
    return ($obj, $var) if wantarray;
    return $var;
  } else {
    return () if wantarray;
    return undef;
  }
}

sub varwho {
  my ($junk, $ID)=@_;
  my ($obj, $var)=@{$Perlilog::VARS[$ID]};
  return "(unknown var ID $ID)" unless (ref $obj);
  my $name=$obj->get('name');
  return "\'$var\' in module \'$name\'";
}

sub attach {
  #TODO: Save the comment both for immediate use and log it as well.

  # Get the details of the variables involved...
  # Note that it doesn't matter which object we are
  my ($junk, $ID1, $ID2, $comment) = @_;
  my ($obj1, $var1) = @{$Perlilog::VARS[$ID1]};
  my ($obj2, $var2) = @{$Perlilog::VARS[$ID2]};
  my $eq1 = $Perlilog::EQVARS[$ID1];
  my $eq2 = $Perlilog::EQVARS[$ID2];

  puke("attach() run with illegal ID1=$ID1\n")
    unless (ref $obj1);
  puke("attach() run with illegal ID2=$ID2\n")
    unless (ref $obj2);

  return 1 if ($eq1 eq $eq2); # Do nothing if they are already connected
  
  # Make a new equivalence list, and update all relevant entries.
  my @neweq = (@{$eq1}, @{$eq2});
  my $i;
  foreach $i (@neweq) {
    $Perlilog::EQVARS[$i] = \@neweq;
  }

  # Set magic callbacks to update (or check) the 'dim' property mutually.
  # If you read this and try to imitate, you'd better know a few things
  # about the scope in which the anonymous subroutine is run.
  # You've been warned.

  $obj1->addmagic(['vars', $var1, 'dim'],
		  sub { $obj2->const(['vars', $var2, 'dim'],
				     $obj1->get(['vars', $var1, 'dim'])); });
  $obj2->addmagic(['vars', $var2, 'dim'],
		  sub { $obj1->const(['vars', $var1, 'dim'],
				     $obj2->get(['vars', $var2, 'dim'])); });
  return 1;
}

sub samedim {
  my $self = shift;
  my $var1 = shift;
  puke("samedim called with unknown variable name ".$self->prettyval($var1).
       " on object ".$self->who."\n")
    unless (defined $self->get(['vars', $var1, 'ID']));
  my $i;
  foreach $i (@_) {
    # We get a local copy of $i for this BLOCK ($var2). 
    # We can't use $i, because by the time the callback is executed,
    # its value may have been altered.
    my $var2 = $i;
    puke("samedim called with unknown variable name ".$self->prettyval($var2).
	 " on object ".$self->who."\n")
      unless (defined $self->get(['vars', $var2, 'ID']));

    $self->addmagic(['vars', $var1, 'dim'],
		    sub { $self->const(['vars', $var2, 'dim'],
				       $self->get(['vars', $var1, 'dim'])); });
    $self->addmagic(['vars', $var2, 'dim'],
		    sub { $self->const(['vars', $var1, 'dim'],
				       $self->get(['vars', $var2, 'dim'])); });
  }
}

sub getID {
  my $self = shift;
  my @vars = @_;
  my $ID;
  foreach (@vars) {
    $ID = $self->get(['vars', $_, 'ID']);
    puke("getID called with unknown variable name\n")
      unless (defined $ID);
    $_=$ID;
  }
  return @vars if wantarray;
  return $vars[0];
}

sub getport {
  my $self = shift;
  my $name = shift;
  my $port = $self->get(['user_port_names', $name]);

  puke("Failed to find port \'$name\' in ".$self->who."\n")
    unless (ref $port);
  return $port;
}


sub labelID {
  my ($self, $port) = @_;
  puke("labelID called with non-object argument\n")
    unless ($self->isobject($port));
  my $obj = $port->get('parent');
  puke("labelID called with a port with no parent (is it really a port?)\n")
    unless ($self->isobject($obj));
  my %h=$port->get('labels');
  my ($val, $name);
  foreach (sort keys %h) {
    $name = $h{$_};
    if ($name =~ /^\d+$/) { # $name is an ID?
      wrong("Unknown variable ID ".$self->prettyval($name).
	    " given as \'$_\' in 'labels' property of ".
	    $port->who()."\n")
	unless ($self->IDvar($name));
      next; # It's in ID format. No more hassle.
    }
    $val = $obj->get(['vars', $name, 'ID']);
    if (defined $val) {
      $h{$_} = $val;
    } else {
      wrong("Undefined variable ".$self->prettyval($name).
	    " given as \'$_\' in 'labels' property of ".$port->who()."\n");
      delete $h{$_};
    }
  }
  return %h;
}

sub interface {
  my $self = shift;
  my $obj = &Perlilog::interface(@_);
  $obj->setparent($self) if ($self->isobject($obj));
  return $obj;
}

sub getreset {
  my $self = shift;
  my $global = $self->globalobj();
  my $type = $global->get('reset_type');
  my $ID = $global->get('reset_ID');
  return ($ID, $type) if wantarray;
  return $ID;
}

sub wheretorec {
  my $self = shift;

  # First we check up if we've already answered this question.

  my $cached = $self->get('perlilog-whereto-answer');
  return $cached if defined($cached);

  # Now we ask ourselves for recommendations. "self" is always
  # assumed as a last (possibly only) resort, so we add it.

  my @targets = $self->codetargets;

  @targets = ((grep { ref } @targets), $self);

  # A yes/no lookup hash for those objects that we are not allowed
  # to return to (avoiding infinite recursion)
  my %blacklisted = map {($_, 1)} @_;

  my $answer = undef;

  foreach my $target (@targets) {
    next if ($blacklisted{$target});
    next if ($target->get('static')); # Static objects are no targets
    if ($target == $self) { # $self was a last resort, remember?
      $answer = $target;
      last; # Perl novices: "last" means that we're skipping the rest...
    }
    # We want someone else to hold our code. But maybe this "someone else"
    # has a better idea? Let's ask. Note that when looking for that better
    # idea, $self has been added to the black list, so we won't loop around
    # forever.
    
    my $gossip = $target->wheretorec(@_, $self);
    if (ref $gossip) { # Did we get a solid answer?
      $answer = $gossip;
      last;
    }
  }
  # Remember our answer if it's worth anything.
  $self->const('perlilog-whereto-answer', $answer)
    if (ref $answer);
  return $answer;
}

sub whereto {
  my $self = shift;
  my $answer = $self->wheretorec();

  wrong("Failed to find an object to put the Verilog code created by ".
	$self->who." (this is strange)\n")
    unless (ref $answer);

  return $answer;
}

sub codetargets { 
  return (); # By default, no other objects to divert the code to
}

# Empty methods (to avoid unknown method error)
sub sanity {}
sub generate {}
sub instantiate {}
sub headers {}
sub epilogue {}
sub files {}
