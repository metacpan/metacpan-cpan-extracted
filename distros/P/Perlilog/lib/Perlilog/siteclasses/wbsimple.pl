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

sub attempt {
  my $this = shift;

  # One master, one slave?
  return undef if 
    (
     ((grep {ref eq 'wbm'} @_) != 1) ||
     ((grep {ref eq 'wbs'} @_) != 1)
    );

  my @extras =  grep {ref eq 'vars'} @_;

  return "There are ports other than 'wbm', wbs' and 'vars' in the bundle"
    if (grep {(ref ne 'wbm') && (ref ne 'wbs') && (ref ne 'vars')} @_ );
  
  # Now we make sure that none of the "vars" weren't meant to be
  # mapped on the bus themselves.

  foreach (@extras) {
    my %l = $_->get('labels');
    return undef
      if (grep /^(r|w|rw|wr)\d+$/, keys %l);
  }

  my $self = $this->new(nick => 'Wishbone_simple_connection');
  return $self;
}

sub generate {
  my $self = shift;

  my %pairs = (cyc_o => 'cyc_i',
	       stb_o => 'stb_i',
	       ack_i => 'ack_o',
	       we_o => 'we_i',
	       adr_o => 'adr_i',
	       dat_o => 'dat_i',
	       dat_i => 'dat_o');

  # Get the ports to connect...
  my @ports = $self->get('perlilog-ports-to-connect');
  my ($wbs) = grep {ref eq 'wbs'} @ports;
  my ($wbm) = grep {ref eq 'wbm'} @ports;
  my @extras = grep {ref eq 'vars'} @ports;

  # Now we assure the excusiveness of the connection
  my $prevconn;

  $prevconn = $wbs->get('wishbone-connection-marker');
  wrong("Attempt to connect ".$wbs->who." to ".$wbm->who.
	" when already connected to ".$self->safewho($prevconn)."\n")
    if (defined $prevconn);

  $prevconn = $wbm->get('wishbone-connection-marker');
  wrong("Attempt to connect ".$wbm->who." to ".$wbs->who.
	" when already connected to ".$self->safewho($prevconn)."\n")
    if (defined $prevconn);

  $wbs->const('wishbone-connection-marker', $wbm);
  $wbm->const('wishbone-connection-marker', $wbs);

  # Translate variable names to ID's
  my %hs=$self->labelID($wbs);
  my %hm=$self->labelID($wbm);

  my %he = ();
  my $port;
  foreach $port (reverse @extras) {
    my %h = $self->labelID($port);
    foreach (keys %h) { $he{$_} = $h{$_}; }
  }

  foreach (qw(rst_i clk_i), sort keys %pairs) {
    wrong("Missing label \'$_\' in ".$wbm->who()."\n")
      unless (defined $hm{$_});
  }

  foreach (qw(rst_i clk_i), sort values %pairs) {
    wrong("Missing label \'$_\' in ".$wbs->who()."\n")
      unless (defined $hs{$_});
  }

  # Now we make variable attachments. First clock and reset, if
  # they were given by some 'vars' port

  if (defined $he{'rst'}) {
    $self->attach($hm{'rst_i'}, $he{'rst'});
    $self->attach($hs{'rst_i'}, $he{'rst'});
  }

  if (defined $he{'clk'}) {
    $self->attach($hm{'clk_i'}, $he{'clk'});
    $self->attach($hs{'clk_i'}, $he{'clk'});
  }

  # And now we attach the master-slave signals

  foreach (sort keys %pairs) {
    $self->attach($hm{$_}, $hs{$pairs{$_}});
  }  
}
