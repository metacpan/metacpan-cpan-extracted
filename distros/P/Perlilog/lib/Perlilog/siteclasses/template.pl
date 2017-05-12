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

# Template class
${__PACKAGE__.'::errorcrawl'}='system';
sub who {
  my $self = shift;
  return "Template Verilog Obj. \'".$self->get('name')."\'";
}

sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);

  my $file = $self->get('tfile');

  wrong("The \'tfile\' property was not set on ".$self->who."\n")
    unless (defined $file);
  
  open (FILE, $file) || blow("Failed to open template file $file for ".
			     $self->who."\n");

  my @keywords = qw(reg wire iwire input output inout parameter integer real time);
  my $line;
  my $verilog = '';
  my $extrahead = '';
  my $prehead = '';
  my ($deftype, $dim, $names, $w);
  my ($portname, $portclass, $binds);
  my @ports;
  my @vars;
  my %vhash = ();
  my %chash = ();
  my $modulecount = 0;
  my $c = 0; # A counter for preserving the variable's order

  # We choose a namespace name for the inline Perls
  my $pack = $self->get('name').'_inlineperl'; 
  
  while (!eof(FILE)) {
    $line = <FILE>; chomp $line;
    
    # If we have "module", flush until semicolon
    if ($line =~ /^[\t\s]*module/) {
      $modulecount++;
      if ($modulecount > 1) {
	wrong("More than one module in $file.\n");
      }
      wrong("Variables were declared before module header of line $. in $file\n")
	if (keys %vhash);
      
      $prehead = $verilog;
      $verilog = '';
      
      while (not (eof(FILE) || ($line =~ /;/))) {
	$line = <FILE>;
      }
      next;
    }
    
    # If we have "task" or "function", flush until the end of it
    if ($line =~ /^[\t\s]*(task|function)/) {
      $verilog .= $line."\n";
      while (!eof(FILE)) {
	$line = <FILE>; chomp $line;
	$verilog .= $line."\n";
	last if ($line =~ /^[\t\s]*(endtask|endfunction)/);
      }
      next;
    }

    # Now we take care of perl in-lines
    if ($line =~ /^[\t\s]*perl(\w*)/) {
      wrong("Strange expression \'perl$1\' in $file, line $.\n")
	if ((length($1)>0) && ($1 ne 'onload'));
      my $toset = ($1 eq 'onload') ? 'early' : 'late';
      my $perl = '';
      my $startline = $. + 1;
      while (!eof(FILE)) {
	$line = <FILE>; chomp $line;
	last if ($line =~ /^[\t\s]*(endperl)/);
	$perl .= $line."\n";
      }
      $perl = "no strict;\npackage $pack;\n# line $startline \"$file\"\n".$perl;
      $self->ppush("perl-inline-$toset", $perl);
      eval("\$".$pack.'::errorcrawl = "halt";'); # We don't want stack dumps.
      next;
    }
    
    next if ($line =~ /^[\t\s]*endmodule/); # Skip "endmodule"
    next if ($line =~ /^\`timescale/); # Skip timescale
    
    # We begin with detecting a port declaration
    ($portname, $portclass, $binds) =
      ($line =~ /^[\s\t]*port[\s\t]+(\w+)[\s\t]+(\w+)[\s\t]+([^;]*?)(\/\/|[;]|$)/);
    
    if (defined $portname) {
      unless (Perlilog::definedclass($portclass)) {
	wrong("Attempt to use undefined port class \'$portclass\' in $file, line $.\n");
      }

      # If the line didn't end with ";", go on searching.
      while (not (eof(FILE) || ($line =~ /;/))) {
	$line = <FILE>; chomp $line;
	$line =~ /^(.*?)(\/\/|[;]|$)/;
	$binds.=$1;
      }
      $binds =~ s/[\s\t]//g;
      push @ports, [$portname, $portclass, $binds];
      next;
    } elsif ($line =~ /^[\s\t]*port/) {
      wrong("Bad port declaration syntax in $file, line $.\n");
    }
 
    # Now detect variable declarations
    $dim = undef;
    ($deftype, $dim, $names) =
      ($line =~ /^[\s\t]*([a-zA-Z]+)[\s\t]*(\[\s*\d+\s*:\s*\d+\s*\]|\[\s*:\s*\])[\s\t]+([,\s\tA-Za-z0-9_]*)(\/\/|[;]|$)/);
    ($deftype, $names) =
      ($line =~ /^[\s\t]*([a-zA-Z]+)[\s\t]+([,\s\tA-Za-z0-9_]*)(\/\/|[;]|$)/)
         unless (defined $deftype);
       
    # Now we look for special formats, where we want to have the variable name
    # registered, but we can't handle it further. Namely, when the variable
    # is a matrix, or when it's initialized.
    
    unless (defined $deftype) {
      ($deftype, $names) =
	($line =~ /^[\s\t]*([a-zA-Z]+)[\s\t]*\[.*\][\s\t]*([,\s\tA-Za-z0-9_]*?)(\/\/|[;]|$)/);
      if (defined $deftype) {
	if (grep {$deftype eq $_} qw(input output inout)) {
	  undef $deftype;
	} else {
          $dim = '[]';
	}
      }
    }
    unless (defined $deftype) {
      ($deftype, $names) =
	($line =~ /^[\s\t]*([a-zA-Z]+)[\s\t]+([,\s\tA-Za-z0-9_]*)[\s\t]*[=].*/);
      $dim = '[]' if (defined $deftype)
    }
    
    unless ((defined $deftype) &&
	    (grep {$deftype eq $_} @keywords)) {
      $verilog .= $line."\n";
      ($w) = ($line =~ /^[\s\t]*([a-zA-Z]+)[\s\t]+/);
      fishy("This line in $file, line $. was probably not handled properly:\n$line\n")
	if ((defined $w) && 
	    (grep {$w eq $_} @keywords));
      next; # Next line if we put this one in $verilog...
    }    
    
    # Note that if we got here, then we have some "legal" variable
    # declaration to play with.

    # If the line didn't end with ";", go on searching.
    while (not (eof(FILE) || ($line =~ /;/))) {
      $line = <FILE>; chomp $line;
      $line =~ /^(.*?)(\/\/|[;]|$)/;
      $names.=$1;
    }
 
    $dim = '' unless (defined $dim); # Single-bit variable
    $dim =~ s/\s//g;
    undef $dim if ($dim eq '[:]');   # Special "unknown width" format.
    $names =~ s/[;\s\t]//g;
    
    foreach my $n (split(',', $names)) {
      $c++;

      if ((defined $dim) && ($dim eq '[]')) { # Variables with troublesome dimensions
	$vhash{$n} = [$n]; # Only register name
	$chash{$n} = $c unless (defined $chash{$n});
	$extrahead .= $line."\n";
      }
      elsif (($deftype eq 'iwire') || ($deftype eq 'input')) {
	$vhash{$n} = [$n, 'wire', 'in', $dim];
	$chash{$n} = $c unless (defined $chash{$n});
      }
      elsif (($deftype eq 'wire') || ($deftype eq 'output')) {
	unless (defined $vhash{$n}) {  # Respect if it was defined as a register
	  $vhash{$n} = [$n, 'wire', 'out', $dim];
	  $chash{$n} = $c;
	}
      }
      elsif ($deftype eq 'inout') {
	$vhash{$n} = [$n, 'wire', 'zout', $dim];
	$chash{$n} = $c unless (defined $chash{$n});

      }
      elsif ($deftype eq 'reg') {
	$vhash{$n} = [$n, 'reg', 'out', $dim];
	$chash{$n} = $c unless (defined $chash{$n});
      }
      else {
	$vhash{$n} = [$n]; # Only register name
	$chash{$n} = $c unless (defined $chash{$n});
	$extrahead .= $line."\n";
      }
    }
  }
  close FILE;
  
  # We now register all the variables. %chash tells us which
  # came before which, so we sort the variables accordingly
   
  foreach my $n (sort { $chash{$a} <=> $chash{$b} } keys %vhash) {
    $self->addvar( @{$vhash{$n}} );
  }

  # Now we parse port definitions, and set the properties and labels.
  foreach (@ports) {
    ($portname, $portclass, $binds) = @{$_};
    my $port;
    my $realname = $self->suggestname($portname);
    my %labels = ();
    my ($x, $is, $y);

    eval {
      $port = $portclass -> new(name => $realname,
				parent => $self);
    };
    if ($@) {
      wrong("Failed to create port $portname in $file:\n$@");
      next;
    }
    foreach my $z (split(',', $binds)) {
      ($x, $is, $y) = ($z=~/^(.*?)([=]|[:])(.*)/);
      
      unless (defined $is) {
	wrong("Bad expression \'$z\' in the definition of $portname\n");
	next;
      }
     
      if ($is eq '=') {
	$port->const($x, $y);
      } else {
	wrong("Numeric value \'$y\' is unallowed on label \'$x\' for port \'$portname\' in \'$file\'\n")
	  if ($y =~ /^\d+$/);
	$labels{$x}=$y;
	unless (defined $vhash{$y}) {
	  wrong("Undeclared variable \'$y\' bound to label \'$x\' for port \'$portname\' in \'$file\'\n");
	  next;
	}
      }      
    }
    $port->set('labels', %labels);
    $self->const(['user_port_names', $portname], $port);
  }
  $self->set('verilog', $verilog);
  $self->set('prehead', $prehead);
  $self->set('extrahead', $extrahead); 

  # We now execute the inline perl pieces, if needed
  my @perls = $self->get('perl-inline-early');

  if (@perls) {
    my $origpack = __PACKAGE__;

    foreach my $p (@perls) {
      my $err = $self->myeval($p);
      blow("Failure in inline script:\n$err") if $err;  
    }      
    eval("package $origpack;"); # back to home (this shouldn't really matter, actually)
  }
  return $self;
}

sub headers {
  my $self = shift;
  $self->ontop($self->get('extrahead'));
  $self->SUPER::headers(@_);
  $self->ontop($self->get('prehead'));
}

sub epilogue {
  my $self = shift;
  $self->SUPER::epilogue(@_);

  my @perls = $self->get('perl-inline-late');
  return unless @perls;

  my $origpack = __PACKAGE__;
  
  foreach my $p (@perls) {
    my $err=$self->myeval($p);
    blow("Failure in inline script:\n$err") if $err;  
  }      
  eval("package $origpack;"); # back to home (this shouldn't really matter, actually)
}

sub myeval {
  my $self = shift;
  eval(shift);
  return $@;
}
