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

# Interface object for vars and Wishbone master
sub attempt {
  my $this = shift;

  my @wbms =  grep {ref eq 'wbm'} @_;
  return undef unless ($#wbms == 0); # Single master, please

  my @allvars = grep {ref eq 'vars'} @_;
  return undef if ($#allvars == -1); # At least one 'vars'

  return undef unless ($#_ == $#allvars+1); # Only 'vars' and one 'wbm'

  my @extras = ();
  my $vars = undef;

  # If a vars port has a read-write-address label, it's not an "extra"
  # but a port that should be mapped on the bus. Do it.

  foreach (@allvars) {
    my %l = $_->get('labels');
    if (grep /^(r|w|rw|wr)\d+$/, keys %l) {
      return "More than one address-mapped \'vars\' port in bundle"
	if (defined $vars);
      $vars = $_;
    } else {
      push @extras, $_;
    }
  }

  my $wbm = $wbms[0];

  # Now we make sure that $vars has wb_adr_bits and wb_adr_select set.
  # The wishbone interfacing won't work otherwise.

  my $bits = $vars->get('wb_adr_bits');
  my $select = $vars->get('wb_adr_select');

  return ("Failed to find \'wb_adr_bits\' and \'wb_adr_select\' properties in ".
	  $vars->who." while attempting to interface it with ".$wbm->who."\n")
    unless ((defined $bits) && (defined $select));

  # Now we create ports to match with, and attempt to find some volunteer
  # to do the matching.

  my $self = $this->new(nick => 'vars_to_wishbone');  

  # We begin with making a slave for the master port.

  my $mywbs = wbs->new(nick => 'vars2wbm_wbs_port',
		       parent => $self);
  # Here we diffuse the properties to our own slave

  $mywbs->const('wb_adr_bits', $bits);
  $mywbs->const('wb_adr_select', $select);
       
  # And finally, we interface our ports.

  my @objs = $self->intobjects($wbm, $mywbs, @extras);
  return "Failed to match ".$self->safewho(@wbms).
    " with a vars-adapting Wishbone slave\n"
      unless (@objs);

  return ($self, $mywbs, @objs);
}

sub generate {
  my $self = shift;

  # Get the ports to connect...
  my @ports = $self->get('ports');
  my ($wbs) = grep {ref eq 'wbs'} @ports;
  my @allvars = grep {ref eq 'vars'} $self->get('perlilog-ports-to-connect');

  # Find our target object (where we're going to write code to)
  my $obj = $self->whereto;

  # Now we create the necessary variables for our one slave port (the
  # one connected with the master).

  my %wbsNames = ();
  my %wbsIDs = ();

  my ($clk, $rst, $adr_i, $dat_i, $dat_o, $we_i, $stb_i, $cyc_i, $ack_o);

  ($clk, $wbsIDs{'clk_i'})   = $obj->namevar('wb_clk_i', 'wire', 'in');
  ($rst, $wbsIDs{'rst_i'})   = $obj->namevar('wb_rst_i', 'wire', 'in');
  ($adr_i, $wbsIDs{'adr_i'}) = $obj->namevar('wb_adr_i', 'wire', 'in');
  ($dat_i, $wbsIDs{'dat_i'}) = $obj->namevar('wb_dat_i', 'wire', 'in');
  ($dat_o, $wbsIDs{'dat_o'}) = $obj->namevar('wb_dat_o', 'wire', 'out');
  ($we_i, $wbsIDs{'we_i'})   = $obj->namevar('wb_we_i', 'wire', 'in');
  ($stb_i, $wbsIDs{'stb_i'}) = $obj->namevar('wb_stb_i', 'wire', 'in');
  ($cyc_i, $wbsIDs{'cyc_i'}) = $obj->namevar('wb_cyc_i', 'wire', 'in');
  ($ack_o, $wbsIDs{'ack_o'}) = $obj->namevar('wb_ack_o', 'wire', 'out');

  $wbs->const('labels', %wbsIDs); # Set up the labels for the port.

  $obj->append("  assign $ack_o = $cyc_i && $stb_i;\n");

  # Find our one mapped vars port.
  my $vars;
  my %l; 
  foreach (@allvars) {
    %l = $_->get('labels');
    if (grep /^(r|w|rw|wr)\d+$/, keys %l) {
      $vars = $_;
      last;
    }
  }

  # Now we set up the read and write addresses
  my %reads = ();
  my %writes = ();

  my %lID = $self->labelID($vars);

  foreach (sort keys %lID) {
    if (/^(rw|wr|r)(\d+)$/) {
      wrong("Double definition for read-from address ($2) on ".$vars->who."\n")
	if (defined $reads{$2});
      $reads{$2} = $lID{$_};
    }
    if (/^(rw|wr|w)(\d+)$/) {
      wrong("Double definition for write-to address ($2) on ".$vars->who."\n")
	if (defined $writes{$2});
      $writes{$2} = $lID{$_};
    }
    wrong("Non-compliant label ".$self->prettyval($_).
	  " on bus-mapped ".$vars->who."\n")
      unless (/^(rw|wr|r|w)(\d+)$/)  
  } 
  
  # Now to bus writes. This is a bit tricky, because we need
  # a register to hold the value, and the drive the desired variable.
  # Note that we do this before read cycles, because we always try to
  # do attach()es before copyvar()s. (Actually, it wouldn't matter in
  # this specific case, but it's a good habit).

  my @writeregs = ();
  my %written = ();
  my ($regname, $regID);
  my $writecaseclause = '';

  foreach (sort {$a <=> $b} keys %writes) {
    my $wireID = $writes{$_};
    # We fecth the variable's name in the object in which it resides,
    # so we can give our register a related name -- no more use for
    # it.
    if (defined $written{$wireID}) {
      # If we have already assigned a register to the variable, just write
      # on the register. This makes it possible to write to the same register
      # via multiple addresses.
      $regname = $written{$wireID};
    } else {
      # Otherwise, we generate a special register.
      my $smartname = $self->IDvar($wireID);
      ($regname, $regID) = $obj->namevar($smartname.'_reg', 'reg', 'out');
      $obj->samedim($regname, $dat_i);
      $written{$wireID} = $regname;
      $self->attach($regID, $wireID);
      push @writeregs, $regname;
    }
    $writecaseclause .= "        $_: $regname <= #1 $dat_i;\n";
  }

  my $writeclause = "  always @(posedge $clk or posedge $rst)\n";
  $writeclause   .= "    if ($rst)\n";
  $writeclause   .= "      begin\n";
  foreach (@writeregs) {
    $writeclause .= "        $_ <= #1 0;\n"; 
  }
  $writeclause   .= "      end\n";
  $writeclause   .= "    else if ($cyc_i && $stb_i && $we_i)\n";
  $writeclause   .= "      case ($adr_i)\n";
  $writeclause .= $writecaseclause;
  $writeclause   .= "      endcase\n";
  
  # Now we create the code for the bus reads.
  
  my @triggers = ($adr_i);
  my %triggered = ();

  my $readclause = '';

  foreach (sort {$a <=> $b} keys %reads) {
    my $localname = $obj->copyvar($reads{$_});
    $readclause .= "      $_: $dat_o = $localname;\n";
    $obj->samedim($dat_o, $localname); # Important!
    unless (defined $triggered{$localname}) {
      $triggered{$localname} = 1;
      push @triggers, $localname;
    }
  }

  $readclause .= "      default: $dat_o = 0;\n"; 
  $readclause .= "    endcase\n\n";    

  # Now we put the opening "always" piece 
  $readclause = "  always @(".join(' or ', @triggers).
    ")\n    case ($adr_i)\n" . $readclause;
  
  # Finally we append our clauses. Well, only if there is some
  # essence in them.

  unless ($#triggers < 1) {
    $obj->append($readclause) ;
    # If the read clause exists, the dat_o is used as a register.
    $obj->set(['vars', $dat_o, 'type'], 'reg');
  }
  $obj->append($writeclause) if (@writeregs);
}

sub codetargets { 
  my $self = shift;

  # Get the ports to connect...
  my @ports = $self->get('perlilog-ports-to-connect');
  my ($wbm) = grep {ref eq 'wbm'} @ports;
  my @allvars = grep {ref eq 'vars'} @ports;

  # Find our one mapped vars port.
  my $vars;
  my %l; 
  foreach (@allvars) {
    %l = $_->get('labels');
    if (grep /^(r|w|rw|wr)\d+$/, keys %l) {
      $vars = $_;
      last;
    }
  }
  # Now we recommend these ports parents...

  return ($vars->get('parent'), $wbm->get('parent'));
}
