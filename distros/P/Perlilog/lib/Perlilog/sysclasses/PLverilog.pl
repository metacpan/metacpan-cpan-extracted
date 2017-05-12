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
sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);
  $self -> const('inshash', {});

  return $self;
}  

sub who {
  my $self = shift;
  return "Verilog Obj. \'".$self->get('name')."\'";
}

sub complete {
  my $self = shift;
  $self->SUPER::complete(@_);
  my $fname= $self->get('vfile');
  my $g = $self->globalobj;
  unless (defined $fname) {
    my $dir=$self->globalobj->get('filesdir');
    $fname=$dir.'/'.$self->get('name').'.v';
    $self->const('vfile',$fname);
  }
  $g ->ppush('vfiles', $fname);
}

sub epilogue {
  my $self = shift;
  $self->SUPER::epilogue(@_);

  my $v = $self->get('verilog');
  $self->ontop('`timescale 1ns / 10ps',"\n")
    unless ((defined $v) && ($v =~ /[\t\s]*\`timescale/));
}

sub files {
  my $self = shift;
  $self->SUPER::files(@_);
  return if ($self->get('perlilog-no-file'));

  my $twin = $self->get('perlilog-equivalent');
  if ((defined $twin) && ($self->isobject($twin))) {
    # All is fine if the 'verilog's stringwise EQUAL, no less
    return if ($twin->get('verilog') eq $self->get('verilog'));

    # Or yell... We don't stop execution, because we want to generate files
    # for comparison.

    fishy("The Verilog produced by ".$self->who." is not equal to ".
	  $twin->who.", as should be due to the \'equivalent\' declaration of ".
	  "the former. Compare files ".$self->get('vfile')." and ".
	  $twin->get('vfile')."!\nNOTE: There Verilog code hereby produced should be ".
	  "considered unreliable\n");
  }

  my $comment = $self->get('header-comment') || "";

  my $fname= $self->get('vfile');
  my $verilog = $comment."\n".$self->get('verilog');

  # Now remove double line breaks (with possible associated white spaces)
  $verilog =~ s/([\s\t]*\n){3,}/\n\n/g; 

  open (VFILE, ">$fname")
    || blow("Failed to open Verilog output file $fname\n");
  print VFILE $verilog;
  close VFILE;

  my $g = $self->globalobj();
  $g->ppush('verilogfiles', $fname);
  $g->ppush('verilogfilesobjects', $self);
}

sub addvar {
  my ($self, $var, $type, $drive, $dim) = @_;
  my $lvar = lc($var);
  my @vars = $self->get('varslist');
  foreach (@vars) {
    blow("Variable \'$var\' assigned to object ".$self->who." when a variable \'$_\' is already defined\n")
      if (lc($_) eq $lvar); 
  }
  my $ID = undef;
  # If $type isn't defined, this is only a name reservation
  if (defined $type) {
    $ID = $self->makeID($var);
    $self->set(['vars', $var, 'type'],$type);
    $self->const(['vars', $var, 'dim'],$dim) if (defined $dim);
    $self->set(['vars', $var, 'drive'],$drive) if (defined $drive);
    $self->const(['vars', $var, 'ID'], $ID);
  }
  $self->ppush('varslist', $var);
  return $ID;
}

sub suggestvar {
  my ($self, $name) = @_;
  my $sug = $name;
  my ($bulk, $num) = ($name =~ /^(.*)_(\d+)$/);
  my @vars = $self->get('varslist');
  my %v;

  foreach (@vars) { $v{lc($_)}=1; } # Store lowercased names
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

sub namevar {
  my ($self, $var, $type, $drive, $dim) = @_;
  my $name = $self->suggestvar($var);
  my $ID = $self->addvar($name, $type, $drive, $dim);
  return $name unless wantarray;
  return ($name, $ID);
}

sub copyvar {
  my ($self, $target) = @_;
  my @cluster = @{$Perlilog::EQVARS[$target]};
  my $i;
  my ($obj, $ID, $var);

  # TODO: When all works fine, add this shortcut (Look if
  # the variable happens to be under our nose first). 

  #   ($obj, $var) = @{$Perlilog::VARS[$target]};
  #   if ($obj == $self) {
  #    return $var unless wantarray;
  #     return ($var, $target);
  #   }


  # Now we search all the members is the cluster to see
  # is one of them happen to belong to our object.

  foreach $i (@cluster) {
    ($obj, $var) = @{$Perlilog::VARS[$i]};
    if ($obj == $self) {
      $ID = $i;
      last;
    }
  }

  # If the variable doesn't appear, we make one, and attach
  # it. The variable name we try is the last variable name
  # we saw while searching. This will give a name that may
  # make sense.

  unless (defined $ID) {
    ($var, $ID) = $self->namevar($var, 'wire', 'in');
    $self->attach($ID, $target);
  }

  return $var unless wantarray;
  return ($var, $ID);
}

sub makeID {
  my ($self, $var)=@_;
  push @Perlilog::VARS, [$self, $var];
  my $index = $#Perlilog::VARS;
  $Perlilog::EQVARS[$index]=[$index];
  return $index;
}


sub addins {
  my ($self, $ins, $detached) = @_;

  $self->addvar($ins); # Reserve the name

  return $ins;
}

sub suggestins {
  my ($self, $name) = @_;
  $name=$self->get('name').'_ins'
    unless (defined $name);

  return $self->suggestvar($name);
}

sub equivalent {
  my ($self, $twin) = @_;

  puke("Target is not an object\n")
    unless ($self->isobject($twin));

  puke($twin->who." can't be used as equivalent because it's declared as ".
       "equivalent to another object\n")
    if (defined $twin->get('perlilog-equivalent'));

  puke($self->who." can't be declared as equivalent to another object, because ".
       $self->get('perlilog-equivalent-lock')->who." depends on it\n")
    if (defined $self->get('perlilog-equivalent-lock'));

  $self->const('perlilog-equivalent', $twin);
  $twin->set('perlilog-equivalent-lock', $self);

  return 1;
}

sub bitrange {
  my $self = shift;
  my $ID = shift;
  my ($obj, $var) = $self->IDvar($ID);

  puke("Faulty ID ".$self->prettyval($ID)." given\n")
    unless ($self->isobject($obj));
  
  my $dim = $obj->get(['vars', $var, 'dim']);
  
  wrong("The dimension was not set for variable \'$var\' in ".
	$obj->who()."\n") unless (defined $dim);

  return (0,0) if (length($dim)==0);
  
  my ($x,$y) = $dim =~ /^\[(\d+):(\d+)\]$/;

  wrong("Faulty dimension ".$self->prettyval($dim)." for variable \'$var\' in ".
	$obj->who()."\n") unless (defined $y);

  return ($x, $y);
}

sub ontop {
  my $self = shift;
  return 0 if ($self->get('static'));
  my @code=@_;
  chomp @code;
  my $code = join("\n", @code)."\n";
  my $verilog = $self->get('verilog');
  $verilog = '' unless (defined $verilog);
  $self->set('verilog', $code.$verilog);
  return 1; # Succeeded.
}

sub append {
  my $self = shift;
  return 0 if ($self->get('static'));
  my @code=@_;
  chomp @code;
  my $code = join("\n", @code)."\n";
  my $verilog = $self->get('verilog');
  $verilog = '' unless (defined $verilog);
  $self->set('verilog',$verilog.$code);
  return 1; # Succeeded.
}

sub clocked {
  my ($self, $code, $clk, @vars) = @_;
  my ($ID, $type) = $self->getreset();
  my $reset = $self->copyvar($ID);
  my $neg = $type =~ /^neg/i;
  $type =~ s/^neg//i; # Chop of negation if it is there
  my $async = ($type eq 'async');
  my $ifreset = $neg ? "!$reset" : $reset;
  my $edge = $neg ? 'negedge' : 'posedge';
  my $edges = $async ? "posedge $clk or $edge $reset" : "posedge $clk";
  my $zeros='';
  foreach (@vars) {
    $zeros.="      $_ <= #1 0;\n";
  }
  chomp $zeros;
  chomp $code;
  my $always = <<END;
  always \@($edges)
    if ($ifreset)
    begin
$zeros
    end
    else
    begin
$code
    end
END
  return $always;
}

sub headers {
  my $self = shift;
  $self->SUPER::headers(@_);
  return 0 if ($self->get('static'));

  # If we have an equivalent object, we steal its name. This is necessary,
  # so that the Verilog will be perfectly equivalent, and thus no warning
  # is generated.

  my $twin = $self->get('perlilog-equivalent');
  my $name;
  if ((defined $twin) && ($self->isobject($twin))) {
    $name = $twin->get('name');
  } else {
    $name = $self->get('name');
  }

  my @vars=$self->get('varslist');

  # We now check up whether a Verilog module should be created
  # at all: If it doesn't have any variables and it isn't static
  # then the headers will be empty anyhow, which means that the
  # module does nothing relevant. That means no Verilog code,
  # and no Verilog file. (The Verilog code generated may be
  # hosted by other modules).

  return if ($self->get('perlilog-no-file'));

  my @inputs = ();
  my @outputs = ();
  my @inouts = ();
  my @headvars = ();
  my @wires = ();
  my @regs = ();
  my ($v, $type, $i);

  # We now scan through the variable list and distribute
  # them by their type
  foreach $v (@vars) {
    $type=$self->get(['vars', $v, 'type']);
    next unless (defined $type);
    # This block works like a "case" or "switch"
    if ($type eq 'input') {
      push @inputs, $v;
      push @headvars, $v;
    }
    elsif ($type eq 'output') {
      push @outputs, $v;
      push @headvars, $v;
    }
    elsif ($type eq 'inout') {
      push @inouts, $v;
      push @headvars, $v;
    }
    elsif ($type eq 'wire') {
      push @wires, $v;
    }
    elsif ($type eq 'reg') {
      push @regs, $v;
      }
    elsif ($type eq 'outreg') {
      push @outputs, $v;
      push @regs, $v;
      push @headvars, $v;
    } else {
      wrong("Unknown variable type ".$self->prettyval($type).
	    " of variable \'$v\' in Verilog module object \'$name\'\n");
    }
  }

  # Now we generate the module's header
  my $decl = "module $name";
  my $hvars=join(', ',@headvars);
  $decl.="($hvars)" if $hvars;
  $decl = $self->linebreak($decl.';', '  ');

  $decl.="\n\n";
  
  # And on to variable declarations. We define a local subroutine that does the
  # dirty job. This is good because it will have access to this scope's variables
  
  my $d = sub {
    my $type = shift;
    my ($var, $dim);
    foreach $var (@_) {
      $dim = $self->get(['vars', $var, 'dim']);
      wrong("No dimension set for variable \'$var\' in Verilog module object \'$name\'\n")
	unless (defined $dim);
      # Note: Right now we don't support arrays.
	$decl.="  $type $dim $var;\n";
    }
  };
  
  # We now use the subroutine to generate the relevant Verilog code
  &$d('input', @inputs);
  &$d('output', @outputs);
  &$d('inout', @inouts);
  &$d('reg', @regs);
  &$d('wire', @wires);
  
  $self->ontop($decl."\n");
  $self->append("\nendmodule");
}

sub instantiate {
  my $self = shift;
  $self->SUPER::instantiate(@_);

  my @vars = $self->get('varslist');

  # If the object has no variables (and thus no inputs or outputs)
  # and is not going to instantiate anything, no need to make a
  # Verilog file of it, nor instantiate it.

  if (($#vars==-1) && (not $self->get('static')) &&
      (not ($self->get('children') ) )) {
    $self->const('perlilog-no-file',1);
    return;
  }

  my $papa = $self->get('parent');
  return unless (ref $papa);

  # Here we check for the 'equivalent' property. If it's an object, we copy the
  # name of our twin sybling. If not, we const-assign "0" to this property, so
  # noone else tries to change it later.

  my $twin = $self->get('perlilog-equivalent');
  my $name;
  if ((defined $twin) && ($self->isobject($twin))) {
    $name = $twin->get('name');
  } else {
    $self->const('perlilog-equivalent',0) unless (defined $twin); # Block the property
    $name = $self->get('name');
  }

  my $h = $self->get('inshash');
  my $extra = $self->get('insparams');
  $extra = '' unless (defined $extra);
  my $insname = $papa->suggestins($name.'_ins');
  $papa->addins($insname);
  my ($v, $pv);
  my @i = ();

  my $ins = "  $name $extra $insname(";
  
  foreach $v (@vars) { # Scan variables for those who reach the outer world
    $pv = ${$h}{$v};
    next unless (defined $pv);
    push @i, ".$v($pv)";
  }

  $ins .= join(', ', @i).");";
  $ins = $self->linebreak($ins, '    ');

  wrong("Failed to instantiate ".$self->who()." since parent is static Verilog\n")
    unless ($papa->append("\n".$ins."\n\n"));
}
