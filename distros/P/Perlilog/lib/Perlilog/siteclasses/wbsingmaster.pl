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

# Interface object for single master
sub attempt {
  my $this = shift;

  my @wbms =  grep {ref eq 'wbm'} @_;

  return undef unless ($#wbms == 0); # Single master, please

  my @vars =  grep {ref eq 'vars'} @_;
  my @extras = ();

  # @others is a list of ports that will be connected to the master.
  # These are not necessarily Wishbone ports, but may contain to-be
  # adapted ports.
  my @others = grep {((ref ne 'vars') && (ref ne 'wbm')) } @_;


  # If a vars port has a read-write-address label, it's not an "extra"
  # but a port that should be mapped on the bus, and should therefore join
  # @others, rather than @extras, which consists of "helping" wires.

  foreach (@vars) {
    my %l = $_->get('labels');
    if (grep /^(r|w|rw|wr)\d+$/, keys %l) {
      push @others, $_;
    } else {
      push @extras, $_;
    }
  }

  return "Nothing to connect the master with"
    unless (@others);

# This shortcut is good if the interface objects order is reversed in the
# registration. It works, but should not be used, because we tell
# wbsimple what to do.
#
# It shows, though, that a master class can dispatch other, simpler classes.
#
#  if (($#others==0) && (ref($others[0]) eq 'wbs')) {
#    return wbsimple->new(nick => 'cheat_simple_wb'); }

  my $self = $this->new(nick => 'single_master_wb_controller');  

  # We are going to need two properties on each of the @others objects
  # in order to make things work. Make sure they are there.

  my ($bits, $select);

  foreach my $mate (@others) {
    my $bits = $mate->get('wb_adr_bits');
    return "Missing \'wb_adr_bits\' property on ".$self->safewho($mate)
      unless (defined $bits);
    return "'wb_adr_bits\' should be a decimal number and not ".$self->prettyval($bits).
      " on ".$self->safewho($mate)
      unless ($bits =~ /^\d+$/);

    my $select = $mate->get('wb_adr_select');
    return "Missing \'wb_adr_select\' property on ".$self->safewho($mate)
      unless (defined $select);
    return "'wb_adr_select\' should be a decimal number and not ".$self->prettyval($select).
      " on ".$self->safewho($mate)
      unless ($select =~ /^\d+$/);
  }
  

  # Now we create ports to match with, and attempt to find some volunteer
  # to do the matching.

  # We begin with making a slave for the master port.

  my $myport = wbs->new(nick => 'wb_bus_controller_slave_port',
			parent => $self);
  
  my @objs = $self->intobjects(@wbms, $myport, @extras);
  return "Failed to match ".$self->safewho(@wbms).
    " with the Wishbone given by the single-master bus controller generator\n"
      unless (@objs);
  my @bunch = ($self, $myport, @objs);

  # Now we scan through the other ports. We just try to match them with
  # single Wishbone masters. If they are not Wishbone slaves, they should
  # be automatically adapted to such.

  foreach (@others) {
    $myport = wbm->new(nick => 'wb_bus_controller_master_port',
		       parent => $self);
    
    @objs = $self->intobjects($_, $myport, @extras);
    return "Failed to adapt ".$self->safewho($_)." to a Wishbone master, that was generated".
      "by the single-master bus controller generator\n"
      unless (@objs);
    push @bunch, $myport, @objs;
  }

  return @bunch;
}

sub generate {
  my $self = shift;

  # Get the ports to connect...
  my @ports = $self->get('ports');
  my ($wbs) = grep {ref eq 'wbs'} @ports;
  my @wbms = grep {ref eq 'wbm'} @ports;

  # Find our target object (where we're going to write code to)
  my $obj = $self->whereto;

  # Now we create the necessary variables for our one slave port (the
  # one connected with the master).

  my %wbsNames = ();
  my %wbsIDs = ();

  ($wbsNames{'clk_i'}, $wbsIDs{'clk_i'}) = $obj->namevar('m_wb_clk_i', 'wire', 'in');
  ($wbsNames{'rst_i'}, $wbsIDs{'rst_i'}) = $obj->namevar('m_wb_rst_i', 'wire', 'in');
  ($wbsNames{'adr_i'}, $wbsIDs{'adr_i'}) = $obj->namevar('m_wb_adr_o', 'wire', 'in');
  ($wbsNames{'dat_i'}, $wbsIDs{'dat_i'}) = $obj->namevar('m_wb_dat_o', 'wire', 'in');
  ($wbsNames{'dat_o'}, $wbsIDs{'dat_o'}) = $obj->namevar('m_wb_dat_i', 'wire', 'out');
  ($wbsNames{'we_i'},  $wbsIDs{'we_i'})  = $obj->namevar('m_wb_we_o', 'wire', 'in');
  ($wbsNames{'stb_i'}, $wbsIDs{'stb_i'}) = $obj->namevar('m_wb_stb_o', 'wire', 'in');
  ($wbsNames{'cyc_i'}, $wbsIDs{'cyc_i'}) = $obj->namevar('m_wb_cyc_o', 'wire', 'in');
  ($wbsNames{'ack_o'}, $wbsIDs{'ack_o'}) = $obj->namevar('m_wb_ack_i', 'wire', 'out');

  $wbs->const('labels', %wbsIDs); # Set up the labels for the port.

  # We are going to need to know the width of the main master's adr_o. Since
  # the master Wishbone port existed before this object, it should be connected
  # by now, and hence this property set.
  
  my ($realmaster) = grep {ref eq 'wbm'} $self->get('perlilog-ports-to-connect');
  my %master_IDs = $self->labelID($realmaster);
  my ($hi, $lo) = $self->bitrange($master_IDs{'adr_o'});

  wrong("Expected hi-to-low bit range on adr_o of ".
	$realmaster->who()."\n") if ($lo > $hi);

  wrong("Expected lowest bit in bit range on adr_o of ".
	$realmaster->who()." to be zero\n") unless ($lo == 0);

  # Now we copy off the variable names that should be "short-circuited" to the
  # controller's slaves. The rest of the variables require a specific set-up,
  # and will be handled per-case.

  my %shorts = (clk_i => 'clk_i',
		rst_i => 'rst_i',
		stb_o => 'stb_i',
		we_o => 'we_i',
		dat_o => 'dat_i');

  my %mlabels = ();
  foreach (keys %shorts) {
    $mlabels{$_} = $wbsIDs{$shorts{$_}};
  }

  # Finally, we set up the master port which mates with each
  # of the slaves.

  my ($bits, $select, $mate, $selcode);
  my @acks = ();
  my @dats = ();

  my $main_ack = $wbsNames{'ack_o'};
  my $main_dat = $wbsNames{'dat_o'};
  my $main_cyc = $wbsNames{'cyc_i'};
  my $main_adr = $wbsNames{'adr_i'};
  
  foreach my $port (@wbms) {
    # Find wb_adr_bits on the mating port
  MATE: foreach $mate ($port->get('mates')) {
      next MATE if (ref($mate) eq 'vars');
      $bits = $mate->get('wb_adr_bits');
      $select = $mate->get('wb_adr_select');     
      last MATE if (defined $bits);
    }
    wrong("Failed to find \'wb_adr_bits\' property on any of ".
	  join(', ', map {$_->who} $port->get('mates'))."\n")
      unless (defined $bits);

    wrong("Found \'wb_adr_bits\' property, but not \'wb_adr_select\' on ".
	  $mate->who()."\n")
      unless (defined $select);

    wrong("Faulty \'wb_adr_bits\' property ".$self->prettyval($bits).
	  " on ".$mate->who()."\n")
      unless ($bits =~ /^\d+$/);

    wrong("Range exceeds dimensions, because \'wb_adr_bits\' on ".
	  $mate->who()." was too large\n")
      if (($hi + 1) < $bits);
    
    if ($hi < $bits) {
      $selcode = "1"; 
    } else {
      $selcode = $wbsNames{'adr_i'}.'['.$hi.':'.$bits.'] == '.$select;
    }

    my $adrhi = ($bits==0) ? $hi : ($bits - 1);
    my ($adrvar, $adrID) = $obj->namevar('wb_slave_adr', 'wire', 'out', "[$adrhi:0]");
    $mlabels{'adr_o'} = $adrID;

    my ($cycvar, $cycID) = $obj->namevar('wb_slave_cyc', 'wire', 'out');
    $mlabels{'cyc_o'} = $cycID;
    
    $obj->samedim($cycvar, $main_cyc);

    my ($ackvar, $ackID) = $obj->namevar('wb_slave_ack', 'wire', 'in');
    $mlabels{'ack_i'} = $ackID;
    push @acks, $ackvar;

    $obj->samedim($ackvar, $main_ack);

    my $selvar = $obj->namevar('wb_slave_active', 'wire', 'out', '');
    $obj->append("  assign $selvar = $selcode;\n".
		 "  assign $cycvar = $main_cyc & $selvar;\n".
		 "  assign $adrvar = $main_adr".'['.$adrhi.":0];\n");

    my ($datvar, $datID) = $obj->namevar('wb_slave_dat', 'wire', 'in');
    $mlabels{'dat_i'} = $datID;
    push @dats, "($selvar ? $datvar : 0)";

    $obj->samedim($datvar, $main_dat);

    $port->const('labels', %mlabels); # Set up the labels for the port.
  }

  my $allacks = join(' | ', @acks);
  my $alldats = join(' | ', @dats);

  $obj->append("  assign $main_ack = $allacks;\n".
	       "  assign $main_dat = $alldats;\n");

  # In a perfect world, we would check up here if the slave selects don't
  # overlap because of addressing inconsintencies. 
}
